Var CoreContext;
Var Assertions;

#Region ServiceInterface

Procedure Инициализация(CoreContextParam) Export
    CoreContext = CoreContextParam;
    Assertions = CoreContext.Плагин("БазовыеУтверждения");
EndProcedure // Инициализация()

Procedure ЗаполнитьНаборТестов(TestsSet) Export
    
    TestsSet.Добавить("Fact_FastOutputStringValue");
    TestsSet.Добавить("Fact_SequentialOutputStringValue");
    TestsSet.Добавить("Fact_FastOutputNumberValue");
    TestsSet.Добавить("Fact_SequentialOutputNumberValue");
    TestsSet.Добавить("Fact_FastOutputTrueValue");
    TestsSet.Добавить("Fact_SequentialOutputTrueValue");
    TestsSet.Добавить("Fact_FastOutputFalseValue");
    TestsSet.Добавить("Fact_SequentialOutputFalseValue");
    TestsSet.Добавить("Fact_FastOutputNullValue");
    TestsSet.Добавить("Fact_SequentialOutputNullValue");
    TestsSet.Добавить("Fact_FastOutputObjectValue");
    TestsSet.Добавить("Fact_SequentialOutputObjectValue");

EndProcedure // ЗаполнитьНаборТестов()

#EndRegion // ServiceInterface

#Region TestCases

Procedure Fact_FastOutputStringValue() Export
    
    BenchmarkData = """This is string value""";

    VerifyAssertion("StringValueOutput", "READ", BenchmarkData, False);
    
EndProcedure // Fact_FastOutputStringValue()

Procedure Fact_SequentialOutputStringValue() Export
    
    BenchmarkData = """This is string value""";

    VerifyAssertion("StringValueOutput", "READ", BenchmarkData, True);
    
EndProcedure // Fact_SequentialOutputStringValue()

Procedure Fact_FastOutputNumberValue() Export
    
    BenchmarkData = 15.6464669489979796464313546498;

    VerifyAssertion("NumberValueOutput", "READ", BenchmarkData, False);
    
EndProcedure // Fact_FastOutputNumberValue()

Procedure Fact_SequentialOutputNumberValue() Export
    
    BenchmarkData = 15.6464669489979796464313546498;

    VerifyAssertion("NumberValueOutput", "READ", BenchmarkData, True);
    
EndProcedure // Fact_SequentialOutputNumberValue()

Procedure Fact_FastOutputTrueValue() Export
    
    BenchmarkData = True;

    VerifyAssertion("TrueValueOutput", "READ", BenchmarkData, False);
    
EndProcedure // Fact_FastOutputTrueValue()

Procedure Fact_SequentialOutputTrueValue() Export
    
    BenchmarkData = True;

    VerifyAssertion("TrueValueOutput", "READ", BenchmarkData, True);
    
EndProcedure // Fact_SequentialOutputTrueValue()

Procedure Fact_FastOutputFalseValue() Export
    
    BenchmarkData = False;

    VerifyAssertion("FalseValueOutput", "READ", BenchmarkData, False);
    
EndProcedure // Fact_FastOutputFalseValue()

Procedure Fact_SequentialOutputFalseValue() Export
    
    BenchmarkData = False;

    VerifyAssertion("FalseValueOutput", "READ", BenchmarkData, True);
    
EndProcedure // Fact_SequentialOutputFalseValue()

Procedure Fact_FastOutputNullValue() Export
    
    BenchmarkData = Null;

    VerifyAssertion("NullValueOutput", "READ", BenchmarkData, False);
    
EndProcedure // Fact_FastOutputNullValue()

Procedure Fact_SequentialOutputNullValue() Export
    
    BenchmarkData = Null;

    VerifyAssertion("NullValueOutput", "READ", BenchmarkData, True);
    
EndProcedure // Fact_SequentialOutputNullValue()

Procedure Fact_FastOutputObjectValue() Export
    
    BenchmarkData = "{
        |""Id"": ""1231"",
        |""SyncToken"": ""SyncToken"",
        |""Name"": ""Garden Supplies"",
        |""Sku"": ""01254001"",
        |""ItemCategoryType"": ""Goods"",
        |""PurchaseCost"": 101,
        |""MetaData"": {
        |""CreateTime"": ""2013-05-05T00:00:00"",
        |""LastUpdate"": ""2017-05-05T00:00:00""
        |},
        |""IncomeAccountRef"": {
        |""value"": 12313,
        |""name"": ""pikabu""
        |}
        |}
        |";

    VerifyAssertion("ObjectValueOutput", "READ", BenchmarkData, False);
    
EndProcedure // Fact_FastOutputObjectValue()

