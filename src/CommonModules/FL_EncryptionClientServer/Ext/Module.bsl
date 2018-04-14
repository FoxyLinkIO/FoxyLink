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

#Region ProgramInterface

// Adds field value to channel data.
//
// Parameters:
//  ChannelData - FormDataCollection - collection with channel data.
//              - ValueTable         - value table with channel data.
//  FieldName   - String             - field name.
//  FieldValue  - String             - field value.
//
Procedure AddFieldValue(ChannelData, FieldName, FieldValue) Export
    
    NewChannelDataRow = ChannelData.Add();
    NewChannelDataRow.FieldName  = FieldName;
    NewChannelDataRow.FieldValue = FieldValue;
    
EndProcedure // AddFieldValue()

// Returns field value by the passed field name.
//
// Parameters:
//  ChannelData - FormDataCollection - collection with channel data.
//              - ValueTable         - value table with channel data.
//  FieldName   - String             - field name.
//
// Returns:
//  String - field value.
//
Function FieldValue(ChannelData, FieldName) Export
    
    FilterParameters = New Structure("FieldName", FieldName);
    FilterResult = ChannelData.FindRows(FilterParameters);
    If FilterResult.Count() = 1 Then
        Return FilterResult[0].FieldValue;
    EndIf;
    
    Raise NStr("en='Value not found or duplicated.';
        |ru='Значение не найдено или дублируется.';
        |uk='Значення не знайдено або дублюється.';
        |en_CA='Value not found or duplicated.'");
    
EndFunction // FieldValue()

// Returns field value by the passed field name without exception.
//
// Parameters:
//  ChannelData - FormDataCollection - collection with channel data.
//              - ValueTable         - value table with channel data.
//  FieldName   - String             - field name.
//
// Returns:
//  String    - field value.
//  Undefined - field value not found.
//
Function FieldValueNoException(ChannelData, FieldName) Export
    
    FilterParameters = New Structure("FieldName", FieldName);
    FilterResult = ChannelData.FindRows(FilterParameters);
    If FilterResult.Count() = 1 Then
        Return FilterResult[0].FieldValue;
    EndIf;
    
    Return Undefined;
    
EndFunction // FieldValueNoException()
   
#EndRegion // ProgramInterface