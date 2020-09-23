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

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region VariablesDescription

Var RefTypesCache; // Types cache for ConvertFunction.
Var StreamWriter; // It is used to write JSON objects and texts. 

#EndRegion // VariablesDescription

#Region FormatDescription

// Number of the formal document from the Internet Engineering Task Force 
// (IETF) that is the result of committee drafting and subsequent review 
// by interested parties.
//
// Returns:
//  String - format standard.
//
Function FormatStandard() Export
    
    Return "RFC 7159";
    
EndFunction // FormatStandard()

// Returns link to the formal document from the Internet Engineering Task Force 
// (IETF) that is the result of committee drafting and subsequent review 
// by interested parties.
//
// Returns:
//  String - format standard link.
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

#EndRegion // FormatDescription

#Region ProgramInterface

// Completes JSON text writing. 
//
Procedure Close() Export
    
    StreamWriter.Close();
    
EndProcedure // Close() 

// Constructor of stream object.
//
// Parameters:
//  Stream    - Stream       - a data stream that can be read successively 
//                              or/and where you can record successively. 
//            - MemoryStream - specialized version of Stream object for 
//                              operation with the data located in the RAM.
//            - FileStream   - specialized version of Stream object for 
//                              operation with the data located in a file on disk.
//  APISchema - Arbitrary    - user defined API schema.
//                  Default value: Undefined.
//
Procedure Initialize(Stream, APISchema = Undefined) Export
    
    // Clear cache.
    ContentEncoding = "UTF-8";
    ThisObject.APISchema.Rows.Clear();
    
    RefTypesCache = New Map;
    RefTypesCache.Insert(Type("String"), False);
    RefTypesCache.Insert(Type("Number"), False);
    RefTypesCache.Insert(Type("Boolean"), False); 
    RefTypesCache.Insert(Type("Undefined"), False);
    
    If APISchema <> Undefined Then
        If TypeOf(ThisObject.APISchema) = TypeOf(APISchema) Then    
            ThisObject.APISchema = APISchema.Copy();
        // Else
            // Old version schema support could be implemented at this place.
        EndIf;
    EndIf;
    
    StreamWriter = New JSONWriter;
    StreamWriter.ValidateStructure = False;
    StreamWriter.OpenStream(Stream, ContentEncoding);
    
EndProcedure // Initialize()

// The function reads the value from the invocation payload. 
//
// Parameters:
//  Invocation           - Structure - see function Catalogs.FL_Messages.NewInvocation
//  AdditionalParameters - Structure - additional parameters for format translation.
//                              Default value: Undefined.
// Returns:
//  Arbitrary - a value read from the invocation payload. 
// 
Function ReadFormat(Invocation, AdditionalParameters) Export
    
    ReadToMap = True;
    PropertiesWithDateValuesNames = Undefined;
    ExpectedDateFormat = JSONDateFormat.ISO;
    ReviverFunctionName = Undefined;
    ReviverFunctionModule = Undefined;
    ReviverFunctionAdditionalParameters = Undefined;
    RetriverPropertiesNames = Undefined;
    
    Payload = Invocation.Payload;
    If TypeOf(Payload) <> Type("BinaryData") Then
        Return Undefined;    
    EndIf;
    
    If TypeOf(AdditionalParameters) = Type("Structure") Then
        
        If AdditionalParameters.Property("ReadToMap") Then
            ReadToMap = AdditionalParameters.ReadToMap;           
        EndIf;
        
        AdditionalParameters.Property("PropertiesWithDateValuesNames", 
            PropertiesWithDateValuesNames);
            
        If AdditionalParameters.Property("ExpectedDateFormat") 
            AND TypeOf(AdditionalParameters.ExpectedDateFormat) = Type("JSONDateFormat") Then
            ExpectedDateFormat = AdditionalParameters.ExpectedDateFormat;    
            
        EndIf;
            
        AdditionalParameters.Property("ReviverFunctionName", 
            ReviverFunctionName);
        AdditionalParameters.Property("ReviverFunctionModule", 
            ReviverFunctionModule);
        AdditionalParameters.Property("ReviverFunctionAdditionalParameters", 
            ReviverFunctionAdditionalParameters);
        AdditionalParameters.Property("RetriverPropertiesNames", 
            RetriverPropertiesNames);
        
    EndIf;
    
    JSONReader = New JSONReader;    
    JSONReader.OpenStream(Payload.OpenStreamForRead());
    Return ReadJSON(JSONReader, 
        ReadToMap, 
        PropertiesWithDateValuesNames,
        ExpectedDateFormat,
        ReviverFunctionName,
        ReviverFunctionModule,
        ReviverFunctionAdditionalParameters,
        RetriverPropertiesNames);
    
