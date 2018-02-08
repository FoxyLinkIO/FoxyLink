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
    
#Region VariablesDescription

Var StreamWriter; // It is used to write CSV text. 

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
    
    Return "RFC 4180";
    
EndFunction // FormatStandard()

// Returns link to the formal document from the Internet Engineering Task Force 
// (IETF) that is the result of committee drafting and subsequent review 
// by interested parties.
//
// Returns:
//  String - format standard link.
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

#EndRegion // FormatDescription

#Region ProgramInterface

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
      
    If APISchema <> Undefined Then
        If TypeOf(ThisObject.APISchema) = TypeOf(APISchema) Then    
            ThisObject.APISchema = APISchema.Copy();
        Else
            // Old version schema support could be implemented at this place.
        EndIf;
    EndIf;
    
    StreamWriter = New DataWriter(Stream, , , Chars.CR + Chars.LF, "");
    
EndProcedure // Initialize()

// Completes CSV text writing.
//
Procedure Close() Export
    
    StreamWriter.Close();       
    
EndProcedure // Close()

#EndRegion // ProgramInterface

#Region ServiceProgramInterface

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
    
    If APISchema.Count() = 0 Then
        
        // It is used when API format is not provided.
        BasicOutput(Item, DataCompositionProcessor, 
            ReportStructure.Names, TemplateColumns);
            
    Else

        // It is used when API format is provided.
        APISchemaOutput(Item, DataCompositionProcessor, 
            ReportStructure, TemplateColumns);
            
    EndIf;
        
EndProcedure // Output()

#EndRegion // ServiceProgramInterface

#Region ServiceProceduresAndFunctions

// Only for internal use.
// 
Procedure BasicOutput(Item, DataCompositionProcessor, 
    GroupNames, TemplateColumns)
    
    // The code in the comment written in one line is below this comment.
    // To edit the code, remove the comment.
    // For more information about the code in 1 line see http://infostart.ru/public/71130/.
    
    //Var Level; 
    //
    //CRLF = Chars.CR + Chars.LF;
    //
    //End = DataCompositionResultItemType.End;
    //Begin = DataCompositionResultItemType.Begin;
    //BeginAndEnd = DataCompositionResultItemType.BeginAndEnd;
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
    //            Item = DataCompositionProcessor.Next();
    //            If Item.ItemType = End Then
    //                
    //                // It works better for complicated hierarchy.
    //                Level = ?(Level - 1 < 0, Undefined, Level - 1);
    //                                    
    //            // ElsIf Not IsBlankString(Item.Template) Then
    //                
    //                // It is impossible to get here due to structure of output.
    //
    //            Else
    //                StreamWriter.WriteChars(CRLF);  
    //            EndIf;
    //            
    //        ElsIf NOT IsBlankString(Item.Template) Then
    //            
    //            ColumnNames = TemplateColumns[Item.Template];
    //            
    //            ColumnIndex = 0;
    //            ColumnCount = ColumnNames.Count() - 1;
    //            For Each ColumnName In ColumnNames Do
    //                
    //                StreamWriter.WriteChars(String(
    //                    Item.ParameterValues[ColumnName.Key].Value));
    //                
    //                If ColumnIndex <> ColumnCount Then
    //                    StreamWriter.WriteChars(",");
    //                EndIf;
    //                
    //                ColumnIndex = ColumnIndex + 1;
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
    
    Var Level; CRLF = Chars.CR + Chars.LF; End = DataCompositionResultItemType.End; Begin = DataCompositionResultItemType.Begin; BeginAndEnd = DataCompositionResultItemType.BeginAndEnd; While Item <> Undefined Do If Item.ItemType = Begin Then Item = DataCompositionProcessor.Next(); If Item.ItemType = Begin Then Item = DataCompositionProcessor.Next(); If Item.ItemType = BeginAndEnd Then Level = ?(Level = Undefined, 0, Level + 1); EndIf; EndIf; EndIf; If Level <> Undefined Then If Item.ItemType = End Then Item = DataCompositionProcessor.Next(); If Item.ItemType = End Then Level = ?(Level - 1 < 0, Undefined, Level - 1); Else StreamWriter.WriteChars(CRLF); EndIf; ElsIf NOT IsBlankString(Item.Template) Then ColumnNames = TemplateColumns[Item.Template]; ColumnIndex = 0; ColumnCount = ColumnNames.Count() - 1; For Each ColumnName In ColumnNames Do StreamWriter.WriteChars(String(Item.ParameterValues[ColumnName.Key].Value)); If ColumnIndex <> ColumnCount Then StreamWriter.WriteChars(","); EndIf; ColumnIndex = ColumnIndex + 1; EndDo; EndIf; EndIf; Item = DataCompositionProcessor.Next(); EndDo;   
    
EndProcedure // BasicOutput() 

