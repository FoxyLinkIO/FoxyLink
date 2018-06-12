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
    
    UpdateOperationsView();
    
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
    SaveOperationSettings();
    
    // Saving settings in write object.
    Catalogs.FL_Exchanges.BeforeWriteAtServer(ThisObject, CurrentObject);
    
EndProcedure // BeforeWriteAtServer() 

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
    
    // If user simply saves catalog item and doesn't close this form,
    // user has some problems with editing. It helps in this case. 
    Catalogs.FL_Exchanges.OnCreateAtServer(ThisObject);    
    
    If NOT IsBlankString(RowOperation) Then
        FilterParameters = NewOperationFilterParameters();
        FillPropertyValues(FilterParameters, CurrentOperationData(RowOperation));
        Catalogs.FL_Exchanges.UpdateEventsView(ThisForm, FilterParameters);
    EndIf;
    
EndProcedure // AfterWriteAtServer()

#EndRegion // FormEventHandlers

#Region FormItemsEventHandlers

&AtClient
Procedure BasicFormatGuidOnChange(Item)
    
    If NOT IsBlankString(Object.BasicFormatGuid) Then
        Object.Version = "1.0.0";
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
Procedure OperationPagesOnCurrentPageChange(Item, CurrentPage)
    
    LoadOperationSettings();
    
EndProcedure // OperationPagesOnCurrentPageChange()

&AtClient
Procedure EventsEventHandlerStartChoice(Item, ChoiceData, StandardProcessing)
    
    StandardProcessing = False;
    
    CurrentData = Items.Events.CurrentData;
    If CurrentData <> Undefined Then
        
        Identifier = CurrentData.GetID();   
        NotifyDescription = New NotifyDescription(
            "DoAfterChooseEventHandlerToSet", ThisObject, Identifier);
        ShowChooseFromList(NotifyDescription, AvailableEventHandlers(
                Identifier), Item);
            
    EndIf;
        
EndProcedure // EventsEventHandlerStartChoice()

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
Procedure AddChannel(Command)
    
    // It is needed to clear resource cache.
    TransitionChannelResources.Clear();
    
    ShowChooseFromList(New NotifyDescription("DoAfterChooseChannelToAdd",
        ThisObject), ExchangeChannels(), Items.AddChannel);
        
EndProcedure // AddChannel()

&AtClient
Procedure AddEvent(Command)
    
    OpenForm("Catalog.FL_Exchanges.Form.EventsSelectionForm", 
        New Structure("Operation, MarkedEvents", RowOperation, MarkedEvents()), 
        ThisObject,
        New UUID, 
        , 
        ,
        New NotifyDescription("DoAfterChooseEventToAdd", ThisObject), 
        FormWindowOpeningMode.LockOwnerWindow);    
    
EndProcedure // AddEvent()

&AtClient
Procedure AddOperation(Command)
    
    ShowChooseFromList(New NotifyDescription("DoAfterChooseOperationToAdd",
        ThisObject), AvailableOperations(), Items.AddOperation);
        
EndProcedure // AddOperation()

&AtClient
Procedure CopyAPI(Command)
    
    ShowChooseFromList(New NotifyDescription("DoAfterChooseOperationAPIToCopy",
        ThisObject), CurrentOperationsWithAPISchema(), Items.CopyAPI);    
    
EndProcedure // CopyAPI()

&AtClient
Procedure CopyDataCompositionSchema(Command)
    
    ShowChooseFromList(New NotifyDescription(
            "DoAfterChooseDataCompositionSchemaToCopy", ThisObject), 
        CurrentOperationsWithDataCompositionSchema(), Items.CopyDataCompositionSchema);
    
EndProcedure // CopyDataCompositionSchema()

