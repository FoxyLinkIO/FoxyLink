////////////////////////////////////////////////////////////////////////////////
// This file is part of FoxyLink.
// Copyright © 2016-2020 Petro Bazeliuk.
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

#Region Public

// Returns the external event handler info structure for this module.
//
// Returns:
//  Structure - see function FL_InteriorUse.NewExternalEventHandlerInfo.
//
Function EventHandlerInfo() Export
    
    Version = ModuleVersion();
    Description = NStr("en='FoxyLink exchange event handler, ver. %1.';
        |ru='Обработчик событий обменов FoxyLink, вер. %1.';
        |uk='Обробник подій обмінів FoxyLink, вер. %1.';
        |en_CA='FoxyLink exchange event handler, ver. %1.'");
    
    EventHandlerInfo = FL_InteriorUse.NewExternalEventHandlerInfo();
    EventHandlerInfo.EventHandler = "FL_Exchange.ProcessMessage";
    EventHandlerInfo.Version = Version;
    EventHandlerInfo.Transactional = False;
    EventHandlerInfo.Description = StrTemplate(Description, Version);
        
    EventSources = New Array;
    EventSources.Add(Upper("HTTPService.FL_AppEndpoint"));
    EventSources.Add(Upper("HTTPСервис.FL_AppEndpoint"));
    
    EventHandlerInfo.Publishers.Insert(Catalogs.FL_Operations.Merge, 
        EventSources); 
       
    Return FL_CommonUse.FixedData(EventHandlerInfo);
    
EndFunction // EventHandlerInfo()

// Returns version of a common module.
//
// Returns:
//  String - version of the common module.
//
Function ModuleVersion() Export
    
    Return "1.0.1";
    
EndFunction // ModuleVersion()

#EndRegion // Public

#Region Internal

// Returns a processing result.
//
// Parameters:
//  AppProperties - Structure - see function Catalogs.FL_Channels.NewAppProperties.
//  Invocation    - Structure - see function Catalogs.FL_Messages.NewInvocation.
//
// Returns:
//  Structure - see fucntion Catalogs.FL_Jobs.NewJobResult. 
//
Function ProcessMessage(AppProperties, Invocation) Export
    
    JobResult = Catalogs.FL_Jobs.NewJobResult();
    If Invocation.Operation = Catalogs.FL_Operations.Merge Then
        MergeOperation(Invocation, JobResult);
    EndIf;
    
    JobResult.Success = FL_InteriorUseReUse.IsSuccessHTTPStatusCode(
        JobResult.StatusCode);
    Return JobResult;
  
EndFunction // ProcessMessage()

#EndRegion // Internal

#Region Private

// Only for internal use.
//
Procedure FillJobResult(Invocation, JobResult)
    
    // MemoryStream = New MemoryStream;
    //
    // JSONWriter = New JSONWriter;
    // JSONWriter.OpenStream(MemoryStream);
    // WriteJSON(JSONWriter, Response);
    // JSONWriter.Close();
    //
    // Invocation.Payload = MemoryStream.CloseAndGetBinaryData();
    
    Catalogs.FL_Jobs.AddToJobResult(JobResult, "Invocation", Invocation);
    If NOT ValueIsFilled(JobResult.StatusCode) Then
        JobResult.StatusCode = FL_InteriorUseReUse.OkStatusCode();
    EndIf;
    
EndProcedure // FillJobResult()

// Only for internal use.
//
Procedure MergeOperation(Invocation, JobResult)

    OutInvocation = Catalogs.FL_Messages.NewInvocation();
    FillPropertyValues(OutInvocation, Invocation);
    OutInvocation.ContentType = "application/json";
    OutInvocation.FileExtension = ".json";
   
    Try
        
        AdditionalParameters = New Structure;
        AdditionalParameters.Insert("ReadToMap", False);
        
        Payload = Catalogs.FL_Messages.ReadInvocationPayload(Invocation, 
            AdditionalParameters); 
        If NOT IsValidMessage(Payload, JobResult) Then
            Return;
        EndIf;
        
        MetadataObject = Metadata.FindByFullName(Payload.Metadata);
        If MetadataObject = Undefined Then
            
            StatusCode = FL_InteriorUseReUse.UnprocessableEntity();
            ErrorMessage = FL_ErrorsClientServer.ErrorConfigurationObjectNotFound(
                Payload.Metadata);
            FL_InteriorUse.WriteLog("FoxyLink.Integration.FL_Exchange", 
                EventLogLevel.Error, 
                Metadata.CommonModules.FL_Exchange,
                ErrorMessage,
                JobResult,
                StatusCode);
            Return;
            
        EndIf;
        
        ProcessMergeOperation(MetadataObject, Payload, JobResult);
        
        FillJobResult(OutInvocation, JobResult);
            
    Except
        
        ErrorInfo = ErrorInfo();
        FL_InteriorUse.WriteLog("FoxyLink.Integration.FL_Exchange", 
            EventLogLevel.Error, 
            Metadata.CommonModules.FL_Exchange,
            ErrorInfo,
            JobResult);
        
    EndTry;
    
EndProcedure // MergeOperation()

// Only for internal use.
//
Procedure ProcessMergeOperation(MetadataObject, Payload, JobResult)
    
    If FL_CommonUse.IsCatalog(MetadataObject) Then
        ProcessCatalogObjects(MetadataObject, Payload, JobResult);
    ElsIf FL_CommonUse.IsDocument(MetadataObject) Then
        ProcessDocumentObjects(MetadataObject, Payload, JobResult);    
    ElsIf FL_CommonUse.IsRegister(MetadataObject) Then
        ProcessRegisterRecords(MetadataObject, Payload, JobResult);    
    Else
        Raise FL_ErrorsClientServer.ErrorMetadataObjectIsNotSupported(
            Payload.Metadata);               
    EndIf;        
    
EndProcedure // ProcessMergeOperation()

// Only for internal use.
//
Procedure ProcessCatalogObjects(MetadataObject, Payload, JobResult)
    
    ConvertionResult = ConvertToReferenceType(Payload.Object, MetadataObject, 
        JobResult);
    If NOT ConvertionResult.TypeConverted Then
        Return;
    EndIf;
    
    ValueTable = FL_CommonUse.NewMockOfMetadataObjectAttributes(MetadataObject);
    FL_CommonUse.ExtendValueTableFromArray(ConvertionResult.ConvertedValue, 
        ValueTable);
        
    PrimaryKeys = FL_CommonUse.PrimaryKeysByMetadataObject(MetadataObject);
    FilterParameters = CreateFilterParameters(Payload.Context, PrimaryKeys, 
        ValueTable);
    
    Manager = FL_CommonUse.ObjectManagerByMetadataObject(MetadataObject);    
    If NOT ValueIsFilled(FilterParameters) Then
        DeleteReferenceRecords();
    EndIf;
    
    WriteCatalogsObjects(Manager, MetadataObject, ValueTable);
    
EndProcedure // ProcessCatalogObjects()

// Only for internal use.
//
Procedure ProcessDocumentObjects(MetadataObject, Payload, JobResult)

    ConvertionResult = ConvertToReferenceType(Payload.Object, MetadataObject, 
        JobResult);
    If NOT ConvertionResult.TypeConverted Then
        Return;
    EndIf; 
    
    ValueTable = FL_CommonUse.NewMockOfMetadataObjectAttributes(MetadataObject);
    FL_CommonUse.ExtendValueTableFromArray(ConvertionResult.ConvertedValue, 
        ValueTable);
        
    PrimaryKeys = FL_CommonUse.PrimaryKeysByMetadataObject(MetadataObject);
    FilterParameters = CreateFilterParameters(Payload.Context, PrimaryKeys, 
        ValueTable);
    
    Manager = FL_CommonUse.ObjectManagerByMetadataObject(MetadataObject);    
    If NOT ValueIsFilled(FilterParameters) Then
        DeleteReferenceRecords();
    EndIf;
    
    WriteDocumentObjects(Manager, ValueTable);
    
EndProcedure // ProcessDocumentObjects()    

// Only for internal use.
//
Procedure ProcessRegisterRecords(MetadataObject, Payload, JobResult)
    
    ConvertionResult = FL_CommonUse.ConvertValueIntoMetadataObject(
        Payload.Object, MetadataObject);
    If NOT ConvertionResult.TypeConverted Then
        
        StatusCode = FL_InteriorUseReUse.UnprocessableEntity();
        FL_InteriorUse.WriteLog("FoxyLink.Integration.FL_Exchange", 
            EventLogLevel.Error, 
            Metadata.CommonModules.FL_Exchange,
            ConvertionResult.ErrorMessages,
            JobResult,
            StatusCode);
        Return;
      
    EndIf;
    
    ValueTable = FL_CommonUse.NewMockOfMetadataObjectAttributes(MetadataObject);
    FL_CommonUse.ExtendValueTableFromArray(ConvertionResult.ConvertedValue, 
        ValueTable); 
    
    FullName = MetadataObject.FullName();
    If FL_CommonUseReUse.IsInformationRegisterTypeObjectCached(FullName) Then
        WriteInformationRegisterRecords(MetadataObject, Payload.Context, 
            ValueTable);    
    Else
        
    EndIf;
    
EndProcedure // ProcessRegisterRecords()

// Only for internal use.
//
Procedure DeleteReferenceRecords()
    
    // TODO: Deleting records
    
EndProcedure // DeleteReferenceRecords()

// Only for internal use.
//
Procedure WriteCatalogsObjects(Manager, MetadataObject, ValueTable)
    
    HierarchyOfItems = Metadata.ObjectProperties.HierarchyType.HierarchyOfItems;
    HierarchyFoldersAndItems = Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems;
    
    ItemsValueTable = FL_CommonUse.NewMockOfMetadataCatalogItemAttributes(
        MetadataObject);
    FoldersValueTable = FL_CommonUse.NewMockOfMetadataCatalogFolderAttributes(
        MetadataObject);
        
    ItemsTabularSections = TabularSections(ItemsValueTable);
    FoldersTabularSections = TabularSections(FoldersValueTable);
        
    HasFolder = MetadataObject.Hierarchical AND 
        MetadataObject.HierarchyType = HierarchyFoldersAndItems;
    For Each Item In ValueTable Do
        
        CatalogObject = CatalogObject(Manager, Item, HasFolder);
        
        // Here is problem with generated refs.
        If Item.Predefined Then
            Item.Predefined = False;
        EndIf;
        
        If HasFolder AND Item.IsFolder Then
            ActualTable = FoldersValueTable;
            TabularSections = FoldersTabularSections;
        Else
            ActualTable = ItemsValueTable;
            TabularSections = ItemsTabularSections; 
        EndIf;    
        
        NewItem = ActualTable.Add();
        FillPropertyValues(NewItem, Item);
        FillPropertyValues(CatalogObject, NewItem);
        For Each TabularSection In TabularSections Do
            CatalogObject[TabularSection].Load(Item[TabularSection]);    
        EndDo;
        
        ActualTable.Clear();
        
        CatalogObject.Write();
        
    EndDo;
    
EndProcedure // WriteCatalogsObjects() 

// Only for internal use.
//
Procedure WriteDocumentObjects(Manager, ValueTable)
    
    TabularSections = TabularSections(ValueTable);
    For Each Item In ValueTable Do
        
        DocumentObject = DocumentObject(Manager, Item);
        
        FillPropertyValues(DocumentObject, Item);
        For Each TabularSection In TabularSections Do
            DocumentObject[TabularSection].Load(Item[TabularSection]);    
        EndDo;
        
        DocumentObject.Write();
        
    EndDo;    
    
EndProcedure // WriteDocumentObjects()

// Only for internal use.
//
Procedure WriteInformationRegisterRecords(MetadataObject, Context, ValueTable)
    
    PrimaryKeys = FL_CommonUse.PrimaryKeysByMetadataObject(MetadataObject);
    FilterParameters = CreateFilterParameters(Context, PrimaryKeys, 
        ValueTable);

    Manager = FL_CommonUse.ObjectManagerByMetadataObject(MetadataObject);
    RecordSet = Manager.CreateRecordSet();
    If NOT ValueIsFilled(FilterParameters) Then
        RecordSet.Load(ValueTable);
        RecordSet.Write();
        Return;
    EndIf;
    
    FilterTable = CreateFilterTable(Context, FilterParameters, PrimaryKeys);
    For Each Filter In FilterTable Do
    
        FillPropertyValues(FilterParameters, Filter);
        FilterResult = ValueTable.FindRows(FilterParameters);
        ValueTableCopy = ValueTable.Copy(FilterResult);    
        
        For Each FilterParameter In FilterParameters Do
            RecordSet.Filter[FilterParameter.Key].Set(FilterParameter.Value);    
        EndDo;
        
        RecordSet.Load(ValueTableCopy);
        RecordSet.Write();
        
    EndDo; 
    
EndProcedure // WriteInformationRegisterRecords()

// Only for internal use.
//
Function CatalogObject(Manager, Item, HasFolder)
    
    If NOT FL_CommonUse.RefExists(Item.Ref) Then
            
        If HasFolder AND Item.IsFolder Then
            CatalogObject = Manager.CreateFolder();
        Else
            CatalogObject = Manager.CreateItem();
        EndIf;  
            
        CatalogObject.SetNewObjectRef(Item.Ref);
        
    Else
        
        CatalogObject = Item.Ref.GetObject();
        
    EndIf;
    
    Return CatalogObject;
    
EndFunction // CatalogObject()

// Only for internal use.
//
Function DocumentObject(Manager, Item)
    
    If NOT FL_CommonUse.RefExists(Item.Ref) Then
        DocumentObject = Manager.CreateDocument();   
        DocumentObject.SetNewObjectRef(Item.Ref);
    Else 
        DocumentObject = Item.Ref.GetObject();
    EndIf;
    
    Return DocumentObject;
    
EndFunction // DocumentObject()

// Only for internal use.
//
Function TabularSections(ValueTable)
    
    TabularSections = New Array;
    ValueType = New TypeDescription("ValueTable");
    Columns = ValueTable.Columns;
    For Each Column In Columns Do
        If Column.ValueType = ValueType Then
            TabularSections.Add(Column.Name);    
        EndIf;
    EndDo;
    
    Return TabularSections;
    
EndFunction // TabularSections()

// Only for internal use.
//
Function ConvertToReferenceType(Object, MetadataObject, JobResult)
    
    MissedRefs = New Map;
    MissedRefs.Insert("Ref", True);
    
    ConversionSettings = FL_CommonUse.NewConversionSettings();
    ConversionSettings.AllowMissedRefs = FL_CommonUse.FixedData(MissedRefs);
    
    ConvertionResult = FL_CommonUse.ConvertValueIntoMetadataObject(Object, 
        MetadataObject, ConversionSettings);
    If NOT ConvertionResult.TypeConverted Then
        
        StatusCode = FL_InteriorUseReUse.UnprocessableEntity();
        FL_InteriorUse.WriteLog("FoxyLink.Integration.FL_Exchange", 
            EventLogLevel.Error, 
            Metadata.CommonModules.FL_Exchange,
            ConvertionResult.ErrorMessages,
            JobResult,
            StatusCode);
      
    EndIf;
    
    Return ConvertionResult;
    
EndFunction // ConvertToReferenceType()

// Only for internal use.
//
Function CreateFilterParameters(Context, PrimaryKeys, ValueTable)
    
    Var ContextFilter;
    FilterParameters = New Structure;
    
    For Each PrimaryKey In PrimaryKeys Do
        
        Context.Property(PrimaryKey.Key, ContextFilter);
        If ValueIsFilled(ContextFilter) Then
            FilterParameters.Insert(PrimaryKey.Key);            
            ValueTable.Indexes.Add(PrimaryKey.Key);
        EndIf;
        
    EndDo;
    
    Return FilterParameters; 
    
EndFunction // CreateFilterParameters()

// Only for internal use.
//
Function CreateFilterTable(Context, FilterParameters, PrimaryKeys)
    
    Count = 1;
    FilterTable = New ValueTable;
    For Each FilterParameter In FilterParameters Do
        
        KeyName = FilterParameter.Key;
        Types = PrimaryKeys[KeyName];
        FilterTable.Columns.Add(KeyName, New TypeDescription(Types));
        
        Values = Context[KeyName];
        Count = Count * Values.Count();
        
    EndDo;
    
    For Index = 0 To Count - 1 Do
        FilterTable.Add();       
    EndDo;
    
    For Each FilterParameter In FilterParameters Do
        
        Array = New Array;
        
        KeyName = FilterParameter.Key;
        Types = PrimaryKeys[KeyName]; 
        Values = Context[KeyName];
        For Each Value In Values Do
            
            ConversionResult = FL_CommonUse.ConvertValueIntoPlatformObject(
                Value, Types);
            If NOT ConversionResult.TypeConverted Then    
                Raise StrConcat(ConversionResult.ErrorMessages, 
                    Chars.CR + Chars.LF);
            EndIf;
            
            Array.Add(ConversionResult.ConvertedValue);
                
        EndDo;
        
        Index = 0;
        Count = Array.Count();
        For Each Filter In FilterTable Do
            Filter[KeyName] = Array[Index];
            Index = Index + 1;
            If Index = Count Then
                Index = 0;    
            EndIf;
        EndDo;
            
    EndDo;
    
    Return FilterTable;
    
EndFunction // CreateFilterTable()

// Only for internal use.
//
//Function NewErrorStructure()
//    
//    ErrorStructure = New Structure;
//    ErrorStructure.Insert("Error", New Structure);
//    ErrorStructure.Error.Insert("Code");
//    ErrorStructure.Error.Insert("Message");
//    
//    Return ErrorStructure;
//    
//EndFunction // NewErrorStructure()

// Only for internal use.
//
//Function NewSuccessStructure()
//    
//    SuccessStructure = New Structure;
//    SuccessStructure.Insert("Data", New Structure);
//    
//    Return SuccessStructure;
//    
//EndFunction // NewSuccessStructure()

// Only for internal use.
//
Function IsValidMessage(Payload, JobResult)
    
    UnprocessableStatusCode = FL_InteriorUseReUse.UnprocessableEntity();
    
    If TypeOf(Payload) <> Type("Structure") Then
        
        ErrorMessage = FL_ErrorsClientServer.ErrorTypeIsDifferentFromExpected(
            "Payload", Payload, Type("Structure"));
        FL_InteriorUse.WriteLog("FoxyLink.Integration.FL_Exchange", 
            EventLogLevel.Error, 
            Metadata.CommonModules.FL_Exchange,
            ErrorMessage,
            JobResult,
            UnprocessableStatusCode);
        Return False;
        
    EndIf; 
    
    If NOT Payload.Property("Context") Then
        
        ErrorMessage = FL_ErrorsClientServer.ErrorKeyIsMissingInObject(
            "Payload", Payload, "Context");
        FL_InteriorUse.WriteLog("FoxyLink.Integration.FL_Exchange", 
            EventLogLevel.Error, 
            Metadata.CommonModules.FL_Exchange,
            ErrorMessage,
            JobResult,
            UnprocessableStatusCode);    
        Return False;
        
    EndIf;
    
    If NOT Payload.Property("Metadata") Then
        
        ErrorMessage = FL_ErrorsClientServer.ErrorKeyIsMissingInObject(
            "Payload", Payload, "Metadata");
        FL_InteriorUse.WriteLog("FoxyLink.Integration.FL_Exchange", 
            EventLogLevel.Error, 
            Metadata.CommonModules.FL_Exchange,
            ErrorMessage,
            JobResult,
            UnprocessableStatusCode);
        Return False;
        
    EndIf;
    
    If NOT Payload.Property("Object") Then
        
        ErrorMessage = FL_ErrorsClientServer.ErrorKeyIsMissingInObject(
            "Payload", Payload, "Object");
        FL_InteriorUse.WriteLog("FoxyLink.Integration.FL_Exchange", 
            EventLogLevel.Error, 
            Metadata.CommonModules.FL_Exchange,
            ErrorMessage,
            JobResult,
            UnprocessableStatusCode);
        Return False;
        
    EndIf;
    
    Return True;
    
EndFunction // IsValidMessage()

#EndRegion // Private