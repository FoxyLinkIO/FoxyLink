////////////////////////////////////////////////////////////////////////////////
// This file is part of IHL (Integration happiness library).
// Copyright © 2016-2017 Petro Bazeliuk.
// 
// IHL is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as 
// published by the Free Software Foundation, either version 3 
// of the License, or any later version.
// 
// IHL is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public 
// License along with IHL. If not, see <http://www.gnu.org/licenses/>.
//
////////////////////////////////////////////////////////////////////////////////

#Region ProgramInterface

// Outputs the result of the data composition scheme in the stream object.
//
// Parameters:
//  Mediator         - Arbitrary - reserved, currently not in use.
//  StreamObject     - Arbitrary - an object is designed for character output by data composition processor.
//  OutputParameters - Structure - see function IHL_DataComposition.NewOutputParameters.
//  SaveResources    - Boolean   - use sequential output to save resources. 
//                     Default value: True.
//
Procedure Output(Mediator, StreamObject, OutputParameters, 
    Val SaveResources = True) Export
    
    // TODO: Check output parameters   
    
    // TODO: Mediator.Logger (Trace, Debug, Warning+)
    DCTParameters = IHL_CommonUseClientServer.CopyStructure(
        OutputParameters.DCTParameters);
        
    // TODO: Make support of DataCompositionTemplateGenerator.
    // Verify, that supported type of generator is in use.
    DCTParameters.GeneratorType = 
        Type("DataCompositionValueCollectionTemplateGenerator");
        
    // TODO: Mediator.Logger (Trace, Debug, Warning+)
    // TODO: Mediator.Performance (APDEX, OPDEX)
    // Create data composition template.
    DataCompositionTemplate = NewDataCompositionTemplate(DCTParameters);
    
    // TODO: Mediator.Logger (Trace, Debug, Warning+)
    // TODO: Mediator.Performance (APDEX, OPDEX)
    // Init data composition processor.
    DataCompositionProcessor = New DataCompositionProcessor;
    DataCompositionProcessor.Initialize(DataCompositionTemplate, 
        OutputParameters.ExternalDataSets, 
        OutputParameters.DetailsData, 
        OutputParameters.CanUseExternalFunctions);
        
  
    // TODO: Mediator.Logger (Trace, Debug, Warning+)
    // TODO: Mediator.Performance (APDEX, OPDEX)
    GroupNames = GroupNames(Mediator, DataCompositionTemplate, 
        DataCompositionTemplate.Body, SaveResources);
        
    // TODO: Mediator.Logger (Trace, Debug, Warning+)
    // TODO: Mediator.Performance (APDEX, OPDEX)
    // Init template columns with particular order.
    TemplateColumns = TemplateColumns(Mediator, DCTParameters.Template,
        DataCompositionTemplate, DataCompositionTemplate.Body);
        
    // Handle naming restrictions.
    // Object can have naming restrictions and this problems should be handled in place.
    StreamObject.VerifyGroupNames(Mediator, GroupNames);
    StreamObject.VerifyColumnNames(Mediator, TemplateColumns);
    
    
    // TODO: Mediator.Logger (Trace, Debug, Warning+)
    // Output start
    DataCompositionProcessor.Next(); // StartElement
    DataCompositionProcessor.Next(); // DataCompositionTemplate
    
    // TODO: Mediator.Logger (Trace, Debug, Warning+)
    // TODO: Mediator.Performance (APDEX, OPDEX)
    Item = DataCompositionProcessor.Next(); // Query execution 
    
    If SaveResources = True Then
        // TODO: Mediator.Logger (Trace, Debug, Warning+)
        // TODO: Mediator.Performance (APDEX, OPDEX)
        StreamObject.MemorySavingOutput(Item, DataCompositionProcessor, 
            TemplateColumns, GroupNames); 
    Else
        // TODO: Mediator.Logger (Trace, Debug, Warning+)
        // TODO: Mediator.Performance (APDEX, OPDEX)
        StreamObject.FastOutput(Item, DataCompositionProcessor, 
            TemplateColumns, GroupNames);    
    EndIf;
    
EndProcedure // Output()

#EndRegion // ProgramInterface

#Region ServiceProgramInterface

