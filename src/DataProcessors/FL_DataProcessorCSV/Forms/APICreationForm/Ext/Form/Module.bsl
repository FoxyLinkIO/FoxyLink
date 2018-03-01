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
// along with this program. If not, see <http://www.gnu.org/licenses/agpl-3.0>.
//
////////////////////////////////////////////////////////////////////////////////

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
    
    Var APISchemaAddress;
        
    If Parameters.Property("APISchemaAddress", APISchemaAddress) Then
        If IsTempStorageURL(APISchemaAddress) Then
            
            ValueTable = GetFromTempStorage(APISchemaAddress);
            If TypeOf(ValueTable) = Type("ValueTable") Then
                ValueToFormAttribute(ValueTable, "Object.APISchema");
                
                For Each APISchemaRow In Object.APISchema Do
                    ThisForm[APISchemaRow.FieldName] = APISchemaRow.FieldValue;    
                EndDo;
                
            EndIf;
            
        EndIf;
    EndIf;
    
    If Delimiter = Chars.Tab Then
        FormatType = "TSV";    
    ElsIf IsBlankString(Delimiter) 
        OR Delimiter = "," Then
        FormatType = "CSV";
    Else
        FormatType = "DSV";    
    EndIf;
    
    Items.Delimiter.Visible = FormatType = "DSV";
  
EndProcedure // OnCreateAtServer()

#EndRegion // FormEventHandlers

#Region FormItemsEventHandlers

&AtClient
Procedure FormatTypeOnChange(Item)
    
    If FormatType = "CSV" Then
        Delimiter = ",";
    ElsIf FormatType = "TSV" Then
        Delimiter = Chars.Tab;
    Else 
        Delimiter = ",";
    EndIf;
    
    Items.Delimiter.Visible = FormatType = "DSV";
    
EndProcedure // FormatTypeOnChange() 

#EndRegion // FormItemsEventHandlers

#Region FormCommandHandlers

&AtClient
Procedure SaveAndClose(Command)
    
    Close(PutValueTableToTempStorage(ThisObject.FormOwner.UUID));    
    
EndProcedure // SaveAndClose()

#EndRegion // FormCommandHandlers

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
&AtServer
Function PutValueTableToTempStorage(Val OwnerUUID)
    
    If IsBlankString(HeaderLine) 
        AND IsBlankString(Delimiter)
        AND IsBlankString(TextEncoding) 
        AND IsBlankString(AddCarriageReturnToLastRow) Then
        Return "";
    EndIf;
    
    If IsBlankString(Delimiter) 
        AND Delimiter <> Chars.Tab Then
        Delimiter = ",";        
    EndIf;
    
    Object.APISchema.Clear();
    
    NewRow = Object.APISchema.Add();
    NewRow.FieldName = "Delimiter";
    NewRow.FieldValue = Delimiter;
        
    NewRow = Object.APISchema.Add();
    NewRow.FieldName = "AddCarriageReturnToLastRow";
    NewRow.FieldValue = AddCarriageReturnToLastRow;
    
    NewRow = Object.APISchema.Add();
    NewRow.FieldName = "HeaderLine";
    NewRow.FieldValue = HeaderLine;
    
    NewRow = Object.APISchema.Add();
    NewRow.FieldName = "TextEncoding";
    NewRow.FieldValue = TextEncoding;
    
    ValueTable = FormAttributeToValue("Object.APISchema", Type("ValueTable")); 
    Return PutToTempStorage(ValueTable, OwnerUUID);
    
EndFunction // PutValueTableToTempStorage()

#EndRegion // ServiceProceduresAndFunctions