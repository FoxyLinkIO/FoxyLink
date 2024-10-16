<p align="center">
  <a href="https://pbazeliuk.com/foxylink">
    <img src="https://github.com/pbazeliuk/FoxyLink/blob/develop/img/FoxyLink64.png" alt="" width=64 height=64>
  </a>
  <h3 align="center">FoxyLink</h3>

  <p align="center">
    Smooth, intuitive, and powerful subsystem for faster and easier integration development 
    <br>based on "1C:Enterprise 8" platform
    <br>
    <a href="https://pbazeliuk.com/foxylink/docs/"><strong>Explore FoxyLink docs »</strong></a>
    <br>
    <br>
    <a href="https://pbazeliuk.com/foxylink/integrations">FoxyLink Integrations</a>
    ·
    <a href="https://pbazeliuk.com/tag/FoxyLink/">Blog</a>
  </p>
</p>

<br>

## Table of contents

- [Quick start](#quick-start)
- [Status](#status)
- [Overview](#overview)
- [Bugs and feature requests](#bugs-and-feature-requests)
- [Documentation (Outdated)](#documentation)
- [Copyright and license](#copyright-and-license)

## Quick start

It's easy to start using it with any configuration on "1C:Enterprise 8" platform, requirements:
- Platform version: 
    - 8.3.10.2772 (minimal, SocialNetwork subsystem unsupported)
    - **recommended 8.3.11.2924** and higher
- Data lock control mode: **Managed**
- Compatibility mode: **8.3.10** and higher
- «1C:Enterprise 8» server cluster and Database server for the best performance 

FoxyLink subsystem is available as configuration, so you can install it using command:
```1C:Enterprise 8 -> Designer -> Configuration -> Compare and merge with configuration from file...```. 

## Status

![](https://vistr.dev/badge?repo=FoxyLinkIO.FoxyLink)
[![Telegram](https://img.shields.io/badge/chat-Telegram-blue.svg)](https://t.me/FoxyLink)
[![Quality Gate](https://sonar.silverbulleters.org/api/badges/gate?key=ktc-foxylink)](https://sonar.silverbulleters.org/dashboard?id=ktc-foxylink)


## Overview

FoxyLink provides an unified programming model to handle integration tasks in a reliable way and run them on 1C:Enterprise server cluster. You can start with a simple setup and grow computational power for integration jobs with time for these scenarios: 

- incredibly easy way to output reports in JSON, CSV, XML, etc.
- integration with different business intelligence systems
- fire-and-forget jobs
- mass notifications/newsletters
- export data to JSON, CSV, XML, etc.
- export data with arbitrary hierarchy  
- creation of messages for message exchange systems
- plugins support
- *...and so on*

![Data composition schema output process](https://raw.githubusercontent.com/pbazeliuk/OutputProcessorExtension/develop/img/OutputProcess.png)

## Bugs and feature requests

Open-source projects develop more smoothly when discussions are public.

If you've discovered a bug, please report it to the [FoxyLink GitHub Issues](https://github.com/pbazeliuk/FoxyLink/issues?state=open). Detailed reports with stack traces, actual and expected behaviours are welcome.

If you have any questions, problems related to the FoxyLink subsystem usage or if you want to discuss new features, please visit the chatroom [Slack](https://foxylinkio.herokuapp.com/).

## Documentation 

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

## Copyright and license

Copyright © 2016-2023 Petro Bazeliuk.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program. If not, see [http://www.gnu.org/licenses/agpl-3.0](http://www.gnu.org/licenses/agpl-3.0).

Legal
------

By submitting a Pull Request, you disavow any rights or claims to any changes submitted to the FoxyLink project and assign the copyright of those changes to Petro Bazeliuk.

If you cannot or do not want to reassign those rights (your employment contract for your employer may not allow this), you should not submit a PR. Open an issue and someone else can do the work.

This is a legal way of saying "If you submit a PR to us, that code becomes ours". 99.9% of the time that's what you intend anyways; we hope it won't scare you away from contributing.

## Happy Customers

[<img src="img/customers/Riger.ca.png" width="100px">](https://www.riger.ca/)
[<img src="img/customers/ktc.svg" width="100px">](https://ktc.ua/)
[<img src="img/customers/prime-print.svg" width="100px">](https://prime-print.com.ua/)
[<img src="img/customers/secur.svg" width="100px">](https://secur.ua/)
[<img src="img/customers/meest-china.svg" width="100px">](https://meest.cn/)
[<img src="img/customers/sviymarket.png" width="100px">](https://sviymarket.com/)
[<img src="img/customers/badyorui.png" width="100px">](https://badyorui.com.ua/)
[<img src="img/customers/previa.uk.png" width="100px">](https://previa.uk.com/)
