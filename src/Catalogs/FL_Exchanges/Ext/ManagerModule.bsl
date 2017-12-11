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

#Region ObjectFormInteraction

// Loads data composition schema, data composition settings and methods 
// for editing in catalog form.
//
// Parameters:
//  ManagedForm - ManagedForm - catalog form.  
//
Procedure OnCreateAtServer(ManagedForm) Export

    Object = ManagedForm.Object;
    If TypeOf(Object.Ref) <> Type("CatalogRef.FL_Exchanges") 
        OR NOT ValueIsFilled(Object.Ref) Then
        Return;
    EndIf;
    
    // ManagedForm.UUID is used to remove automatically the value after 
    // closing the form.
    PlaceStorageDataIntoFormObject(Object, Object.Ref, ManagedForm.UUID);
    
EndProcedure // OnCreateAtServer()

// Updates methods view on managed form.
//
// Parameters:
//  ManagedForm - ManagedForm - catalog form.  
//
Procedure UpdateMethodsView(ManagedForm) Export
    
    Items = ManagedForm.Items;
    Methods = ManagedForm.Object.Methods;
    
    // Add methods from object.
    For Each Item In Methods Do
        
        MethodDescription = Item.Method.Description;
        
        SearchResult = Items.Find(MethodDescription);
        If SearchResult <> Undefined Then
            SearchResult.Picture = PictureLib.FL_InvalidMethodSettings;
        Else
            AddMethodOnForm(Items, MethodDescription, Item.OperationDescription,
                PictureLib.FL_InvalidMethodSettings);
        EndIf;
            
    EndDo;
    
    For Each Item In Items.MethodPages.ChildItems Do
        
        Method = Catalogs.FL_Methods.MethodByDescription(Item.Name);
        FilterResult = Methods.FindRows(New Structure("Method", Method));
        If FilterResult.Count() = 0 Then
            
            // This code is needed to fix problem with platform bug.
            If Item.ChildItems.Find("HiddenGroupSettings") <> Undefined Then
                FL_InteriorUse.MoveItemInItemFormCollectionNoSearch(Items, 
                    Items.HiddenGroupSettings, Items.HiddenGroup);        
            EndIf;
            
            Items.Delete(Item);
            
        EndIf;
        
    EndDo;
    
    // Hide or unhide delete method button.
    Items.DeleteAPIMethod.Visible = Methods.Count() > 0;   
    
EndProcedure // UpdateMethodsView()

// Helps to save untracked changes in catalog form.
//
// Parameters:
//  ManagedForm   - ManagedForm                - catalog form.
//  CurrentObject - CatalogObject.FL_Exchanges - object that is used 
//                  for reading, modifying, adding and deleting catalog items. 
//
Procedure BeforeWriteAtServer(ManagedForm, CurrentObject) Export
    
    ProcessBeforeWriteAtServer(ManagedForm.Object, CurrentObject);        
    
EndProcedure // BeforeWriteAtServer()

#EndRegion // ObjectFormInteraction

// Outputs the resulting message into stream based on the specified exchange settings.
//
// Parameters:
//  Stream           - Stream         - a data stream that can be read successively 
//                                       or/and where you can record successively. 
//                   - MemoryStream   - specialized version of Stream object for 
//                                       operation with the data located in the RAM.
//                   - FileStream     - specialized version of Stream object for 
//                                       operation with the data located in a file on disk.
//  ExchangeSettings - FixedStructure - exchange settings.
//  MessageSettings  - FixedStructure - message settings.
//                          Default value: Undefined.
//
// Returns:
//  Arbitrary - the resulting message.
//
Procedure OutputMessageIntoStream(Stream, ExchangeSettings, 
    MessageSettings = Undefined) Export
    
    DataCompositionSchema = GetValueFromStorage(ExchangeSettings, 
        "DataCompositionSchema");
    DataCompositionSettings = GetValueFromStorage(ExchangeSettings, 
        "DataCompositionSettings");
    
    SettingsComposer = New DataCompositionSettingsComposer;
    FL_DataComposition.InitSettingsComposer(SettingsComposer,
        DataCompositionSchema,
        DataCompositionSettings);

    If MessageSettings <> Undefined Then 
        FL_DataComposition.SetDataToSettingsComposer(SettingsComposer, 
            MessageSettings); 
    EndIf;
        
    DataCompositionTemplate = FL_DataComposition
        .NewTemplateComposerParameters();
    DataCompositionTemplate.Schema   = DataCompositionSchema;
    DataCompositionTemplate.Template = SettingsComposer.GetSettings();
    
    OutputParameters = FL_DataComposition.NewOutputParameters();
    OutputParameters.DCTParameters = DataCompositionTemplate;
    OutputParameters.CanUseExternalFunctions = ExchangeSettings
        .CanUseExternalFunctions;
    
    StreamObject = NewFormatProcessor(ExchangeSettings.BasicFormatGuid);
    StreamObject.Initialize(Stream, GetValueFromStorage(ExchangeSettings, 
            "APISchema"));    
    FL_DataComposition.Output(StreamObject, OutputParameters);    
    StreamObject.Close();    
    