// Only for internal use.
//
Procedure APISchemaOutput(Item, DataCompositionProcessor, 
    ReportStructure, TemplateColumns)
    
    // The code in the comment written in one line is below this comment.
    // To edit the code, remove the comment.
    // For more information about the code in 1 line see http://infostart.ru/public/71130/.
     
    //Var Level, Delimiter; 
    //
    //CRLF = Chars.CR + Chars.LF;
    //
    //FindResult = APISchema.Find("HeaderLine", "FieldName");
    //If FindResult <> Undefined Then
    //    If NOT IsBlankString(FindResult.FieldValue) Then
    //        StreamWriter.WriteChars(FindResult.FieldValue);
    //        StreamWriter.WriteChars(CRLF);    
    //    EndIf;
    //EndIf;
    //
    //FindResult = APISchema.Find("Delimiter", "FieldName");
    //If FindResult <> Undefined Then
    //    Delimiter = FindResult.FieldValue;
    //Else
    //    Delimiter = ",";    
    //EndIf;
    //
    //End = DataCompositionResultItemType.End;
    //Begin = DataCompositionResultItemType.Begin;
    //BeginAndEnd = DataCompositionResultItemType.BeginAndEnd;
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
    //            Item = DataCompositionProcessor.Next();
    //            If Item.ItemType = End Then
    //                
    //                // It works better for complicated hierarchy.
    //                Level = ?(Level - 1 < 0, Undefined, Level - 1);
    //                                    
    //            // ElsIf Not IsBlankString(Item.Template) Then
    //                
    //                // It is impossible to get here due to structure of output.
    //
    //            Else
    //                StreamWriter.WriteChars(CRLF);  
    //            EndIf;
    //            
    //        ElsIf NOT IsBlankString(Item.Template) Then
    //            
    //            ColumnNames = TemplateColumns[Item.Template];
    //            
    //            ColumnIndex = 0;
    //            ColumnCount = ColumnNames.Count() - 1;
    //            For Each ColumnName In ColumnNames Do
    //                
    //                StreamWriter.WriteChars(String(
    //                    Item.ParameterValues[ColumnName.Key].Value));
    //                
    //                If ColumnIndex <> ColumnCount Then
    //                    StreamWriter.WriteChars(Delimiter);
    //                EndIf;
    //                
    //                ColumnIndex = ColumnIndex + 1;
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
    
    Var Level, Delimiter; CRLF = Chars.CR + Chars.LF; FindResult = APISchema.Find("HeaderLine", "FieldName"); If FindResult <> Undefined Then If NOT IsBlankString(FindResult.FieldValue) Then StreamWriter.WriteChars(FindResult.FieldValue); StreamWriter.WriteChars(CRLF); EndIf; EndIf; FindResult = APISchema.Find("Delimiter", "FieldName"); If FindResult <> Undefined Then Delimiter = FindResult.FieldValue; Else Delimiter = ","; EndIf; End = DataCompositionResultItemType.End; Begin = DataCompositionResultItemType.Begin; BeginAndEnd = DataCompositionResultItemType.BeginAndEnd; While Item <> Undefined Do If Item.ItemType = Begin Then Item = DataCompositionProcessor.Next(); If Item.ItemType = Begin Then Item = DataCompositionProcessor.Next(); If Item.ItemType = BeginAndEnd Then Level = ?(Level = Undefined, 0, Level + 1); EndIf; EndIf; EndIf; If Level <> Undefined Then If Item.ItemType = End Then Item = DataCompositionProcessor.Next(); If Item.ItemType = End Then Level = ?(Level - 1 < 0, Undefined, Level - 1); Else StreamWriter.WriteChars(CRLF); EndIf; ElsIf NOT IsBlankString(Item.Template) Then ColumnNames = TemplateColumns[Item.Template]; ColumnIndex = 0; ColumnCount = ColumnNames.Count() - 1; For Each ColumnName In ColumnNames Do StreamWriter.WriteChars(String(Item.ParameterValues[ColumnName.Key].Value)); If ColumnIndex <> ColumnCount Then StreamWriter.WriteChars(Delimiter); EndIf; ColumnIndex = ColumnIndex + 1; EndDo; EndIf; EndIf; Item = DataCompositionProcessor.Next(); EndDo;
   
EndProcedure // APISchemaOutput()

#EndRegion // ServiceProceduresAndFunctions

#Region ExternalDataProcessorInfo

// Returns object version.
//
// Returns:
//  String - object version.
//
Function Version() Export
    
    Return "1.0.1.0";
    
EndFunction // Version()

// Returns base object description.
//
// Returns:
//  String - base object description.
//
Function BaseDescription() Export
    
    BaseDescription = NStr("en='CSV (%1) format data processor, ver. %2';
        |ru='Обработчик формата CSV (%1), вер. %2';
        |en_CA='CSV (%1) format data processor, ver. %2'");
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

#EndRegion // ExternalDataProcessorInfo

#EndIf