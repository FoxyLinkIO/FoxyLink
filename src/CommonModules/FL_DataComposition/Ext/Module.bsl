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

#Region ProgramInterface

// Outputs the result of the data composition schema in the stream object.
//
// Parameters:
//  StreamObject     - Arbitrary - an object is designed for character output by data composition processor.
//  OutputParameters - Structure - see function FL_DataComposition.NewOutputParameters.
//
Procedure Output(StreamObject, OutputParameters) Export
    
    DCTParameters = FL_CommonUseClientServer.CopyStructure(
        OutputParameters.DCTParameters);
        
    // Verify, that supported type of generator is in use.
    DCTParameters.GeneratorType = 
        Type("DataCompositionValueCollectionTemplateGenerator");
        
    // Create data composition template.
    DataCompositionTemplate = NewDataCompositionTemplate(DCTParameters);
    
    // Init data composition processor.
    DataCompositionProcessor = New DataCompositionProcessor;
    DataCompositionProcessor.Initialize(DataCompositionTemplate, 
        OutputParameters.ExternalDataSets, 
        OutputParameters.DetailsData, 
        OutputParameters.CanUseExternalFunctions);
          
    ReportStructure = NewReportStructure();
    FillReportStructure(ReportStructure, DataCompositionTemplate, 
        DataCompositionTemplate.Body);
        
    // Init template columns with particular order.
    TemplateColumns = TemplateColumns(DCTParameters.Template,
        DataCompositionTemplate, DataCompositionTemplate.Body);
        
    // Handle naming restrictions.
    // Object can have naming restrictions and this problems should be handled in place.
    StreamObject.VerifyReportStructure(ReportStructure);
    StreamObject.VerifyColumnNames(TemplateColumns);
    
    // Output start
    DataCompositionProcessor.Next(); // StartElement
    DataCompositionProcessor.Next(); // DataCompositionTemplate
    
    Item = DataCompositionProcessor.Next(); // Query execution 
    
    StreamObject.Output(Item, DataCompositionProcessor, 
        ReportStructure, TemplateColumns);    
    
EndProcedure // Output()

// Outputs the result of the data composition schema in the spreadsheet document.
//
// Parameters:
//  SpreadsheetDocument - SpreadsheetDocument - spreadsheet document.
//  OutputParameters    - Structure           - see function FL_DataComposition.NewOutputParameters.
//
Procedure OutputInSpreadsheetDocument(SpreadsheetDocument, 
    OutputParameters) Export
       
    DCTParameters = FL_CommonUseClientServer.CopyStructure(
        OutputParameters.DCTParameters);
        
    // Verify, that supported type of generator is in use.
    DCTParameters.GeneratorType = Type("DataCompositionTemplateGenerator");
    
    // Create data composition template.
    DataCompositionTemplate = NewDataCompositionTemplate(DCTParameters);

    // Init data composition processor.
    DataCompositionProcessor = New DataCompositionProcessor;
    DataCompositionProcessor.Initialize(DataCompositionTemplate, 
        OutputParameters.ExternalDataSets, 
        OutputParameters.DetailsData, 
        OutputParameters.CanUseExternalFunctions);

    // Output result
    OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
    OutputProcessor.SetDocument(SpreadsheetDocument);
    OutputProcessor.Output(DataCompositionProcessor);    
    
EndProcedure // OutputInSpreadsheetDocument()

// Outputs the result of the data composition schema in the value collection.
//
// Parameters:
//  ValueCollection  - ValueTable, ValueTree - value collection.
//  OutputParameters - Structure             - see function FL_DataComposition.NewOutputParameters.
//
Procedure OutputInValueCollection(ValueCollection, OutputParameters) Export
       
    DCTParameters = FL_CommonUseClientServer.CopyStructure(
        OutputParameters.DCTParameters);
        
    // Verify, that supported type of generator is in use.
    DCTParameters.GeneratorType = 
        Type("DataCompositionValueCollectionTemplateGenerator");
    
    // Create data composition template.
    DataCompositionTemplate = NewDataCompositionTemplate(DCTParameters);

    // Init data composition processor.
    DataCompositionProcessor = New DataCompositionProcessor;
    DataCompositionProcessor.Initialize(DataCompositionTemplate, 
        OutputParameters.ExternalDataSets, 
        OutputParameters.DetailsData, 
        OutputParameters.CanUseExternalFunctions);

    // Output result
    OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
    OutputProcessor.SetObject(ValueCollection);
    OutputProcessor.Output(DataCompositionProcessor);    
    
EndProcedure // OutputInValueCollection()

#EndRegion // ProgramInterface

#Region ServiceInterface

// Creates data composition schema from the data sources and data sets and
// copies data composition schema to the destination address.
//
// Parameters:
//  DataSources        - Array  - data source items.
//          see function FL_DataComposition.NewDataCompositionSchemaDataSource.
//  DataSets           - Array  - data set items.
//          see function FL_DataComposition.NewDataCompositionSchemaDataSetQuery.
//          see function FL_DataComposition.NewDataCompositionSchemaDataSetObject.
//          see function FL_DataComposition.NewDataCompositionSchemaDataSetUnion.
//  DestinationAddress - String - the address to copy data composition schema in.
//  UUID               - UUID   - an unique identifier of the form in the 
//          temporary storage of which the data should be placed
//
Procedure CreateDataCompositionSchema(DataSources, DataSets, DestinationAddress, 
    UUID) Export
    
    // Create a data composition schema.
    DataCompositiomSchema = New DataCompositionSchema;
    
    // Determine the data sources for the schema.
    For Each DataSource In DataSources Do
        FillPropertyValues(DataCompositiomSchema.DataSources.Add(), 
            DataSource);
    EndDo;

    // Determine the data sets for the schema.
    For Each DataSet In DataSets Do
        
        NewDataSet = DataCompositiomSchema.DataSets.Add(DataSet.Type);
        FillPropertyValues(NewDataSet, DataSet, , "Fields"); 
        
        // Determine the data fields for the data set.
        For Each Field In DataSet.Fields Do
            NewField = NewDataSet.Fields.Add(Field.Type);
            FillPropertyValues(NewField, Field);
        EndDo;
        
    EndDo;
    
    DestinationAddress = PutToTempStorage(DataCompositiomSchema, UUID);
    
