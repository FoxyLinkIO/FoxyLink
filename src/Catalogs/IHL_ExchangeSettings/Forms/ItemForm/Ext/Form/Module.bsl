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
        LoadBasicFormatInfo();    
    EndIf;
    
    Catalogs.IHL_ExchangeSettings.OnCreateAtServer(ThisObject);
    
    UpdateMethodsView();
    
EndProcedure // OnCreateAtServer()

&AtClient
Procedure OnOpen(Cancel)
    
    
    
EndProcedure // OnOpen()

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
    
    #If ThickClientOrdinaryApplication Or ThickClientManagedApplication Then
        
    If TypeOf(ChoiceSource) = Type("DataCompositionSchemaWizard")
        And TypeOf(SelectedValue) = Type("DataCompositionSchema") Then
        
        UpdateDataCompositionSchema(SelectedValue);    
        
    EndIf;
        
    #EndIf
    
EndProcedure // ChoiceProcessing() 

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
    
    // Saving settings in form object.
    SaveMethodSettings();
    
    // Saving settings in write object.
    Catalogs.IHL_ExchangeSettings.BeforeWriteAtServer(ThisObject, CurrentObject);
    
EndProcedure // BeforeWriteAtServer() 

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
    
    // If user simply saves catalog item and doesn't close this form,
    // user has some problems with editing. It helps in this case. 
    Catalogs.IHL_ExchangeSettings.OnCreateAtServer(ThisObject);    
    
EndProcedure // AfterWriteAtServer()

#EndRegion // FormEventHandlers

#Region FormItemsEventHandlers

&AtClient
Procedure BasicFormatGuidOnChange(Item)
    
    If Not IsBlankString(Object.BasicFormatGuid) Then
        LoadBasicFormatInfo();   
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



&AtClient
Procedure ChannelsSelection(Item, SelectedRow, Field, StandardProcessing)
    
    StandardProcessing = False;
    SelectedRow = Object.Channels.FindByID(SelectedRow);
    
    ChannelParameters = ChannelParameters(SelectedRow.BasicChannelGuid, "ConsoleForm"); 
    ChannelParameters.Parameters.Insert("EncryptedData", Object.EncryptedData);
    ChannelParameters.Parameters.Insert("ChannelGuid", SelectedRow.ChannelGuid);
        
    OpenForm(ChannelParameters.FormName, 
            ChannelParameters.Parameters, 
            ThisObject,
            New UUID, 
            , 
            , 
            , 
            FormWindowOpeningMode.LockOwnerWindow);
    
EndProcedure // ChannelsSelection()


#Region DataCompositionSettingsComposer

&AtClient
Procedure RowComposerSettingsSettingsOnChange(Item)
    
    Modified = True;
    RowComposerSettingsModified = True;
    
EndProcedure // RowComposerSettingsSettingsOnChange()

&AtClient
Procedure RowComposerSettingsSettingsBeforeRowChange(Item, Cancel)
    
    Modified = True;
    RowComposerSettingsModified = True;
    
EndProcedure // RowComposerSettingsSettingsBeforeRowChange()


&AtClient
Procedure RowComposerSettingsSettingsDataParametersOnChange(Item)
    
    Modified = True;
    RowComposerSettingsModified = True;    
    
EndProcedure // RowComposerSettingsSettingsDataParametersOnChange()


&AtClient
Procedure RowComposerSettingsSettingsSelectionSelectionAvailableFieldsSelection(Item, SelectedRow, Field, StandardProcessing)
    
    Modified = True;
    RowComposerSettingsModified = True;
    
EndProcedure // RowComposerSettingsSettingsSelectionSelectionAvailableFieldsSelection()

&AtClient
Procedure RowComposerSettingsSettingsSelectionOnChange(Item)
    
    Modified = True;
    RowComposerSettingsModified = True;    
    
EndProcedure // RowComposerSettingsSettingsSelectionOnChange() 


&AtClient
Procedure RowComposerSettingsSettingsFilterFilterAvailableFieldsSelection(Item, SelectedRow, Field, StandardProcessing)
   
    Modified = True;
    RowComposerSettingsModified = True;
    
