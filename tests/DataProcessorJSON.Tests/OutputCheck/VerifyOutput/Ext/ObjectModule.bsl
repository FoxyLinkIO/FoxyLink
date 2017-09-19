Var CoreContext;
Var Assertions;

#Region ServiceInterface

Procedure Инициализация(CoreContextParam) Export
    CoreContext = CoreContextParam;
    Assertions = CoreContext.Плагин("БазовыеУтверждения");
EndProcedure // Инициализация()

Procedure ЗаполнитьНаборТестов(TestsSet) Export
    
    TestsSet.Добавить("Fact_EmptyDataCompositionSchema");
    TestsSet.Добавить("Fact_OneLevelDetailRecord");
    TestsSet.Добавить("Fact_OneLevelDetailRecords");
    TestsSet.Добавить("Fact_OLDetailRecord_SLDeatailRecord");
    TestsSet.Добавить("Fact_OneLevelGrouping");
    TestsSet.Добавить("Fact_OLGrouping_SLDetailRecords");
    TestsSet.Добавить("Fact_OLGrouping_SLDetailRecords_SLGrouping_ThirdLevelDetailRecords");
    TestsSet.Добавить("Fact_OLGrouping_SLDetailRecords_TLGrouping_WithResource");
    TestsSet.Добавить("Fact_OLGrouping_SLGrouping_TLDetailRecords_NestedResource");

EndProcedure // ЗаполнитьНаборТестов()

#EndRegion // ServiceInterface

#Region TestCases

Procedure Fact_EmptyDataCompositionSchema() Export
    
    DataCompositionSchema = New DataCompositionSchema;
    
    DataCompositionTemplate = IHL_DataComposition.NewDataCompositionTemplateParameters();
    DataCompositionTemplate.Schema   = DataCompositionSchema;
    DataCompositionTemplate.Template = DataCompositionSchema.DefaultSettings;
    
    OutputParameters = IHL_DataComposition.NewOutputParameters();
    OutputParameters.DCTParameters = DataCompositionTemplate;
    OutputParameters.CanUseExternalFunctions = True;
    
    StreamObject = DataProcessors.DataProcessorJSON.Create();
    StreamObject.Initialize();
    
    IHL_DataComposition.Output(Undefined, StreamObject, OutputParameters);
    
    Result = StreamObject.Close();
    
    Assertions.ПроверитьРавенство(Result, "{}");
        
EndProcedure // Fact_EmptyDataCompositionSchema() 

