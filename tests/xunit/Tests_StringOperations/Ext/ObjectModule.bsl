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
    
    SpecSymbolMessage = NStr("en='Is special symbol with code : {%1}';
            |ru='Это специальный символ с кодом : {%1}';
            |uk='Це спеціальний знак з кодом : {%1}';
            |en_CA='Is special symbol with code : {%1}'");    
    TestsSet.Добавить("Fact_IsSpecSymbol_Code_0", False, 
        StrTemplate(SpecSymbolMessage, "0"));
    TestsSet.Добавить("Fact_IsSpecSymbol_Code_33", False, 
        StrTemplate(SpecSymbolMessage, "33"));
    TestsSet.Добавить("Fact_IsSpecSymbol_Code_256", False, 
        StrTemplate(SpecSymbolMessage, "256"));
        
    NumberSymbolMessage = NStr("en='Is number : {%1}';
            |ru='Это число : {%1}';
            |uk='Це число : {%1}';
            |en_CA='Is number : {%1}'");
    TestsSet.Добавить("Fact_IsNumber_0", False, 
        StrTemplate(NumberSymbolMessage, "0"));
    TestsSet.Добавить("Fact_IsNumber_9", False, 
        StrTemplate(NumberSymbolMessage, "9"));
        
    LatinSymbolMessage = NStr("en='Is latin letter : {%1}';
            |ru='Это латинская буква : {%1}';
            |uk='Це латинська буква : {%1}';
            |en_CA='Is latin letter : {%1}'");    
    TestsSet.Добавить("Fact_IsLatinLetter_A", False, 
        StrTemplate(LatinSymbolMessage, "A"));
    TestsSet.Добавить("Fact_IsLatinLetter_smallA", False, 
        StrTemplate(LatinSymbolMessage, "a"));
    TestsSet.Добавить("Fact_IsLatinLetter_Z", False, 
        StrTemplate(LatinSymbolMessage, "Z"));
    TestsSet.Добавить("Fact_IsLatinLetter_smallZ", False, 
        StrTemplate(LatinSymbolMessage, "z"));
        
    CyrillicSymbolMessage = NStr("en='Is cyrillic letter : {%1}';
            |ru='Это кириллическая буква : {%1}';
            |uk='Це кирилична буква : {%1}';
            |en_CA='Is cyrillic letter : {%1}'");
    TestsSet.Добавить("Fact_IsCyrillicLetter_А", False, 
        StrTemplate(CyrillicSymbolMessage, "А"));
    TestsSet.Добавить("Fact_IsCyrillicLetter_smallЯ", False, 
        StrTemplate(CyrillicSymbolMessage, "я"));
      
    VariableNameMessage = NStr("en='Is incorrect variable name : {%1}';
            |ru='Это неверное имя переменной : {%1}';
            |uk='Це неправильна назва змінної : {%1}';
            |en_CA='Is incorrect variable name : {%1}'");
    TestsSet.Добавить("Fact_IsIncorrectVariableName_1", False,
        StrTemplate(VariableNameMessage, "Гаt_#sd1"));
    TestsSet.Добавить("Fact_IsIncorrectVariableName_2", False,
        StrTemplate(VariableNameMessage, "1fABb"));
    TestsSet.Добавить("Fact_IsIncorrectVariableName_3", False,
        StrTemplate(VariableNameMessage, "_1 x"));
    TestsSet.Добавить("Fact_IsCorrectVariableName", False,
        StrTemplate(NStr("en='Is correct variable name : {%1}';
                |ru='Это верное имя переменной : {%1}';
                |uk='Це правильна назва змінної : {%1}';
                |en_CA='Is correct variable name : {%1}'"), 
            "_1_hFФа"));

EndProcedure // ЗаполнитьНаборТестов()

#EndRegion // ServiceInterface

#Region TestCases

Procedure Fact_IsSpecSymbol_Code_0() Export
    
    Assertions.ПроверитьИстину(FL_CommonUseClientServer.IsSpecialSymbol(Char(0)));
    
EndProcedure // Fact_IsSymbol_Code_0()

Procedure Fact_IsSpecSymbol_Code_33() Export
    
    Assertions.ПроверитьИстину(FL_CommonUseClientServer.IsSpecialSymbol(Char(33)));
    
EndProcedure // Fact_IsSymbol_Code_33()

Procedure Fact_IsSpecSymbol_Code_256() Export
    
    Assertions.ПроверитьИстину(FL_CommonUseClientServer.IsSpecialSymbol(Char(256)));
    
EndProcedure // Fact_IsSpecSymbol_Code_256()

Procedure Fact_IsNumber_0() Export
    
    Assertions.ПроверитьИстину(FL_CommonUseClientServer.IsNumber("0"));
    
EndProcedure // Fact_IsNumber_0()

Procedure Fact_IsNumber_9() Export
    
    Assertions.ПроверитьИстину(FL_CommonUseClientServer.IsNumber("9"));
    
EndProcedure // Fact_IsNumber_9()

Procedure Fact_IsLatinLetter_A() Export
    
    Assertions.ПроверитьИстину(FL_CommonUseClientServer.IsLatinLetter("A"));
    
EndProcedure // Fact_IsLatinLetter_A()

Procedure Fact_IsLatinLetter_smallA() Export
    
    Assertions.ПроверитьИстину(FL_CommonUseClientServer.IsLatinLetter("a"));
    
EndProcedure // Fact_IsLatinLetter_smallA()

Procedure Fact_IsLatinLetter_Z() Export
    
    Assertions.ПроверитьИстину(FL_CommonUseClientServer.IsLatinLetter("Z"));
    
EndProcedure // Fact_IsLatinLetter_Z()

Procedure Fact_IsLatinLetter_smallZ() Export
    
    Assertions.ПроверитьИстину(FL_CommonUseClientServer.IsLatinLetter("z"));
    
EndProcedure // Fact_IsLatinLetter_smallZ()

Procedure Fact_IsCyrillicLetter_А() Export
    
    Assertions.ПроверитьИстину(FL_CommonUseClientServer.IsCyrillicLetter("А"));
    
EndProcedure // Fact_IsCyrillicLetter_А()

Procedure Fact_IsCyrillicLetter_smallЯ() Export
    
    Assertions.ПроверитьИстину(FL_CommonUseClientServer.IsCyrillicLetter("я"));
    
EndProcedure // Fact_IsCyrillicLetter_smallЯ()

Procedure Fact_IsIncorrectVariableName_1() Export
    
    Assertions.ПроверитьЛожь(FL_CommonUseClientServer.IsCorrectVariableName("Гаt_#sd1"));
    
EndProcedure // Fact_IsIncorrectVariableName_1()

Procedure Fact_IsIncorrectVariableName_2() Export
    
    Assertions.ПроверитьЛожь(FL_CommonUseClientServer.IsCorrectVariableName("1fABb"));
    
EndProcedure // Fact_IsIncorrectVariableName_2()

Procedure Fact_IsIncorrectVariableName_3() Export
    
    Assertions.ПроверитьЛожь(FL_CommonUseClientServer.IsCorrectVariableName("_1 x"));
    
EndProcedure // Fact_IsIncorrectVariableName_3()

Procedure Fact_IsCorrectVariableName() Export
    
    Assertions.ПроверитьИстину(FL_CommonUseClientServer.IsCorrectVariableName("_1_hFФа"));
    
EndProcedure // Fact_IsCorrectVariableName()

#EndRegion // TestCases