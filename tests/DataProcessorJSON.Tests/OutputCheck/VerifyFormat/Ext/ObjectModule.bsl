﻿Var CoreContext;
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
    
    TestsSet.Добавить("Fact_TwoEmptyObjectValue");
    TestsSet.Добавить("Fact_TwoEmptyObjectStringValue");
    TestsSet.Добавить("Fact_TwoEmptyArrayValue");
    TestsSet.Добавить("Fact_TwoEmptyArrayStringValue");
    TestsSet.Добавить("Fact_TwoEmptyArrayInArray");
    TestsSet.Добавить("Fact_TwoEmptyArrayStringInArray");
    
    TestsSet.Добавить("Fact_TwoInnerObjectValue");
    TestsSet.Добавить("Fact_ObjectValue");
    TestsSet.Добавить("Fact_ObjectArraySeveralTypes");
    
    TestsSet.Добавить("Fact_Bug_46");
    TestsSet.Добавить("Fact_Bug_232");
    
    TestsSet.Добавить("Fact_ComplexHierarchy_1");
    
EndProcedure // ЗаполнитьНаборТестов()

#EndRegion // ServiceInterface

#Region TestCases

Procedure Fact_StringValue() Export
    
    BenchmarkData = """This is string value""";

    VerifyAssertion("StringValueOutput", BenchmarkData);
    
EndProcedure // Fact_StringValue()

Procedure Fact_NumberValue() Export
    
    BenchmarkData = 15.6464669489979796464313546498;

    VerifyAssertion("NumberValueOutput", BenchmarkData);
    
EndProcedure // Fact_NumberValue()

Procedure Fact_TrueValue() Export
    
    BenchmarkData = True;

    VerifyAssertion("TrueValueOutput", BenchmarkData);
    
EndProcedure // Fact_TrueValue()

Procedure Fact_FalseValue() Export
    
    BenchmarkData = False;

    VerifyAssertion("FalseValueOutput", BenchmarkData);
    
EndProcedure // Fact_FalseValue()

Procedure Fact_NullValue() Export
    
    BenchmarkData = Null;

    VerifyAssertion("NullValueOutput", BenchmarkData);
    
EndProcedure // Fact_NullValue()

Procedure Fact_EmptyObjectValue() Export
    
    BenchmarkData = "{}";
    VerifyAssertion("EmptyObjectValueOutput", BenchmarkData);

EndProcedure // Fact_EmptyObjectValue() 

Procedure Fact_EmptyArrayValue() Export
    
    BenchmarkData = "[]";
    VerifyAssertion("EmptyArrayValueOutput", BenchmarkData);

EndProcedure // Fact_EmptyArrayValue() 

Procedure Fact_TwoEmptyObjectValue() Export
    
    BenchmarkData = "
        |{
        |""name"": {},
        |""addr"": {}
        |}
        |";

    VerifyAssertion("{ """": { }, """": { } }", BenchmarkData);
    
EndProcedure // Fact_TwoEmptyObjectValue()

Procedure Fact_TwoEmptyObjectStringValue() Export
    
    BenchmarkData = "
        |{
        |""string"": ""This is a string value."",
        |""name"": {},
        |""addr"": {}
        |}
        |";

    VerifyAssertion("{ """": {}, """": {}, """": """"}", BenchmarkData);
    
EndProcedure // Fact_TwoEmptyObjectStringValue()

Procedure Fact_TwoEmptyArrayValue() Export
    
    BenchmarkData = "
        |{
        |""name"": [],
        |""addr"": []
        |}
        |";

    VerifyAssertion("{ """": [ ], """": [ ] }", BenchmarkData);
    
EndProcedure // Fact_TwoEmptyArrayValue()

Procedure Fact_TwoEmptyArrayStringValue() Export
    
    BenchmarkData = "
        |{
        |""string"": ""This is a string value."",
        |""name"": [],
        |""addr"": []
        |}
        |";

    VerifyAssertion("{ """": [], """": [], """": """"}", BenchmarkData);
    
EndProcedure // Fact_TwoEmptyArrayStringValue()

Procedure Fact_TwoEmptyArrayInArray() Export
    
    BenchmarkData = "
        |[
        |[],
        |[]
        |]
        |";

    VerifyAssertion("[ [ ], [ ] ]", BenchmarkData);
    
EndProcedure // Fact_TwoEmptyArrayInArray()

