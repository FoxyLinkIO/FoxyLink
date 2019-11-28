////////////////////////////////////////////////////////////////////////////////
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

#Region ObjectFormInteraction

// Loads data composition schema, data composition settings and operations 
// for editing in catalog form.
//
// Parameters:
//  ManagedForm - ManagedForm - catalog form.  
//
Procedure OnCreateAtServer(ManagedForm) Export

    Var CopyingValue;
    
    Object = ManagedForm.Object;
    TypeExchanges = Type("CatalogRef.FL_Exchanges");
    
    Ref = Object.Ref;
    If TypeOf(Ref) <> TypeExchanges 
        OR NOT ValueIsFilled(Ref) Then
        
        Parameters = ManagedForm.Parameters;
        If NOT Parameters.Property("CopyingValue", CopyingValue) Then
            Return;
        EndIf;
        
        If TypeOf(CopyingValue) <> TypeExchanges
            OR NOT ValueIsFilled(CopyingValue) Then
            Return;    
        EndIf;
        
        Ref = CopyingValue;
        
    EndIf;
    
    // ManagedForm.UUID is used to remove automatically the value after 
    // closing the form.
    PlaceEventsDataIntoFormObject(Object, Ref, ManagedForm.UUID);
    PlaceOperationsDataIntoFormObject(Object, Ref, ManagedForm.UUID);
    
EndProcedure // OnCreateAtServer()

// Updates events view on managed form.
//
// Parameters:
//  ManagedForm      - ManagedForm - catalog form.
//  FilterParameters - Structure   - event filter parameters.
//      * Operation - CatalogRef.FL_Operations - an operation for updating catalog form.
//
Procedure UpdateEventsView(ManagedForm, FilterParameters) Export
    
    Events = ManagedForm.Object.Events;
    
    FilterResults = Events.FindRows(FilterParameters);
    If NOT ValueIsFilled(FilterResults) Then
        Return;
    EndIf;
   
    EventHandlers = FL_InteriorUseReUse.AvailableEventHandlers(
        FilterParameters.Operation);
    For Each FilterResult In FilterResults Do
        
        For Each EventHandler In EventHandlers Do
            If FilterResult.EventHandler = EventHandler.EventHandler Then
                FillPropertyValues(FilterResult, EventHandler);   
            EndIf;
        EndDo;
        
        FilterResult.PictureIndex = FL_CommonUseReUse
            .PicSequenceIndexByFullName(FilterResult.MetadataObject);
            
    EndDo;
        
EndProcedure // UpdateEventsView()

// Updates operations view on managed form.
//
// Parameters:
//  ManagedForm - ManagedForm - catalog form.  
//
Procedure UpdateOperationsView(ManagedForm) Export
    
    Items = ManagedForm.Items;
    Operations = ManagedForm.Object.Operations;
    
    // Add operations from object.
    For Each Item In Operations Do
        
        OperationDescription = Item.Operation.Description;
        
        SearchResult = Items.Find(OperationDescription);
        If SearchResult <> Undefined Then
            SearchResult.Picture = PictureLib.FL_InvalidMethodSettings;
        Else
            AddOperationOnForm(Items, OperationDescription, 
                Item.OperationDescription, PictureLib.FL_InvalidMethodSettings);
        EndIf;
            
    EndDo;
    
    For Each Item In Items.OperationPages.ChildItems Do
        
        Operation = FL_CommonUse.ReferenceByDescription(
            Metadata.Catalogs.FL_Operations, Item.Name);
        FilterResult = Operations.FindRows(New Structure("Operation", 
            Operation));
        If NOT ValueIsFilled(FilterResult) Then
            
            // This code is needed to fix problem with platform bug.
            If Item.ChildItems.Find("HiddenGroupSettings") <> Undefined Then
                FL_InteriorUse.MoveItemInItemFormCollectionNoSearch(Items, 
                    Items.HiddenGroupSettings, Items.HiddenGroup);        
            EndIf;
            
            Items.Delete(Item);
            
        EndIf;
        
    EndDo;
    
    // Hide or unhide delete operation button.
    Items.DeleteOperation.Visible = ValueIsFilled(Operations);   
    
EndProcedure // UpdateOperationsView()

