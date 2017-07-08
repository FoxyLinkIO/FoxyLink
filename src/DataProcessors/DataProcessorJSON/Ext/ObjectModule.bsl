////////////////////////////////////////////////////////////////////////////////
// This file is part of IHL (Integration happiness library).
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
// along with this program. If not, see <http://www.gnu.org/licenses/agpl-3.0>.
//
////////////////////////////////////////////////////////////////////////////////

#Region VariablesDescription

Var RefTypesCache; // Types cache for ConvertFunction.
Var StreamWriter; // It is used to write JSON objects and texts. 

#EndRegion // VariablesDescription

#Region FormatDescription

// Number of the formal document from the Internet Engineering Task Force 
// (IETF) that is the result of committee drafting and subsequent review 
// by interested parties.
//
Function FormatStandard() Export
    
    Return "RFC 7159";
    
EndFunction // FormatStandard()

// Returns link to the formal document from the Internet Engineering Task Force 
// (IETF) that is the result of committee drafting and subsequent review 
// by interested parties.
//
Function FormatStandardLink() Export
    
    Return "https://tools.ietf.org/html/rfc7159";
    
EndFunction // FormatStandardLink()

// Returns short format name.
//
// Returns:
//  String - format short name.
// 
Function FormatShortName() Export
    
    Return "JSON";    
    
EndFunction // FormatShortName()

// Returns full format name.
//
// Returns:
//  String - format full name.
//
Function FormatFullName() Export
    
    Return "The JavaScript Object Notation";    
    
EndFunction // FormatFullName()

// Returns format file extension.
//
// Returns:
//  String - file extension.
//
Function FormatFileExtension() Export
    
    Return ".json";
    
EndFunction // FormatFileExtension()

// Returns format media type.
//
// Returns:
//  String - format media type.
//
Function FormatMediaType() Export
    
    Return "application/json";
    
EndFunction // FormatMediaType()




Function SupportedTypes() Export
    
    ValueList = New ValueList();
    ValueList.Add("String");
    ValueList.Add("Number");
    ValueList.Add("Boolean");
    ValueList.Add("Null");
    ValueList.Add("Object");
    ValueList.Add("Array");
    Return ValueList;
    
EndFunction // SupportedTypes()

// Check if a type can have nested items.
//
// Parameters:
//  TypeName  - String - type name.
//
// Returns:
//   Boolean - True if this type can have nested items; False in other case.
//
Function TypeCanHaveNestedItems(TypeName) Export
    
    If TypeName = "Object" Or TypeName = "Array" Then
        Return True;
    EndIf;
    
    Return False;
    
EndFunction // TypeCanHaveNestedItems()

#EndRegion // FormatDescription

#Region ProgramInterface

// Constructor of stream object.
//
// Parameters:
//  APISchema - Arbitrary - user defined API schema.
//                  Default value: Undefined.
//  OpenFile  - String    - output filename.
//                  Default value: Undefined.
//
Procedure Initialize(APISchema = Undefined, OpenFile = Undefined) Export
    
    RefTypesCache = New Map;
    
    If APISchema <> Undefined Then
        If TypeOf(ThisObject.APISchema) = TypeOf(APISchema) Then    
            ThisObject.APISchema = APISchema.Copy();
        Else
            // Old version schema support could be implemented at this place.
        EndIf;
    EndIf;
    
    StreamWriter = New JSONWriter;
    If OpenFile <> Undefined Then 
            
    Else
        StreamWriter.SetString();    
    EndIf;
    
EndProcedure // Initialize()


// This object can have naming restrictions and this problems should be handled. 
//
// Parameters:
//  Mediator   - Arbitrary - reserved, currently not in use.
//  GroupNames - Structure - see function IHL_DataComposition.GroupNames.
//
Procedure VerifyGroupNames(Mediator, GroupNames) Export
    
    // No naming restrictions.
    
EndProcedure // VerifyGroupNames()