Procedure Fact_TwoEmptyArrayStringInArray() Export
    
    BenchmarkData = "
        |[
        |""This is a string value."",
        |[],
        |[]
        |]
        |";

    VerifyAssertion("[ """", [ ], [ ] ]", BenchmarkData);
    
EndProcedure // Fact_TwoEmptyArrayStringInArray()

Procedure Fact_TwoInnerObjectValue() Export
    
    BenchmarkData = "
        |{
        |""Identity"": {
        |""Name"": ""Dana"",
        |""Surname"": ""Balana""
        |},
        |""Passport"": {
        |""Id"": ""CH 890112""
        |}
        |}
        |";

    VerifyAssertion("{ """": {F,F}, """": {F} }", BenchmarkData);
    
EndProcedure // Fact_TwoInnerObjectValue()

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

    VerifyAssertion("ObjectValueOutput", BenchmarkData);
    
EndProcedure // Fact_ObjectValue()

Procedure Fact_ObjectArraySeveralTypes() Export
    
    BenchmarkData = "{
        |""Name"": ""PE KS"",
        |""Credentials"": {
        |""Login"": ""ks123"",
        |""Password"": ""yfk,yjV82""
        |},
        |""App"": {
        |""Login"": ""f12a00d3"",
        |""Password"": ""f43ad59""
        |},
        |""Accounts"": [
        |1,
        |{
        |""ref"": ""8e4ddf8e"",
        |""Name"": ""KS - 260080""
        |},
        |2,
        |{
        |""ref"": ""4731c66c"",
        |""Name"": ""KS - 260081""
        |}
        |]
        |}";

    VerifyAssertion("ObjectArraySeveralTypes", BenchmarkData);
    
EndProcedure // Fact_ObjectArraySeveralTypes()

Procedure Fact_Bug_46() Export
    
    BenchmarkData = "[
    |{
    |""String"": ""String"",
    |""Number"": 7,
    |""Boolean"": false
    |},
    |{
    |""String"": ""String"",
    |""Number"": 42,
    |""Boolean"": true
    |}
    |]";

    VerifyAssertion("#46 Bug: JSON Array", BenchmarkData);
    
EndProcedure // Fact_Bug_46()

Procedure Fact_Bug_232() Export
    
    BenchmarkData = "{
    |""ExchangeName"": ""Exchange"",
    |""Stock"": [
    |{
    |""Sku"": ""AT-01"",
    |""Warehouse"": [
    |{
    |""String"": ""String3"",
    |""Number"": 100,
    |""Boolean"": false
    |}
    |]
    |},
    |{
    |""Sku"": ""SN-0112"",
    |""Warehouse"": [
    |{
    |""String"": ""String1"",
    |""Number"": 1,
    |""Boolean"": true
    |},
    |{
    |""String"": ""String2"",
    |""Number"": 10,
    |""Boolean"": true
    |}
    |]
    |}
    |]
    |}";

    VerifyAssertion("#232 Bug: Array+Field", BenchmarkData);
    
EndProcedure // Fact_Bug_232()

Procedure Fact_ComplexHierarchy_1() Export
    
    BenchmarkData = "[
        |[
        |{}
        |],
        |[
        |{
        |""Foo"": false,
        |""Bar"": {
        |""Foo"": ""Bar""
        |}
        |}
        |]
        |]
        |";

    VerifyAssertion("[[{}],[{:,{:}}]]", BenchmarkData);
    
EndProcedure // Fact_ComplexHierarchy_1()

#EndRegion // TestCases

#Region ServiceProceduresAndFunctions

Procedure VerifyAssertion(CatalogRefName, BenchmarkData)
    
    Settings = Catalogs.FL_Exchanges.ExchangeSettingsByRefs(
        Catalogs.FL_Exchanges.FindByDescription(CatalogRefName), 
        Catalogs.FL_Operations.Read); 
                
    StreamObject = FL_InteriorUse.NewFormatProcessor(
            Settings.BasicFormatGuid);
        
    // Open new memory stream and initialize format processor.
    Stream = New MemoryStream;
    StreamObject.Initialize(Stream, Settings.APISchema);
    
    OutputParameters = Catalogs.FL_Exchanges.NewOutputParameters(Settings);
                
    FL_DataComposition.Output(StreamObject, OutputParameters);
    
    // Close format stream and memory stream.
    StreamObject.Close();
    ResultMessage = GetStringFromBinaryData(Stream.CloseAndGetBinaryData());

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
