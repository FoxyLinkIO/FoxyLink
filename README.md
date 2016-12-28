Расширение процессора вывода 
=========

[![Join the chat at https://gitter.im/UpdateExpress/OutputProcessorExtension](https://badges.gitter.im/UpdateExpress/OutputProcessorExtension.svg)](https://gitter.im/UpdateExpress/OutputProcessorExtension?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

[![Gitter](https://badges.gitter.im/UpdateExpress/OutputProcessorExtension.svg)](https://gitter.im/UpdateExpress/OutputProcessorExtension?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge) [![License LGPLv3](https://img.shields.io/badge/license-LGPLv3-green.svg)](http://www.gnu.org/licenses/lgpl-3.0.html)

## Краткий Обзор

Небольшое расширение процессора вывода в JSON. Вывод максимально приближен к выводу в ТабличныйДокумент, только в формате JSON. Легко интегрируется в любую конфигурацию на платформе «1С:Предприятие 8» версии 8.3.6 и выше.

Вы можете начать с простой установки и сразу начинать пользоваться. Основные сценарии использования: 

- вывод отчетов в формате JSON
- интеграция с различными BI системами
- формирование различных выгрузок с иерархией
- формирование сообщений для систем управления очередями
- *...и многое другое*

![Процесс формирования результата схемы компоновки данных](https://pbazeliuk.files.wordpress.com/2016/11/11.png)

Установка
-------------

Расширение распространяеться как конфигурация, для старта необходимо ```Cравнить и объединить``` с вашей конфигурацией. 


Использование
------

**Обычный вывод**

Вывод с использованием дополнительных объектов (деревья, структуры, массивы). Увеличенное использование памяти.

```1C-Enterprise
Функция ВывестиВJSON(СхемаКомпоновкиДанных, НастройкиКомпоновкиДанных)
    
    ПараметрыМакета = UpdateExpressКомпоновкаДанных.ПараметрыМакетаКомпоновкиДанных();
    ПараметрыМакета.Схема = СхемаКомпоновкиДанных;
    ПараметрыМакета.Настройки = НастройкиКомпоновкиДанных;
	
    ПараметрыВывода = UpdateExpressКомпоновкаДанных.ПараметрыВыводаРезультатаКомпоновки();
    ПараметрыВывода.ПараметрыМакета = ПараметрыМакета;
    ПараметрыВывода.ВозможностьИспользованияВнешнихФункций = Истина;

    ЗаписьJSON = Новый ЗаписьJSON;
    ЗаписьJSON.УстановитьСтроку();
    ЗаписьJSON.ЗаписатьНачалоОбъекта();
	
    // Третий параметр указывает на использование обычного вывода
    UpdateExpressПроцессорВывода.Вывести(ЗаписьJSON, ПараметрыВывода, Ложь);
	
    ЗаписьJSON.ЗаписатьКонецОбъекта();
    Возврат ЗаписьJSON.Закрыть();
    
КонецФункции // ВывестиВJSON()    
```

**Последовательный вывод**

Последовательный вывод без использования дополнительных объектов (деревья, структуры, массивы). Вывод медленнее на 20%. Пониженное использование памяти.

```1C-Enterprise
Функция ВывестиВJSON(СхемаКомпоновкиДанных, НастройкиКомпоновкиДанных)
    
    ПараметрыМакета = UpdateExpressКомпоновкаДанных.ПараметрыМакетаКомпоновкиДанных();
    ПараметрыМакета.Схема = СхемаКомпоновкиДанных;
    ПараметрыМакета.Настройки = НастройкиКомпоновкиДанных;
	
    ПараметрыВывода = UpdateExpressКомпоновкаДанных.ПараметрыВыводаРезультатаКомпоновки();
    ПараметрыВывода.ПараметрыМакета = ПараметрыМакета;
    ПараметрыВывода.ВозможностьИспользованияВнешнихФункций = Истина;

    ЗаписьJSON = Новый ЗаписьJSON;
    ЗаписьJSON.УстановитьСтроку();
    ЗаписьJSON.ЗаписатьНачалоОбъекта();
	
    // Третий параметр указывает на необходимость последовательного вывода
    UpdateExpressПроцессорВывода.Вывести(ЗаписьJSON, ПараметрыВывода, Истина);
	
    ЗаписьJSON.ЗаписатьКонецОбъекта();
    Возврат ЗаписьJSON.Закрыть();
    
КонецФункции // ВывестиВJSON()    
```


Вопросы? Проблемы?
---------------------

Открытые проекты развиваются более продуктивно, если дискуссии являются публичными.

Если у вас есть любые вопросы, проблемы связанные с использованием расширения или хотите обсудить новую фичу, смело пишите в чат [Gitter](https://gitter.im/UpdateExpress/OutputProcessorExtension?utm_source=share-link&utm_medium=link&utm_campaign=share-link).  

Если вы нашли баг, пожалуйста опишите его [Update.Express GitHub Issues](https://github.com/UpdateExpress/OutputProcessorExtension/issues?state=open). Детальное описание и описание ожидаемого поведения приветствуется.

Связанные Проекты
-----------------


License
--------

Copyright © 2016 Petro Bazeliuk.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with this program.  If not, see [http://www.gnu.org/licenses/](http://www.gnu.org/licenses).


Legal
------

By submitting a Pull Request, you disavow any rights or claims to any changes submitted to the Update.Express project and assign the copyright of those changes to Petro Bazeliuk.

If you cannot or do not want to reassign those rights (your employment contract for your employer may not allow this), you should not submit a PR. Open an issue and someone else can do the work.

This is a legal way of saying "If you submit a PR to us, that code becomes ours". 99.9% of the time that's what you intend anyways; we hope it doesn't scare you away from contributing.
