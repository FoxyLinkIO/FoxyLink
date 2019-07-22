﻿////////////////////////////////////////////////////////////////////////////////
// This file is part of FoxyLink.
// Copyright © 2016-2019 Petro Bazeliuk.
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

// Routes message or messages to exchanges and app endpoints.
//
// Parameters:
//  Source      - Structure, FixedStructure - see function Catalogs.FL_Messages.NewInvocation.
//              - CatalogRef.FL_Messages    - a single message to route.
//              - Array                     - a list of messages to route.
//                      Default value: Undefined.
//  Exchange    - CatalogRef.FL_Exchanges   - a routing exchange.
//                      Default value: Undefined.
//  AppEndpoint - CatalogRef.FL_Channels    - a receiver channel.
//                      Default value: Undefined.
//  ReRoute     - Boolean                   - if True, reroutes message or messages.
//                      Default value: False.
//
Procedure Route(Source = Undefined, Exchange = Undefined, 
    AppEndpoint = Undefined, ReRoute = False) Export
    
    Messages = Messages(Source);
    For Each Message In Messages Do
        
        If NOT ReRoute AND FL_CommonUse.ObjectAttributeValue(Message, "Routed") Then
            Continue;
        EndIf;
        
        Try
            
            BeginTransaction();
            
            MessageObject = Message.GetObject();
            MessageObject.Routed = True;
            RouteToEndpoints(MessageObject, Exchange, AppEndpoint);
            
            MessageObject.Write();
            
            CommitTransaction();    
            
        Except
            
            RollbackTransaction();
            
            FL_InteriorUse.WriteLog("FoxyLink.Integration.Route",
                EventLogLevel.Error,
                Metadata.Catalogs.FL_Messages,
                ErrorDescription());        
            
        EndTry;
                
    EndDo;
    
EndProcedure // Route()

// Routes and runs a message to exchanges and app endpoints.
//
// Parameters:
//  Source      - Structure, FixedStructure - see function Catalogs.FL_Messages.NewInvocation.
//              - CatalogRef.FL_Messages    - a single message to route.
//  Exchange    - CatalogRef.FL_Exchanges   - a routing exchange.
//                      Default value: Undefined.
//  AppEndpoint - CatalogRef.FL_Channels    - a receiver channel.
//                      Default value: Undefined.
//  JobResult   - Structure                 - returns the copy of last job result execution.
//                                            See function Catalogs.FL_Jobs.NewJobResult.
//                      Default value: Undefined.
//
Procedure RouteAndRun(Source, Exchange = Undefined, 
    AppEndpoint = Undefined, JobResult = Undefined) Export

    Message = GetMessage(Source);
    
    MessageObject = Message.GetObject();
    MessageObject.Routed = True;
    RouteToEndpoints(MessageObject, Exchange, AppEndpoint, True);
    
    For Each Row In MessageObject.Exchanges Do
        Catalogs.FL_Jobs.Trigger(Row.Job, True, JobResult);    
    EndDo;
    
    MessageObject.Write();   
    
EndProcedure // RouteAndRun()    

// Returns an output result of message that is delivered into exchange and 
// app endpoint if it's set.
//
// Parameters:
//  Source      - Structure, FixedStructure - see function Catalogs.FL_Messages.NewInvocation.
//              - CatalogRef.FL_Messages    - a single message to get result.
//  Exchange    - CatalogRef.FL_Exchanges   - a routing exchange.
//  AppEndpoint - CatalogRef.FL_Channels    - a receiver channel.
//                      Default value: Null.
//
// Returns:
//  Structure - see function Catalogs.FL_Jobs.NewJobResult.  
//
Function RouteAndRunOutputResult(Source, Exchange, AppEndpoint = Null) Export
    
    // Copy of the job result, see function Catalogs.FL_Jobs.NewJobResult.
    JobResult = Catalogs.FL_Jobs.NewJobResult();
    
    If TransactionActive() Then
        
        Message = GetMessage(Source);
        RouteAndRun(Message, Exchange, AppEndpoint, JobResult);    
        
    Else
        
        Try
        
            BeginTransaction();
            
            Message = GetMessage(Source);
            RouteAndRun(Message, Exchange, AppEndpoint, JobResult); 
            
            CommitTransaction();
        
        Except
            
            RollbackTransaction();
            
            ErrorMessage = ErrorDescription();
            FL_InteriorUse.WriteLog("FoxyLink.Integration.RouteAndRunResult",
                EventLogLevel.Error,
                Metadata.Catalogs.FL_Messages,
                ErrorMessage);
                
            // Move message up in stack 
            Raise ErrorMessage;
            
        EndTry;
        
    EndIf;
    
    Return JobResult;
    
