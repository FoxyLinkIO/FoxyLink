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
    
    DataCompositionTemplate = IHLDataComposition.NewDataCompositionTemplateParameters();
    DataCompositionTemplate.Schema   = DataCompositionSchema;
    DataCompositionTemplate.Template = DataCompositionSchema.DefaultSettings;
    
    OutputParameters = IHLDataComposition.NewOutputParameters();
    OutputParameters.DCTParameters = DataCompositionTemplate;
    OutputParameters.CanUseExternalFunctions = True;
    
    StreamObject = DataProcessors.DataProcessorJSON.Create();
    StreamObject.Initialize();
    StreamObject.WriteStartObject();
    
    IHLDataComposition.Output(Undefined, StreamObject, OutputParameters, True);
    
    StreamObject.WriteEndObject();
    Result = StreamObject.Close();
    
    Assertions.ПроверитьРавенство(Result, "{}");
    
    
    StreamObject = DataProcessors.DataProcessorJSON.Create();
    StreamObject.Initialize();
    StreamObject.WriteStartObject();
    
    IHLDataComposition.Output(Undefined, StreamObject, OutputParameters, False);
    
    StreamObject.WriteEndObject();
    Result = StreamObject.Close();;

    Assertions.ПроверитьРавенство(Result, "{}");
    
EndProcedure // Fact_EmptyDataCompositionSchema() 

Procedure Fact_OneLevelDetailRecord() Export
    
    BenchmarkData = "{
        |""Data"": [
        |{
        |""ЭтоXMLСтрока"": ""3c4fbca9-a4ec-11e6-830d-ac220b83ed61"",
        |""Код"": 1,
        |""ИмяПредопределенныхДанных"": ""ПредопределенноеЗначение1"",
        |""Наименование"": ""Предопределенное значение"",
        |""ПометкаУдаления"": false,
        |""РеквизитБулево"": false,
        |""Предопределенный"": true,
        |""РеквизитПеречисление"": """"
        |}
        |]
        |}";

    VerifyAssertion("Тест_Одна_Дет_Запись", "transfer", BenchmarkData);
    
EndProcedure // Fact_OneLevelDetailRecord()

Procedure Fact_OneLevelDetailRecords() Export

    BenchmarkData = "{
        |""Data"": [
        |{
        |""Наименование"": ""Предопределенное значение"",
        |""ПометкаУдаления"": false,
        |""РеквизитБулево"": false,
        |""Код"": 1,
        |""Ссылка"": ""3c4fbca9-a4ec-11e6-830d-ac220b83ed61""
        |},
        |{
        |""Наименование"": ""Простое значение №1"",
        |""ПометкаУдаления"": false,
        |""РеквизитБулево"": true,
        |""Код"": 2,
        |""Ссылка"": ""85bb6509-a4f5-11e6-830d-ac220b83ed61""
        |}
        |]
        |}";
        
    VerifyAssertion("Тест_Две_Дет_Записи", "transfer", BenchmarkData);

EndProcedure // Fact_OneLevelDetailRecords()

Procedure Fact_OLDetailRecord_SLDeatailRecord() Export

    BenchmarkData = "{
        |""Data"": [
        |{
        |""СтрокаXML"": ""3c4fbca9-a4ec-11e6-830d-ac220b83ed61"",
        |""Код"": 1,
        |""Наименование"": ""Предопределенное значение"",
        |""Предопределенный"": true,
        |""РеквизитБулево"": false,
        |""ПометкаУдаления"": false,
        |""Group"": [
        |{
        |""СтрокаXML"": ""3c4fbca9-a4ec-11e6-830d-ac220b83ed61"",
        |""Код"": 1,
        |""Наименование"": ""Предопределенное значение"",
        |""Предопределенный"": true,
        |""РеквизитБулево"": false,
        |""ПометкаУдаления"": false
        |}
        |]
        |},
        |{
        |""СтрокаXML"": ""85bb6509-a4f5-11e6-830d-ac220b83ed61"",
        |""Код"": 2,
        |""Наименование"": ""Простое значение №1"",
        |""Предопределенный"": false,
        |""РеквизитБулево"": true,
        |""ПометкаУдаления"": false,
        |""Group"": [
        |{
        |""СтрокаXML"": ""85bb6509-a4f5-11e6-830d-ac220b83ed61"",
        |""Код"": 2,
        |""Наименование"": ""Простое значение №1"",
        |""Предопределенный"": false,
        |""РеквизитБулево"": true,
        |""ПометкаУдаления"": false
        |}
        |]
        |}
        |]
        |}";
        
    VerifyAssertion("Тест_Иерархия_Дет_Записей", "transfer", BenchmarkData);
        
EndProcedure // Fact_OLDetailRecord_SLDeatailRecord()

Procedure Fact_OneLevelGrouping() Export

    BenchmarkData = "{
        |""Data"": [
        |{
        |""Ссылка"": ""3c4fbca9-a4ec-11e6-830d-ac220b83ed61""
        |},
        |{
        |""Ссылка"": ""85bb6509-a4f5-11e6-830d-ac220b83ed61""
        |}
        |]
        |}";
        
    VerifyAssertion("Тест_Одна_Группировка", "transfer", BenchmarkData);

EndProcedure // Fact_OneLevelGrouping()

Procedure Fact_OLGrouping_SLDetailRecords() Export

    BenchmarkData = "{
        |""Data"": [
        |{
        |""СсылкаUUID"": ""3c4fbca9-a4ec-11e6-830d-ac220b83ed61"",
        |""Details"": [
        |{
        |""ИмяПредопределенныхДанных"": ""ПредопределенноеЗначение1"",
        |""Код"": 1,
        |""Наименование"": ""Предопределенное значение"",
        |""ПометкаУдаления"": false,
        |""Предопределенный"": true,
        |""РеквизитБулево"": false
        |}
        |]
        |},
        |{
        |""СсылкаUUID"": ""85bb6509-a4f5-11e6-830d-ac220b83ed61"",
        |""Details"": [
        |{
        |""ИмяПредопределенныхДанных"": """",
        |""Код"": 2,
        |""Наименование"": ""Простое значение №1"",
        |""ПометкаУдаления"": false,
        |""Предопределенный"": false,
        |""РеквизитБулево"": true
        |}
        |]
        |}
        |]
        |}";

    VerifyAssertion("Тест_Группировка_И_Дет", "transfer", BenchmarkData);
        
