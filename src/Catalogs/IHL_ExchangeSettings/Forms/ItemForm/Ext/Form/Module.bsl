////////////////////////////////////////////////////////////////////////////////
// This file is part of IHL (Integration happiness library).
// Copyright © 2016-2017 Petro Bazeliuk.
// 
// IHL is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as 
// published by the Free Software Foundation, either version 3 
// of the License, or any later version.
// 
// IHL is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public 
// License along with IHL. If not, see <http://www.gnu.org/licenses/>.
//
////////////////////////////////////////////////////////////////////////////////

&AtServer
Var BasicFormatObject;

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
    
    If IsBlankString(Object.BasicFormatGuid) Then
        For Each Format In Catalogs.IHL_ExchangeSettings.AvailableFormats() Do
            FillPropertyValues(Items.BasicFormatGuid.ChoiceList.Add(), Format);    
        EndDo;
        Items.HeaderPagesFormat.CurrentPage = Items.HeaderPageSelectFormat;
        Items.HeaderGroupLeft.Visible = False;
    Else
        LoadBasicFormatData();    
    EndIf;
    
    Catalogs.IHL_ExchangeSettings.OnCreateAtServer(ThisObject);
    
    UpdateMethodsView();
    
EndProcedure // OnCreateAtServer()

&AtClient
Procedure OnOpen(Cancel)
    
    
    
EndProcedure // OnOpen()

#EndRegion // FormEventHandlers

#Region FormItemsEventHandlers

&AtClient
Procedure BasicFormatGuidOnChange(Item)
    
    If Not IsBlankString(Object.BasicFormatGuid) Then
        LoadBasicFormatData();   
    EndIf;
    
EndProcedure // BasicFormatGuidOnChange()

&AtClient
Procedure FormatStandardClick(Item, StandardProcessing)
    
    StandardProcessing = False;
    BeginRunningApplication(New NotifyDescription(
        "DoAfterBeginRunningApplication", ThisObject), 
        FormatStandardLink());
    
EndProcedure // FormatStandardClick()



&AtClient
Procedure MethodPagesOnCurrentPageChange(Item, CurrentPage)
    
    LoadMethodSettings();
    
EndProcedure // MethodPagesOnCurrentPageChange()

#EndRegion // FormItemsEventHandlers

#Region FormCommandHandlers

&AtClient
Procedure AddAPIMethod(Command)
    
    ShowChooseFromList(New NotifyDescription("DoAfterChooseAvailableMethodToAdd",
        ThisObject), AvailableMethods(), Items.AddAPIMethod);
        
EndProcedure // AddAPIMethod()
    
&AtClient
Procedure DeleteAPIMethod(Command)
    
    ShowChooseFromList(New NotifyDescription("DoAfterChooseCurrentMethodToDelete",
        ThisObject), CurrentMethods(), Items.DeleteAPIMethod);
    
EndProcedure // DeleteAPIMethod()

#EndRegion // FormCommandHandlers

#Region ServiceProceduresAndFunctions

&AtClient
Procedure DoAfterBeginRunningApplication(CodeReturn, AdditionalParameters) Export
    
    // TODO: Some checks   
    
EndProcedure // DoAfterChooseAvailableFormat() 


// Fills basic format info.
//
&AtServer
Procedure LoadBasicFormatData()

    Items.HeaderGroupLeft.Visible = True;
    Items.HeaderPagesFormat.CurrentPage = Items.HeaderPageBasicFormat;
    FormatProcessor = Catalogs.IHL_ExchangeSettings.NewFormatProcessor(
        FormatProcessorName, Object.BasicFormatGuid);
        
    FormatName = StrTemplate("%1 (%2)", FormatProcessor.FormatFullName(),
        FormatProcessor.FormatShortName());
        
    FormatStandard = FormatProcessor.FormatStandard();
        
    FormatPluginVersion = FormatProcessor.Version();

EndProcedure // LoadBasicFormatData() 



// Returns link to the formal document from the Internet Engineering Task Force 
// (IETF) that is the result of committee drafting and subsequent review 
// by interested parties.
//
&AtServer
Function FormatStandardLink() 
    
     FormatProcessor = Catalogs.IHL_ExchangeSettings.NewFormatProcessor(
        FormatProcessorName, Object.BasicFormatGuid);     
     Return FormatProcessor.FormatStandardLink();
    
EndFunction // FormatStandardLink()



#Region Methods