Procedure Fact_OneLevelDetailRecord() Export
    
    BenchmarkData = "{
        |""Data"": [
        |{
        |""Predefined"": true,
        |""PredefinedObjectName"": ""ПредопределенноеЗначение1"",
        |""DeletionMark"": false,
        |""Code"": 1,
        |""Description"": ""Предопределенное значение"",
        |""XMLString"": ""3c4fbca9-a4ec-11e6-830d-ac220b83ed61"",
        |""BooleanAttribute"": false,
        |""EnumAttribute"": """"
        |}
        |]
        |}
        |";

    VerifyAssertion("OneLevelDetailedRecord", "READ", BenchmarkData);
    
EndProcedure // Fact_OneLevelDetailRecord()

Procedure Fact_OneLevelDetailRecords() Export

    BenchmarkData = "{
        |""Data"": [
        |{
        |""Predefined"": true,
        |""PredefinedObjectName"": ""ПредопределенноеЗначение1"",
        |""DeletionMark"": false,
        |""Code"": 1,
        |""Description"": ""Предопределенное значение"",
        |""XMLString"": ""3c4fbca9-a4ec-11e6-830d-ac220b83ed61"",
        |""BooleanAttribute"": false,
        |""EnumAttribute"": """"
        |},
        |{
        |""Predefined"": false,
        |""PredefinedObjectName"": """",
        |""DeletionMark"": false,
        |""Code"": 2,
        |""Description"": ""Простое значение №1"",
        |""XMLString"": ""85bb6509-a4f5-11e6-830d-ac220b83ed61"",
        |""BooleanAttribute"": true,
        |""EnumAttribute"": ""ЗначениеПеречисления2""
        |},
        |{
        |""Predefined"": false,
        |""PredefinedObjectName"": """",
        |""DeletionMark"": false,
        |""Code"": 3,
        |""Description"": ""Наименование #2"",
        |""XMLString"": ""85bb650f-a4f5-11e6-830d-ac220b83ed61"",
        |""BooleanAttribute"": false,
        |""EnumAttribute"": """"
        |}
        |]
        |}
        |";
        
    VerifyAssertion("OneLevelDetailedRecords", "READ", BenchmarkData);

EndProcedure // Fact_OneLevelDetailRecords()

Procedure Fact_OLDetailRecord_SLDeatailRecord() Export

    BenchmarkData = "{
        |""Data"": [
        |{
        |""СтрокаXML"": ""3c4fbca9-a4ec-11e6-830d-ac220b83ed61"",
        |""Code"": 1,
        |""Description"": ""Предопределенное значение"",
        |""Predefined"": true,
        |""РеквизитБулево"": false,
        |""DeletionMark"": false,
        |""Group"": [
        |{
        |""СтрокаXML"": ""3c4fbca9-a4ec-11e6-830d-ac220b83ed61"",
        |""Code"": 1,
        |""Description"": ""Предопределенное значение"",
        |""Predefined"": true,
        |""РеквизитБулево"": false,
        |""DeletionMark"": false
        |}
        |]
        |},
        |{
        |""СтрокаXML"": ""85bb6509-a4f5-11e6-830d-ac220b83ed61"",
        |""Code"": 2,
        |""Description"": ""Простое значение №1"",
        |""Predefined"": false,
        |""РеквизитБулево"": true,
        |""DeletionMark"": false,
        |""Group"": [
        |{
        |""СтрокаXML"": ""85bb6509-a4f5-11e6-830d-ac220b83ed61"",
        |""Code"": 2,
        |""Description"": ""Простое значение №1"",
        |""Predefined"": false,
        |""РеквизитБулево"": true,
        |""DeletionMark"": false
        |}
        |]
        |}
        |]
        |}";
        
    VerifyAssertion("TwoLevelDetailRecords", "READ", BenchmarkData);
        
EndProcedure // Fact_OLDetailRecord_SLDeatailRecord()

Procedure Fact_OneLevelGrouping() Export

    BenchmarkData = "{
        |""Data"": [
        |{
        |""Reference"": ""3c4fbca9-a4ec-11e6-830d-ac220b83ed61""
        |},
        |{
        |""Reference"": ""85bb6509-a4f5-11e6-830d-ac220b83ed61""
        |}
        |]
        |}";
        
    VerifyAssertion("OneLevelGrouping", "READ", BenchmarkData);

EndProcedure // Fact_OneLevelGrouping()

Procedure Fact_OLGrouping_SLDetailRecords() Export

    BenchmarkData = "{
        |""Data"": [
        |{
        |""СсылкаUUID"": ""3c4fbca9-a4ec-11e6-830d-ac220b83ed61"",
        |""Details"": [
        |{
        |""PredefinedObjectName"": ""ПредопределенноеЗначение1"",
        |""Code"": 1,
        |""Description"": ""Предопределенное значение"",
        |""DeletionMark"": false,
        |""Predefined"": true,
        |""РеквизитБулево"": false
        |}
        |]
        |},
        |{
        |""СсылкаUUID"": ""85bb6509-a4f5-11e6-830d-ac220b83ed61"",
        |""Details"": [
        |{
        |""PredefinedObjectName"": """",
        |""Code"": 2,
        |""Description"": ""Простое значение №1"",
        |""DeletionMark"": false,
        |""Predefined"": false,
        |""РеквизитБулево"": true
        |}
        |]
        |}
        |]
        |}";

    VerifyAssertion("L1Group-L2DetailedRecords", "READ", BenchmarkData);
        
EndProcedure // Fact_OLGrouping_SLDetailRecords()

