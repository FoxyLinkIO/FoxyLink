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

// Adds field value to collection of channel data.
//
// Parameters:
//  Collection - FormDataCollection - collection with channel data.
//             - ValueTable         - value table with channel data.
//  FieldName  - String             - field name.
//  FieldValue - String             - field value.
//
Procedure AddFieldValue(Collection, FieldName, FieldValue) Export
    
    NewCollectionRow = Collection.Add();
    NewCollectionRow.FieldName  = FieldName;
    NewCollectionRow.FieldValue = FieldValue;
    
EndProcedure // AddFieldValue()

// Sets or adds field value in collection of channel data.
//
// Parameters:
//  Collection - FormDataCollection - collection with channel data.
//             - ValueTable         - value table with channel data.
//  FieldName  - String             - field name.
//  FieldValue - String             - field value.
//
Procedure SetFieldValue(Collection, FieldName, FieldValue) Export

    CollectionRow = Collection.Find(FieldName, "FieldName");
    If CollectionRow <> Undefined Then
        CollectionRow.FieldValue = FieldValue;
    Else
        AddFieldValue(Collection, FieldName, FieldValue);  
    EndIf;    
    
EndProcedure // SetFieldValue()  

// Returns field value by the passed field name.
//
// Parameters:
//  Collection - FormDataCollection - collection with channel data.
//             - ValueTable         - value table with channel data.
//  FieldName  - String             - field name.
//
// Returns:
//  String - field value.
//
Function FieldValue(Collection, FieldName) Export
    
    FilterParameters = New Structure("FieldName", FieldName);
    FilterResult = Collection.FindRows(FilterParameters);
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
//  Collection   - FormDataCollection - collection with channel data.
//               - ValueTable         - value table with channel data.
//  FieldName    - String             - field name.
//  DefaultValue - Arbitrary          - default value if exist.
//                          Default value: Undefined.
// Returns:
//  String - field value.
//  Undefined, Arbitrary - field value not found; default value returns.
//
Function FieldValueNoException(Collection, FieldName, 
    DefaultValue = Undefined) Export
    
    FilterParameters = New Structure("FieldName", FieldName);
    FilterResult = Collection.FindRows(FilterParameters);
    If FilterResult.Count() = 1 Then
        Return FilterResult[0].FieldValue;   
    EndIf;
    
    Return DefaultValue;
    
EndFunction // FieldValueNoException()
   
#EndRegion // ProgramInterface