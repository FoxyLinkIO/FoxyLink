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

#Region ObjectFormInteraction

// Loads data composition schema, data composition settings and operations 
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
        If FilterResult.Count() = 0 Then
            
            // This code is needed to fix problem with platform bug.
            If Item.ChildItems.Find("HiddenGroupSettings") <> Undefined Then
                FL_InteriorUse.MoveItemInItemFormCollectionNoSearch(Items, 
                    Items.HiddenGroupSettings, Items.HiddenGroup);        
            EndIf;
            
            Items.Delete(Item);
            
        EndIf;
        
    EndDo;
    
    // Hide or unhide delete operation button.
    Items.DeleteOperation.Visible = Operations.Count() > 0;   
    
EndProcedure // UpdateOperationsView()

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
    InvocationData.Operation = Catalogs.FL_Operations.Read;
    InvocationData.Owner = Catalogs.FL_Exchanges.Self;
    InvocationData.SourceObject = ExchangeRef;
    
    Try 
        
        BeginTransaction();
        
        Job = FL_BackgroundJob.Enqueue(InvocationData);
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
        
        #If MobileAppServer Then
        FileProperties.ModificationTime = CurrentDate();
        #ElsIf Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
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
//  ExchangeSettings - Structure - see function Catalog.FL_Exchanges.NewExchangeSettings.
//  MessageSettings  - Structure - see function FL_DataComposition.NewMessageSettings.
//                          Default value: Undefined.
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
//
Function NewOutputParameters(ExchangeSettings, 
    MessageSettings = Undefined) Export
    
    SettingsComposer = New DataCompositionSettingsComposer;
    FL_DataComposition.InitSettingsComposer(SettingsComposer,
        ExchangeSettings.DataCompositionSchema,
        ExchangeSettings.DataCompositionSettings);

    If MessageSettings <> Undefined Then 
        FL_DataComposition.SetDataToSettingsComposer(SettingsComposer, 
            MessageSettings); 
    EndIf;
        
    DataCompositionTemplate = FL_DataComposition
        .NewTemplateComposerParameters();
    DataCompositionTemplate.Schema   = ExchangeSettings.DataCompositionSchema;
    DataCompositionTemplate.Template = SettingsComposer.GetSettings();
    
    OutputParameters = FL_DataComposition.NewOutputParameters();
    OutputParameters.DCTParameters = DataCompositionTemplate;
    OutputParameters.CanUseExternalFunctions = ExchangeSettings
        .CanUseExternalFunctions;
        
    Return OutputParameters;
  
EndFunction // NewOutputParameters()

// Returns exchange settings.
//
// Parameters:
//  ExchangeRef  - CatalogRef.FL_Exchanges  - reference of the FL_Exchanges catalog.
//  OperationRef - CatalogRef.FL_Operations - reference of the FL_Operations catalog.
//
// Returns:
//  FixedStructure  - exchange settings.  
//
Function ExchangeSettingsByRefs(ExchangeRef, OperationRef) Export

    Query = New Query;
    Query.Text = QueryTextExchangeSettingsByRefs();
    Query.SetParameter("ExchangeRef", ExchangeRef);
    Query.SetParameter("OperationRef", OperationRef);
    QueryResult = Query.Execute();
    
    Return New FixedStructure(ExchangeSettingsByQueryResult(QueryResult, 
        ExchangeRef, OperationRef));

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

#Region ServiceProceduresAndFunctions

#Region ObjectFormInteraction

// Only for internal use.
//
Procedure PlaceStorageDataIntoFormObject(FormObject, CurrentObject, FormUUID)
    
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
        
EndProcedure // PlaceStorageDataIntoFormObject()

// Only for internal use.
//
Procedure ProcessBeforeWriteAtServer(FormObject, CurrentObject)
    
    FormOperations = FormObject.Operations;
    ObjectOperations = CurrentObject.Operations;
    For Each FormRow In FormOperations Do
        
        ObjectRow = ObjectOperations.Find(FormRow.Operation, "Operation");
        
        FillPropertyValues(ObjectRow, FormRow, "CanUseExternalFunctions, 
            |Priority"); 
        
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
    
EndProcedure // ProcessBeforeWriteAtServer() 
    
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
        
        ErrorMessage = StrReplace(Nstr("en='Error: Exchange settings {%1} and/or operation {%2} not found.';
                |ru='Ошибка: Настройки обмена {%1} и/или операция {%2} не найдены.';
                |en_CA='Error: Exchange settings {%1} and/or operation {%2} not found.'"),
            String(Exchange), String(Operation)); 
            
        Raise ErrorMessage;
        
    EndIf;

    ValueTable = QueryResult.Unload();
    If ValueTable.Count() > 1 Then
        
        ErrorMessage = StrReplace(Nstr("en='Error: Duplicated records of exchange settings {%1} and operation {%2} are found.';
                |ru='Ошибка: Обнаружены дублирующиеся настройки обмена {%1} и операция {%2}.';
                |en_CA='Error: Duplicated records of exchange settings {%1} and operation {%2} are found.'"),
            String(Exchange), String(Operation));
            
        Return ErrorMessage;
        
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

    QueryText = "
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
    Return QueryText;

EndFunction // QueryTextExchangeSettingsByNames()

#EndRegion // ServiceProceduresAndFunctions

#EndIf