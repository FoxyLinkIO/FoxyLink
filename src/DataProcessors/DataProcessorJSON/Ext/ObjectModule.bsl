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

Var RefTypesCache;
Var StreamWriter;

#Region FormatDescription

// Number of the formal document from the Internet Engineering Task Force 
// (IETF) that is the result of committee drafting and subsequent review 
// by interested parties.
//
Function FormatStandard() Export
    
    Return "RFC7159";
    
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


//Function PrimitiveTypes() Export
//    
//    PTypes = New Map;
//    PTypes.Insert("string", Type("String"));
//    PTypes.Insert("number", Type("Number"));
//    PTypes.Insert("boolean",Type("Boolean"));
//    PTypes.Insert("null",   Type("Undefined"));
//    Return PTypes;
//    
//EndFunction // PrimitiveTypes()

//Function StructuredTypes() Export
//    
//    STypes = New Map;
//    STypes.Insert("object",Type("Map"));
//    STypes.Insert("array", Type("Array"));
//    Return STypes;
//    
//EndFunction // StructuredTypes()

#EndRegion // FormatDescription

#Region ProgramInterface

// Constructor of stream object.
//
// Parameters:
//  OpenFile - String - output filename.
//             Default value: Empty string.
//
Procedure Initialize(OpenFile = "") Export
    
    RefTypesCache = New Map;
    
    StreamWriter = New JSONWriter;
    If IsBlankString(OpenFile) Then 
        StreamWriter.SetString();
    Else
        
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

//Records the end of a JSON object.
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
    
    Var Level; 

    End = DataCompositionResultItemType.End;
    Begin = DataCompositionResultItemType.Begin;
    BeginAndEnd = DataCompositionResultItemType.BeginAndEnd;
    
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
    
    Var CurrentRow;
    
    OutputTree = New ValueTree;
    OutputTree.Columns.Add("Array");
    OutputTree.Columns.Add("Structure");
    
    OutputStructure = New Structure;
    
    End = DataCompositionResultItemType.End;
    Begin = DataCompositionResultItemType.Begin;
    BeginAndEnd = DataCompositionResultItemType.BeginAndEnd;
    
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

#Region ExternalDataProcessorInfo

Function Version() Export
    
    Return "0.5.0.0";
    
EndFunction // Version()

Function BaseDescription() Export
    
    BaseDescription = NStr("en = 'JSON (%1) format data processor, ver. %2'; 
        |ru = 'Обработчик формата JSON (%1), вер. %2'");
    BaseDescription = StrTemplate(BaseDescription, FormatStandard(), Version());      
    Return BaseDescription;    
    
EndFunction // BaseDescription()

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