EndFunction // ReadFormat()

#EndRegion // ProgramInterface

#Region ServiceInterface

// This object can have naming restrictions and this problems should be handled. 
//
// Parameters:
//  ReportStructure - Structure - see function FL_DataComposition.NewReportStructure.
//
Procedure VerifyReportStructure(ReportStructure) Export
    
    // No naming restrictions.
    
EndProcedure // VerifyReportStructure()

// This object can have naming restrictions and this problems should be handled. 
//
// Parameters:
//  TemplateColumns - Structure - see function FL_DataComposition.TemplateColumns.
//
Procedure VerifyColumnNames(TemplateColumns) Export
    
    // No naming restrictions.
    
EndProcedure // VerifyColumnNames()

// Outputs sequentially result of the data composition shema into stream object.
//
// Parameters:
//  Item            - DataCompositionResultItem         - a data composition result item.
//  DataCompositionProcessor - DataCompositionProcessor - object that performs data composition.
//  ReportStructure - Structure - see function FL_DataComposition.NewReportStructure.
//  TemplateColumns - Structure - see function FL_DataComposition.TemplateColumns.
//
Procedure Output(Item, DataCompositionProcessor, ReportStructure, 
    TemplateColumns) Export
    
    If ValueIsFilled(APISchema.Rows) Then
        
        // It is used when API format is provided.
        APISchemaOutput(Item, DataCompositionProcessor, 
            ReportStructure, TemplateColumns);
            
    Else

        // It is used when API format is not provided.
        BasicOutput(Item, DataCompositionProcessor, 
            ReportStructure.Names, TemplateColumns);   
            
    EndIf;
        
EndProcedure // Output()

// Returns JSON types represented by four primitive types (String, Number, 
// Boolean and Null) and two structured types (Object and Array).
//
// Returns:
//  ValueList - JSON types.
//      * String - JSON type name.
//
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

// Checks if the type is a structured type.
//
// Parameters:
//  TypeName - String - type name.
//
// Returns:
//  Boolean - True if this type is a structured type; False in other case.
//
Function IsStructuredType(TypeName) Export
    
    Return TypeName = "Object" Or TypeName = "Array";
    
EndFunction // IsStructuredType()

#EndRegion // ServiceInterface

#Region ServiceProceduresAndFunctions