EndProcedure // CreateDataCompositionSchema() 

// Copies data composition schema from the source address to the destination address.
//
// Parameters:
//  DestinationAddress - String                - the address to copy data composition schema in.
//  SourceAddress      - String                - the address to copy data composition schema from.
//                     - DataCompositionSchema - the source data composition schema to copy from.
//  CheckForChanges    - Boolean               - if value is 'True', source and destination 
//                                              address is checked for changes.
//                          Default value: False.
//  Changed            - Boolean               - out parameter for the result of comparation
//                                              source and destination data for changes.
//                          Default value: False.
//
Procedure CopyDataCompositionSchema(DestinationAddress, SourceAddress,
    CheckForChanges = False, Changed = False) Export

    If IsTempStorageURL(SourceAddress) Then
        DataCompositionSchema = GetFromTempStorage(SourceAddress);
    Else
        DataCompositionSchema = SourceAddress;
    EndIf;
    
    If TypeOf(DataCompositionSchema) = Type("DataCompositionSchema") Then
        DataCompositionSchema = XDTOSerializer.ReadXDTO(
            XDTOSerializer.WriteXDTO(DataCompositionSchema));
    Else
        DataCompositionSchema = New DataCompositionSchema;
    EndIf;
    
    If CheckForChanges Then
        Changed = False;
        If IsTempStorageURL(DestinationAddress) Then
            
            CurrentDCS = GetFromTempStorage(DestinationAddress);
            If TypeOf(CurrentDCS) = Type("DataCompositionSchema") Then
                Changed = FL_CommonUse.ValueToJSONString(CurrentDCS) <> 
                    FL_CommonUse.ValueToJSONString(DataCompositionSchema);
            Else
                Changed = True;
            EndIf;
            
        Else
            Changed = True; 
        EndIf;
    EndIf;

    FL_CommonUseClientServer.PutSerializedValueToTempStorage(
        DataCompositionSchema, DestinationAddress, New UUID);
    
EndProcedure // CopyDataCompositionSchema()