Procedure Fact_OLGrouping_SLDetailRecords_SLGrouping_ThirdLevelDetailRecords() Export

    BenchmarkData = "{
        |""Data"": [
        |{
        |""СсылкаUUID"": ""85bb650f-a4f5-11e6-830d-ac220b83ed61"",
        |""Reference"": ""85bb650f-a4f5-11e6-830d-ac220b83ed61"",
        |""Details"": [
        |{
        |""PredefinedObjectName"": """",
        |""Code"": 3,
        |""Description"": ""Наименование #2"",
        |""DeletionMark"": false,
        |""Predefined"": false,
        |""РеквизитБулево"": false
        |}
        |],
        |""ReferenceGroup"": [
        |{
        |""Reference"": ""85bb650f-a4f5-11e6-830d-ac220b83ed61"",
        |""Description"": ""Наименование #2"",
        |""RefDetails"": [
        |{
        |""PredefinedObjectName"": """",
        |""Code"": 3,
        |""DeletionMark"": false,
        |""Predefined"": false,
        |""РеквизитБулево"": false
        |}
        |]
        |}
        |]
        |},
        |{
        |""СсылкаUUID"": ""3c4fbca9-a4ec-11e6-830d-ac220b83ed61"",
        |""Reference"": ""3c4fbca9-a4ec-11e6-830d-ac220b83ed61"",
        |""Details"": [
        |{
        |""PredefinedObjectName"": ""ПредопределенноеЗначение1"",
        |""Code"": 1,
        |""Description"": ""Предопределенное значение"",
        |""DeletionMark"": false,
        |""Predefined"": true,
        |""РеквизитБулево"": false
        |}
        |],
        |""ReferenceGroup"": [
        |{
        |""Reference"": ""3c4fbca9-a4ec-11e6-830d-ac220b83ed61"",
        |""Description"": ""Предопределенное значение"",
        |""RefDetails"": [
        |{
        |""PredefinedObjectName"": ""ПредопределенноеЗначение1"",
        |""Code"": 1,
        |""DeletionMark"": false,
        |""Predefined"": true,
        |""РеквизитБулево"": false
        |}
        |]
        |}
        |]
        |},
        |{
        |""СсылкаUUID"": ""85bb6509-a4f5-11e6-830d-ac220b83ed61"",
        |""Reference"": ""85bb6509-a4f5-11e6-830d-ac220b83ed61"",
        |""Details"": [
        |{
        |""PredefinedObjectName"": """",
        |""Code"": 2,
        |""Description"": ""Простое значение №1"",
        |""DeletionMark"": false,
        |""Predefined"": false,
        |""РеквизитБулево"": true
        |}
        |],
        |""ReferenceGroup"": [
        |{
        |""Reference"": ""85bb6509-a4f5-11e6-830d-ac220b83ed61"",
        |""Description"": ""Простое значение №1"",
        |""RefDetails"": [
        |{
        |""PredefinedObjectName"": """",
        |""Code"": 2,
        |""DeletionMark"": false,
        |""Predefined"": false,
        |""РеквизитБулево"": true
        |}
        |]
        |}
        |]
        |}
        |]
        |}";
        
    VerifyAssertion("Lv1G-Lv2D-Lv2G-Lv3D", "READ", BenchmarkData);

EndProcedure // Fact_OLGrouping_SLDetailRecords_SLGrouping_ThirdLevelDetailRecords()