// This object can have naming restrictions and this problems should be handled. 
//
// Parameters:
//  Mediator        - Arbitrary - reserved, currently not in use.
//  TemplateColumns - Structure - see function IHL_DataComposition.TemplateColumns.
//
Procedure VerifyColumnNames(Mediator, TemplateColumns) Export
    
    // No naming restrictions.
    
EndProcedure // VerifyColumnNames()


// Records a JSON property name.
//
// Parameters:
//  PropertyName - String - property name.  
//
Procedure WritePropertyName(PropertyName) Export
    StreamWriter.WritePropertyName(PropertyName);    
EndProcedure // WritePropertyName()

// Records the beginning of the JSON object.
//
Procedure WriteStartObject() Export
    StreamWriter.WriteStartObject();    
EndProcedure // WriteStartObject() 

// Records the end of a JSON object.
//
Procedure WriteEndObject() Export
    StreamWriter.WriteEndObject();  
EndProcedure // WriteEndObject()

// Records the beginning of JSON array.
//
Procedure WriteStartArray() Export
    StreamWriter.WriteStartArray();    
EndProcedure // WriteStartArray()

// Records the end of the JSON array.
//
Procedure WriteEndArray() Export
    StreamWriter.WriteEndArray();       
EndProcedure // WriteEndArray()

// Records JSON property value.
//
// Parameters:
//  Value - Arbitrary - the written value.
//
Procedure WriteValue(Value) Export
    
    WriteJSON(StreamWriter, Value, , "ConvertFunction", ThisObject);    
    
EndProcedure // WriteValue()


// Completes JSON text writing. If writing to a file, the file is closed. If writing to a string, the resultant string 
// will be returned as the method's return value. If writing to file, the method will return an empty string.
//
// Returns:
//  String - JSON string.
//
Function Close() Export
    Return StreamWriter.Close();   
EndFunction // Close() 

#EndRegion // ProgramInterface

#Region ServiceProgramInterface

// Outputs sequentially result of the data composition shema into stream object.
//
// Parameters:
//  Item            - DataCompositionResultItem         - a data composition result item.
//  DataCompositionProcessor - DataCompositionProcessor - object that performs data composition.
//  TemplateColumns - Structure - see function IHL_DataComposition.TemplateColumns.
//  GroupNames      - Structure - see function IHL_DataComposition.GroupNames.
//
Procedure MemorySavingOutput(Item, DataCompositionProcessor, TemplateColumns, 
    GroupNames) Export
    
    If APISchema.Rows.Count() = 0 Then
        
        // It is used when API format is not provided.
        BasicMemorySavingOutput(Item, DataCompositionProcessor, 
            TemplateColumns, GroupNames);
            
    Else

        // It is used when API format is provided.
        APISchemaMemorySavingOutput(Item, DataCompositionProcessor, 
            TemplateColumns, GroupNames);
            
    EndIf;
        
EndProcedure // MemorySavingOutput()

// Outputs fast result of the data composition shema into stream object.
// 
// Note:
//  Additional memory in use.
//
// Parameters:
//  Item            - DataCompositionResultItem         - a data composition result item.
//  DataCompositionProcessor - DataCompositionProcessor - object that performs data composition.
//  TemplateColumns - Structure - see function IHL_DataComposition.TemplateColumns.
//  GroupNames      - Structure - see function IHL_DataComposition.GroupNames.
//
Procedure FastOutput(Item, DataCompositionProcessor, TemplateColumns, 
    GroupNames) Export 
    
    If APISchema.Rows.Count() = 0 Then
        
        // It is used when API format is not provided.
        BasicFastOutput(Item, DataCompositionProcessor, 
            TemplateColumns, GroupNames);
            
    Else

        // It is used when API format is provided.
        APISchemaFastOutput(Item, DataCompositionProcessor, 
            TemplateColumns, GroupNames);
            
    EndIf;
     
EndProcedure // FastOutput()

