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

Function Create(Source, Parameters) Export
    
    Return Undefined;            
    
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
    
    BeginTransaction(DataLockControlMode.Managed);
    Try
        DataLock.Lock();
        
        JobObject = Job.GetObject();
        JobObject.State = State; 
        JobObject.Write();
        
        CommitTransaction();
    Except
        RollbackTransaction();
        // TODO: Exception raise
        // Raise;
        Return False;
    EndTry;
    
    Return True;
    
EndFunction // ChangeState()


// Creates exchange message.
//
// Parameters:
//  SourceObject    - Arbitrary - event source.
//  QueryParameters - Structure - exchange settings parameters.
//
// Returns:
//  CatalogRef.FL_Jobs - exchange message.
//
Function CreateMessage(SourceObject, QueryParameters) Export
    
    IsReference = FL_CommonUse.IsReference(TypeOf(SourceObject));
    
    QueryChannels = New Query;
    QueryChannels.Text = QueryTextSubscribersData();
    QueryChannels.Parameters.Insert("Owner");
    QueryChannels.Parameters.Insert("APIVersion");
    QueryChannels.Parameters.Insert("Method");
    FillPropertyValues(QueryChannels.Parameters, QueryParameters);
    ResultArray = QueryChannels.ExecuteBatch();
    
    ChannelsSettings = ResultArray[1].Unload();
    ChannelResources = ResultArray[2].Unload();
    
    NewMessage = Catalogs.FL_Jobs.CreateItem();
    NewMessage.CreatedAt = CurrentUniversalDate();
    NewMessage.State = Catalogs.FL_States.Enqueued;
    FillPropertyValues(NewMessage, QueryParameters); 
    If IsReference Then
        NewMessage.SourceObject = SourceObject;
    EndIf;
    
    // It is needed to fill data composition settings parameters.
    If ChannelsSettings.Count() > 0 Then
        
        ValueStorage = ChannelsSettings[0].DataCompositionSchema; 
        If TypeOf(ValueStorage) = Type("ValueStorage") Then
            
            DataCompositionSchema = ValueStorage.Get();
            If TypeOf(DataCompositionSchema) = Type("DataCompositionSchema") Then
                
                Parameters = DataCompositionSchema.Parameters;
                For Each Parameter In Parameters Do
                    
                    PName = TrimAll(Parameter.Name);
                    PTypeDescription = Parameter.ValueType;
                    PValue = Undefined;
                    
                    If QueryParameters.Property(PName) And PTypeDescription
                        .ContainsType(TypeOf(QueryParameters[PName])) Then
                      
                        PValue = QueryParameters[PName]; 
                      
                    ElsIf IsReference = True Then
                        
                        MetaObject = SourceObject.Metadata();                            
                        If MetaObject.Attributes.Find(PName) <> Undefined Then
                            ObjectAttributeValue(SourceObject, PName, PTypeDescription, PValue); 
                        EndIf;
                        
                        If FL_CommonUse.IsStandardAttribute(MetaObject.StandardAttributes, PName) Then
                            ObjectAttributeValue(SourceObject, PName, PTypeDescription, PValue);        
                        EndIf;
                        
                    Else
                        
                        ParameterValue = Undefined;
                        
                    EndIf;
                    
                    NewRow = NewMessage.DCSParameters.Add();
                    NewRow.Parameter = PName;
                    NewRow.ValuePresentation = String(PValue);
                    NewRow.ValueStorage = New ValueStorage(PValue);
                    
                EndDo;
                
            EndIf;
            
        EndIf;
        
    EndIf;
    
    
    FilterParameters = NewFilterChannelResourcesParameters();
    For Each Channel In ChannelsSettings Do
        
        FillPropertyValues(NewMessage.Subscribers.Add(), Channel);
        FillPropertyValues(FilterParameters, Channel);
        
        FilterResults = ChannelResources.FindRows(FilterParameters);
        For Each FilterResult In FilterResults Do
            
            If FilterResult.ExecutableCode = True Then
                
                ExecutableParams = New Structure;
                ExecutableParams.Insert("Source", SourceObject);
                ExecutableParams.Insert("Result", Undefined);
                
                Algorithm = StrTemplate("
                        |Source = Parameters.Source;
                        |Result = Parameters.Result;
                        |
                        |%1
                        |
                        |Parameters.Result = Result;", 
                    FilterResult.FieldValue);
                    
                Try
                    FL_RunInSafeMode.ExecuteInSafeMode(Algorithm, 
                        ExecutableParams);
                        
                    NewResource = NewMessage.SubscriberResources.Add();    
                    FillPropertyValues(NewResource, FilterResult, , "FieldValue");
                    NewResource.FieldValue = ExecutableParams.Result;
                    
                Except

                    ErrorInfo = ErrorInfo();
                    ErrorMessage = StrTemplate(
                        NStr("en = 'An error occurred when calling procedure ExecuteInSafeMode of common module FL_RunInSafeMode. %1';
                            |ru = 'Ошибка при вызове процедуры ExecuteInSafeMode общего модуля FL_RunInSafeMode. %1'"),
                        BriefErrorDescription(ErrorInfo));
                    FL_CommonUseClientServer.NotifyUser(ErrorMessage);     
                          
                    FillPropertyValues(NewMessage.SubscriberResources.Add(), 
                        FilterResult);   
                        
                EndTry;
                
            Else
                FillPropertyValues(NewMessage.SubscriberResources.Add(), 
                    FilterResult);    
            EndIf;
                  
        EndDo;
        
    EndDo;
    
    NewMessage.Write();
    Return NewMessage.Ref;
    
EndFunction // CreateMessage()

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
    
    
    // Start measuring.
    // Mediator
    
    MessageSettings = FL_DataComposition.NewMessageSettings();
    For Each DCSParameter In MessageObject.DCSParameters Do
        MessageSettings.Body.Parameters.Insert(DCSParameter.Parameter, 
            DCSParameter.ValueStorage.Get());
    EndDo;

    ExchangeSettings = Catalogs.FL_Exchanges.ExchangeSettingsByRefs(
        MessageObject.Owner, MessageObject.Method); 
        
    ResultMessage = Catalogs.FL_Exchanges.GenerateMessageResult(Undefined, 
        ExchangeSettings, FL_CommonUse.FixedData(MessageSettings));
            
    If Not MessageObject.Subscribers.Count() = 0 Then
        
        //Subscribers = MessageData.Subscribers.Select();
        
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
    
    
    // End measuring.
    // Mediator    
        
        
    //If TransactionActive() Then
    //    CommitTransaction();
    //EndIf;
    
    Return DeliveryResponse;
            
EndFunction // ProcessMessage() 

#EndRegion // ProgramInterface

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
Procedure ObjectAttributeValue(Ref, Name, TypeDescription, Value)
    
    Value = FL_CommonUse.ObjectAttributeValue(Ref, Name);   
    If Not TypeDescription.ContainsType(TypeOf(Value)) Then
        Value = Undefined;
    EndIf;
    
EndProcedure // ObjectAttributeValue()


// Only for internal use.
//
Function NewFilterChannelResourcesParameters()
    
    FilterParameters = New Structure;
    FilterParameters.Insert("Channel");
    
    Return FilterParameters;
    
EndFunction // NewFilterChannelResourcesParameters() 


// Only for internal use.
//
//Function QueryTextMessageData()
//
//    QueryText = "
//        |SELECT
//        |   BackgroundJobs.Owner      AS Owner,
//        |   BackgroundJobs.APIVersion AS APIVersion,
//        //|   BackgroundJobs.Completed  AS Completed,
//        |   BackgroundJobs.Method     AS Method,
//        |   BackgroundJobs.Reference  AS Reference,
//        |
//        |   BackgroundJobs.Subscribers.(
//        |       Channel         AS Channel,
//        |       Completed       AS Completed,
//        |       ResponseHandler AS ResponseHandler
//        |       ) AS Subscribers,
//        |
//        |   BackgroundJobs.SubscriberResources.(
//        |       Channel     AS Channel,
//        |       FieldName   AS FieldName,
//        |       FieldValue  AS FieldValue
//        |       ) AS SubscriberResources        
//        |
//        |FROM
//        |   Catalog.FL_Jobs AS BackgroundJobs
//        |   
//        |WHERE
//        |   BackgroundJobs.Ref = &Ref
//        |AND BackgroundJobs.DeletionMark = FALSE
//        |";  
//    Return QueryText;
//
//EndFunction // QueryTextMessageData()

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

#EndIf