EndProcedure // RowComposerSettingsSettingsFilterFilterAvailableFieldsSelection()

&AtClient
Procedure RowComposerSettingsSettingsFilterOnChange(Item)
    
    Modified = True;
    RowComposerSettingsModified = True;
    
EndProcedure // RowComposerSettingsSettingsFilterOnChange()


&AtClient
Procedure RowComposerSettingsSettingsOrderOrderAvailableFieldsSelection(Item, SelectedRow, Field, StandardProcessing)
    
    Modified = True;
    RowComposerSettingsModified = True;
    
EndProcedure // RowComposerSettingsSettingsOrderOrderAvailableFieldsSelection()

&AtClient
Procedure RowComposerSettingsSettingsOrderOnChange(Item)
    
    Modified = True;
    RowComposerSettingsModified = True;    
    
EndProcedure // RowComposerSettingsSettingsOrderOnChange()

#EndRegion // DataCompositionSettingsComposer

#EndRegion // FormItemsEventHandlers

#Region FormCommandHandlers

&AtClient
Procedure AddAPIMethod(Command)
    
    ShowChooseFromList(New NotifyDescription("DoAfterChooseMethodToAdd",
        ThisObject), AvailableMethods(), Items.AddAPIMethod);
        
EndProcedure // AddAPIMethod()
    
&AtClient
Procedure DeleteAPIMethod(Command)
    
    ShowChooseFromList(New NotifyDescription("DoAfterChooseMethodToDelete",
        ThisObject), CurrentMethods(), Items.DeleteAPIMethod);
    
EndProcedure // DeleteAPIMethod()


&AtClient
Procedure AddExchangeChannel(Command)
    
    ShowChooseFromList(New NotifyDescription("DoAfterChooseChannelToAdd",
        ThisObject), AvailableChannels(), Items.AddExchangeChannel);
        
EndProcedure // AddExchangeChannel()