EndProcedure // OutputMessageIntoStream()

// Returns the whole object exchange settings.
//
// Parameters:
//  BinaryData - BinaryData - the value contains binary data read from the file.
//
// Returns:
//  Structure - structure with import settings.
//
Function ImportObject(BinaryData) Export
    
    JSONReader = New JSONReader;
    JSONReader.OpenStream(BinaryData.OpenStreamForRead());
    
    ExchangeStructure = NewExchangeStructure();
    While JSONReader.Read() Do
        
        If JSONReader.CurrentValueType = JSONValueType.PropertyName AND 
            Upper(JSONReader.CurrentValue) = Upper("Exchange") Then
            JSONReader.Read();
            ExchangeStructure.Exchange = XDTOSerializer.ReadJSON(JSONReader);     
        EndIf;
        
    EndDo;
    
    //ObjectStructure = ReadJSON(JSONReader);
    JSONReader.Close();
    
    Return ExchangeStructure;
    
EndFunction // ImportObject()

// Exports the whole object exchange settings.
//
// Parameters:
//  ExchangeRef - CatalogRef.FL_Exchanges - exchange to export.
//
// Returns:
//  Structure - see function FL_InteriorUseClientServer.NewFileProperties.
//
Function ExportObject(ExchangeRef) Export
    
    InvocationData = FL_BackgroundJob.NewInvocationData();
    InvocationData.Arguments = ExchangeRef;
    InvocationData.MetadataObject = "Catalog.FL_Exchanges";
    InvocationData.Method = Catalogs.FL_Methods.Read;
    InvocationData.Owner = Catalogs.FL_Exchanges.Self;
    InvocationData.SourceObject = ExchangeRef;
    
    Try 
        
        BeginTransaction();
        
        Job = FL_BackgroundJob.Enqueue("Catalogs.FL_Jobs.Trigger", 
            InvocationData);
        Catalogs.FL_Jobs.Trigger(Job);
    
        CommitTransaction();
        
    Except
        
        RollbackTransaction();
        Raise;
        
    EndTry;
    
    If Job.State = Catalogs.FL_States.Succeeded 
        AND Job.SubscribersLog.Count() > 0 Then
        
        FileData = Job.SubscribersLog[0].OriginalResponse.Get();
        FileDescription = FL_CommonUse.ObjectAttributeValue(ExchangeRef, 
            "Description");
    
        FileProperties = FL_InteriorUseClientServer.NewFileProperties();
        FileProperties.Name = StrTemplate("%1.json", FileDescription);
        FileProperties.BaseName = FileDescription;
        FileProperties.Extension = ".json";
        FileProperties.Size = FileData.Size();
        FileProperties.IsFile = True;
        FileProperties.StorageAddress = PutToTempStorage(FileData);
        FileProperties.ModificationTime = CurrentSessionDate();
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
            
                DataProcessor = DataProcessors[Item.Name].Create();                
                ValueList.Add(DataProcessor.LibraryGuid(),
                    StrTemplate("%1 (%2), ver. %3", 
                        DataProcessor.FormatShortName(),
                        DataProcessor.FormatStandard(),
                        DataProcessor.Version()));
            
            Except
                
                FL_CommonUseClientServer.NotifyUser(ErrorDescription());
                Continue;
                
            EndTry;
            
        EndIf;
        
    EndDo;
    
    Return ValueList;
    
EndFunction // AvailableFormats()

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
           
    Return DataProcessors[DataProcessorName].Create();
        