// Helps to save untracked changes in catalog form.
//
// Parameters:
//  ManagedForm   - ManagedForm                - catalog form.
//  CurrentObject - CatalogObject.FL_Exchanges - object that is used 
//                  for reading, modifying, adding and deleting catalog items. 
//
Procedure BeforeWriteAtServer(ManagedForm, CurrentObject) Export
    
    PlaceEventsDataIntoDataBaseObject(ManagedForm.Object, CurrentObject);
    PlaceOperationsDataIntoDataBaseObject(ManagedForm.Object, CurrentObject);
    
EndProcedure // BeforeWriteAtServer()

// Fills format description on managed form.
//
// Parameters:
//  ManagedForm     - ManagedForm                               - catalog form.
//  FormatProcessor - DataProcessorObject.<Data processor name> - format data processor.
//
Procedure FillFormatDescription(ManagedForm, FormatProcessor) Export
    
    ManagedForm.FormatName = StrTemplate("%1 (%2)", 
        FormatProcessor.FormatFullName(), FormatProcessor.FormatShortName());  
    ManagedForm.FormatStandard = FormatProcessor.FormatStandard();   
    ManagedForm.FormatPluginVersion = FormatProcessor.Version();
    
EndProcedure // FillFormatDescription()

#EndRegion // ObjectFormInteraction

// Returns a processing result.
//
// Parameters:
//  Exchange - CatalogRef.FL_Exchanges - reference of the FL_Exchanges catalog.
//  Message  - CatalogRef.FL_Messages  - reference of the FL_Messages catalog.
//
// Returns:
//  Structure - see fucntion Catalogs.FL_Jobs.NewJobResult. 
//
Function ProcessMessage(Exchange, Message) Export
    
    JobResult = Catalogs.FL_Jobs.NewJobResult();
    
    Try
        
        Settings = ExchangeSettingsByRefs(Exchange, Message.Operation);
        StreamObject = FL_InteriorUse.NewFormatProcessor(
            Settings.BasicFormatGuid);
        
        // Open new memory stream and initialize format processor.
        Stream = New MemoryStream;
        StreamObject.Initialize(Stream, Settings.APISchema);
        
        OutputParameters = NewOutputParameters(Settings, 
            Catalogs.FL_Messages.DeserializeContext(Message));
                    
        FL_DataComposition.Output(StreamObject, OutputParameters);
        
        // Fill MIME-type information.
        Properties = NewProperties();
        FillPropertyValues(Properties, Message);
        Properties.ContentType = StreamObject.FormatMediaType();
        Properties.ContentEncoding = StreamObject.ContentEncoding;
        Properties.FileExtension = StreamObject.FormatFileExtension();
        Properties.MessageId = XMLString(Message);
        
        // Close format stream and memory stream.
        StreamObject.Close();
        Payload = Stream.CloseAndGetBinaryData();
        
        JobResult.StatusCode = FL_InteriorUseReUse.OkStatusCode();
        
        Catalogs.FL_Jobs.AddToJobResult(JobResult, "Payload", Payload);     
        Catalogs.FL_Jobs.AddToJobResult(JobResult, "Properties", Properties); 

    Except
        
        ErrorInformation = ErrorInfo();
        FL_InteriorUse.WriteLog("FoxyLink.Integration.ProcessMessage", 
            EventLogLevel.Error,
            Metadata.Catalogs.FL_Exchanges,
            ErrorInformation,
            JobResult);
            
    EndTry;
    
    JobResult.Success = FL_InteriorUseReUse.IsSuccessHTTPStatusCode(
        JobResult.StatusCode);
    Return JobResult;
  
EndFunction // ProcessMessage()

