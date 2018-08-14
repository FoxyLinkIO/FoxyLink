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

// Returns {failed to process message context} error description.
//
// Returns:
//  String - error description message.
//
Function ErrorFailedToProcessMessageContext() Export
    
    ErrorMessage = NStr("en='Error: Failed to process message context {%1}.'; 
        |ru='Ошибка: Не удалось обработать контекст сообщения {%1}.';
        |uk='Помилка: Не вдалось опрацювати контекст повідомлення {%1}.';
        |en_CA='Error: Failed to process message context {%1}.'");
    Return ErrorMessage;
    
EndFunction // ErrorFailedToProcessMessageContext()

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
        |ru='Ошибка: Ключ {%1} отсутствует в {%2} {%3}.';
        |uk='Помилка: Ключ {%1} відсутній в {%2} {%3}.';
        |en_CA='Error: Key {%1} is missing in {%2} {%3}.'");
    ErrorMessage = StrTemplate(ErrorMessage, KeyName, String(TypeOf(VarValue)), 
        VarName);
    Return ErrorMessage;   
    
EndFunction // ErrorKeyIsMissingInObject()

// Returns identifier missing in linked objects error description.
//
// Parameters:
//  AppEndpoint - CatalogRef.FL_Channels - a reference to application endpoint.
//  Object      - AnyRef                 - any valid reference in database.
//
// Returns:
//  String - error description message.
//
Function ErrorIdentifierIsMissingInLinkedObjects(AppEndpoint, Object) Export
    
    ErrorMessage = NStr("en='Error: Identifier is missing {AppEndpoint: %1} {Object: %2}.';
        |ru='Ошибка: Идентификатор отсутствует {Конечная точка: %1} {Объект: %2}.';
        |uk='Помилка: Ідентифікатор відсутній {Кінцева точка: %1} {Об''єкт: %2}.';
        |en_CA='Error: Identifier is missing {AppEndpoint: %1} {Object: %2}.'");
    ErrorMessage = StrTemplate(ErrorMessage, String(AppEndpoint), 
        String(Object));
    Return ErrorMessage;   
    
EndFunction // ErrorIdentifierIsMissingInLinkedObjects()

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
        |uk='Помилка: Колекція колонок {%1} відрізняється від колекції колонок {%2}.';
        |en_CA='Error: The column collection {%1} differ from the column collection {%2}.'");
    ErrorMessage = StrTemplate(ErrorMessage, CollectionName1, CollectionName2);
    Return ErrorMessage;   
    
EndFunction // ErrorColumnCollectionsAreDifferent()

#Region ValueConversion

// Adds an error message to the provided conversion result and set propery 
// {TypeConverted} to False value.
//
// Parameters:
//  VarName          - String    - attribute name.
//  ConversionResult - Structure - see function FL_CommonUse.NewConversionResult.
//
Procedure RequiredAttributeMissingInObject(VarName, ConversionResult) Export
    
    ErrorMessage = NStr(
        "en='Error: Required attribute {%1} could not be found.'; 
        |ru='Ошибка: Обязательный реквизит {%1} не удалось найти.'; 
        |uk='Помилка: Необхідний реквізит {%1} не вдалося знайти.';
        |en_CA='Error: Required attribute {%1} could not be found.'");
    
    ConversionResult.TypeConverted = False;
    ConversionResult.ErrorMessages.Add(StrTemplate(ErrorMessage, VarName));
    
EndProcedure // RequiredAttributeMissingInObject()

// Adds an error message to the provided conversion result and set propery 
// {TypeConverted} to False value.
//
// Parameters:
//  VarName          - String    - tabular section name.
//  ConversionResult - Structure - see function FL_CommonUse.NewConversionResult.
//
Procedure RequiredTabularSectionMissingInObject(VarName, ConversionResult) Export
    
    ErrorMessage = NStr(
        "en='Error: Required tabular section {%1} could not be found.'; 
        |ru='Ошибка: Обязательную табличную часть {%1} не удалось найти.'; 
        |uk='Помилка: Необхідну табличну частину {%1} не вдалося знайти.';
        |en_CA='Error: Required tabular section {%1} could not be found.'");
    
    ConversionResult.TypeConverted = False;
    ConversionResult.ErrorMessages.Add(StrTemplate(ErrorMessage, VarName));
    
EndProcedure // RequiredTabularSectionMissingInObject()

// Adds an error message to the provided conversion result and set propery 
// {TypeConverted} to False value.
//
// Parameters:
//  VarName          - String    - attribute name.
//  TabularName      - String    - tabular section name.
//  ConversionResult - Structure - see function FL_CommonUse.NewConversionResult.
//
Procedure RequiredTabularColumnMissingInObject(VarName, TabularName, 
    ConversionResult) Export

    ErrorMessage = NStr(
        "en='Error: Required attribute {%1} in tabular section {%2} could not be found.'; 
        |ru='Ошибка: Обязательный реквизит {%1} в табличной части {%2} не удалось найти.'; 
        |uk='Помилка: Необхідний реквізит {%1} в табличній частині {%2} не вдалося знайти.';
        |en_CA='Error: Required attribute {%1} in tabular section {%2} could not be found.'");
    
    ConversionResult.TypeConverted = False;
    ConversionResult.ErrorMessages.Add(StrTemplate(ErrorMessage, VarName, 
        TabularName));
    
EndProcedure // RequiredTabularColumnMissingInObject()

// Adds an error message to the provided conversion result and set propery 
// {TypeConverted} to False value.
//
// Parameters:
//  VarName          - String    - attribute name.
//  TabularName      - String    - tabular section name.
//  ConversionResult - Structure - see function FL_CommonUse.NewConversionResult.
//
Procedure RequiredTabularAttributeNotFilled(VarName, TabularName, 
    ConversionResult) Export

    ErrorMessage = NStr(
        "en='Error: Required attribute {%1} in tabular section {%2} not filled.'; 
        |ru='Ошибка: Обязательный реквизит {%1} в табличной части {%2} не заполнен.'; 
        |uk='Помилка: Необхідний реквізит {%1} в табличній частині {%2} не заповнений.';
        |en_CA='Error: Required attribute {%1} in tabular section {%2} not filled.'");
    
    ConversionResult.TypeConverted = False;
    ConversionResult.ErrorMessages.Add(StrTemplate(ErrorMessage, VarName, 
        TabularName));
    
EndProcedure // RequiredTabularAttributeNotFilled()

// Adds an error message to the provided conversion result and set propery 
// {TypeConverted} to False value.
//
// Parameters:
//  TabularName      - String    - tabular section name.
//  TabularValue     - Arbitrary - tabular section value.
//  ConversionResult - Structure - see function FL_CommonUse.NewConversionResult.
//
Procedure RequiredTabularTypeDifferentFromExpected(TabularName, TabularValue,
    ConversionResult) Export
    
    ErrorMessage = NStr(
        "en='Error: Required tabular section {%1}. Expected type {%2} and received type is {%3}.'; 
        |ru='Ошибка: Обязательная табличная часть {%1}. Ожидался тип {%2}, а получили тип {%3}.'; 
        |uk='Помилка: Необхідна таблична частина {%1}. Очікувався тип {%2}, а отримали тип {%3}.';
        |en_CA='Error: Required tabular section {%1}. Expected type {%2} and received type is {%3}.'");
    
    ConversionResult.TypeConverted = False;
    ConversionResult.ErrorMessages.Add(StrTemplate(ErrorMessage, TabularName, 
        String(Type("FixedArray")), String(TypeOf(TabularValue)))); 
    
EndProcedure // RequiredTabularTypeDifferentFromExpected()

// Adds an error message to the provided conversion result and set propery 
// {TypeConverted} to False value.
//
// Parameters:
//  VarName          - String    - value table name.
//  VarValue         - Arbitrary - value table value.
//  ConversionResult - Structure - see function FL_CommonUse.NewConversionResult.
//
Procedure ObjectValueTableTypeDifferentFromExpected(VarName, VarValue,
    ConversionResult) Export
    
    ErrorMessage = NStr(
        "en='Error: Object value table {%1}. Expected type {%2} and received type is {%3}.'; 
        |ru='Ошибка: Таблица значений объекта {%1}. Ожидался тип {%2}, а получили тип {%3}.'; 
        |uk='Помилка: Таблиця значень об''єкту {%1}. Очікувався тип {%2}, а отримали тип {%3}.';
        |en_CA='Error: Object value table {%1}. Expected type {%2} and received type is {%3}.'");
    
    ConversionResult.TypeConverted = False;
    ConversionResult.ErrorMessages.Add(StrTemplate(ErrorMessage, VarName, 
        String(Type("ValueTable")), String(TypeOf(VarValue)))); 
    
EndProcedure // RequiredTabularTypeDifferentFromExpected()

// Adds an error message to the provided conversion result and set propery 
// {TypeConverted} to False value.
//
// Parameters:
//  VarValue         - Arbitrary - attribute value.
//  ConversionResult - Structure - see function FL_CommonUse.NewConversionResult.
//
Procedure RequiredAttributeTypeNotSupported(VarValue, ConversionResult) Export
    
    ErrorMessage = NStr(
        "en='Error: Type {%1} of required attribute not supported.'; 
        |ru='Ошибка: Тип {%1} проверяемого реквизита не поддерживается.'; 
        |uk='Помилка: Тип {%1} перевіряємого реквізиту не підтримується.';
        |en_CA='Error: Type {%1} of required attribute not supported.'");
    
    ConversionResult.TypeConverted = False;
    ConversionResult.ErrorMessages.Add(StrTemplate(ErrorMessage, 
        String(TypeOf(VarValue))));
    
EndProcedure // RequiredAttributeTypeNotSupported()

#EndRegion // ValueConversion

#EndRegion // ProgramInterface