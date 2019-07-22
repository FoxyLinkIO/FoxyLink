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

#Region ProgramInterface

#Region ConstantsInteraction

// Returns the composition of a set of constants.
//
// Parameters:
//  Set - ConstantsSet - set of constants.
//
// Returns:
//  Structure - with keys:
//      * Key - String - constant name from set.
//
Function SetOfConstants(Set) Export

    Result = New Structure;
    For Each MetaConstant In Metadata.Constants Do
        If FL_CommonUseClientServer.IsObjectAttribute(Set, MetaConstant.Name) Then
            Result.Insert(MetaConstant.Name);
        EndIf;
    EndDo;
    Return Result;

EndFunction // SetOfConstants()

#EndRegion // ConstantsInteraction

#Region HTTPInteraction

// Sends data at the specified address to be processed using the specified HTTP-method.
//
// Parameters:
//  HTTPConnection - HTTPConnection - an object to interact with external 
//                          systems by HTTP protocol, including file transfer.
//  HTTPRequest    - HTTPRequest    - describes the HTTP-requests sent using 
//                                      the HTTPConnection object.
//  HTTPMethod     - HTTPMethod     - HTTP method name.
//  JobResult      - Structure      - see function Catalogs.FL_Jobs.NewJobResult.
//
Procedure CallHTTPMethod(HTTPConnection, HTTPRequest, HTTPMethod, 
    JobResult) Export
    
    LogObject = Undefined;
    
    If JobResult.LogAttribute <> Undefined Then
        LogObject = StartLogHTTPRequest(HTTPConnection, HTTPRequest, HTTPMethod);
    EndIf;

    Try
        
        HTTPResponse = HTTPConnection.CallHTTPMethod(HTTPMethod, HTTPRequest);
        
        Headers = HTTPResponse.Headers;
        Payload = HTTPResponse.GetBodyAsBinaryData();
        JobResult.StatusCode = HTTPResponse.StatusCode;
        
        Properties = Catalogs.FL_Exchanges.NewProperties();
        Properties.ContentType = Headers.Get("Content-Type");
        
        Catalogs.FL_Jobs.AddToJobResult(JobResult, "Payload", Payload);
        Catalogs.FL_Jobs.AddToJobResult(JobResult, "Properties", Properties);    
        
        If JobResult.LogAttribute <> Undefined Then
            JobResult.LogAttribute = JobResult.LogAttribute + EndLogHTTPRequest(
                LogObject, JobResult.StatusCode, HTTPResponse.GetBodyAsString());    
        EndIf;
        
    Except
        
        JobResult.StatusCode = FL_InteriorUseReUse
            .InternalServerErrorStatusCode();
        JobResult.LogAttribute = ErrorDescription();
        
    EndTry;
    
    JobResult.Success = FL_InteriorUseReUse.IsSuccessHTTPStatusCode(
        JobResult.StatusCode);
        
EndProcedure // CallHTTPMethod()

// Creates HTTPConnection object. 
//
// Parameters:
//  StringURI           - String        - reference to the resource in the format:
//    <schema>://<login>:<password>@<host>:<port>/<path>?<parameters>#<anchor>.
//  Proxy               - InternetProxy - proxy used to connect to server.
//                              Default value: Undefined.
//  Timeout             - Number        - defines timeout for connection and 
//                                        operations in seconds.
//                              Default value: 0 - timeout is not set.
//  UseOSAuthentication - Boolean       - enables NTLM or Negotiate authentication on the server.
//                              Default value: False. 
//
// Returns:
//  HTTPConnection - an object to interact with external systems by HTTP 
//                   protocol, including file transfer.  
//
Function NewHTTPConnection(StringURI, Proxy = Undefined, Timeout = 0, 
    UseOSAuthentication = False) Export
    
    URIStructure = FL_CommonUseClientServer.URIStructure(StringURI);
    If Upper(URIStructure.Schema) = Upper("https") Then 
        SecureConnection = New OpenSSLSecureConnection(Undefined, Undefined);      
    Else 
        SecureConnection = Undefined;
    EndIf;

    HTTPConnection = New HTTPConnection(
        URIStructure.Host,
        URIStructure.Port,
        URIStructure.Login,
        URIStructure.Password,
        Proxy,
        Timeout,
        SecureConnection,
        UseOSAuthentication);
        
    Return HTTPConnection;        
    
EndFunction // NewHTTPConnection()

// Creates HTTPRequest object.
//
// Parameters:
//  ResourceAddress - String     - line of the http resource.
//  Headers         - Map        - request headers.
//                          Default value: Undefined.
//  BinaryBody      - BinaryData - contains a request body as binary data. 
//                          Default value: Undefined.
//
// Returns:
//  HTTPRequest - describes the HTTP-requests. 
//
Function NewHTTPRequest(ResourceAddress, Headers = Undefined, 
    BinaryBody = Undefined) Export
    
    If Headers = Undefined Then
        Headers = New Map;
    EndIf;
    
    HTTPRequest = New HTTPRequest(ResourceAddress, Headers);
    If TypeOf(BinaryBody) = Type("BinaryData") Then 
        HTTPRequest.SetBodyFromBinaryData(BinaryBody);
    EndIf;
    
    Return HTTPRequest;
    
EndFunction // NewHTTPRequest()

#EndRegion // HTTPInteraction

#Region FormInteraction