Procedure Fact_SequentialOutputObjectValue() Export
    
    BenchmarkData = "{
        |""Id"": ""1231"",
        |""SyncToken"": ""SyncToken"",
        |""Name"": ""Garden Supplies"",
        |""Sku"": ""01254001"",
        |""ItemCategoryType"": ""Goods"",
        |""PurchaseCost"": 101,
        |""MetaData"": {
        |""CreateTime"": ""2013-05-05T00:00:00"",
        |""LastUpdate"": ""2017-05-05T00:00:00""
        |},
        |""IncomeAccountRef"": {
        |""value"": 12313,
        |""name"": ""pikabu""
        |}
        |}
        |";

    VerifyAssertion("ObjectValueOutput", "READ", BenchmarkData, True);
    
EndProcedure // Fact_SequentialOutputObjectValue()



//Procedure Fact_OneLevelDetailRecords() Export

//    BenchmarkData = "{
//        |""Data"": [
//        |{
//        |""Predefined"": true,
//        |""PredefinedObjectName"": ""ПредопределенноеЗначение1"",
//        |""DeletionMark"": false,
//        |""Code"": 1,
//        |""Description"": ""Предопределенное значение"",
//        |""XMLString"": ""3c4fbca9-a4ec-11e6-830d-ac220b83ed61"",
//        |""BooleanAttribute"": false,
//        |""EnumAttribute"": """"
//        |},
//        |{
//        |""Predefined"": false,
//        |""PredefinedObjectName"": """",
//        |""DeletionMark"": false,
//        |""Code"": 2,
//        |""Description"": ""Простое значение №1"",
//        |""XMLString"": ""85bb6509-a4f5-11e6-830d-ac220b83ed61"",
//        |""BooleanAttribute"": true,
//        |""EnumAttribute"": ""ЗначениеПеречисления2""
//        |},
//        |{
//        |""Predefined"": false,
//        |""PredefinedObjectName"": """",
//        |""DeletionMark"": false,
//        |""Code"": 3,
//        |""Description"": ""Наименование #2"",
//        |""XMLString"": ""85bb650f-a4f5-11e6-830d-ac220b83ed61"",
//        |""BooleanAttribute"": false,
//        |""EnumAttribute"": """"
//        |}
//        |]
//        |}
//        |";
//        
//    VerifyAssertion("OneLevelDetailedRecords", "READ", BenchmarkData);

//EndProcedure // Fact_OneLevelDetailRecords()

#EndRegion // TestCases

#Region ServiceProceduresAndFunctions

Procedure VerifyAssertion(CatalogRefName, MethodName, BenchmarkData, 
    SaveResources)
    
    Query = New Query;
    Query.Text = "
        |SELECT
        |   IHL_ExchangeSettingsMethods.APISchema               AS APISchema,
        |   IHL_ExchangeSettingsMethods.DataCompositionSchema   AS DataCompositionSchema,
        |   IHL_ExchangeSettingsMethods.DataCompositionSettings AS DataCompositionSettings,
        |   IHL_ExchangeSettingsMethods.CanUseExternalFunctions AS CanUseExternalFunctions,
        |   IHL_ExchangeSettings.Description AS Description
        |FROM
        |   Catalog.IHL_ExchangeSettings AS IHL_ExchangeSettings
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
    StreamObject.Initialize(QuerySettings.APISchema.Get());
    
    IHL_DataComposition.Output(Undefined, StreamObject, OutputParameters, SaveResources);
    
    Result = StreamObject.Close();
    
    If TypeOf(BenchmarkData) = Type("Number") Then
        Assertions.ПроверитьРавенство(Number(Result), BenchmarkData);       
    ElsIf TypeOf(BenchmarkData) = Type("String") Then
        Assertions.ПроверитьРавенство(DeleteCRLF(Result), DeleteCRLF(BenchmarkData));
    ElsIf TypeOf(BenchmarkData) = Type("Boolean") Then
        Assertions.ПроверитьРавенство(Boolean(Result), BenchmarkData);
    ElsIf BenchmarkData = Null Then
        Assertions.ПроверитьРавенство(?(Result = "null", Null, Result), BenchmarkData);
    Else
        Assertions.ПроверитьРавенство(Result, BenchmarkData)    
    EndIf;
       
EndProcedure // VerifyAssertion()

Function DeleteCRLF(Val String)
    
    String = StrReplace(String, Chars.CR, "");
    String = StrReplace(String, Chars.LF, "");
    String = StrReplace(String, Chars.CR + Chars.LF, "");
    Return String;
    
EndFunction // DeleteCRLF()

#EndRegion // ServiceProceduresAndFunctions