Procedure Fact_OLGrouping_SLDetailRecords_TLGrouping_WithResource() Export

    BenchmarkData = "{
        |""Group"": [
        |{
        |""ПростойСправочник"": ""85bb650f-a4f5-11e6-830d-ac220b83ed61"",
        |""РесурсЧислоОстаток"": 102,
        |""Group2"": [
        |{
        |""Спр1UUID"": ""85bb650f-a4f5-11e6-830d-ac220b83ed61"",
        |""Спр2UUID"": ""bc63d7b8-a597-11e6-830e-ac220b83ed61"",
        |""ПростойСправочник2"": ""bc63d7b8-a597-11e6-830e-ac220b83ed61"",
        |""РесурсЧислоОстаток"": 51,
        |""Group3"": [
        |{
        |""ПростойСправочник2"": ""bc63d7b8-a597-11e6-830e-ac220b83ed61"",
        |""РесурсЧислоОстаток"": 51
        |}
        |]
        |},
        |{
        |""Спр1UUID"": ""85bb650f-a4f5-11e6-830d-ac220b83ed61"",
        |""Спр2UUID"": ""bc63d7c2-a597-11e6-830e-ac220b83ed61"",
        |""ПростойСправочник2"": ""bc63d7c2-a597-11e6-830e-ac220b83ed61"",
        |""РесурсЧислоОстаток"": 51,
        |""Group3"": [
        |{
        |""ПростойСправочник2"": ""bc63d7c2-a597-11e6-830e-ac220b83ed61"",
        |""РесурсЧислоОстаток"": 51
        |}
        |]
        |}
        |]
        |},
        |{
        |""ПростойСправочник"": ""3c4fbca9-a4ec-11e6-830d-ac220b83ed61"",
        |""РесурсЧислоОстаток"": 11,
        |""Group2"": [
        |{
        |""Спр1UUID"": ""3c4fbca9-a4ec-11e6-830d-ac220b83ed61"",
        |""Спр2UUID"": ""bc63d7b8-a597-11e6-830e-ac220b83ed61"",
        |""ПростойСправочник2"": ""bc63d7b8-a597-11e6-830e-ac220b83ed61"",
        |""РесурсЧислоОстаток"": 1,
        |""Group3"": [
        |{
        |""ПростойСправочник2"": ""bc63d7b8-a597-11e6-830e-ac220b83ed61"",
        |""РесурсЧислоОстаток"": 1
        |}
        |]
        |},
        |{
        |""Спр1UUID"": ""3c4fbca9-a4ec-11e6-830d-ac220b83ed61"",
        |""Спр2UUID"": ""bc63d7b9-a597-11e6-830e-ac220b83ed61"",
        |""ПростойСправочник2"": ""bc63d7b9-a597-11e6-830e-ac220b83ed61"",
        |""РесурсЧислоОстаток"": 6,
        |""Group3"": [
        |{
        |""ПростойСправочник2"": ""bc63d7b9-a597-11e6-830e-ac220b83ed61"",
        |""РесурсЧислоОстаток"": 6
        |}
        |]
        |},
        |{
        |""Спр1UUID"": ""3c4fbca9-a4ec-11e6-830d-ac220b83ed61"",
        |""Спр2UUID"": ""bc63d7c2-a597-11e6-830e-ac220b83ed61"",
        |""ПростойСправочник2"": ""bc63d7c2-a597-11e6-830e-ac220b83ed61"",
        |""РесурсЧислоОстаток"": 4,
        |""Group3"": [
        |{
        |""ПростойСправочник2"": ""bc63d7c2-a597-11e6-830e-ac220b83ed61"",
        |""РесурсЧислоОстаток"": 4
        |}
        |]
        |}
        |]
        |},
        |{
        |""ПростойСправочник"": ""85bb6509-a4f5-11e6-830d-ac220b83ed61"",
        |""РесурсЧислоОстаток"": 68,
        |""Group2"": [
        |{
        |""Спр1UUID"": ""85bb6509-a4f5-11e6-830d-ac220b83ed61"",
        |""Спр2UUID"": ""bc63d7b8-a597-11e6-830e-ac220b83ed61"",
        |""ПростойСправочник2"": ""bc63d7b8-a597-11e6-830e-ac220b83ed61"",
        |""РесурсЧислоОстаток"": 57,
        |""Group3"": [
        |{
        |""ПростойСправочник2"": ""bc63d7b8-a597-11e6-830e-ac220b83ed61"",
        |""РесурсЧислоОстаток"": 57
        |}
        |]
        |},
        |{
        |""Спр1UUID"": ""85bb6509-a4f5-11e6-830d-ac220b83ed61"",
        |""Спр2UUID"": ""bc63d7b9-a597-11e6-830e-ac220b83ed61"",
        |""ПростойСправочник2"": ""bc63d7b9-a597-11e6-830e-ac220b83ed61"",
        |""РесурсЧислоОстаток"": 11,
        |""Group3"": [
        |{
        |""ПростойСправочник2"": ""bc63d7b9-a597-11e6-830e-ac220b83ed61"",
        |""РесурсЧислоОстаток"": 11
        |}
        |]
        |}
        |]
        |}
        |]
        |}";

    VerifyAssertion("Resources+Lv1G-Lv2D-Lv3G", "READ", BenchmarkData);

EndProcedure // Fact_OLGrouping_SLDetailRecords_TLGrouping_WithResource()

