////////////////////////////////////////////////////////////////////////////////
// This file is part of FoxyLink.
// Copyright © 2016-2018 Petro Bazeliuk.
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
    
    If Parameters.Property("AutoTest") Then
        // Return if the form for analysis is received.
        Return;
    EndIf;
    
    If IsBlankString(Object.BasicFormatGuid) Then
        For Each Format In Catalogs.FL_Exchanges.AvailableFormats() Do
            FillPropertyValues(Items.BasicFormatGuid.ChoiceList.Add(), Format);    
        EndDo;
        Items.HeaderPages.CurrentPage = Items.HeaderPageSelectFormat;
        Items.HeaderGroupLeft.Visible = False;
    Else
        LoadBasicFormatInfo();    
    EndIf;
    
    Catalogs.FL_Exchanges.OnCreateAtServer(ThisObject);
    
    UpdateMethodsView();
    
EndProcedure // OnCreateAtServer()

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
    
    #If ThickClientOrdinaryApplication Or ThickClientManagedApplication Then
        
    If TypeOf(ChoiceSource) = Type("DataCompositionSchemaWizard")
        AND TypeOf(SelectedValue) = Type("DataCompositionSchema") Then
        
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
    
    If NOT IsBlankString(Object.BasicFormatGuid) Then
        Object.Version = "1.0.0.0";
        LoadBasicFormatInfo();   
    EndIf;
    
EndProcedure // BasicFormatGuidOnChange()

&AtClient
Procedure FormatStandardClick(Item, StandardProcessing)
    
    StandardProcessing = False;
    
    AppParameters = FL_InteriorUseClient.NewRunApplicationParameters();
    AppParameters.NotifyDescription = New NotifyDescription(
        "DoAfterBeginRunningApplication", FL_InteriorUseClient);
    AppParameters.CommandLine = FormatStandardLink();
    AppParameters.WaitForCompletion = True;
    
    FL_InteriorUseClient.Attachable_FileSystemExtension(New NotifyDescription(
        "Attachable_RunApplication", FL_InteriorUseClient, AppParameters));
        
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
        , 
        FormWindowOpeningMode.LockOwnerWindow);
    
EndProcedure // ChannelsSelection()

#Region DataCompositionSettingsComposer

&AtClient
Procedure RowComposerSettingsOnChange(Item)
    
    Modified = True;
    RowComposerSettingsModified = True;
    
EndProcedure // RowComposerSettingsOnChange()

&AtClient
Procedure RowComposerSettingsBeforeRowChange(Item, Cancel)
    
    Modified = True;
    RowComposerSettingsModified = True;
    
EndProcedure // RowComposerSettingsBeforeRowChange()

&AtClient
Procedure RowComposerSettingsDataParametersOnChange(Item)
    
    Modified = True;
    RowComposerSettingsModified = True;    
    
EndProcedure // RowComposerSettingsDataParametersOnChange()

&AtClient
Procedure RowComposerSettingsSelectionAvailableFieldsSelection(Item, 
    SelectedRow, Field, StandardProcessing)
    
    Modified = True;
    RowComposerSettingsModified = True;
    
EndProcedure // RowComposerSettingsSelectionAvailableFieldsSelection()

&AtClient
Procedure RowComposerSettingsSelectionOnChange(Item)
    
    Modified = True;
    RowComposerSettingsModified = True;    
    
EndProcedure // RowComposerSettingsSelectionOnChange() 

&AtClient
Procedure RowComposerSettingsFilterAvailableFieldsSelection(Item, SelectedRow, 
    Field, StandardProcessing)
   
    Modified = True;
    RowComposerSettingsModified = True;
    
EndProcedure // RowComposerSettingsFilterAvailableFieldsSelection()

&AtClient
Procedure RowComposerSettingsFilterOnChange(Item)
    
    Modified = True;
    RowComposerSettingsModified = True;
    
EndProcedure // RowComposerSettingsFilterOnChange()

&AtClient
Procedure RowComposerSettingsOrderAvailableFieldsSelection(Item, SelectedRow, 
    Field, StandardProcessing)
    
    Modified = True;
    RowComposerSettingsModified = True;
    
EndProcedure // RowComposerSettingsOrderAvailableFieldsSelection()

&AtClient
Procedure RowComposerSettingsOrderOnChange(Item)
    
    Modified = True;
    RowComposerSettingsModified = True;    
    