// Only for internal use.
// 
Procedure BasicOutput(Item, DataCompositionProcessor, 
    GroupNames, TemplateColumns)
    
    // The code in the comment written in one line is below this comment.
    // To edit the code, remove the comment.
    // For more information about the code in 1 line see http://infostart.ru/public/71130/.
    //
    //Var Level; 
    //
    //End = DataCompositionResultItemType.End;
    //Begin = DataCompositionResultItemType.Begin;
    //BeginAndEnd = DataCompositionResultItemType.BeginAndEnd;
    //
    //StreamWriter.WriteStartObject();
    //
    //While Item <> Undefined Do
    //    
    //    If Item.ItemType = Begin Then
    //        
    //        Item = DataCompositionProcessor.Next();
    //        If Item.ItemType = Begin Then
    //            
    //            Item = DataCompositionProcessor.Next();
    //            If Item.ItemType = BeginAndEnd Then
    //               
    //                // It works better for complicated hierarchy.
    //                Level = ?(Level = Undefined, 0, Level + 1);
    //                
    //                StreamWriter.WritePropertyName(GroupNames[Item.Template]);
    //                StreamWriter.WriteStartArray();
    //                
    //            EndIf;
    //            
    //        EndIf;
    //        
    //    EndIf;
    //    
    //    If Level <> Undefined Then
    //        
    //        If Item.ItemType = End Then
    //            
    //            StreamWriter.WriteEndObject();
    //            
    //            Item = DataCompositionProcessor.Next();
    //            If Item.ItemType = End Then
    //                
    //                // It works better for complicated hierarchy.
    //                Level = ?(Level - 1 < 0, Undefined, Level - 1);
    //                
    //                StreamWriter.WriteEndArray();
    //                
    //            // ElsIf Not IsBlankString(Item.Template) Then
    //                
    //                // It is impossible to get here due to structure of output.
    //                
    //            EndIf;
    //            
    //        ElsIf NOT IsBlankString(Item.Template) Then
    //            
    //            ColumnNames = TemplateColumns[Item.Template];
    //            
    //            StreamWriter.WriteStartObject();
    //           
    //            For Each ColumnName In ColumnNames Do
    //                
    //                StreamWriter.WritePropertyName(ColumnName.Value);
    //                Value = Item.ParameterValues[ColumnName.Key].Value;
    //                ValueType = TypeOf(Value);
    // 
    //                If RefTypesCache[ValueType] = False Then
    //                    StreamWriter.WriteValue(Value);
    //                ElsIf ValueType = Type("Date") Then
    //                    StreamWriter.WriteValue(WriteJSONDate(Value, JSONDateFormat.ISO));    
    //                ElsIf RefTypesCache[ValueType] = True Then
    //                    StreamWriter.WriteValue(XMLString(Value));
    //                // Possible improvement: skip non-ValueType.
    //                ElsIf FL_CommonUse.IsReference(ValueType) Then
    //                    RefTypesCache.Insert(ValueType, True);
    //                    StreamWriter.WriteValue(XMLString(Value));         
    //                Else
    //                    StreamWriter.WriteValue(Undefined);              
    //                EndIf;
    //                
    //            EndDo;
    //            
    //        EndIf;
    //        
    //    EndIf;
    //    
    //    Item = DataCompositionProcessor.Next();
    //    
    //EndDo;
    //
    //StreamWriter.WriteEndObject();        
    
    Var Level; End = DataCompositionResultItemType.End; Begin = DataCompositionResultItemType.Begin; BeginAndEnd = DataCompositionResultItemType.BeginAndEnd; StreamWriter.WriteStartObject(); While Item <> Undefined Do If Item.ItemType = Begin Then Item = DataCompositionProcessor.Next(); If Item.ItemType = Begin Then Item = DataCompositionProcessor.Next(); If Item.ItemType = BeginAndEnd Then Level = ?(Level = Undefined, 0, Level + 1); StreamWriter.WritePropertyName(GroupNames[Item.Template]); StreamWriter.WriteStartArray(); EndIf; EndIf; EndIf; If Level <> Undefined Then If Item.ItemType = End Then StreamWriter.WriteEndObject(); Item = DataCompositionProcessor.Next(); If Item.ItemType = End Then Level = ?(Level - 1 < 0, Undefined, Level - 1); StreamWriter.WriteEndArray(); EndIf; ElsIf NOT IsBlankString(Item.Template) Then ColumnNames = TemplateColumns[Item.Template]; StreamWriter.WriteStartObject(); For Each ColumnName In ColumnNames Do StreamWriter.WritePropertyName(ColumnName.Value); Value = Item.ParameterValues[ColumnName.Key].Value; ValueType = TypeOf(Value); If RefTypesCache[ValueType] = False Then StreamWriter.WriteValue(Value); ElsIf ValueType = Type("Date") Then StreamWriter.WriteValue(WriteJSONDate(Value, JSONDateFormat.ISO)); ElsIf RefTypesCache[ValueType] = True Then StreamWriter.WriteValue(XMLString(Value)); ElsIf FL_CommonUse.IsReference(ValueType) Then RefTypesCache.Insert(ValueType, True); StreamWriter.WriteValue(XMLString(Value)); Else StreamWriter.WriteValue(Undefined); EndIf; EndDo; EndIf; EndIf; Item = DataCompositionProcessor.Next(); EndDo; StreamWriter.WriteEndObject();  
    
