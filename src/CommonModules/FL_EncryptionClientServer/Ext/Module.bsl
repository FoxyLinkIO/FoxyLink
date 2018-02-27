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

// Returns field value by the passed field name.
//
// Parameters:
//  FieldName   - String             - field name.
//  ChannelData - FormDataCollection - collection with channel data.
//              - ValueTable         - value table with channel data.
//
// Returns:
//  String - field value.
//
Function FieldValue(FieldName, ChannelData) Export
    
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
   
#EndRegion // ProgramInterface