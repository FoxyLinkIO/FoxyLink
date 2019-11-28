////////////////////////////////////////////////////////////////////////////////
// This file is part of FoxyLink.
// Copyright © 2016-2019 Petro Bazeliuk.
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

// Returns {cannot perform this operation} error description.
//
// Returns:
//  String - error description message.
//
Function ErrorCannotPerformThisOperation() Export
    
    Return NStr(
        "en='Error: Cannot perform this operation. 
        |For more information, see the event log.';
        |ru='Ошибка: Невозможно выполнить эту операцию. 
        |Для получения дополнительной информации см. Журнал регистрации.';
        |uk='Помилка: Неможливо виконати цю операцію. 
        |Для отримання додаткової інформації див. Журнал реєстрації.';
        |en_CA='Error: Cannot perform this operation. 
        |For more information, see the event log.'");
    
EndFunction // ErrorCannotPerformThisOperation()

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
    Return StrTemplate(ErrorMessage, CollectionName1, CollectionName2);
    
EndFunction // ErrorColumnCollectionsAreDifferent()

// Returns {app endpoint channel form is disabled} error description.
//
// Returns:
//  String - error description message.
//
Function ErrorDisabledAppEndpointChannelForm() Export
    
    Return NStr("en='App endpoint form is not intended for usage.';
        |ru='Форма конечной точки не предназначена для использования.';
        |uk='Форма кінцевої точки не предназначена для використання.';
        |en_CA='App endpoint form is not intended for usage.'");
    
EndFunction // ErrorDisabledAppEndpointChannelForm()
    
// Returns {failed to process message context} error description.
//
// Returns:
//  String - error description message.
//
Function ErrorFailedToProcessMessageContext() Export
    
    Return NStr("en='Error: Failed to process message context {%1}.'; 
        |ru='Ошибка: Не удалось обработать контекст сообщения {%1}.';
        |uk='Помилка: Не вдалось опрацювати контекст повідомлення {%1}.';
        |en_CA='Error: Failed to process message context {%1}.'");
    
EndFunction // ErrorFailedToProcessMessageContext()

// Returns {failed to process parameter template} error description.
//
// Returns:
//  String - error description message.
//
Function ErrorFailedToProcessParameterTemplate() Export
    
    Return NStr("en='Error: Failed to process parameter {%1}.'; 
        |ru='Ошибка: Не удалось обработать параметр {%1}.';
        |uk='Помилка: Не вдалось опрацювати параметр {%1}.';
        |en_CA='Error: Failed to process parameter {%1}.'");
    
EndFunction // ErrorFailedToProcessParameterTemplate()

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
    Return StrTemplate(ErrorMessage, String(AppEndpoint), 
        String(Object)); 
    
EndFunction // ErrorIdentifierIsMissingInLinkedObjects()

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
    Return StrTemplate(ErrorMessage, KeyName, String(TypeOf(VarValue)), 
        VarName);   
    
EndFunction // ErrorKeyIsMissingInObject()

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
    Return StrTemplate(ErrorMessage, VarName, String(ExpectedType), 
        String(TypeOf(VarValue)));  
    
EndFunction // ErrorTypeIsDifferentFromExpected()

#Region BackgroundJobs

// Returns {background job not found by UUID} error description.
//
// Parameters:
//  UUID - UUID - background job UUID. 
//
// Returns:
//  String - error description message.
//
Function ErrorBackgroundJobNotFoundByUUID(UUID) Export
    
    ErrorMessage = NStr("en='Error: Background job not found by UUID {%1}.';
        |ru='Ошибка: Фоновое задание не найдено с помощью уникального идентификатора {%1}.';
        |uk='Помилка: Фонове завдання, не знайдено за допомогою унікального ідентифікатора {%1}.';
        |en_CA='Error: Background job not found by UUID {%1}.'");
    Return StrTemplate(ErrorMessage, String(UUID));  
    
EndFunction // ErrorBackgroundJobNotFoundByUUID()

// Returns {background job was canceled} error description.
//
// Returns:
//  String - error description message.
//
Function ErrorBackgroundJobWasCanceled() Export
    
    Return NStr("en='Error: Background job was canceled by administrator.';
        |ru='Ошибка: Фоновое задание отменено администратором.';
        |uk='Помилка: Фонове завдання відмінено адміністратором.';
        |en_CA='Error: Background job was canceled by administrator.'");
    
EndFunction // ErrorBackgroundJobNotFoundByUUID()

// Returns {cannot execute simultaneouslyB background job} error description.
//
// Returns:
//  String - error description message.
//
Function ErrorCannotExecuteSimultaneouslyBackgroundJob() Export
    
    Return NStr(
        "en='Error: In file IB, it is impossible simultaneously to execute more than one background job.'; 
        |ru='Ошибка: В файловой ИБ невозможно одновременно выполнять более одного фонового задания.';
        |uk='Помилка: В файловій ІБ неможливо одночасно виконувати більше одного фонового завдання.';
        |en_CA='Error: In file IB, it is impossible simultaneously to execute more than one background job.'");

EndFunction // ErrorCannotExecuteSimultaneouslyBackgroundJob()

// Returns {cannot start background job in COMConnection} error description.
//
// Returns:
//  String - error description message.
//
Function ErrorCannotStartBackgroundJobInCOMConnection() Export
    
    Return NStr(
        "en='Error: In file IB, background jobs can only be started from the client application.';
        |ru='Ошибка: В файловой ИБ можно запустить фоновое задание только из клиентского приложения.';
        |uk='Помилка: В файловій ІБ можна запустити фонове завдання тільки з клієнтського додатку.';
        |en_CA='Error: In file IB, background jobs can only be started from the client application.'");

EndFunction // ErrorCannotStartBackgroundJobInCOMConnection()


// Returns {cannot start background job without extensions} error description.
//
// Returns:
//  String - error description message.
//
Function ErrorCannotStartBackgroundJobWithoutExtensions() Export
    
    Return NStr(
        "en='Cannot start a background job with {WithoutExtensions} parameter in a file infobase.';
        |ru='Невозможно запустить фоновое задание с параметром {WithoutExtensions} в файловой информационной базе.'; 
        |uk='Неможливо запустити фонове завдання з параметром {WithoutExtensions} в файловій інформаційній базі.';
        |en_CA='Cannot start a background job with {WithoutExtensions} parameter in a file infobase.'");

EndFunction // ErrorCannotStartBackgroundJobWithoutExtensions()

#EndRegion // BackgroundJobs

#Region DataCompositionSchema
     
// Returns value list allowed is set to false error description.
//
// Parameters:
//  VarName - String - attribute name.
//
// Returns:
//  String - error description message.
//
Function ErrorDataCompositionDataParameterValueListNotAllowed(VarName) Export

    ErrorMessage = NStr("en='The invocation context has several primary key values for {%1}.
        |Data composition schema parameter property {ValueListAllowed} is set to value {False}.';
        |ru='Контекст вызова имеет несколько значений первичных ключей для {%1}.
        |Свойству параметра схемы компоновки данных {ДоступенСписокЗначений} установлено значение {Ложь}.';
        |uk='Контекст виклику має декілька значень первинних ключів для {%1}.
        |Властивості параметра схеми компоновки даних {ДоступенСписокЗначений} вставновлено значення {Хибно}.';
        |en_CA='The invocation context has several primary key values  for {%1}.
        |Data composition schema parameter property {ValueListAllowed} is set to value {False}.'");
    Return StrTemplate(ErrorMessage, VarName); 
    
EndFunction // ErrorDataCompositionDataParameterValueListNotAllowed()

// Returns available parameter warning description.
//
// Parameters:
//  VarName - String - attribute name.
//
// Returns:
//  String - warning description message.
//
Function WarningDataCompositionAvailableParameterNotFound(VarName) Export

    WarningMessage = NStr("en='Warning: Available parameter not found for {%1}.'; 
        |ru='Предупреждение: Доступный параметр не найден для {%1}.'; 
        |uk='Попередження: Доступний параметр не знайдено для {%1}.';
        |en_CA='Warning: Available parameter not found for {%1}.'");
    Return StrTemplate(WarningMessage, VarName);

EndFunction // WarningDataCompositionAvailableParameterNotFound()

#EndRegion // DataCompositionSchema

#Region ValueConversion

// Adds an error message to the provided conversion result.
//
// Parameters:
//  ConversionResult - Structure - see function FL_CommonUse.NewConversionResult.
//
Procedure CodeInConfigurationIsZeroLength(ConversionResult) Export
    
    ErrorMessage = NStr(
        "en='%1 Code in configuration has zero length.'; 
        |ru='%1 Длина поля Код в конфигурации равна нулю.'; 
        |uk='%1 Довжина поля Код в конфігурації рівна нулю.';
        |en_CA='%1 Code in configuration has zero length.'");
    
    AddMessage = FL_ErrorsClientServer.ErrorFailedToProcessParameterTemplate();
    ConversionResult.ErrorMessages.Add(StrTemplate(ErrorMessage, AddMessage)); 
    
EndProcedure // CodeInConfigurationIsZeroLength()

// Adds an error message to the provided conversion result.
//
// Parameters:
//  Length           - Number    - provided code length for database object.
//  ExpectedLength   - Number    - maximal code length of database object.
//  ConversionResult - Structure - see function FL_CommonUse.NewConversionResult.
//
Procedure CodeLengthExceededMaximumLenght(Length, ExpectedLength, 
    ConversionResult) Export
    
    ErrorMessage = NStr(
        "en='%1 Code lenght is {%2} and maximum length is {%3}.'; 
        |ru='%1 Длина Кода равна {%2}, что больше максимальной длины {%3}.'; 
        |uk='%1 Довжина Коду рівна {%2}, що більше максимальної {%3}.';
        |en_CA='%1 Code lenght is {%2} and maximum length is {%3}.'");
    
    AddMessage = FL_ErrorsClientServer.ErrorFailedToProcessParameterTemplate();        
    ConversionResult.ErrorMessages.Add(StrTemplate(ErrorMessage, AddMessage, 
        Length, ExpectedLength));
    
EndProcedure // CodeLengthExceededMaximumLenght()

// Adds an error message to the provided conversion result.
//
// Parameters:
//  VarValue         - Arbitrary - variable value.
//  ExpectedType     - Type      - expected variable value type.
//  ConversionResult - Structure - see function FL_CommonUse.NewConversionResult.
//
Procedure CodeTypeIsDifferentFromExpected(VarValue, ExpectedType, 
    ConversionResult) Export

    ErrorMessage = NStr(
        "en='%1 Expected Code type {%2} and received type is {%3}.'; 
        |ru='%1 Тип Кода ожидался {%2}, а получили тип {%3}.'; 
        |uk='%1 Тип Коду очікувався {%2}, але отримали тип {%3}.';
        |en_CA='%1 Expected Code type {%2} and received type is {%3}.'");
        
    AddMessage = FL_ErrorsClientServer.ErrorFailedToProcessParameterTemplate();                          
    ConversionResult.ErrorMessages.Add(StrTemplate(ErrorMessage, AddMessage, 
        String(ExpectedType), String(TypeOf(VarValue))));
    
EndProcedure // CodeTypeIsDifferentFromExpected()

// Adds an error message to the provided conversion result.
//
// Parameters:
//  CodeType         - CatalogCodeType - catalog code type.
//  ConversionResult - Structure       - see function FL_CommonUse.NewConversionResult.
//
Procedure CodeTypeIsNotSupported(CodeType, ConversionResult) Export
    
    ErrorMessage = NStr(
        "en='%1 Code type {%2} not supported.'; 
        |ru='%1 Тип Кода {%2} не поддерживается.'; 
        |uk='%1 Тип Коду {%2} не підтримується.';
        |en_CA='%1 Code type {%2} not supported.'");     
        
    AddMessage = FL_ErrorsClientServer.ErrorFailedToProcessParameterTemplate();
    ConversionResult.ErrorMessages.Add(StrTemplate(ErrorMessage, AddMessage, 
        String(CodeType)));
    
EndProcedure // CodeTypeIsNotSupported()

// Adds an error message to the provided conversion result.
//
// Parameters:
//  VarValue         - Arbitrary - variable value.
//  ConversionResult - Structure - see function FL_CommonUse.NewConversionResult.
//
Procedure CodeIsNotSupportedInFoxyLink(VarValue, ConversionResult) Export
    
    ErrorMessage = NStr(
        "en='%1 Code in {%2} is not supported in this FoxyLink configuration.'; 
        |ru='%1 Код в {%2} не поддерживается в этой конфигурации FoxyLink.'; 
        |uk='%1 Код в {%2} не підтримується в цій конфігурації FoxyLink.';
        |en_CA='%1 Code in {%2} is not supported in this FoxyLink configuration.'");
    
    AddMessage = FL_ErrorsClientServer.ErrorFailedToProcessParameterTemplate();
    ConversionResult.ErrorMessages.Add(StrTemplate(ErrorMessage, AddMessage, 
        String(TypeOf(VarValue))));
    
EndProcedure // CodeIsNotSupportedInFoxyLink()

// Adds an error message to the provided conversion result and sets property 
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

// Adds an error message to the provided conversion result and sets property 
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

// Adds an error message to the provided conversion result and sets property 
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

// Adds an error message to the provided conversion result and sets property 
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

// Adds an error message to the provided conversion result and sets property 
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

// Adds an error message to the provided conversion result and sets property 
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

// Adds an error message to the provided conversion result and sets property 
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

#EndRegion // ValueConversion

#EndRegion // ProgramInterface