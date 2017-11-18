Var CoreContext;
Var Assertions;

#Region ServiceInterface

Procedure Инициализация(CoreContextParam) Export
    CoreContext = CoreContextParam;
    Assertions = CoreContext.Плагин("БазовыеУтверждения");
EndProcedure // Инициализация()

Procedure ЗаполнитьНаборТестов(TestsSet) Export

    TestsSet.Добавить("Fact_BackgroundJob_ServerModule");
    TestsSet.Добавить("Fact_BatchJob_ServerModule");
    TestsSet.Добавить("Fact_RecurringJob_ServerModule");
    
    TestsSet.Добавить("Fact_CommonUse_ServerModule");
    TestsSet.Добавить("Fact_CommonUseClientServer_Module");
    TestsSet.Добавить("Fact_CommonUseReUse_ServerModule");

    TestsSet.Добавить("Fact_DataComposition_ServerModule");
    TestsSet.Добавить("Fact_Encryption_ServerModule");
    TestsSet.Добавить("Fact_ErrorsClientServer_Module");
    TestsSet.Добавить("Fact_Events_ServerModule");
    TestsSet.Добавить("Fact_EventsReUse_ServerModule");
    TestsSet.Добавить("Fact_InteriorUse_ServerModule");
    TestsSet.Добавить("Fact_InteriorUseReUse_ServerModule");
    TestsSet.Добавить("Fact_JobServer_ServerModule");
    TestsSet.Добавить("Fact_RunInSafeMode_ServerModule");
    TestsSet.Добавить("Fact_Tasks_ServerModule");
    
    TestsSet.Добавить("Fact_DataProcessorCSV");
    TestsSet.Добавить("Fact_DataProcessorJSON");
    TestsSet.Добавить("Fact_DataProcessorXML");
    
EndProcedure // ЗаполнитьНаборТестов()

#EndRegion // ServiceInterface

#Region TestCases

Procedure Fact_BackgroundJob_ServerModule() Export
        
    Module = Metadata.CommonModules.Find("FL_BackgroundJob");
    ServerCommonModule(Module);
    
EndProcedure // Fact_BackgroundJob_ServerModule()

Procedure Fact_BatchJob_ServerModule() Export
        
    Module = Metadata.CommonModules.Find("FL_BatchJob");
    ServerCommonModule(Module);
    
EndProcedure // Fact_BatchJob_ServerModule()

Procedure Fact_RecurringJob_ServerModule() Export

    Module = Metadata.CommonModules.Find("FL_RecurringJob");
    ServerCommonModule(Module);

EndProcedure // Fact_RecurringJob_ServerModule()

Procedure Fact_CommonUse_ServerModule() Export
        
    Module = Metadata.CommonModules.Find("FL_CommonUse");
    ServerCommonModule(Module);
    
EndProcedure // Fact_CommonUse_ServerModule()

Procedure Fact_CommonUseClientServer_Module() Export

    Module = Metadata.CommonModules.Find("FL_CommonUseClientServer");
    ClientServerCommonModule(Module);

EndProcedure // Fact_CommonUseClientServer_Module()

Procedure Fact_CommonUseReUse_ServerModule() Export
        
    Module = Metadata.CommonModules.Find("FL_CommonUseReUse");
    ReUseServerCommonModule(Module);
    
EndProcedure // Fact_CommonUse_ServerModule()

Procedure Fact_DataComposition_ServerModule() Export

    Module = Metadata.CommonModules.Find("FL_DataComposition");
    ServerCommonModule(Module);

EndProcedure // Fact_DataComposition_ServerModule()

Procedure Fact_Encryption_ServerModule() Export

    Module = Metadata.CommonModules.Find("FL_Encryption");
    ServerCommonModule(Module);

EndProcedure // Fact_Encryption_ServerModule()

Procedure Fact_ErrorsClientServer_Module() Export

    Module = Metadata.CommonModules.Find("FL_ErrorsClientServer");
    ClientServerCommonModule(Module);

EndProcedure // Fact_ErrorsClientServer_Module()

Procedure Fact_Events_ServerModule() Export

    Module = Metadata.CommonModules.Find("FL_Events");
    ServerCommonModule(Module);

EndProcedure // Fact_Events_ServerModule()

Procedure Fact_EventsReUse_ServerModule() Export
        
    Module = Metadata.CommonModules.Find("FL_EventsReUse");
    ReUseServerCommonModule(Module);
    
EndProcedure // Fact_EventsReUse_ServerModule()