&AtClient
Procedure DeleteAPI(Command)
    
    ShowQueryBox(New NotifyDescription("DoAfterChooseAPISchemaToDelete", 
            ThisObject),
        NStr("en='Delete API schema from the current operation?';
            |ru='Удалить API схему из текущей операции?';
            |en_CA='Delete API schema from the current operation?'"),
        QuestionDialogMode.YesNo, 
        , 
        DialogReturnCode.No);    
    
EndProcedure // DeleteAPI()

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
Procedure DeleteOperation(Command)
    
    ExchangeOperations = New ValueList();
    For Each Item In Object.Operations Do
        ExchangeOperations.Add(Item.Operation);   
    EndDo;

    ShowChooseFromList(New NotifyDescription("DoAfterChooseOperationToDelete",
        ThisObject), ExchangeOperations, Items.DeleteOperation);
    
EndProcedure // DeleteOperation()

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
Procedure EnqueueEvents(Command)
    
    CurrentData = Items.Events.CurrentData;
    If CurrentData <> Undefined Then
        
        FormParameters = New Structure;
        FormParameters.Insert("Exchange", Object.Ref); 
        FormParameters.Insert("EventSource", CurrentData.MetadataObject);
        FormParameters.Insert("Operation", CurrentData.Operation);
        
        OpenForm("Catalog.FL_Messages.Form.EnqueueMessagesForm", 
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
Procedure GenerateSpecificDocument(Command)
    
    GenerateSpecificDocumentAtServer();   
         
EndProcedure // GenerateSpecificDocument() 

&AtClient
Procedure GenerateSpreadsheetDocument(Command)
    
    GenerateSpreadsheetDocumentAtServer();
    
EndProcedure // GenerateSpreadsheetDocument()

#EndRegion // FormCommandHandlers

#Region ServiceProceduresAndFunctions

#Region Formats

// Rewrites the current operation APISchema form the ClosureResult.
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
        CurrentData = CurrentOperationData(RowOperation);
        CurrentData.APISchemaAddress = ClosureResult;
        
        UpdateOperationView(CurrentData);
            
    EndIf;
    
EndProcedure // DoAfterCloseAPICreationForm()

// Copies API schema from the selected operation to the current operation.
//
// Parameters:
//  SelectedElement      - ValueListItem - the selected list item or Undefined 
//                                          if the user has not selected anything. 
//  AdditionalParameters - Arbitrary     - the value specified when the 
//                                          NotifyDescription object was created. 
//
&AtClient
Procedure DoAfterChooseOperationAPIToCopy(SelectedElement, 
    AdditionalParameters) Export
    
    If SelectedElement <> Undefined Then
        
        FilterResult = Object.Operations.FindRows(SelectedElement.Value);
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
    
EndProcedure // DoAfterChooseOperationAPIToCopy()

// Deletes API schema from the current operation.
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
    
    FormatProcessor = FL_InteriorUse.NewFormatProcessor(
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
    
    FormatProcessor = FL_InteriorUse.NewFormatProcessor(
        Object.BasicFormatGuid);     
    Return FormatProcessor.FormatStandardLink();
    
EndFunction // FormatStandardLink()

&AtServer
Function DescribeAPIParameters()
        
    FormatProcessor = FL_InteriorUse.NewFormatProcessor(
        Object.BasicFormatGuid);      
    FormatProcessorMetadata = FormatProcessor.Metadata();

    APISchemaData = NewAPISchemaData(); 
    APISchemaData.FormName = StrTemplate("%1.Form.APICreationForm", 
        FormatProcessorMetadata.FullName());    
    APISchemaData.Parameters.APISchemaAddress = CurrentOperationData(RowOperation)
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

// Returns list of currently used operations with filled API schema.
//
&AtServer
Function CurrentOperationsWithAPISchema()
    
    ValueList = New ValueList();
    CurrentData = CurrentOperationData(RowOperation);  
    For Each Item In Object.Operations Do
        
        If Item.GetID() = CurrentData.GetID() Then
            Continue;
        EndIf;
        
        If IsTempStorageURL(Item.APISchemaAddress) Then
            FilterParameters = NewOperationFilterParameters();
            FilterParameters.Operation = Item.Operation;
            ValueList.Add(FilterParameters, Item.Operation);   
        EndIf;
    EndDo;
    
    Return ValueList;
    
EndFunction // CurrentOperationsWithAPISchema()

#EndRegion // Formats 

#Region Operations

// Adds new operation to ThisObject.
//
// Parameters:
//  SelectedElement      - ValueListItem - the selected list item or Undefined 
//                                          if the user has not selected anything. 
//  AdditionalParameters - Arbitrary     - the value specified when the 
//                                          NotifyDescription object was created.  
//
&AtClient
Procedure DoAfterChooseOperationToAdd(SelectedElement, 
    AdditionalParameters) Export
    
    NormalPriority = 5;
    
    If SelectedElement <> Undefined Then
        
        FilterParameters = NewOperationFilterParameters();
        FilterParameters.Operation = SelectedElement.Value;    
        FilterResult = Object.Operations.FindRows(FilterParameters);
        If FilterResult.Count() = 0 Then
            
            Modified = True;
            
            NewOperation = Object.Operations.Add();
            NewOperation.Operation = SelectedElement.Value;
            NewOperation.Priority = NormalPriority;
    
            UpdateOperationsView();
                        
        EndIf;
        
    EndIf;
    
EndProcedure // DoAfterChooseOperationToAdd() 

// Deletes operation from ThisObject.
//
// Parameters:
//  SelectedElement      - ValueListItem - the selected list item or Undefined 
//                                          if the user has not selected anything. 
//  AdditionalParameters - Arbitrary     - the value specified when the 
//                                          NotifyDescription object was created.
//
&AtClient
Procedure DoAfterChooseOperationToDelete(SelectedElement, 
    AdditionalParameters) Export
    
    If SelectedElement <> Undefined 
        AND TypeOf(SelectedElement.Value) = Type("CatalogRef.FL_Operations") Then
        
        FilterParameters = NewOperationFilterParameters();
        FilterParameters.Operation = SelectedElement.Value;
           
        FL_CommonUseClientServer.DeleteRowsByFilter(Object.Operations, 
            FilterParameters, Modified);
        
        FL_CommonUseClientServer.DeleteRowsByFilter(Object.Events, 
            FilterParameters, Modified);
            
        FL_CommonUseClientServer.DeleteRowsByFilter(Object.Channels, 
            FilterParameters, Modified);
            
        FL_CommonUseClientServer.DeleteRowsByFilter(Object.ChannelResources, 
            FilterParameters, Modified);
                    
        UpdateOperationsView();
                            
    EndIf;
    
EndProcedure // DoAfterChooseOperationToDelete() 

// Copies data composition schema from the selected operation to the current 
// operation.
//
// Parameters:
//  SelectedElement      - ValueListItem - the selected list item or Undefined 
//                                          if the user has not selected anything. 
//  AdditionalParameters - Arbitrary     - the value specified when the 
//                                          NotifyDescription object was created. 
//
&AtClient
Procedure DoAfterChooseDataCompositionSchemaToCopy(SelectedElement, 
    AdditionalParameters) Export
    
    If SelectedElement <> Undefined Then
        
        FilterResult = Object.Operations.FindRows(SelectedElement.Value);
        If FilterResult.Count() > 0 Then
            
            CopyDataCompositionSchemaAtServer(FilterResult[0].GetId());
            
            Explanation = NStr("en='Data composition schema successfully copied.';
                |ru='Схема компоновки данных успешно скопирована.';
                |uk='Схема компоновки даних успішно скопійована.';
                |en_CA='Data composition schema successfully copied.'");
            
            ShowUserNotification(Title, , Explanation, 
                PictureLib.FL_Logotype64);
                
        EndIf;
        
    EndIf;    
    
EndProcedure // DoAfterChooseDataCompositionSchemaToCopy()

&AtServer
Procedure CopyDataCompositionSchemaAtServer(OperationId)
    
    Source = Object.Operations.FindByID(OperationId);
    If Source = Undefined Then
        Return;
    EndIf;
    
    If IsTempStorageURL(Source.DataCompositionSchemaAddress) Then
        
        Modified = True;
        UpdateDataCompositionSchema(GetFromTempStorage(
            Source.DataCompositionSchemaAddress));
            
    EndIf;
    
EndProcedure // CopyDataCompositionSchemaAtServer()

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
    
    // Read API schema from temp storage address.
    CurrentData = CurrentOperationData(RowOperation);
    If IsTempStorageURL(CurrentData.APISchemaAddress) Then
        ExchangeSettings.APISchema = GetFromTempStorage(
            CurrentData.APISchemaAddress);    
    EndIf;
    
    ExchangeSettings.DataCompositionSchema = GetFromTempStorage(
        DataCompositionSchemaEditAddress);     
    ExchangeSettings.DataCompositionSettings = RowComposerSettings
        .GetSettings();
    ExchangeSettings.CanUseExternalFunctions = RowCanUseExternalFunctions;
     
    // Open a new memory stream.
    Stream = New MemoryStream;
    
    // Initialize format processor.
    StreamObject = FL_InteriorUse.NewFormatProcessor(Object.BasicFormatGuid);
    StreamObject.Initialize(Stream, ExchangeSettings.APISchema);
    
    OutputParameters = Catalogs.FL_Exchanges.NewOutputParameters(
        ExchangeSettings);
    FL_DataComposition.Output(StreamObject, OutputParameters);
    
    // Close format stream.
    StreamObject.Close();     
            
    // End measuring.
    TestingExecutionTime = CurrentUniversalDateInMilliseconds() - StartTime;
    
    ResultTextDocument.AddLine(GetStringFromBinaryData(
        Stream.CloseAndGetBinaryData()));
    
    Items.HiddenPageTestingResults.CurrentPage = 
        Items.HiddenPageTestingTextDocument;
    
EndProcedure // GenerateSpecificDocumentAtServer() 

// See function Catalogs.FL_Exchanges.UpdateOperationsView.
//
&AtServer
Procedure UpdateOperationsView()
    
    Catalogs.FL_Exchanges.UpdateOperationsView(ThisObject);   
    
    LoadOperationSettings();
    
EndProcedure // UpdateOperationsView()

// Updates the view of the operation on the form.
//
// Parameters:
//  CurrentData - FormDataCollectionItem - the current operation data.
// 
&AtServer
Procedure UpdateOperationView(CurrentData)

    If ThisObject.FormatAPISchemaSupport Then
        
        Items.CopyAPI.Visible = False;
        Items.DeleteAPI.Visible = IsTempStorageURL(CurrentData.APISchemaAddress);
        For Each Row In Object.Operations Do
        
            If Row.GetID() = CurrentData.GetID() Then
                Continue;
            EndIf;
            
            If IsTempStorageURL(Row.APISchemaAddress) Then
                Items.CopyAPI.Visible = True;
                Break;    
            EndIf;
        
        EndDo;
        
    EndIf;
    
    FilterParameters = NewOperationFilterParameters();
    FillPropertyValues(FilterParameters, CurrentData);
    Items.Events.RowFilter = New FixedStructure(FilterParameters);
    Items.Channels.RowFilter = New FixedStructure(FilterParameters);

    Catalogs.FL_Exchanges.UpdateEventsView(ThisForm, FilterParameters);
    
EndProcedure // UpdateOperationView() 

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

// Loads operation settings in form object.
//
&AtServer
Procedure LoadOperationSettings()
    
    ResultTextDocument.Clear();
    ResultSpreadsheetDocument.Clear();

    SaveOperationSettings();
        
    CurrentPage = Items.OperationPages.CurrentPage;
    If CurrentPage = Undefined 
        AND Items.OperationPages.ChildItems.Count() > 0 Then
        CurrentPage = Items.OperationPages.ChildItems[0];
    EndIf;
    
    If CurrentPage <> Undefined Then
       
        RowOperation = CurrentPage.Name;
        FL_InteriorUse.MoveItemInItemFormCollection(Items, 
            "HiddenGroupSettings", RowOperation);
           
        CurrentData = CurrentOperationData(RowOperation);
        RowPriority = CurrentData.Priority;
        RowCanUseExternalFunctions = CurrentData.CanUseExternalFunctions;
        
        UpdateOperationView(CurrentData);
        
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

        RowOperation = Undefined;
        RowCanUseExternalFunctions = Undefined;
        DataCompositionSchemaEditAddress = "";
        RowComposerSettings = New DataCompositionSettingsComposer;
            
    EndIf;    
    
EndProcedure // LoadOperationSettings()

// Saves all untracked changes in form object.
//
&AtServer
Procedure SaveOperationSettings()

    If Not IsBlankString(RowOperation) Then
        
        If Items.OperationPages.ChildItems.Find(RowOperation) <> Undefined Then
        
            ChangedData = CurrentOperationData(RowOperation);
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

EndProcedure // SaveOperationSettings() 

// See function Catalogs.FL_Operations.AvailableOperations.
//
&AtServer
Function AvailableOperations()
    
    Return Catalogs.FL_Operations.AvailableOperations();
    
EndFunction // AvailableOperations()

// Returns list of currently used operations with filled data composition 
// schema.
//
&AtServer
Function CurrentOperationsWithDataCompositionSchema()
    
    ValueList = New ValueList();
    CurrentData = CurrentOperationData(RowOperation);  
    For Each Item In Object.Operations Do
        
        If Item.GetID() = CurrentData.GetID() Then
            Continue;
        EndIf;
        
        If IsTempStorageURL(Item.DataCompositionSchemaAddress) Then
            FilterParameters = NewOperationFilterParameters();
            FilterParameters.Operation = Item.Operation;
            ValueList.Add(FilterParameters, Item.Operation);   
        EndIf;
    EndDo;
    
    Return ValueList;
    
EndFunction // CurrentOperationsWithDataCompositionSchema()

// Finds and returns operation data in object.
//
// Parameters:
//  RowOperation - String - the operation name.
//
// Returns:
//  FormDataCollectionItem - operation data.
//
&AtServer
Function CurrentOperationData(Val RowOperation)

    Operation = FL_CommonUse.ReferenceByDescription(
        Metadata.Catalogs.FL_Operations, RowOperation);
    
    FilterParameters = NewOperationFilterParameters();
    FilterParameters.Operation = Operation;
    FilterResult = Object.Operations.FindRows(FilterParameters);
    If FilterResult.Count() > 0 Then
        CurrentData = FilterResult[0];
    Else
        
        ErrorMessage = NStr("en='Critical error, operation not found.';
            |ru='Критическая ошибка, операция не найдена.';
            |en_CA='Critical error, operation not found.'");
        
        Raise ErrorMessage;     
        
    EndIf;
            
    Return CurrentData;    

EndFunction // CurrentOperationData()  

// Only for internal use.
//
&AtClientAtServerNoContext
Function NewOperationFilterParameters()

    FilterParameters = New Structure;
    FilterParameters.Insert("Operation");
    Return FilterParameters;

EndFunction // NewOperationFilterParameters() 

#EndRegion // Operations

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
        AND TypeOf(ClosureResult) = Type("ValueList") Then
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

// Sets a new event handler for the operation and metadata object.
//
// Parameters:
//  SelectedElement      - ValueListItem - the selected list item or Undefined 
//                                          if the user has not selected anything. 
//  AdditionalParameters - Arbitrary     - the value specified when the 
//                                          NotifyDescription object was created.  
//
&AtClient
Procedure DoAfterChooseEventHandlerToSet(SelectedElement, 
    AdditionalParameters) Export
    
    If SelectedElement <> Undefined Then
        
        CurrentData = Object.Events.FindByID(AdditionalParameters);
        If CurrentData <> Undefined Then
            
            Modified = True;
            
            SelectedValue = SelectedElement.Value;
            CurrentData.Description = SelectedValue.Description;
            CurrentData.EventHandler = SelectedValue.EventHandler;
            CurrentData.Version = SelectedValue.Version;
            CurrentData.Transactional = SelectedValue.Transactional;
            
        EndIf;
        
    EndIf;
    
EndProcedure // DoAfterChooseEventHandlerToSet()

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
        
        EnqueueEventAtServer();
        
        Explanation = NStr("en='Event enqueued successfully.';
            |ru='Событие успешно добавлено в очередь.';
            |uk='Подія успішно додана в чергу.';
            |en_CA='Event enqueued successfully.'");
        
        ShowUserNotification("FoxyLink", , Explanation, 
            PictureLib.FL_Logotype64);
        
    EndIf;    

EndProcedure // DoAfterEnqueueEvents()

// Only for internal use.
//
&AtServer
Procedure AddEventAtServer(EventValueList)

    For Each Event In Object.Events Do
        Event.Updated = False;
    EndDo;
        
    CurrentData = CurrentOperationData(RowOperation);   
    FilterParameters = NewOperationFilterParameters();
    FilterParameters.Operation = CurrentData.Operation;
    FilterParameters.Insert("MetadataObject");
    
    For Each Event In EventValueList Do
        
        FilterParameters.MetadataObject = Event.Value;
        FilterResults = Object.Events.FindRows(FilterParameters);
        If FilterResults.Count() = 0 Then
            Modified = True;
            EventRow = Object.Events.Add();
        Else
            EventRow = FilterResults[0];    
        EndIf;
       
        FillPropertyValues(EventRow, FilterParameters);
        
        EventRow.Updated = True;
        EventRow.EventName = Event.Presentation;
        EventRow.PictureIndex = FL_CommonUseReUse
            .PicSequenceIndexByFullName(EventRow.MetadataObject);
            
        If IsBlankString(EventRow.EventHandler) Then
            
            EventHandlers = FL_InteriorUseReUse.AvailableEventHandlers(
                EventRow.Operation, EventRow.MetadataObject);
            For Each EventHandler In EventHandlers Do
                If EventHandler.Default Then
                    Modified = True;
                    FillPropertyValues(EventRow, EventHandler);           
                EndIf;
            EndDo;    

        EndIf;
                
    EndDo;
    
    FilterParameters.Delete("MetadataObject");
    FilterParameters.Insert("Updated", False);
    FL_CommonUseClientServer.DeleteRowsByFilter(Object.Events, 
        FilterParameters, Modified);
    
EndProcedure // AddEventAtServer() 

// Only for internal use.
//
&AtServer
Procedure EnqueueEventAtServer()
    
    CurrentData = CurrentOperationData(RowOperation);
    
    Invocation = Catalogs.FL_Messages.NewInvocation();
    Invocation.Operation = CurrentData.Operation;
    Catalogs.FL_Messages.Route(Invocation, Object.Ref);
    
EndProcedure // EnqueueEventAtServer()

// Only for internal use.
//
&AtServer
Function MarkedEvents()
    
    CurrentData = CurrentOperationData(RowOperation);
    FilterParameters = NewOperationFilterParameters();
    FilterParameters.Operation = CurrentData.Operation;
    
    FilterResults = Object.Events.FindRows(FilterParameters);
    
    MarkedEvents = New ValueList;
    For Each FilterResult In FilterResults Do
        MarkedEvents.Add(FilterResult.MetadataObject);    
    EndDo;
    
    Return MarkedEvents;
    
EndFunction // MarkedEvents()

// Only for internal use.
//
&AtServer
Function AvailableEventHandlers(Identifier) 
    
    ValueList = New ValueList;
    CurrentData = Object.Events.FindByID(Identifier);
    If CurrentData = Undefined Then
        Return ValueList;     
    EndIf;
    
    EventHandlers = FL_InteriorUseReUse.AvailableEventHandlers(
        CurrentData.Operation, CurrentData.MetadataObject);   
    For Each EventHandler In EventHandlers Do
        ValueList.Add(EventHandler, EventHandler.Description, 
            EventHandler.Default);   
    EndDo;
    
    Return ValueList;
    
EndFunction // AvailableEventHandlers()

#EndRegion // Events

#Region AppEndpoints

// Adds new channel to operation to ThisObject.
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
    
    CurrentData = CurrentOperationData(RowOperation);   
    
    FilterParameters = ChannelFilterParameters();
    FilterParameters.Operation = CurrentData.Operation;
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
    
    ChannelProcessor = FL_InteriorUse.NewAppEndpointProcessor(
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
    FilterParameters.Insert("Operation");
    Return FilterParameters;

EndFunction // ChannelFilterParameters() 

// See function Catalogs.FL_Channels.ExchangeChannels.
//
&AtServerNoContext
Function ExchangeChannels()
    
    Return Catalogs.FL_Channels.ExchangeChannels();
    
EndFunction // ExchangeChannels()

#EndRegion // AppEndpoints

#EndRegion // ServiceProceduresAndFunctions