&AtClient
Procedure DeleteExchangeChannel(Command)
    
    CurrentData = Items.Channels.CurrentData;
    If CurrentData <> Undefined Then
        
        ShowQueryBox(New NotifyDescription("DoAfterChooseChannelToDelete", 
            ThisObject, New Structure("Identifier ", CurrentData.GetID())),
            NStr("en = 'Are you sure that you want to permanently delete the selected channel?';
                 |ru = 'Вы действительно уверены, что хотите удалить выбранный канал?'"),
            QuestionDialogMode.YesNo, , DialogReturnCode.No);     
        
    EndIf;
    
EndProcedure // DeleteExchangeChannel()


&AtClient
Procedure EditDataCompositionSchema(Command)
    
    #If ThickClientOrdinaryApplication Or ThickClientManagedApplication Then
        
        // Copy existing data composition schema.
        DataCompositionSchema = XDTOSerializer.ReadXDTO(XDTOSerializer.WriteXDTO(
            GetFromTempStorage(DataCompositionSchemaEditAddress)));
        
        Wizard = New DataCompositionSchemaWizard(DataCompositionSchema);
        Wizard.Edit(ThisObject);
        
    #Else
        
        ShowMessageBox(Undefined,
            NStr("en = 'To edit the layout scheme, run configuration in thick client mode.';
                |ru = 'Для того, чтобы редактировать схему компоновки,  
                |необходимо запустить конфигурацию в режиме толстого клиента.'"));
        
    #EndIf
    
EndProcedure // EditDataCompositionSchema()

&AtClient
Procedure GenerateSpreadsheetDocument(Command)
    
    GenerateSpreadsheetDocumentAtServer();
    
EndProcedure // GenerateSpreadsheetDocument()

&AtClient
Procedure GenerateSpecificDocument(Command)
    
    GenerateSpecificDocumentAtServer();   
         
EndProcedure // GenerateSpecificDocument() 


&AtClient
Procedure DescribeAPI(Command)
           
    DescribeAPIData = DescribeAPIParameters();
    OpenForm(DescribeAPIData.FormName, 
        DescribeAPIData.Parameters, 
        ThisObject,
        New UUID, 
        , 
        , 
        New NotifyDescription("DoAfterCloseAPICreationForm", ThisObject), 
        FormWindowOpeningMode.LockOwnerWindow);
         
EndProcedure // DescribeAPI()

&AtClient
Procedure CopyAPI(Command)
    
    ShowChooseFromList(New NotifyDescription("DoAfterChooseMethodAPIToCopy",
        ThisObject), CurrentMethods(), Items.CopyAPI);    
    
EndProcedure // CopyAPI()

#EndRegion // FormCommandHandlers

#Region ServiceProceduresAndFunctions

#Region Formats

&AtClient
Procedure DoAfterBeginRunningApplication(CodeReturn, AdditionalParameters) Export
    
    // TODO: Some checks   
    
EndProcedure // DoAfterBeginRunningApplication() 

&AtServer
Procedure DoAfterCloseAPICreationForm(ClosureResult, AdditionalParameters) Export
    
    If ClosureResult <> Undefined Then
        If IsTempStorageURL(ClosureResult) Then
            
            Modified = True;
            CurrentData = CurrentMethodData(RowMethod);
            CurrentData.APISchemaAddress = ClosureResult;
            
        EndIf;
    EndIf;
    
EndProcedure // DoAfterCloseAPICreationForm()


// Fills basic format info.
//
&AtServer
Procedure LoadBasicFormatInfo()

    Items.HeaderGroupLeft.Visible = True;
    Items.HeaderPagesFormat.CurrentPage = Items.HeaderPageBasicFormat;
    FormatProcessor = Catalogs.IHL_ExchangeSettings.NewFormatProcessor(
        FormatProcessorName, Object.BasicFormatGuid);
        
    FormatName = StrTemplate("%1 (%2)", FormatProcessor.FormatFullName(),
        FormatProcessor.FormatShortName());
        
    FormatStandard = FormatProcessor.FormatStandard();
        
    FormatPluginVersion = FormatProcessor.Version();
    
    FPMetadata = FormatProcessor.Metadata();
    SearchResult = FPMetadata.Forms.Find("APICreationForm");
    
    Items.CopyAPI.Visible = SearchResult <> Undefined;
    Items.DescribeAPI.Visible = SearchResult <> Undefined;
    Items.GenerateSpecificDocument.Title = StrTemplate("Generate (%1, ver. %2)", 
        FormatProcessor.FormatShortName(), FormatProcessor.Version());
    
EndProcedure // LoadBasicFormatInfo() 



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

&AtServer
Function DescribeAPIParameters()
        
    FormatProcessor = Catalogs.IHL_ExchangeSettings.NewFormatProcessor(
        FormatProcessorName, Object.BasicFormatGuid);      
    FPMetadata = FormatProcessor.Metadata();

    APISchemaData = NewAPISchemaData(); 
    APISchemaData.FormName = StrTemplate("%1.%2.Form.APICreationForm",
        IHL_CommonUse.BaseTypeNameByMetadataObject(FPMetadata), FPMetadata.Name);    
    APISchemaData.Parameters.APISchemaAddress = CurrentMethodData(RowMethod)
        .APISchemaAddress; 
    
    Return APISchemaData;
    
EndFunction // DescribeAPIParameters()

// Only for internal use.
//
&AtServer
Function NewAPISchemaData()
    
    APICreationData = New Structure;
    APICreationData.Insert("FormName");
    APICreationData.Insert("Parameters", New Structure("APISchemaAddress"));
    Return APICreationData;
    
EndFunction // NewAPISchemaData()

#EndRegion // Formats 

#Region Methods

// Adds new API method to ThisObject.
//
&AtClient
Procedure DoAfterChooseMethodToAdd(SelectedElement, 
    AdditionalParameters) Export
    
    If SelectedElement <> Undefined Then
        
        // TODO: Add possibility to use different versions of API.
        FilterParameters = New Structure("APIVersion, Method", "1.0.0", 
            SelectedElement.Value);
            
        FilterResult = Object.Methods.FindRows(FilterParameters);
        If FilterResult.Count() = 0 Then
            
            Modified = True;
            
            NewMethod = Object.Methods.Add();
            NewMethod.Method = SelectedElement.Value;
            NewMethod.APIVersion = "1.0.0";
            
            UpdateMethodsView();
                        
        EndIf;
        
    EndIf;
    
EndProcedure // DoAfterChooseMethodToAdd() 

// Copies format API from the selected method to the current method.
//
&AtClient
Procedure DoAfterChooseMethodAPIToCopy(SelectedElement, 
    AdditionalParameters) Export
    
    If SelectedElement <> Undefined Then
        
        FilterResult = Object.Methods.FindRows(SelectedElement.Value);
        If FilterResult.Count() > 0 Then
            
            DescribeAPIData = DescribeAPIParameters();
            FillPropertyValues(DescribeAPIData.Parameters, FilterResult[0]);
            
            OpenForm(DescribeAPIData.FormName, 
                DescribeAPIData.Parameters, 
                ThisObject,
                New UUID, 
                , 
                ,                      
                New NotifyDescription("DoAfterCloseAPICreationForm", ThisObject), 
                FormWindowOpeningMode.LockOwnerWindow);
                
        EndIf;
        
    EndIf;
    
EndProcedure // DoAfterChooseMethodAPIToCopy()

// Deletes API method from ThisObject.
//
&AtClient
Procedure DoAfterChooseMethodToDelete(SelectedElement, 
    AdditionalParameters) Export
    
    If SelectedElement <> Undefined Then
            
        FilterResult = Object.Methods.FindRows(SelectedElement.Value);
        If FilterResult.Count() > 0 Then
            
            Modified = True;
            
            Object.Methods.Delete(FilterResult[0]);
            
            // Delete transition cache.
            FilterResult = TransitionMethodPagesHistory.FindRows(SelectedElement.Value);
            If FilterResult.Count() > 0 Then                
                TransitionMethodPagesHistory.Delete(FilterResult[0]);
            EndIf;
            
            UpdateMethodsView();
            
        EndIf;
                
    EndIf;
    
EndProcedure // DoAfterChooseMethodToDelete() 


&AtServer
Procedure GenerateSpreadsheetDocumentAtServer()
    
    ResultSpreadsheetDocument.Clear();
    
     // Start measuring.
    StartTime = CurrentUniversalDateInMilliseconds();
    
    
    DataCompositionSchema = GetFromTempStorage(
        DataCompositionSchemaEditAddress);     
    DataCompositionSettings = RowComposerSettings.GetSettings();

    DataCompositionTemplate = IHL_DataComposition
        .NewDataCompositionTemplateParameters();
    DataCompositionTemplate.Schema   = DataCompositionSchema;
    DataCompositionTemplate.Template = DataCompositionSettings;

    OutputParameters = IHL_DataComposition.NewOutputParameters();
    OutputParameters.DCTParameters = DataCompositionTemplate;
    OutputParameters.CanUseExternalFunctions = True;
    
    IHL_DataComposition.OutputInSpreadsheetDocument(Undefined, // Reserved
        ResultSpreadsheetDocument, OutputParameters);     
        
        
    // End measuring.
    TestingExecutionTime = CurrentUniversalDateInMilliseconds() - StartTime;
        
    Items.HiddenPageTestingResults.CurrentPage = 
        Items.HiddenPageTestingSpreadsheetDocument;
        
EndProcedure // GenerateSpreadsheetDocumentAtServer()

&AtServer
Procedure GenerateSpecificDocumentAtServer()

    Var APISchema;
    
    ResultTextDocument.Clear();
    
    // Start measuring.
    StartTime = CurrentUniversalDateInMilliseconds();
    
    // Read API schema from temp storage address.
    CurrentData = CurrentMethodData(RowMethod);
    If IsTempStorageURL(CurrentData.APISchemaAddress) Then
        APISchema = GetFromTempStorage(CurrentData.APISchemaAddress);    
    EndIf;
    
     
    DataCompositionSchema = GetFromTempStorage(
        DataCompositionSchemaEditAddress);     
    DataCompositionSettings = RowComposerSettings.GetSettings();

    DataCompositionTemplate = IHL_DataComposition
        .NewDataCompositionTemplateParameters();
    DataCompositionTemplate.Schema   = DataCompositionSchema;
    DataCompositionTemplate.Template = DataCompositionSettings;

    OutputParameters = IHL_DataComposition.NewOutputParameters();
    OutputParameters.DCTParameters = DataCompositionTemplate;
    OutputParameters.CanUseExternalFunctions = RowCanUseExternalFunctions;
    
    StreamObject = Catalogs.IHL_ExchangeSettings.NewFormatProcessor(
        FormatProcessorName, Object.BasicFormatGuid);
    StreamObject.Initialize(APISchema);    
    
    IHL_DataComposition.Output(Undefined, StreamObject, OutputParameters, 
        RowOutputType = 1); // Convert to boolean type (sequential output).
        
    Result = StreamObject.Close();
    
    
    // End measuring.
    TestingExecutionTime = CurrentUniversalDateInMilliseconds() - StartTime;
    
    ResultTextDocument.AddLine(Result);
    Items.HiddenPageTestingResults.CurrentPage = 
        Items.HiddenPageTestingTextDocument;
    
EndProcedure // GenerateSpecificDocumentAtServer() 


// See function Catalogs.IHL_Methods.UpdateMethodsView.
//
&AtServer
Procedure UpdateMethodsView()
    
    Catalogs.IHL_ExchangeSettings.UpdateMethodsView(ThisObject);   
    
    LoadMethodSettings();
    
EndProcedure // UpdateMethodsView()

// Applies changes to data composition schema.
//
// Parameters:
//  DataCompositionSchema - DataCompositionSchema - updated data composition schema.
//
&AtServer
Procedure UpdateDataCompositionSchema(DataCompositionSchema)

    Changes = False;
    IHL_DataComposition.CopyDataCompositionSchema(
        DataCompositionSchemaEditAddress, 
        DataCompositionSchema, 
        True, 
        Changes);

    Modified = Modified Or Changes;
    RowComposerSettingsModified = RowComposerSettingsModified Or Changes;
    RowDataCompositionSchemaModified = RowDataCompositionSchemaModified Or Changes;
        
    If Changes = True Then
        
        // Init data composer by new data composition schema.
        IHL_DataComposition.InitSettingsComposer(Undefined, // Reserved
            RowComposerSettings, 
            DataCompositionSchemaEditAddress);

    Endif;

EndProcedure // UpdateDataCompositionSchema() 

&AtServer
Procedure LoadMethodSettings()
    
    ResultTextDocument.Clear();
    ResultSpreadsheetDocument.Clear();

    SaveMethodSettings();
        
    CurrentPage = Items.MethodPages.CurrentPage;
    If CurrentPage = Undefined And Items.MethodPages.ChildItems.Count() > 0 Then
        CurrentPage = Items.MethodPages.ChildItems[0];
    EndIf;
    
    If CurrentPage <> Undefined Then
       
        RowMethod = CurrentPage.Name;
        IHL_InteriorUse.MoveItemInItemFormCollection(Items, 
            "HiddenGroupSettings", RowMethod);
           
        CurrentData = CurrentMethodData(RowMethod);
        RowAPIVersion = CurrentData.APIVersion;
        RowOutputType = CurrentData.OutputType;
        RowCanUseExternalFunctions = CurrentData.CanUseExternalFunctions;
        
        
        UpdateMethodView(ThisObject, CurrentData);
        
        // Create schema, if needed.
        If IsBlankString(CurrentData.DataCompositionSchemaAddress) Then
            CurrentData.DataCompositionSchemaAddress = PutToTempStorage(
                New DataCompositionSchema, ThisObject.UUID);
        EndIf;
            
        IHL_DataComposition.CopyDataCompositionSchema(
            DataCompositionSchemaEditAddress,
            CurrentData.DataCompositionSchemaAddress);
            
        // It isn't error, we have to continue loading catalog form to fix bugs
        // if configuration is changed.
        Try
            
            IHL_DataComposition.InitSettingsComposer(Undefined, // Reserved
                RowComposerSettings, 
                CurrentData.DataCompositionSchemaAddress, 
                CurrentData.DataCompositionSettingsAddress);
                
        Except
            
            IHL_CommonUseClientServer.NotifyUser(ErrorDescription());    
            
        EndTry; 
             
    Else

        RowMethod = Undefined;
        RowAPIVersion = Undefined;
        RowOutputType = Undefined;
        RowCanUseExternalFunctions = Undefined;
        DataCompositionSchemaEditAddress = "";
        RowComposerSettings = New DataCompositionSettingsComposer;
            
    EndIf;    
    
EndProcedure // LoadMethodSettings()

// Saves all untracked changes in form object.
//
&AtServer
Procedure SaveMethodSettings()

    If Not IsBlankString(RowMethod) Then
        
        If Items.MethodPages.ChildItems.Find(RowMethod) <> Undefined Then
        
            ChangedData = CurrentMethodData(RowMethod);
            ChangedData.OutputType = RowOutputType;
            ChangedData.CanUseExternalFunctions = RowCanUseExternalFunctions;
            
            If RowDataCompositionSchemaModified Then
                
                IHL_DataComposition.CopyDataCompositionSchema(
                    ChangedData.DataCompositionSchemaAddress, 
                    DataCompositionSchemaEditAddress);
                    
            EndIf;

            If RowComposerSettingsModified Then
                
                IHL_CommonUseClientServer.PutSerializedValueToTempStorage(
                    RowComposerSettings.GetSettings(), 
                    ChangedData.DataCompositionSettingsAddress, 
                    ThisObject.UUID);
                    
            EndIf;
          
        EndIf;
        
    EndIf;
    
    RowComposerSettingsModified = False;
    RowDataCompositionSchemaModified = False;

EndProcedure // SaveMethodSettings() 



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

// Finds and returns method data in object.
//
// Parameters:
//  RowMethod - String - the method name.
//
// Returns:
//   FormDataCollectionItem - method data.
//
&AtServer
Function CurrentMethodData(Val RowMethod)

    Method = Catalogs.IHL_Methods.MethodByDescription(RowMethod);
    
    FilterParameters = New Structure("Method", Method);
    FilterResult = TransitionMethodPagesHistory.FindRows(FilterParameters);
    If FilterResult.Count() > 0 Then 
        FilterParameters.Insert("APIVersion", FilterResult[0].APIVersion);
        TransitionMethodPagesHistory.Delete(FilterResult[0]);
    EndIf;
    
    FilterResult = Object.Methods.FindRows(FilterParameters);
    If FilterResult.Count() > 0 Then
        
        CurrentData = FilterResult[0];
        NewRow = TransitionMethodPagesHistory.Add();
        FillPropertyValues(NewRow, CurrentData);

    Else
        
        ErrorMessage = NStr("en = 'Critical error, method not found.';
            |ru = 'Критическая ошибка, метод не найден.'");
        Raise ErrorMessage;     
        
    EndIf;
        
    Return CurrentData;    

EndFunction // CurrentMethodData()  


// Updates the view of the method on the form.
//
// Parameters:
//  ThisObject  - ManagedForm            - catalog form.
//  CurrentData - FormDataCollectionItem - the current method data.
// 
&AtServerNoContext
Procedure UpdateMethodView(ThisObject, CurrentData)

    Items = ThisObject.Items;
    Items.Channels.RowFilter = New FixedStructure("Method, APIVersion", 
        CurrentData.Method, CurrentData.APIVersion);  

EndProcedure // UpdateMethodView() 

#EndRegion // Methods

#Region Channels

// Adds new channel to API method to ThisObject.
//
&AtClient
Procedure DoAfterChooseChannelToAdd(SelectedElement, 
    AdditionalParameters) Export
    
    If SelectedElement <> Undefined Then
        
        ChannelParameters = ChannelParameters(SelectedElement.Value);
        OpenForm(ChannelParameters.FormName, 
            ChannelParameters.Parameters, 
            ThisObject,
            New UUID, 
            , 
            , 
            New NotifyDescription("DoAfterCloseChannelForm", ThisObject, 
                ChannelParameters), 
            FormWindowOpeningMode.LockOwnerWindow);
                    
    EndIf;
    
EndProcedure // DoAfterChooseChannelToAdd() 

&AtClient
Procedure DoAfterChooseChannelToDelete(QuestionResult, 
    AdditionalParameters) Export
    
    Var Identifier;
    
    If QuestionResult = DialogReturnCode.Yes Then
        If TypeOf(AdditionalParameters) = Type("Structure")
            And AdditionalParameters.Property("Identifier", Identifier) Then
            
            SearchResult = Object.Channels.FindByID(Identifier);
            If SearchResult <> Undefined Then
                
                ChannelGuid = SearchResult.ChannelGuid;
                Object.Channels.Delete(SearchResult);
                
                FilterResult = Object.EncryptedData.FindRows(
                    New Structure("ChannelGuid", ChannelGuid));
                For Each RowItem In FilterResult Do     
                    Object.EncryptedData.Delete(RowItem);        
                EndDo;
                
                Modified = True;
                
            EndIf;
            
        EndIf; 
    EndIf;
    
EndProcedure // DoAfterChooseChannelToDelete()

&AtServer
Procedure DoAfterCloseChannelForm(ClosureResult, AdditionalParameters) Export
    
    If ClosureResult <> Undefined Then
        
        If TypeOf(ClosureResult) = Type("FormDataCollection") Then
            
            Modified = True;
            
            ChannelGuid = String(New UUID);
            CurrentData = CurrentMethodData(RowMethod);
            
            NewChannel = Object.Channels.Add(); 
            NewChannel.ChannelGuid = ChannelGuid;
            FillPropertyValues(NewChannel, CurrentData, "Method, APIVersion");
            FillPropertyValues(NewChannel, AdditionalParameters);
            
            For Each Item In ClosureResult Do
                NewData = Object.EncryptedData.Add();        
                NewData.ChannelGuid = ChannelGuid;
                FillPropertyValues(NewData, Item);
            EndDo;
            
        EndIf;
        
    EndIf;
    
EndProcedure // DoAfterCloseChannelForm()





// See function Catalogs.IHL_ExchangeSettings.AvailableChannels.
//
&AtServer
Function AvailableChannels()
    
    Return Catalogs.IHL_ExchangeSettings.AvailableChannels();
    
EndFunction // AvailableChannels()

// Only for internal use.
//
&AtServer
Function ChannelParameters(Val LibraryGuid, Val FormName = "ChannelForm")
    
    ChannelProcessor = Catalogs.IHL_ExchangeSettings.NewChannelProcessor(
        LibraryGuid);      
    CPMetadata = ChannelProcessor.Metadata();

    ChannelParameters = NewChannelParameters(); 
    ChannelParameters.FormName = StrTemplate("%1.%2.Form.%3",
        IHL_CommonUse.BaseTypeNameByMetadataObject(CPMetadata), 
        CPMetadata.Name, 
        FormName);        
    ChannelParameters.FullName = ChannelProcessor.ChannelFullName();
    ChannelParameters.ShortName = ChannelProcessor.ChannelShortName();
    ChannelParameters.BasicChannelGuid = LibraryGuid;
       
    Return ChannelParameters;
 
EndFunction // ChannelParameters() 

// Only for internal use.
//
&AtServerNoContext
Function NewChannelParameters()
    
    Parameters = New Structure;
    Parameters.Insert("Valid", True);
    Parameters.Insert("FormName");
    Parameters.Insert("FullName");
    Parameters.Insert("ShortName");
    Parameters.Insert("BasicChannelGuid");
    Parameters.Insert("Parameters", New Structure());
    Return Parameters;     
    
EndFunction // NewChannelParameters()

#EndRegion // Channels

#EndRegion // ServiceProceduresAndFunctions