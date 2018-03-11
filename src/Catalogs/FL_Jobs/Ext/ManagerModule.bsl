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
//  Jobs - Array              - array of references to the jobs to be triggered.
//       - CatalogRef.FL_Jobs - reference to the job to be triggered.
//
Procedure Trigger(Jobs) Export
    
    ValidJobs = New Array;
    ValidateJobType(ValidJobs, Jobs);
    
    StreamObjectCache = New Map;
    For Each Job In ValidJobs Do
        
        // Start measuring.
        StartTime = CurrentUniversalDateInMilliseconds();
        
        JobObject = Job.GetObject();
        JobProperties = NewJobProperties();
        FillJobProperties(JobObject, JobProperties);
        
        // Fills stream by the exchange result data.
        StreamOutExchangeData(JobProperties, StreamObjectCache);
        
        // Notify all subscrubers.
        NotifyChannels(JobObject, JobProperties);
        
        ChangeState(JobObject, JobProperties.CurrentState);    
        
        // End measuring.
        EndTime = CurrentUniversalDateInMilliseconds();
        RecordJobPerformanceMetrics(JobObject, StartTime, EndTime);
        
    EndDo;
            
EndProcedure // Trigger() 

// Creates a new background job in a specified state.
//
// Parameters:
//  InvocationData - FixedStructure       - job that should be processed in background.
//  State          - CatalogRef.FL_States - initial state for a background job.
//
// Returns:
//  CatalogRef.FL_Jobs - ref to created background job or 
//                       Undefined, if it was not created.
//
Function Create(InvocationData, State) Export
    
    Var InvocationContext, SessionContext;
        
    JobObject = Catalogs.FL_Jobs.CreateItem();
    FillPropertyValues(JobObject, InvocationData);
    
    If InvocationData.Property("InvocationContext", InvocationContext) 
        AND TypeOf(InvocationContext) = Type("ValueTable") Then
        JobObject.InvocationContext.Load(InvocationContext);
    EndIf;
    
    If InvocationData.Property("SessionContext", SessionContext) 
        AND TypeOf(SessionContext) = Type("ValueTable") Then
        JobObject.SessionContext.Load(SessionContext);
    EndIf;
    
    SubIndex = 1;
    ResIndex = 2;
        
    SubscribersData = New Query;
    SubscribersData.Text = QueryTextSubscribersData();
    SubscribersData.SetParameter("Owner", JobObject.Owner);
    SubscribersData.SetParameter("Operation", JobObject.Operation);
    BatchResult = SubscribersData.ExecuteBatch();
    
    FillSubscribers(JobObject, BatchResult[SubIndex].Unload());
    FillSubscriberResources(JobObject, InvocationData.Source, 
        BatchResult[ResIndex].Unload());
        
    ChangeState(JobObject, State);
    
    // End measuring.
    EndTime = CurrentUniversalDateInMilliseconds();
    RecordJobPerformanceMetrics(JobObject, JobObject.CreatedAt, EndTime);
    
    Return JobObject.Ref;

EndFunction // Create()

// Attempts to change a state of a background job with a given identifier 
// to a specified one.
//
// Parameters:
//  Job           - CatalogRef.FL_Jobs    - job, whose state should be changed.
//                - CatalogObject.FL_Jobs - job, whose state should be changed.
//  State         - CatalogRef.FL_States  - new state for a background job.
//  ExpectedState - String, CatalogRef.FL_States - value is not Undefined, 
//                      state change will be performed only if the current 
//                      state name of a job equal to the given value.
//                          Default value: Undefined.
//
// Returns:
//  Boolean - True, if a given state was applied successfully otherwise False.
//
Function ChangeState(Job, State, ExpectedState = Undefined) Export
    
    If ExpectedState <> Undefined 
        AND Upper(String(ExpectedState)) <> Upper(String(Job.State)) Then
        Return False;             
    EndIf;
    
    If TypeOf(Job) = Type("CatalogRef.FL_Jobs") Then
        
        JobObject = Job.GetObject();
        JobObject.State = State;
        JobObject.Write();
        
        RecordJobPerformanceMetrics(JobObject);
        
    Else
        
        Job.State = State; 
        Job.Write();
        
    EndIf;
        
    Return True;
    
EndFunction // ChangeState()

#EndRegion // ProgramInterface

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
Procedure ValidateJobType(ValidJobs, Job)
    
    If TypeOf(Job) = Type("CatalogRef.FL_Jobs") Then
        
        ValidJobs.Add(Job);
        
    ElsIf TypeOf(Job) = Type("Array") Then
        
        For Each Item In Job Do
            ValidateJobType(ValidJobs, Item);        
        EndDo;
        
    Else
        
        ErrorMessage = FL_ErrorsClientServer.ErrorTypeIsDifferentFromExpected(
            "Jobs", Job, "Array, CatalogRef.FL_Jobs");
        Raise ErrorMessage;
        
    EndIf;    
    