EndProcedure // Fact_OLGrouping_SLDetailRecords()

Procedure Fact_OLGrouping_SLDetailRecords_SLGrouping_ThirdLevelDetailRecords() Export

    BenchmarkData = "{
        |""Data"": [
        |{
        |""СсылкаUUID"": ""85bb650f-a4f5-11e6-830d-ac220b83ed61"",
        |""Ссылка"": ""85bb650f-a4f5-11e6-830d-ac220b83ed61"",
        |""Details"": [
        |{
        |""ИмяПредопределенныхДанных"": """",
        |""Код"": 3,
        |""Наименование"": ""Наименование #2"",
        |""ПометкаУдаления"": false,
        |""Предопределенный"": false,
        |""РеквизитБулево"": false
        |}
        |],
        |""Reference"": [
        |{
        |""Ссылка"": ""85bb650f-a4f5-11e6-830d-ac220b83ed61"",
        |""Наименование"": ""Наименование #2"",
        |""RefDetails"": [
        |{
        |""ИмяПредопределенныхДанных"": """",
        |""Код"": 3,
        |""ПометкаУдаления"": false,
        |""Предопределенный"": false,
        |""РеквизитБулево"": false
        |}
        |]
        |}
        |]
        |},
        |{
        |""СсылкаUUID"": ""3c4fbca9-a4ec-11e6-830d-ac220b83ed61"",
        |""Ссылка"": ""3c4fbca9-a4ec-11e6-830d-ac220b83ed61"",
        |""Details"": [
        |{
        |""ИмяПредопределенныхДанных"": ""ПредопределенноеЗначение1"",
        |""Код"": 1,
        |""Наименование"": ""Предопределенное значение"",
        |""ПометкаУдаления"": false,
        |""Предопределенный"": true,
        |""РеквизитБулево"": false
        |}
        |],
        |""Reference"": [
        |{
        |""Ссылка"": ""3c4fbca9-a4ec-11e6-830d-ac220b83ed61"",
        |""Наименование"": ""Предопределенное значение"",
        |""RefDetails"": [
        |{
        |""ИмяПредопределенныхДанных"": ""ПредопределенноеЗначение1"",
        |""Код"": 1,
        |""ПометкаУдаления"": false,
        |""Предопределенный"": true,
        |""РеквизитБулево"": false
        |}
        |]
        |}
        |]
        |},
        |{
        |""СсылкаUUID"": ""85bb6509-a4f5-11e6-830d-ac220b83ed61"",
        |""Ссылка"": ""85bb6509-a4f5-11e6-830d-ac220b83ed61"",
        |""Details"": [
        |{
        |""ИмяПредопределенныхДанных"": """",
        |""Код"": 2,
        |""Наименование"": ""Простое значение №1"",
        |""ПометкаУдаления"": false,
        |""Предопределенный"": false,
        |""РеквизитБулево"": true
        |}
        |],
        |""Reference"": [
        |{
        |""Ссылка"": ""85bb6509-a4f5-11e6-830d-ac220b83ed61"",
        |""Наименование"": ""Простое значение №1"",
        |""RefDetails"": [
        |{
        |""ИмяПредопределенныхДанных"": """",
        |""Код"": 2,
        |""ПометкаУдаления"": false,
        |""Предопределенный"": false,
        |""РеквизитБулево"": true
        |}
        |]
        |}
        |]
        |}
        |]
        |}";
        
    VerifyAssertion("Тест_Груп2_Дет_Груп_Дет", "transfer", BenchmarkData);

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

    VerifyAssertion("Тест_Рес_Гр1_Дет11_Гр111", "transfer", BenchmarkData);

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

    VerifyAssertion("Тест_РесурсВложенВТаблицу", "transfer", BenchmarkData);

