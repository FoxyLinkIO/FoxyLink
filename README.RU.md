<p align="center">
  <a href="https://pbazeliuk.com/foxylink">
    <img src="https://github.com/pbazeliuk/FoxyLink/blob/develop/img/FoxyLink64.png" alt="" width=64 height=64>
  </a>
  <h3 align="center">FoxyLink</h3>

  <p align="center">
    Интуитивно понятная и мощная подсистема для более быстрой и прозрачной интеграции
    <br>основана на платформе "1С:Предприятие 8"
    <br>
    <a href="https://pbazeliuk.com/foxylink/docs/"><strong>FoxyLink документация »</strong></a>
    <br>
    <br>
    <a href="https://pbazeliuk.com/foxylink/integrations">FoxyLink интеграции</a>
    ·
    <a href="https://pbazeliuk.com/tag/FoxyLink/">Блог</a>
  </p>
</p>

<br>

## Содержание

- [Быстрый старт](#Быстрый-старт)
- [Статус](#Статус)
- [Общие сведения](#Общие-сведения)
- [Ошибки и пожелания](#Ошибки-и-пожелания)
- [Документация (Устарела)](#Документация)
- [Авторское право и лицензия](#Авторское-право-и-лицензия)

## Быстрый старт

Подсистему легко начать использовать с любой конфигурацией на платформе «1С: Предприятие 8», требования:
- Версия платформы: 
    - 8.3.10.2252 (минимальная, подсистема SocialNetwork не поддерживается) 
    - **рекомендуемая 8.3.11.2924** и выше
- Режим управления блокировкой данных: **Управляемый**
- Режим совместимости: **8.3.7** и выше
- Кластер серверов «1С:Предприятие 8» и сервер базы данных для наилучшей производительности 

Подсистема FoxyLink доступна как конфигурация, поэтому вы можете установить ее с помощью команды:
```1С:Предприятие 8 -> Конфигуратор -> Конфигурация -> Сравнить, объединить с конфигурацией из файла...```. 

## Статус

[![Telegram](https://img.shields.io/badge/chat-Telegram-blue.svg)](https://t.me/FoxyLink)
[![Quality Gate](https://sonar.silverbulleters.org/api/badges/gate?key=ktc-foxylink)](https://sonar.silverbulleters.org/dashboard?id=ktc-foxylink)

## Общие сведения

FoxyLink предоставляет унифицированную модель программирования для надежного управления задачами интеграции и запуска их на кластере серверов «1С: Предприятие 8». Вы можете начать с простой настройки и увеличить вычислительную мощность для задач интеграции со временем для этих сценариев:

- невероятно простой способ вывода отчетов в JSON, CSV, XML и т. д.
- интеграция с различными системами бизнес-аналитики
- задачами выполнить-и-забыть
- массовые уведомления / информационные рассылки
- экспортировать данные в JSON, CSV, XML и т. д.
- экспортировать данные с произвольной иерархией
- создание сообщений для систем обмена сообщениями
- поддержка плагинов
- *...и так далее*

![Data composition schema output process](https://raw.githubusercontent.com/pbazeliuk/OutputProcessorExtension/develop/img/OutputProcess.png)

## Ошибки и пожелания

Проекты с открытым исходным кодом развиваются более плавно, когда обсуждения публичны.

Если вы обнаружили ошибку, сообщите об этом в [FoxyLink GitHub Issues](https://github.com/pbazeliuk/FoxyLink/issues?state=open). Приветствуются подробные отчеты с вызовами стека, реальным и ожидаемым поведением.

Если у вас есть какие-либо вопросы, проблемы, связанные с использованием подсистемы FoxyLink или если вы хотите обсудить новые функции, посетите чат [Slack](https://foxylinkio.herokuapp.com/).
## Документация 

```1C-Enterprise
Function OutputInJSON(DataCompositionSchema, DataCompositionSettings)
    
    DataCompositionTemplate = FL_DataComposition.NewTemplateComposerParameters();
    DataCompositionTemplate.Schema   = DataCompositionSchema;
    DataCompositionTemplate.Template = DataCompositionSettings;
    
    OutputParameters = FL_DataComposition.NewOutputParameters();
    OutputParameters.DCTParameters = DataCompositionTemplate;
    OutputParameters.CanUseExternalFunctions = True;
    
    StreamObject = DataProcessors.FL_DataProcessorJSON.Create();
    Stream = New MemoryStream();
    StreamObject.Initialize(Stream);
	
    FL_DataComposition.Output(StreamObject, OutputParameters);

    StreamObject.Close()
    
    Return GetStringFromBinaryData(Stream.CloseAndGetBinaryData());
   
EndFunction // OutputInJSON()
```

## Авторское право и лицензия

Копирайт © 2016-2019 Петр Базелюк.

Эта программа бесплатного программного обеспечения: вы можете распространять ее и/или изменять
в соответствии с условиями GNU Affero General Public License которая
опубликована Фондом Свободного Программного Обеспечения, под 3(третьей) версией
лицензии или (по вашему выбору) под любой более поздней версией данной лицензии.

Эта программа распространяется в надежде, что она будет полезна,
но БЕЗ КАКИХ-ЛИБО ГАРАНТИЙ; без подразумеваемой гарантии
КОММЕРЧЕСКАЯ ПРИГОДНОСТЬ ИЛИ ПРИГОДНОСТЬ ДЛЯ ОПРЕДЕЛЕННОЙ ЦЕЛИ. См.
GNU Affero General Public License для получения более подробной информации.

Вы должны были получить копию GNU Affero General Public License
наряду с этой программой. Если нет, см. [http://www.gnu.org/licenses/agpl-3.0](http://www.gnu.org/licenses/agpl-3.0).

Примечание
------

Отправляя запрос (Pull Request), вы отказываетесь от любых прав или претензий к любым изменениям, внесенным в проект FoxyLink, и передаете все авторские права на эти изменения Петру Базелюку.

Если вы не можете или не хотите переназначать эти права (ваш трудовой договор для вашего работодателя не может этого допускать), вы не должны предоставлять PR. Откройте новую задачу, и кто-то другой сможет выполнить эту работу.

Это законный способ сказать: «Если вы подадите нам PR, этот код станет нашим». Мы надеемся, что это не отпугнет вас от участия в проекте.

## Счастливые клиенты

<p align="center">
  <a href="https://www.riger.ca/">
    <img src="https://github.com/FoxyLinkIO/FoxyLink/blob/develop/img/customers/Riger.ca.png" alt="" width=100px height=42px/>
  </a>
  <a href="https://ktc.ua/">
    <img src="https://github.com/FoxyLinkIO/FoxyLink/blob/develop/img/customers/ktc.svg" alt="" width=196px height=42px/>
  </a>
  <a href="https://previa.uk.com/">
    <img src="https://github.com/FoxyLinkIO/FoxyLink/blob/develop/img/customers/previa.uk.png" alt="" width=100px height=42px/>
  </a>
</p>