EndFunction // RouteAndRunOutputResult()

// Creates a message based on a given event object call expression.
//
// Parameters:
//  Invocation - Structure - see function Catalogs.FL_Messages.NewInvocation. 
//
// Returns:
//  CatalogRef.FL_Messages - ref to created message or Undefined, if it was not created.
//
Function Create(Invocation) Export
    
    If TransactionActive() Then
        
        // Creates a message
        Message = CreateMessage(Invocation);
        
    Else
        
        Try
        
            BeginTransaction();
            
            // Creates a message in transaction
            Message = CreateMessage(Invocation);
            
            CommitTransaction();
        
        Except
            
            RollbackTransaction();
            
            FL_InteriorUse.WriteLog("FoxyLink.Integration.Create",
                EventLogLevel.Error,
                Metadata.Catalogs.FL_Messages,
                ErrorDescription());
            
        EndTry;
        
    EndIf;
        
    Return Message;  
    
EndFunction // Create()

#EndRegion // ProgramInterface

#Region ServiceInterface

// Adds data to invocation context.
//
// Parameters:
//  Context    - ValueTable - see function FL_BackgroundJob.NewContext. 
//  PrimaryKey - String     - the name of primary key.
//  Value      - Arbitrary  - the value of primary key.
//  Filter     - Boolean    - defines if primary key is used.
//                  Default value: False.
//
Procedure AddToContext(Context, PrimaryKey, Value, 
    Filter = False) Export
      
    NewContextItem = Context.Add();
    NewContextItem.Filter = Filter;
    NewContextItem.PrimaryKey = Upper(PrimaryKey);
    NewContextItem.XMLValue = XMLString(Value);
   
    XMLDataType = XMLTypeOf(Value);
    If XMLDataType <> Undefined Then
        FillPropertyValues(NewContextItem, XMLTypeOf(Value));
    EndIf;
    
EndProcedure // AddToContext()

// Fills invocation context data.
//
// Parameters:
//  Source     - Arbitrary - source object.
//  Invocation - Structure - see function Catalogs.FL_Messages.NewInvocation. 
//
Procedure FillContext(Source, Invocation) Export
    
    EventSource = Invocation.EventSource;
    If FL_CommonUseReUse.IsReferenceTypeObjectCached(EventSource) Then
        
        AddToContext(Invocation.Context, "Ref", Source.Ref, True); 
        
    ElsIf FL_CommonUseReUse.IsInformationRegisterTypeObjectCached(EventSource)
        OR FL_CommonUseReUse.IsAccumulationRegisterTypeObjectCached(EventSource) Then

        PrimaryKeys = FL_CommonUse.PrimaryKeysByMetadataObject(
            Source.Metadata());
        
        FillRegisterContext(Invocation.Context, Source.Filter, PrimaryKeys, 
            Source.Unload());
              
    EndIf;
    
    // Do not change this line. It is easy to break passing by reference.
    FL_CommonUse.RemoveDuplicatesFromValueTable(Invocation.Context);
    
EndProcedure // FillContext()

// Fills accumulation register invocation context.
//
// Parameters:
//  Context         - ValueTable - see function Catalogs.FL_Messages.NewContext.
//  Filter          - Filter     - it contains the object Filter, for which 
//                                  current filtration of records is performed.
//  PrimaryKeys     - Structure  - see function FL_CommonUse.PrimaryKeysByMetadataObject.
//  AttributeValues - ValueTable - value table with primary keys values.
//
Procedure FillRegisterContext(Context, Filter, PrimaryKeys, 
    AttributeValues) Export
    
    SynonymsEN = FL_CommonUseReUse.StandardAttributeSynonymsEN();
    For Each PrimaryKey In PrimaryKeys Do
            
        FilterValue = Filter.Find(PrimaryKey.Key);
        If FilterValue <> Undefined AND FilterValue.Use Then
            AddToContext(Context, PrimaryKey.Key, FilterValue.Value, 
                FilterValue.Use);
            Continue;
        EndIf;
        
        KeyName = PrimaryKey.Key;
        Column = AttributeValues.Columns.Find(KeyName);
        If Column = Undefined Then
            KeyName = SynonymsEN.Get(Upper(PrimaryKey.Key));        
        EndIf;
        
        ColumnValues = AttributeValues.UnloadColumn(KeyName);
        For Each ColumnValue In ColumnValues Do
            AddToContext(Context, PrimaryKey.Key, ColumnValue);   
        EndDo;
        
    EndDo;    
    
EndProcedure // FillRegisterContext()
 
