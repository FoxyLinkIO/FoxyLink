////////////////////////////////////////////////////////////////////////////////
// This file is part of FoxyLink.
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
// along with FoxyLink. If not, see <http://www.gnu.org/licenses/agpl-3.0>.
//
////////////////////////////////////////////////////////////////////////////////

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
    
    If IsBlankString(Object.BasicFormatGuid) Then
        For Each Format In Catalogs.FL_Exchanges.AvailableFormats() Do
            FillPropertyValues(Items.BasicFormatGuid.ChoiceList.Add(), Format);    
        EndDo;
        Items.HeaderPagesFormat.CurrentPage = Items.HeaderPageSelectFormat;
        Items.HeaderGroupLeft.Visible = False;
    Else
        LoadBasicFormatInfo();    
    EndIf;
    
    Catalogs.FL_Exchanges.OnCreateAtServer(ThisObject);
    
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
    Catalogs.FL_Exchanges.BeforeWriteAtServer(ThisObject, CurrentObject);
    
EndProcedure // BeforeWriteAtServer() 

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
    
    // If user simply saves catalog item and doesn't close this form,
    // user has some problems with editing. It helps in this case. 
    Catalogs.FL_Exchanges.OnCreateAtServer(ThisObject);    
    
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
    
    ChannelParameters = ChannelParameters(SelectedRow.Channel, "ChannelForm");
    ChannelParameters.Insert("ChannelRef", SelectedRow.Channel);
 
    OpenForm(ChannelParameters.FormName, 
        ChannelParameters, 
        ThisObject,
        New UUID, 
        , 
        ,
        //New NotifyDescription("DoAfterCloseConnectionForm", ThisObject, 
        //    ChannelParameters)
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
Procedure AddEvent(Command)
    
    OpenForm("Catalog.FL_Exchanges.Form.EventsSelectionForm", 
        , 
        ThisObject,
        New UUID, 
        , 
        ,
        New NotifyDescription("DoAfterChooseEventToAdd", ThisObject)
        , 
        FormWindowOpeningMode.LockOwnerWindow);    
    
EndProcedure // AddEvent()

&AtClient
Procedure FireEvent(Command)
    
    CurrentData = Items.Events.CurrentData;
    If CurrentData <> Undefined Then
        
        ShowQueryBox(New NotifyDescription("DoAfterChooseEventToFire", 
            ThisObject, New Structure("Identifier ", CurrentData.GetID())),
            NStr("en = 'Fire the event for all objects from the metadata?';
                 |ru = 'Вызвать событие для всех объектов из метаданного?'"),
            QuestionDialogMode.YesNo, , DialogReturnCode.No);
        
    EndIf;
    
EndProcedure // FireEvent()

&AtClient
Procedure DeleteEvent(Command)
    
    CurrentData = Items.Events.CurrentData;
    If CurrentData <> Undefined Then
        
        ShowQueryBox(New NotifyDescription("DoAfterChooseEventToDelete", 
            ThisObject, New Structure("Identifier ", CurrentData.GetID())),
            NStr("en = 'Permanently delete the selected event?';
                 |ru = 'Удалить выбранное событие?'"),
            QuestionDialogMode.YesNo, , DialogReturnCode.No);     
        
    EndIf;
    
EndProcedure // DeleteEvent() 


&AtClient
Procedure AddChannel(Command)
    
    // It is needed to clear resource cache.
    TransitionChannelResources.Clear();
    
    ShowChooseFromList(New NotifyDescription("DoAfterChooseChannelToAdd",
        ThisObject), ExchangeChannels(), Items.AddChannel);
        
EndProcedure // AddChannel()

&AtClient
Procedure EditChannelResources(Command)
   
    // It is needed to clear resource cache.
    TransitionChannelResources.Clear();
    
    CurrentData = Items.Channels.CurrentData;
    If CurrentData <> Undefined Then
        ChannelParameters = RequiredChannelResources(CurrentData.Channel);
        If ChannelParameters <> Undefined Then
            
            FilterParameters = ChannelFilterParameters();
            FillPropertyValues(FilterParameters, CurrentData);
            FilterResults = Object.ChannelResources.FindRows(FilterParameters);
            For Each FilterResult In FilterResults Do
                FillPropertyValues(TransitionChannelResources.Add(), FilterResult);         
            EndDo;
            
            OpenChannelResourceForm(ChannelParameters, CurrentData.Channel);
            
        EndIf;
    EndIf;
    
EndProcedure // EditChannelResources()

&AtClient
Procedure ChannelResponseHandler(Command)
    
    CurrentData = Items.Channels.CurrentData;
    If CurrentData <> Undefined Then
        OpenForm("CommonForm.FL_ResponseHandlerForm", 
            New Structure("ResponseHandler", CurrentData.ResponseHandler), 
            ThisObject,
            New UUID, 
            , 
            ,
            New NotifyDescription("DoAfterCloseResponseHandlerForm", ThisObject, 
                CurrentData.GetID())
            , 
            FormWindowOpeningMode.LockOwnerWindow);        
    EndIf;
    
EndProcedure // ChannelResponseHandler()

&AtClient
Procedure DeleteChannel(Command)
    
    CurrentData = Items.Channels.CurrentData;
    If CurrentData <> Undefined Then
        
        ShowQueryBox(New NotifyDescription("DoAfterChooseChannelToDelete", 
            ThisObject, New Structure("Identifier", CurrentData.GetID())),
            NStr("en = 'Permanently delete the selected channel?';
                 |ru = 'Удалить выбранный канал?'"),
            QuestionDialogMode.YesNo, , DialogReturnCode.No);     
        
    EndIf;
    
EndProcedure // DeleteChannel()


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
        ThisObject), CurrentMethodsWithAPISchema(), Items.CopyAPI);    
    
EndProcedure // CopyAPI()

&AtClient
Procedure DeleteAPI(Command)
    
    ShowQueryBox(New NotifyDescription("DoAfterChooseAPISchemaToDelete", 
            ThisObject),
        NStr("en = 'Delete API schema from the current method?';
             |ru = 'Удалить API схему из текущего метода?'"),
        QuestionDialogMode.YesNo, 
        , 
        DialogReturnCode.No);    
    
EndProcedure // DeleteAPI()

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
        If TypeOf(ClosureResult) = Type("String") Then
            
            Modified = True;
            CurrentData = CurrentMethodData(RowMethod);
            CurrentData.APISchemaAddress = ClosureResult;
            
            UpdateMethodView(CurrentData);
            
        EndIf;
    EndIf;
    
EndProcedure // DoAfterCloseAPICreationForm()

// Copies API schema from the selected method to the current method.
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

// Deletes API schema from the current method.
//
&AtClient
Procedure DoAfterChooseAPISchemaToDelete(QuestionResult, 
    AdditionalParameters) Export
    
    If QuestionResult = DialogReturnCode.Yes Then
        DoAfterCloseAPICreationForm("", Undefined);
    EndIf;    
    
EndProcedure // DoAfterChooseAPISchemaToDelete()



// Fills basic format info.
//
&AtServer
Procedure LoadBasicFormatInfo()

    Items.HeaderGroupLeft.Visible = True;
    Items.HeaderPagesFormat.CurrentPage = Items.HeaderPageBasicFormat;
    FormatProcessor = Catalogs.FL_Exchanges.NewFormatProcessor(
        Object.BasicFormatGuid);
        
    FormatName = StrTemplate("%1 (%2)", FormatProcessor.FormatFullName(),
        FormatProcessor.FormatShortName());
        
    FormatStandard = FormatProcessor.FormatStandard();
        
    FormatPluginVersion = FormatProcessor.Version();
    
    FPMetadata = FormatProcessor.Metadata();
    FormatAPISchemaSupport = FPMetadata.Forms.Find("APICreationForm") <> Undefined;

    Items.DescribeAPI.Visible = FormatAPISchemaSupport;
    Items.GenerateSpecificDocument.Title = StrTemplate("Generate (%1, ver. %2)", 
        FormatProcessor.FormatShortName(), FormatProcessor.Version());
    
EndProcedure // LoadBasicFormatInfo() 



// Returns link to the formal document from the Internet Engineering Task Force 
// (IETF) that is the result of committee drafting and subsequent review 
// by interested parties.
//
&AtServer
Function FormatStandardLink() 
    
     FormatProcessor = Catalogs.FL_Exchanges.NewFormatProcessor(
        Object.BasicFormatGuid);     
     Return FormatProcessor.FormatStandardLink();
    
EndFunction // FormatStandardLink()

&AtServer
Function DescribeAPIParameters()
        
    FormatProcessor = Catalogs.FL_Exchanges.NewFormatProcessor(
        Object.BasicFormatGuid);      
    FormatProcessorMetadata = FormatProcessor.Metadata();

    APISchemaData = NewAPISchemaData(); 
    APISchemaData.FormName = StrTemplate("%1.Form.APICreationForm", 
        FormatProcessorMetadata.FullName());    
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

// Deletes API method from ThisObject.
//
&AtClient
Procedure DoAfterChooseMethodToDelete(SelectedElement, 
    AdditionalParameters) Export
    
    If SelectedElement <> Undefined Then
            
        FilterResult = Object.Methods.FindRows(SelectedElement.Value);
        If FilterResult.Count() > 0 Then
            
            Modified = True;
            
            FL_CommonUseClientServer.DeleteRowsByFilter(Object.Events, 
                SelectedElement.Value, Modified);
                
            FL_CommonUseClientServer.DeleteRowsByFilter(Object.Channels, 
                SelectedElement.Value, Modified);
                
            FL_CommonUseClientServer.DeleteRowsByFilter(Object.ChannelResources, 
                SelectedElement.Value, Modified);

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

    DataCompositionTemplate = FL_DataComposition
        .NewDataCompositionTemplateParameters();
    DataCompositionTemplate.Schema   = DataCompositionSchema;
    DataCompositionTemplate.Template = DataCompositionSettings;

    OutputParameters = FL_DataComposition.NewOutputParameters();
    OutputParameters.DCTParameters = DataCompositionTemplate;
    OutputParameters.CanUseExternalFunctions = True;
    
    FL_DataComposition.OutputInSpreadsheetDocument(Undefined, // Reserved
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
    
    
    ExchangeSettings = Catalogs.FL_Exchanges.NewExchangeSettings();
    ExchangeSettings.BasicFormatGuid = Object.BasicFormatGuid;
    
    // Read API schema from temp storage address.
    CurrentData = CurrentMethodData(RowMethod);
    If IsTempStorageURL(CurrentData.APISchemaAddress) Then
        ExchangeSettings.APISchema = GetFromTempStorage(
            CurrentData.APISchemaAddress);    
    EndIf;
    
    ExchangeSettings.DataCompositionSchema = GetFromTempStorage(
        DataCompositionSchemaEditAddress);     
    ExchangeSettings.DataCompositionSettings = RowComposerSettings
        .GetSettings();
    ExchangeSettings.CanUseExternalFunctions = RowCanUseExternalFunctions;
    
    ResultMessage = Catalogs.FL_Exchanges.GenerateMessageResult(Undefined,
        New FixedStructure(ExchangeSettings));
        
        
    // End measuring.
    TestingExecutionTime = CurrentUniversalDateInMilliseconds() - StartTime;
    
    ResultTextDocument.AddLine(ResultMessage);
    Items.HiddenPageTestingResults.CurrentPage = 
        Items.HiddenPageTestingTextDocument;
    
EndProcedure // GenerateSpecificDocumentAtServer() 


// See function Catalogs.FL_Methods.UpdateMethodsView.
//
&AtServer
Procedure UpdateMethodsView()
    
    Catalogs.FL_Exchanges.UpdateMethodsView(ThisObject);   
    
    LoadMethodSettings();
    
EndProcedure // UpdateMethodsView()

// Updates the view of the method on the form.
//
// Parameters:
//  CurrentData - FormDataCollectionItem - the current method data.
// 
&AtServer
Procedure UpdateMethodView(CurrentData)

    If ThisObject.FormatAPISchemaSupport Then
        
        Items.CopyAPI.Visible = False;
        Items.DeleteAPI.Visible = IsTempStorageURL(CurrentData.APISchemaAddress);
        For Each Row In Object.Methods Do
        
            If Row.GetID() = CurrentData.GetID() Then
                Continue;
            EndIf;
            
            If IsTempStorageURL(Row.APISchemaAddress) Then
                Items.CopyAPI.Visible = True;
                Break;    
            EndIf;
        
        EndDo;
        
    EndIf;
    
    FilterParameters = NewMethodFilterParameters();
    FillPropertyValues(FilterParameters, CurrentData);
    Items.Events.RowFilter = New FixedStructure(FilterParameters);
    Items.Channels.RowFilter = New FixedStructure(FilterParameters);

EndProcedure // UpdateMethodView() 

// Applies changes to data composition schema.
//
// Parameters:
//  DataCompositionSchema - DataCompositionSchema - updated data composition schema.
//
&AtServer
Procedure UpdateDataCompositionSchema(DataCompositionSchema)

    Changes = False;
    FL_DataComposition.CopyDataCompositionSchema(
        DataCompositionSchemaEditAddress, 
        DataCompositionSchema, 
        True, 
        Changes);

    Modified = Modified Or Changes;
    RowComposerSettingsModified = RowComposerSettingsModified Or Changes;
    RowDataCompositionSchemaModified = RowDataCompositionSchemaModified Or Changes;
        
    If Changes = True Then
        
        // Init data composer by new data composition schema.
        FL_DataComposition.InitSettingsComposer(Undefined, // Reserved
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
        FL_InteriorUse.MoveItemInItemFormCollection(Items, 
            "HiddenGroupSettings", RowMethod);
           
        CurrentData = CurrentMethodData(RowMethod);
        RowAPIVersion = CurrentData.APIVersion;
        RowCanUseExternalFunctions = CurrentData.CanUseExternalFunctions;
        
        
        UpdateMethodView(CurrentData);
        
        // Create schema, if needed.
        If IsBlankString(CurrentData.DataCompositionSchemaAddress) Then
            CurrentData.DataCompositionSchemaAddress = PutToTempStorage(
                New DataCompositionSchema, ThisObject.UUID);
        EndIf;
            
        FL_DataComposition.CopyDataCompositionSchema(
            DataCompositionSchemaEditAddress,
            CurrentData.DataCompositionSchemaAddress);
            
        // It isn't error, we have to continue loading catalog form to fix bugs
        // if configuration is changed.
        Try
            
            FL_DataComposition.InitSettingsComposer(Undefined, // Reserved
                RowComposerSettings, 
                CurrentData.DataCompositionSchemaAddress, 
                CurrentData.DataCompositionSettingsAddress);
                
        Except
            
            FL_CommonUseClientServer.NotifyUser(ErrorDescription());    
            
        EndTry; 
             
    Else

        RowMethod = Undefined;
        RowAPIVersion = Undefined;
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
            ChangedData.CanUseExternalFunctions = RowCanUseExternalFunctions;
            
            If RowDataCompositionSchemaModified Then
                
                FL_DataComposition.CopyDataCompositionSchema(
                    ChangedData.DataCompositionSchemaAddress, 
                    DataCompositionSchemaEditAddress);
                    
            EndIf;

            If RowComposerSettingsModified Then
                
                FL_CommonUseClientServer.PutSerializedValueToTempStorage(
                    RowComposerSettings.GetSettings(), 
                    ChangedData.DataCompositionSettingsAddress, 
                    ThisObject.UUID);
                    
            EndIf;
          
        EndIf;
        
    EndIf;
    
    RowComposerSettingsModified = False;
    RowDataCompositionSchemaModified = False;

EndProcedure // SaveMethodSettings() 



// See function Catalogs.FL_Methods.AvailableMethods.
//
&AtServer
Function AvailableMethods()
    
    Return Catalogs.FL_Methods.AvailableMethods();
    
EndFunction // AvailableMethods()

// Returns list of currently used methods.
//
&AtServer
Function CurrentMethods()
    
    ValueList = New ValueList();
    For Each Item In Object.Methods Do
        
        ValueItem = NewMethodFilterParameters();
        FillPropertyValues(ValueItem, Item);
        ValueList.Add(ValueItem, StrTemplate("%1, ver. %2", Item.Method,
            Item.APIVersion));   
    EndDo;
    
    Return ValueList;
    
EndFunction // CurrentMethods()

// Returns list of currently used methods with filled API schema.
//
&AtServer
Function CurrentMethodsWithAPISchema()
    
    ValueList = New ValueList();
    CurrentData = CurrentMethodData(RowMethod);  
    For Each Item In Object.Methods Do
        
        If Item.GetID() = CurrentData.GetID() Then
            Continue;
        EndIf;
        
        If IsTempStorageURL(Item.APISchemaAddress) Then
            
            ValueItem = NewMethodFilterParameters();
            FillPropertyValues(ValueItem, Item);
            ValueList.Add(ValueItem, StrTemplate("%1, ver. %2", Item.Method, 
                Item.APIVersion));
                
        EndIf;
    EndDo;
    
    Return ValueList;
    
EndFunction // CurrentMethodsWithAPISchema()

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

    Method = Catalogs.FL_Methods.MethodByDescription(RowMethod);
    
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



// Only for internal use.
//
&AtClientAtServerNoContext
Function NewMethodFilterParameters()

    FilterParameters = New Structure;
    FilterParameters.Insert("APIVersion");
    FilterParameters.Insert("Method");
    Return FilterParameters;

EndFunction // NewMethodFilterParameters() 

#EndRegion // Methods

#Region Events

// Adds new subscriptions on events.
//
&AtClient
Procedure DoAfterChooseEventToAdd(ClosureResult, 
    AdditionalParameters) Export
    
    If ClosureResult <> Undefined Then
        If TypeOf(ClosureResult) = Type("Array") Then
            AddEventAtServer(ClosureResult);            
        EndIf;           
    EndIf;
    
EndProcedure // DoAfterChooseEventToAdd() 

// Adds new subscriptions on events.
//
&AtClient
Procedure DoAfterChooseEventToFire(QuestionResult, 
    AdditionalParameters) Export
    
    Var Identifier;
    
    If QuestionResult = DialogReturnCode.Yes Then
        If TypeOf(AdditionalParameters) = Type("Structure")
         And AdditionalParameters.Property("Identifier", Identifier) Then
            FireEventAtServer(Identifier);            
        EndIf; 
    EndIf;
    
EndProcedure // DoAfterChooseEventsToAdd() 

// Deletes the selected event.
//
&AtClient
Procedure DoAfterChooseEventToDelete(QuestionResult, 
    AdditionalParameters) Export
    
    Var Identifier;
    
    If QuestionResult = DialogReturnCode.Yes Then
        If TypeOf(AdditionalParameters) = Type("Structure")
            And AdditionalParameters.Property("Identifier", Identifier) Then
            
            SearchResult = Object.Events.FindByID(Identifier);
            If SearchResult <> Undefined Then
                
                Modified = True;
                
                Object.Events.Delete(SearchResult);                
                
            EndIf;
            
        EndIf; 
    EndIf;
    
EndProcedure // DoAfterChooseEventToDelete()


// Only for internal use.
//
&AtServer
Procedure AddEventAtServer(EventsArray)

    CurrentData = CurrentMethodData(RowMethod);   
    
    FilterParameters = NewEventFilterParameters();
    FillPropertyValues(FilterParameters, CurrentData, "APIVersion, Method");
    
    FL_CommonUseClientServer.DeleteRowsByFilter(Object.Events, 
        FilterParameters, Modified);
    
    For Each Event In EventsArray Do
        
        Modified = True;
        EventRow = Object.Events.Add();
        EventRow.MetadataObject = Event;
        FillPropertyValues(EventRow, FilterParameters);
        
    EndDo;
    
EndProcedure // AddEventAtServer() 

// Only for internal use.
//
&AtServer
Procedure FireEventAtServer(Identifier)
    
    SearchResult = Object.Events.FindByID(Identifier);
    If SearchResult = Undefined Then
        Return;          
    EndIf;
    
    Query = New Query;
    Query.Text = StrTemplate("SELECT Ref As Source From %1", 
        SearchResult.MetadataObject);
    QueryResult = Query.Execute();
    If Not QueryResult.IsEmpty() Then 
        
        CurrentData = CurrentMethodData(RowMethod);
        
        QueryParameters = New Structure;
        QueryParameters.Insert("Owner", Object.Ref);
        QueryParameters.Insert("APIVersion", CurrentData.APIVersion);
        QueryParameters.Insert("Method", CurrentData.Method);
        
        QueryResultSelection = QueryResult.Select();
        While QueryResultSelection.Next() Do
            Catalogs.FL_Jobs.CreateMessage(
                QueryResultSelection.Source, QueryParameters);       
        EndDo;
        
    EndIf;
        
EndProcedure // FireEventAtServer() 


// Only for internal use.
//
&AtClientAtServerNoContext
Function NewEventFilterParameters()

    FilterParameters = New Structure;
    FilterParameters.Insert("APIVersion");
    //FilterParameters.Insert("MetadataObject");
    FilterParameters.Insert("Method");
    Return FilterParameters;

EndFunction // NewEventFilterParameters() 

#EndRegion // Events

#Region Channels

// Adds new channel to API method to ThisObject.
//
&AtClient
Procedure DoAfterChooseChannelToAdd(SelectedElement, 
    AdditionalParameters) Export
    
    If SelectedElement <> Undefined Then
        
        ChannelRef = SelectedElement.Value;
        ChannelParameters = RequiredChannelResources(ChannelRef);
        If ChannelParameters <> Undefined Then
            OpenChannelResourceForm(ChannelParameters, ChannelRef);       
        Else    
            AddChannelAtServer(ChannelRef);    
        EndIf;
                   
    EndIf;
    
EndProcedure // DoAfterChooseChannelToAdd() 

// Deletes the selected channel.
//
&AtClient
Procedure DoAfterChooseChannelToDelete(QuestionResult, 
    AdditionalParameters) Export
    
    Var Identifier;
    
    If QuestionResult = DialogReturnCode.Yes Then
        If TypeOf(AdditionalParameters) = Type("Structure")
            And AdditionalParameters.Property("Identifier", Identifier) Then
            
            SearchResult = Object.Channels.FindByID(Identifier);
            If SearchResult <> Undefined Then
                
                Modified = True;
                
                FilterParameters = ChannelFilterParameters();
                FillPropertyValues(FilterParameters, SearchResult);
                FL_CommonUseClientServer.DeleteRowsByFilter(Object.ChannelResources, 
                    FilterParameters, Modified);
                
                Object.Channels.Delete(SearchResult);                
                
            EndIf;
            
        EndIf; 
    EndIf;
    
EndProcedure // DoAfterChooseChannelToDelete()

// Fills required channel resources.
//
&AtClient
Procedure DoAfterCloseChannelResourcesForm(ClosureResult, 
    ChannelRef) Export
    
    If ClosureResult <> Undefined Then

        If TypeOf(ClosureResult) = Type("FormDataStructure") Then
            
            ChannelIdentifier = AddChannelAtServer(ChannelRef);
            ChannelRow = Object.Channels.FindByID(ChannelIdentifier);
            
            If ClosureResult.Property("ChannelResources") And
                TypeOf(ClosureResult.ChannelResources) = Type("FormDataCollection") Then
                
                Modified = True;
                FilterParameters = ChannelFilterParameters();
                FillPropertyValues(FilterParameters, ChannelRow);
                
                FilterResults = Object.ChannelResources.FindRows(FilterParameters);
                If FilterResults.Count() Then
                    For Each FilterResult In FilterResults Do
                        Object.ChannelResources.Delete(FilterResult);    
                    EndDo;         
                EndIf;
                
                For Each Item In ClosureResult.ChannelResources Do
                    NewData = Object.ChannelResources.Add();
                    FillPropertyValues(NewData, ChannelRow);
                    FillPropertyValues(NewData, Item);
                EndDo; 
                
            EndIf;
            
        EndIf;
 
    EndIf;
    
EndProcedure // DoAfterCloseChannelResourcesForm()

// Fills channel response handler.
//
&AtClient
Procedure DoAfterCloseResponseHandlerForm(ClosureResult, 
    ID) Export
    
    If ClosureResult <> Undefined Then
        If TypeOf(ClosureResult) = Type("String") Then
            CurrentData = Object.Channels.FindByID(ID);
            If CurrentData <> Undefined Then
                Modified = True;
                CurrentData.ResponseHandler = ClosureResult;        
            EndIf;
        EndIf;
    EndIf;
    
EndProcedure // DoAfterCloseResponseHandlerForm() 


&AtClient
Procedure OpenChannelResourceForm(ChannelParameters, ChannelRef)
    
    ChannelParameters.Insert("ChannelResources", TransitionChannelResources);
    OpenForm(ChannelParameters.FormName, 
        ChannelParameters, 
        ThisObject,
        New UUID, 
        , 
        ,
        New NotifyDescription("DoAfterCloseChannelResourcesForm", ThisObject, 
            ChannelRef)
        , 
        FormWindowOpeningMode.LockOwnerWindow);
    
EndProcedure // OpenChannelResourceForm()




// Only for internal use.
//
&AtServer
Function AddChannelAtServer(Channel) 
    
    CurrentData = CurrentMethodData(RowMethod);   
    
    FilterParameters = ChannelFilterParameters();
    FilterParameters.Channel = Channel;
    FillPropertyValues(FilterParameters, CurrentData, "APIVersion, Method");
    
    FilterResults = Object.Channels.FindRows(FilterParameters);
    If FilterResults.Count() = 0 Then        
        
        Modified = True;
        ChannelRow = Object.Channels.Add();
        FillPropertyValues(ChannelRow, FilterParameters);
        
    Else
        
        ChannelRow = FilterResults[0];
        
    EndIf;
    
    Return ChannelRow.GetID();
    
EndFunction // AddChannelAtServer()

// Only for internal use.
//
&AtServer
Function ChannelParameters(ChannelRef, Val FormName = "ChannelForm")
    
    Return Catalogs.FL_Channels.NewChannelParameters(
        ChannelRef.BasicChannelGuid, FormName);
 
EndFunction // ChannelParameters() 

// Only for internal use.
//
&AtServer
Function RequiredChannelResources(ChannelRef, Val FormName = "ResourcesForm")
    
    ChannelProcessor = Catalogs.FL_Channels.NewChannelProcessor(
        ChannelRef.BasicChannelGuid);
    If ChannelProcessor.ResourcesRequired() Then
        Return Catalogs.FL_Channels.NewChannelParameters(
            ChannelRef.BasicChannelGuid, FormName);    
    EndIf;
    
    Return Undefined;
        
EndFunction // RequiredChannelResources() 



// Only for internal use.
//
&AtClientAtServerNoContext
Function ChannelFilterParameters()

    FilterParameters = New Structure;
    FilterParameters.Insert("APIVersion");
    FilterParameters.Insert("Channel");
    FilterParameters.Insert("Method");
    Return FilterParameters;

EndFunction // ChannelFilterParameters() 



// See function Catalogs.FL_Channels.ExchangeChannels.
//
&AtServerNoContext
Function ExchangeChannels()
    
    Return Catalogs.FL_Channels.ExchangeChannels();
    
EndFunction // ExchangeChannels()

#EndRegion // Channels

#EndRegion // ServiceProceduresAndFunctions