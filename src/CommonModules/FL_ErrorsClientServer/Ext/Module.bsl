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

#Region ProgramInterface

// Returns wrong type error description.
//
// Parameters:
//  VarName      - String    - variable name.
//  VarValue     - Arbitrary - variable value.
//  ExpectedType - Type      - expected variable value type.
//
// Returns:
//  String - error description message.
//
Function ErrorTypeIsDifferentThanExpected(VarName, VarValue, ExpectedType) Export
    
    ErrorMessage = NStr(
        "en = 'Error: Failed to process parameter ''%1''. Expected type ''%2'' and received type is ''%3''.';
        |ru = 'Ошибка: Не удалось обработать параметр ''%1''. Ожидался тип ''%2'', а получили тип ''%3''.'");
    
    ErrorMessage = StrTemplate(ErrorMessage, VarName, String(ExpectedType), 
        String(TypeOf(VarValue)));
    Return ErrorMessage;   
    
EndFunction // ErrorTypeIsDifferentThanExpected()

// Returns key missing error description.
//
// Parameters:
//  VarName      - String    - variable name.
//  VarValue     - Arbitrary - variable value.
//  KeyName      - String    - expected key.
//
// Returns:
//  String - error description message.
//
Function ErrorKeyIsMissingInObject(VarName, VarValue, KeyName) Export
    
    ErrorMessage = NStr(
        "en = 'Error: Key ''%1'' is missing in %2 ''%3''.';
        |ru = 'Ошибка: Ключ ''%1'' отсутствует в %2 ''%3''.'");
    
    ErrorMessage = StrTemplate(ErrorMessage, KeyName, String(TypeOf(VarValue)), 
        VarName);
    Return ErrorMessage;   
    
EndFunction // ErrorKeyIsMissingInObject()

#EndRegion // ProgramInterface