// This function is called for all properties if their types do not support direct conversion to JSON format.
//
// Parameters:
//  Property             - String    - name of property is transferred into the parameter if the structure 
//                                      or mapping is written
//  Value                - Arbitrary - the source value is transferred into the parameter.
//  AdditionalParameters - Arbitrary - additional parameters specified in the call to the WriteJSON method.
//  Cancel               - Boolean   - cancels the property write operation.
//
// Returns:
//   Converted Value into value allowed for the JSON-type record. 
//
Function ConvertFunction(Property, Value, AdditionalParameters, Cancel) Export 
    
    ValueType = TypeOf(Value);
    
    If Value = Null Then
        Return Undefined;
    ElsIf RefTypesCache[ValueType] = True Then
        Return XMLString(Value);
    ElsIf IHL_CommonUse.IsReference(ValueType) Then
        RefTypesCache.Insert(ValueType, True);
        Return XMLString(Value);
    Else 
        Return Undefined;
    EndIf;

EndFunction // ConvertFunction()

#EndRegion // ServiceProgramInterface

#Region ServiceProceduresAndFunctions

// Only for internal use.
// 
Procedure BasicMemorySavingOutput(Item, DataCompositionProcessor, 
    TemplateColumns, GroupNames)
    
    Var Level; 
    
    End = DataCompositionResultItemType.End;
    Begin = DataCompositionResultItemType.Begin;
    BeginAndEnd = DataCompositionResultItemType.BeginAndEnd;
    
    StreamWriter.WriteStartObject();
    
    While True Do
        
        If Item = Undefined Then
            Break;
        EndIf;
        
        If Item.ItemType = Begin Then
            
            Item = DataCompositionProcessor.Next();
            If Item.ItemType = Begin Then
                
                Item = DataCompositionProcessor.Next();
                If Item.ItemType = BeginAndEnd Then
                   
                    // It works better for complicated hierarchy.
                    Level = ?(Level = Undefined, 0, Level + 1);
                    
                    StreamWriter.WritePropertyName(GroupNames[Item.Template]);
                    StreamWriter.WriteStartArray();
                    
                EndIf;
                
            EndIf;
            
        EndIf;
        
        If Level <> Undefined Then
            
            If Item.ItemType = End Then
                
                StreamWriter.WriteEndObject();
                
                Item = DataCompositionProcessor.Next();
                If Item.ItemType = End Then
                    
                    // It works better for complicated hierarchy.
                    Level = ?(Level - 1 < 0, Undefined, Level - 1);
                    
                    StreamWriter.WriteEndArray();
                    
                // ElsIf Not IsBlankString(Item.Template) Then
                    
                    // It is impossible to get here due to structure of output.
                    
                EndIf;
                
            ElsIf Not IsBlankString(Item.Template) Then
                
                ColumnNames = TemplateColumns[Item.Template];
                
                StreamWriter.WriteStartObject();
                For Each ColumnName In ColumnNames Do
                    StreamWriter.WritePropertyName(ColumnName.Value);
                    WriteJSON(StreamWriter, Item.ParameterValues[ColumnName.Key].Value, , "ConvertFunction", ThisObject);
                EndDo;
                
            EndIf;
            
        EndIf;
        
        Item = DataCompositionProcessor.Next();
        
    EndDo;
    
    StreamWriter.WriteEndObject();        
    
EndProcedure // BasicMemorySavingOutput() 