Procedure Fact_InteriorUse_ServerModule() Export

    Module = Metadata.CommonModules.Find("FL_InteriorUse");
    ServerCommonModule(Module);

EndProcedure // Fact_InteriorUse_ServerModule()

Procedure Fact_InteriorUseReUse_ServerModule() Export
        
    Module = Metadata.CommonModules.Find("FL_InteriorUseReUse");
    ReUseServerCommonModule(Module);
    
EndProcedure // Fact_InteriorUseReUse_ServerModule()

Procedure Fact_JobServer_ServerModule() Export

    Module = Metadata.CommonModules.Find("FL_JobServer");
    ServerCommonModule(Module);

EndProcedure // Fact_JobServer_ServerModule()

Procedure Fact_RunInSafeMode_ServerModule() Export

    Module = Metadata.CommonModules.Find("FL_RunInSafeMode");
    ServerCommonModule(Module);

EndProcedure // Fact_RunInSafeMode_ServerModule()

Procedure Fact_Tasks_ServerModule() Export

    Module = Metadata.CommonModules.Find("FL_Tasks");
    ServerCommonModule(Module);

EndProcedure // Fact_Tasks_ServerModule()

Procedure Fact_DataProcessorCSV() Export
    
    Result = Metadata.DataProcessors.Find("FL_DataProcessorCSV");

    Assertions.ПроверитьТип(Result, "MetadataObject");
    
EndProcedure // Fact_DataProcessorCSV()

Procedure Fact_DataProcessorJSON() Export
    
    Result = Metadata.DataProcessors.Find("FL_DataProcessorJSON");

    Assertions.ПроверитьТип(Result, "MetadataObject");
    
EndProcedure // Fact_DataProcessorJSON()

Procedure Fact_DataProcessorXML() Export
    
    Result = Metadata.DataProcessors.Find("FL_DataProcessorXML");

    Assertions.ПроверитьТип(Result, "MetadataObject");
    
EndProcedure // Fact_DataProcessorXML()

#EndRegion // TestCases

#Region ServiceProceduresAndFunctions

Procedure ServerCommonModule(Module)
    
    Assertions.ПроверитьТип(Module, "MetadataObject");
     
    Assertions.ПроверитьЛожь(Module.Global);

    Assertions.ПроверитьЛожь(Module.ClientManagedApplication);
    Assertions.ПроверитьИстину(Module.Server);
    Assertions.ПроверитьИстину(Module.ExternalConnection);
    Assertions.ПроверитьИстину(Module.ClientOrdinaryApplication);

    Assertions.ПроверитьЛожь(Module.Privileged);
    Assertions.ПроверитьЛожь(Module.ServerCall);

    Assertions.ПроверитьРавенство(Module.ReturnValuesReuse, 
        Metadata.ObjectProperties.ReturnValuesReuse.DontUse);    
    
EndProcedure // ServerCommonModule()

Procedure ClientServerCommonModule(Module)
    
    Assertions.ПроверитьТип(Module, "MetadataObject");
     
    Assertions.ПроверитьЛожь(Module.Global);

    Assertions.ПроверитьИстину(Module.ClientManagedApplication);
    Assertions.ПроверитьИстину(Module.Server);
    Assertions.ПроверитьИстину(Module.ExternalConnection);
    Assertions.ПроверитьИстину(Module.ClientOrdinaryApplication);

    Assertions.ПроверитьЛожь(Module.Privileged);
    Assertions.ПроверитьЛожь(Module.ServerCall);

    Assertions.ПроверитьРавенство(Module.ReturnValuesReuse, 
        Metadata.ObjectProperties.ReturnValuesReuse.DontUse);    
    
EndProcedure // ClientServerCommonModule()

Procedure ReUseServerCommonModule(Module) 
    
    Assertions.ПроверитьТип(Module, "MetadataObject");
     
    Assertions.ПроверитьЛожь(Module.Global);

    Assertions.ПроверитьЛожь(Module.ClientManagedApplication);
    Assertions.ПроверитьИстину(Module.Server);
    Assertions.ПроверитьИстину(Module.ExternalConnection);
    Assertions.ПроверитьИстину(Module.ClientOrdinaryApplication);

    Assertions.ПроверитьЛожь(Module.Privileged);
    Assertions.ПроверитьЛожь(Module.ServerCall);

    Assertions.ПроверитьРавенство(Module.ReturnValuesReuse, 
        Metadata.ObjectProperties.ReturnValuesReuse.DuringSession);    
    
EndProcedure // ReUseServerCommonModule()

#EndRegion // ServiceProceduresAndFunctions