// Returns deserialized context value if exists.
//
// Parameters:
//  PrimaryKey - String    - the name of primary key.
//  Properties - Structure - see function Catalogs.FL_Exchanges.NewProperties.
//  JobResult  - Structure - see function Catalogs.FL_Jobs.NewJobResult.
//                      Default value: Undefined.
//
// Returns:
//  Arbitrary - deserialized context value if exists.
//  Undefined - context value is absent.
//
Function ContextValue(PrimaryKey, Properties, JobResult = Undefined) Export
    
    Context = DeserializeContext(Properties.MessageId);
    If Context = Undefined OR Context.Count() = 0 Then  
        
        ErrorDescription = StrTemplate(FL_ErrorsClientServer
            .ErrorFailedToProcessMessageContext(), Properties.MessageId);
        FL_InteriorUse.WriteLog("FoxyLink.Integration.ContextValue",
            EventLogLevel.Error,
            Metadata.Catalogs.FL_Messages,
            ErrorDescription,
            JobResult);
        Return Undefined;
                
    EndIf;
        
    SearchResult = Context.Find(PrimaryKey, "PrimaryKey");
    If SearchResult = Undefined Then
        
        ErrorDescription = FL_ErrorsClientServer.ErrorKeyIsMissingInObject(
            "Context", Context, PrimaryKey);
        FL_InteriorUse.WriteLog("FoxyLink.Integration.ContextValue",
            EventLogLevel.Error,
            Metadata.Catalogs.FL_Messages,
            ErrorDescription,
            JobResult);
        Return Undefined;
        
    EndIf;
    
    Return SearchResult.Value;
    
EndFunction // ContextValue()

// Returns deserialized context value if exists or undefined.
//
// Parameters:
//  PrimaryKey - String    - the name of primary key.
//  Properties - Structure - see function Catalogs.FL_Exchanges.NewProperties.
//
// Returns:
//  Arbitrary - deserialized context value if exists.
//  Undefined - context value is absent.
//
Function ContextValueNoException(PrimaryKey, Properties) Export

    Var MessageId;

    If TypeOf(Properties) <> Type("Structure") 
        OR NOT Properties.Property("MessageId", MessageId) Then
        Return Undefined;
    EndIf;

    Context = DeserializeContext(MessageId);
    If Context = Undefined OR Context.Count() = 0 Then  
        Return Undefined;      
    EndIf;
        
    SearchResult = Context.Find(PrimaryKey, "PrimaryKey");
    If SearchResult = Undefined Then
        Return Undefined;
    EndIf;
    
    Return SearchResult.Value;
    
EndFunction // ContextValueNoException()

// Deserializes a message tabular section or payload into context call.
//
// Parameters:
//  Message - CatalogRef.FL_Messages - reference to the message.
//          - String                 - message id.
//
// Returns:
//  Arbitrary - deserialized context.
//  Undefined - context is absent.
//
Function DeserializeContext(Val Message) Export
    
    If TypeOf(Message) = TypeOf("String") Then
        Message = FL_CommonUse.ReferenceByCode(Metadata.Catalogs.FL_Messages, 
            Message);     
    EndIf;
    
    Query = New Query;
    Query.Text = QueryTextMessageContext();
    Query.SetParameter("Message", Message);
    QueryResult = Query.Execute();
    If NOT QueryResult.IsEmpty() Then
        
        Context = QueryResult.Unload();
        JoinContextValueColumn(Context);
        Return Context; 
        
    EndIf;
    
    Query.Text = QueryTextMessagePayload();
    QueryResult = Query.Execute();
    If QueryResult.IsEmpty() Then
        Return Undefined;    
    EndIf;
    
    QueryResult = QueryResult.Select();
    QueryResult.Next();
    
    Payload = QueryResult.Payload.Get();
    If TypeOf(Payload) = Type("Structure") 
        OR TypeOf(Payload) = Type("FixedStructure") Then
        Return Payload;    
    EndIf;
    
    If TypeOf(Payload) <> Type("BinaryData") Then
        Return Undefined;
    EndIf;
    
    If Payload.Size() = 0 Then
        Return Undefined;
    EndIf;
    
    // #110 https://github.com/FoxyLinkIO/FoxyLink/issues/110
    JSONReader = New JSONReader;
    JSONReader.OpenStream(Payload.OpenStreamForRead(), 
        QueryResult.ContentEncoding);
    Context = ReadJSON(JSONReader);
    JSONReader.Close();
    
    Return Context;
    
EndFunction // DeserializeContext()

// Defines if event is a publisher.
//
// Parameters:
//  EventSource - String - the full name of a event object as a term.
//
// Returns:
//  Boolean - True, if it is publisher, otherwise False.
//
Function IsPublisher(EventSource) Export
    
    Query = New Query;
    Query.Text = QueryTextIsPublisher();
    Query.SetParameter("EventSource", EventSource);
    Return NOT Query.Execute().IsEmpty();
    
