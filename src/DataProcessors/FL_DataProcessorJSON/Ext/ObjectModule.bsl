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
    RefTypesCache.Insert(Type("String"), False);
    RefTypesCache.Insert(Type("Number"), False);
    RefTypesCache.Insert(Type("Boolean"), False); 
    RefTypesCache.Insert(Type("Undefined"), False);
    
    
    If APISchema <> Undefined Then
        If TypeOf(ThisObject.APISchema) = TypeOf(APISchema) Then    
            ThisObject.APISchema = APISchema.Copy();
        Else
            // Old version schema support could be implemented at this place.
        EndIf;
    EndIf;
    
    StreamWriter = New JSONWriter;
    StreamWriter.ValidateStructure = False;
    If OpenFile <> Undefined Then 
            
    Else
        StreamWriter.SetString();    
    EndIf;
    
EndProcedure // Initialize()


// Completes JSON text writing. If writing to a file, the file is closed. 
// If writing to a string, the resultant string will be returned as the method's return value. 
// If writing to file, the method will return an empty string.
//
// Returns:
//  String - JSON string.
//
Function Close() Export
    Return StreamWriter.Close();   
EndFunction // Close() 

#EndRegion // ProgramInterface

#Region ServiceInterface

// This object can have naming restrictions and this problems should be handled. 
//
// Parameters:
//  Mediator   - Arbitrary - reserved, currently not in use.
//  ReportStructure - Structure - see function FL_DataComposition.NewReportStructure.
//
Procedure VerifyReportStructure(Mediator, ReportStructure) Export
    
    // No naming restrictions.
    
EndProcedure // VerifyReportStructure()

// This object can have naming restrictions and this problems should be handled. 
//
// Parameters:
//  Mediator        - Arbitrary - reserved, currently not in use.
//  TemplateColumns - Structure - see function FL_DataComposition.TemplateColumns.
//
Procedure VerifyColumnNames(Mediator, TemplateColumns) Export
    
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
    
    If APISchema.Rows.Count() = 0 Then
        
        // It is used when API format is not provided.
        BasicOutput(Item, DataCompositionProcessor, 
            ReportStructure.Names, TemplateColumns);
            
    Else

        // It is used when API format is provided.
        APISchemaOutput(Item, DataCompositionProcessor, 
            ReportStructure, TemplateColumns);
            
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
    
    If TypeName = "Object" Or TypeName = "Array" Then
        Return True;
    EndIf;
    
    Return False;
    
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
    //        ElsIf IsBlankString(Item.Template) = False Then
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
    
    Var Level; End = DataCompositionResultItemType.End; Begin = DataCompositionResultItemType.Begin; BeginAndEnd = DataCompositionResultItemType.BeginAndEnd; StreamWriter.WriteStartObject(); While Item <> Undefined Do If Item.ItemType = Begin Then Item = DataCompositionProcessor.Next(); If Item.ItemType = Begin Then Item = DataCompositionProcessor.Next(); If Item.ItemType = BeginAndEnd Then Level = ?(Level = Undefined, 0, Level + 1); StreamWriter.WritePropertyName(GroupNames[Item.Template]); StreamWriter.WriteStartArray(); EndIf; EndIf; EndIf; If Level <> Undefined Then If Item.ItemType = End Then StreamWriter.WriteEndObject(); Item = DataCompositionProcessor.Next(); If Item.ItemType = End Then Level = ?(Level - 1 < 0, Undefined, Level - 1); StreamWriter.WriteEndArray(); EndIf; ElsIf Not IsBlankString(Item.Template) Then ColumnNames = TemplateColumns[Item.Template]; StreamWriter.WriteStartObject(); For Each ColumnName In ColumnNames Do StreamWriter.WritePropertyName(ColumnName.Value); Value = Item.ParameterValues[ColumnName.Key].Value; ValueType = TypeOf(Value); If RefTypesCache[ValueType] = False Then StreamWriter.WriteValue(Value); ElsIf ValueType = Type("Date") Then StreamWriter.WriteValue(WriteJSONDate(Value, JSONDateFormat.ISO)); ElsIf RefTypesCache[ValueType] = True Then StreamWriter.WriteValue(XMLString(Value)); ElsIf FL_CommonUse.IsReference(ValueType) Then RefTypesCache.Insert(ValueType, True); StreamWriter.WriteValue(XMLString(Value)); Else StreamWriter.WriteValue(Undefined); EndIf; EndDo; EndIf; EndIf; Item = DataCompositionProcessor.Next(); EndDo; StreamWriter.WriteEndObject();  
    
EndProcedure // BasicOutput() 

// Only for internal use.
//
Procedure APISchemaOutput(Item, DataCompositionProcessor, 
    ReportStructure, TemplateColumns)
    
    Raise NStr("en = 'To use this option you need the FoxyLink Pro. 
        |FoxyLink Pro is a set of extension packages, that are available under 
        |paid subscriptions. After purchase, you receive binaries and access 
        |to the private repository.';
        |ru = 'Для использования этой опции вам нужен FoxyLink Pro.
        |FoxyLink Pro представляет собой набор пакетов расширения, доступных 
        |под платной подпиской. После покупки вы получаете двоичные файлы и 
        |доступ к частному репозиторию.'");
    
EndProcedure // APISchemaOutput()

#EndRegion // ServiceProceduresAndFunctions 

#Region ExternalDataProcessorInfo

// Returns object version.
//
// Returns:
//  String - object version.
//
Function Version() Export
    
    Return "1.0.0.0";
    
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
    
    Return False;
     
EndFunction // ExternalDataProcessorInfo()

// Only for internal use.
//
Function СведенияОВнешнейОбработке() Export 
    
    // Версия подключаемой функциональности 
    Версия = Version();

    Наименование = BaseDescription();
    
    Return False;
    
EndFunction // СведенияОВнешнейОбработке()

#EndRegion // ExternalDataProcessorInfo

#EndIf