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

#Region ProgramInterface

// Creates a new fire-and-forget job based on a given method call expression.
//
// Parameters:
//  MethodExpression - String    - method call expression that will be marshalled 
//                                  to the Server.
//  InvocationData   - Structure - see function FL_BackgroundJob.NewInvocationData. 
//                          Default value: Undefined.
//
// Returns:
//  CatalogRef.FL_Jobs - ref to created background job or 
//                       Undefined, if it was not created.
//
Function Enqueue(MethodExpression, InvocationData = Undefined) Export

    SubIndex = 1;
    ResIndex = 2;
    
    If InvocationData = Undefined Then
        InvocationData = NewInvocationData();    
    EndIf;
    
    SubscribersData = New Query;
    SubscribersData.Text = QueryTextSubscribersData();
    SubscribersData.SetParameter("Owner", InvocationData.Owner);
    SubscribersData.SetParameter("Method", InvocationData.Method);
    SubscribersData.SetParameter("APIVersion", InvocationData.APIVersion);
    ResultArray = SubscribersData.ExecuteBatch();
    
    Subscribers = ResultArray[SubIndex].Unload();
    SubscriberResources = ResultArray[ResIndex].Unload();
    
    BackgroundJob = NewBackgroundJob();
    FillPropertyValues(BackgroundJob, InvocationData, , "Parameters");
    FillParameters(BackgroundJob, Subscribers, InvocationData);
    FillSubscribers(BackgroundJob, Subscribers);
    FillSubscriberResources(BackgroundJob, SubscriberResources);
    
    Return Catalogs.FL_Jobs.Create(BackgroundJob, InvocationData.State);
    
EndFunction // Enqueue()

// Changes state of a job with the specified Job to the DeletedState. 
// If FromState value is not undefined, state change will be performed 
// only if the current state name of the job equal to the given value.
//
// Parameters:
//  Job   - UUID                -
//        - CatalogRef.FL_Jobs -
//
// Returns:
//  Boolean - True, if state change succeeded, otherwise False.
//
Function Delete(Job, FromState = Undefined) Export

    Return False;
    
EndFunction // Delete()

// Changes state of a job with the specified parameter Job to the EnqueuedState.
// If FromState value is not undefined, state change will be performed 
// only if the current state name of the job equal to the given value.
//
// Parameters:
//  Job   - UUID                -
//        - CatalogRef.FL_Jobs -
//  State -                     - current state assertion.
//                  Default value: Undefined.
//
// Returns:
//  Boolean - True, if state change succeeded, otherwise False.
//
Function Requeue(Job, FromState = Undefined) Export

    Return False;
    
EndFunction // Requeue()

// Creates a new background job that will wait for a successful completion 
// of another background job to be triggered in the EnqueuedState.
//
// Returns:
//  CatalogRef.FL_Jobs - ref to created background job or 
//                       Undefined, if it was not created.
//
Function ContinueWith() Export

    Return False;
    
EndFunction // ContinueWith()

// Creates a new background job based on a specified instance method
// call expression and schedules it to be enqueued after a given delay.
//
// Returns:
//  CatalogRef.FL_Jobs - ref to created background job or 
//                       Undefined, if it was not created.
//
Function Schedule() Export

    Return False;
    
EndFunction // Schedule()

#EndRegion // ProgramInterface

#Region ServiceIterface

// Returns a new invocation data for a service method.
//
// Returns:
//  Structure - the invocation data structure with keys:
//      * APIVersion     - String                  -
//                              Default value: Undefined.
//      * Arguments      - Arbitrary               -
//                              Default value: Undefined.
//      * MetadataObject - String                  - the full name of a metadata
//                                                   object as a term.
//                              Default value: "".
//      * Method         - String                  - 
//                              Default value: Undefined.
//      * Owner          - CatalogReg.FL_Exchanges - an owner of invocation data.
//                              Default value: Undefined.
//      * Parameters     - Structure               - сontains values of data 
//                                                   receiving parameters.
//      * SourceObject   - AnyRef                  - an event source object.
//                              Default value: Undefined.
//      * State          - CatalogRef.FL_States    - new state for a background job.
//                              Default value: Catalogs.FL_States.Enqueued.
//
Function NewInvocationData() Export
    
    InvocationData = New Structure;
    InvocationData.Insert("APIVersion", "1.0.0"); 
    InvocationData.Insert("Arguments");
    InvocationData.Insert("MetadataObject", "");
    InvocationData.Insert("Method");
    InvocationData.Insert("Owner");
    InvocationData.Insert("Parameters", New Structure);
    InvocationData.Insert("SourceObject");
    InvocationData.Insert("State", Catalogs.FL_States.Enqueued);
    Return InvocationData;
    