EndFunction // IsPublisher()

// Defines if event is a message publisher.
//
// Parameters:
//  EventSource - String                   - the full name of a event object as a term.
//  Operation   - CatalogRef.FL_Operations - reference to the FL_Operations catalog.
//              - String                   - item name of FL_Operations catalog.
//
// Returns:
//  Boolean - True, if it is message publisher, otherwise False.
//
Function IsMessagePublisher(EventSource, Operation) Export
    
    OperationRef = Operation;
    If TypeOf(OperationRef) = Type("String") Then
        OperationRef = FL_CommonUse.ReferenceByDescription(
            Metadata.Catalogs.FL_Operations, OperationRef);
    EndIf;
    
    Query = New Query;
    Query.Text = QueryTextIsMessagePublisher();
    Query.SetParameter("EventSource", EventSource);
    Query.SetParameter("Operation", OperationRef);
    
    Return NOT Query.Execute().IsEmpty();
    
EndFunction // IsMessagePublisher()

// Returns a new invocation data for a service method.
//
// Returns:
//  Structure - the invocation data structure with keys:
//      * AppId             - String                   - identifier of the application
//                                              that produced the message.
//                                      Default value: "ThisConfiguration".
//      * ContentEncoding   - String                   - message content encoding.
//                                      Default value: "UTF-8". 
//      * ContentType       - String                   - message content type.
//                                      Default value: "1C:Enterprise".
//      * EventSource       - String                   - provides access to the 
//                                              event source object name.
//                                      Default value: "".
//      * MessageId         - String                   - message identifier as a string. 
//                                              If applications need to identify messages.
//      * Operation         - CatalogReg.FL_Operations - the type of change experienced.
//      * Payload           - Arbitrary                - invocation payload.
//      * Routed            - Boolean                  - shows if message was routed.
//                                      Default value: Boolean.
//      * Timestamp         - Number                   - timestamp of the moment 
//                                              when message was created.
//      * UserId            - String                   - user identifier.
//      * InvocationContext - ValueTable               - invocation context.
//      * SessionContext    - ValueTable               - session context.
//      * Source            - AnyRef                   - an event source object.
//                                      Default value: Undefined.
//
Function NewInvocation() Export
    
    Invocation = New Structure;
    
    // Attributes section
    Invocation.Insert("AppId", FL_InteriorUseReUse.AppIdentifier());
    Invocation.Insert("ContentEncoding", "UTF-8");
    Invocation.Insert("ContentType", "1C:Enterprise");
    Invocation.Insert("CorrelationId");
    Invocation.Insert("EventSource", "");
    Invocation.Insert("Operation");
    Invocation.Insert("Payload");
    Invocation.Insert("ReplyTo");
    Invocation.Insert("Routed", False);
    Invocation.Insert("Timestamp", CurrentUniversalDateInMilliseconds());
    Invocation.Insert("UserId", InfoBaseUsers.CurrentUser());
    
    // Tabular section
    TabularSections = Metadata.Catalogs.FL_Messages.TabularSections;
    Context = FL_CommonUse.NewMockOfMetadataObjectAttributes(
        TabularSections.Context);
    Context.Columns.Delete("LINENUMBER");
    Invocation.Insert("Context", Context);
    Invocation.Insert("SessionContext", FL_CommonUse
        .NewMockOfMetadataObjectAttributes(TabularSections.SessionContext));

    // Technical section
    Invocation.Insert("Source", Undefined);
    
    Return Invocation;
    
EndFunction // NewInvocation()

#EndRegion // ServiceInterface

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
Function CreateMessage(Invocation)
    
    Var Context, SessionContext;
        
    MessageObject = Catalogs.FL_Messages.CreateItem();
    MessageObject.SetNewCode();
    FillPropertyValues(MessageObject, Invocation);
    
    If Invocation.Property("Context", Context) 
        AND TypeOf(Context) = Type("ValueTable") Then
        MessageObject.Context.Load(Context);
    EndIf;
    
    If Invocation.Property("SessionContext", SessionContext) 
        AND TypeOf(SessionContext) = Type("ValueTable") Then
        MessageObject.SessionContext.Load(SessionContext);
    EndIf;
    
    MessageObject.Write();
        
    If Invocation.Payload <> Undefined Then
        
        MaxDeflation = 9;
        RecordManager = InformationRegisters.FL_MessagePayload
            .CreateRecordManager();
        RecordManager.Message = MessageObject.Ref;
        RecordManager.Payload = New ValueStorage(Invocation.Payload, 
            New Deflation(MaxDeflation));
        RecordManager.Write();
        
    EndIf;
    
    Return MessageObject.Ref;
    
EndFunction // CreateMessage()

