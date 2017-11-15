////////////////////////////////////////////////////////////////////////////////
// This file is part of FoxyLink.
// Copyright © 2016-2017 Petro Bazeliuk.
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
    
    Var Subscribers, SubscriberResources, Parameters; 
    
    NewJob = Catalogs.FL_Jobs.CreateItem();
    NewJob.State = State;
    NewJob.CreatedAt = CurrentUniversalDate();
    
    FillPropertyValues(NewJob, BackgroundJob);

    If BackgroundJob.Property("Subscribers", Subscribers) 
        AND TypeOf(Subscribers) = Type("ValueTable") Then
        NewJob.Subscribers.Load(Subscribers);
    EndIf;
    
    If BackgroundJob.Property("SubscriberResources", SubscriberResources) 
        AND TypeOf(SubscriberResources) = Type("ValueTable") Then
        NewJob.SubscriberResources.Load(SubscriberResources);
    EndIf;
    
    If BackgroundJob.Property("Parameters", Parameters) 
        AND TypeOf(Parameters) = Type("ValueTable") Then
        NewJob.DCSParameters.Load(Parameters);
    EndIf;
    
    Try
        NewJob.Write();
        Return NewJob.Ref;
    Except
        Return Undefined;
    EndTry;
    
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

// Processes exchange message.
//
// Parameters:
//  Ref - CatalogRef.FL_Jobs - reference to the exchange message. 
//
// Returns:
//  Structure - delivery response.
//
Function ProcessMessage(Ref) Export
    
    //BeginTransaction();
    //
    //DataLock = New DataLock;
    //ItemLock = DataLock.Add("Catalog.FL_Jobs");
    //ItemLock.Mode = DataLockMode.Exclusive;
    //ItemLock.SetValue("Ref", Ref);
    //DataLock.Lock();
    
    // It is needed to avoid "Dirty read" from the file infobase.
    //IsFileInfobase = FL_CommonUse.FileInfobase();
    //If IsFileInfobase Then
    //    BeginTransaction();
    //EndIf;
    
    //Query = New Query;
    //Query.Text = QueryTextMessageData();
    //Query.SetParameter("Ref", Ref);
    //QueryResult = Query.Execute();
    //If QueryResult.IsEmpty() Then
    //    
    //    If TransactionActive() Then
    //        RollbackTransaction();
    //    EndIf;
    //    
    //    Raise Nstr(
    //        "en = 'Error: Message data not found, it might be set the deletion mark.'; 
    //        |ru = 'Ошибка: Данные сообщения не найдены, возможно, установлена пометка на удаление.'");
    //    
    //EndIf;
    
    // MessageData = QueryResult.Select();
    // MessageObject.Next();
    MessageObject = Ref.GetObject();
    MessageObject.State = Catalogs.FL_States.Succeeded;
        
    MessageSettings = FL_DataComposition.NewMessageSettings();
    For Each DCSParameter In MessageObject.DCSParameters Do
        MessageSettings.Body.Parameters.Insert(DCSParameter.Parameter, 
            DCSParameter.ValueStorage.Get());
    EndDo;

    ExchangeSettings = Catalogs.FL_Exchanges.ExchangeSettingsByRefs(
        MessageObject.Owner, MessageObject.Method); 
        
    ResultMessage = Catalogs.FL_Exchanges.GenerateMessageResult(Undefined, 
        ExchangeSettings, MessageSettings);
            
    If Not MessageObject.Subscribers.Count() = 0 Then
        
        FilterParameters = New Structure("Channel");
        SubscriberResources = MessageObject.SubscriberResources.Unload();
        For Each Subscriber In MessageObject.Subscribers Do 
            
            If Subscriber.Completed Then
                Continue;    
            EndIf;
            
            FilterParameters.Channel = Subscriber.Channel; 
            
            DeliveryResponse = Catalogs.FL_Channels.SendMessageResult(
                Undefined, 
                ResultMessage, 
                Subscriber.Channel, 
                SubscriberResources.FindRows(
                    FilterParameters));
                    
            
            SuccessResponseHandler = True;
            ErrorResponseDescription = "";
            If Not IsBlankString(Subscriber.ResponseHandler) Then
                
                Try
                    Execute(Subscriber.ResponseHandler);
                Except
                    ErrorResponseHandler = False;
                    ErrorResponseDescription = ErrorDescription();
                EndTry;
                
            EndIf;
            
            If DeliveryResponse.Success And SuccessResponseHandler Then
                Subscriber.Completed = True;
            Else
                MessageObject.State = Catalogs.FL_States.Failed;
            EndIf;
                    
        EndDo;
             
    EndIf;
    
    MessageObject.Write();  
        
    Return DeliveryResponse;
            
EndFunction // ProcessMessage() 

#EndRegion // ProgramInterface

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
Function QueryTextMessageData()

    QueryText = "
        |SELECT
        |   BackgroundJobs.Owner      AS Owner,
        |   BackgroundJobs.APIVersion AS APIVersion,
        |   BackgroundJobs.Method     AS Method,
        |   BackgroundJobs.Reference  AS Reference,
        |
        |   BackgroundJobs.Subscribers.(
        |       Channel         AS Channel,
        |       Completed       AS Completed,
        |       ResponseHandler AS ResponseHandler
        |       ) AS Subscribers,
        |
        |   BackgroundJobs.SubscriberResources.(
        |       Channel     AS Channel,
        |       FieldName   AS FieldName,
        |       FieldValue  AS FieldValue
        |       ) AS SubscriberResources        
        |
        |FROM
        |   Catalog.FL_Jobs AS BackgroundJobs
        |   
        |WHERE
        |   BackgroundJobs.Ref = &Ref
        |AND BackgroundJobs.DeletionMark = FALSE
        |";  
    Return QueryText;

EndFunction // QueryTextMessageData()

#EndRegion // ServiceProceduresAndFunctions

#EndIf