EndFunction // NewInvocationData()

#EndRegion // ServiceIterface 

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
Procedure FillParameters(BackgroundJob, Subscribers, InvocationData)
    
    // It is needed to fill data composition settings parameters.
    If Subscribers.Count() = 0 Then
        Return;
    EndIf;
        
    DataCompositionSchema = Subscribers[0].DataCompositionSchema.Get(); 
    If TypeOf(DataCompositionSchema) <> Type("DataCompositionSchema") Then
        Return;    
    EndIf;
    
    For Each Parameter In DataCompositionSchema.Parameters Do
        
        Value = Undefined;
 
        FillParameterValueFromStructure(Parameter, InvocationData.Parameters, Value);
        FillParameterValueFromArguments(Parameter, InvocationData.Arguments, Value);
        
        BgParameter = BackgroundJob.Parameters.Add();
        BgParameter.Parameter = Parameter.Name;
        BgParameter.ValuePresentation = String(Value);
        BgParameter.ValueStorage = New ValueStorage(Value);
        
    EndDo;
                 
EndProcedure // FillParameters()

// Only for internal use.
//
Procedure FillParameterValueFromStructure(Parameter, Parameters, Value)
    
    If Value <> Undefined Then
        Return;
    EndIf;
    
    If Parameters.Property(Parameter.Name, Value) Then
               
        AdValue = Parameter.ValueType.AdjustValue(Value);
        If AdValue = Value Then
            
            // The parameter is passed as a single list item.
            If Parameter.ValueListAllowed Then
                Value = New ValueList;
                Value.Add(AdValue);
            EndIf;
            
        ElsIf Parameter.ValueListAllowed
            AND TypeOf(Value) = Type("ValueList") Then
            
            If FL_CommonUseClientServer.CopyTypeDescription(Value.ValueType, ,
                Parameter.ValueType).Types().Count() > 0 Then
                
                Value = Undefined;
                
            EndIf;
            
        Else
            
            Value = Undefined;    
            
        EndIf;
        
    EndIf;
    
EndProcedure // FillParameterValueFromStructure() 

// Only for internal use.
//
Procedure FillParameterValueFromArguments(Parameter, Arguments, Value)
    
    If Value <> Undefined Then
        Return;
    EndIf;
    
    If TypeOf(Arguments) = Type("ValueTable") Then
        
        Column = Arguments.Columns.Find(Parameter.Name);
        If Column <> Undefined AND Parameter.ValueListAllowed Then
            
            If FL_CommonUseClientServer.CopyTypeDescription(Column.ValueType, ,
                Parameter.ValueType).Types().Count() = 0 Then
                
                Value = New ValueList;
                Value.LoadValues(Arguments.UnloadColumn(Parameter.Name));
                
            EndIf;            
            
        EndIf;
        
    ElsIf Arguments <> Undefined Then 
        
        MetadataObject = Arguments.Metadata(); 
        If MetadataObject.Attributes.Find(Parameter.Name) <> Undefined 
            OR FL_CommonUse.IsStandardAttribute(
                MetadataObject.StandardAttributes, Parameter.Name) Then
                
            Value = FL_CommonUse.ObjectAttributeValue(Arguments, 
                Parameter.Name);
            If NOT Parameter.ValueType.ContainsType(TypeOf(Value)) Then
                Value = Undefined;
            EndIf;
            
        EndIf;
        
    EndIf;
    
EndProcedure // FillParameterValueFromArguments()

// Only for internal use.
//
Procedure FillSubscribers(BackgroundJob, Subscribers)
    
    For Each Subscriber In Subscribers Do
        
        FillPropertyValues(BackgroundJob.Subscribers.Add(), Subscriber);
        
    EndDo;    
    
EndProcedure // FillSubscribers()