// Only for internal use.
//
Procedure RouteToEndpoints(Source, Exchange, AppEndpoint, RouteAndRun = False)
    
    ExchangeEndpoints = ExchangeEndpoints(Source, Exchange);  
    For Each Endpoint In ExchangeEndpoints Do
        
        // Checks whether message is passed through event filter 
        If NOT PassedByEventFilter(Source, Endpoint) Then
            Continue;
        EndIf;
        
        JobData = FL_BackgroundJob.NewJobData();
        JobData.Invoke = Endpoint.Invoke;
        JobData.Isolated = Endpoint.Isolated;
        JobData.MethodName = Endpoint.EventHandler;
        JobData.Priority = Endpoint.Priority;
        JobData.Transactional = Endpoint.Transactional;
        If RouteAndRun Then
            JobData.State = Catalogs.FL_States.Processing;    
        EndIf;
        
        InputParameter = JobData.Input.Add();
        InputParameter.Name = "Exchange";
        InputParameter.Value = Endpoint.Exchange;
        
        InputParameter = JobData.Input.Add();
        InputParameter.Name = "Message";
        InputParameter.Value = Source.Ref;
        
        ExchangeJob = FL_BackgroundJob.Enqueue(JobData);
        NewRow = Source.Exchanges.Add();
        NewRow.Exchange = Endpoint.Exchange;
        NewRow.Job = ExchangeJob;
        
        If AppEndpoint <> Null Then
            RouteToAppEndpoints(Source, Endpoint.Exchange, AppEndpoint, 
                ExchangeJob);
        EndIf;
        
    EndDo;
    
EndProcedure // RouteToEndpoints()

// Only for internal use.
//
Procedure RouteToAppEndpoints(Source, Exchange, AppEndpoint, ExchangeJob)
    
    AppIndex = 1;
    ResourceIndex = 2;
    
    BatchResult = AppEndpoints(Source, Exchange, AppEndpoint);
    AppEndpoints = BatchResult[AppIndex].Unload();
    AppResources = BatchResult[ResourceIndex].Unload();
    
    Filter = New Structure("AppEndpoint");
    For Each TableRow In AppEndpoints Do
        
        AppProperties = Catalogs.FL_Channels.NewAppEndpointProperties();
        AppProperties.AppEndpoint = TableRow.AppEndpoint;
        
        Filter.AppEndpoint = TableRow.AppEndpoint;
        FillAppResources(Source, AppProperties, AppResources.FindRows(Filter));
        
        JobData = FL_BackgroundJob.NewJobData();
        JobData.Invoke = TableRow.Invoke;
        JobData.Isolated = TableRow.Isolated;
        JobData.MethodName = "Catalogs.FL_Channels.ProcessMessage";
        JobData.Priority = TableRow.Priority;
        JobData.State = Catalogs.FL_States.Awaiting;

        InputParameter = JobData.Input.Add();
        InputParameter.Name = "AppProperties";
        InputParameter.Value = AppProperties;
        
        AppEndpointJob = FL_BackgroundJob.ContinueWith(ExchangeJob, JobData);
        NewRow = Source.AppEndpoints.Add();
        NewRow.Endpoint = TableRow.AppEndpoint;
        NewRow.Exchange = Exchange;
        NewRow.Job = AppEndpointJob;
       
    EndDo;
    
EndProcedure // RouteToAppEndpoints()

// Only for internal use.
//
Procedure FillAppResources(Source, AppProperties, AppResources)
    
    For Each AppResource In AppResources Do
        
        NewResource = AppProperties.AppResources.Add();
        FillPropertyValues(NewResource, AppResource);
        
        If AppResource.ExecutableCode Then
               
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
                AppResource.FieldValue);
                
            Try
                
                FL_RunInSafeMode.ExecuteInSafeMode(Algorithm, 
                    ExecutableParams);
                    
                NewResource.FieldValue = ExecutableParams.Result;
                
            Except

                FL_InteriorUse.WriteLog("FoxyLink.Integration.FillAppResources", 
                    EventLogLevel.Error,
                    Metadata.Catalogs.FL_Messages,
                    ErrorDescription());
                     
            EndTry;
                
        EndIf;
                    
    EndDo;    
    
EndProcedure // FillAppResources()

// Only for internal use.
//
Procedure JoinContextValueColumn(Context)
    
    Context.Columns.Add("Value");
    For Each Row In Context Do
        Row.Value = FL_CommonUse.ValueFromXMLTypeAndValue(Row.XMLValue, 
            Row.TypeName, Row.NamespaceURI);     
    EndDo;
    
EndProcedure // JoinContextValueColumn()

