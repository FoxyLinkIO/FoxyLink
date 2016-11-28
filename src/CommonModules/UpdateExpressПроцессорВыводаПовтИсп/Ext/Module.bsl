// This file is part of Update.Express.
// Copyright © 2016 Petro Bazeliuk.
// 
// Update.Express is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as 
// published by the Free Software Foundation, either version 3 
// of the License, or any later version.
// 
// Update.Express is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public 
// License along with Update.Express. If not, see <http://www.gnu.org/licenses/>.

#Область ПрограммныйИнтерфейс

Функция ЭтоПолеРесурс(Знач Выражение) Экспорт
	
	Выражение = СтрЗаменить(Выражение, Символ(32), "");
	Выражение = СтрЗаменить(Выражение, Символ(160), "");
	Выражение = СтрЗаменить(Выражение, Символы.ПС, "");
	Выражение = СтрЗаменить(Выражение, Символы.ВК, "");
	Выражение = СтрЗаменить(Выражение, Символы.ВК + Символы.ПС, "");
	Выражение = ВРег(Выражение);
	
	Если Найти(Выражение, "СУММА(") = 1 
	 ИЛИ Найти(Выражение, "СРЕДНЕЕ(") = 1
	 ИЛИ Найти(Выражение, "МАКСИМУМ(") = 1
	 ИЛИ Найти(Выражение, "МИНИМУМ(") = 1
	 ИЛИ Найти(Выражение, "КОЛИЧЕСТВО(") = 1
	 ИЛИ Найти(Выражение, "ВЫРАЗИТЬ(") = 1
	 ИЛИ Найти(Выражение, "ВЫЧИСЛИТЬВЫРАЖЕНИЕ(") = 1 Тогда
		Возврат Истина;
	Иначе
		Возврат Ложь
	КонецЕсли;
	
КонецФункции // ЭтоПолеРесурс()

Функция ФункцияПреобразования(Свойство, Значение, ДополнительныеПараметры,
	Отказ) Экспорт
	
	ТипЗначения = ТипЗнч(Значение);
	ИмяТипа = XMLТип(ТипЗначения).ИмяТипа;
	Если Значение = Null Тогда
		
		Возврат Неопределено;
		
	ИначеЕсли UpdateExpressСлужебныйПовтИсп.ЭтоТипСправочникСсылка(ИмяТипа) Тогда
		
		Возврат XMLСтрока(Значение);
		
	ИначеЕсли UpdateExpressСлужебныйПовтИсп.ЭтоТипДокументСсылка(ИмяТипа) Тогда
		
		Возврат XMLСтрока(Значение);
		
	ИначеЕсли UpdateExpressСлужебныйПовтИсп.ЭтоТипПеречислениеСсылка(ИмяТипа) Тогда
		
		Возврат XMLСтрока(Значение);
		
	КонецЕсли;
	
	Возврат Неопределено;	
	
КонецФункции // ФункцияПреобразования()

#КонецОбласти // ПрограммныйИнтерфейс

#Область СервисныеПроцедурыИФункции



#КонецОбласти // СервисныеПроцедурыИФункции