EndProcedure // BasicOutput() 

// Only for internal use.
//
Procedure APISchemaOutput(Item, DataCompositionProcessor, 
    ReportStructure, TemplateColumns)
    
    // The code in the comment written in one line is below this comment.
    // To edit the code, remove the comment.
    // For more information about the code in 1 line see http://infostart.ru/public/71130/.
    // 
    //FillParamName(ReportStructure, TemplateColumns);
    //TypeDate = Type("Date");
    //
    //CurrentLevel = APISchema.Rows[0];
    //If CurrentLevel.Type = "Object" Then
    //    StreamWriter.WriteStartObject();
    //ElsIf CurrentLevel.Type = "Array" Then
    //    StreamWriter.WriteStartArray();
    //EndIf;                   
    //
    //While Item <> Undefined Do
    //    
    //    If NOT IsBlankString(Item.Template) Then
    //        
    //        If CurrentLevel = Undefined Then    
    //            ErrorMessage = StrTemplate(NStr("en='Error: Failed to find property with name: {%1}.';
    //                    |ru='Ошибка: Не удалось найти свойство с именем: {%1}.';
    //                    |en_CA='Error: Failed to find property with name: {%1}.'"),
    //                ReportStructure.Names[Item.Template]);
    //            Raise ErrorMessage;
    //        EndIf;
    //        
    //        If CurrentLevel.Template <> Item.Template Then
    //            
    //            DownLevel = CurrentLevel.Rows.Find(Item.Template, "Template", True);
    //            If DownLevel <> Undefined Then
    //                CertainlyOpenArrObj(CurrentLevel, DownLevel);    
    //            Else
    //                CertainlyCloseArrObj(CurrentLevel);
    //                Continue;                      
    //            EndIf;
    //            
    //        EndIf;
    //                                                                                      
    //       If CurrentLevel.StructuredType Then 
    //           
    //           For Each Row In CurrentLevel.Rows Do
    //               
    //               If Row.StructuredType Then
    //                   Continue;
    //               EndIf;
    //               
    //               If CurrentLevel.Type <> "Array" Then
    //                   StreamWriter.WritePropertyName(Row.Name);
    //               EndIf;
    //                
    //               Value = Item.ParameterValues[Row.Parameter].Value;
    //               ValueType = TypeOf(Value);
    //
    //               If RefTypesCache[ValueType] = False Then
    //                   StreamWriter.WriteValue(Value);
    //               ElsIf ValueType = TypeDate Then
    //                   StreamWriter.WriteValue(WriteJSONDate(Value, JSONDateFormat.ISO));    
    //               ElsIf RefTypesCache[ValueType] = True Then
    //                   StreamWriter.WriteValue(XMLString(Value));
    //               // Possible improvement: skip non-ValueType.
    //               ElsIf FL_CommonUse.IsReference(ValueType) 
    //                   OR ValueType = Type("UUID")Then
    //                   RefTypesCache.Insert(ValueType, True);
    //                   StreamWriter.WriteValue(XMLString(Value));         
    //               Else
    //                   StreamWriter.WriteValue(Undefined);              
    //               EndIf;
    //               
    //               Row.Done = True;
    //                                           
    //           EndDo;
    //           
    //           If CurrentLevel.Type = "Object" 
    //               AND CurrentLevel.Rows.Find(False, "Done") = Undefined Then
    //               CertainlyCloseArrObj(CurrentLevel);
    //           EndIf;
    //           
    //       Else
    //                                    
    //            Value = Item.ParameterValues[CurrentLevel.Parameter].Value;
    //            ValueType = TypeOf(Value);
    //
    //            If RefTypesCache[ValueType] = False Then
    //                StreamWriter.WriteValue(Value);
    //            ElsIf ValueType = TypeDate Then
    //                StreamWriter.WriteValue(WriteJSONDate(Value, JSONDateFormat.ISO));    
    //            ElsIf RefTypesCache[ValueType] = True Then
    //                StreamWriter.WriteValue(XMLString(Value));
    //            // Possible improvement: skip non-ValueType.
    //        ElsIf FL_CommonUse.IsReference(ValueType) 
    //            OR ValueType = Type("UUID") Then
    //                RefTypesCache.Insert(ValueType, True);
    //                StreamWriter.WriteValue(XMLString(Value));         
    //            Else
    //                StreamWriter.WriteValue(Undefined);              
    //            EndIf;
    //            
    //        EndIf;
    //                                  
    //    EndIf;
    //    
    //    Item = DataCompositionProcessor.Next();
    //    
    //EndDo;
    //
    //While CurrentLevel <> Undefined Do
    //    CertainlyCloseArrObj(CurrentLevel);
    //EndDo;
    
    FillParamName(ReportStructure, TemplateColumns); TypeDate = Type("Date"); CurrentLevel = APISchema.Rows[0]; If CurrentLevel.Type = "Object" Then StreamWriter.WriteStartObject(); ElsIf CurrentLevel.Type = "Array" Then StreamWriter.WriteStartArray(); EndIf; While Item <> Undefined Do If NOT IsBlankString(Item.Template) Then If CurrentLevel = Undefined Then ErrorMessage = StrTemplate(NStr("en='Error: Failed to find property with name: {%1}.';ru='Ошибка: Не удалось найти свойство с именем: {%1}.'; en_CA='Error: Failed to find property with name: {%1}.'"), ReportStructure.Names[Item.Template]); Raise ErrorMessage; EndIf; If CurrentLevel.Template <> Item.Template Then DownLevel = CurrentLevel.Rows.Find(Item.Template, "Template", True); If DownLevel <> Undefined Then CertainlyOpenArrObj(CurrentLevel, DownLevel); Else CertainlyCloseArrObj(CurrentLevel); Continue; EndIf; EndIf; If CurrentLevel.StructuredType Then For Each Row In CurrentLevel.Rows Do If Row.StructuredType Then Continue; EndIf; If CurrentLevel.Type <> "Array" Then StreamWriter.WritePropertyName(Row.Name); EndIf; Value = Item.ParameterValues[Row.Parameter].Value; ValueType = TypeOf(Value); If RefTypesCache[ValueType] = False Then StreamWriter.WriteValue(Value); ElsIf ValueType = TypeDate Then StreamWriter.WriteValue(WriteJSONDate(Value, JSONDateFormat.ISO)); ElsIf RefTypesCache[ValueType] = True Then StreamWriter.WriteValue(XMLString(Value)); ElsIf FL_CommonUse.IsReference(ValueType) OR ValueType = Type("UUID")Then RefTypesCache.Insert(ValueType, True); StreamWriter.WriteValue(XMLString(Value)); Else StreamWriter.WriteValue(Undefined); EndIf; Row.Done = True; EndDo; If CurrentLevel.Type = "Object" AND CurrentLevel.Rows.Find(False, "Done") = Undefined Then CertainlyCloseArrObj(CurrentLevel); EndIf; Else Value = Item.ParameterValues[CurrentLevel.Parameter].Value; ValueType = TypeOf(Value); If RefTypesCache[ValueType] = False Then StreamWriter.WriteValue(Value); ElsIf ValueType = TypeDate Then StreamWriter.WriteValue(WriteJSONDate(Value, JSONDateFormat.ISO)); ElsIf RefTypesCache[ValueType] = True Then StreamWriter.WriteValue(XMLString(Value)); ElsIf FL_CommonUse.IsReference(ValueType) OR ValueType = Type("UUID") Then RefTypesCache.Insert(ValueType, True); StreamWriter.WriteValue(XMLString(Value)); Else StreamWriter.WriteValue(Undefined); EndIf; EndIf; EndIf; Item = DataCompositionProcessor.Next(); EndDo; While CurrentLevel <> Undefined Do CertainlyCloseArrObj(CurrentLevel); EndDo;
 