EndFunction // NewFormatProcessor()

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

// Returns exchange settings.
//
// Parameters:
//  ExchangeRef - CatalogRef.FL_Exchanges - reference of the FL_Exchanges catalog.
//  MethodRef   - CatalogRef.FL_Methods   - reference of the FL_Methods catalog.
//
// Returns:
//  FixedStructure  - exchange settings. 
//  String          - error description. 
//
Function ExchangeSettingsByRefs(ExchangeRef, MethodRef) Export

    Query = New Query;
    Query.Text = QueryTextExchangeSettingsByRefs();
    Query.SetParameter("ExchangeRef", ExchangeRef);
    Query.SetParameter("MethodRef", MethodRef);

    QueryResult = Query.Execute();
    If QueryResult.IsEmpty() Then
        ErrorMessage = StrReplace(Nstr(
                "en = 'Error: Exchange settings ''%1'' and/or method ''%2'' not found.'; 
                |ru = 'Ошибка: Настройки обмена ''%1'' и/или метод ''%2'' не найдены.'"),
            String(ExchangeRef), String(MethodRef));    
        Return ErrorMessage;
    EndIf;

    ValueTable = QueryResult.Unload();
    If ValueTable.Count() > 1 Then
        ErrorMessage = StrReplace(Nstr(
                "en = 'Error: Duplicated records of exchange settings ''%1'' and method ''%2'' are found.'; 
                |ru = 'Ошибка: Обнаружены дублирующиеся настройки обмена ''%1'' и метод ''%2''.'"),
            String(ExchangeRef), String(MethodRef));
        Return ErrorMessage;     
    EndIf;

    FullSettings = FL_CommonUse.ValueTableRowIntoStructure(ValueTable[0]);
    ExchangeSettings = NewExchangeSettings();
    FillPropertyValues(ExchangeSettings, FullSettings);
    Return New FixedStructure(ExchangeSettings);

EndFunction // ExchangeSettingsByNameAndMethod()

// Returns exchange settings.
//
// Parameters:
//  ExchangeName - String - name of the FL_Exchanges catalog.
//  MethodName   - String - name of the FL_Methods catalog.
//
// Returns:
//  FixedStructure  - exchange settings. 
//  String          - error description. 
//
Function ExchangeSettingsByNames(Val ExchangeName, Val MethodName) Export

    Query = New Query;
    Query.Text = QueryTextExchangeSettingsByNames();
    Query.SetParameter("ExchangeName", ExchangeName);
    Query.SetParameter("MethodName", MethodName);

    QueryResult = Query.Execute();
    If QueryResult.IsEmpty() Then
        ErrorMessage = StrReplace(Nstr(
                "en = 'Error: Exchange settings ''%1'' and/or method ''%2'' not found.'; 
                |ru = 'Ошибка: Настройки обмена ''%1'' и/или метод ''%2'' не найдены.'"),
            ExchangeName, MethodName);    
        Return ErrorMessage;
    EndIf;

    ValueTable = QueryResult.Unload();
    If ValueTable.Count() > 1 Then
        ErrorMessage = StrReplace(Nstr(
                "en = 'Error: Duplicated records of exchange settings ''%1'' and method ''%2'' are found.'; 
                |ru = 'Ошибка: Обнаружены дублирующиеся настройки обмена ''%1'' и метод ''%2''.'"),
            ExchangeName, MethodName);
        Return ErrorMessage;     
    EndIf;

    FullSettings = FL_CommonUse.ValueTableRowIntoStructure(ValueTable[0]);
    ExchangeSettings = NewExchangeSettings();
    FillPropertyValues(ExchangeSettings, FullSettings); 
    Return New FixedStructure(ExchangeSettings);

EndFunction // ExchangeSettingsByNames()

#EndRegion // ProgramInterface

#Region ServiceProceduresAndFunctions

#Region ObjectFormInteraction

// Only for internal use.
//
Procedure PlaceStorageDataIntoFormObject(Object, Ref, FormUUID)
        
    FilterParameters = New Structure("Method, APIVersion"); 
    For Each Item In Object.Methods Do
        
        FillPropertyValues(FilterParameters, Item); 
        FilterResult = Ref.Methods.FindRows(FilterParameters);
        If FilterResult.Count() = 1 Then
            
            ItemRow = FilterResult[0];
            DataCompositionSchema = ItemRow.DataCompositionSchema.Get();
            If DataCompositionSchema <> Undefined Then
                Item.DataCompositionSchemaAddress = PutToTempStorage(
                    DataCompositionSchema, FormUUID);
            EndIf;
            
            DataCompositionSettings = ItemRow.DataCompositionSettings.Get();
            If DataCompositionSettings <> Undefined Then
                Item.DataCompositionSettingsAddress = PutToTempStorage(
                    DataCompositionSettings, FormUUID);
            EndIf;

            APISchema = ItemRow.APISchema.Get();
            If APISchema <> Undefined Then
                Item.APISchemaAddress = PutToTempStorage(APISchema, FormUUID);
            EndIf; 
            
        EndIf;

    EndDo;
        
EndProcedure // PlaceStorageDataIntoFormObject()

// Only for internal use.
//
Procedure ProcessBeforeWriteAtServer(FormObject, CurrentObject)
    
    FMethods = FormObject.Methods;
    CMethods = CurrentObject.Methods;
    
    FilterParameters = New Structure("Method, APIVersion");
    
    For Each FMethod In FMethods Do
        
        FillPropertyValues(FilterParameters, FMethod);
        FilterResults = CMethods.FindRows(FilterParameters);
        For Each FilterResult In FilterResults Do
            
            FillPropertyValues(FilterResult, FMethod, "CanUseExternalFunctions"); 
            
            If IsTempStorageURL(FMethod.DataCompositionSchemaAddress) Then
                FilterResult.DataCompositionSchema = New ValueStorage(
                    GetFromTempStorage(FMethod.DataCompositionSchemaAddress));
            Else
                FilterResult.DataCompositionSchema = New ValueStorage(Undefined);
            EndIf;
            
            If IsTempStorageURL(FMethod.DataCompositionSettingsAddress) Then
                FilterResult.DataCompositionSettings = New ValueStorage(
                    GetFromTempStorage(FMethod.DataCompositionSettingsAddress));
            Else
                FilterResult.DataCompositionSettings = New ValueStorage(Undefined);
            EndIf;
            
            If IsTempStorageURL(FMethod.APISchemaAddress) Then
                FilterResult.APISchema = New ValueStorage(
                    GetFromTempStorage(FMethod.APISchemaAddress));
            Else
                FilterResult.APISchema = New ValueStorage(Undefined);
            EndIf;
            
        EndDo;
        
    EndDo;
    
EndProcedure // ProcessBeforeWriteAtServer() 
    
// Add a new group page that corresponds to a method.
//
// Parameters:
//  Items             - FormAllItems - collection of all managed form items.
//  MethodDescription - String       - the method name.
//  Description       - String       - the method description. 
//  Picture           - Picture      - title picture.
//
Procedure AddMethodOnForm(Items, MethodDescription, Description, Picture)

    BasicDescription = NStr(
        "en = 'Description is not available.';
        |ru = 'Описание операции не доступно.'");

    Parameters = New Structure;
    Parameters.Insert("Name", MethodDescription);
    Parameters.Insert("Title", MethodDescription);
    Parameters.Insert("Type", FormGroupType.Page);
    Parameters.Insert("ElementType", Type("FormGroup"));
    Parameters.Insert("EnableContentChange", False);
    Parameters.Insert("Picture", Picture);
    NewPage = FL_InteriorUse.AddItemToItemFormCollection(Items, Parameters, 
        Items.MethodPages);
        
    Parameters = New Structure;
    Parameters.Insert("Name", "Label" + MethodDescription);
    Parameters.Insert("Title", ?(IsBlankString(Description), BasicDescription, 
        Description));
    Parameters.Insert("Type", FormDecorationType.Label);
    Parameters.Insert("ElementType", Тип("FormDecoration"));
    Parameters.Insert("TextColor", New Color(0, 0, 0));
    Parameters.Insert("Font", New Font(, , True));
    FL_InteriorUse.AddItemToItemFormCollection(Items, Parameters, 
        NewPage);

EndProcedure // AddMethodOnForm()

#EndRegion // ObjectFormInteraction

// Only for internal use.
//
Function NewExchangeStructure()
    
    ExchangeStructure = New Structure;
    ExchangeStructure.Insert("Exchange");
    ExchangeStructure.Insert("Channels", New Array);
    ExchangeStructure.Insert("Methods", New Array);
    Return ExchangeStructure;
    
EndFunction // NewExchangeStructure()

// Only for internal use.
//
Function GetValueFromStorage(Storage, Key)
    
    Var Value;
    
    If Storage.Property(Key, Value) 
        AND TypeOf(Value) = Type("ValueStorage") Then
        
        Return Value.Get();   

    EndIf;
    
    Return Value;

EndFunction // GetValueFromStorage()

// Only for internal use.
//
Function QueryTextExchangeSettingsByRefs()

    QueryText = "
        |SELECT
        |   ExchangeSettings.Ref                AS Ref,
        |   ExchangeSettings.Description        AS Description,
        |   ExchangeSettings.BasicFormatGuid    AS BasicFormatGuid,
        |   ExchangeSettings.InUse              AS InUse,
        |
        |   ExchangeSettingsMethods.APIVersion              AS APIVersion,
        |   ExchangeSettingsMethods.APISchema               AS APISchema,
        |   ExchangeSettingsMethods.DataCompositionSchema   AS DataCompositionSchema,
        |   ExchangeSettingsMethods.DataCompositionSettings AS DataCompositionSettings,
        |   ExchangeSettingsMethods.CanUseExternalFunctions AS CanUseExternalFunctions,
        |   ExchangeSettingsMethods.OperationDescription    AS MethodDescription,
        |
        |   FL_Methods.Ref         AS Method,
        |   FL_Methods.RESTMethod  AS RESTMethod,
        |   FL_Methods.CRUDMethod  AS CRUDMethod
        |
        |   
        |
        |FROM
        |   Catalog.FL_Exchanges AS ExchangeSettings
        |   
        |INNER JOIN Catalog.FL_Exchanges.Methods AS ExchangeSettingsMethods
        |ON  ExchangeSettingsMethods.Ref = ExchangeSettings.Ref
        |   
        |INNER JOIN Catalog.FL_Methods AS FL_Methods
        |ON  FL_Methods.Ref = &MethodRef
        |AND FL_Methods.Ref = ExchangeSettingsMethods.Method
        |   
        |WHERE
        |    ExchangeSettings.Ref = &ExchangeRef
        |AND ExchangeSettings.DeletionMark = FALSE
        |";  
    Return QueryText;

EndFunction // QueryTextExchangeSettingsByRefs()

// Only for internal use.
//
Function QueryTextExchangeSettingsByNames()

    QueryText = "
        |SELECT
        |   ExchangeSettings.Ref                AS Ref,
        |   ExchangeSettings.Description        AS Description,
        |   ExchangeSettings.BasicFormatGuid    AS BasicFormatGuid,
        |   ExchangeSettings.InUse              AS InUse,
        |
        |   ExchangeSettingsMethods.APIVersion              AS APIVersion,
        |   ExchangeSettingsMethods.APISchema               AS APISchema,
        |   ExchangeSettingsMethods.DataCompositionSchema   AS DataCompositionSchema,
        |   ExchangeSettingsMethods.DataCompositionSettings AS DataCompositionSettings,
        |   ExchangeSettingsMethods.CanUseExternalFunctions AS CanUseExternalFunctions,
        |   ExchangeSettingsMethods.OperationDescription    AS MethodDescription,
        |
        |   FL_Methods.Ref         AS Method,
        |   FL_Methods.RESTMethod  AS RESTMethod,
        |   FL_Methods.CRUDMethod  AS CRUDMethod
        |
        |FROM
        |   Catalog.FL_Exchanges AS ExchangeSettings
        |   
        |INNER JOIN Catalog.FL_Exchanges.Methods AS ExchangeSettingsMethods
        |ON  ExchangeSettingsMethods.Ref = ExchangeSettings.Ref
        |   
        |INNER JOIN Catalog.FL_Methods AS FL_Methods
        |ON  FL_Methods.Description = &MethodName
        |AND FL_Methods.Ref         = ExchangeSettingsMethods.Method
        |   
        |WHERE
        |    ExchangeSettings.Description = &ExchangeName
        |AND ExchangeSettings.DeletionMark = FALSE
        |";  
    Return QueryText;

EndFunction // QueryTextExchangeSettingsByNames()

#EndRegion // ServiceProceduresAndFunctions

#EndIf