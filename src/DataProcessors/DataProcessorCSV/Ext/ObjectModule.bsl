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

Var RefTypesCache;
Var StreamWriter;

#Region FormatDescription

// Number of the formal document from the Internet Engineering Task Force 
// (IETF) that is the result of committee drafting and subsequent review 
// by interested parties.
//
Function FormatStandard() Export
    
    Return "RFC 4180";
    
EndFunction // FormatStandard()

// Returns link to the formal document from the Internet Engineering Task Force 
// (IETF) that is the result of committee drafting and subsequent review 
// by interested parties.
//
Function FormatStandardLink() Export
    
    Return "https://tools.ietf.org/html/rfc4180";
    
EndFunction // FormatStandardLink()

// Returns short format name.
//
// Returns:
//  String - format short name.
// 
Function FormatShortName() Export
    
    Return "CSV";    
    
EndFunction // FormatShortName()

// Returns full format name.
//
// Returns:
//  String - format full name.
//
Function FormatFullName() Export
    
    Return "Comma-separated values";    
    
EndFunction // FormatFullName()

// Returns format file extension.
//
// Returns:
//  String - file extension.
//
Function FormatFileExtension() Export
    
    Return ".csv";
    
EndFunction // FormatFileExtension()

// Returns format media type.
//
// Returns:
//  String - format media type.
//
Function FormatMediaType() Export
    
    Return "text/csv";
    
EndFunction // FormatMediaType()




//Function SupportedTypes() Export
//    
//    ValueList = New ValueList();
//    ValueList.Add("String");
//    ValueList.Add("Number");
//    ValueList.Add("Boolean");
//    ValueList.Add("Null");
//    ValueList.Add("Object");
//    ValueList.Add("Array");
//    Return ValueList;
//    
//EndFunction // SupportedTypes()

//// Check if a type can have nested items.
////
//// Parameters:
////  TypeName  - String - type name.
////
//// Returns:
////   Boolean - True if this type can have nested items; False in other case.
////
//Function TypeCanHaveNestedItems(TypeName) Export
//    
//    If TypeName = "Object" Or TypeName = "Array" Then
//        Return True;
//    EndIf;
//    
//    Return False;
//    
//EndFunction // TypeCanHaveNestedItems()

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
    
EndProcedure // Initialize()

#EndRegion // ProgramInterface

#Region ServiceProgramInterface

// Outputs sequentially result of the data composition shema into stream object.
//
// Parameters:
//  Item            - DataCompositionResultItem         - a data composition result item.
//  DataCompositionProcessor - DataCompositionProcessor - object that performs data composition.
//  TemplateColumns - Structure - see function IHLDataComposition.TemplateColumns.
//  GroupNames      - Structure - see function IHLDataComposition.GroupNames.
//
Procedure MemorySavingOutput(Item, DataCompositionProcessor, TemplateColumns, 
    GroupNames) Export
    
EndProcedure // MemorySavingOutput()

// Outputs fast result of the data composition shema into stream object.
// 
// Note:
//  Additional memory in use.
//
// Parameters:
//  Item            - DataCompositionResultItem         - a data composition result item.
//  DataCompositionProcessor - DataCompositionProcessor - object that performs data composition.
//  TemplateColumns - Structure - see function IHLDataComposition.TemplateColumns.
//  GroupNames      - Structure - see function IHLDataComposition.GroupNames.
//
Procedure FastOutput(Item, DataCompositionProcessor, TemplateColumns, 
    GroupNames) Export 
    
EndProcedure // FastOutput()

#EndRegion // ServiceProgramInterface

#Region ExternalDataProcessorInfo

// Returns object version.
//
// Returns:
//  String - object version.
//
Function Version() Export
    
    Return "0.0.1.0";
    
EndFunction // Version()

Function BaseDescription() Export
    
    BaseDescription = NStr("en = 'CSV (%1) format data processor, ver. %2'; 
        |ru = 'Обработчик формата CSV (%1), вер. %2'");
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
    
    Return "e86f4368-29ca-42b5-b50e-c3b465f65d9e";
    
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