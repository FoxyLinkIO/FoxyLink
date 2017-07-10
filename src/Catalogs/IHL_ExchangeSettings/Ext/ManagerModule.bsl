////////////////////////////////////////////////////////////////////////////////
// This file is part of IHL (Integration happiness library).
// Copyright © 2016-2017 Petro Bazeliuk.
// 
// This program is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Affero General Public License as 
// published by the Free Software Foundation, either version 3 of the License,
// or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful, 
// but WITHOUT ANY WARRANTY; without even the implied warranty of 
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License 
// along with this program. If not, see <http://www.gnu.org/licenses/agpl-3.0>.
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
    
    LoadSettingsToTempStorage(Object);    

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
    
EndProcedure // UpdateMethodsView()

// Helps to save untracked changes in catalog form.
//
// Parameters:
//  ManagedForm   - ManagedForm                        - catalog form.
//  CurrentObject - CatalogObject.IHL_ExchangeSettings - object that is used 
//                  for reading, modifying, adding and deleting catalog items. 
//
Procedure BeforeWriteAtServer(ManagedForm, CurrentObject) Export
    
    ProcessBeforeWriteAtServer(ManagedForm.Object, CurrentObject);        
    
EndProcedure // BeforeWriteAtServer()


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


// Returns available plugable channels.
//
// Returns:
//  ValueList - with values:
//      * Value - String - channel library guid.
//
Function AvailableChannels() Export
    
    ValueList = New ValueList;

    PlugableChannels = IHL_InteriorUse.PlugableChannelsSubsystem(); 
    For Each Item In PlugableChannels.Content Do
        
        If Metadata.DataProcessors.Contains(Item) Then
            
            Try
            
                DataProcessor = DataProcessors[Item.Name].Create();                
                ValueList.Add(DataProcessor.LibraryGuid(),
                    StrTemplate("%1 (ver. %2)", 
                        DataProcessor.ChannelFullName(),
                        DataProcessor.Version()));
            
            Except
                
                IHL_CommonUseClientServer.NotifyUser(ErrorDescription());
                Continue;
                
            EndTry;
            
        EndIf;
        
    EndDo;
    
    Return ValueList;
    
EndFunction // AvailableChannels()

// Returns new channel data processor for every server call.
//
// Parameters:
//  LibraryGuid - String - library guid which is used to identify 
//                         different implementations of specific channel.
//
// Returns:
//  DataProcessorObject.<Data processor name> - channel data processor.
//
Function NewChannelProcessor(Val LibraryGuid) Export
    
    PlugableChannels = IHL_InteriorUse.PlugableChannelsSubsystem();
    For Each Item In PlugableChannels.Content Do
        
        If Metadata.DataProcessors.Contains(Item) Then
            
            Try
            
                ChannelProcessor = DataProcessors[Item.Name].Create();
                If ChannelProcessor.LibraryGuid() = LibraryGuid Then
                    ChannelProcessorName = Item.Name;
                    Break;
                EndIf;
            
            Except
                
                IHL_CommonUseClientServer.NotifyUser(ErrorDescription());
                Continue;
                
            EndTry;
            
        EndIf;
        
    EndDo;
            
    Return ChannelProcessor;
    
EndFunction // NewChannelProcessor()



