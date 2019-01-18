&AtClient
Var CoreContext;

&AtClient
Var Assertions;

// { ServiceInterface

// Connects and loads plugins needed for this test data processor.
//
// Parameters:
//  CoreContextParam - ExternalDataProcessorObject.xddTestRunner - test runner data processor. 
// 
&AtClient
Procedure Инициализация(CoreContextParam) Export
    
    CoreContext = CoreContextParam;
    Assertions = CoreContext.Плагин("БазовыеУтверждения");
    
    LoadSettings();
    
EndProcedure // Инициализация()

// Loads tests to the test runner data processor.
//
// Parameters:
//  TestsSet         - ExternalDataProcessorObject.ЗагрузчикФайла - file loader data processor.
//  CoreContextParam - ExternalDataProcessorObject.xddTestRunner  - test runner data processor. 
// 
&AtClient
Procedure ЗаполнитьНаборТестов(TestsSet, CoreContextParam) Export

    Инициализация(CoreContextParam);
    CoreContext = CoreContextParam;
    
   // LoadSubsystemTests(TestsSet); 
   // LoadSmokeCommonModuleTests(TestsSet);
        
EndProcedure // ЗаполнитьНаборТестов()

// } ServiceInterface

// { TestCases

// Tests whether subsystem is installed.
//
// Parameters:
//  SubsystemName  - String  - subsystem name.
//  Transaction    - Boolean - shows if transaction exist. 
//                      Default value: False.
//  SubsystemOwner - String  - subsystem owner name.
//                      Default value: Undefined.
//
&AtServer
Procedure Fact_SubsystemExists(SubsystemName, Transaction = False) Export
    
    SplitResult = _StrSplit(SubsystemName, ".");    
    ParentSubsystem = Metadata;
    For Each ParentName In SplitResult Do
        ParentSubsystem = ParentSubsystem.Subsystems.Find(ParentName);
        //Assertions.ПроверитьТип(ParentSubsystem, "MetadataObject");
    EndDo;
    
EndProcedure // Fact_SubsystemExists()

// Tests whether client common module is set properly.
//
// Parameters:
//  CommonModuleName - String  - common module name.
//  Transaction      - Boolean - shows if transaction exist. 
//                      Default value: False.
//
&AtServer
Procedure Fact_ClientModule(CommonModuleName, Transaction = False) Export
    
    Module = Metadata.CommonModules.Find(CommonModuleName);
    
    Assertions.ПроверитьТип(Module, "MetadataObject");
     
    Assertions.ПроверитьЛожь(Module.Global);

    Assertions.ПроверитьИстину(Module.ClientManagedApplication);
    Assertions.ПроверитьЛожь(Module.Server);
    Assertions.ПроверитьЛожь(Module.ExternalConnection);
    Assertions.ПроверитьИстину(Module.ClientOrdinaryApplication);

    Assertions.ПроверитьЛожь(Module.Privileged);
    Assertions.ПроверитьЛожь(Module.ServerCall); 
    
EndProcedure // Fact_ClientModule()

// Tests whether server common module is set properly.
//
// Parameters:
//  CommonModuleName - String  - common module name.
//  Transaction      - Boolean - shows if transaction exist. 
//                      Default value: False.
//
&AtServer
Procedure Fact_ServerModule(CommonModuleName, Transaction = False) Export
    
    Module = Metadata.CommonModules.Find(CommonModuleName);
    
    Assertions.ПроверитьТип(Module, "MetadataObject");
     
    Assertions.ПроверитьЛожь(Module.Global);

    Assertions.ПроверитьЛожь(Module.ClientManagedApplication);
    Assertions.ПроверитьИстину(Module.Server);
    Assertions.ПроверитьИстину(Module.ExternalConnection);
    Assertions.ПроверитьИстину(Module.ClientOrdinaryApplication);

    Assertions.ПроверитьЛожь(Module.Privileged);
    Assertions.ПроверитьЛожь(Module.ServerCall);   
    
EndProcedure // Fact_ServerModule()

// Tests whether client-server common module is set properly.
//
// Parameters:
//  CommonModuleName - String  - common module name.
//  Transaction      - Boolean - shows if transaction exist. 
//                      Default value: False.
//
&AtServer
Procedure Fact_ClientServerModule(CommonModuleName, Transaction = False) Export
    
    Module = Metadata.CommonModules.Find(CommonModuleName);
    
    Assertions.ПроверитьТип(Module, "MetadataObject");
     
    Assertions.ПроверитьЛожь(Module.Global);

    Assertions.ПроверитьИстину(Module.ClientManagedApplication);
    Assertions.ПроверитьИстину(Module.Server);
    Assertions.ПроверитьИстину(Module.ExternalConnection);
    Assertions.ПроверитьИстину(Module.ClientOrdinaryApplication);

    Assertions.ПроверитьЛожь(Module.Privileged);
    Assertions.ПроверитьЛожь(Module.ServerCall);   
    
EndProcedure // Fact_ClientServerModule()

// Tests whether reuse option is set properly.
//
// Parameters:
//  CommonModuleName - String  - common module name.
//  Transaction      - Boolean - shows if transaction exist. 
//                      Default value: False.
//
&AtServer
Procedure Fact_ModuleReUse(CommonModuleName, Transaction = False) Export
    
    Module = Metadata.CommonModules.Find(CommonModuleName);
    Assertions.ПроверитьРавенство(Module.ReturnValuesReuse, 
        Metadata.ObjectProperties.ReturnValuesReuse.DuringSession);
    
EndProcedure // Fact_ModuleReUse() 

// Tests whether reuse option is set properly.
//
// Parameters:
//  CommonModuleName - String  - common module name.
//  Transaction      - Boolean - shows if transaction exist. 
//                      Default value: False.
//
&AtServer
Procedure Fact_ModuleReUseDontUse(CommonModuleName, Transaction = False) Export
    
    Module = Metadata.CommonModules.Find(CommonModuleName);
    Assertions.ПроверитьРавенство(Module.ReturnValuesReuse, 
        Metadata.ObjectProperties.ReturnValuesReuse.DontUse);
    
EndProcedure // Fact_ModuleReUseDontUse() 
    
// } TestCases

// { ServiceProceduresAndFunctions

// Loads smoke tests settings. 
//
&AtClient
Procedure LoadSettings()
    
    SettingsPath = "smoke";
    SettingsPlugin = CoreContext.Плагин("Настройки");
    Object.Settings = SettingsPlugin.ПолучитьНастройку(SettingsPath);
    If Not ValueIsFilled(Object.Settings) Then
        Object.Settings = New Structure;
    EndIf;
    
    If Not Object.Settings.Property("SmokeCommonModules") Then
        Object.Settings.Insert("SmokeCommonModules", 
            NewSmokeCommonModulesSettings());    
    EndIf;

EndProcedure // LoadSettings()

// Retuns basic smoke common modules settings.
//
// Returns:
//  Structure - basic smoke common modules settings.
//      * Subsystems - Array - subsystem names collection for which it's needed 
//                             to run smoke common modules tests. 
//                             If not set, smoke tests run without any restrictions.
//          ** ArrayItem - String - subsystem name. 
//
&AtServer
Function NewSmokeCommonModulesSettings()
    
    Return FormAttributeToValue("Object").NewSmokeCommonModulesSettings();
    
EndFunction // NewSmokeCommonModulesSettings()

// } ServiceProceduresAndFunctions