// Exports the whole object exchange settings.
//
// Parameters:
//  Exchange - CatalogRef.FL_Exchanges - exchange to export.
//
// Returns:
//  Structure - see function FL_InteriorUseClientServer.NewFileProperties.
//
Function ExportObject(Exchange) Export
    
    PayloadRow = Undefined;
    PropertiesRow = Undefined;
    
    Invocation = Catalogs.FL_Messages.NewInvocation();
    Invocation.EventSource = "Catalogs.FL_Exchanges.Commands.ExportExchange";
    Invocation.Operation = Catalogs.FL_Operations.Read;
    Catalogs.FL_Messages.AddToContext(Invocation.Context, "Ref", Exchange, 
        True);
    
    JobResult = Catalogs.FL_Messages.RouteAndRunOutputResult(Invocation, 
        Catalogs.FL_Exchanges.Self);    
        
    If JobResult.Success 
        AND TypeOf(JobResult.Output) = Type("ValueTable") Then
        PayloadRow = JobResult.Output.Find("Payload", "Name");
        PropertiesRow = JobResult.Output.Find("Properties", "Name");
    EndIf;
        
    If PayloadRow <> Undefined 
        AND PropertiesRow <> Undefined Then 
        
        FileData = PayloadRow.Value;
        Properties = PropertiesRow.Value;
        
        FileDescription = FL_CommonUse.ObjectAttributeValue(Exchange, 
            "Description");
    
        FileProperties = FL_InteriorUseClientServer.NewFileProperties();
        FileProperties.Name = StrTemplate("%1%2", FileDescription, 
            Properties.FileExtension);
        FileProperties.BaseName = FileDescription;
        FileProperties.Extension = Properties.FileExtension;
        FileProperties.Size = FileData.Size();
        FileProperties.IsFile = True;
        FileProperties.StorageAddress = PutToTempStorage(FileData);
        
        #If MobileAppServer OR МобильноеПриложениеСервер Then
        FileProperties.ModificationTime = CurrentDate();
        #ElsIf Server OR ThickClientOrdinaryApplication OR ExternalConnection OR Сервер OR ТолстыйКлиентОбычноеПриложение OR ВнешнееСоединение Then
        FileProperties.ModificationTime = CurrentSessionDate();
        #EndIf
    
        FileProperties.ModificationTimeUTC = CurrentUniversalDate();
        Return FileProperties;
        
    EndIf;
    
    Return Undefined;
    
EndFunction // ExportObject()