// Only for internal use.
//
Procedure APISchemaMemorySavingOutput(Item, DataCompositionProcessor, 
    TemplateColumns, GroupNames)
    
    Var CurrentLevel, HasNestedItems; 
       
    FillParamName(GroupNames, TemplateColumns);
    
    
    Begin = DataCompositionResultItemType.Begin;
    BeginAndEnd = DataCompositionResultItemType.BeginAndEnd;
    End = DataCompositionResultItemType.End;
    
    While True Do
        
        If Item = Undefined Then
            Break;
        EndIf;
        
        If Item.ItemType = Begin Then
            
            Item = DataCompositionProcessor.Next();
            If Item.ItemType = Begin Then
                
                Item = DataCompositionProcessor.Next();
                If Item.ItemType = BeginAndEnd Then
                    
                    If CurrentLevel = Undefined Then
                        CurrentLevel = APISchema.Rows.Find(Item.Template, "Template");
                    Else
                        CurrentLevel = CurrentLevel.Rows.Find(Item.Template, "Template");
                    EndIf;
                    
                    
                    If CurrentLevel <> Undefined Then
                        If TypeOf(CurrentLevel.Listed) = Type("Undefined") Then
                            CurrentLevel.Listed = New Map;
                        EndIf;
                    Else     
                        ErrorMessage = StrTemplate(NStr(
                                "en = 'Error: Failed to find property with name: %1.';
                                |ru = 'Ошибка: Не удалось найти свойство с именем: %1.'"),
                            GroupNames[Item.Template]);
                        Raise ErrorMessage;
                    EndIf;
                    
                    HasNestedItems = TypeCanHaveNestedItems(CurrentLevel.Type);
                    
                    If CurrentLevel.Parent <> Undefined Then
                        
                        CheckDublicateProperty(CurrentLevel.Listed, 
                            CurrentLevel.Name, CurrentLevel.Parent.Name);
                        
                        StreamWriter.WritePropertyName(CurrentLevel.Name);
                        
                    EndIf;
                        
                    If CurrentLevel.Type = "Object" Then
                        StreamWriter.WriteStartObject();
                    ElsIf CurrentLevel.Type = "Array" Then
                        StreamWriter.WriteStartArray(); 
                    EndIf;
                                            
                EndIf;
                
            EndIf;
            
        EndIf;
        
        If CurrentLevel <> Undefined Then
            
            If Item.ItemType = End Then
                
                Item = DataCompositionProcessor.Next();
                If Item.ItemType = End Then
                    
                    If CurrentLevel.Type = "Object" Then
                        StreamWriter.WriteEndObject();
                    ElsIf CurrentLevel.Type = "Array" Then
                        StreamWriter.WriteEndArray();        
                    EndIf; 
                    
                    CurrentLevel = CurrentLevel.Parent;
                                                            
                EndIf;
                
            ElsIf Not IsBlankString(Item.Template) Then
                
                If HasNestedItems = True Then 
                    
                    For Each Row In CurrentLevel.Rows Do
                        
                        If TypeCanHaveNestedItems(Row.Type) = False Then
                            
                            CheckDublicateProperty(CurrentLevel.Listed, 
                                Row.Name, CurrentLevel.Name);
                            
                            StreamWriter.WritePropertyName(Row.Name);
                            WriteJSON(StreamWriter, 
                                Item.ParameterValues[Row.Parameter].Value, 
                                , 
                                "ConvertFunction", 
                                ThisObject);    
                            
                        EndIf;
                        
                    EndDo;
                    
                Else
                    
                    CheckDublicateProperty(CurrentLevel.Listed, 
                        CurrentLevel.Name, CurrentLevel.Name);
                    
                    WriteJSON(StreamWriter, 
                        Item.ParameterValues[CurrentLevel.Parameter].Value, 
                        , 
                        "ConvertFunction", 
                        ThisObject);        
                    
                EndIf;
                                
            EndIf;
            
        EndIf;
        
        Item = DataCompositionProcessor.Next();
        
    EndDo;
    
EndProcedure // APISchemaMemorySavingOutput()

// Only for internal use.
// 
Procedure BasicFastOutput(Item, DataCompositionProcessor, 
    TemplateColumns, GroupNames)

    Var CurrentRow;
    
    OutputTree = New ValueTree;
    OutputTree.Columns.Add("Array");
    OutputTree.Columns.Add("Structure");
    
    OutputStructure = New Structure;
    
    End = DataCompositionResultItemType.End;
    Begin = DataCompositionResultItemType.Begin;
    BeginAndEnd = DataCompositionResultItemType.BeginAndEnd;
    
    StreamWriter.WriteStartObject();
    
    While True Do
        
        If Item = Undefined Then
            Break;
        EndIf;
        
        If Item.ItemType = Begin Then
            
            Item = DataCompositionProcessor.Next();
            If Item.ItemType = Begin Then
                
                Item = DataCompositionProcessor.Next();
                If Item.ItemType = BeginAndEnd Then
                
                    Array = New Array;
                    If CurrentRow = Undefined Then
                        OutputStructure.Insert(GroupNames[Item.Template], Array);
                        CurrentRow = OutputTree.Rows.Add();
                    Else
                        CurrentRow.Structure.Insert(GroupNames[Item.Template], Array);
                        CurrentRow = CurrentRow.Rows.Add();
                    EndIf;
                    
                    CurrentRow.Array = Array;
                    
                EndIf;
                
            EndIf;
            
        EndIf;
        
        If CurrentRow <> Undefined Then
            
            If Item.ItemType = End Then
                
                CurrentRow = CurrentRow.Parent;
                
                Item = DataCompositionProcessor.Next();
                If Item.ItemType = End Then
                    CurrentRow = CurrentRow.Parent;
                // ElsIf Not IsBlankString(Item.Template) Then
                    
                    // It is impossible to get here due to structure of output.
                    
                EndIf;
    
            ElsIf Not IsBlankString(Item.Template) Then
                
                Structure = New Structure;
                CurrentRow.Array.Add(Structure);
                CurrentRow = CurrentRow.Rows.Add();
                CurrentRow.Structure = Structure;
                
                ColumnNames = TemplateColumns[Item.Template];
                For Each ColumnName In ColumnNames Do
                    Structure.Insert(ColumnName.Value, Item.ParameterValues[ColumnName.Key].Value);
                EndDo;
                
            EndIf;
            
        EndIf;
        
        Item = DataCompositionProcessor.Next();
        
    EndDo;
    
    For Each KeyAndValue In OutputStructure Do 
        StreamWriter.WritePropertyName(KeyAndValue.Key);
        WriteJSON(StreamWriter, KeyAndValue.Value, , "ConvertFunction", ThisObject);    
    EndDo;
    
    StreamWriter.WriteEndObject();        
    
EndProcedure // BasicFastOutput() 

// Only for internal use.
//
Procedure APISchemaFastOutput(Item, DataCompositionProcessor, 
    TemplateColumns, GroupNames)
    
EndProcedure // APISchemaFastOutput()



// Only for internal use.
//
Procedure FillParamName(GroupNames, TemplateColumns)
    
    // It is needed to verify duplicate property names.
    APISchema.Columns.Add("Listed");
    
    // It is needed to check if a parameter has been listed in the 
    // StreamObject at that level of hierarchy.
    APISchema.Columns.Add("Template", New TypeDescription("String"));
    APISchema.Columns.Add("Parameter", New TypeDescription("String")); 

    // Inverted group cache.
    APIGroupNames = New Map;
    For Each Item In GroupNames Do
        APIGroupNames.Insert(Upper(Item.Value), Item.Key);
    EndDo;  
    
    // Inverted columns cache.
    APITemplateColumns = New Structure;
    For Each Item In TemplateColumns Do
        APIColumnsCache = New Map;
        APITemplateColumns.Insert(Item.Key, APIColumnsCache);
        For Each CItem In Item.Value Do
            APIColumnsCache.Insert(Upper(CItem.Value), CItem.Key);        
        EndDo;
    EndDo; 
    
    FillParamNameRecursively(APISchema.Rows, APIGroupNames, APITemplateColumns);
    
EndProcedure // FillParamName()

// Only for internal use.
//
Procedure FillParamNameRecursively(Rows, APIGroupNames, APITemplateColumns)
    
    For Each Row In Rows Do
        
        HasNestedItems = TypeCanHaveNestedItems(Row.Type);
        If HasNestedItems = True Or Row.Parent = Undefined Then
            
            TemplateItem = APIGroupNames[Upper(Row.Name)]; 
            If ValueIsFilled(TemplateItem) = False Then
                ErrorMessage = StrTemplate(NStr(
                        "en = 'Error: Failed to find grouping in DataCompositionSchema with name: ''%1''.';
                        |ru = 'Ошибка: Не удалось найти группировку в СхемеКомпоновкиДанных с именем: ''%1''.'"),
                    Row.Name);
                Raise ErrorMessage;
            EndIf;
            
            Row.Template = TemplateItem;
            
        Else
            
            TemplateItem = Row.Parent.Template;
            
        EndIf;
        
        
        ColumnItem = APITemplateColumns[TemplateItem][Upper(Row.Name)];
        If ColumnItem = Undefined And HasNestedItems = False Then
            ErrorMessage = StrTemplate(NStr(
                    "en = 'Error: Failed to find field in DataCompositionSchema with name: ''%1'', grouping: ''%2''.';
                    |ru = 'Ошибка: Не удалось найти поле в СхемеКомпоновкиДанных с именем: ''%1'', группировка: ''%2''.'"),
                Row.Name, ?(Row.Parent = Undefined, Row.Name, Row.Parent.Name));
            Raise ErrorMessage;        
        EndIf;
        
        Row.Parameter = ColumnItem;    
            
        If Row.Rows.Count() > 0 Then
            FillParamNameRecursively(Row.Rows, APIGroupNames, 
                APITemplateColumns);        
        EndIf;  
                            
    EndDo;
    
EndProcedure // FillParamNameRecursively()

// Only for internal use.
//
Procedure CheckDublicateProperty(Listed, Name, Group)
    
    If Listed.Get(Name) = Undefined Then
        Listed.Insert(Name, True);    
    Else
        ErrorMessage = StrTemplate(NStr(
                "en = 'SyntaxError: Duplicate property with name: ''%1'', grouping: ''%2''.';
                |ru = 'СинтаксическаяОшибка: Дублируемое свойство с именем: ''%1'', группировка: ''%2''.'"),
            Name, Group);
        Raise ErrorMessage;     
    EndIf;
    
EndProcedure // CheckDublicateProperty()

#EndRegion // ServiceProceduresAndFunctions 

#Region ExternalDataProcessorInfo

// Returns object version.
//
// Returns:
//  String - object version.
//
Function Version() Export
    
    Return "0.5.0.0";
    
EndFunction // Version()

// Returns base object description.
//
// Returns:
//  String - base object description.
//
Function BaseDescription() Export
    
    BaseDescription = NStr("en = 'JSON (%1) format data processor, ver. %2'; 
        |ru = 'Обработчик формата JSON (%1), вер. %2'");
    BaseDescription = StrTemplate(BaseDescription, FormatStandard(), Version());      
    Return BaseDescription;    
    
EndFunction // BaseDescription()

// Returns library guid which is used to identify different implementations 
// of specific format.
//
// Returns:
//  String - library guid. 
//  
Function LibraryGuid() Export
    
    Return "3ca485fe-3fcc-445b-9843-48c5ed370c0f";
    
EndFunction // LibraryGuid()


// Only for internal use.
//
Function ExternalDataProcessorInfo() Export
    
    Version = Version();
    
    Description = BaseDescription();
     
EndFunction // ExternalDataProcessorInfo()

// Only for internal use.
//
Function СведенияОВнешнейОбработке() Export 
    
    // Версия подключаемой функциональности 
    Версия = Version();

    Наименование = BaseDescription();
            
EndFunction // СведенияОВнешнейОбработке()

#EndRegion // ExternalDataProcessorInfo