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

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region ProgramInterface

// Loads data composition schema, data composition settings and methods 
// for editing in catalog form.
//
// Parameters:
//  ManagedForm - ManagedForm - catalog form.  
//
Procedure OnCreateAtServer(ManagedForm) Export

    Object = ManagedForm.Object;
    If TypeOf(Object.Ref) <> Type("CatalogRef.IHL_ExchangeSettings") Then
        Return;
    EndIf;
    
    LoadDCSchemaAndDCSettings(Object);    

EndProcedure // OnCreateAtServer()

// Updates methods view on managed form.
//
// Parameters:
//  ManagedForm - ManagedForm - catalog form.  
//
Procedure UpdateMethodsView(ManagedForm) Export
    
    Items = ManagedForm.Items;
    Methods = ManagedForm.Object.Methods;
    
    // Add methods from object.
    For Each Item In Methods Do
        
        MethodDescription = Item.Method.Description;
        //РезультатПоиска = Catalogs.IHL_Methods.НайтиПоКоду(Операция.ИмяОперации);
        //Если РезультатПоиска.Пустая() = Ложь Тогда
        //    Операция.Операция = РезультатПоиска.Ссылка;
        //    Операция.Описание = РезультатПоиска.Описание;
        //    Операция.ИмяОперации = РезультатПоиска.Код;
        //КонецЕсли;
        
        SearchResult = Items.Find(MethodDescription);
        If SearchResult <> Undefined Then
            SearchResult.Picture = PictureLib.IHL_MethodSettingsInvalid;
        Else
            AddMethodOnForm(Items, MethodDescription, Item.OperationDescription,
                PictureLib.IHL_MethodSettingsInvalid);
        EndIf;
            
    EndDo;
    
    
    For Each Item In Items.MethodPages.ChildItems Do
        
        Method = Catalogs.IHL_Methods.MethodByDescription(Item.Name);
        FilterResult = Methods.FindRows(New Structure("Method", Method));
        If FilterResult.Count() = 0 Then
            
            // This code is needed to fix problem with platform bug.
            If Item.ChildItems.Find("HiddenGroupSettings") <> Undefined Then
                IHL_InteriorUse.MoveItemInItemFormCollectionNoSearch(Items, 
                    Items.HiddenGroupSettings, Items.HiddenGroup);        
            EndIf;
            
            Items.Delete(Item);
            
        EndIf;
        
    EndDo;
    
    // Hide or unhide delete method button.
    Items.DeleteAPIMethod.Visible = Methods.Count() > 0;         


    // Добавляем операции из справочника
    //Запрос = Новый Запрос;
    //Запрос.Текст = ТекстЗапросаОперации();
    //ВыборкаОперации = Запрос.Выполнить().Выбрать();
    //Пока ВыборкаОперации.Следующий() Цикл
    //    
    //    Если ВыборкаОперации.Используется = Ложь Тогда
    //        Продолжить;	
    //    КонецЕсли;
    //    
    //    ЭлементФормы = Элементы.Найти(ВыборкаОперации.ИмяОперации);
    //    Если ЭлементФормы <> Неопределено Тогда
    //        
    //        ЭлементФормы.Картинка = БиблиотекаКартинок.UpdateExpressДействующий;
    //        
    //    Иначе
    //        
    //        ЭлементФормы = ДобавитьСтраницуОперацииНаФорму(Элементы, 
    //            ВыборкаОперации.ИмяОперации, 
    //            ВыборкаОперации.Описание, 
    //            БиблиотекаКартинок.UpdateExpressДействующий);
    //            
    //        ЗаполнитьЗначенияСвойств(Операции.Добавить(), ВыборкаОперации, , "Используется");
    //        
    //    КонецЕсли;
    //    
    //    Если ПустаяСтрока(Объект.ПолноеИмяОбъектаМетаданных)
    //       И ВыборкаОперации.СвязанСОбъектомМетаданных Тогда
    //        ЭлементФормы.Доступность = Ложь;
    //    Иначе
    //        ЭлементФормы.Доступность = Истина;		
    //    КонецЕсли;
    //    
    //КонецЦикла;
    
    
EndProcedure // UpdateMethodsView()




// Returns available plugable formats.
//
// Returns:
//  ValueList - with values:
//      * Value - String - format library guid.
//
Function AvailableFormats() Export
    
    ValueList = New ValueList;

    PlugableFormats = IHL_InteriorUse.PlugableFormatsSubsystem(); 
    For Each Item In PlugableFormats.Content Do
        
        If Metadata.DataProcessors.Contains(Item) Then
            
            Try
            
                DataProcessor = DataProcessors[Item.Name].Create();                
                ValueList.Add(DataProcessor.LibraryGuid(),
                    StrTemplate("%1 (%2), ver. %3", 
                        DataProcessor.FormatShortName(),
                        DataProcessor.FormatStandard(),
                        DataProcessor.Version()));
            
            Except
                
                IHL_CommonUseClientServer.NotifyUser(ErrorDescription());
                Continue;
                
            EndTry;
            
        EndIf;
        
    EndDo;
    
    Return ValueList;
    
