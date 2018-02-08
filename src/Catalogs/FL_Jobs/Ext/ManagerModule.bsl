////////////////////////////////////////////////////////////////////////////////
// This file is part of FoxyLink.
// Copyright © 2016-2018 Petro Bazeliuk.
// 
// This program is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Affero General Public License as 
// published by the Free Software Foundation, either version 3 of the License,
// or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful, 
// but WITHOUT ANY WARRANTY; without even the implied warranty of 
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License 
// along with FoxyLink. If not, see <http://www.gnu.org/licenses/agpl-3.0>.
//
////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
    
#Region ProgramInterface    

// Used to run a job now. The information about triggered invocation will not 
// be recorded in the recurring job itself, and its next execution time will 
// not be recalculated from this running. For example, if you have a weekly job
// that runs on Wednesday, and you manually trigger it on Friday it will run on 
// the following Wednesday.
//
// Parameters:
//  Job - Array              - array of references to the jobs to be triggered.
//      - CatalogRef.FL_Jobs - reference to the job to be triggered.
//
Procedure Trigger(Job) Export
    
    If TypeOf(Job) = Type("Array") Then
        For Each Item In Job Do
            ProcessJob(Item);        
        EndDo;
    Else
        ProcessJob(Job);       
    EndIf;       
            
EndProcedure // Trigger() 

// Creates a new background job in a specified state.
//
// Parameters:
//  BackgroundJob - FixedStructure       - job that should be processed in background.
//  State         - CatalogRef.FL_States - initial state for a background job.
//
// Returns:
//  CatalogRef.FL_Jobs - ref to created background job or 
//                       Undefined, if it was not created.
//
Function Create(BackgroundJob, State) Export
    
    Var Parameters, SessionContext, Subscribers, SubscriberResources; 
    
    NewJob = Catalogs.FL_Jobs.CreateItem();
    NewJob.State = State;
    NewJob.CreatedAt = CurrentUniversalDate();
    
    FillPropertyValues(NewJob, BackgroundJob);

    If BackgroundJob.Property("Parameters", Parameters) 
        AND TypeOf(Parameters) = Type("ValueTable") Then
        NewJob.DCSParameters.Load(Parameters);
    EndIf;
    
    If BackgroundJob.Property("SessionContext", SessionContext) 
        AND TypeOf(SessionContext) = Type("ValueTable") Then
        NewJob.SessionContext.Load(SessionContext);
    EndIf;
    
    If BackgroundJob.Property("Subscribers", Subscribers) 
        AND TypeOf(Subscribers) = Type("ValueTable") Then
        NewJob.Subscribers.Load(Subscribers);
    EndIf;
    
    If BackgroundJob.Property("SubscriberResources", SubscriberResources) 
        AND TypeOf(SubscriberResources) = Type("ValueTable") Then
        NewJob.SubscriberResources.Load(SubscriberResources);
    EndIf;
    
    NewJob.Write();
    Return NewJob.Ref;

EndFunction // Create()

// Attempts to change a state of a background job with a given identifier 
// to a specified one.
//
// Parameters:
//  Job           - CatalogRef.FL_Jobs   - job, whose state should be changed.
//  State         - CatalogRef.FL_States - new state for a background job.
//  ExpectedState - String, CatalogRef.FL_States - value is not Undefined, 
//                      state change will be performed only if the current 
//                      state name of a job equal to the given value.
//                          Default value: Undefined.
//
// Returns:
//  Boolean - True, if a given state was applied successfully otherwise False.
//
Function ChangeState(Job, State, ExpectedState = Undefined) Export
    
    DataLock = New DataLock;
    LockItem = DataLock.Add("Catalog.FL_Jobs");
    LockItem.Mode = DataLockMode.Exclusive;
    LockItem.SetValue("Ref", Job);
    
    Try
        BeginTransaction();
        
        DataLock.Lock();
        
        JobObject = Job.GetObject();
        JobObject.State = State; 
        JobObject.Write();
        
        CommitTransaction();
        
    Except
        
        RollbackTransaction();
        Return False;
        
    EndTry;
    
    Return True;
    
EndFunction // ChangeState()

#EndRegion // ProgramInterface

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
Procedure ProcessJob(Job)
    
    JobObject = Job.GetObject();
    JobObject.State = Catalogs.FL_States.Succeeded;
        
    MessageSettings = FL_DataComposition.NewMessageSettings();
    For Each DCSParameter In JobObject.DCSParameters Do
        MessageSettings.Body.Parameters.Insert(DCSParameter.Parameter, 
            DCSParameter.ValueStorage.Get());
    EndDo;

    ExchangeSettings = Catalogs.FL_Exchanges.ExchangeSettingsByRefs(
        JobObject.Owner, JobObject.Method);          
        
    MemoryStream = New MemoryStream;
    Catalogs.FL_Exchanges.OutputMessageIntoStream(MemoryStream, 
        ExchangeSettings, MessageSettings);  
    NotifyChannels(JobObject, MemoryStream);     
    
    JobObject.Write();   
    
EndProcedure // ProcessJob()

// Only for internal use.
//
Procedure NotifyChannels(JobObject, Stream)
    
    If JobObject.Subscribers.Count() = 0 Then
        Return;    
    EndIf;
    
    FilterParameters = New Structure("Channel");
    Resources = JobObject.SubscriberResources.Unload();
    For Each Subscriber In JobObject.Subscribers Do 
        
        If Subscriber.Completed Then
            Continue;    
        EndIf;
        
        //Try
            FilterParameters.Channel = Subscriber.Channel;   
            TriggerResult = Catalogs.FL_Channels.TransferStreamToChannel(
                Subscriber.Channel, Stream, NewProperties(JobObject, 
                    Resources.FindRows(FilterParameters)));
        //Except
            //TODO: Exceptions!
        //EndTry;
                
        //SuccessResponseHandler = True;
        //ErrorResponseDescription = "";
        //If Not IsBlankString(Subscriber.ResponseHandler) Then
        //    
        //    Try
        //        Execute(Subscriber.ResponseHandler);
        //    Except
        //        SuccessResponseHandler = False;
        //        ErrorResponseDescription = ErrorDescription();
        //    EndTry;
        //    
        //EndIf;
        
        If TriggerResult.Success Then //AND SuccessResponseHandler Then
            Subscriber.Completed = True;
        Else
            JobObject.State = Catalogs.FL_States.Failed;
        EndIf;
        
        NewLogRow = JobObject.SubscribersLog.Add();
        NewLogRow.Channel = Subscriber.Channel;
        FillPropertyValues(NewLogRow, TriggerResult);
                
    EndDo;
             
EndProcedure // NotifyChannels()

// Only for internal use.
//
Function NewProperties(JobObject, Resources)
    
    Properties = New Structure;
    For Each Resource In Resources Do
        Properties.Insert(Resource.FieldName, Resource.FieldValue);        
    EndDo;
    
    JobProperties = New Structure;
    JobProperties.Insert("MetadataObject", JobObject.MetadataObject);
    JobProperties.Insert("Method", JobObject.Method);
    JobProperties.Insert("SourceObject", JobObject.SourceObject);
    //JobProperties.Insert("MediaType", JobObject.MediaType);
    Properties.Insert("JobProperties", JobProperties);
    Return Properties;
    
EndFunction // NewProperties()

#EndRegion // ServiceProceduresAndFunctions

#EndIf