// Only for internal use.
//
Function GetMessage(Source)
    
    If TypeOf(Source) = Type("CatalogRef.FL_Messages") Then
        
        Return Source;
        
    ElsIf TypeOf(Source) = Type("Structure") 
        OR TypeOf(Source) = Type("FixedStructure") Then
        
        Return Create(Source);
        
    Else
        
        ErrorMessage = FL_ErrorsClientServer.ErrorTypeIsDifferentFromExpected(
            "Source", Source, Type("CatalogRef.FL_Messages"));
        Raise ErrorMessage;
        
    EndIf;
        
EndFunction // GetMessage()

// Only for internal use.
//
Function Messages(Source)
    
    Messages = New Array;
    If TypeOf(Source) = Type("Array") Then
        
        Messages = FL_CommonUseClientServer.CopyArray(Source); 
        
    ElsIf TypeOf(Source) = Type("CatalogRef.FL_Messages") Then
        
        Messages.Add(Source);
        
    ElsIf TypeOf(Source) = Type("Structure") 
        OR TypeOf(Source) = Type("FixedStructure") Then
        
        Messages.Add(Create(Source));
        
    Else         
        
        Query = New Query;
        Query.Text = QueryTextMessages();
        QueryResult = Query.Execute();
        If NOT QueryResult.IsEmpty() Then
            Messages = QueryResult.Unload().UnloadColumn("Message");
        EndIf;
        
    EndIf;
    
    Return Messages;
        
EndFunction // Messages()

// Only for internal use.
//
Function ExchangeEndpoints(Source, Exchange)
    
    Query = New Query;
    Query.Text = QueryTextExchangeEndpoints();
    Query.SetParameter("EventSource", Source.EventSource);
    Query.SetParameter("Operation", Source.Operation);
        
    If Exchange <> Undefined Then 
        Query.Text = QueryTextExchangeEndpoint();
        Query.SetParameter("Exchange", Exchange);
        Query.SetParameter("EventHandler", "Catalogs.FL_Exchanges.ProcessMessage");
    EndIf;
    
    Return Query.Execute().Unload();
        
EndFunction // ExchangeEndpoints()

// Only for internal use.
//
Function PassedByEventFilter(Source, Endpoint)
    
    FilterPassed = True;
    FilterNotPassed = False;
    
    // Event source isn't set or unknown. 
    If Endpoint.EventFilterDCSchema = Undefined
        OR Endpoint.EventFilterDCSettings = Undefined Then
        Return FilterPassed;
    EndIf;
    
    DataCompositionSchema = Endpoint.EventFilterDCSchema.Get();
    DataCompositionSettings = Endpoint.EventFilterDCSettings.Get();
    
    // Event filter isn't set.
    If TypeOf(DataCompositionSchema) <> Type("DataCompositionSchema") Then
        Return FilterPassed;
    EndIf;
    
    If Source.Context.Count() <> 0 Then
        Context = Source.Context.Unload();
        JoinContextValueColumn(Context);
    Else
        // HTTP endpoint context.
        Context = DeserializeContext(Source.Ref);    
    EndIf;
    
    Settings = Catalogs.FL_Exchanges.NewExchangeSettings();
    Settings.DataCompositionSchema = DataCompositionSchema;
    Settings.DataCompositionSettings = DataCompositionSettings;
    
    OutputParameters = Catalogs.FL_Exchanges.NewOutputParameters(Settings, 
        Context);
        
    ValueTable = New ValueTable;
    FL_DataComposition.OutputInValueCollection(ValueTable, OutputParameters);    
    If ValueTable.Count() > 0 Then
        Return FilterPassed;
    EndIf;
    
    Return FilterNotPassed;
    
EndFunction // PassedByEventFilter()

// Only for internal use.
//
Function AppEndpoints(Source, Exchange, AppEndpoint)
        
    Query = New Query;
    Query.Text = QueryTextAppEndpoints();
    Query.SetParameter("Exchange", Exchange);
    Query.SetParameter("Operation", Source.Operation);
    
    If AppEndpoint <> Undefined Then 
        Query.Text = QueryTextAppEndpoint();
        Query.SetParameter("AppEndpoint", AppEndpoint);
    EndIf;
    
    Return Query.ExecuteBatch();
    
EndFunction // AppEndpoints()

// Only for internal use.
//
Function QueryTextIsPublisher()

    QueryText = "
        |SELECT 
        |   MessagePublishers.EventSource AS EventSource
        |FROM
        |   InformationRegister.FL_MessagePublishers AS MessagePublishers 
        |WHERE
        |   MessagePublishers.EventSource = &EventSource
        |AND MessagePublishers.InUse
        |";
    Return QueryText;
    
EndFunction // QueryTextIsPublisher()