// Returns available plugable formats.
//
// Returns:
//  ValueList - with values:
//      * Value - String - format library guid.
//
Function AvailableFormats() Export
    
    ValueList = New ValueList;

    PlugableFormats = FL_InteriorUse.PluggableSubsystem("Formats"); 
    For Each Item In PlugableFormats.Content Do
        
        If Metadata.DataProcessors.Contains(Item) Then
            
            Try
                
                PresentationTemplate = NStr("en='%1 (%2), ver. %3';
                    |ru='%1 (%2), вер. %3';
                    |uk='%1 (%2), вер. %3';
                    |en_CA='%1 (%2), ver. %3'");
                
                DataProcessor = DataProcessors[Item.Name].Create();
                LibraryGuid = DataProcessor.LibraryGuid();
                FormatName = DataProcessor.FormatShortName();
                Standard = DataProcessor.FormatStandard();
                Version = DataProcessor.Version();
     
                Presentation = StrTemplate(PresentationTemplate, FormatName, 
                    Standard, Version);  
                ValueList.Add(LibraryGuid, Presentation);
                
            Except
                
                FL_CommonUseClientServer.NotifyUser(ErrorDescription());
                
            EndTry;
            
        EndIf;
        
    EndDo;
    
    Return ValueList;
    
EndFunction // AvailableFormats()

// Returns a new exchange settings structure.
//
// Returns
//  Structure - exchange settings structure with values:
//      * APISchema               - ValueStorage - API schema storage.
//                                  Arbitrary    - user defined API schema.
//      * BasicFormatGuid         - String       - library guid which is used to identify 
//                                      different implementations of specific format.
//      * CanUseExternalFunctions - Boolean      - indicates the possibility to use the function 
//                                      of common configuration modules in expressions of data composition.
//      * DataCompositionSchema   - ValueStorage - DataCompositionSchema storage.
//                                - DataCompositionSchema - schema, for which template must be built..
//      * DataCompositionSettings - ValueStorage - DataCompositionSettings storage.
//                                - DataCompositionSettings - settings, for which template must be created..
//
Function NewExchangeSettings() Export
    
    ExchangeSettings = New Structure;
    ExchangeSettings.Insert("APISchema");
    ExchangeSettings.Insert("BasicFormatGuid");
    ExchangeSettings.Insert("DataCompositionSchema");
    ExchangeSettings.Insert("DataCompositionSettings");
     
    ExchangeSettings.Insert("DetailsData");
    ExchangeSettings.Insert("AppearanceTemplate");
    ExchangeSettings.Insert("GeneratorType", Type("DataCompositionValueCollectionTemplateGenerator"));
    ExchangeSettings.Insert("CheckFieldsAvailability", True);
    ExchangeSettings.Insert("FunctionalOptionParameters");
    
    ExchangeSettings.Insert("ExternalDataSets");
    ExchangeSettings.Insert("DetailsData");
    ExchangeSettings.Insert("CanUseExternalFunctions", False);
    ExchangeSettings.Insert("DCTParameters");
    
    Return ExchangeSettings;
        
EndFunction // NewExchangeSettings()

// Returns filled structure with output parameters.
// 
// Parameters:
//  Settings - Structure  - see function Catalog.FL_Exchanges.NewExchangeSettings.
//  Context  - ValueTable - see function Catalogs.FL_Messages.NewContext.
//                  Default value: Undefined.
//
// Returns:
//  Structure - with keys:
//      * ExternalDataSets - Structure - structure key corresponds to external data set name. Structure value - 
//                                          external data set.
//      * DetailsData - DataCompositionDetailsData - an object to fill with details data. If not specified, details 
//                                                      will not be filled in.  
//      * CanUseExternalFunctions - Boolean - indicates the possibility to use the function of common configuration
//                                              modules in expressions of data composition.
//                                  Default value: False.
//      * DCTParameters - Structure - see function FL_DataComposition.NewDataCompositionTemplateParameters.
//
// See also:
//  DataCompositionProcessor.Initialize in the syntax-assistant.
//
Function NewOutputParameters(Settings, Context = Undefined) Export
    
    SettingsComposer = New DataCompositionSettingsComposer;
    FL_DataComposition.InitSettingsComposer(SettingsComposer,
        Settings.DataCompositionSchema,
        Settings.DataCompositionSettings);
        
    If Context <> Undefined Then
        FL_DataComposition.SetDataToSettingsComposer(SettingsComposer, Context);
    EndIf;
   
    DataCompositionTemplate = FL_DataComposition.NewTemplateComposerParameters();
    DataCompositionTemplate.Schema = Settings.DataCompositionSchema;
    DataCompositionTemplate.Template = SettingsComposer.GetSettings();
    
    OutputParameters = FL_DataComposition.NewOutputParameters();
    OutputParameters.DCTParameters = DataCompositionTemplate;
    OutputParameters.CanUseExternalFunctions = Settings.CanUseExternalFunctions;
    
    Return OutputParameters;
  
EndFunction // NewOutputParameters()

// Returns exchange settings.
//
// Parameters:
//  Exchange  - CatalogRef.FL_Exchanges  - reference of the FL_Exchanges catalog.
//  Operation - CatalogRef.FL_Operations - reference of the FL_Operations catalog.
//
// Returns:
//  FixedStructure - exchange settings.  
//
Function ExchangeSettingsByRefs(Exchange, Operation) Export

    Query = New Query;
    Query.Text = QueryTextExchangeSettingsByRefs();
    Query.SetParameter("ExchangeRef", Exchange);
    Query.SetParameter("OperationRef", Operation);
    QueryResult = Query.Execute();
    
    Return New FixedStructure(ExchangeSettingsByQueryResult(QueryResult, 
        Exchange, Operation));

EndFunction // ExchangeSettingsByRefs()

// Returns exchange settings.
//
// Parameters:
//  ExchangeName  - String - name of the FL_Exchanges catalog.
//  OperationName - String - name of the FL_Operations catalog.
//
// Returns:
//  FixedStructure  - exchange settings. 
//
Function ExchangeSettingsByNames(Val ExchangeName, Val OperationName) Export

    Query = New Query;
    Query.Text = QueryTextExchangeSettingsByNames();
    Query.SetParameter("ExchangeName", ExchangeName);
    Query.SetParameter("OperationName", OperationName);
    QueryResult = Query.Execute();
    
    Return New FixedStructure(ExchangeSettingsByQueryResult(QueryResult, 
        ExchangeName, OperationName));

EndFunction // ExchangeSettingsByNames()

#EndRegion // ProgramInterface

#Region ServiceInterface

// Returns a new message properties.
//
// Returns: 
//  Structure - the new message properties with keys:
//      * AppId           - String - identifier of the application that 
//                                   produced the message.
//      * ContentEncoding - String - message content encoding.
//      * ContentType     - String - message content type.
//      * CorrelationId   - String - message correlated to this one.
//      * EventSource     - String - provides access to the event source object name.
//      * FileExtension   - String - message format file extension.
//      * MessageId       - String - message identifier as a string. 
//                                   If applications need to identify messages.
//      * Operation       - CatalogRef.FL_Operations - the type of change experienced.
//      * ReplyTo         - String - resource name other apps should send the response to.
//      * Timestamp       - Number - timestamp of the moment when message was created.
//      * UserId          - String - user id.
//
Function NewProperties() Export
    
    Properties = New Structure;
    Properties.Insert("AppId");
    Properties.Insert("ContentEncoding");
    Properties.Insert("ContentType");
    Properties.Insert("CorrelationId");
    Properties.Insert("EventSource");
    Properties.Insert("FileExtension");
    Properties.Insert("MessageId");
    Properties.Insert("Operation");
    Properties.Insert("ReplyTo");
    Properties.Insert("Timestamp");
    Properties.Insert("UserId");

    Return Properties;
    
EndFunction // NewProperties()

// Returns the external event handler info structure for this module.
//
// Returns:
//  Structure - see function FL_InteriorUse.NewExternalEventHandlerInfo.
//
Function EventHandlerInfo() Export
    
    EventHandlerInfo = FL_InteriorUse.NewExternalEventHandlerInfo();
    EventHandlerInfo.EventHandler = "Catalogs.FL_Exchanges.ProcessMessage";
    EventHandlerInfo.Default = True;
    EventHandlerInfo.Version = "1.0.2";
    EventHandlerInfo.Description = StrTemplate(NStr("
            |en='Standard event handler, ver. %1.';
            |ru='Стандартный обработчик событий, вер. %1.';
            |uk='Стандартний обробник подій, вер. %1.';
            |en_CA='Standard event handler, ver. %1.'"), 
        EventHandlerInfo.Version);
        
    EventSources = New Array;
    EventSources.Add("HTTPSERVICE.FL_APPENDPOINT");
    EventSources.Add("HTTPСЕРВИС.FL_APPENDPOINT");
    EventSources.Add("CATALOG.*");
    EventSources.Add("СПРАВОЧНИК.*");
    EventSources.Add("DOCUMENT.*");
    EventSources.Add("ДОКУМЕНТ.*");
    EventSources.Add("CHARTOFCHARACTERISTICTYPES.*");
    EventSources.Add("ПЛАНВИДОВХАРАКТЕРИСТИК.*");
    EventSources.Add("INFORMATIONREGISTER.*");
    EventSources.Add("РЕГИСТРСВЕДЕНИЙ.*");
    EventSources.Add("ACCUMULATIONREGISTER.*");
    EventSources.Add("РЕГИСТРНАКОПЛЕНИЯ.*");
    
    AvailableOperations = Catalogs.FL_Operations.AvailableOperations();
    For Each AvailableOperation In AvailableOperations Do
        EventHandlerInfo.Publishers.Insert(AvailableOperation.Value, 
            EventSources);    
    EndDo;
       
    Return FL_CommonUse.FixedData(EventHandlerInfo);
    
EndFunction // EventHandlerInfo()

#EndRegion // ServiceInterface

#Region ServiceProceduresAndFunctions

#Region ObjectFormInteraction

// Only for internal use.
//
Procedure PlaceEventsDataIntoFormObject(FormObject, CurrentObject, FormUUID)
    
    FilterParameters = New Structure;
    FilterParameters.Insert("MetadataObject");
    FilterParameters.Insert("Operation");
    
    FormEvents = FormObject.Events;
    ObjectEvents = CurrentObject.Events;
    For Each FormRow In FormEvents Do
        
        FillPropertyValues(FilterParameters, FormRow);
        FilterResult = ObjectEvents.FindRows(FilterParameters);
        If FilterResult.Count() = 1 Then
            
            ObjectRow = FilterResult[0];
            DataCompositionSchema = ObjectRow.EventFilterDCSchema.Get();
            If DataCompositionSchema <> Undefined Then
                FormRow.EventFilterDCSchemaAddress = PutToTempStorage(
                    DataCompositionSchema, FormUUID);
            EndIf;
            
            DataCompositionSettings = ObjectRow.EventFilterDCSettings.Get();
            If DataCompositionSettings <> Undefined Then
                FormRow.EventFilterDCSettingsAddress = PutToTempStorage(
                    DataCompositionSettings, FormUUID);
                FormRow.FilterPresentation = String(DataCompositionSettings.Filter);
            EndIf;
        
        EndIf;
            
    EndDo;    
    
EndProcedure // PlaceEventsDataIntoFormObject()

// Only for internal use.
//
Procedure PlaceOperationsDataIntoFormObject(FormObject, CurrentObject, FormUUID)
    
    FormOperations = FormObject.Operations;
    ObjectOperations = CurrentObject.Operations;
    For Each FormRow In FormOperations Do
        
        ObjectRow = ObjectOperations.Find(FormRow.Operation, "Operation");
        DataCompositionSchema = ObjectRow.DataCompositionSchema.Get();
        If DataCompositionSchema <> Undefined Then
            FormRow.DataCompositionSchemaAddress = PutToTempStorage(
                DataCompositionSchema, FormUUID);
        EndIf;
        
        DataCompositionSettings = ObjectRow.DataCompositionSettings.Get();
        If DataCompositionSettings <> Undefined Then
            FormRow.DataCompositionSettingsAddress = PutToTempStorage(
                DataCompositionSettings, FormUUID);
        EndIf;

        APISchema = ObjectRow.APISchema.Get();
        If APISchema <> Undefined Then
            FormRow.APISchemaAddress = PutToTempStorage(APISchema, FormUUID);
        EndIf; 
            
    EndDo;
    
EndProcedure // PlaceOperationsDataIntoFormObject()

// Only for internal use.
//
Procedure PlaceEventsDataIntoDataBaseObject(FormObject, CurrentObject)
    
    FilterParameters = New Structure;
    FilterParameters.Insert("MetadataObject");
    FilterParameters.Insert("Operation");
    
    FormEvents = FormObject.Events;
    ObjectEvents = CurrentObject.Events;
    For Each FormRow In FormEvents Do
        
        FillPropertyValues(FilterParameters, FormRow);
        FilterResult = ObjectEvents.FindRows(FilterParameters);
        If FilterResult.Count() = 1 Then
            
            ObjectRow = FilterResult[0];
            If IsTempStorageURL(FormRow.EventFilterDCSchemaAddress) Then
                ObjectRow.EventFilterDCSchema = New ValueStorage(
                    GetFromTempStorage(FormRow.EventFilterDCSchemaAddress));
            Else
                ObjectRow.EventFilterDCSchema = New ValueStorage(Undefined);
            EndIf;
            
            If IsTempStorageURL(FormRow.EventFilterDCSettingsAddress) Then
                ObjectRow.EventFilterDCSettings = New ValueStorage(
                    GetFromTempStorage(FormRow.EventFilterDCSettingsAddress));
            Else
                ObjectRow.EventFilterDCSettings = New ValueStorage(Undefined);
            EndIf;
            
        EndIf;
                     
    EndDo;
    
EndProcedure // PlaceEventsDataIntoDataBaseObject()

// Only for internal use.
//
Procedure PlaceOperationsDataIntoDataBaseObject(FormObject, CurrentObject)
    
    FormOperations = FormObject.Operations;
    ObjectOperations = CurrentObject.Operations;
    For Each FormRow In FormOperations Do
        
        ObjectRow = ObjectOperations.Find(FormRow.Operation, "Operation");
        
        FillPropertyValues(ObjectRow, FormRow, "CanUseExternalFunctions, 
            |Invoke, Isolated, Priority"); 
        
        If IsTempStorageURL(FormRow.DataCompositionSchemaAddress) Then
            ObjectRow.DataCompositionSchema = New ValueStorage(
                GetFromTempStorage(FormRow.DataCompositionSchemaAddress));
        Else
            ObjectRow.DataCompositionSchema = New ValueStorage(Undefined);
        EndIf;
        
        If IsTempStorageURL(FormRow.DataCompositionSettingsAddress) Then
            ObjectRow.DataCompositionSettings = New ValueStorage(
                GetFromTempStorage(FormRow.DataCompositionSettingsAddress));
        Else
            ObjectRow.DataCompositionSettings = New ValueStorage(Undefined);
        EndIf;
        
        If IsTempStorageURL(FormRow.APISchemaAddress) Then
            ObjectRow.APISchema = New ValueStorage(
                GetFromTempStorage(FormRow.APISchemaAddress));
        Else
            ObjectRow.APISchema = New ValueStorage(Undefined);
        EndIf;
                
    EndDo;
    
EndProcedure // PlaceOperationsDataIntoDataBaseObject() 
    
// Add a new group page that corresponds to the operation.
//
// Parameters:
//  Items                - FormAllItems - collection of all managed form items.
//  OperationDescription - String       - the operation name.
//  Description          - String       - the operation description. 
//  Picture              - Picture      - title picture.
//
Procedure AddOperationOnForm(Items, OperationDescription, Description, Picture)

    BasicDescription = NStr("en='Operation description is not available.';
        |ru='Описание операции не доступно.';
        |uk='Опис операції не доступний.';
        |en_CA='Operation description is not available.'");

    Parameters = New Structure;
    Parameters.Insert("Name", OperationDescription);
    Parameters.Insert("Title", OperationDescription);
    Parameters.Insert("Type", FormGroupType.Page);
    Parameters.Insert("ElementType", Type("FormGroup"));
    Parameters.Insert("EnableContentChange", False);
    Parameters.Insert("Picture", Picture);
    NewPage = FL_InteriorUse.AddItemToItemFormCollection(Items, Parameters, 
        Items.OperationPages);
        
    Parameters = New Structure;
    Parameters.Insert("Name", "Label" + OperationDescription);
    Parameters.Insert("Title", ?(IsBlankString(Description), BasicDescription, 
        Description));
    Parameters.Insert("Type", FormDecorationType.Label);
    Parameters.Insert("ElementType", Тип("FormDecoration"));
    Parameters.Insert("TextColor", New Color(0, 0, 0));
    Parameters.Insert("Font", New Font(, , True));
    FL_InteriorUse.AddItemToItemFormCollection(Items, Parameters, 
        NewPage);

EndProcedure // AddOperationOnForm()

#EndRegion // ObjectFormInteraction

// Only for internal use.
//
Function ExchangeSettingsByQueryResult(QueryResult, Exchange, Operation)
    
    If QueryResult.IsEmpty() Then
        
        ErrorTemplate = Nstr("en='Error: Exchange settings {%1} and/or operation {%2} not found.';
            |ru='Ошибка: Настройки обмена {%1} и/или операция {%2} не найдены.';
            |uk='Помилка: Настройки обміну {%1} та/чи операція {%2} не знайдені.';
            |en_CA='Error: Exchange settings {%1} and/or operation {%2} not found.'");
        ErrorMessage = StrTemplate(ErrorTemplate, String(Exchange), 
            String(Operation));   
        Raise ErrorMessage;
        
    EndIf;

    ValueTable = QueryResult.Unload();
    If ValueTable.Count() > 1 Then
        
        ErrorTemplate = Nstr("en='Error: Duplicated records of exchange settings {%1} and operation {%2} are found.';
            |ru='Ошибка: Обнаружены дублирующиеся настройки обмена {%1} и операция {%2}.';
            |uk='Помилка: Виявлено, що дублюються налаштування обміну {%1} та операція {%2}.';
            |en_CA='Error: Duplicated records of exchange settings {%1} and operation {%2} are found.'");
        ErrorMessage = StrTemplate(ErrorTemplate, String(Exchange), 
            String(Operation));  
        Raise ErrorMessage;
        
    EndIf;

    QuerySettings = ValueTable[0];
    
    ExchangeSettings = NewExchangeSettings();
    ExchangeSettings.APISchema = QuerySettings.APISchema.Get();
    ExchangeSettings.DataCompositionSchema = QuerySettings
        .DataCompositionSchema.Get();
    ExchangeSettings.DataCompositionSettings = QuerySettings
        .DataCompositionSettings.Get();
        
    FillPropertyValues(ExchangeSettings, QuerySettings, , "APISchema, 
        |DataCompositionSchema, DataCompositionSettings");    
        
    Return ExchangeSettings;
    
EndFunction // ExchangeSettingsByQueryResult()

// Only for internal use.
//
Function QueryTextExchangeSettingsByRefs()

    Return "
        |SELECT
        |   ExchangeSettings.Ref                AS Ref,
        |   ExchangeSettings.Description        AS Description,
        |   ExchangeSettings.BasicFormatGuid    AS BasicFormatGuid,
        |   ExchangeSettings.InUse              AS InUse,
        |
        |   ExchangeSettingsOperations.APISchema               AS APISchema,
        |   ExchangeSettingsOperations.DataCompositionSchema   AS DataCompositionSchema,
        |   ExchangeSettingsOperations.DataCompositionSettings AS DataCompositionSettings,
        |   ExchangeSettingsOperations.CanUseExternalFunctions AS CanUseExternalFunctions,
        |   ExchangeSettingsOperations.OperationDescription    AS OperationDescription,
        |
        |   FL_Operations.Ref         AS Operation,
        |   FL_Operations.RESTMethod  AS RESTMethod,
        |   FL_Operations.CRUDMethod  AS CRUDMethod
        |
        |   
        |
        |FROM
        |   Catalog.FL_Exchanges AS ExchangeSettings
        |   
        |INNER JOIN Catalog.FL_Exchanges.Operations AS ExchangeSettingsOperations
        |ON  ExchangeSettingsOperations.Ref = ExchangeSettings.Ref
        |   
        |INNER JOIN Catalog.FL_Operations AS FL_Operations
        |ON  FL_Operations.Ref = &OperationRef
        |AND FL_Operations.Ref = ExchangeSettingsOperations.Operation
        |   
        |WHERE
        |    ExchangeSettings.Ref = &ExchangeRef
        |AND ExchangeSettings.DeletionMark = FALSE
        |";

EndFunction // QueryTextExchangeSettingsByRefs()

// Only for internal use.
//
Function QueryTextExchangeSettingsByNames()

    Return "
        |SELECT
        |   ExchangeSettings.Ref                AS Ref,
        |   ExchangeSettings.Description        AS Description,
        |   ExchangeSettings.BasicFormatGuid    AS BasicFormatGuid,
        |   ExchangeSettings.InUse              AS InUse,
        |
        |   ExchangeSettingsOperations.APISchema               AS APISchema,
        |   ExchangeSettingsOperations.DataCompositionSchema   AS DataCompositionSchema,
        |   ExchangeSettingsOperations.DataCompositionSettings AS DataCompositionSettings,
        |   ExchangeSettingsOperations.CanUseExternalFunctions AS CanUseExternalFunctions,
        |   ExchangeSettingsOperations.OperationDescription    AS OperationDescription,
        |
        |   FL_Operations.Ref         AS Operation,
        |   FL_Operations.RESTMethod  AS RESTMethod,
        |   FL_Operations.CRUDMethod  AS CRUDMethod
        |
        |FROM
        |   Catalog.FL_Exchanges AS ExchangeSettings
        |   
        |INNER JOIN Catalog.FL_Exchanges.Operations AS ExchangeSettingsOperations
        |ON  ExchangeSettingsOperations.Ref = ExchangeSettings.Ref
        |   
        |INNER JOIN Catalog.FL_Operations AS FL_Operations
        |ON  FL_Operations.Description = &OperationName
        |AND FL_Operations.Ref         = ExchangeSettingsOperations.Operation
        |   
        |WHERE
        |    ExchangeSettings.Description = &ExchangeName
        |AND ExchangeSettings.DeletionMark = FALSE
        |";

EndFunction // QueryTextExchangeSettingsByNames()

#EndRegion // ServiceProceduresAndFunctions

#EndIf