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
- Platform version: **8.3.10.2252** and higher
- Data lock control mode: **Managed**
- Compatibility mode: **8.3.7** and higher
- 1C:Enterprise server cluster and Database server for the best performance 

FoxyLink subsystem is available as configuration, so you can install it using command:
```1C:Enterprise 8 -> Designer -> Configuration -> Compare and merge with configuration from file...```. 

## Status

[![Gitter](https://badges.gitter.im/UpdateExpress/OutputProcessorExtension.svg)](https://gitter.im/UpdateExpress/OutputProcessorExtension?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)
[![Quality Gate](https://sonar.silverbulleters.org/api/badges/gate?key=ktc-foxylink)](https://sonar.silverbulleters.org/dashboard?id=ktc-foxylink)


## Overview

FoxyLink provides an unified programming model to handle integration tasks in a reliable way and run them on 1C:Enterprise server cluster. You can start with a simple setup and grow computational power for integration jobs with time for these scenarios: 

- incredibly easy way to output reports in json, xml, etc.
- integration with different business intelligence systems
- fire-and-forget jobs
- mass notifications/newsletters
- export data to json, xml, etc.
- export data with arbitrary hierarchy  
- creation of messages for message exchange systems
- plugins support
- *...and so on*

![Data composition schema output process](https://raw.githubusercontent.com/pbazeliuk/OutputProcessorExtension/develop/img/OutputProcess.png)

## Bugs and feature requests

Open-source projects develop more smoothly when discussions are public.

If you've discovered a bug, please report it to the [FoxyLink GitHub Issues](https://github.com/pbazeliuk/FoxyLink/issues?state=open). Detailed reports with stack traces, actual and expected behavours are welcome.

If you have any questions, problems related to the FoxyLink subsystem usage or if you want to discuss new features, please visit the chatroom [Gitter](https://gitter.im/UpdateExpress/OutputProcessorExtension?utm_source=share-link&utm_medium=link&utm_campaign=share-link).

## Documentation 

```1C-Enterprise
Function OutputInJSON(DataCompositionSchema, DataCompositionSettings)
    
    DataCompositionTemplate = FL_DataComposition.NewDataCompositionTemplateParameters();
    DataCompositionTemplate.Schema   = DataCompositionSchema;
    DataCompositionTemplate.Template = DataCompositionSettings;
    
    OutputParameters = FL_DataComposition.NewOutputParameters();
    OutputParameters.DCTParameters = DataCompositionTemplate;
    OutputParameters.CanUseExternalFunctions = True;
    
    StreamObject = DataProcessors.FL_DataProcessorJSON.Create();
    StreamObject.Initialize();
	
    FL_DataComposition.Output(Undefined, StreamObject, OutputParameters);
    
    Return StreamObject.Close();
   
EndFunction // OutputInJSON()     
```

## Copyright and license

Copyright © 2016-2017 Petro Bazeliuk.

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

This is a legal way of saying "If you submit a PR to us, that code becomes ours". 99.9% of the time that's what you intend anyways; we hope it doesn't scare you away from contributing.