// Only for internal use.
//
Function QueryTextIsMessagePublisher()

    QueryText = "
        |SELECT 
        |   MessagePublishers.EventSource AS EventSource,
        |   MessagePublishers.Operation AS Operation,
        |   MessagePublishers.InUse AS InUse
        |FROM
        |   InformationRegister.FL_MessagePublishers AS MessagePublishers 
        |WHERE
        |   MessagePublishers.EventSource = &EventSource
        |AND MessagePublishers.Operation = &Operation
        |AND MessagePublishers.InUse
        |";
    Return QueryText;
    
EndFunction // QueryTextIsMessagePublisher()

// Only for internal use.
//
Function QueryTextMessages()

    QueryText = "
        |SELECT 
        |   Messages.Ref AS Message
        |
        |FROM
        |   Catalog.FL_Messages AS Messages 
        |
        |WHERE
        |   NOT Messages.Routed
        |
        |ORDER BY
        |   Messages.Timestamp ASC
        |";
    Return QueryText;
    
EndFunction // QueryTextMessages()

// Only for internal use.
//
Function QueryTextExchangeEndpoint()

    QueryText = "
        |SELECT 
        |   Exchanges.Ref AS Exchange,
        |   IsNull(OperationTable.Invoke, False) AS Invoke,
        |   IsNull(OperationTable.Isolated, False) AS Isolated,
        |   IsNull(OperationTable.Priority, 5) AS Priority,
        |   IsNull(EventTable.EventFilterDCSchema, Undefined) AS EventFilterDCSchema,
        |   IsNull(EventTable.EventFilterDCSettings, Undefined) AS EventFilterDCSettings,
        |   IsNull(EventTable.EventHandler, &EventHandler) AS EventHandler,
        |   IsNull(EventTable.Transactional, False) AS Transactional
        |FROM
        |   Catalog.FL_Exchanges AS Exchanges 
        |
        |LEFT JOIN Catalog.FL_Exchanges.Events AS EventTable
        // [OPPX|OPHP1 +] Attribute + Ref
        |ON  EventTable.MetadataObject = &EventSource
        |AND EventTable.Ref            = Exchanges.Ref
        |AND EventTable.Operation      = &Operation
        |
        |LEFT JOIN Catalog.FL_Exchanges.Operations AS OperationTable
        |ON  OperationTable.Ref = Exchanges.Ref
        |AND OperationTable.Operation = &Operation 
        |
        |WHERE
        |   Exchanges.Ref = &Exchange    
        |
        |ORDER BY
        |   IsNull(OperationTable.Priority, 5) ASC
        |";
    Return QueryText;
    
EndFunction // QueryTextExchangeEndpoint()

// Only for internal use.
//
Function QueryTextExchangeEndpoints()

    QueryText = "
        |SELECT 
        |   Exchanges.Ref AS Exchange,
        |   IsNull(OperationTable.Invoke, False) AS Invoke,
        |   IsNull(OperationTable.Isolated, False) AS Isolated, 
        |   IsNull(OperationTable.Priority, 5) AS Priority,
        |   EventTable.EventFilterDCSchema AS EventFilterDCSchema,
        |   EventTable.EventFilterDCSettings AS EventFilterDCSettings,
        |   EventTable.EventHandler AS EventHandler,
        |   EventTable.Transactional AS Transactional
        |FROM
        |   Catalog.FL_Exchanges AS Exchanges 
        |
        |INNER JOIN Catalog.FL_Exchanges.Events AS EventTable
        // [OPPX|OPHP1 +] Attribute + Ref
        |ON  EventTable.MetadataObject = &EventSource
        |AND EventTable.Ref            = Exchanges.Ref
        |AND EventTable.Operation      = &Operation
        |
        |LEFT JOIN Catalog.FL_Exchanges.Operations AS OperationTable
        |ON  OperationTable.Ref = Exchanges.Ref
        |AND OperationTable.Operation = &Operation 
        |
        |WHERE
        |   Exchanges.InUse
        |
        |ORDER BY
        |   IsNull(OperationTable.Priority, 5) ASC
        |";
    Return QueryText;
    
EndFunction // QueryTextExchangeEndpoints()

