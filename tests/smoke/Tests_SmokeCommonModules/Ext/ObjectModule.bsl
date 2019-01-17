Var CoreContext;
Var Assertions;

#Region ServiceInterface

// Connects and loads plugins needed for this test data processor.
//
// Parameters:
//  CoreContextParam - ExternalDataProcessorObject.xddTestRunner - test runner data processor. 
// 
Procedure Инициализация(CoreContextParam) Export
    
    CoreContext = CoreContextParam;
    Assertions = CoreContext.Плагин("БазовыеУтверждения");
    
EndProcedure // Инициализация()

// Loads tests to the test runner data processor.
//
// Parameters:
//  TestsSet         - ExternalDataProcessorObject.ЗагрузчикФайла - file loader data processor.
//  CoreContextParam - ExternalDataProcessorObject.xddTestRunner  - test runner data processor. 
// 
Procedure ЗаполнитьНаборТестов(TestsSet, CoreContextParam) Export

    CoreContext = CoreContextParam;
    
    LoadSubsystemTests(TestsSet); 
    LoadSmokeCommonModuleTests(TestsSet);
        
EndProcedure // ЗаполнитьНаборТестов()

#EndRegion // ServiceInterface

#Region TestCases

// Tests whether subsystem is installed.
//
// Parameters:
//  SubsystemName  - String  - subsystem name.
//  Transaction    - Boolean - shows if transaction exist. 
//                      Default value: False.
//  SubsystemOwner - String  - subsystem owner name.
//                      Default value: Undefined.
//
Procedure Fact_SubsystemExists(SubsystemName, Transaction = False, 
    SubsystemOwner = Undefined) Export
    
    If SubsystemOwner = Undefined Then
        MainSubsystem = Metadata;    
    Else
        MainSubsystem = Metadata.Subsystems.Find(SubsystemOwner);
        Assertions.ПроверитьТип(MainSubsystem, "MetadataObject");
    EndIf;
    
    Subsystem = MainSubsystem.Subsystems.Find(SubsystemName);
    Assertions.ПроверитьТип(Subsystem, "MetadataObject");
    
EndProcedure // Fact_SubsystemExists()

// Tests whether client common module is set properly.
//
// Parameters:
//  CommonModuleName - String  - common module name.
//  Transaction      - Boolean - shows if transaction exist. 
//                      Default value: False.
//
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
Procedure Fact_ModuleReUseDontUse(CommonModuleName, Transaction = False) Export
    
    Module = Metadata.CommonModules.Find(CommonModuleName);
    Assertions.ПроверитьРавенство(Module.ReturnValuesReuse, 
        Metadata.ObjectProperties.ReturnValuesReuse.DontUse);
    
EndProcedure // Fact_ModuleReUseDontUse() 
    
#EndRegion // TestCases

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
Procedure AddSubsystemTest(TestsSet, SubsystemName, SubsystemOwner = Undefined)
    
    TestParameters = TestsSet.ПараметрыТеста(SubsystemName, False, 
        SubsystemOwner);
    TestsSet.Добавить("Fact_SubsystemExists", TestParameters, StrTemplate(
        NStr("en='Subsystem : %1 installed';
            |ru='Подсистема : %1 установлена';
            |uk='Підсистема : %1 встановлена';
            |en_CA='Subsystem : %1 installed'"), 
        SubsystemName));   
    
EndProcedure // AddSubsystemTest()

// Only for internal use.
//
Procedure LoadSubsystemTests(TestsSet)
    
    TestsSet.НачатьГруппу(
        NStr("en='Subsystems'; 
            |ru='Подсистемы';
            |uk='Підсистеми';
            |en_CA='Subsystems'"), 
        True);
        
    AddSubsystemTest(TestsSet, "FoxyLink"); 
    AddSubsystemTest(TestsSet, "GeneralSettings", "FoxyLink");
    AddSubsystemTest(TestsSet, "Integration", "FoxyLink");
    AddSubsystemTest(TestsSet, "Plugins", "FoxyLink");
    AddSubsystemTest(TestsSet, "Tasks", "FoxyLink");
        
EndProcedure // LoadSubsystemTests()

// Only for internal use.
//
Procedure AddSmokeCommonModuleTest(TestsSet, SubsystemName, SubsystemOwner)
    
    GroupCommonModulesNotExists = True;        
    For Each Item In SubsystemOwner.Content Do
         
        If Metadata.CommonModules.Find(Item.Name) <> Undefined Then
            
            If GroupCommonModulesNotExists Then
                
                GroupCommonModulesNotExists = False;
                TestsSet.НачатьГруппу(StrTemplate(
                    NStr("en='Subsystem : %1 : CommonModules'; 
                        |ru='Подсистема : %1 : ОбщиеМодули';
                        |uk='Підсистема : %1 : ЗагальніМодулі';
                        |en_CA='Subsystem : %1 : CommonModules'"),
                    SubsystemName));
                    
            EndIf;
            
            TestParameters = TestsSet.ПараметрыТеста(Item.Name, False);
            If StrFind(Item.Name, "ClientServer") <> 0 Then
                TestName = "Fact_ClientServerModule";
            ElsIf StrFind(Item.Name, "Client") <> 0 Then
                TestName = "Fact_ClientModule";
            Else
                TestName = "Fact_ServerModule";    
            EndIf;
                
            TestsSet.Добавить(TestName, TestParameters, StrTemplate(
                NStr("en='Common module : %1 {%2}';
                    |ru='Общий модуль : %1 {%2}';
                    |uk='Загальний модуль : %1 {%2}';
                    |en_CA='Common module : %1 {%2}'"), 
                Item.Name, Item.Comment));    
                
            If StrFind(Item.Name, "ReUse") <> 0 Then
                TestName = "Fact_ModuleReUse";    
            Else
                TestName = "Fact_ModuleReUseDontUse";   
            EndIf;
            
            TestsSet.Добавить(TestName, TestParameters, StrTemplate(
                NStr("en='Common module : %1 {Reuse}';
                    |ru='Общий модуль : %1 {Повторное использование}';
                    |uk='Загальний модуль : %1 {Повторне використання}';
                    |en_CA='Common module : %1 {Reuse}'"), 
                Item.Name));
                
        EndIf;

    EndDo;
    
    For Each SubSystem In SubsystemOwner.Subsystems Do
        AddSmokeCommonModuleTest(TestsSet, SubSystem.Synonym, SubSystem);      
    EndDo;
    
EndProcedure // AddSmokeCommonModuleTest()

// Only for internal use.
//
Procedure LoadSmokeCommonModuleTests(TestsSet)
    
    MainSubsystem = Metadata.Subsystems.Find("FoxyLink");
    If MainSubsystem = Undefined Then
        Return;
    EndIf;
    
    AddSmokeCommonModuleTest(TestsSet, MainSubsystem.Name, MainSubsystem); 
          
EndProcedure // LoadSmokeCommonModuleTests()

#EndRegion // ServiceProceduresAndFunctions