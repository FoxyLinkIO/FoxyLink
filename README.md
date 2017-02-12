Integration happiness library (IHL): Output processor extension 
=========

[![Gitter](https://badges.gitter.im/UpdateExpress/OutputProcessorExtension.svg)](https://gitter.im/UpdateExpress/OutputProcessorExtension?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge) [![License LGPLv3](https://img.shields.io/badge/license-LGPLv3-green.svg)](http://www.gnu.org/licenses/lgpl-3.0.html)

## Overview

Incredibly easy way to output result from DataCompositionSchema into json, xml, etc format. Output result is arranged in the same way as SpreadsheetDocument. It's easy to start using it with any configuration on "1C:Enterprise 8" platform (version 8.3.6 and higher).

You can start with a simple setup. Main usage scenarios: 

- output reports in json, xml, etc.
- integration with different business intelligence systems
- export data with arbitrary hierarchy
- export data to json, xml, etc.  
- creation of messages for message exchange systems
- *...and so on*

![Data composition schema output process](https://raw.githubusercontent.com/pbazeliuk/OutputProcessorExtension/develop/img/OutputProcess.png)

Installation
-------------

IHL extension is available as configuration. You can install it using command ```1C:Enterprise 8 -> Designer -> Configuration -> Compare and merge with configuration from file...```. 


Usage
------

**Fast output**

Output with using additional objects (tree, structures, arrays). It causes increased use of memory.

```1C-Enterprise
Function OutputInJSON(DataCompositionSchema, DataCompositionSettings)
    
    DataCompositionTemplate = IHLDataComposition.NewDataCompositionTemplateParameters();
    DataCompositionTemplate.Schema   = DataCompositionSchema;
    DataCompositionTemplate.Template = DataCompositionSettings;
    
    OutputParameters = IHLDataComposition.NewOutputParameters();
    OutputParameters.DCTParameters = DataCompositionTemplate;
    OutputParameters.CanUseExternalFunctions = True;
    
    StreamObject = DataProcessors.DataProcessorJSON.Create();
    StreamObject.Initialize();
    StreamObject.WriteStartObject();
	
    IHLDataComposition.Output(Undefined, StreamObject, OutputParameters, False);
    
    StreamObject.WriteEndObject();
    Result = StreamObject.Close();
	
    Return Result;
    
EndFunction // OutputInJSON()    
```

**Sequential output**

Sequential output is 22.53% slower than fast output, although it has light memory usage.

```1C-Enterprise
Function OutputInJSON(DataCompositionSchema, DataCompositionSettings)
    
    DataCompositionTemplate = IHLDataComposition.NewDataCompositionTemplateParameters();
    DataCompositionTemplate.Schema   = DataCompositionSchema;
    DataCompositionTemplate.Template = DataCompositionSettings;
    
    OutputParameters = IHLDataComposition.NewOutputParameters();
    OutputParameters.DCTParameters = DataCompositionTemplate;
    OutputParameters.CanUseExternalFunctions = True;
    
    StreamObject = DataProcessors.DataProcessorJSON.Create();
    StreamObject.Initialize();
    StreamObject.WriteStartObject();
	
    IHLDataComposition.Output(Undefined, StreamObject, OutputParameters, True);
    
    StreamObject.WriteEndObject();
    Result = StreamObject.Close();
	
    Return Result;
    
EndFunction // OutputInJSON()     
```


Questions? Problems?
---------------------

Open-source projects develop more smoothly when discussions are public.

If you have any questions, problems related to IHL extension usage or if you want to discuss new features, please visit the chatroom [Gitter](https://gitter.im/UpdateExpress/OutputProcessorExtension?utm_source=share-link&utm_medium=link&utm_campaign=share-link).  

If you've discovered a bug, please report it to the [IHL GitHub Issues](https://github.com/pbazeliuk/OutputProcessorExtension/issues?state=open). Detailed reports with stack traces, actual and expected behavours are welcome.

Related Projects
-----------------


License
--------

Copyright © 2016-2017 Petro Bazeliuk.

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

By submitting a Pull Request, you disavow any rights or claims to any changes submitted to the IHL project and assign the copyright of those changes to Petro Bazeliuk.

If you cannot or do not want to reassign those rights (your employment contract for your employer may not allow this), you should not submit a PR. Open an issue and someone else can do the work.

This is a legal way of saying "If you submit a PR to us, that code becomes ours". 99.9% of the time that's what you intend anyways; we hope it doesn't scare you away from contributing.