// Only for internal use.
//
Procedure FillSubscriberResources(BackgroundJob, Resources)
    
    For Each Resource In Resources Do
        
        If Resource.ExecutableCode Then
                
            ExecutableParams = New Structure;
            ExecutableParams.Insert("Source", BackgroundJob.SourceObject);
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
                    
                NewResource = BackgroundJob.SubscriberResources.Add();    
                FillPropertyValues(NewResource, Resource, , "FieldValue");
                NewResource.FieldValue = ExecutableParams.Result;
                
            Except

                ErrorInfo = ErrorInfo();
                ErrorMessage = StrTemplate(
                    NStr("en = 'An error occurred when calling procedure 
                        |ExecuteInSafeMode of common module FL_RunInSafeMode. %1';
                        |ru = 'Ошибка при вызове процедуры ExecuteInSafeMode 
                        |общего модуля FL_RunInSafeMode. %1'"),
                    BriefErrorDescription(ErrorInfo));
                FL_CommonUseClientServer.NotifyUser(ErrorMessage);     
                      
                FillPropertyValues(BackgroundJob.SubscriberResources.Add(), 
                    Resource);   
                    
            EndTry;
            
        Else
            FillPropertyValues(BackgroundJob.SubscriberResources.Add(), 
                Resource);    
        EndIf;
            
    EndDo;    
    
EndProcedure // FillSubscribers()

// Only for internal use.
//
Function NewBackgroundJob()
    
    BackgroundJob = New Structure;
    BackgroundJob.Insert("APIVersion");
    BackgroundJob.Insert("MetadataObject", "");
    BackgroundJob.Insert("Method");
    BackgroundJob.Insert("Owner");
    BackgroundJob.Insert("SourceObject");
    BackgroundJob.Insert("Subscribers", NewSubscribers());
    BackgroundJob.Insert("SubscriberResources", NewSubscriberResources());
    BackgroundJob.Insert("Parameters", NewParameters());
    Return BackgroundJob;
    
EndFunction // NewBackgroundJob()

// Only for internal use.
//
Function NewSubscribers()
    
    Subscribers = New ValueTable;
    Subscribers.Columns.Add("Channel", 
        New TypeDescription("CatalogRef.FL_Channels"));
    Subscribers.Columns.Add("Completed", New TypeDescription("Boolean"));
    Subscribers.Columns.Add("ResponseHandler", 
        FL_CommonUse.StringTypeDescription());
    Return Subscribers;
    
EndFunction // NewSubscribers()

// Only for internal use.
//
Function NewSubscriberResources()
    
    MaxFieldNameLength = 50;
    
    SubscriberResources = New ValueTable;
    SubscriberResources.Columns.Add("Channel", 
        New TypeDescription("CatalogRef.FL_Channels"));
    SubscriberResources.Columns.Add("FieldName", 
        FL_CommonUse.StringTypeDescription(MaxFieldNameLength));
    SubscriberResources.Columns.Add("FieldValue", 
        FL_CommonUse.StringTypeDescription());
    Return SubscriberResources;
    
EndFunction // NewSubscribers()

// Only for internal use.
//
Function NewParameters()
    
    MaxParameterLength = 25;
    MaxPresentationLength = 1024;
    
    Parameters = New ValueTable;
    Parameters.Columns.Add("Parameter", 
        FL_CommonUse.StringTypeDescription(MaxParameterLength));
    Parameters.Columns.Add("ValuePresentation", 
        FL_CommonUse.StringTypeDescription(MaxPresentationLength));
    Parameters.Columns.Add("ValueStorage", 
        New TypeDescription("ValueStorage"));
    Return Parameters;
    
EndFunction // NewParameters()

// Only for internal use.
//
Function QueryTextSubscribersData()

    QueryText = "
        |SELECT
        |   Channels.Ref             AS Owner,
        |   Channels.APIVersion      AS APIVersion,
        |   Channels.Channel         AS Channel,
        |   Channels.Method          AS Method,
        |   Channels.ResponseHandler AS ResponseHandler
        |INTO ChannelsCache
        |FROM
        |   Catalog.FL_Exchanges.Channels AS Channels
        |WHERE
        |    Channels.Ref        = &Owner
        |AND Channels.Method     = &Method
        |AND Channels.APIVersion = &APIVersion
        |
        |INDEX BY
        |   Owner   
        |;
        |
        |////////////////////////////////////////////////////////////////////////////////
        |SELECT
        |   Channels.Channel              AS Channel,
        |   Channels.ResponseHandler      AS ResponseHandler,
        |   Methods.DataCompositionSchema AS DataCompositionSchema
        |
        |FROM
        |   ChannelsCache AS Channels
        |
        |INNER JOIN Catalog.FL_Exchanges.Methods AS Methods
        |ON  Methods.Ref        = Channels.Owner
        |AND Methods.Method     = Channels.Method
        |AND Methods.APIVersion = Channels.APIVersion
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
        |ON  Channels.Owner      = ChannelResources.Ref
        |AND Channels.Channel    = ChannelResources.Channel
        |AND Channels.Method     = ChannelResources.Method
        |AND Channels.APIVersion = ChannelResources.APIVersion
        |;
        |";
    Return QueryText;
    
EndFunction // QueryTextSubscribersData()

#EndRegion // ServiceProceduresAndFunctions