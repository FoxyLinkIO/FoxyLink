Var CoreContext;
Var Assertions;

#Region ServiceInterface

Procedure Инициализация(CoreContextParam) Export
    CoreContext = CoreContextParam;
    Assertions = CoreContext.Плагин("БазовыеУтверждения");
EndProcedure // Инициализация()

Procedure ЗаполнитьНаборТестов(TestsSet) Export
    
    TestsSet.Добавить("Fact_StringValue");
    TestsSet.Добавить("Fact_NumberValue");
    TestsSet.Добавить("Fact_TrueValue");
    TestsSet.Добавить("Fact_FalseValue");
    TestsSet.Добавить("Fact_NullValue");
    TestsSet.Добавить("Fact_EmptyObjectValue");
    TestsSet.Добавить("Fact_EmptyArrayValue");
    TestsSet.Добавить("Fact_ObjectValue");

EndProcedure // ЗаполнитьНаборТестов()

#EndRegion // ServiceInterface

#Region TestCases

Procedure Fact_StringValue() Export
    
    BenchmarkData = """This is string value""";

    VerifyAssertion("StringValueOutput", "READ", BenchmarkData);
    
EndProcedure // Fact_StringValue()

Procedure Fact_NumberValue() Export
    
    BenchmarkData = 15.6464669489979796464313546498;

    VerifyAssertion("NumberValueOutput", "READ", BenchmarkData);
    
EndProcedure // Fact_NumberValue()

Procedure Fact_TrueValue() Export
    
    BenchmarkData = True;

    VerifyAssertion("TrueValueOutput", "READ", BenchmarkData);
    
EndProcedure // Fact_TrueValue()

Procedure Fact_FalseValue() Export
    
    BenchmarkData = False;

    VerifyAssertion("FalseValueOutput", "READ", BenchmarkData);
    
EndProcedure // Fact_FalseValue()

Procedure Fact_NullValue() Export
    
    BenchmarkData = Null;

    VerifyAssertion("NullValueOutput", "READ", BenchmarkData);
    
EndProcedure // Fact_NullValue()

Procedure Fact_EmptyObjectValue() Export
    
    BenchmarkData = "{}";
    VerifyAssertion("EmptyObjectValueOutput", "READ", BenchmarkData);

EndProcedure // Fact_EmptyObjectValue() 

Procedure Fact_EmptyArrayValue() Export
    
    BenchmarkData = "[]";
    VerifyAssertion("EmptyArrayValueOutput", "READ", BenchmarkData);

EndProcedure // Fact_EmptyArrayValue() 

Procedure Fact_ObjectValue() Export
    
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

    VerifyAssertion("ObjectValueOutput", "READ", BenchmarkData);
    
EndProcedure // Fact_ObjectValue()

#EndRegion // TestCases

#Region ServiceProceduresAndFunctions

Procedure VerifyAssertion(CatalogRefName, MethodName, BenchmarkData)
    
    ExchangeSettings = Catalogs.FL_Exchanges.ExchangeSettingsByRefs(
        Catalogs.FL_Exchanges.FindByDescription(CatalogRefName), 
        Catalogs.FL_Methods.FindByDescription(MethodName)); 
        
    ResultMessage = Catalogs.FL_Exchanges.GenerateMessageResult(Undefined, 
        ExchangeSettings);

    If TypeOf(BenchmarkData) = Type("Number") Then
        Assertions.ПроверитьРавенство(Number(ResultMessage), BenchmarkData);       
    ElsIf TypeOf(BenchmarkData) = Type("String") Then
        Assertions.ПроверитьРавенство(DeleteCRLF(ResultMessage), DeleteCRLF(BenchmarkData));
    ElsIf TypeOf(BenchmarkData) = Type("Boolean") Then
        Assertions.ПроверитьРавенство(Boolean(ResultMessage), BenchmarkData);
    ElsIf BenchmarkData = Null Then
        Assertions.ПроверитьРавенство(?(ResultMessage = "null", Null, ResultMessage), BenchmarkData);
    Else
        Assertions.ПроверитьРавенство(ResultMessage, BenchmarkData)    
    EndIf;
       
EndProcedure // VerifyAssertion()

Function DeleteCRLF(Val String)
    
    String = StrReplace(String, Chars.CR, "");
    String = StrReplace(String, Chars.LF, "");
    String = StrReplace(String, Chars.CR + Chars.LF, "");
    Return String;
    
EndFunction // DeleteCRLF()

#EndRegion // ServiceProceduresAndFunctions