EndFunction // AvailableFormats()

// Returns new format data processor for every server call.
//
// Parameters:
//  FormatProcessorName - String - name of the object type depends on the data 
//                                 processor name in the configuration.
//  LibraryGuid         - String - library guid which is used to identify 
//                                 different implementations of specific format.
//
// Returns:
//  DataProcessorObject.<Data processor name> - format data processor.
//
Function NewFormatProcessor(FormatProcessorName, Val LibraryGuid) Export
    
    If IsBlankString(FormatProcessorName) Then
        
        PlugableFormats = IHL_InteriorUse.PlugableFormatsSubsystem();
        For Each Item In PlugableFormats.Content Do
            
            If Metadata.DataProcessors.Contains(Item) Then
                
                Try
                
                    FormatProcessor = DataProcessors[Item.Name].Create();
                    If FormatProcessor.LibraryGuid() = LibraryGuid Then
                        FormatProcessorName = Item.Name;
                        Break;
                    EndIf;
                
                Except
                    
                    IHL_CommonUseClientServer.NotifyUser(ErrorDescription());
                    Continue;
                    
                EndTry;
                
            EndIf;
            
        EndDo;
        
    Else
        
        FormatProcessor = DataProcessors[FormatProcessorName].Create();
        
    EndIf;
    
    Return FormatProcessor;
    
EndFunction // NewFormatProcessor()

#EndRegion // ProgramInterface

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
Procedure LoadDCSchemaAndDCSettings(Object)

    Ref = Object.Ref;
    If ValueIsFilled(Ref) Then
        
        FilterParameters = New Structure("Method, APIVersion"); 
        For Each Item In Object.Methods Do
            
            FillPropertyValues(FilterParameters, Item); 
            FilterResult = Ref.Methods.FindRows(FilterParameters);
            If FilterResult.Count() <> 1 Then
                
                // TODO: Critical problems, later it must be fixed. 
                Continue; 
                
            EndIf;
            
            DataCompositionSchema = FilterResult[0].DataCompositionSchema.Get();
            If DataCompositionSchema <> Undefined Then
                Item.DataCompositionSchemaAddress = 
                    PutToTempStorage(DataCompositionSchema, New UUID);
            EndIf;
            
            DataCompositionSettings = FilterResult[0].DataCompositionSettings.Get();
            If DataCompositionSettings <> Undefined Then
                Item.DataCompositionSettingsAddress = 
                    PutToTempStorage(DataCompositionSettings, New UUID);
            EndIf;
            
        EndDo;
        
    EndIf;
        
EndProcedure // LoadDCSchemaAndDCSettings()


// Добавляет страницу операции на форму.
//
// Параметры:
//	Элементы    - ВсеЭлементы - коллекция элементов формы.
//	ИмяОперации - Строка      - имя добавляемой операция.
//  Картинка    - Картинка    - картинка, отображает статус операции.
//
// Возвращаемое значение:
//	ДекорацияФормы, ГруппаФормы, КнопкаФормы, ТаблицаФормы, ПолеФормы - новый элемент формы.	
//
Function AddMethodOnForm(Items, MethodDescription, Description, Picture)

    BasicDescription = NStr(
        "en = 'Description is not available.';
        |ru = 'Описание операции не доступно.'");

    Parameters = New Structure;
    Parameters.Insert("Name", MethodDescription);
    Parameters.Insert("Title", MethodDescription);
    Parameters.Insert("Type", FormGroupType.Page);
    Parameters.Insert("ElementType", Type("FormGroup"));
    Parameters.Insert("EnableContentChange", False);
    Parameters.Insert("Picture", Picture);
    NewPage = IHL_InteriorUse.AddItemToItemFormCollection(Items, Parameters, 
        Items.MethodPages);
        
    Parameters = New Structure;
    Parameters.Insert("Name", "Label" + MethodDescription);
    Parameters.Insert("Title", ?(IsBlankString(Description), BasicDescription, 
        Description));
    Parameters.Insert("Type", FormDecorationType.Label);
    Parameters.Insert("ElementType", Тип("FormDecoration"));
    Parameters.Insert("TextColor", New Color(0, 0, 0));
    Parameters.Insert("Font", New Font(, , True));

    Return IHL_InteriorUse.AddItemToItemFormCollection(Items, Parameters, 
        NewPage);

EndFunction // AddMethodOnForm()

#EndRegion // ServiceProceduresAndFunctions

#EndIf