// Adds new API method to ThisObject.
//
&AtClient
Procedure DoAfterChooseAvailableMethodToAdd(SelectedElement, 
    AdditionalParameters) Export
    
    If SelectedElement <> Undefined Then
        
        // TODO: Add possibility to use different versions of API.
        FilterParameters = New Structure("APIVersion, Method", "1.0.0.0", 
            SelectedElement.Value);
            
        FilterResult = Object.Methods.FindRows(FilterParameters);
        If FilterResult.Count() = 0 Then
            
            Modified = True;
            
            NewMethod = Object.Methods.Add();
            NewMethod.Method = SelectedElement.Value;
            NewMethod.APIVersion = "1.0";
            
            UpdateMethodsView();
                        
        EndIf;
        
    EndIf;
    
EndProcedure // DoAfterChooseAvailableMethodToAdd() 

// Deletes API method from ThisObject.
//
&AtClient
Procedure DoAfterChooseCurrentMethodToDelete(SelectedElement, 
    AdditionalParameters) Export
    
    If SelectedElement <> Undefined Then
            
        FilterResult = Object.Methods.FindRows(SelectedElement.Value);
        If FilterResult.Count() > 0 Then
            
            Modified = True;
            
            Object.Methods.Delete(FilterResult[0]);
            
            UpdateMethodsView();
            
        EndIf;
        
    EndIf;
    
EndProcedure // DoAfterChooseCurrentMethodToDelete() 





// See function Catalogs.IHL_Methods.UpdateMethodsView.
//
&AtServer
Procedure UpdateMethodsView()
    
    Catalogs.IHL_ExchangeSettings.UpdateMethodsView(ThisObject);   
    
    LoadMethodSettings();
    
EndProcedure // UpdateMethodsView()

&AtServer
Procedure LoadMethodSettings()
    
    ResultTextDocument.Clear();
    ResultSpreadsheetDocument.Clear();

    //СохранитьИзмененияСхемыКомпоновкиДанных();
        
    CurrentPage = Items.MethodPages.CurrentPage;
    If CurrentPage = Undefined And Items.MethodPages.ChildItems.Count() > 0 Then
        CurrentPage = Items.MethodPages.ChildItems[0];    
    EndIf;
    
    If CurrentPage <> Undefined Then
       
        RowMethod = CurrentPage.Name;
        IHL_InteriorUse.MoveItemInItemFormCollection(Items, 
            "HiddenGroupSettings", RowMethod);
           
    //    ТекущиеДанные = ТекущиеДанныеОбъектаОперации(ИдентификаторОперации);
    //    ОперацияИспользуется 	  = ТекущиеДанные.Используется;
    //    ОперацияФайловоеХранилище = НЕ ТекущиеДанные.ОтключитьФайловоеХранилище;
    //    OutputType = CurrentData.OutputType;
    //    
    //    // Обновим отображение для операции
    //    UpdateExpressНастройкиОбменов.ОбновитьОтображениеОперации(ЭтотОбъект,
    //        ТекущиеДанные.Операция);
    //    
    //    // Загрузим схемы, если необходимо
    //    Если ПустаяСтрока(ТекущиеДанные.АдресСхемыКомпоновкиДанных) Тогда
    //        ТекущиеДанные.АдресСхемыКомпоновкиДанных = ПоместитьВоВременноеХранилище(
    //            Новый СхемаКомпоновкиДанных, УникальныйИдентификатор);	
    //    КонецЕсли;
    //        
    //    UpdateExpressКомпоновкаДанных.СкопироватьСхемуКомпоновкиДанных(
    //        АдресРедактируемойСхемыКомпоновкиДанных,
    //        ТекущиеДанные.АдресСхемыКомпоновкиДанных);
    //        
    //    UpdateExpressКомпоновкаДанных.ИнициализироватьКомпоновщикНастроек(
    //        КомпоновщикНастроек, 
    //        ТекущиеДанные.АдресСхемыКомпоновкиДанных, 
    //        ТекущиеДанные.АдресНастроекКомпоновкиДанных);
            
    Else

        RowMethod = Undefined;
        RowOutputType = Undefined;
    //    АдресРедактируемойСхемыКомпоновкиДанных = "";
    //    КомпоновщикНастроек = Новый КомпоновщикНастроекКомпоновкиДанных;
            
    EndIf;    
    
EndProcedure // LoadMethodSettings()


// See function Catalogs.IHL_Methods.AvailableMethods.
//
&AtServer
Function AvailableMethods()
    
    Return Catalogs.IHL_Methods.AvailableMethods();
    
EndFunction // AvailableMethods()

// Returns list of currently used methods.
//
&AtServer
Function CurrentMethods()
    
    ValueList = New ValueList();
    For Each Item In Object.Methods Do
        ValueList.Add(New Structure("Method, APIVersion", Item.Method, Item.APIVersion), 
            StrTemplate("%1, ver. %2", Item.Method, Item.APIVersion));   
    EndDo;
    
    Return ValueList;
    
EndFunction // CurrentMethods()

#EndRegion // Methods

#EndRegion // ServiceProceduresAndFunctions