// Copies data to a form object from app endpoint or form parameters collection. 
//
// Parameters:
//  AppEndpoint - CatalogRef.FL_Channels  - reference to the app endpoint.
//  FormObject  - DataProcessorObject.<*> - represents a processing object. 
//                                          It can be used to access the attributes and the tabular section, 
//                                          as well as the data processor forms and templates.
//  Parameters  - FormDataStructure       - contains the form parameters collection.
//
Procedure FillAppEndpointChannelFormData(AppEndpoint, FormObject, 
    Parameters) Export
    
    If Parameters.Property("AppEndpoint", AppEndpoint)
        AND NOT Parameters.Property("ChannelData") 
        AND NOT Parameters.Property("EncryptedData") Then
        
        For Each Item In AppEndpoint.ChannelData Do
            FillPropertyValues(FormObject.ChannelData.Add(), Item);
        EndDo;
        
        For Each Item In AppEndpoint.EncryptedData Do
            FillPropertyValues(FormObject.EncryptedData.Add(), Item);
        EndDo;
            
    Else
        
        CopyFormData(Parameters.ChannelData, FormObject.ChannelData);
        CopyFormData(Parameters.EncryptedData, FormObject.EncryptedData);
        
    EndIf;
    
EndProcedure // FillAppEndpointChannelFormData()

// Copies data to a managed form from form parameters collection.
//
// Parameters:
//  ManagedForm - ManagedForm       - contains the given form.
//  Parameters  - FormDataStructure - contains the form parameters collection.
//
Procedure FillAppEndpointResourcesFormData(ManagedForm, Parameters) Export
    
    If Parameters.Property("ChannelResources") Then
        
        Attributes = ManagedForm.GetAttributes();
        For Each Attribute In Attributes Do
            
            FieldValue = FL_EncryptionClientServer.FieldValueNoException(
                Parameters.ChannelResources, Attribute.Name);    
            If FieldValue <> Undefined Then
                ManagedForm[Attribute.Name] = FieldValue;    
            EndIf;
            
        EndDo;
        
    EndIf;
    
EndProcedure // FillAppEndpointResourcesFormData()

// Moves a collection item.
//
// Parameters:
//  Items      - FormAllItems - collection of all managed form items.
//  ItemName   - String       - item to be moved.
//  ParentName - String       - new parent of the item. May be the same as the old one.
//  Location   - String       - item before which the moved item should be placed. If it 
//                              is not specified, the item is moved to the collection end.
//                  Default value: "".
//
Procedure MoveItemInItemFormCollection(Items, ItemName, 
    ParentName, Location = "") Export
    
    Items.Move(Items.Find(ItemName), Items.Find(ParentName), 
        Items.Find(Location));
    
EndProcedure // MoveItemInItemFormCollection()

// Moves a collection item. 
//
// Parameters:
//  Items    - FormAllItems - collection of all managed form items.
//  Item     - FormGroup, FormTable, FormDecoration, FormButton, FormField - item to be moved.
//  Parent   - FormGroup, FormTable, ManagedForm - new parent of the item. May be the same as the old one.
//  Location - FormGroup, FormTable, FormDecoration, FormButton, FormField - item before 
//                      which the moved item should be placed. If it is not specified, 
//                      the item is moved to the collection end.
//                  Default value: Undefined.
//
Procedure MoveItemInItemFormCollectionNoSearch(Items, Item, 
    Parent, Location = Undefined) Export

    Items.Move(Item, Parent, Location);

EndProcedure // MoveItemInItemFormCollectionNoSearch()

// Sets the value into property of the form item.
// Applied when the form item can not be on form because user does not have 
// rights to an object, attribute or command.
//
// Parameters:
//  FormItems    - FormItems - property of the managed form.
//  ItemName     - String    - form item name.
//  PropertyName - String    - name of the set form item property.
//  Value        - Arbitrary - new item value.
// 
Procedure SetFormItemProperty(FormItems, ItemName, PropertyName, Value) Export

    FormItem = FormItems.Find(ItemName);
    If FormItem <> Undefined AND FormItem[PropertyName] <> Value Then
        FormItem[PropertyName] = Value;
    EndIf;

EndProcedure // SetFormItemProperty() 

