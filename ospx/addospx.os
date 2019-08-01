// Возвращает путь к браузеру BDD (проверка поведения через фичи) - внешней обработке bddRunner.epf
//
//  Возвращаемое значение:
//   Строка - полный путь внешней обработки
//
Функция ПутьИнструментаБДД() Экспорт
	Возврат ОбъединитьПути(КаталогИнструментов(), "bddRunner.epf");
КонецФункции //ПутьИнструментаБДД()

// Возвращает путь к браузеру тестов - внешней обработке xddTestRunner.epf
//
//  Возвращаемое значение:
//   Строка - полный путь внешней обработки
//
Функция ПутьИнструментаТДД() Экспорт
	Возврат ОбъединитьПути(КаталогИнструментов(), "xddTestRunner.epf");
КонецФункции // ПутьИнструментаТДД()

// Возвращает путь к каталогу сценариев onescript, т.е. к каталогу текущего скрипта
//
//  Возвращаемое значение:
//   Строка - полный путь внешней обработки
//
Функция КаталогИнструментов() Экспорт
	ФайлИсточника = Новый Файл(ТекущийСценарий().Источник);
	Возврат Новый Файл(ОбъединитьПути(ФайлИсточника.Путь, "..", "tools", "add")).ПолноеИмя;
КонецФункции //КаталогИнструментов()

// Returns the path to the BDD browser (behaviour driven development) - external data processor bddRunner.epf.
//
//  Returns:
//   String - full path to the external data processor.
//
Function GetPathBDD() Export
	Return ПутьИнструментаБДД();
EndFunction // GetPathBDD()

// Returns the path to the test browser - external data processor xddTestRunner.epf.
//
//  Returns:
//   String - full path to the external data processor.
//
Function GetPathXDD() Export
	Return ПутьИнструментаТДД();
EndFunction // GetPathXDD()

// Returns the path to the onescript scripts, i.e. to the directory of the current script.
//
//  Returns:
//   String - full path to the external data processor.
//
Function InstrumentsPath() Export
	Return КаталогИнструментов();
EndFunction // InstrumentsPath()
	