EndProcedure // APISchemaOutput()

// Only for internal use.
//
Procedure CertainlyOpenArrObj(CurrentLevel, DownLevel)
    
    // The code in the comment written in one line is below this comment.
    // To edit the code, remove the comment.
    // For more information about the code in 1 line see http://infostart.ru/public/71130/.
    //
    //Pointer = DownLevel;
    //Pointers = New Array;
    //While CurrentLevel <> Pointer Do
    //    Pointers.Insert(0, Pointer);
    //    Pointer = Pointer.Parent;
    //EndDo;
    //
    //CurrentLevel = DownLevel;
    //For Each Rows In CurrentLevel.Rows Do
    //    Rows.Done = False;   
    //EndDo;
    //
    //For Each Pointer In Pointers Do
    //    
    //    If Pointer.Parent.Type = "Object" Then
    //        StreamWriter.WritePropertyName(Pointer.Name);    
    //    EndIf;
    //    
    //    If Pointer.Type = "Object" Then
    //        StreamWriter.WriteStartObject();    
    //    Else
    //        StreamWriter.WriteStartArray();       
    //    EndIf;
    //    
    //EndDo;
    
    Pointer = DownLevel; Pointers = New Array; While CurrentLevel <> Pointer Do Pointers.Insert(0, Pointer); Pointer = Pointer.Parent; EndDo; CurrentLevel = DownLevel; For Each Rows In CurrentLevel.Rows Do Rows.Done = False; EndDo; For Each Pointer In Pointers Do If Pointer.Parent.Type = "Object" Then StreamWriter.WritePropertyName(Pointer.Name); EndIf; If Pointer.Type = "Object" Then StreamWriter.WriteStartObject(); Else StreamWriter.WriteStartArray(); EndIf; EndDo;
    