EndProcedure // Fact_OLGrouping_SLGrouping_TLDetailRecords_NestedResource()

#EndRegion // TestCases

#Region ServiceProceduresAndFunctions

Procedure VerifyAssertion(CatalogRefName, CommandName, BenchmarkData)
    
    Query = New Query;
    Query.Text = "
        |SELECT
        |  UpdateExpressНастройкиОбменовКоманды.СхемаКомпоновкиДанных AS СхемаКомпоновкиДанных,
        |  UpdateExpressНастройкиОбменовКоманды.НастройкиКомпоновкиДанных AS НастройкиКомпоновкиДанных,
        |  UpdateExpressНастройкиОбменовКоманды.Наименование AS Наименование,
        |  UpdateExpressНастройкиОбменов.Description AS Description
        |FROM
        |  Catalog.UpdateExpressНастройкиОбменов AS UpdateExpressНастройкиОбменов
        |      LEFT JOIN Catalog.UpdateExpressНастройкиОбменов.Команды AS UpdateExpressНастройкиОбменовКоманды
        |      ON UpdateExpressНастройкиОбменов.Команды.Ref = UpdateExpressНастройкиОбменовКоманды.Ref
        |WHERE
        |  UpdateExpressНастройкиОбменовКоманды.Наименование = &CommandName
        |  AND UpdateExpressНастройкиОбменов.Description = &Description
        |";
    Query.SetParameter("Description", CatalogRefName);
    Query.SetParameter("CommandName", CommandName);
    QuerySettings = Query.Execute().Select();
    QuerySettings.Next();
        
    DataCompositionSchema = QuerySettings.СхемаКомпоновкиДанных.Get();
    SettingsComposer = New DataCompositionSettingsComposer;
    IHLDataComposition.InitSettingsComposer(Undefined, SettingsComposer, 
        DataCompositionSchema, 
        PutToTempStorage(QuerySettings.НастройкиКомпоновкиДанных.Get()));
        
    
    DataCompositionTemplate = IHLDataComposition.NewDataCompositionTemplateParameters();
    DataCompositionTemplate.Schema   = DataCompositionSchema;
    DataCompositionTemplate.Template = SettingsComposer.GetSettings();
    
    OutputParameters = IHLDataComposition.NewOutputParameters();
    OutputParameters.DCTParameters = DataCompositionTemplate;
    OutputParameters.CanUseExternalFunctions = True;
    
    StreamObject = DataProcessors.DataProcessorJSON.Create();
    StreamObject.Initialize();
    StreamObject.WriteStartObject();
    
    IHLDataComposition.Output(Undefined, StreamObject, OutputParameters, True);
    
    StreamObject.WriteEndObject();
    Result = StreamObject.Close();
    
    Assertions.ПроверитьРавенство(DeleteCRLF(Result), DeleteCRLF(BenchmarkData));
    
    
    StreamObject = DataProcessors.DataProcessorJSON.Create();
    StreamObject.Initialize();
    StreamObject.WriteStartObject();
    
    IHLDataComposition.Output(Undefined, StreamObject, OutputParameters, False);
    
    StreamObject.WriteEndObject();
    Result = StreamObject.Close();;

    Assertions.ПроверитьРавенство(DeleteCRLF(Result), DeleteCRLF(BenchmarkData));
       
EndProcedure // VerifyAssertion()

Function DeleteCRLF(Val String)
    
    String = StrReplace(String, Chars.CR, "");
    String = StrReplace(String, Chars.LF, "");
    String = StrReplace(String, Chars.CR + Chars.LF, "");
    Return String;
    
EndFunction // DeleteCRLF()

#EndRegion // ServiceProceduresAndFunctions
