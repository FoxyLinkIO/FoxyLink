Var CoreContext;
Var Assertions;

#Region ServiceInterface

Procedure Инициализация(CoreContextParam) Export
    CoreContext = CoreContextParam;
    Assertions = CoreContext.Плагин("БазовыеУтверждения");
EndProcedure // Инициализация()

Procedure ЗаполнитьНаборТестов(TestsSet) Export
    
    TestsSet.Добавить("Fact_OutputStringValue");
    TestsSet.Добавить("Fact_OutputNumberValue");
    TestsSet.Добавить("Fact_OutputTrueValue");
    TestsSet.Добавить("Fact_OutputFalseValue");
    TestsSet.Добавить("Fact_OutputNullValue");
    TestsSet.Добавить("Fact_OutputObjectValue");

EndProcedure // ЗаполнитьНаборТестов()

#EndRegion // ServiceInterface

#Region TestCases

Procedure Fact_OutputStringValue() Export
    
    BenchmarkData = """This is string value""";

    VerifyAssertion("StringValueOutput", "READ", BenchmarkData, True);
    
EndProcedure // Fact_OutputStringValue()

Procedure Fact_OutputNumberValue() Export
    
    BenchmarkData = 15.6464669489979796464313546498;

    VerifyAssertion("NumberValueOutput", "READ", BenchmarkData, True);
    
EndProcedure // Fact_OutputNumberValue()

Procedure Fact_OutputTrueValue() Export
    
    BenchmarkData = True;

    VerifyAssertion("TrueValueOutput", "READ", BenchmarkData, True);
    
EndProcedure // Fact_OutputTrueValue()

Procedure Fact_OutputFalseValue() Export
    
    BenchmarkData = False;

    VerifyAssertion("FalseValueOutput", "READ", BenchmarkData, True);
    
EndProcedure // Fact_OutputFalseValue()

Procedure Fact_OutputNullValue() Export
    
    BenchmarkData = Null;

    VerifyAssertion("NullValueOutput", "READ", BenchmarkData, True);
    
EndProcedure // Fact_OutputNullValue()

Procedure Fact_OutputObjectValue() Export
    
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
    
EndProcedure // Fact_OutputObjectValue()

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
    
    IHL_DataComposition.Output(Undefined, StreamObject, OutputParameters);
    
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