EndProcedure // CertainlyOpenArrObj()

// Only for internal use.
//
Procedure CertainlyCloseArrObj(Row)
    
    // The code in the comment written in one line is below this comment.
    // To edit the code, remove the comment.
    // For more information about the code in 1 line see http://infostart.ru/public/71130/.
    //
    //If Row.Type = "Object" Then
    //   StreamWriter.WriteEndObject();
    //ElsIf Row.Type = "Array" Then
    //    StreamWriter.WriteEndArray();
    //EndIf;
    //
    //Row.Done = True;
    //Row = Row.Parent;
    
    If Row.Type = "Object" Then StreamWriter.WriteEndObject(); ElsIf Row.Type = "Array" Then StreamWriter.WriteEndArray(); EndIf; Row.Done = True; Row = Row.Parent;
    
EndProcedure // CertainlyCloseArrObj() 

// Only for internal use.
//
Procedure FillParamName(ReportStructure, TemplateColumns)
    
    MaxLengthOfAreaName = 13;
    
    Hierarchy = ReportStructure.Hierarchy;
    
    // It is needed to verify duplicate property names.
    // APISchema.Columns.Add("Listed");
    
    // It is needed to check if a parameter has been listed in the 
    // StreamObject at that level of hierarchy.
    APISchema.Columns.Add("Done", New TypeDescription("Boolean"));
    APISchema.Columns.Add("Template", FL_CommonUse.StringTypeDescription(
        MaxLengthOfAreaName));
    APISchema.Columns.Add("Parameter", New TypeDescription("String"));
        
    // Inverted columns cache.
    APITemplateColumns = New Structure;
    For Each Item In TemplateColumns Do
        APIColumnsCache = New Map;
        APITemplateColumns.Insert(Item.Key, APIColumnsCache);
        For Each CItem In Item.Value Do
            APIColumnsCache.Insert(Upper(CItem.Value), CItem.Key);        
        EndDo;
    EndDo; 
    
    FillParamNameRecursively(APISchema.Rows, Hierarchy, APITemplateColumns);
    