// Currently is used in tests.
Procedure InitSettingsComposer(Mediator, SettingsComposer, 
    DataCompositionSchemaURL, DataCompositionSettingsURL = Undefined) Export

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
        
        ErrorMessage = StrTemplate(NStr(
                "en = 'Error: Failed to initialize data composition settings composer. %1.';
                |ru = 'Ошибка: Не удалось инициализировать компоновщик настроек компоновки данных. %1.';
                |uk = 'Помилка: Не вдалось ініціалізувати компоновщик налаштувань компоновки данних. %1.'"),
            ErrorDescription());
            
        Raise ErrorMessage;
             
    EndTry;

    If TypeOf(DataCompositionSettings) = Type("DataCompositionSettings") Then
        
        SettingsComposer.LoadSettings(DataCompositionSettings);
        
    ElsIf TypeOf(DataCompositionSchema) = Type("DataCompositionSchema") Then
        
        SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
        
    Else
        
        ErrorMessage = NStr(
            "en = 'Error: Failed to find data composition settings';
            |ru = 'Ошибка: Не удалось найти настроки компоновки данных.';
            |uk = 'Помилка: Не вдалось знайти налаштування компоновки данних.'");
            
        Raise ErrorMessage;
        
    КонецЕсли;

    SettingsComposer.Refresh(
        DataCompositionSettingsRefreshMethod.CheckAvailability);

EndProcedure // InitSettingsComposer()



// Creates layout template according passed parameters.
//
// Parameters:
//  DCTParameters - Structure - see function IHL_DataComposition.NewDataCompositionTemplateParameters.
//
// Returns:
//  DataCompositionTemplate - created layout template.
//
Function NewDataCompositionTemplate(DCTParameters) Export
   
    // TODO: Проверка параметров макета
    
 
    DCTComposer = New DataCompositionTemplateComposer;
    Return DCTComposer.Execute(
        DCTParameters.Schema, 
        DCTParameters.Template, 
        DCTParameters.DetailsData, 
        DCTParameters.AppearanceTemplate, 
        DCTParameters.GeneratorType,
        DCTParameters.CheckFieldsAvailability,
        DCTParameters.FunctionalOptionParameters);
    
EndFunction // NewDataCompositionTemplate()


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
//      * DCTParameters - Structure - see function IHL_DataComposition.NewDataCompositionTemplateParameters.
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
Function NewDataCompositionTemplateParameters() Export
    
    DCTParameters = New Structure;
    DCTParameters.Insert("Schema");
    DCTParameters.Insert("Template");
    DCTParameters.Insert("DetailsData");
    DCTParameters.Insert("AppearanceTemplate");
    DCTParameters.Insert("GeneratorType", Type("DataCompositionTemplateGenerator"));
    DCTParameters.Insert("CheckFieldsAvailability", True);
    DCTParameters.Insert("FunctionalOptionParameters");
    Return DCTParameters;
    
EndFunction // NewDataCompositionTemplateParameters()

#EndRegion // ServiceProgramInterface

#Region ServiceProceduresAndFunctions

// Recursively fills the structure of group names from nested data composition 
// layouts in main data composition template. 
//
// Note:
//  Return value is type of "Structure", not "Map".
//  The main reason is that "Structure" was faster then "Map" on test system 
//  in ~17.62% or ~1967 ms for 100000 executions.
//
//  The first character of a group name must be either a letter or an underscore character "_". Subsequent characters 
//  may be letters, underscore characters, or numbers. If a name of group brakes the rule, the SaveResources parameter 
//  is set "True" and fast output is imposible due to naming restrictions of 1C:Enterprise platform.
//  
// Parameters:
//  Mediator     - Arbitrary - reserved, currently not in use.
//  DataCompositionTemplate - DataCompositionTemplate - main data composition template, for which is needed to create 
//                                           a structure with the names of groups nested in data composition layouts. 
//  DataCompositionTemplateBody - DataCompositionTemplateBody - the body of current data composition layout. 
//  SaveResources - Boolean   - use sequential output to save resources.
//  GroupNames    - Structure - group names that were set early in the report strucure 
//                              with help of context menu command "Set name...".
//                  Default value: Undefined.
//
// Returns:
//  Structure - group names that were set early in the report strucure with help of context menu command "Set name...".
//      * Key   - String - the name of nested data composition layout.
//      * Value - String - the name of body element group in nested data composition layout. 
//                          It will be used as a name of array during output process execution. 
//
Function GroupNames(Mediator, DataCompositionTemplate, 
    DataCompositionTemplateBody, SaveResources, GroupNames = Undefined)
    
    If GroupNames = Undefined Then
        GroupNames = New Structure;
    EndIf;
    
    For Each ItemBody In DataCompositionTemplateBody Do
        
        If TypeOf(ItemBody) = Type("DataCompositionTemplateAreaTemplate") Then
            Continue; 
        EndIf;
        
        AreaTemplateDefinition = AreaTemplateDefinition(Mediator, 
            DataCompositionTemplate, ItemBody);
            
        If SaveResources = False Then
            SaveResources = Not IHL_CommonUseClientServer.IsCorrectVariableName(
                ItemBody.Name);
        EndIf;
        
        GroupNames.Insert(AreaTemplateDefinition.Name, ItemBody.Name);
        
        If ItemBody.Body.Count() > 1 Then
            GroupNames(Mediator, DataCompositionTemplate, ItemBody.Body,
                SaveResources, GroupNames);
        EndIf;
             
    EndDo;
    
    Return GroupNames;
    
EndFunction // GroupNames()

// Returns the structure with template columns which is needed for output processor. 
//
// Parameters:
//  Mediator                    - Arbitrary - reserved, currently not in use.
//  DataCompositionSettings     - DataCompositionSettings     - settings, for which template has been created.
//  DataCompositionTemplate     - DataCompositionTemplate     - main data composition template, for which is needed 
//                                  to create a structure with the names of columns nested in data composition layouts.
//  DataCompositionTemplateBody - DataCompositionTemplateBody - the body of current data composition layout.
//  TemplateColumns             - Structure                   - cache with template columns for output processor. 
//                                Default value: Undefined.
//  ColumnsCache                - Structure                   - see function IHL_DataComposition.NewColumnsCache.
//                                Default value: Undefined.
//  ResourcesCache              - Structure                   - see function IHL_DataComposition.NewResourcesCache.
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
Function TemplateColumns(Mediator, DataCompositionSettings, 
    DataCompositionTemplate, DataCompositionTemplateBody, 
    TemplateColumns = Undefined, ColumnsCache = Undefined, 
    ResourcesCache = Undefined, ColumnsToSkip = Undefined)
    
    // Precache columns, resources and objects.
    If TemplateColumns = Undefined And ColumnsCache = Undefined
        And ResourcesCache = Undefined And ColumnsToSkip = Undefined Then
     
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
         
        AreaTemplateDefinition = AreaTemplateDefinition(Mediator, 
            DataCompositionTemplate, ItemBody);    
            
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
                    
                    ErrorMessage = NStr(
                        "en = '""DataCompositionExpressionAreaParameter"" is not found.'; 
                        |ru = '""ПараметрОбластиВыражениеКомпоновкиДанных"" не найден.'; 
                        |uk = '""ПараметрОбластиВыражениеКомпоновкиДанных"" не знайдено.'");
                        
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
            
            TemplateColumns(Mediator, DataCompositionSettings, 
                DataCompositionTemplate, ItemBody.Body, TemplateColumns, 
                ColumnsCache, ResourcesCache, NextLevelColumnsToSkip);
            
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
    //ScriptVariant = Metadata.ObjectProperties.ScriptVariant;
    //If (Metadata.ScriptVariant = ScriptVariant.English) Then
    //    MainTemplate = DataCompositionTemplate.Templates.Find("Template1");
    //ElsIf (Metadata.ScriptVariant = ScriptVariant.Russian) Then 
    //    MainTemplate = DataCompositionTemplate.Templates.Find("Макет1");    
    //EndIf;
    
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
            
            
            If IsBlankString(Cell.Column) Then
                Value = NormalizeColumnName(MainTemplateCells[Index].Name);
            Else
                Value = NormalizeColumnName(Cell.Column);
            EndIf;
            
            TemplateColumnCache.Insert(String(Cell.Value), Value); 
            
        КонецЦикла;
        
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

    If (ResourcesCache = Undefined) Then
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
//  Mediator                    - Arbitrary               - reserved, currently not in use.
//  DataCompositionTemplate     - DataCompositionTemplate - main data composition template. 
//  DataCompositionTemplateBody - DataCompositionTemplateGroup, 
//                                DataCompositionTemplateChart,
//                                DataCompositionTemplateTableHierarchicalGroup,
//                                DataCompositionTemplateRecords, 
//                                DataCompositionTemplateTable,
//                                DataCompositionTemplateNestedObject. 
//  
// Returns:
//  DataCompositionTemplateAreaTemplateDefinition.
//
Function AreaTemplateDefinition(Mediator, DataCompositionTemplate, BodyElement)
    
    // Now, it is a fatal error. However, in future it might be handled.
    If BodyElement.Body.Count() = 0 Then
        
        ErrorMessage = NStr(
            "en = '""DataCompositionTemplateAreaTemplate"" is not found.'; 
            |ru = '""МакетОбластиМакетаКомпоновкиДанных"" не найден.'; 
            |uk = '""МакетОбластиМакетаКомпоновкиДанных"" не знайдено.'");
        
        Raise ErrorMessage;
        
    EndIf;
    
    AreaTemplate = BodyElement.Body[0];
    // Now, it is a fatal error. However, in future it might be handled.
    If TypeOf(AreaTemplate) <> Type("DataCompositionTemplateAreaTemplate") Then
        
        ErrorMessage = NStr(
            "en = 'The body does not contain ""DataCompositionTemplateAreaTemplate"".'; 
            |ru = 'Тело не содержит ""МакетОбластиМакетаКомпоновкиДанных"".'; 
            |uk = 'Тіло не містить ""МакетОбластиМакетаКомпоновкиДанных"".'");
            
        Raise ErrorMessage;
        
    EndIf;
    
    SearchResult = DataCompositionTemplate.Templates.Find(AreaTemplate.Template);
    // Now, it is a fatal error. However, in future it might be handled.
    If SearchResult = Undefined Then
        
        ErrorMessage = NStr(
            "en = '""DataCompositionTemplateAreaTemplateDefinition"" is not found.'; 
            |ru = '""ОписаниеМакетаОбластиМакетаКомпоновкиДанных"" не найден.'; 
            |uk = '""ОписаниеМакетаОбластиМакетаКомпоновкиДанных"" не знайдено.'");
            
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

#EndRegion // ServiceProceduresAndFunctions