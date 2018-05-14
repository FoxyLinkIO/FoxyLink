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
// along with this program. If not, see <http://www.gnu.org/licenses/agpl-3.0>.
//
////////////////////////////////////////////////////////////////////////////////

#Region ProgramInterface

// Personalizes anonymous errors by the provided key name.
//
// Parameters:
//  AnonymousErrors    - Array  - a list of anonymous errors. 
//  PersonalizedErrors - Array  - a list of personalized errors.
//  KeyName            - String - the key name connected with errors.
//
Procedure PersonalizeErrorsWithKey(AnonymousErrors, PersonalizedErrors, 
    KeyName) Export
    
    For Each ErrorMessage In AnonymousErrors Do
        PersonalizedErrors.Add(StrTemplate(ErrorMessage, KeyName));    
    EndDo;
    
EndProcedure // PersonalizeErrorsWithKey()

// Returns {failed to process parameter template} error description.
//
// Returns:
//  String - error description message.
//
Function ErrorFailedToProcessParameterTemplate() Export
    
    ErrorMessage = NStr("en='Error: Failed to process parameter {%1}.'; 
        |ru='Ошибка: Не удалось обработать параметр {%1}.';
        |uk='Помилка: Не вдалось опрацювати параметр {%1}.';
        |en_CA='Error: Failed to process parameter {%1}.'");
    Return ErrorMessage;
    
EndFunction // ErrorFailedToProcessParameterTemplate()

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
Function ErrorTypeIsDifferentFromExpected(VarName, VarValue, 
    ExpectedType) Export
    
    ErrorMessage = NStr("en='Error: Failed to process parameter {%1}. Expected type {%2} and received type is {%3}.';
        |ru='Ошибка: Не удалось обработать параметр {%1}. Ожидался тип {%2}, а получили тип {%3}.';
        |uk='Помилка: Не вдалось опрацювати параметр {%1}. Очікувався тип {%2}, а отримали тип {%3}.';
        |en_CA='Error: Failed to process parameter {%1}. Expected type {%2} and received type is {%3}.'");
    ErrorMessage = StrTemplate(ErrorMessage, VarName, String(ExpectedType), 
        String(TypeOf(VarValue)));
    Return ErrorMessage;   
    
EndFunction // ErrorTypeIsDifferentFromExpected()

// Returns key missing error description.
//
// Parameters:
//  VarName  - String    - variable name.
//  VarValue - Arbitrary - variable value.
//  KeyName  - String    - expected key.
//
// Returns:
//  String - error description message.
//
Function ErrorKeyIsMissingInObject(VarName, VarValue, KeyName) Export
    
    ErrorMessage = NStr("en='Error: Key {%1} is missing in {%2} {%3}.';
        |ru='Ошибка: Ключ {%1} отсутствует в %2 {%3}.';
        |en_CA='Error: Key {%1} is missing in %2 {%3}.'");
    ErrorMessage = StrTemplate(ErrorMessage, KeyName, String(TypeOf(VarValue)), 
        VarName);
    Return ErrorMessage;   
    
EndFunction // ErrorKeyIsMissingInObject()

// Returns collections are different error description.
//
// Parameters:
//  CollectionName1 - String - collection name1.
//  CollectionName2 - String - collection name2.
//
// Returns:
//  String - error description message.
//
Function ErrorColumnCollectionsAreDifferent(CollectionName1, 
    CollectionName2) Export
    
    ErrorMessage = NStr("en='Error: The column collection {%1} differ from the column collection {%2}.';
        |ru='Ошибка: Коллекция колонок {%1} отличается от коллекции колонок {%2}.';
        |en_CA='Error: The column collection {%1} differ from the column collection {%2}.'");
    ErrorMessage = StrTemplate(ErrorMessage, CollectionName1, CollectionName2);
    Return ErrorMessage;   
    
EndFunction // ErrorColumnCollectionsAreDifferent()

#EndRegion // ProgramInterface