EndProcedure // FillParamName()

// Only for internal use.
//
Procedure FillParamNameRecursively(Rows, Hierarchy, APITemplateColumns)
    
    // The code in the comment written in one line is below this comment.
    // To edit the code, remove the comment.
    // For more information about the code in 1 line see http://infostart.ru/public/71130/.
    //
    //Var NestedHierarchy;
    //
    //Shift = 0;
    //RowsCount = Rows.Count() - 1;
    //For Index = 0 To RowsCount Do
    //    
    //    Row = Rows[Index - Shift];
    //    If Row.TurnedOff = 1 Then 
    //        Rows.Delete(Row);
    //        Shift = Shift + 1;
    //        Continue;
    //    EndIf;
    //    
    //    If Row.Parent = Undefined Then
    //        If ValueIsFilled(Row.Rows) Then
    //            FillParamNameRecursively(Row.Rows, Hierarchy, 
    //                APITemplateColumns);    
    //        Else
    //            FillTemplateName(Row, Hierarchy);
    //            FillParameterName(Row, APITemplateColumns);
    //        EndIf;           
    //    Else 
    //        If NOT Row.StructuredType Then
    //            RowParent = Row.Parent;
    //            If IsBlankString(RowParent.Template) Then
    //                FillTemplateName(RowParent, Hierarchy);
    //            EndIf;
    //            Row.Template = RowParent.Template;
    //            FillParameterName(Row, APITemplateColumns); 
    //        Else
    //            FillTemplateName(Row, Hierarchy, NestedHierarchy);
    //            If ValueIsFilled(Row.Rows) Then
    //                FillParamNameRecursively(Row.Rows, NestedHierarchy, 
    //                    APITemplateColumns);        
    //            EndIf;    
    //        EndIf;  
    //    EndIf;
    //            
    //EndDo;
    
    Var NestedHierarchy; Shift = 0; RowsCount = Rows.Count() - 1; For Index = 0 To RowsCount Do Row = Rows[Index - Shift]; If Row.TurnedOff = 1 Then Rows.Delete(Row);Shift = Shift + 1; Continue; EndIf; If Row.Parent = Undefined Then If ValueIsFilled(Row.Rows) Then FillParamNameRecursively(Row.Rows, Hierarchy, APITemplateColumns); Else FillTemplateName(Row, Hierarchy); FillParameterName(Row, APITemplateColumns); EndIf; Else If NOT Row.StructuredType Then RowParent = Row.Parent; If IsBlankString(RowParent.Template) Then FillTemplateName(RowParent, Hierarchy); EndIf; Row.Template = RowParent.Template; FillParameterName(Row, APITemplateColumns); Else FillTemplateName(Row, Hierarchy, NestedHierarchy); If ValueIsFilled(Row.Rows) Then FillParamNameRecursively(Row.Rows, NestedHierarchy, APITemplateColumns); EndIf; EndIf; EndIf; EndDo;
    
EndProcedure // FillParamNameRecursively()

// Only for internal use.
//
Procedure FillTemplateName(Row, Hierarchy, NestedHierarchy = Undefined)
    
    // The code in the comment written in one line is below this comment.
    // To edit the code, remove the comment.
    // For more information about the code in 1 line see http://infostart.ru/public/71130/.
    //
    //NestedHierarchy = Hierarchy.Rows.Find(Row.Name, "Name");
    //If NestedHierarchy <> Undefined Then
    //    Row.Template = NestedHierarchy.Template;    
    //Else
    //    ErrorMessage = NStr("en='Error: Failed to find grouping in the report structure with name: {%1}.';
    //        |ru='Ошибка: Не удалось найти группировку в структуре отчета с именем: {%1}.';
    //        |uk='Помилка: Не вдалось знайти груповання в структурі звіту з іменем: {%1}.';
    //        |en_CA='Error: Failed to find grouping in the report structure with name: {%1}.'");
    //    Raise StrTemplate(ErrorMessage, Row.Name);    
    //EndIf;
    
    NestedHierarchy = Hierarchy.Rows.Find(Row.Name, "Name"); If NestedHierarchy <> Undefined Then Row.Template = NestedHierarchy.Template; Else ErrorMessage = NStr("en='Error: Failed to find grouping in the report structure with name: {%1}.';ru='Ошибка: Не удалось найти группировку в структуре отчета с именем: {%1}.';uk='Помилка: Не вдалось знайти груповання в структурі звіту з іменем: {%1}.';en_CA='Error: Failed to find grouping in the report structure with name: {%1}.'"); Raise StrTemplate(ErrorMessage, Row.Name); EndIf;
        