// Initializes data composition settings composer by data compostion schema and
// data composition settings.
//
// Parameters:
//  SettingsComposer - DataCompositionSettingsComposer   - describes relation of 
//                              data composition settings and data composition schema.
//  DataCompositionSchemaURL   - String                  - the address in temp storage.
//                             - DataCompositionSchema   - data composition schame.
//  DataCompositionSettingsURL - String                  - the address in temp storage.
//                             - DataCompositionSettings - data composition settings.
//                                  Default value: Undefined.
//
Procedure InitSettingsComposer(SettingsComposer, DataCompositionSchemaURL, 
    DataCompositionSettingsURL = Undefined) Export

    If IsTempStorageURL(DataCompositionSchemaURL) Then
        DataCompositionSchema = GetFromTempStorage(DataCompositionSchemaURL);
    Else
        DataCompositionSchema = DataCompositionSchemaURL; 
    EndIf;

    If ValueIsFilled(DataCompositionSettingsURL) Then
        If IsTempStorageURL(DataCompositionSettingsURL) Then
            DataCompositionSettings = GetFromTempStorage(DataCompositionSettingsURL);
        Else
            DataCompositionSettings = DataCompositionSettingsURL;
        EndIf;
    EndIf;

    Try
        SettingsComposer.Initialize( // Do not change, else composer won't be connected with data composition schema.
            New DataCompositionAvailableSettingsSource(DataCompositionSchemaURL));
    Except
        
        ErrorMessage = StrTemplate(NStr("en='Error: Failed to initialize data composition settings composer. %1.';
            |ru='Ошибка: Не удалось инициализировать компоновщик настроек компоновки данных. %1.';
            |en_CA='Error: Failed to initialize data composition settings composer. %1.'"),
            ErrorDescription());
            
        Raise ErrorMessage;
             
    EndTry;

    If TypeOf(DataCompositionSettings) = Type("DataCompositionSettings") Then
        
        SettingsComposer.LoadSettings(DataCompositionSettings);
        
    ElsIf TypeOf(DataCompositionSchema) = Type("DataCompositionSchema") Then
        
        SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
        
        // Platform bug is here. We have to copy DefaultSettings.Selection.Items 
        // titles from DataCompositionSchema to SettingsComposer.Settings.Selection.Items.
        Items = SettingsComposer.Settings.Selection.Items;
        DefaultItems = DataCompositionSchema.DefaultSettings.Selection.Items;
        
        MapSelection = New Map;
        For Each Item In Items Do
            MapSelection.Insert(Item.Field, Item);                
        EndDo;
        
        For Each Item In DefaultItems Do 
            If NOT IsBlankString(Item.Title) Then
                
                Value = MapSelection[Item.Field]; 
                If Value <> Undefined Then
                    Value.Title = Item.Title;     
                EndIf;
                
            EndIf; 
        EndDo;
        
    Else
        
        ErrorMessage = NStr("en='Error: Failed to find data composition settings';
            |ru='Ошибка: Не удалось найти настроки компоновки данных.';
            |en_CA='Error: Failed to find data composition settings'");
            
        Raise ErrorMessage;
        
    EndIf;
    
    SettingsComposer.Refresh(
        DataCompositionSettingsRefreshMethod.CheckAvailability);

EndProcedure // InitSettingsComposer()

// Sets the message settings into data composition settings composer.
//
// Parameters:
//  SettingsComposer  - DataCompositionSettingsComposer - describes relation of 
//                              data composition settings and data composition schema.
//  InvocationContext - ValueTable - see function FL_BackgroundJob.NewInvocationContext.
//
Procedure SetDataToSettingsComposer(SettingsComposer, InvocationContext) Export
    
    Var MessageBody, Parameters, Filter;
    
    If TypeOf(SettingsComposer) <> Type("DataCompositionSettingsComposer") Then
        Raise FL_ErrorsClientServer.ErrorTypeIsDifferentFromExpected(
            "SettingsComposer", SettingsComposer, Type("DataCompositionSettingsComposer"));          
    EndIf;
    
    If TypeOf(InvocationContext) <> Type("ValueTable") Then      
        Raise FL_ErrorsClientServer.ErrorTypeIsDifferentFromExpected(
            "InvocationContext", InvocationContext, Type("ValueTable"));     
    EndIf;
             
    DataParameters = SettingsComposer.Settings.DataParameters;
    FillDataCompositionParameterValueCollection(DataParameters, 
        InvocationContext);
                                
EndProcedure // SetDataToSettingsComposer()

// Creates description of data source of data composition schema.
//
// Returns:
//  Structure - with keys:
//      * ConnectionString - String - connection string with data source. 
//                                    For current infobase - an empty string.
//                              Default value: "".
//      * DataSourceType   - String - data source type. For current infobase - "Local".
//                              Default value: "Local".                
//      * Name             - String - data source name.
//                              Default value: "DataSource".
//
Function NewDataCompositionSchemaDataSource() Export

    DataCompositionSchemaDataSource = New Structure;
    DataCompositionSchemaDataSource.Insert("ConnectionString", "");
    DataCompositionSchemaDataSource.Insert("DataSourceType", "Local");
    DataCompositionSchemaDataSource.Insert("Name", "DataSource");
    Return DataCompositionSchemaDataSource;
    
EndFunction // NewDataCompositionSchemaDataSource()

// Creates description of a data set of data composition schema (query).
//
// Returns:
//  Structure - with keys:
//      * AutoFillAvailableFields - Boolean - specifies necessity of automatic 
//                                            filling of accessible fields on 
//                                            the basis of the text of inquiry.
//                                      Default value: True.
//      * DataSource              - String  - name of data source, from which
//                                            data will be obtained.
//                                      Default value: "DataSource".  
//      * Fields                  - Array   - descriptions of fields of data set.
//      * Name                    - String  - data set name.
//                                      Default value: "DataSetQuery".
//      * Query                   - String  - query text for obtaining data of the set.
//      * Type                    - Type    - type of added element.
//                                      Default value: DataCompositionSchemaDataSetQuery.
//
Function NewDataCompositionSchemaDataSetQuery() Export
    
    DataCompositionSchemaDataSetQuery = New Structure;
    DataCompositionSchemaDataSetQuery.Insert("AutoFillAvailableFields", True);
    DataCompositionSchemaDataSetQuery.Insert("DataSource", "DataSource");
    DataCompositionSchemaDataSetQuery.Insert("Fields", New Array);
    DataCompositionSchemaDataSetQuery.Insert("Name", "DataSetQuery");
    DataCompositionSchemaDataSetQuery.Insert("Query");
    DataCompositionSchemaDataSetQuery.Insert("Type", 
        Type("DataCompositionSchemaDataSetQuery"));
    Return DataCompositionSchemaDataSetQuery;
    
EndFunction // NewDataCompositionSchemaDataSet()

// Creates description of a data set of data composition schema (object).
//
// Returns:
//  Structure - with keys:
//      * DataSource - String - name of data source, from which data will be obtained.
//                          Default value: "DataSource".  
//      * Fields     - Array  - descriptions of fields of data set.
//      * Name       - String - data set name.
//                          Default value: "DataSetObject".
//      * ObjectName - String - name of object where data have to be retrieved from.
//      * Type       - Type    - type of added element.
//                          Default value: DataCompositionSchemaDataSetObject.
//
Function NewDataCompositionSchemaDataSetObject() Export
    
    DataCompositionSchemaDataSetObject = New Structure;
    DataCompositionSchemaDataSetObject.Insert("DataSource", "DataSource");
    DataCompositionSchemaDataSetObject.Insert("Fields", New Array);
    DataCompositionSchemaDataSetObject.Insert("Name", "DataSetObject");
    DataCompositionSchemaDataSetObject.Insert("ObjectName");
    DataCompositionSchemaDataSetObject.Insert("Type", 
        Type("DataCompositionSchemaDataSetObject"));
    Return DataCompositionSchemaDataSetObject;
    
EndFunction // NewDataCompositionSchemaDataSetObject()

// Creates description of a data set of data composition schema (union).
//
// Returns:
//  Structure - with keys:
//      * Fields - Array  - descriptions of fields of data set.
//      * Items  - Array  - union parts. 
//      * Name   - String - data set name.
//                  Default value: "DataSetUnion".
//      * Type   - Type   - type of added element.
//                  Default value: DataCompositionSchemaDataSetUnion.
//
Function NewDataCompositionSchemaDataSetUnion() Export
    
    DataCompositionSchemaDataSetUnion = New Structure;
    DataCompositionSchemaDataSetUnion.Insert("Fields", New Array);
    DataCompositionSchemaDataSetUnion.Insert("Items", New Array);    
    DataCompositionSchemaDataSetUnion.Insert("Name", "DataSetUnion");
    DataCompositionSchemaDataSetUnion.Insert("Type", 
        Type("DataCompositionSchemaDataSetUnion"));
    Return DataCompositionSchemaDataSetUnion;
    
EndFunction // NewDataCompositionSchemaDataSetUnion()

// Creates description for data set field of data composition schema (field).
//
// Returns:
//  Structure - with keys:
//      * Appearance - Array - description of the formatting to be applied.   
//      * AttributeUseRestriction - DataCompositionSchemaFieldUseRestriction - 
//          indicates a given field restriction of use in the user settings. 
//          The same types of use are subject to restriction as field use 
//          restrictions. Behavior of this property is similar to property 
//          UseRestriction. Is used for fields of object type. At the same 
//          time, you can choose a field, but you can not choose its attributes.
//      * DataPath - String - contains data path under which the field will 
//          appear in settings and expressions. Note that the field will 
//          appear exactly under this name, and not under a name specified 
//          in the property Field. If several data sets have fields with the
//          same data paths, a data set field that is parent data set will be 
//          used. Specifying similar data paths of fields of not connected data
//          sets is not allowed.
//          In the data composition system it is not allowed to specify names, 
//          that match the following keywords, as the data path:
//              • CASE
//              • IS
//              • ELSE
//              • WHEN
//              • END
//              • NOT
//              • LIKE
//              • DISTINCT
//              • ESCAPE
//              • THEN 
//      * EditParameters        - Array  - editing parameters for a field value
//          in a filter.
//      * Field                 - String - name of described data set field.
//      * HierarchyCheckDataSet - String - if field condition InHierarchy need 
//          to be processed in a non-standard way, this property specifies data
//          set name where data for checking reference belonging to a hierarchy 
//          of a certain value is obtained.
//                  Default value: "".            
//      * HierarchyCheckDataSetParameter - String - parameter where a value is
//          substituted that require obtaining daughter elements.
//                  Default value: "".
//      * OrderExpressions - Array - description of expressions used for ordering
//          data set when ordering by a given field is required. 
//      * PresentationExpression - String - an expression used for calculation 
//          field presentation. Can be used for redefining standard field presentation.
//                  Default value: "".
//      * Role  - DataCompositionDataSetFieldRole - field role.
//      * Title - String - string displayed in user settings and in the results
//          header for a given field.
//      * UseRestriction - DataCompositionSchemaFieldUseRestriction - indicates
//          a given field restriction of use in the settings. Note that field 
//          use is defined by data set itself. Using this property you can only 
//          restrict use, but you cannot permit what is denied in data set 
//          description. For example, when a query indicates that a field may 
//          be selected, but does not indicate that this field may be used in 
//          a filter, then absence of filter restriction in this property does 
//          not make this field available for use in a filter.
//      * ValueType - TypeDescription - field data type.
//      * Type   - Type   - type of added element.
//                  Default value: DataCompositionSchemaDataSetField.
//
Function NewDataCompositionSchemaDataSetField() Export
    
    DataCompositionSchemaDataSetField = New Structure;
    DataCompositionSchemaDataSetField.Insert("Appearance");
    DataCompositionSchemaDataSetField.Insert("AttributeUseRestriction");
    DataCompositionSchemaDataSetField.Insert("DataPath");
    DataCompositionSchemaDataSetField.Insert("EditParameters", New Array);
    DataCompositionSchemaDataSetField.Insert("Field");
    DataCompositionSchemaDataSetField.Insert("HierarchyCheckDataSet", "");
    DataCompositionSchemaDataSetField.Insert("HierarchyCheckDataSetParameter", "");
    DataCompositionSchemaDataSetField.Insert("OrderExpressions", New Array);
    DataCompositionSchemaDataSetField.Insert("PresentationExpression", "");
    DataCompositionSchemaDataSetField.Insert("Role");
    DataCompositionSchemaDataSetField.Insert("Title");
    DataCompositionSchemaDataSetField.Insert("UseRestriction");
    DataCompositionSchemaDataSetField.Insert("ValueType");
    DataCompositionSchemaDataSetField.Insert("Type",
        Type("DataCompositionSchemaDataSetField"));
    Return DataCompositionSchemaDataSetField;
    
EndFunction // NewDataCompositionSchemaDataSetField()

// Creates description for data set field of data composition schema (folder).
//
// Returns:
//  Structure - with keys:
//      * DataPath - String - contains data path under which the field will 
//          appear in settings and expressions. Note that the field will 
//          appear exactly under this name, and not under a name specified 
//          in the property Field. If several data sets have fields with the
//          same data paths, a data set field that is parent data set will be 
//          used. Specifying similar data paths of fields of not connected data
//          sets is not allowed.
//          In the data composition system it is not allowed to specify names, 
//          that match the following keywords, as the data path:
//              • CASE
//              • IS
//              • ELSE
//              • WHEN
//              • END
//              • NOT
//              • LIKE
//              • DISTINCT
//              • ESCAPE
//              • THEN 
//      * Title - String - string displayed in user settings and in the results
//          header for a given field.
//      * UseRestriction - DataCompositionSchemaFieldUseRestriction - indicates
//          a given field restriction of use in the settings. Note that field 
//          use is defined by data set itself. Using this property you can only 
//          restrict use, but you cannot permit what is denied in data set 
//          description. For example, when a query indicates that a field may 
//          be selected, but does not indicate that this field may be used in 
//          a filter, then absence of filter restriction in this property does 
//          not make this field available for use in a filter. 
//      * Type  - Type   - type of added element.
//                  Default value: DataCompositionSchemaDataSetFieldFolder.
//
Function NewDataCompositionSchemaDataSetFieldFolder() Export
    
    DataCompositionSchemaDataSetFieldFolder = New Structure;
    DataCompositionSchemaDataSetFieldFolder.Insert("DataPath");
    DataCompositionSchemaDataSetFieldFolder.Insert("Title");
    DataCompositionSchemaDataSetFieldFolder.Insert("UseRestriction");
    DataCompositionSchemaDataSetFieldFolder.Insert("Type",
        Type("DataCompositionSchemaDataSetFieldFolder"));
    Return DataCompositionSchemaDataSetFieldFolder;
    
EndFunction // NewDataCompositionSchemaDataSetFieldFolder()

// Creates description for nested data set-field.
//
// Returns:
//  Structure - with keys:
//      * DataPath - String - contains data path under which the nested dataset
//          will appear in data composition schema and settings.
//          In the data composition system it is not allowed to specify names, 
//          that match the following keywords, as the data path:
//              • CASE
//              • IS
//              • ELSE
//              • WHEN
//              • END
//              • NOT
//              • LIKE
//              • DISTINCT
//              • ESCAPE
//              • THEN 
//      * Field - String - the name of a dataset field from which the nested 
//          dataset data will be obtained.
//      * Title - String - the nested dataset title. This title will be used
//          for displaying in the report settings and report result. 
//      * Type  - Type   - type of added element.
//                  Default value: DataCompositionSchemaNestedDataSet.
//
Function NewDataCompositionSchemaNestedDataSet() Export
    
    DataCompositionSchemaNestedDataSet = New Structure;
    DataCompositionSchemaNestedDataSet.Insert("DataPath");
    DataCompositionSchemaNestedDataSet.Insert("Field");
    DataCompositionSchemaNestedDataSet.Insert("Title");
    DataCompositionSchemaNestedDataSet.Insert("Type", 
        Type("DataCompositionSchemaNestedDataSet"));
    Return DataCompositionSchemaNestedDataSet;    
    
EndFunction // NewDataCompositionSchemaNestedDataSet()

// Creates layout template according passed parameters.
//
// Parameters:
//  DCTParameters - Structure - see function FL_DataComposition.NewDataCompositionTemplateParameters.
//
// Returns:
//  DataCompositionTemplate - created layout template.
//
Function NewDataCompositionTemplate(DCTParameters) Export
   
    DataCompositionTemplateComposer = New DataCompositionTemplateComposer;
    Return DataCompositionTemplateComposer.Execute(DCTParameters.Schema, 
        DCTParameters.Template, 
        DCTParameters.DetailsData, 
        DCTParameters.AppearanceTemplate, 
        DCTParameters.GeneratorType,
        DCTParameters.CheckFieldsAvailability,
        DCTParameters.FunctionalOptionParameters);
    
EndFunction // NewDataCompositionTemplate()

// Creates a new structure with data composition template parameters. 
// Parameters are needed to execute template layout.
//
// Returns:
//  Structure - with keys:
//      * Schema - DataCompositionSchema - schema, for which template must be built. 
//      * Template - DataCompositionSettings - settings, for which template must be created. 
//      * DetailsData - DataCompositionDetailsData - contains a variable where details data will be placed. If this 
//                                              parameter is not specified, details will not be filled in. 
//      * AppearanceTemplate - DataCompositionAppearanceTemplate - appearance template determining the data composition
//                                              template. If not specified, the default appearance template is used. 
//      * GeneratorType - Type - specifies the type of data composition template generator.  
//                          Available types: 
//                              DataCompositionValueCollectionTemplateGenerator; 
//                              DataCompositionTemplateGenerator.               
//                          Default value: Type("DataCompositionTemplateGenerator"). 
//      * CheckFieldsAvailability - Boolean - specifies whether to check the rights to view fields and the field 
//                                              availability in enabled features.
//                                  Default value: True.
//      * FunctionalOptionParameters - Structure - contains functional option parameters used when executing a report.
//
// See also:
//  DataCompositionTemplateComposer.Execute in the syntax-assistant.
//
Function NewTemplateComposerParameters() Export
    
    TemplateComposerParameters = New Structure;
    TemplateComposerParameters.Insert("Schema");
    TemplateComposerParameters.Insert("Template");
    TemplateComposerParameters.Insert("DetailsData");
    TemplateComposerParameters.Insert("AppearanceTemplate");
    TemplateComposerParameters.Insert("GeneratorType", 
        Type("DataCompositionTemplateGenerator"));
    TemplateComposerParameters.Insert("CheckFieldsAvailability", True);
    TemplateComposerParameters.Insert("FunctionalOptionParameters");
    Return TemplateComposerParameters;
    
EndFunction // NewTemplateComposerParameters()

// Creates a new structure with output parameters.
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
Function NewOutputParameters() Export
    
    OutputParameters = New Structure;
    OutputParameters.Insert("ExternalDataSets");
    OutputParameters.Insert("DetailsData");
    OutputParameters.Insert("CanUseExternalFunctions", False);
    OutputParameters.Insert("DCTParameters");
    Return OutputParameters;
    
EndFunction // NewOutputParameters()

// Creates a new structure with message settings.
//
// Returns:
//  Structure - with keys:
//      * Body - Structure - message body.
//          ** Filter     - Structure - contains a filter applied to records in the grouping.
//          ** Parameters - Structure - contains schema parameter descriptions.
//
Function NewMessageSettings() Export
    
    Body = New Structure;
    Body.Insert("Filter", New Structure);
    Body.Insert("Parameters", New Structure);
    
    MessageSettings = New Structure;
    MessageSettings.Insert("Body", Body);
    
    Return MessageSettings;
    
EndFunction // NewMessageSettings() 

#EndRegion // ServiceInterface

#Region ServiceProceduresAndFunctions

// Recursively fills the report structure from nested data composition 
// layouts in main data composition template. 
//
// Note:
//  Return value is type of "Structure", not "Map".
//  The main reason is that "Structure" was faster then "Map" on test system 
//  in ~17.62% or ~1967 ms for 100000 executions.
// 
// Parameters:
//  ReportStructure - Structure - see function FL_DataComposition.NewReportStructure.
//  DataCompositionTemplate - DataCompositionTemplate - main data composition 
//                          template, for which is needed to fill a structure 
//                          with the names of groups nested in data composition layouts. 
//  DataCompositionTemplateBody - DataCompositionTemplateBody - the body of current 
//                          data composition layout. 
//
Procedure FillReportStructure(ReportStructure, 
    DataCompositionTemplate, DataCompositionTemplateBody)
        
    For Each ItemBody In DataCompositionTemplateBody Do
        
        If TypeOf(ItemBody) = Type("DataCompositionTemplateAreaTemplate") Then
            Continue; 
        EndIf;
        
        AreaTemplateDefinition = AreaTemplateDefinition(DataCompositionTemplate, 
            ItemBody);
            
        ReportStructure.Names.Insert(AreaTemplateDefinition.Name, 
            ItemBody.Name);    
            
        NewTreeRow = ReportStructure.Hierarchy.Rows.Add();    
        NewTreeRow.Name = ItemBody.Name;
        NewTreeRow.Template = AreaTemplateDefinition.Name;
        
        If ItemBody.Body.Count() > 1 Then
            
            ReportStructure.Hierarchy = NewTreeRow; 
            FillReportStructure(ReportStructure, DataCompositionTemplate, 
                ItemBody.Body);
            If NewTreeRow.Parent = Undefined Then
                ReportStructure.Hierarchy = NewTreeRow.Owner();
            Else
                ReportStructure.Hierarchy = NewTreeRow.Parent;        
            EndIf;
            
        EndIf;
             
    EndDo;
        
EndProcedure // FillReportStructure()

// Fills data composition parameter value collection from MessageSettings.Body.Parameters.
//
// Parameters:
//  DataParameters    - DataCompositionParameterValues - values of data parameters. 
//                                      They are implemented as parameter values.
//  InvocationContext - ValueTable                      - invocation context.
//
Procedure FillDataCompositionParameterValueCollection(DataParameters, 
    InvocationContext)

    // Verification is necessary as the type can be Undefined.
    AvailableParameters = DataParameters.AvailableParameters;
    If TypeOf(AvailableParameters) <> Type("DataCompositionAvailableParameters") Then
        Return;
    EndIf;
    
    FilterParameters = New Structure("PrimaryKey");
    For Each Item In AvailableParameters.Items Do
        
        PrimaryKey = String(Item.Parameter);
        FilterParameters.PrimaryKey = Upper(PrimaryKey);  
        Parameters = InvocationContext.FindRows(FilterParameters);
        If Parameters.Count() = 1 Then
            
            SetDataCompositionDataParameterValue(DataParameters, PrimaryKey, 
                Parameters[0].Value);
                
        ElsIf Parameters.Count() > 1 Then 
            
            If NOT Item.ValueListAllowed Then
                
                ErrorMessage = NStr("en='The invocation context has several primary key values.
                    |Parameter property {ValueListAllowed} is set to value {False}.';
                    |ru='Контекст вызова имеет несколько значений первичных ключей.
                    |Свойству параметра {ДоступенСписокЗначений} установлено значение {Ложь}.';
                    |en_CA='The invocation context has several primary key values.
                    |Parameter property {ValueListAllowed} is set to value {False}.'");
                        
                Raise ErrorMessage;
                
            EndIf;
            
            ValueList = New ValueList;
            For Each Parameter In Parameters Do
                ValueList.Add(Parameter.Value);        
            EndDo;
            
            SetDataCompositionDataParameterValue(DataParameters, PrimaryKey, 
                ValueList);
            
        EndIf;
                
    EndDo;
    
EndProcedure // FillDataCompositionParameterValueCollection()

// Sets value of data parameter by identifier. 
//
// Parameters:
//  DataParameters - DataCompositionDataParameterValues - values of data parameters. 
//                                          They are implemented as parameter values.
//  ID             - String                             - identifier of parameter.
//  Value          - Arbitrary                          - converted parameter value.
//
Procedure SetDataCompositionDataParameterValue(DataParameters, ID, Value)

    Items = DataParameters.Items;
    SearchResult = Items.Find(ID);
    If SearchResult <> Undefined Then
        SearchResult.Use = True;
        SearchResult.Value = Value;
    Else
        
        // Research is needed whether we can add new parameters.        
        Raise StrTemplate(NStr("en='For field {%1} adding new elements into 
                |{DataCompositionParameterValueCollection} not implemented.';
            |ru='Для поля {%1} добавление новых элементов в 
                |{КоллекцияЗначенийПараметровКомпоновкиДанных} не реализовано.';
            |en_CA='For field {%1} adding new elements into 
                |{DataCompositionParameterValueCollection} not implemented.'"),
            ID);
        
    EndIf;

EndProcedure // SetValueOfDataCompositionAvailableParameter()

// Returns the structure with template columns which is needed for output processor. 
//
// Parameters:
//  DataCompositionSettings     - DataCompositionSettings     - settings, for which template has been created.
//  DataCompositionTemplate     - DataCompositionTemplate     - main data composition template, for which is needed 
//                                  to create a structure with the names of columns nested in data composition layouts.
//  DataCompositionTemplateBody - DataCompositionTemplateBody - the body of current data composition layout.
//  TemplateColumns             - Structure                   - cache with template columns for output processor. 
//                                Default value: Undefined.
//  ColumnsCache                - Structure                   - see function FL_DataComposition.NewColumnsCache.
//                                Default value: Undefined.
//  ResourcesCache              - Structure                   - see function FL_DataComposition.NewResourcesCache.
//                                Default value: Undefined.
//  ColumnsToSkip               - Map -                       - map with columns to skip on current level of the hierarchy.
//                                Default value: Undefined.
//
// Returns:
//  Structure - with keys:
//      * Key   - String    - names of nested data composition layouts.
//      * Value - Structure - with keys:
//          ** Key   - String - cell string values of the certain data composition layout (P1, P2, ... Pn).
//          ** Value - String - normalized column name.
//
Function TemplateColumns(DataCompositionSettings, 
    DataCompositionTemplate, DataCompositionTemplateBody, 
    TemplateColumns = Undefined, ColumnsCache = Undefined, 
    ResourcesCache = Undefined, ColumnsToSkip = Undefined)
    
    // Precache columns, resources and objects.
    If TemplateColumns = Undefined AND ColumnsCache = Undefined
        AND ResourcesCache = Undefined AND ColumnsToSkip = Undefined Then
     
        ColumnsToSkip = New Map;
        TemplateColumns = New Structure;
        
        ColumnsCache = NewColumnsCache(DataCompositionTemplate);
        
        // Here can be FATAL errors in future if synonyms will be used from 
        // DataCompositionScheme due to 1C:Enterprise platform restrictions.
        ResourcesCache = NewResourcesCache(
            DataCompositionSettings.Selection.SelectionAvailableFields.Items);        
               
    EndIf;
    
    For Each ItemBody In DataCompositionTemplateBody Do
        
        If TypeOf(ItemBody) = Type("DataCompositionTemplateAreaTemplate") Then
            Continue;
        EndIf;
        
        NextLevelColumnsToSkip = New Map;
         
        AreaTemplateDefinition = AreaTemplateDefinition(DataCompositionTemplate, 
            ItemBody);    
            
        TemplateColumns.Insert(AreaTemplateDefinition.Name, New Structure);
        
        For Each Cell In AreaTemplateDefinition.Template.Cells Do
            
            If Cell.Value = Undefined Then
                // Field isn't used by current template, skip.
                Continue;
            EndIf;  
            
            CellKey = String(Cell.Value);
            
            // Here can be a fatal error. However, in future it might be handled.
            ColumnName = ColumnsCache[AreaTemplateDefinition.Name][CellKey];
            
            // Skip column on current level.
            SkipColumn = ColumnsToSkip.Get(CellKey) <> Undefined;
            
            // Group
            If TypeOf(ItemBody) = Type("DataCompositionTemplateGroup") Then
                
                // Now, it is a fatal error. However, in future it might be handled.
                DCExpression = AreaTemplateDefinition.Parameters.Find(CellKey);
                If DCExpression = Undefined Then
                    
                    ErrorMessage = NStr("en='{DataCompositionExpressionAreaParameter} is not found.';
                        |ru='{ПараметрОбластиВыражениеКомпоновкиДанных} не найден.';
                        |uk='{ПараметрОбластиВыражениеКомпоновкиДанных} не знайдено.';
                        |en_CA='{DataCompositionExpressionAreaParameter} is not found.'");
                        
                    Raise ErrorMessage;
                    
                EndIf;    
                    
                Result = GroupTemplateItem(ItemBody.Group, 
                    DCExpression.Expression, Not SkipColumn);        
                If Result = Undefined Then
                    // If it is a resource it must be in place.
                    If Not ResourcesCache.Property(ColumnName) Then
                        // It isn't a resource, skip.
                        Continue;
                    EndIf;
                Else
                    // Skip column on next level. 
                    NextLevelColumnsToSkip.Insert(CellKey, 
                        DCExpression.Expression);
                EndIf;
                
            // Detail records
            ElsIf TypeOf(ItemBody) = Type("DataCompositionTemplateRecords") Then
            
                If SkipColumn Then
                    // Colunm is used higher in hierarchy, skip. 
                    Continue;
                EndIf;
                
            EndIf;
            
            TemplateColumns[AreaTemplateDefinition.Name].Insert(CellKey, ColumnName);
            
        EndDo;
           
        // Is there nested elements?
        If ItemBody.Body.Count() > 1 Then
            
            For Each Column In ColumnsToSkip Do
                NextLevelColumnsToSkip.Insert(Column.Key, Column.Value);
            EndDo;
            
            TemplateColumns(DataCompositionSettings, 
                DataCompositionTemplate, 
                ItemBody.Body, 
                TemplateColumns, 
                ColumnsCache, 
                ResourcesCache, 
                NextLevelColumnsToSkip);
            
        EndIf;
        
    EndDo;

    Return TemplateColumns;
    
EndFunction // TemplateColumns() 

// Creates a new structure with columns cache from main data composition template.
//
// Parameters:
//  DataCompositionTemplate - DataCompositionTemplate - main data composition template, for which is needed 
//                                  to create a map with the names of columns nested in data composition layouts.
//
// Returns:
//  Structure - with keys:
//      * Key   - String - names of nested data composition layouts. 
//                         Remember, every nested data composition layout can have own order of groups and columns. 
//      * Value - Structure - columns cache of the certain data composition layout.
//          ** Key   - String - cell string values of the certain data composition layout (P1, P2, ... Pn).
//          ** Value - String - normalized column name. 
//
Function NewColumnsCache(DataCompositionTemplate)
    
    ColumnsCache = New Structure;
    
    // Interesting, it has other dependency then script variant.
    // ScriptVariant = Metadata.ObjectProperties.ScriptVariant;
    // If (Metadata.ScriptVariant = ScriptVariant.English) Then
    //    MainTemplate = DataCompositionTemplate.Templates.Find("Template1");
    // ElsIf (Metadata.ScriptVariant = ScriptVariant.Russian) Then 
    //    MainTemplate = DataCompositionTemplate.Templates.Find("Макет1");    
    // EndIf;
    
    MainTemplate = DataCompositionTemplate.Templates.Find("Template1");
    If MainTemplate = Undefined Then
        MainTemplate = DataCompositionTemplate.Templates.Find("Макет1");
    EndIf;
    
    // It's empty data composition scheme.
    If MainTemplate = Undefined Then
        Return ColumnsCache; 
    EndIf;
    
    MainTemplateCells = MainTemplate.Template.Cells;
    For Each Template In DataCompositionTemplate.Templates Do  
        
        If MainTemplate = Template Then
            Continue;
        EndIf;
        
        TemplateColumnCache = New Structure; 
        Cells = Template.Template.Cells;
        For Index = 0 To Cells.Count() - 1 Do
            
            Cell = Cells[Index];
            If Cell.Value = Undefined Then
                // Field isn't used by current template, skip.
                Continue;
            EndIf;
            
            // Go through types and decide what is the type.
            // Primitive (String, Number, Boolean, Undefined, Null)
            // Reference
            // Date
            
            //CellFromMain.ValueType.ContainsType(Type("String"))
            //CellFromMain.ValueType.ContainsType(Type("Number"))
            
            CellFromMain = MainTemplateCells[Index];
            If NOT IsBlankString(CellFromMain.Title) Then
                Value = NormalizeColumnName(CellFromMain.Title);    
            ElsIf NOT IsBlankString(Cell.Column) Then
                Value = NormalizeColumnName(Cell.Column);    
            Else
                Value = NormalizeColumnName(CellFromMain.Name);    
            EndIf;
            
            TemplateColumnCache.Insert(String(Cell.Value), Value); 
            
        EndDo;
        
        ColumnsCache.Insert(Template.Name, TemplateColumnCache);
    
    EndDo;
    
    Return ColumnsCache; 
    
EndFunction // NewColumnsCache() 

// Recursively creates a new strucutre with resources cache from data composition settings.
//
// Parameters:
//  Items          - DataCompositionAvailableFieldCollection - collection of available fields.
//  ResourcesCache - Structure - resources cache.
//
// Returns:
//  Structure - with keys:
//      * Key - normalized resource name.
//
Function NewResourcesCache(Items, ResourcesCache = Undefined)

    If ResourcesCache = Undefined Then
        ResourcesCache = New Structure;       
    EndIf;
    
    For Each Item In Items Do
                                           
        If Item.Resource Then
            ColumnName = String(Item.Field);
            ResourcesCache.Insert(NormalizeColumnName(ColumnName));
        EndIf;
        
        If Item.Table Then
            NewResourcesCache(Item.Items, ResourcesCache);
        EndIf;

    EndDo;
    
    Return ResourcesCache;
    
EndFunction // NewResourcesCache()

// Returns normalized column name.
//
// Parameters:
//  ColumnName - String - column name, which needs to be normalized.
//
// Returns:
//  String - normalized column name.
//
Function NormalizeColumnName(Val ColumnName)
    
    ColumnName = StrReplace(ColumnName, ".", "");
    ColumnName = StrReplace(ColumnName, "'", "_");
    ColumnName = StrReplace(ColumnName, "[", "_");
    ColumnName = StrReplace(ColumnName, "]", "_");
    
    While True Do
        
        Position = StrFind(ColumnName, " ");
        If Position = 0 Then
            Break;
        EndIf;
        
        ColumnName = Mid(ColumnName, 1, Position - 1) 
            + Upper(Mid(ColumnName, Position + 1, 1)) 
            + Mid(ColumnName, Position + 2, StrLen(ColumnName) - Position + 2);
        
    EndDo;
    
    Return ColumnName;
    
EndFunction // NormalizeColumnName()

// Returns data composition template area template definition 
// that is matched to data composition template body.  
//
// Parameters:
//  DataCompositionTemplate - DataCompositionTemplate - main data composition template. 
//  BodyElement             - DataCompositionTemplateGroup, 
//                            DataCompositionTemplateChart,
//                            DataCompositionTemplateTableHierarchicalGroup,
//                            DataCompositionTemplateRecords, 
//                            DataCompositionTemplateTable,
//                            DataCompositionTemplateNestedObject. 
//  
// Returns:
//  DataCompositionTemplateAreaTemplateDefinition.
//
Function AreaTemplateDefinition(DataCompositionTemplate, BodyElement)
    
    // Now, it is a fatal error. However, in future it might be handled.
    If BodyElement.Body.Count() = 0 Then
        
        ErrorMessage = NStr("en='{DataCompositionTemplateAreaTemplate} is not found.';
            |ru='{МакетОбластиМакетаКомпоновкиДанных} не найден.';
            |uk='{МакетОбластиМакетаКомпоновкиДанных} не знайдено.';
            |en_CA='{DataCompositionTemplateAreaTemplate} is not found.'");
        
        Raise ErrorMessage;
        
    EndIf;
    
    AreaTemplate = BodyElement.Body[0];
    // Now, it is a fatal error. However, in future it might be handled.
    If TypeOf(AreaTemplate) <> Type("DataCompositionTemplateAreaTemplate") Then
        
        ErrorMessage = NStr("en='The body does not contain {DataCompositionTemplateAreaTemplate}.';
            |ru='Тело не содержит {МакетОбластиМакетаКомпоновкиДанных}.';
            |uk='Тіло не містить {МакетОбластиМакетаКомпоновкиДанных}.';
            |en_CA='The body does not contain {DataCompositionTemplateAreaTemplate}.'");
            
        Raise ErrorMessage;
        
    EndIf;
    
    SearchResult = DataCompositionTemplate.Templates.Find(AreaTemplate.Template);
    // Now, it is a fatal error. However, in future it might be handled.
    If SearchResult = Undefined Then
        
        ErrorMessage = NStr("en='{DataCompositionTemplateAreaTemplateDefinition} is not found.';
            |ru='{ОписаниеМакетаОбластиМакетаКомпоновкиДанных} не найден.';
            |uk='{ОписаниеМакетаОбластиМакетаКомпоновкиДанных} не знайдено.';
            |en_CA='{DataCompositionTemplateAreaTemplateDefinition} is not found.'");
            
        Raise ErrorMessage;
        
    EndIf;
    
    Return SearchResult; 
    
EndFunction // AreaTemplateDefinition()

// Returns template grouping item from template group according to the expression.
//
// Parameters:
//  TemplateGroup - DataCompositionTemplateGrouping - data composition template grouping collection.
//  Expression         - String  - a grouping item declaration.
//  ProcessSubordinate - Boolean - if it is top of hierarchy, fields from this group are also used at this level of 
//                                  hierarchy. If it is subordinate group and fields have intersections with parent
//                                  group, it is supposed to delete all parent fields which have been got recently
//                                  indirectly.
//
// Returns:
//  DataCompositionTemplateGroupingItem - item is found by expression.
//  Undefined - item isn't found by expression.
//
Function GroupTemplateItem(TemplateGroup, Expression, ProcessSubordinate = True)
    
    For Each TemplateGroupingItem In TemplateGroup Do
        
        If TemplateGroupingItem.Expression = Expression Then
            Return TemplateGroupingItem;
        EndIf;
        
        If ProcessSubordinate Then
            
            SubordinateData = TemplateGroupingItem.Expression + ".";
            If StrFind(Expression, SubordinateData) = 1 Then
                Return TemplateGroupingItem;
            EndIf;
            
        EndIf;
    
    EndDo;
    
    Return Undefined;
    
EndFunction // GroupTemplateItem()

// Returns an empty report structure. Names that were set early in the report 
// strucure with help of context menu command "Set name...".
//
// Returns:
//  Structure - with keys:
//      * Names     - Structure - with keys:
//          ** Key   - String - the name of nested data composition layout.
//          ** Value - String - the name of body element group in nested data 
//                              composition layout. It will be used as a name 
//                              of array during output process execution.
//      * Hierarchy - ValueTree - with columns:
//          ** Name     - String - the name of nested data composition layout.
//          ** Template - String - the name of body element group in nested data 
//                              composition layout. It will be used as a name 
//                              of array during output process execution.
//
Function NewReportStructure()
    
    MaxLengthOfAreaName = 13; // 99999 Templates in one data composition schema.
    MaxLengthOfBodyName = 50;
    
    Hierarchy = New ValueTree;
    Hierarchy.Columns.Add("Template", FL_CommonUse.StringTypeDescription(
        MaxLengthOfAreaName));
    Hierarchy.Columns.Add("Name", FL_CommonUse.StringTypeDescription(
        MaxLengthOfBodyName));
    
    ReportStructure = New Structure;
    ReportStructure.Insert("Names", New Structure);
    ReportStructure.Insert("Hierarchy", Hierarchy);
    
    Return ReportStructure;
    
EndFunction // NewReportStructure() 

#EndRegion // ServiceProceduresAndFunctions