// Only for internal use.
//
Function QueryTextAppEndpoint()
    
    QueryText = "
        |SELECT
        |   &Exchange AS Ref,
        |   &AppEndpoint AS AppEndpoint,
        |   &Operation AS Operation
        |INTO AppEndpointsCache
        |
        |INDEX BY
        |   AppEndpoint
        |;
        |
        |////////////////////////////////////////////////////////////////////////////////
        |SELECT
        |   AppEndpoints.AppEndpoint AS AppEndpoint,
        |   IsNull(Operations.Invoke, False) AS Invoke,
        |   IsNull(Operations.Isolated, False) AS Isolated,
        |   IsNull(Operations.Priority, 5) AS Priority
        |FROM
        |   AppEndpointsCache AS AppEndpoints
        |
        |LEFT JOIN Catalog.FL_Exchanges.Operations AS Operations
        |ON  Operations.Ref = AppEndpoints.Ref
        |AND Operations.Operation = AppEndpoints.Operation
        |;
        |
        |////////////////////////////////////////////////////////////////////////////////
        |SELECT 
        |   ChannelResources.Channel        AS AppEndpoint,
        |   ChannelResources.ExecutableCode AS ExecutableCode,
        |   ChannelResources.FieldName      AS FieldName,
        |   ChannelResources.FieldValue     AS FieldValue
        |FROM
        |   Catalog.FL_Exchanges.ChannelResources AS ChannelResources   
        |
        |INNER JOIN AppEndpointsCache AS AppEndpoints
        |ON  AppEndpoints.Ref = ChannelResources.Ref
        |AND AppEndpoints.AppEndpoint = ChannelResources.Channel
        |AND AppEndpoints.Operation = ChannelResources.Operation
        |;
        |
        |////////////////////////////////////////////////////////////////////////////////
        |DROP AppEndpointsCache
        |;
        |";
    
    Return QueryText;  
    
EndFunction // QueryTextAppEndpoint()

// Only for internal use.
//
Function QueryTextAppEndpoints()
    
    QueryText = "
        |SELECT
        |   AppEndpoints.Ref AS Ref,
        |   AppEndpoints.Channel AS AppEndpoint,
        |   AppEndpoints.Operation AS Operation
        |INTO AppEndpointsCache
        |FROM
        |   Catalog.FL_Exchanges.Channels AS AppEndpoints
        |WHERE
        |    AppEndpoints.Ref = &Exchange
        |AND AppEndpoints.Operation = &Operation
        |
        |INDEX BY
        |   AppEndpoints.Ref   
        |;
        |
        |////////////////////////////////////////////////////////////////////////////////
        |SELECT
        |   AppEndpoints.AppEndpoint AS AppEndpoint,
        |   Operations.Invoke AS Invoke,
        |   Operations.Isolated AS Isolated,
        |   Operations.Priority AS Priority
        |FROM
        |   AppEndpointsCache AS AppEndpoints
        |
        |INNER JOIN Catalog.FL_Exchanges.Operations AS Operations
        |ON  Operations.Ref = AppEndpoints.Ref
        |AND Operations.Operation = AppEndpoints.Operation
        |;
        |
        |////////////////////////////////////////////////////////////////////////////////
        |SELECT 
        |   ChannelResources.Channel        AS AppEndpoint,
        |   ChannelResources.ExecutableCode AS ExecutableCode,
        |   ChannelResources.FieldName      AS FieldName,
        |   ChannelResources.FieldValue     AS FieldValue
        |FROM
        |   Catalog.FL_Exchanges.ChannelResources AS ChannelResources   
        |
        |INNER JOIN AppEndpointsCache AS AppEndpoints
        |ON  AppEndpoints.Ref = ChannelResources.Ref
        |AND AppEndpoints.AppEndpoint = ChannelResources.Channel
        |AND AppEndpoints.Operation = ChannelResources.Operation
        |;
        |
        |////////////////////////////////////////////////////////////////////////////////
        |DROP AppEndpointsCache
        |;
        |";
    
    Return QueryText;  
    
EndFunction // QueryTextAppEndpoints()

// Only for internal use.
//
Function QueryTextMessageContext()
    
    QueryText = "
        |SELECT
        |   MessageContext.Filter AS Filter,
        |   MessageContext.NamespaceURI AS NamespaceURI,
        |   MessageContext.PrimaryKey AS PrimaryKey,
        |   MessageContext.TypeName AS TypeName,
        |   MessageContext.XMLValue AS XMLValue
        |FROM 
        |   Catalog.FL_Messages.Context AS MessageContext
        |WHERE
        |   MessageContext.Ref = &Message  
        |";
    Return QueryText;
    
EndFunction // QueryTextMessageContext()

// Only for internal use.
//
Function QueryTextMessagePayload()
    
    QueryText = "
        |SELECT
        |   MessagePayload.Message.ContentEncoding AS ContentEncoding,
        |   MessagePayload.Message.ContentType AS ContentType,
        |   MessagePayload.Payload AS Payload
        |FROM 
        |   InformationRegister.FL_MessagePayload AS MessagePayload
        |WHERE
        |   MessagePayload.Message = &Message  
        |";
    Return QueryText;
    
EndFunction // QueryTextMessagePayload()
    
#EndRegion // ServiceProceduresAndFunctions

#EndIf