EndProcedure // ValidateJobType()

// Only for internal use.
//
Procedure StreamOutExchangeData(JobProperties, Cache)
    
    ExchangeSettings = Catalogs.FL_Exchanges.ExchangeSettingsByRefs(
        JobProperties.Owner, JobProperties.Operation);    
            
    StreamObject = StreamObjectCached(Cache, ExchangeSettings.BasicFormatGuid); 
    
    // Open new memory stream and initialize format processor.
    Stream = New MemoryStream;
    StreamObject.Initialize(Stream, ExchangeSettings.APISchema);
    
    OutputParameters = Catalogs.FL_Exchanges.NewOutputParameters(
        ExchangeSettings, JobProperties.InvocationContext);
                
    FL_DataComposition.Output(StreamObject, OutputParameters);
    
    // Fill MIME-type information.
    JobProperties.ContentType = StreamObject.FormatMediaType();
    JobProperties.ContentEncoding = StreamObject.ContentEncoding;
    JobProperties.FileExtension = StreamObject.FormatFileExtension();
    JobProperties.ReadonlyStream = Stream.GetReadOnlyStream(); 
    
    // Close format stream and memory stream.
    StreamObject.Close();
    Stream.Close();
    
EndProcedure // StreamOutExchangeData()

// Only for internal use.
//
Procedure NotifyChannels(JobObject, JobProperties)
        
    FilterParameters = New Structure("Channel");
    Resources = JobObject.SubscriberResources.Unload();
    
    For Each Subscriber In JobObject.Subscribers Do 
        
        If Subscriber.Completed Then
            Continue;    
        EndIf;
        
        Try
        
            JobProperties.ReadonlyStream.Seek(0, PositionInStream.Begin);
            FilterParameters.Channel = Subscriber.Channel;   
            TriggerResult = Catalogs.FL_Channels.TransferStreamToChannel(
                Subscriber.Channel, 
                JobProperties.ReadonlyStream, 
                NewProperties(JobProperties, Resources.FindRows(
                        FilterParameters)));
                
        Except
            
            TriggerResult = Catalogs.FL_Channels.NewChannelDeliverResult();
            TriggerResult.LogAttribute = ErrorDescription();
            
        EndTry;
                
        If TriggerResult.Success Then
            Subscriber.Completed = True;
        Else
            JobProperties.CurrentState = Catalogs.FL_States.Failed;
        EndIf;
        
        NewLogRow = JobObject.SubscribersLog.Add();
        NewLogRow.Channel = Subscriber.Channel;
        FillPropertyValues(NewLogRow, TriggerResult);
                
    EndDo;
             
EndProcedure // NotifyChannels()

// Only for internal use.
//
Procedure FillJobProperties(JobObject, JobProperties)
    
    InvocationContext = JobObject.InvocationContext.Unload();
    InvocationContext.Columns.Add("Value");
    For Each Context In InvocationContext Do
        
        Try
            Type = FromXMLType(Context.TypeName, Context.NamespaceURI);
            Context.Value = XMLValue(Type, Context.XMLValue);
        Except
            Context.Value = Undefined;     
        EndTry;
        
    EndDo;
    
    JobProperties.InvocationContext = InvocationContext;
    JobProperties.Job = JobObject.Ref;
    JobProperties.MetadataObject = JobObject.MetadataObject;
    JobProperties.Operation = JobObject.Operation;
    JobProperties.Owner = JobObject.Owner;
    
EndProcedure // FillJobProperties()

// Only for internal use.
//
Procedure FillSubscribers(JobObject, Subscribers)
    
    For Each Subscriber In Subscribers Do
        FillPropertyValues(JobObject.Subscribers.Add(), Subscriber);
    EndDo;    
    
EndProcedure // FillSubscribers()