EndProcedure // RowComposerSettingsOrderOnChange()

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
    
    ExchangeMethods = New ValueList();
    For Each Item In Object.Methods Do
        ExchangeMethods.Add(Item.Method);   
    EndDo;

    ShowChooseFromList(New NotifyDescription("DoAfterChooseMethodToDelete",
        ThisObject), ExchangeMethods, Items.DeleteAPIMethod);
    
EndProcedure // DeleteAPIMethod()

&AtClient
Procedure AddEvent(Command)
    
    OpenForm("Catalog.FL_Exchanges.Form.EventsSelectionForm", 
        New Structure("MarkedEvents", MarkedEvents()), 
        ThisObject,
        New UUID, 
        , 
        ,
        New NotifyDescription("DoAfterChooseEventToAdd", ThisObject), 
        FormWindowOpeningMode.LockOwnerWindow);    
    
EndProcedure // AddEvent()

&AtClient
Procedure EnqueueEvents(Command)
    
    CurrentData = Items.Events.CurrentData;
    If CurrentData <> Undefined Then
        
        FormParameters = New Structure;
        FormParameters.Insert("Exchange", Object.Ref); 
        FormParameters.Insert("MetadataObject", CurrentData.MetadataObject);
        FormParameters.Insert("Method", CurrentData.Method);
        
        OpenForm("Catalog.FL_Jobs.Form.EnqueueEventsForm", 
            FormParameters, 
            ThisObject,
            New UUID, 
            , 
            ,
            , 
            FormWindowOpeningMode.LockOwnerWindow);    
            
    Else
        
        ShowQueryBox(New NotifyDescription("DoAfterEnqueueEvents", ThisObject),
            NStr("en='Enqueue event that is not connected with metadata directly?';
                |ru='Отправить в очередь событие, которое напрямую не связано с метаданными?';
                |en_CA='Enqueue event that is not connected with metadata directly?'"),
            QuestionDialogMode.YesNo, , DialogReturnCode.No);    
        
    EndIf;
    
EndProcedure // EnqueueEvents()

&AtClient
Procedure DeleteEvent(Command)
    
    CurrentData = Items.Events.CurrentData;
    If CurrentData <> Undefined Then
        
        ShowQueryBox(New NotifyDescription("DoAfterChooseEventToDelete", 
            ThisObject, New Structure("Identifier ", CurrentData.GetID())),
            NStr("en='Permanently delete the selected event?';
                |ru='Удалить выбранное событие?';
                |en_CA='Permanently delete the selected event?'"),
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
            NStr("en='Permanently delete the selected channel?';
                |ru='Удалить выбранный канал?';
                |en_CA='Permanently delete the selected channel?'"),
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
            NStr("en='To edit the layout scheme, run configuration in thick client mode.';
                |ru='Для того, чтобы редактировать схему компоновки, необходимо запустить конфигурацию в режиме толстого клиента.';
                |en_CA='To edit the layout scheme, run configuration in thick client mode.'"));
        
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
        NStr("en='Delete API schema from the current method?';
            |ru='Удалить API схему из текущего метода?';
            |en_CA='Delete API schema from the current method?'"),
        QuestionDialogMode.YesNo, 
        , 
        DialogReturnCode.No);    
    
EndProcedure // DeleteAPI()

#EndRegion // FormCommandHandlers

#Region ServiceProceduresAndFunctions

#Region Formats

// Rewrites the current method APISchema form the ClosureResult.
// Changes are applied only for the form Object.
//
// Parameters:
//  ClosureResult        - Arbitrary - the value transferred when you call 
//                                      the Close method of the opened form.
//  AdditionalParameters - Arbitrary - the value specified when the 
//                                      NotifyDescription object was created. 
//
&AtServer
Procedure DoAfterCloseAPICreationForm(ClosureResult, AdditionalParameters) Export
    
    If ClosureResult <> Undefined
        AND TypeOf(ClosureResult) = Type("String") Then
            
        Modified = True;
        CurrentData = CurrentMethodData(RowMethod);
        CurrentData.APISchemaAddress = ClosureResult;
        
        UpdateMethodView(CurrentData);
            
    EndIf;
    
EndProcedure // DoAfterCloseAPICreationForm()

// Copies API schema from the selected method to the current method.
//
// Parameters:
//  SelectedElement      - ValueListItem - the selected list item or Undefined 
//                                          if the user has not selected anything. 
//  AdditionalParameters - Arbitrary     - the value specified when the 
//                                          NotifyDescription object was created. 
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
// Parameters:
//  QuestionResult       - DialogReturnCode - system enumeration value 
//                  or a value related to a clicked button. If a dialog 
//                  is closed on timeout, the value is Timeout. 
//  AdditionalParameters - Arbitrary        - the value specified when the 
//                              NotifyDescription object was created.
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
    Items.HeaderPages.CurrentPage = Items.HeaderPageBasicFormat;
    
    FormatProcessor = Catalogs.FL_Exchanges.NewFormatProcessor(
        Object.BasicFormatGuid);
    
    Catalogs.FL_Exchanges.FillFormatDescription(ThisObject, FormatProcessor);    
        
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
// Parameters:
//  SelectedElement      - ValueListItem - the selected list item or Undefined 
//                                          if the user has not selected anything. 
//  AdditionalParameters - Arbitrary     - the value specified when the 
//                                          NotifyDescription object was created.  
//
&AtClient
Procedure DoAfterChooseMethodToAdd(SelectedElement, 
    AdditionalParameters) Export
    
    NormalPriority = 5;
    
    If SelectedElement <> Undefined Then
        
        FilterParameters = NewMethodFilterParameters();
        FilterParameters.Method = SelectedElement.Value;    
        FilterResult = Object.Methods.FindRows(FilterParameters);
        If FilterResult.Count() = 0 Then
            
            Modified = True;
            
            NewMethod = Object.Methods.Add();
            NewMethod.Method = SelectedElement.Value;
            NewMethod.Priority = NormalPriority;
    
            UpdateMethodsView();
                        
        EndIf;
        
    EndIf;
    
EndProcedure // DoAfterChooseMethodToAdd() 

// Deletes API method from ThisObject.
//
// Parameters:
//  SelectedElement      - ValueListItem - the selected list item or Undefined 
//                                          if the user has not selected anything. 
//  AdditionalParameters - Arbitrary     - the value specified when the 
//                                          NotifyDescription object was created.
//
&AtClient
Procedure DoAfterChooseMethodToDelete(SelectedElement, 
    AdditionalParameters) Export
    
    If SelectedElement <> Undefined 
        AND TypeOf(SelectedElement.Value) = Type("CatalogRef.FL_Methods") Then
        
        FilterParameters = NewMethodFilterParameters();
        FilterParameters.Method = SelectedElement.Value;
           
        FL_CommonUseClientServer.DeleteRowsByFilter(Object.Methods, 
            FilterParameters, Modified);
        
        FL_CommonUseClientServer.DeleteRowsByFilter(Object.Events, 
            FilterParameters, Modified);
            
        FL_CommonUseClientServer.DeleteRowsByFilter(Object.Channels, 
            FilterParameters, Modified);
            
        FL_CommonUseClientServer.DeleteRowsByFilter(Object.ChannelResources, 
            FilterParameters, Modified);
                    
        UpdateMethodsView();
                            
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
        .NewTemplateComposerParameters();
    DataCompositionTemplate.Schema   = DataCompositionSchema;
    DataCompositionTemplate.Template = DataCompositionSettings;

    OutputParameters = FL_DataComposition.NewOutputParameters();
    OutputParameters.DCTParameters = DataCompositionTemplate;
    OutputParameters.CanUseExternalFunctions = RowCanUseExternalFunctions;
    
    FL_DataComposition.OutputInSpreadsheetDocument(ResultSpreadsheetDocument, 
        OutputParameters);     
            
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
    
    MemoryStream = New MemoryStream;
    Catalogs.FL_Exchanges.OutputMessageIntoStream(MemoryStream,
        New FixedStructure(ExchangeSettings));
            
    // End measuring.
    TestingExecutionTime = CurrentUniversalDateInMilliseconds() - StartTime;
    
    ResultTextDocument.AddLine(GetStringFromBinaryData(
        MemoryStream.CloseAndGetBinaryData()));
    
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
        
    If Changes Then
        
        // Init data composer by new data composition schema.
        FL_DataComposition.InitSettingsComposer(RowComposerSettings, 
            DataCompositionSchemaEditAddress);

    EndIf;

EndProcedure // UpdateDataCompositionSchema() 

// Loads method settings in form object.
//
&AtServer
Procedure LoadMethodSettings()
    
    ResultTextDocument.Clear();
    ResultSpreadsheetDocument.Clear();

    SaveMethodSettings();
        
    CurrentPage = Items.MethodPages.CurrentPage;
    If CurrentPage = Undefined 
        AND Items.MethodPages.ChildItems.Count() > 0 Then
        CurrentPage = Items.MethodPages.ChildItems[0];
    EndIf;
    
    If CurrentPage <> Undefined Then
       
        RowMethod = CurrentPage.Name;
        FL_InteriorUse.MoveItemInItemFormCollection(Items, 
            "HiddenGroupSettings", RowMethod);
           
        CurrentData = CurrentMethodData(RowMethod);
        RowPriority = CurrentData.Priority;
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
            
            FL_DataComposition.InitSettingsComposer(RowComposerSettings, 
                CurrentData.DataCompositionSchemaAddress, 
                CurrentData.DataCompositionSettingsAddress);
                
        Except
            
            FL_CommonUseClientServer.NotifyUser(ErrorDescription());    
            
        EndTry; 
             
    Else

        RowMethod = Undefined;
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
            ChangedData.Priority = RowPriority;
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
            FilterParameters = NewMethodFilterParameters();
            FilterParameters.Method = Item.Method;
            ValueList.Add(FilterParameters, Item.Method);   
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

    Method = FL_CommonUse.ReferenceByDescription(Metadata.Catalogs.FL_Methods,
        RowMethod);
    
    FilterParameters = NewMethodFilterParameters();
    FilterParameters.Method = Method;
    FilterResult = Object.Methods.FindRows(FilterParameters);
    If FilterResult.Count() > 0 Then
        CurrentData = FilterResult[0];
    Else
        
        ErrorMessage = NStr("en='Critical error, method not found.';
            |ru='Критическая ошибка, метод не найден.';
            |en_CA='Critical error, method not found.'");
        
        Raise ErrorMessage;     
        
    EndIf;
            
    Return CurrentData;    

EndFunction // CurrentMethodData()  

// Only for internal use.
//
&AtClientAtServerNoContext
Function NewMethodFilterParameters()

    FilterParameters = New Structure;
    FilterParameters.Insert("Method");
    Return FilterParameters;

EndFunction // NewMethodFilterParameters() 

#EndRegion // Methods

#Region Events

// Adds new subscriptions on events.
//
// Parameters:
//  ClosureResult        - Arbitrary - the value transferred when you call 
//                                      the Close method of the opened form.
//  AdditionalParameters - Arbitrary - the value specified when the 
//                                      NotifyDescription object was created.
//
&AtClient
Procedure DoAfterChooseEventToAdd(ClosureResult, 
    AdditionalParameters) Export
    
    If ClosureResult <> Undefined
        AND TypeOf(ClosureResult) = Type("Array") Then
        
        AddEventAtServer(ClosureResult);
        
    EndIf;
    
EndProcedure // DoAfterChooseEventToAdd() 

// Deletes the selected event.
//
// Parameters:
//  QuestionResult       - DialogReturnCode - system enumeration value 
//                  or a value related to a clicked button. If a dialog 
//                  is closed on timeout, the value is Timeout. 
//  AdditionalParameters - Arbitrary        - the value specified when the 
//                              NotifyDescription object was created.
//
&AtClient
Procedure DoAfterChooseEventToDelete(QuestionResult, 
    AdditionalParameters) Export
    
    Var Identifier;
    
    If QuestionResult = DialogReturnCode.Yes
        AND TypeOf(AdditionalParameters) = Type("Structure")
        AND AdditionalParameters.Property("Identifier", Identifier) Then
            
        SearchResult = Object.Events.FindByID(Identifier);
        If SearchResult <> Undefined Then
            
            Modified = True;
            Object.Events.Delete(SearchResult);                
            
        EndIf;
            
    EndIf;
    
EndProcedure // DoAfterChooseEventToDelete()

// Enqueues event that is not connected with metadata directly.
//
// Parameters:
//  QuestionResult       - DialogReturnCode - system enumeration value 
//                  or a value related to a clicked button. If a dialog 
//                  is closed on timeout, the value is Timeout. 
//  AdditionalParameters - Arbitrary        - the value specified when the 
//                              NotifyDescription object was created.
//
&AtClient
Procedure DoAfterEnqueueEvents(QuestionResult, AdditionalParameters) Export
    
    If QuestionResult = DialogReturnCode.Yes Then    
        
        Job = EnqueueEventAtServer();
        
        Explanation = NStr("en='Event enqueued successfully.';
            |ru='Событие успешно добавлено в очередь.';
            |en_CA='Event enqueued successfully.'");
        
        ShowUserNotification("FoxyLink", 
            GetURL(Job), 
            Explanation, 
            PictureLib.FL_Logotype64);
        
    EndIf;    

EndProcedure // DoAfterEnqueueEvents()

// Only for internal use.
//
&AtServer
Procedure AddEventAtServer(EventsArray)

    CurrentData = CurrentMethodData(RowMethod);   
    FilterParameters = NewMethodFilterParameters();
    FilterParameters.Method = CurrentData.Method;
    
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
Function EnqueueEventAtServer()
    
    CurrentData = CurrentMethodData(RowMethod);
    
    InvocationData = FL_BackgroundJob.NewInvocationData();
    InvocationData.Method = CurrentData.Method;
    InvocationData.Owner = Object.Ref;
    InvocationData.Priority = CurrentData.Priority;
    
    Return FL_BackgroundJob.Enqueue("Catalogs.FL_Jobs.Trigger", 
        InvocationData);
    
EndFunction // EnqueueEventAtServer()

// Only for internal use.
//
&AtServer
Function MarkedEvents()
    
    CurrentData = CurrentMethodData(RowMethod);
    FilterParameters = NewMethodFilterParameters();
    FilterParameters.Method = CurrentData.Method;
    
    FilterResults = Object.Events.FindRows(FilterParameters);
    
    MarkedEvents = New ValueList;
    For Each FilterResult In FilterResults Do
        MarkedEvents.Add(FilterResult.MetadataObject);    
    EndDo;
    
    Return MarkedEvents;
    
EndFunction // MarkedEvents()

#EndRegion // Events

#Region Channels

// Adds new channel to API method to ThisObject.
//
// Parameters:
//  SelectedElement      - ValueListItem - the selected list item or Undefined 
//                                          if the user has not selected anything. 
//  AdditionalParameters - Arbitrary     - the value specified when the 
//                                          NotifyDescription object was created.
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
// Parameters:
//  QuestionResult       - DialogReturnCode - system enumeration value or a value
//                                      related to a clicked button. If a dialog 
//                                      is closed on timeout, the value is Timeout. 
//  AdditionalParameters - Structure        - the value specified when the 
//                                      NotifyDescription object was created.
//
&AtClient
Procedure DoAfterChooseChannelToDelete(QuestionResult, 
    AdditionalParameters) Export
    
    Var Identifier;
    
    If QuestionResult = DialogReturnCode.Yes
        AND TypeOf(AdditionalParameters) = Type("Structure")
        AND AdditionalParameters.Property("Identifier", Identifier) Then
            
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
    
EndProcedure // DoAfterChooseChannelToDelete()

// Fills required channel resources.
//
// Parameters:
//  ClosureResult - FormDataStructure      - the value transferred when you call 
//                                           the Close method of the opened form.
//  ChannelRef    - CatalogRef.FL_Channels - the value specified when the 
//                                           NotifyDescription object was created.
//
&AtClient
Procedure DoAfterCloseChannelResourcesForm(ClosureResult, 
    ChannelRef) Export
    
    If ClosureResult <> Undefined
        AND TypeOf(ClosureResult) = Type("FormDataStructure") Then
            
        ChannelIdentifier = AddChannelAtServer(ChannelRef);
        ChannelRow = Object.Channels.FindByID(ChannelIdentifier);
        
        If ClosureResult.Property("ChannelResources")
            AND TypeOf(ClosureResult.ChannelResources) = Type("FormDataCollection") Then
            
            Modified = True;
            FilterParameters = ChannelFilterParameters();
            FillPropertyValues(FilterParameters, ChannelRow);
            
            FilterResults = Object.ChannelResources.FindRows(FilterParameters);
            For Each FilterResult In FilterResults Do
                Object.ChannelResources.Delete(FilterResult);    
            EndDo;         
            
            For Each Item In ClosureResult.ChannelResources Do
                NewData = Object.ChannelResources.Add();
                FillPropertyValues(NewData, ChannelRow);
                FillPropertyValues(NewData, Item);
            EndDo; 
            
        EndIf;
 
    EndIf;
    
EndProcedure // DoAfterCloseChannelResourcesForm()

// Fills channel response handler.
//
// Parameters:
//  ClosureResult - String - the value transferred when you call the Close 
//                           method of the opened form.
//  ID            - Number - the value specified when the NotifyDescription
//                           object was created.
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
    
    ChannelParameters.Insert("Channel", ChannelRef);
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
    FilterParameters.Method = CurrentData.Method;
    FilterParameters.Channel = Channel;
    
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