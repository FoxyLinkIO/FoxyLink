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
    
    Parameters.Property("BinaryDataAddress", BinaryDataAddress);
    Parameters.Property("LibraryGuid", LibraryGuid);
    Parameters.Property("Template", Template);
    If NOT IsBlankString(LibraryGuid) AND NOT IsBlankString(Template) Then
        
        ChannelProcessor = FL_InteriorUse.NewChannelProcessor(LibraryGuid);
        BinaryData = ChannelProcessor.GetTemplate(Template);
        BinaryDataAddress = PutToTempStorage(BinaryData, UUID);
        
    EndIf;
    
    FL_InteriorUse.LoadImportedExchange(ThisObject, ImportedExchange());
    
    SetExchangeMatches();
    SetOperationMatches();
    SetChannelMatches();
    SetEventMatches();
    
    LoadBasicFormatInfo();
    
EndProcedure // OnCreateAtServer() 

#EndRegion // FormEventHandlers

#Region FormItemsEventHandlers

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

#EndRegion // FormItemsEventHandlers

#Region FormCommandHandlers

&AtClient
Procedure InstallOrUpdateExchange(Command)
    
    InstallOrUpdateExchangeAtServer();
    Close();
    
EndProcedure // InstallOrUpdateExchange()

&AtClient
Procedure DeleteChannel(Command)
    
    CurrentData = Items.Channels.CurrentData;
    If CurrentData <> Undefined Then
        
        ShowQueryBox(New NotifyDescription("DoAfterChooseChannelToDelete", 
            ThisObject, New Structure("Identifier ", CurrentData.GetID())),
            NStr("en='Permanently delete the selected channel?';
                |ru='Удалить выбранный канал?';
                |en_CA='Permanently delete the selected channel?'"),
            QuestionDialogMode.YesNo, , DialogReturnCode.No);     
        
    EndIf;   
    
EndProcedure // DeleteChannel()

&AtClient
Procedure InstallChannel(Command)
    
    CurrentData = Items.Channels.CurrentData;
    If CurrentData <> Undefined Then
        
        If CurrentData.Ref.IsEmpty() Then
            InstallOrUpdateChannel(CurrentData);        
        Else

            Explanation = NStr("en='Channel reference must be empty.';
                |ru='Ссылка на канал должна быть не заполнена.';
                |en_CA='Channel reference must be empty.'");    
            ShowUserNotification(Title, , Explanation, PictureLib.FL_Logotype64);
            
        EndIf;
        
    EndIf;
        
EndProcedure // InstallChannel()

&AtClient
Procedure InstallChannelUpdate(Command)
    
    CurrentData = Items.Channels.CurrentData;
    If CurrentData <> Undefined Then
        
        If NOT CurrentData.Ref.IsEmpty() Then
            InstallOrUpdateChannel(CurrentData);       
        Else

            Explanation = NStr("en='Channel reference must be filled.';
                |ru='Ссылка на канал должна быть заполнена.';
                |en_CA='Channel reference must be filled.'");    
            ShowUserNotification(Title, , Explanation, PictureLib.FL_Logotype64);
            
        EndIf;
            
    EndIf;
    
EndProcedure // InstallChannelUpdate()

&AtClient
Procedure SelectChannel(Command)
    
    CurrentData = Items.Channels.CurrentData;
    If CurrentData <> Undefined Then
        
        OpenForm("Catalog.FL_Channels.Form.ChoiceForm", 
            New Structure("BasicChannelGuid", CurrentData.BasicChannelGuid),
            ThisObject,
            New UUID,
            ,
            ,
            New NotifyDescription("DoAfterCloseChannelChoiceForm", ThisObject, 
                New Structure("Identifier ", CurrentData.GetID())),
            FormWindowOpeningMode.LockOwnerWindow);
            
    EndIf;
        
EndProcedure // SelectChannel()

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
   
    CurrentData = Items.Operations.CurrentData;
    If CurrentData <> Undefined Then
        
        ShowQueryBox(New NotifyDescription("DoAfterChooseOperationToDelete", 
            ThisObject, New Structure("Identifier ", CurrentData.GetID())),
            NStr("en='Permanently delete the selected operation?';
                |ru='Удалить выбранную операцию?';
                |en_CA='Permanently delete the selected operation?'"),
            QuestionDialogMode.YesNo, , DialogReturnCode.No);     
        
    EndIf;
    
EndProcedure // DeleteOperation()

&AtClient
Procedure SelectOperation(Command)
    
    CurrentData = Items.Operations.CurrentData;
    If CurrentData <> Undefined Then
        
        OpenForm("Catalog.FL_Operations.Form.ChoiceForm", 
            ,
            ThisObject,
            New UUID,
            ,
            ,
            New NotifyDescription("DoAfterCloseOperationChoiceForm", ThisObject, 
                New Structure("Identifier ", CurrentData.GetID())),
            FormWindowOpeningMode.LockOwnerWindow);
            
    EndIf;  
    
EndProcedure // SelectOperation() 

#EndRegion // FormCommandHandlers

#Region ServiceProceduresAndFunctions

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
            
        SearchResult = Events.FindByID(Identifier);
        If SearchResult <> Undefined Then
            Events.Delete(SearchResult);                
        EndIf;
        
        SetEventMatches();
            
    EndIf;
    
EndProcedure // DoAfterChooseEventToDelete()

&AtServer
Procedure SetEventMatches()
    
    Matched = True;
    For Each Item In Events Do
        
        MetadataObject = Metadata.FindByFullName(Item.MetadataObject);
        Item.Matched = MetadataObject <> Undefined;
        
        If NOT Item.Matched Then
            Matched = False;
        EndIf;
        
    EndDo;
        
    If NOT Matched Then
        Items.EventsPage.Picture = PictureLib.FL_ExplanationMark;
        Items.EventsPage.Title = NStr("en='Events (there are events that require attention)';
            |ru='События (есть события которые требуют внимания)';
            |en_CA='Events (there are events that require attention)'");
    Else
        Items.EventsPage.Picture = PictureLib.FL_Ok;
        Items.EventsPage.Title = NStr("en='Events';ru='События';en_CA='Events'");     
    EndIf;
    
EndProcedure // SetEventMatches()

#Region Formats

// Fills basic format info.
//
&AtServer
Procedure LoadBasicFormatInfo()

    FormatProcessor = FL_InteriorUse.NewFormatProcessor(BasicFormatGuid);    
    Catalogs.FL_Exchanges.FillFormatDescription(ThisObject, FormatProcessor);
    
EndProcedure // LoadBasicFormatInfo()

// Returns link to the formal document from the Internet Engineering Task Force 
// (IETF) that is the result of committee drafting and subsequent review 
// by interested parties.
//
&AtServer
Function FormatStandardLink() 
    
    FormatProcessor = FL_InteriorUse.NewFormatProcessor(BasicFormatGuid);     
    Return FormatProcessor.FormatStandardLink();
    
EndFunction // FormatStandardLink()

#EndRegion // Formats

#Region Operations

// Sets the selected operation as corresponding to the current line in the 
// operation table.
//
// Parameters:
//  ClosureResult        - Arbitrary - the value transferred when you call 
//                                      the Close method of the opened form.
//  AdditionalParameters - Arbitrary - the value specified when the 
//                                      NotifyDescription object was created. 
//
&AtClient
Procedure DoAfterCloseOperationChoiceForm(ClosureResult, 
    AdditionalParameters) Export

    If ClosureResult <> Undefined 
        AND TypeOf(ClosureResult) = Type("CatalogRef.FL_Operations") Then
        
        CurrentData = Operations.FindByID(AdditionalParameters.Identifier);
        CurrentData.Ref = ClosureResult;
        CurrentData.OperationMatched = True;
        CurrentData.RESTMatched = True;
        CurrentData.CRUDResolved = True;
        
    EndIf;
    
EndProcedure // DoAfterCloseOperationChoiceForm()
    
// Deletes the selected operation.
//
// Parameters:
//  QuestionResult       - DialogReturnCode - system enumeration value 
//                  or a value related to a clicked button. If a dialog 
//                  is closed on timeout, the value is Timeout. 
//  AdditionalParameters - Arbitrary        - the value specified when the 
//                              NotifyDescription object was created.
//
&AtClient
Procedure DoAfterChooseOperationToDelete(QuestionResult, 
    AdditionalParameters) Export
    
    Var Identifier;
    
    If QuestionResult = DialogReturnCode.Yes
        AND TypeOf(AdditionalParameters) = Type("Structure")
        AND AdditionalParameters.Property("Identifier", Identifier) Then
            
        SearchResult = Operations.FindByID(Identifier);
        If SearchResult <> Undefined Then
            Operations.Delete(SearchResult);                
        EndIf;
        
        SetOperationMatches();
            
    EndIf;
    
EndProcedure // DoAfterChooseOperationToDelete()

// Only for internal use.
//
&AtServer
Procedure SetOperationMatches()
    
    Matched = True;
    For Each Item In Operations Do
        
        Item.OperationMatched = Item.Ref.Description = Item.Description;
        Item.RESTMatched   = Item.Ref.RESTMethod  = Item.RESTMethod;
        Item.CRUDResolved  = Item.Ref.CRUDMethod  = Item.CRUDMethod;
        
        If NOT Item.OperationMatched
            OR NOT Item.RESTMatched 
            OR NOT Item.CRUDResolved Then
            Matched = False;
        EndIf;
        
    EndDo;
    
    If NOT Matched Then
        Items.OperationsPage.Picture = PictureLib.FL_ExplanationMark;
        Items.OperationsPage.Title = NStr("en='Operations (there are operations that require attention)';
            |ru='Операции (есть операции которые требуют внимания)';
            |en_CA='Operations (there are operations that require attention)'");
    Else
        Items.OperationsPage.Picture = PictureLib.FL_Ok;
        Items.OperationsPage.Title = NStr("en='Operations';ru='Операции';en_CA='Operations'");     
    EndIf;
        
EndProcedure // SetOperationMatches()

#EndRegion // Operations

#Region Channels

// Sets the selected channel as corresponding to the current line in the 
// channel table.
//
// Parameters:
//  ClosureResult        - Arbitrary - the value transferred when you call 
//                                      the Close method of the opened form.
//  AdditionalParameters - Arbitrary - the value specified when the 
//                                      NotifyDescription object was created. 
//
&AtClient
Procedure DoAfterCloseChannelChoiceForm(ClosureResult, 
    AdditionalParameters) Export

    If ClosureResult <> Undefined 
        AND TypeOf(ClosureResult) = Type("CatalogRef.FL_Channels") Then
        
        CurrentData = Channels.FindByID(AdditionalParameters.Identifier);
        CurrentData.Ref = ClosureResult;
        
        SetChannelMatches();
        
    EndIf;
    
EndProcedure // DoAfterCloseChannelChoiceForm()
    
// Saves a connection to this channel into database if it was established.
//
// Parameters:
//  ClosureResult        - Arbitrary - the value transferred when you call 
//                                      the Close method of the opened form.
//  AdditionalParameters - Arbitrary - the value specified when the 
//                                      NotifyDescription object was created. 
//
&AtClient
Procedure DoAfterCloseConnectionForm(ClosureResult, 
    AdditionalParameters) Export
    
    If ClosureResult <> Undefined 
        AND TypeOf(ClosureResult) = Type("FormDataStructure") Then
            
        If ClosureResult.Property("ChannelData")
            AND TypeOf(ClosureResult.ChannelData) = Type("FormDataCollection") Then
            
            FL_CommonUseClientServer.ExtendValueTable(
                ClosureResult.ChannelData, ChannelData);
            
        EndIf;
        
        If ClosureResult.Property("EncryptedData")
            AND TypeOf(ClosureResult.EncryptedData) = Type("FormDataCollection") Then
            
            FL_CommonUseClientServer.ExtendValueTable(
                ClosureResult.EncryptedData, EncryptedData);
            
        EndIf;
        
        InstallOrUpdateChannelAtServer(AdditionalParameters.Identifier);
 
    EndIf;
    
EndProcedure // DoAfterCloseConnectionForm()

// Deletes the selected channel.
//
// Parameters:
//  QuestionResult       - DialogReturnCode - system enumeration value 
//                  or a value related to a clicked button. If a dialog 
//                  is closed on timeout, the value is Timeout. 
//  AdditionalParameters - Arbitrary        - the value specified when the 
//                              NotifyDescription object was created.
//
&AtClient
Procedure DoAfterChooseChannelToDelete(QuestionResult, 
    AdditionalParameters) Export
    
    Var Identifier;
    
    If QuestionResult = DialogReturnCode.Yes
        AND TypeOf(AdditionalParameters) = Type("Structure")
        AND AdditionalParameters.Property("Identifier", Identifier) Then
            
        SearchResult = Channels.FindByID(Identifier);
        If SearchResult <> Undefined Then
            Channels.Delete(SearchResult);                
        EndIf;
        
        SetChannelMatches();
            
    EndIf;
    
EndProcedure // DoAfterChooseChannelToDelete()

// Only for internal use.
//
&AtClient
Procedure InstallOrUpdateChannel(CurrentData)
    
    If PreAuthorizationRequired(CurrentData.BasicChannelGuid) Then
                
        ChannelParameters = ChannelParameters(
            CurrentData.BasicChannelGuid, "ConnectionForm");
        ChannelParameters.Insert("Identifier", CurrentData.GetID());
        
        OpenForm(ChannelParameters.FormName, 
            ChannelParameters, 
            ThisObject,
            New UUID, 
            , 
            , 
            New NotifyDescription("DoAfterCloseConnectionForm", ThisObject, 
                ChannelParameters), 
            FormWindowOpeningMode.LockOwnerWindow);
            
    Else

        InstallOrUpdateChannelAtServer(CurrentData.GetID());
        
    EndIf;
    
EndProcedure // InstallOrUpdateChannel()

// Only for internal use.
//
&AtServer
Procedure SetChannelMatches()
        
    Matched = True;
    For Each Item In Channels Do
        
        Item.VersionMatched = Item.Ref.Version = Item.Version;
        Item.ConnectedMatched = Item.Ref.Connected = Item.Connected;
        Item.ChannelGuidMatched = Item.Ref.BasicChannelGuid = Item.BasicChannelGuid;
        
        If NOT Item.VersionMatched
            OR NOT Item.ConnectedMatched 
            OR NOT Item.ChannelGuidMatched Then
            Matched = False;
        EndIf;
        
    EndDo;
    
    If NOT Matched Then
        Items.ChannelsPage.Picture = PictureLib.FL_ExplanationMark;
        Items.ChannelsPage.Title = NStr("en='Channels (there are channels that require attention)';
            |ru='Каналы (есть каналы которые требуют внимания)';
            |en_CA='Channels (there are channels that require attention)'");
    Else
        Items.ChannelsPage.Picture = PictureLib.FL_Ok;
        Items.ChannelsPage.Title = NStr("en='Channels';ru='Каналы';en_CA='Channels'");     
    EndIf;
    
EndProcedure // SetChannelMatches()

// Only for internal use.
//
&AtServer
Procedure InstallOrUpdateChannelAtServer(Identifier)
    
    Channel = Channels.FindByID(Identifier);
    If Channel.Ref.IsEmpty() Then
        ChannelObject = Catalogs.FL_Channels.CreateItem();
        ChannelObject.Description = Channel.Description;
    Else    
        ChannelObject = Channel.Ref.GetObject();    
    EndIf;
    
    ChannelObject.BasicChannelGuid = Channel.BasicChannelGuid;
    ChannelObject.Connected = True;
    ChannelObject.Log = Channel.Log;
    ChannelObject.Version = Channel.Version;
    ChannelObject.ChannelData.Clear();
    ChannelObject.EncryptedData.Clear();
    
    FL_CommonUseClientServer.ExtendValueTable(ChannelData, 
        ChannelObject.ChannelData);
    FL_CommonUseClientServer.ExtendValueTable(EncryptedData, 
        ChannelObject.EncryptedData);     
        
    ChannelData.Clear();
    EncryptedData.Clear(); 
        
    ChannelObject.Write(); 
    Channel.Ref = ChannelObject.Ref;
    
    SetChannelMatches();
    
EndProcedure // InstallOrUpdateChannelAtServer() 

// Only for internal use.
//
&AtServerNoContext
Function PreAuthorizationRequired(Val LibraryGuid)
    
    ChannelProcessor = FL_InteriorUse.NewChannelProcessor(LibraryGuid);
    Return ChannelProcessor.PreAuthorizationRequired(); 
    
EndFunction // PreAuthorizationRequired()

// Only for internal use.
//
&AtServerNoContext
Function ChannelParameters(Val LibraryGuid, Val FormName)
    
    Return Catalogs.FL_Channels.NewChannelParameters(LibraryGuid, FormName);      
 
EndFunction // ChannelParameters()

#EndRegion // Channels

#Region Exchange

&AtServer
Procedure SetExchangeMatches()
    
    If Ref.IsEmpty() Then
        Items.FormInstallExchangeUpdate.Visible = False;
        Items.FormInstallExchange.Visible = True;
        Items.FormInstallExchange.DefaultButton = True;
    Else
        Items.FormInstallExchange.Visible = False;
        Items.FormInstallExchangeUpdate.Visible = True;
        Items.FormInstallExchangeUpdate.DefaultButton = True;    
    EndIf;
    
EndProcedure // SetExchangeMatches()

// Only for internal use.
//
&AtServer
Procedure InstallOrUpdateExchangeAtServer()
    
    If Ref.IsEmpty() Then
        Object = Catalogs.FL_Exchanges.CreateItem();
    Else    
        Object = Ref.GetObject();    
    EndIf;
    
    Object.ChannelResources.Clear();
    Object.Channels.Clear();
    Object.Events.Clear();
    Object.Operations.Clear();
    
    Object.Description = Description;
    Object.BasicFormatGuid = BasicFormatGuid;
    Object.InUse = InUse;
    Object.Version = Version;
    
    ImportedExchange = ImportedExchange();
    ImportOperations(Object, ImportedExchange, Operations);
    ImportEvents(Object, ImportedExchange, Operations, Events);
    ImportChannels(Object, ImportedExchange, Operations, Channels);
    ImportChannelResources(Object, ImportedExchange, Operations, Channels);
    
    Object.Write(); 
    Ref = Object.Ref;

EndProcedure // InstallOrUpdateExchangeAtServer()

// Only for internal use.
//
&AtServerNoContext
Procedure ImportOperations(Object, ImportedExchange, OperationTable)
    
    If NOT ImportedExchange.Property("Operations") Then
        Return;    
    EndIf; 
    
    FilterParameters = New Structure("Operation");
    For Each Operation In ImportedExchange.Operations Do
        
        FilterParameters.Operation = Operation.Operation;
        FilterResult = OperationTable.FindRows(FilterParameters);
        If FilterResult.Count() <> 0 Then
            CorrespondingOperation = FilterResult[0].Ref;    
        Else 
            Continue;
        EndIf;
        
        NewOperation = Object.Operations.Add();
        FillPropertyValues(NewOperation, Operation, , "APISchema, 
            |DataCompositionSchema, DataCompositionSettings, Operation");
        
        NewOperation.APISchema = FL_CommonUse.ValueFromJSONString(
            Operation.APISchema);
        NewOperation.DataCompositionSchema = FL_CommonUse.ValueFromJSONString(
            Operation.DataCompositionSchema);
        NewOperation.DataCompositionSettings = FL_CommonUse.ValueFromJSONString(
            Operation.DataCompositionSettings);
        NewOperation.Operation = CorrespondingOperation;
        
    EndDo;
    
EndProcedure // ImportOperations()

// Only for internal use.
//
&AtServerNoContext
Procedure ImportEvents(Object, ImportedExchange, OperationTable, EventTable)
    
    If NOT ImportedExchange.Property("Events") Then
        Return;    
    EndIf; 
    
    FilterParameters = New Structure("MetadataObject");
    For Each Event In ImportedExchange.Events Do
        
        FilterParameters.MetadataObject = Event.MetadataObject;
        FilterResult = EventTable.FindRows(FilterParameters);
        If FilterResult.Count() = 0 Then
            Continue;
        EndIf;
        
        EventFilter = New Structure("Operation");
        FillPropertyValues(EventFilter, Event);
        OperationLines = FindOperationLines(Object.Operations, OperationTable, 
            EventFilter);
        For Each OperationLine In OperationLines Do
            NewEvent = Object.Events.Add();
            FillPropertyValues(NewEvent, Event, , "Operation");
            FillPropertyValues(NewEvent, OperationLine, "Operation");
        EndDo;
        
    EndDo;
    
EndProcedure // ImportEvents()

// Only for internal use.
//
&AtServerNoContext
Procedure ImportChannels(Object, ImportedExchange, OperationTable, ChannelTable)
    
    If NOT ImportedExchange.Property("Channels") Then
        Return;    
    EndIf; 
    
    FilterParameters = New Structure("Channel");
    For Each Channel In ImportedExchange.Channels Do
        
        FilterParameters.Channel = Channel.Channel;
        FilterResult = ChannelTable.FindRows(FilterParameters);
        If FilterResult.Count() = 0 Then
            Continue;
        EndIf;
        
        ChannelFilter = New Structure("Operation");
        FillPropertyValues(ChannelFilter, Channel);
        OperationLines = FindOperationLines(Object.Operations, OperationTable, 
            ChannelFilter);
        For Each OperationLine In OperationLines Do
            NewChannel = Object.Channels.Add();
            NewChannel.Channel = FilterResult[0].Ref; 
            FillPropertyValues(NewChannel, Channel, , "Channel, Operation");
            FillPropertyValues(NewChannel, OperationLine, "Operation");
        EndDo;
        
    EndDo;
    
EndProcedure // ImportChannels()

// Only for internal use.
//
&AtServerNoContext
Procedure ImportChannelResources(Object, ImportedExchange, OperationTable, ChannelTable)
    
    If NOT ImportedExchange.Property("Channels") Then
        Return;    
    EndIf;
    
    If NOT ImportedExchange.Property("ChannelResources") Then
        Return;    
    EndIf; 
    
    FilterParameters = New Structure("Channel");
    For Each ChannelResource In ImportedExchange.ChannelResources Do
        
        FilterParameters.Channel = ChannelResource.Channel;
        FilterResult = ChannelTable.FindRows(FilterParameters);
        If FilterResult.Count() = 0 Then
            Continue;
        EndIf;
        
        ChannelResourceFilter = New Structure("Operation");
        FillPropertyValues(ChannelResourceFilter, ChannelResource);
        OperationLines = FindOperationLines(Object.Operations, OperationTable, 
            ChannelResourceFilter);
        For Each OperationLine In OperationLines Do
            NewChannelResource = Object.ChannelResources.Add();
            NewChannelResource.Channel = FilterResult[0].Ref; 
            FillPropertyValues(NewChannelResource, ChannelResource, , "Channel, Operation");
            FillPropertyValues(NewChannelResource, OperationLine, "Operation");
        EndDo;
        
    EndDo;
    
EndProcedure // ImportChannelResources()

// Only for internal use.
//
&AtServerNoContext
Function FindOperationLines(VTOperations, FDCOperations, FilterParameters)
    
    FilterResult = FDCOperations.FindRows(New Structure("Operation", 
        FilterParameters.Operation));
    If FilterResult.Count() <> 0 Then
        FilterParameters.Operation = FilterResult[0].Ref;
    Else 
        Return Undefined;
    EndIf;
    
    Return VTOperations.FindRows(FilterParameters);    
    
EndFunction // FindOperationLines()

// Only for internal use.
//
&AtServer
Function ImportedExchange()
    
    BinaryData = GetFromTempStorage(BinaryDataAddress);
    JSONReader = New JSONReader;
    JSONReader.OpenStream(BinaryData.OpenStreamForRead());
    Return ReadJSON(JSONReader);
    
EndFunction // ImportedExchange()

#EndRegion // Exchange

#EndRegion // ServiceProceduresAndFunctions