// Only for internal use.
//
Procedure FillSubscriberResources(JobObject, Source, Resources)
    
    For Each Resource In Resources Do
        
        If Resource.ExecutableCode Then
                
            ExecutableParams = New Structure;
            ExecutableParams.Insert("Source", Source);
            ExecutableParams.Insert("Result", Undefined);
            
            Algorithm = StrTemplate("
                    |Source = Parameters.Source;
                    |Result = Parameters.Result;
                    |
                    |%1
                    |
                    |Parameters.Result = Result;", 
                Resource.FieldValue);
                
            Try
                FL_RunInSafeMode.ExecuteInSafeMode(Algorithm, 
                    ExecutableParams);
                    
                NewResource = JobObject.SubscriberResources.Add();    
                FillPropertyValues(NewResource, Resource, , "FieldValue");
                NewResource.FieldValue = ExecutableParams.Result;
                
            Except

                ErrorInfo = ErrorInfo();
                ErrorMessage = StrTemplate(
                    NStr("en='An error occurred when calling procedure 
                            |ExecuteInSafeMode of common module FL_RunInSafeMode. %1';
                        |ru='Ошибка при вызове процедуры ExecuteInSafeMode 
                            |общего модуля FL_RunInSafeMode. %1';
                        |en_CA='An error occurred when calling procedure 
                            |ExecuteInSafeMode of common module FL_RunInSafeMode. %1'"),
                    BriefErrorDescription(ErrorInfo));
                FL_CommonUseClientServer.NotifyUser(ErrorMessage);     
                      
                FillPropertyValues(JobObject.SubscriberResources.Add(), 
                    Resource);   
                    
            EndTry;
            
        Else
            FillPropertyValues(JobObject.SubscriberResources.Add(), 
                Resource);    
        EndIf;
            
    EndDo;    
    
EndProcedure // FillSubscribers()

// Only for internal use.
//
Procedure RecordJobPerformanceMetrics(JobObject, StartTime = 0, EndTime = 0) 
    
    RecordManager = InformationRegisters.FL_JobState.CreateRecordManager();
    RecordManager.Job = JobObject.Ref;
    RecordManager.State = JobObject.State;
    RecordManager.CreatedAt = CurrentUniversalDateInMilliseconds();
    RecordManager.PerformanceDuration = EndTime - StartTime; 
    RecordManager.Write();
    
EndProcedure // RecordJobPerformanceMetrics()

// Only for internal use.
//
Function StreamObjectCached(Cache, Guid)
    
    StreamObject = Cache.Get(Guid);   
    If StreamObject = Undefined Then
        StreamObject = FL_InteriorUse.NewFormatProcessor(Guid);
        Cache.Insert(Guid, StreamObject);
    EndIf;
    
    Return StreamObject;
    
EndFunction // StreamObjectCached()

// Only for internal use.
//
Function NewProperties(JobProperties, Resources)
    
    Properties = New Structure;
    Properties.Insert("JobProperties", JobProperties);
    For Each Resource In Resources Do
        Properties.Insert(Resource.FieldName, Resource.FieldValue);        
    EndDo;
    
    Return Properties;
    
EndFunction // NewProperties()

// Only for internal use.
//
Function NewJobProperties()
    
    JobProperties = New Structure;
    JobProperties.Insert("ContentType");
    JobProperties.Insert("ContentEncoding");
    JobProperties.Insert("CurrentState", Catalogs.FL_States.Succeeded);
    JobProperties.Insert("FileExtension");
    JobProperties.Insert("Job");
    JobProperties.Insert("InvocationContext");
    JobProperties.Insert("MetadataObject");
    JobProperties.Insert("Operation");
    JobProperties.Insert("Owner");
    JobProperties.Insert("ReadonlyStream");
    
    Return JobProperties;
    
EndFunction // NewJobProperties()

// Only for internal use.
//
Function QueryTextSubscribersData()

    QueryText = "
        |SELECT
        |   Channels.Ref AS Owner,
        |   Channels.Channel AS Channel,
        |   Channels.Operation AS Operation
        |INTO ChannelsCache
        |FROM
        |   Catalog.FL_Exchanges.Channels AS Channels
        |WHERE
        |    Channels.Ref = &Owner
        |AND Channels.Operation = &Operation
        |
        |INDEX BY
        |   Owner   
        |;
        |
        |////////////////////////////////////////////////////////////////////////////////
        |SELECT
        |   Channels.Channel AS Channel,
        |   Operations.DataCompositionSchema AS DataCompositionSchema
        |FROM
        |   ChannelsCache AS Channels
        |
        |INNER JOIN Catalog.FL_Exchanges.Operations AS Operations
        |ON  Operations.Ref = Channels.Owner
        |AND Operations.Operation = Channels.Operation
        |;
        |
        |////////////////////////////////////////////////////////////////////////////////
        |SELECT 
        |   ChannelResources.Channel        AS Channel,
        |   ChannelResources.ExecutableCode AS ExecutableCode,
        |   ChannelResources.FieldName      AS FieldName,
        |   ChannelResources.FieldValue     AS FieldValue
        |FROM
        |   Catalog.FL_Exchanges.ChannelResources AS ChannelResources   
        |
        |INNER JOIN ChannelsCache AS Channels
        |ON  Channels.Owner = ChannelResources.Ref
        |AND Channels.Channel = ChannelResources.Channel
        |AND Channels.Operation = ChannelResources.Operation
        |;
        |";
    Return QueryText;
    
EndFunction // QueryTextSubscribersData()

#EndRegion // ServiceProceduresAndFunctions

#EndIf