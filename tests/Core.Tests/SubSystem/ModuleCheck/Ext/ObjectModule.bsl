Var CoreContext;
Var Assertions;

#Region ServiceInterface

Procedure Инициализация(CoreContextParam) Export
    CoreContext = CoreContextParam;
    Assertions = CoreContext.Плагин("БазовыеУтверждения");
EndProcedure // Инициализация()

Procedure ЗаполнитьНаборТестов(TestsSet) Export

    TestsSet.Добавить("Fact_CommonModuleIHLCommonUse");
    TestsSet.Добавить("Fact_CommonModuleIHLCommonUseClientServer");
    TestsSet.Добавить("Fact_CommonModuleIHLDataComposition");
    TestsSet.Добавить("Fact_DataProcessorDataProcessorJSON");

EndProcedure // ЗаполнитьНаборТестов()

#EndRegion // ServiceInterface

#Region TestCases

Procedure Fact_CommonModuleIHLCommonUse() Export
        
    Result = Metadata.CommonModules.Find("IHL_CommonUse");

    Assertions.ПроверитьТип(Result, "MetadataObject");
     
    Assertions.ПроверитьЛожь(Result.Global);

    Assertions.ПроверитьЛожь(Result.ClientManagedApplication);
    Assertions.ПроверитьИстину(Result.Server);
    Assertions.ПроверитьИстину(Result.ExternalConnection);
    Assertions.ПроверитьИстину(Result.ClientOrdinaryApplication);

    Assertions.ПроверитьЛожь(Result.Privileged);
    Assertions.ПроверитьЛожь(Result.ServerCall);

    Assertions.ПроверитьРавенство(Result.ReturnValuesReuse, 
        Metadata.ObjectProperties.ReturnValuesReuse.DontUse);

EndProcedure // Fact_CommonModuleIHLCommonUse()

Procedure Fact_CommonModuleIHLDataComposition() Export

    Result = Metadata.CommonModules.Find("IHL_DataComposition");

    Assertions.ПроверитьТип(Result, "MetadataObject");
     
    Assertions.ПроверитьЛожь(Result.Global);

    Assertions.ПроверитьЛожь(Result.ClientManagedApplication);
    Assertions.ПроверитьИстину(Result.Server);
    Assertions.ПроверитьИстину(Result.ExternalConnection);
    Assertions.ПроверитьИстину(Result.ClientOrdinaryApplication);

    Assertions.ПроверитьЛожь(Result.Privileged);
    Assertions.ПроверитьЛожь(Result.ServerCall);

    Assertions.ПроверитьРавенство(Result.ReturnValuesReuse, 
        Metadata.ObjectProperties.ReturnValuesReuse.DontUse);


EndProcedure // Fact_CommonModuleIHLDataComposition()

Procedure Fact_CommonModuleIHLCommonUseClientServer() Export
        
    Result = Metadata.CommonModules.Find("IHL_CommonUseClientServer");

    Assertions.ПроверитьТип(Result, "MetadataObject");
     
    Assertions.ПроверитьЛожь(Result.Global);

    Assertions.ПроверитьИстину(Result.ClientManagedApplication);
    Assertions.ПроверитьИстину(Result.Server);
    Assertions.ПроверитьИстину(Result.ExternalConnection);
    Assertions.ПроверитьИстину(Result.ClientOrdinaryApplication);

    Assertions.ПроверитьЛожь(Result.Privileged);
    Assertions.ПроверитьЛожь(Result.ServerCall);

    Assertions.ПроверитьРавенство(Result.ReturnValuesReuse, 
        Metadata.ObjectProperties.ReturnValuesReuse.DontUse);

EndProcedure // Fact_CommonModuleIHLCommonUseClientServer()

Procedure Fact_DataProcessorDataProcessorJSON() Export
    
    Result = Metadata.DataProcessors.Find("DataProcessorJSON");

    Assertions.ПроверитьТип(Result, "MetadataObject");
    
EndProcedure // Fact_DataProcessorDataProcessorJSON()

#КонецОбласти // TestCases