// Returns exchange settings.
//
// Parameters:
//  ExchangeName - String - name of the IHL_ExchangeSettings catalog.
//  MethodName   - String - name of the IHL_Methods catalog.
//
// Returns:
//  FixedStructure  - exchange settings. 
//  String          - error description. 
//
Function GetExchangeSettings(Val ExchangeName, Val MethodName) Export

    Query = New Query;
    Query.Text = TextQueryExchangeSettings();
    Query.SetParameter("ExchangeName", ExchangeName);
    Query.SetParameter("MethodName", MethodName);

    QueryResult = Query.Execute();
    If QueryResult.IsEmpty() Then
        ErrorMessage = StrReplace(Nstr(
                "en = 'Error: Exchange settings ''%1'' and/or method ''%2'' not found.'; 
                |ru = 'Ошибка: Настройки обмена ''%1'' и/или метод ''%2'' не найдены.'"),
            ExchangeName, MethodName);    
        Return ErrorMessage;
    EndIf;

    ValueTable = QueryResult.Unload();
    If ValueTable.Count() > 1 Then
        ErrorMessage = StrReplace(Nstr(
                "en = 'Error: Duplicated records of exchange settings ''%1'' and method ''%2'' are found.'; 
                |ru = 'Ошибка: Обнаружены дублирующиеся настройки обмена ''%1'' и метод ''%2''.'"),
            ExchangeName, MethodName);
        Return ErrorMessage;     
    EndIf;

    ExchangeSettings = IHL_CommonUse.ValueTableRowIntoStructure(ValueTable[0]);         
    Return New FixedStructure(ExchangeSettings);

EndFunction // GetExchangeSettings()

#EndRegion // ProgramInterface

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
Procedure LoadSettingsToTempStorage(Object)

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
                Item.DataCompositionSchemaAddress = PutToTempStorage(
                    DataCompositionSchema, New UUID);
            EndIf;
            
            DataCompositionSettings = FilterResult[0].DataCompositionSettings.Get();
            If DataCompositionSettings <> Undefined Then
                Item.DataCompositionSettingsAddress = PutToTempStorage(
                    DataCompositionSettings, New UUID);
            EndIf;

            APISchema = FilterResult[0].APISchema.Get();
            If APISchema <> Undefined Then
                Item.APISchemaAddress = PutToTempStorage(APISchema, 
                    New UUID);
            EndIf;
            
        EndDo;
        
    EndIf;
        
EndProcedure // LoadSettingsToTempStorage()

// Only for internal use.
//
Procedure ProcessBeforeWriteAtServer(FormObject, CurrentObject)
    
    FMethods = FormObject.Methods;
    CMethods = CurrentObject.Methods;
    
    FilterParameters = New Structure("Method, APIVersion");
    
    For Each FMethod In FMethods Do
        
        FillPropertyValues(FilterParameters, FMethod);
        FilterResults = CMethods.FindRows(FilterParameters);
        For Each FilterResult In FilterResults Do
            
            FillPropertyValues(FilterResult, FMethod, "OutputType, CanUseExternalFunctions"); 
            
            If IsTempStorageURL(FMethod.DataCompositionSchemaAddress) Then
                FilterResult.DataCompositionSchema = New ValueStorage(
                    GetFromTempStorage(FMethod.DataCompositionSchemaAddress));
            Else
                FilterResult.DataCompositionSchema = New ValueStorage(Undefined);
            EndIf;
            
            If IsTempStorageURL(FMethod.DataCompositionSettingsAddress) Then
                FilterResult.DataCompositionSettings = New ValueStorage(
                    GetFromTempStorage(FMethod.DataCompositionSettingsAddress));
            Else
                FilterResult.DataCompositionSettings = New ValueStorage(Undefined);
            EndIf;
            
            If IsTempStorageURL(FMethod.APISchemaAddress) Then
                FilterResult.APISchema = New ValueStorage(
                    GetFromTempStorage(FMethod.APISchemaAddress));
            Else
                FilterResult.APISchema = New ValueStorage(Undefined);
            EndIf;
            
        EndDo;
        
    EndDo;
    
EndProcedure // ProcessBeforeWriteAtServer() 
    
// Add a new group page that corresponds to a method.
//
// Parameters:
//  Items             - FormAllItems - collection of all managed form items.
//  MethodDescription - String       - the method name.
//  Description       - String       - the method description. 
//  Picture           - Picture      - title picture.
//
Procedure AddMethodOnForm(Items, MethodDescription, Description, Picture)

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
    IHL_InteriorUse.AddItemToItemFormCollection(Items, Parameters, 
        NewPage);

EndProcedure // AddMethodOnForm()


// Only for internal use.
//
Function TextQueryExchangeSettings()

    QueryText = "
        |SELECT
        |   ExchangeSettings.Ref         AS Ref,
        |   ExchangeSettings.Description AS Description,
        |   ExchangeSettings.InUse       AS InUse,
        |
        |   ExchangeSettingsMethods.APIVersion              AS APIVersion,
        |   ExchangeSettingsMethods.APISchema               AS APISchema,
        |   ExchangeSettingsMethods.DataCompositionSchema   AS DataCompositionSchema,
        |   ExchangeSettingsMethods.DataCompositionSettings AS DataCompositionSettings,
        |   ExchangeSettingsMethods.CanUseExternalFunctions AS CanUseExternalFunctions,
        |   ExchangeSettingsMethods.OutputType              AS OutputType,
        |   ExchangeSettingsMethods.OperationDescription    AS MethodDescription,
        |
        |   IHL_Methods.Ref         AS Method,
        |   IHL_Methods.RESTMethod  AS RESTMethod,
        |   IHL_Methods.CRUDMethod  AS CRUDMethod
        |
        |FROM
        |   Catalog.IHL_ExchangeSettings AS ExchangeSettings
        |   
        |INNER JOIN Catalog.IHL_ExchangeSettings.Methods AS ExchangeSettingsMethods
        |ON  ExchangeSettingsMethods.Ref = ExchangeSettings.Ref
        |   
        |INNER JOIN Catalog.IHL_Methods AS IHL_Methods
        |ON  IHL_Methods.Description = &MethodName
        |AND IHL_Methods.Ref         = ExchangeSettingsMethods.Method
        |   
        |WHERE
        |   ExchangeSettings.Description = &ExchangeName
        |AND ExchangeSettings.DeletionMark = FALSE
        |";  
    Return QueryText;

EndFunction // TextQueryExchangeSettings()

#EndRegion // ServiceProceduresAndFunctions

#EndIf