Procedure Fact_OLGrouping_SLGrouping_TLDetailRecords_NestedResource() Export

    BenchmarkData = "{
        |""Data"": [
        |{
        |""Дата"": ""2016-11-08T11:49:17"",
        |""Номер"": ""000000004"",
        |""СоставРеквизитЧисло"": 11,
        |""Goods"": [
        |{
        |""СоставПростойСправочник2Description"": ""Ноутбук"",
        |""СоставРеквизитЧисло"": 1,
        |""Details"": [
        |{
        |""СоставРеквизитЧисло"": 1
        |}
        |]
        |},
        |{
        |""СоставПростойСправочник2Description"": ""Видео-карта"",
        |""СоставРеквизитЧисло"": 4,
        |""Details"": [
        |{
        |""СоставРеквизитЧисло"": 4
        |}
        |]
        |},
        |{
        |""СоставПростойСправочник2Description"": ""Винчестер"",
        |""СоставРеквизитЧисло"": 6,
        |""Details"": [
        |{
        |""СоставРеквизитЧисло"": 6
        |}
        |]
        |}
        |]
        |}
        |]
        |}";

    VerifyAssertion("ResInTable-Lv1G-Lv2G-Lv3D", "READ", BenchmarkData);

EndProcedure // Fact_OLGrouping_SLGrouping_TLDetailRecords_NestedResource()

#EndRegion // TestCases

#Region ServiceProceduresAndFunctions

Procedure VerifyAssertion(CatalogRefName, MethodName, BenchmarkData)
    
    Query = New Query;
    Query.Text = "
        |SELECT
        |  IHL_ExchangeSettingsMethods.DataCompositionSchema AS DataCompositionSchema,
        |  IHL_ExchangeSettingsMethods.DataCompositionSettings AS DataCompositionSettings,
        |  IHL_ExchangeSettingsMethods.CanUseExternalFunctions AS CanUseExternalFunctions,
        |  IHL_ExchangeSettings.Description AS Description
        |FROM
        |  Catalog.IHL_ExchangeSettings AS IHL_ExchangeSettings
        |      
        |LEFT JOIN Catalog.IHL_ExchangeSettings.Methods AS IHL_ExchangeSettingsMethods
        |ON  IHL_ExchangeSettingsMethods.Ref    = IHL_ExchangeSettings.Ref
        |AND IHL_ExchangeSettingsMethods.Method = &Method
        |
        |WHERE
        |   IHL_ExchangeSettings.Description = &Description
        |";
    Query.SetParameter("Method", Catalogs.IHL_Methods.FindByDescription(MethodName));
    Query.SetParameter("Description", CatalogRefName);
    QuerySettings = Query.Execute().Select();
    QuerySettings.Next();
        
    DataCompositionSchema = QuerySettings.DataCompositionSchema.Get();
    SettingsComposer = New DataCompositionSettingsComposer;
    IHL_DataComposition.InitSettingsComposer(Undefined, SettingsComposer, 
        DataCompositionSchema, 
        PutToTempStorage(QuerySettings.DataCompositionSettings.Get()));
        
    
    DataCompositionTemplate = IHL_DataComposition.NewDataCompositionTemplateParameters();
    DataCompositionTemplate.Schema   = DataCompositionSchema;
    DataCompositionTemplate.Template = SettingsComposer.GetSettings();
    
    OutputParameters = IHL_DataComposition.NewOutputParameters();
    OutputParameters.DCTParameters = DataCompositionTemplate;
    OutputParameters.CanUseExternalFunctions = QuerySettings.CanUseExternalFunctions;
    
    StreamObject = DataProcessors.DataProcessorJSON.Create();
    StreamObject.Initialize();
    
    IHL_DataComposition.Output(Undefined, StreamObject, OutputParameters);
    
    Result = StreamObject.Close();
    
    Assertions.ПроверитьРавенство(DeleteCRLF(Result), DeleteCRLF(BenchmarkData));
        
EndProcedure // VerifyAssertion()

Function DeleteCRLF(Val String)
    
    String = StrReplace(String, Chars.CR, "");
    String = StrReplace(String, Chars.LF, "");
    String = StrReplace(String, Chars.CR + Chars.LF, "");
    Return String;
    
EndFunction // DeleteCRLF()

#EndRegion // ServiceProceduresAndFunctions