// Add an item to item form collection.
// 
// Parameters:
//  Items      - FormAllItems - collection of all managed form items.
//  Parameters - Structure    - parameters of the new form item.
//  Parent     - FormGroup, FormTable, ManagedForm - parent of the new form item.
//
// Returns:
//  FormDecoration, FormGroup, FormButton, FormTable, FormField - the new form item.
//
Function AddItemToItemFormCollection(Items, Parameters, 
    Parent = Undefined) Export
        
    If TypeOf(Parameters) <> Type("Structure") Then
        
        ErrorMessage = StrTemplate(NStr("
                |en='Parameter(2) failed to convert. Expected type {%1} and received type is {%2}.';
                |ru='Параметр(2) не удалось преобразовать. Ожидался тип {%1}, а получили тип {%2}.';
                |uk='Параметр(2) не вдалось перетворити. Очікувався тип {%1}, а отримали тип {%2}.';
                |en_CA='Parameter(2) failed to convert. Expected type {%1} and received type is {%2}.'"),
            String(Type("Structure")),
            String(TypeOf(Parameters)));

        Raise ErrorMessage;
        
    EndIf;

    ItemName = ParametersPropertyValue(Parameters, "Name", 
        NStr("en='Error: Item name is not set.';
            |ru='Ошибка: Имя элемента не задано.';
            |uk='Помилка: Назву елементу не вказано.'
            |en_CA='Error: Item name is not set.'"), True, True);
                                                    
    ElementType = ParametersPropertyValue(Parameters, "ElementType", 
        NStr("en='Error: The element type is not specified.';
            |ru='Ошибка: Тип элемента не задан.';
            |uk='Помилка: Тип елементу не вказано.';
            |en_CA='Error: The element type is not specified.'"), True, True);
                                                    
    ItemType = ParametersPropertyValue(Parameters, "Type", 
        NStr("en='Error: Type of element is not specified.';
            |ru='Ошибка: Вид элемента не задан.';
            |uk='Помилка: Вид елементу не вказано.';
            |en_CA='Error: Type of element is not specified.'"), False, True);

    If Parent <> Undefined 
        AND TypeOf(Parent) <> Type("FormGroup") 
        AND TypeOf(Parent) <> Type("FormTable") 
        AND TypeOf(Parent) <> Type("ManagedForm") Then
           
        ErrorMessage = StrTemplate(NStr("
                |en='Error: Parameter(3) failed to convert.
                    |Expected type {%1}, {%2}, {%3} and received type is {%4}.';
                |ru='Ошибка: Тип параметра(3) не удалось преобразовать. 
                    |Ожидался тип {%1}, {%2}, {%3}, а получили тип {%4}.';
                |uk='Помилка: Тип параметру(3) не вдалось перетворити. 
                    |Очікувався тип {%1}, {%2}, {%3}, а отримали тип {%4}.';
                |en_CA='Error: Parameter(3) failed to convert. 
                    |Expected type {%1}, {%2}, {%3} and received type is {%4}.'"),
            String(Type("ManagedForm")),
            String(Type("FormGroup")),
            String(Type("FormTable")),
            String(TypeOf(Parent)));
            
        Raise ErrorMessage;
            
    EndIf;
        
    NewFormItem = Items.Add(ItemName, ElementType, Parent);
    If ItemType <> Undefined Then
        NewFormItem.Type = ItemType;
    EndIf;

    FillPropertyValues(NewFormItem, Parameters);

    Return NewFormItem;
    
EndFunction // AddItemToItemFormCollection()

// Returns a new form field.
//
// Parameters:
//  Type - FormFieldType - the managed form field type.
//
// Returns:
//  Structure - with all available properties for the field.
// 
Function NewFormField(Type) Export
    
    FormField = New Structure;
    FormField.Insert("AutoCellHeight", False);    
    FormField.Insert("CellHyperlink", False);
    FormField.Insert("ContextMenu");
    FormField.Insert("DataPath");
    FormField.Insert("DefaultItem", False);
    
    #If NOT MobileAppServer Then
    FormField.Insert("EditMode", ColumnEditMode.EnterOnInput);
    #EndIf

    FormField.Insert("Enabled", True);
    FormField.Insert("ExtendedTooltip");
    FormField.Insert("FixingInTable", FixingInTable.None);
    FormField.Insert("FooterBackColor", StyleColors.TableFooterBackColor);
    FormField.Insert("FooterDataPath");
    FormField.Insert("FooterFont", StyleFonts.NormalTextFont);
    FormField.Insert("FooterHorizontalAlign", ItemHorizontalLocation.Auto);
    FormField.Insert("FooterPicture", New Picture);
    FormField.Insert("FooterText");
    FormField.Insert("FooterTextColor", StyleColors.TableFooterTextColor);
    FormField.Insert("HeaderHorizontalAlign", ItemHorizontalLocation.Left);
    FormField.Insert("HeaderPicture", New Picture);
    FormField.Insert("HorizontalAlign", ItemHorizontalLocation.Auto);
    FormField.Insert("HorizontalAlignInGroup", ItemHorizontalLocation.Auto);
    FormField.Insert("Name");
    FormField.Insert("Parent");
    FormField.Insert("ReadOnly", False);
    // Unexpected behaviour. FormField.Insert("Shortcut");
    FormField.Insert("ShowInFooter", True);
    FormField.Insert("ShowInHeader", True);
    FormField.Insert("SkipOnInput");
    FormField.Insert("Title");
    FormField.Insert("TitleBackColor", StyleColors.TableHeaderBackColor);
    FormField.Insert("TitleFont", StyleFonts.NormalTextFont);
    FormField.Insert("TitleHeight", 0);
    FormField.Insert("TitleLocation",  FormItemTitleLocation.Auto);
    FormField.Insert("TitleTextColor", StyleColors.TableHeaderTextColor);
    FormField.Insert("ToolTip");
    FormField.Insert("ToolTipRepresentation", ToolTipRepresentation.Auto);
    FormField.Insert("Type", Type);
    // Unexpected behaviour. FormField.Insert("TypeRestriction");
    FormField.Insert("VerticalAlign", ItemVerticalAlign.Auto);
    FormField.Insert("VerticalAlignInGroup", ItemVerticalAlign.Auto);
    FormField.Insert("Visible", True);
    FormField.Insert("WarningOnEdit");
    FormField.Insert("WarningOnEditRepresentation", WarningOnEditRepresentation.Auto);
    
    If Type = FormFieldType.InputField Then
        AddFormFieldExtensionForTextBox(FormField);
    EndIf;
    
    FormField.Insert("ElementType", Type("FormField"));
    Return FormField;
    
EndFunction // NewFormField()

#Endregion // FormInteraction

#Region LogInteraction

// Writes an event in the event log and updates job result state if passed. 
//
// Parameters:
//  EventName      - String         - event is indicated by string. Can contain points  
//                              for signifying event hierarchy.
//  Level          - EventLogLevel  - level of event importance. 
//  MetadataObject - MetadataObject - the object that is associated with the event.
//  Commentaries   - String         - arbitrary string of commentary for the event.
//                 - Array          - commentaries list.
//  JobResult      - Structure      - see function Catalogs.FL_Jobs.NewJobResult.
//                          Default value: Undefined.
//
Procedure WriteLog(EventName, Level, MetadataObject, Commentaries, 
    JobResult = Undefined) Export
    
    Var Commentary;
     
    If TypeOf(Commentaries) = Type("Array") Then
        Commentary = StrConcat(Commentaries, Chars.CR + Chars.LF);
    Else 
        Commentary = Commentaries;
    EndIf;
    
    If TypeOf(JobResult) = Type("Structure") Then
        
        JobResult.LogAttribute = Commentary;
        If Level = EventLogLevel.Error Then
            JobResult.StatusCode = FL_InteriorUseReUse
                .InternalServerErrorStatusCode();                
        EndIf;

    EndIf;
    
    WriteLogEvent(EventName, Level, MetadataObject, , Commentary);
    
EndProcedure // WriteLog()

#EndRegion // LogInteraction

#Region SubsystemInteraction

// Performs initial filling of the subsystem.
//
Procedure InitializeSubsystem() Export
    
    Catalogs.FL_States.InitializeStates();
    InitializeOperations();
    InitializeChannels();
    InitializeConstants();
    
EndProcedure // InitializeSubsystem() 

// Loads imported exchange data into a mock object.
//
// Parameters:
//  MockObject - Arbitrary - the mock object. 
//  Exchange   - Structure - an structure with imported exchange.
// 
Procedure LoadImportedExchange(MockObject, Exchange) Export
    
    MockObject.Exchange = Exchange.Ref;
    FillPropertyValues(MockObject, Exchange, "BasicFormatGuid, Description,
        |InUse, PredefinedDataName, Version");
    
    // Methods load.
    If Exchange.Property("Operations") Then
        FL_CommonUseClientServer.ExtendValueTable(LoadImportedOperations(
                Exchange.Operations), 
            MockObject.Operations);
    EndIf;
    
    // Channels load.
    If Exchange.Property("Channels") Then
        FL_CommonUseClientServer.ExtendValueTable(LoadImportedChannels(
                Exchange.Channels), 
            MockObject.Channels);
        FL_CommonUse.RemoveDuplicatesFromValueTable(MockObject.Channels);
    EndIf;
    
    // Events load.
    If Exchange.Property("Events") Then
        FL_CommonUseClientServer.ExtendValueTable(Exchange.Events, 
            MockObject.Events);
        FL_CommonUse.RemoveDuplicatesFromValueTable(MockObject.Events);
    EndIf;
    
    // Exchange load.
    Result = FL_CommonUse.ReferenceByPredefinedDataName(
        Metadata.Catalogs.FL_Exchanges, Exchange.PredefinedDataName);
    If Result <> Undefined Then
        MockObject.Ref = Result;
        Return;
    EndIf;
    
    Result = Catalogs.FL_Exchanges.GetRef(New UUID(Exchange.Ref));
    If FL_CommonUse.RefExists(Result) Then
        MockObject.Ref = Result;
        Return;
    EndIf;
    
    Result = FL_CommonUse.ReferenceByDescription(
        Metadata.Catalogs.FL_Exchanges, Exchange.Description);
    If Result <> Undefined Then
        MockObject.Ref = Result; 
        Return;
    EndIf;
              
EndProcedure // LoadImportedExchange()

// Returns metadata object: pluggable subsystem.
//
// Parameters:
//  SubsystemName - String - plugable subsystem name.
//
// Returns:
//  MetadataObject: Subsystem - plugable subsystem.  
//
Function PluggableSubsystem(SubsystemName) Export
    
    MainSubsystem = Metadata.Subsystems.Find("FoxyLink");
    If MainSubsystem = Undefined Then
        
        ErrorMessage = NStr("en='Failed to find main subsystem {FoxyLink}.';
            |ru='Не удалось найти основную подсистему {FoxyLink}.';
            |uk='Не вдалось знайти основну підсистему {FoxyLink}.';
            |en_CA='Failed to find main subsystem {FoxyLink}.'");
        Raise ErrorMessage;
        
    EndIf;
    
    PluginsSubsystem = MainSubsystem.Subsystems.Find("Plugins");
    If PluginsSubsystem = Undefined Then
        
        ErrorMessage = NStr("en='Failed to find {FoxyLink -> Plugins} subsystem.';
            |ru='Не удалось найти подсистему {FoxyLink -> Plugins}.';
            |uk='Не вдалось знайти підсистему {FoxyLink -> Plugins}.';
            |en_CA='Failed to find {FoxyLink -> Plugins} subsystem.'");
        Raise ErrorMessage;
        
    EndIf;
    
    PluggableSubsystem = PluginsSubsystem.Subsystems.Find(SubsystemName);
    If PluggableSubsystem = Undefined Then
        
        ErrorMessage = StrTemplate(NStr("en='Failed to find {FoxyLink -> Plugins -> %1} subsystem.';
                |ru='Не удалось найти подсистему {FoxyLink -> Plugins -> %1}.';
                |uk='Не вдалось знайти підсистему {FoxyLink -> Plugins -> %1}.';
                |en_CA='Failed to find {FoxyLink -> Plugins -> %1} subsystem.'"),
            SubsystemName);
        Raise ErrorMessage;
        
    EndIf;
    
    Return PluggableSubsystem;
    
EndFunction // PluggableSubsystem()

// Returns a new pluggable settings structure.
//
// Returns:
//  Structure - with keys:
//      * Name     - String - name of settings.
//      * Template - String - name of template with data settings.
//      * ToolTip  - String - short settings description.
//      * Version  - String - version of current settings.
//
Function NewPluggableSettings() Export
    
    PluggableSettings = New Structure;
    PluggableSettings.Insert("Name");
    PluggableSettings.Insert("Template");
    PluggableSettings.Insert("ToolTip");
    PluggableSettings.Insert("Version");
    Return PluggableSettings;
    
EndFunction // NewPluggableSettings()

// Returns a new app endpoint data processor for every server call.
//
// Parameters:
//  LibraryGuid - String - library guid which is used to identify 
//                         different implementations of specific app endpoint.
//
// Returns:
//  DataProcessorObject.<Data processor name> - app endpoint data processor.
//
Function NewAppEndpointProcessor(Val LibraryGuid) Export
    
    DataProcessorName = FL_InteriorUseReUse.IdentifyPluginProcessorName(
        LibraryGuid, "Channels");
        
    If DataProcessorName = Undefined Then
        Raise NStr("en='Requested channel processor is not installed.';
            |ru='Запрашиваемый процессор канала не установлен.';
            |uk='Запитуваний процесор каналу не встановлено.';
            |en_CA='Requested channel processor is not installed.'");    
    EndIf;    
        
    Return DataProcessors[DataProcessorName].Create();
    
EndFunction // NewAppEndpointProcessor()

// Returns new format data processor for every server call.
//
// Parameters:
//  LibraryGuid - String - library guid which is used to identify 
//                         different implementations of specific format.
//
// Returns:
//  DataProcessorObject.<Data processor name> - format data processor.
//
Function NewFormatProcessor(Val LibraryGuid) Export
    
    DataProcessorName = FL_InteriorUseReUse.IdentifyPluginProcessorName(
        LibraryGuid, "Formats");
        
    If DataProcessorName = Undefined Then
        Raise NStr("en='Requested format processor is not installed.';
            |ru='Запрашиваемый процессор формата не установлен.';
            |uk='Запитуваний процесор формату не встановлено.';
            |en_CA='Requested format processor is not installed.'");    
    EndIf;
        
    Return DataProcessors[DataProcessorName].Create();
        
EndFunction // NewFormatProcessor()
 
// Returns a new external event handler info structure.
//
// Returns:
//  Structure - with keys:
//      * EventHandler  - String  - event handler module.
//      * Default       - Boolean - True if it's default handler.
//                          Default value: False.
//      * Description   - String  - event handler description.
//      * Publishers    - Map     - publishers map.
//          ** Key   - CatalogRef.FL_Operations - publisher operation.
//          ** Value - Array                    - event source objects.
//      * Transactional - Boolean - True if method creates implicit transactions.
//                          Default value: False.
//      * Version       - String  - event handler version.
//
Function NewExternalEventHandlerInfo() Export
    
    EventHandlerInfo = New Structure;
    EventHandlerInfo.Insert("EventHandler");
    EventHandlerInfo.Insert("Default", False);
    EventHandlerInfo.Insert("Description");
    EventHandlerInfo.Insert("Publishers", New Map);
    EventHandlerInfo.Insert("Transactional", False);
    EventHandlerInfo.Insert("Version");
    
    Return EventHandlerInfo;
    
EndFunction // NewExternalEventHandlerInfo() 

#EndRegion // SubsystemInteraction

#Region RightsInteraction

// Verifies administrative access rights.
//
Procedure AdministrativeRights() Export

    If NOT PrivilegedMode() Then
        VerifyAccessRights("Administration", Metadata);
    EndIf;

EndProcedure // AdministrativeRights()

#EndRegion // RightsInteraction

#EndRegion // ProgramInterface

#Region ServiceProceduresAndFunctions

#Region FormInteraction

// Only for internal use.
//
Procedure AddFormFieldExtensionForTextBox(FormField)
    
    #If MobileAppServer Then
    FormField.Insert("AutoCapitalizationOnTextInput", AutoCapitalizationOnTextInput.Auto);
    #EndIf
  
    FormField.Insert("AutoChoiceIncomplete");
   
    #If MobileAppServer Then
    FormField.Insert("AutoCorrectionOnTextInput", AutoCorrectionOnTextInput.Auto);
    #EndIf

    FormField.Insert("AutoMarkIncomplete");
    FormField.Insert("AutoMaxHeight", True);
    FormField.Insert("AutoMaxWidth", True);
    
    #If MobileAppServer Then
    FormField.Insert("AutoShowClearButton", AutoShowClearButtonMode.Auto);
    FormField.Insert("AutoShowOpenButton", AutoShowOpenButtonMode.Auto);
    #EndIf
    
    // Unexpected behaviour. FormField.Insert("AvailableTypes");
    FormField.Insert("BackColor", StyleColors.FieldBackColor);
    FormField.Insert("BorderColor", StyleColors.BorderColor);
    FormField.Insert("ChoiceButton");
    FormField.Insert("ChoiceButtonPicture", New Picture);
    FormField.Insert("ChoiceButtonRepresentation", ChoiceButtonRepresentation.Auto);
    FormField.Insert("ChoiceFoldersAndItems", FoldersAndItems.Auto);
    FormField.Insert("ChoiceForm", "");
    FormField.Insert("ChoiceHistoryOnInput", ChoiceHistoryOnInput.Auto);
    FormField.Insert("ChoiceList");
    FormField.Insert("ChoiceListHeight", 0);
    // Unexpected behaviour. FormField.Insert("ChoiceParameterLinks");
    // Unexpected behaviour. FormField.Insert("ChoiceParameters");
    FormField.Insert("ChooseType", True);
    FormField.Insert("ClearButton");
    FormField.Insert("CreateButton");
    FormField.Insert("DropListButton");
    FormField.Insert("DropListWidth", 0);
    FormField.Insert("EditFormat");
    FormField.Insert("EditText");
    FormField.Insert("EditTextUpdate", EditTextUpdate.Auto);
    FormField.Insert("ExtendedEdit");
    FormField.Insert("Font", StyleFonts.NormalTextFont);
    FormField.Insert("Format");
    FormField.Insert("Height", 0);
    
    #If MobileAppServer Then
    FormField.Insert("HeightControlVariant", ItemHeightControlVariant.Auto);
    #EndIf

    FormField.Insert("HorizontalStretch");
    FormField.Insert("IncompleteChoiceMode", IncompleteChoiceMode.OnEnterPressed);
    FormField.Insert("InputHint");
    FormField.Insert("ListChoiceMode", False);
    FormField.Insert("MarkIncomplete", False);
    FormField.Insert("MarkNegatives");
    FormField.Insert("Mask");
    FormField.Insert("MaxHeight", 0);
    FormField.Insert("MaxValue");
    FormField.Insert("MaxWidth", 0);
    FormField.Insert("MinValue");
    FormField.Insert("MultiLine");
    
    #If MobileAppServer Then
    FormField.Insert("OnScreenKeyboardReturnKeyText", OnScreenKeyboardReturnKeyText.Auto);
    #EndIf
    
    FormField.Insert("OpenButton");
    FormField.Insert("PasswordMode");
    FormField.Insert("QuickChoice");
    // Unexpected behaviour. FormField.Insert("SelectedText");
    
    #If MobileAppServer Then
    FormField.Insert("SpecialTextInputMode", SpecialTextInputMode.Auto);
    FormField.Insert("SpellCheckingOnTextInput", SpellCheckingOnTextInput.Auto);
    #EndIf
    
    FormField.Insert("SpinButton");
    FormField.Insert("TextColor", StyleColors.FieldTextColor);
    FormField.Insert("TextEdit", True);
    FormField.Insert("TypeDomainEnabled", True);
    // Unexpected behaviour. FormField.Insert("TypeLink");
    FormField.Insert("VerticalStretch");
    FormField.Insert("Width", 0);
    FormField.Insert("Wrap", True);       
    
EndProcedure // AddFormFieldExtensionForTextBox() 

// Returns property value from structure.
// 
// Parameters:
//  Parameters     - Structure - an object that stores property values.
//  PropertyName   - String    - a property name (key).
//  ErrorMessage   - String    - error message to display if property not found.
//  PerformCheck   - Boolean   - if value is 'True' and the object does not contain the 
//                               property name (key), exception occurs.
//                          Default value: False.
//  DeleteProperty - Boolean   - if value is 'True', property will be deleted from the object.
//                          Default value: False.
//
// Returns:
//  Arbitrary - property value.
//
Function ParametersPropertyValue(Parameters, PropertyName, ErrorMessage, 
    PerformCheck = False, DeleteProperty = False)

    Var ProperyValue;
        
    If NOT Parameters.Property(PropertyName, ProperyValue)
        AND PerformCheck Then
        
        Raise ErrorMessage;   
            
    EndIf;
        
    If DeleteProperty Then 
        Parameters.Delete(PropertyName);
    EndIf;

    Return ProperyValue;

EndFunction // ParametersPropertyValue()

#EndRegion // FormInteraction

#Region SubsystemInteraction

// Only for internal use.
//
Procedure InitializeOperations()
    
    CreateOperation = Catalogs.FL_Operations.Create.GetObject();
    If CreateOperation.RESTMethod.IsEmpty() 
        AND CreateOperation.CRUDMethod.IsEmpty() Then
        
        CreateOperation.RESTMethod = Enums.FL_RESTMethods.POST;
        CreateOperation.CRUDMethod = Enums.FL_CRUDMethods.CREATE;
        CreateOperation.Write();
        
    EndIf;
    
    ReadOperation = Catalogs.FL_Operations.Read.GetObject();
    If ReadOperation.RESTMethod.IsEmpty() 
        AND ReadOperation.CRUDMethod.IsEmpty() Then
        
        ReadOperation.RESTMethod = Enums.FL_RESTMethods.GET;
        ReadOperation.CRUDMethod = Enums.FL_CRUDMethods.READ;
        ReadOperation.Write();
        
    EndIf;
    
    UpdateOperation = Catalogs.FL_Operations.Update.GetObject();
    If UpdateOperation.RESTMethod.IsEmpty() 
        AND UpdateOperation.CRUDMethod.IsEmpty() Then
        
        UpdateOperation.RESTMethod = Enums.FL_RESTMethods.PUT;
        UpdateOperation.CRUDMethod = Enums.FL_CRUDMethods.UPDATE;
        UpdateOperation.Write();
        
    EndIf;
    
    DeleteOperation = Catalogs.FL_Operations.Delete.GetObject();
    If DeleteOperation.RESTMethod.IsEmpty() 
        AND DeleteOperation.CRUDMethod.IsEmpty() Then
        
        DeleteOperation.RESTMethod = Enums.FL_RESTMethods.DELETE;
        DeleteOperation.CRUDMethod = Enums.FL_CRUDMethods.DELETE;
        DeleteOperation.Write();
        
    EndIf;
    
EndProcedure // InitializeOperations()

// Only for internal use.
//
Procedure InitializeChannels()
    
    Try
    
        SelfFilesProcessor = NewAppEndpointProcessor(
            "595e752d-57f4-4398-a1cb-e6c5a6aaa65c");
        
        SelfFiles = Catalogs.FL_Channels.SelfFiles.GetObject();
        SelfFiles.DataExchange.Load = True;
        SelfFiles.BasicChannelGuid = SelfFilesProcessor.LibraryGuid();
        SelfFiles.Connected = True;
        SelfFiles.Log = False;
        SelfFiles.Version = SelfFilesProcessor.Version();
        SelfFiles.Write();
        
    Except
        
        FL_InteriorUse.WriteLog(
            "FoxyLink.InitializeSubsystem.InitializeChannels", 
            EventLogLevel.Error,
            Metadata.Catalogs.FL_Channels,
            ErrorDescription());
        
    EndTry;
        
EndProcedure // InitializeChannels() 

// Only for internal use.
//
Procedure InitializeConstants()
    
    RetryAttempts = Constants.FL_RetryAttempts.Get();
    If RetryAttempts = 0 Then
        FL_JobServer.SetRetryAttempts(FL_JobServer.DefaultRetryAttempts());    
    EndIf;
    
    WorkerCount = Constants.FL_WorkerCount.Get();
    If WorkerCount = 0 Then
        FL_JobServer.SetWorkerCount(FL_JobServer.DefaultWorkerCount());    
    EndIf;
    
    WorkerJobsLimit = Constants.FL_WorkerJobsLimit.Get();
    If WorkerJobsLimit = 0 Then
        FL_JobServer.SetWorkerJobsLimit(FL_JobServer.DefaultWorkerJobsLimit());    
    EndIf;
    
EndProcedure // InitializeConstants() 

// Returns mock object (ValueTable) with imported operations.
//
// Parameters:
//  Operations - Array - an array with imported operations.
//
// Returns:
//  ValueTable - the mock object with imported operations.
// 
Function LoadImportedOperations(Operations)
    
    GuidLength = 36;
    
    MockObject = FL_CommonUse.NewMockOfMetadataObjectAttributes(
        Metadata.Catalogs.FL_Operations);
    MockObject.Columns.Add("Operation", FL_CommonUse.StringTypeDescription(
        GuidLength));

    For Each Operation In Operations Do
        
        MockRow = MockObject.Add();
        FillPropertyValues(MockRow, Operation, , "CRUDMethod, RESTMethod");
        
        If NOT IsBlankString(Operation.CRUDMethod) Then
            MockRow.CRUDMethod = Enums.FL_CRUDMethods[Operation.CRUDMethod];
        EndIf;
        
        If NOT IsBlankString(Operation.RESTMethod) Then
            MockRow.RESTMethod = Enums.FL_RESTMethods[Operation.RESTMethod];
        EndIf;
        
        Result = FL_CommonUse.ReferenceByPredefinedDataName(
            Metadata.Catalogs.FL_Operations, Operation.PredefinedDataName);
        If Result <> Undefined Then
            MockRow.Ref = Result;
            Continue;
        EndIf;
        
        Result = Catalogs.FL_Operations.GetRef(New UUID(Operation.Operation));
        If FL_CommonUse.RefExists(Result) Then
            MockRow.Ref = Result;
            Continue;
        EndIf;
        
        Result = FL_CommonUse.ReferenceByDescription(
            Metadata.Catalogs.FL_Operations, Operation.Description);
        If Result <> Undefined Then
            MockRow.Ref = Result;    
        EndIf;
        
    EndDo;
    
    Return MockObject;
    
EndFunction // LoadImportedOperations()

// Returns mock object (ValueTable) with imported channels.
//
// Parameters:
//  Channels - Array - an array with imported channels.
//
// Returns:
//  ValueTable - the mock object with imported channels.
// 
Function LoadImportedChannels(Channels)
    
    GuidLength = 36;
    
    MockObject = FL_CommonUse.NewMockOfMetadataObjectAttributes(
        Metadata.Catalogs.FL_Channels);
    MockObject.Columns.Add("Channel", FL_CommonUse.StringTypeDescription(
        GuidLength));

    For Each Channel In Channels Do
        
        MockRow = MockObject.Add();
        FillPropertyValues(MockRow, Channel);
        
        Result = FL_CommonUse.ReferenceByPredefinedDataName(
            Metadata.Catalogs.FL_Channels, Channel.PredefinedDataName);
        If Result <> Undefined Then
            MockRow.Ref = Result;
            Continue;
        EndIf;
        
        Result = Catalogs.FL_Channels.GetRef(New UUID(Channel.Channel));
        If FL_CommonUse.RefExists(Result) Then
            MockRow.Ref = Result;
            Continue;
        EndIf;
        
        Result = FL_CommonUse.ReferenceByDescription(
            Metadata.Catalogs.FL_Channels, Channel.Description);
        If Result <> Undefined Then
            MockRow.Ref = Result;    
        EndIf;
        
    EndDo;
    
    Return MockObject;
    
EndFunction // LoadImportedChannels()

#EndRegion // SubsystemInteraction

#Region LogInteraction 

// Returns a log message object that must be passed to the function 
// FL_InteriorUse.EndLogHTTPRequest.
//
// Parameters:
//  HTTPConnection - HTTPConnection - an object to interact with external 
//                          systems by HTTP protocol, including file transfer.
//  HTTPRequest    - HTTPRequest    - describes the HTTP-requests sent using 
//                          the HTTPConnection object. 
//  HTTPMethod     - String         - HTTP method name.
//
// Returns:
//  Structure - see function FL_InteriorUse.NewLogMessageHTTP.
//
Function StartLogHTTPRequest(HTTPConnection, HTTPRequest, HTTPMethod)
    
    MessageSize = HTTPRequest.GetBodyAsStream().Size();
    
    LogMessage = NewLogMessageHTTP();
    LogMessage.HostURL = HTTPConnection.Host;
    LogMessage.HTTPMethod = Upper(HTTPMethod);
    LogMessage.ResourceAddress = HTTPRequest.ResourceAddress;
    If FL_InteriorUseReUse.IsHTTPMethodWithoutBody(Upper(HTTPMethod)) Then
        LogMessage.Delete("RequestBody");
    ElsIf FL_InteriorUseReUse.MaximumMessageSize() < MessageSize Then
        LogMessage.RequestBody = NStr(
            "en='The body of the message was deleted as it exceeded the maximum message size.';
            |ru='Тело сообщения удалено, так как оно превысило максимальный размер сообщения.';
            |uk='Тіло повідомлення видалено, так як воно перевищило максимальний розмір повідомлення.';
            |en_CA='The body of the message was deleted as it exceeded the maximum message size.'");         
    Else
        LogMessage.RequestBody = HTTPRequest.GetBodyAsString();   
    EndIf;
    
    Return LogMessage;
    
EndFunction // StartLogHTTPRequest()

// Returns complete log message.
//
// Parameters:
//  LogObject    - Structure - see function FL_InteriorUse.NewLogMessageHTTP.
//  StatusCode   - Number    - HTTP server status (response) code.
//  ResponseBody - String    - response body as a string.
//
// Returns:
//  String - complete log message.
//
Function EndLogHTTPRequest(LogObject, StatusCode, ResponseBody)
    
    LogObject.StatusCode = StatusCode;
    LogObject.ResponseBody = ResponseBody;
    LogObject.DoneResponse = CurrentUniversalDate();   
    LogObject.Elapsed = CurrentUniversalDateInMilliseconds() - LogObject.Elapsed;
    
    If LogObject.Property("RequestBody") Then
        
        Return StrTemplate("BeginRequest: %1
                |
                |REQUEST URL
                |Host URL: %2
                |Resource: %3 %4
                |
                |REQUEST BODY
                |%5
                |
                |RESPONSE BODY
                |Result: %6
                |%7
                |
                |DoneResponse: %8
                |Overall Elapsed: %9 ms
                |----------------------------------------------------------------------
                |", 
            LogObject.BeginRequest,
            LogObject.HostURL,
            LogObject.HTTPMethod,
            LogObject.ResourceAddress,
            LogObject.RequestBody,
            LogObject.StatusCode,
            LogObject.ResponseBody,
            LogObject.DoneResponse,
            LogObject.Elapsed);
        
    Else
        
        Return StrTemplate("BeginRequest: %1
                |
                |REQUEST URL
                |Host URL: %2
                |Resource: %3 %4
                |
                |RESPONSE BODY 
                |Result: %5
                |%6
                |
                |DoneResponse: %7
                |Overall Elapsed: %8 ms
                |----------------------------------------------------------------------
                |", 
            LogObject.BeginRequest,
            LogObject.HostURL,
            LogObject.HTTPMethod,
            LogObject.ResourceAddress,
            LogObject.StatusCode,
            LogObject.ResponseBody,
            LogObject.DoneResponse,
            LogObject.Elapsed);
        
    EndIf;
    
EndFunction // EndLogHTTPRequest()

// Returns a new basic HTTP log message.
//
// Returns:
//  Structure - the new basic HTTP log message:
//      * BeginRequest    - Date   - time at which this HTTP request began.
//      * HostURL         - String - host name.
//      * HTTPMethod      - String - the name of the HTTP method.
//      * ResourceAddress - String - line of the http resource. 
//      * RequestBody     - String - request body as a string.  
//      * StatusCode      - Number - HTTP server status (response) code.
//      * ResponseBody    - String - response body as a string.
//      * DoneResponse    - Date   - HTTP request processed time.             
//      * Elapsed         - Date   - time at which this HTTP request began.
//                        - Number - request execution time in ms.
//
Function NewLogMessageHTTP()
    
    LogMessageHTTP = New Structure;
    LogMessageHTTP.Insert("BeginRequest", CurrentUniversalDate());
    LogMessageHTTP.Insert("HostURL");
    LogMessageHTTP.Insert("HTTPMethod");
    LogMessageHTTP.Insert("ResourceAddress");
    LogMessageHTTP.Insert("RequestBody");
    LogMessageHTTP.Insert("StatusCode");
    LogMessageHTTP.Insert("ResponseBody");
    LogMessageHTTP.Insert("DoneResponse");
    LogMessageHTTP.Insert("Elapsed", CurrentUniversalDateInMilliseconds());
    Return LogMessageHTTP;
    
EndFunction // NewLogMessageHTTP()

#EndRegion // LogInteraction

#EndRegion // ServiceProceduresAndFunctions