EndProcedure // FillTemplateName()

// Only for internal use.
//
Procedure FillParameterName(Row, TemplateColumns)
    
    // The code in the comment written in one line is below this comment.
    // To edit the code, remove the comment.
    // For more information about the code in 1 line see http://infostart.ru/public/71130/.
    //
    //ColumnItem = TemplateColumns[Row.Template][Upper(Row.Name)];
    //If ColumnItem = Undefined AND NOT Row.StructuredType Then
    //    ErrorMessage = NStr("en='Error: Failed to find field in report structure with name: {%1}, grouping: {%2}.';
    //        |ru='Ошибка: Не удалось найти поле в структуре отчета с именем: {%1}, группировка: {%2}.';
    //        |uk='Помилка: Не вдалось знайти поле в структурі звіту з іменем: {%1}, групування: {%2}.';
    //        |en_CA='Error: Failed to find field in report structure with name: {%1}, grouping: {%2}.'");
    //    Raise StrTemplate(ErrorMessage, Row.Name, ?(Row.Parent = Undefined, Row.Name, Row.Parent.Name));        
    //EndIf;
    //
    //Row.Parameter = ColumnItem;
    
    ColumnItem = TemplateColumns[Row.Template][Upper(Row.Name)]; If ColumnItem = Undefined AND NOT Row.StructuredType Then ErrorMessage = NStr("en='Error: Failed to find field in report structure with name: {%1}, grouping: {%2}.';ru='Ошибка: Не удалось найти поле в структуре отчета с именем: {%1}, группировка: {%2}.';uk='Помилка: Не вдалось знайти поле в структурі звіту з іменем: {%1}, групування: {%2}.';en_CA='Error: Failed to find field in report structure with name: {%1}, grouping: {%2}.'"); Raise StrTemplate(ErrorMessage, Row.Name, ?(Row.Parent = Undefined, Row.Name, Row.Parent.Name)); EndIf; Row.Parameter = ColumnItem;
    
EndProcedure // FillParameterName()

// Only for internal use.
//
Procedure CheckDublicateProperty(Listed, Name, Group)
    
    If Listed.Get(Name) = Undefined Then
        Listed.Insert(Name, True);    
    Else
        ErrorMessage = NStr("en='SyntaxError: Duplicate property with name: {%1}, grouping: {%2}.';
            |ru='СинтаксическаяОшибка: Дублирующее свойство с именем: {%1}, группировка: {%2}.';
            |uk='СинтаксичнаПомилка: Дублювана властивість з іменем: {%1}, групування: {%2}.';
            |en_CA='SyntaxError: Duplicate property with name: {%1}, grouping: {%2}.'");
        Raise StrTemplate(ErrorMessage, Name, Group);     
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
    
    Return "1.0.6";
    
EndFunction // Version()

// Returns base object description.
//
// Returns:
//  String - base object description.
//
Function BaseDescription() Export
    
    BaseDescription = NStr("en='JSON (%1) format data processor, ver. %2';
        |ru='Обработчик формата JSON (%1), вер. %2';
        |uk='Обробник формату JSON (%1), вер. %2';
        |en_CA='JSON (%1) format data processor, ver. %2'");
    Return StrTemplate(BaseDescription, FormatStandard(), Version());   
    
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

#EndRegion // ExternalDataProcessorInfo

#EndIf