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
    
    Parameters.Property("LibraryGuid", LibraryGuid);
    Parameters.Property("Template", Template);
    
    If NOT IsBlankString(LibraryGuid) AND NOT IsBlankString(Template) Then 
        
        ChannelProcessor = Catalogs.FL_Channels.NewChannelProcessor(
            LibraryGuid);
        BinaryData = ChannelProcessor.GetTemplate(Template);
        JSONReader = New JSONReader;
        JSONReader.OpenStream(BinaryData.OpenStreamForRead());
        ImportedExchange = ReadJSON(JSONReader);
        
        FL_InteriorUse.LoadImportedExchange(ThisObject, ImportedExchange);
        
        SetMethodMatches();
        SetChannelMatches();
        SetEventMatches();
        
    EndIf;
    
    LoadBasicFormatInfo();
    
EndProcedure // OnCreateAtServer() 

#EndRegion // FormEventHandlers

#Region FormItemsEventHandlers

&AtClient
Procedure FormatStandardClick(Item, StandardProcessing)
    
    StandardProcessing = False;
    
    AppParameters = FL_InteriorUseClient.NewRunApplicationParameters();
    AppParameters.NotifyDescription = New NotifyDescription(
        "DoAfterBeginRunningApplication", ThisObject);
    AppParameters.CommandLine = FormatStandardLink();
    AppParameters.WaitForCompletion = True;
    
    FL_InteriorUseClient.Attachable_FileSystemExtension(New NotifyDescription(
        "Attachable_RunApplication", FL_InteriorUseClient, AppParameters));
        
EndProcedure // FormatStandardClick()

#EndRegion // FormItemsEventHandlers

#Region FormCommandHandlers

&AtClient
Procedure DeleteChannel(Command)
    
    CurrentData = Items.Channels.CurrentData;
    If CurrentData <> Undefined Then
        
        ShowQueryBox(New NotifyDescription("DoAfterChooseChannelToDelete", 
            ThisObject, New Structure("Identifier ", CurrentData.GetID())),
            NStr("en = 'Permanently delete the selected channel?';
                 |ru = 'Удалить выбранный канал?'"),
            QuestionDialogMode.YesNo, , DialogReturnCode.No);     
        
    EndIf;   
    
EndProcedure // DeleteChannel()

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
Procedure DeleteMethod(Command)
   
    CurrentData = Items.Methods.CurrentData;
    If CurrentData <> Undefined Then
        
        ShowQueryBox(New NotifyDescription("DoAfterChooseMethodToDelete", 
            ThisObject, New Structure("Identifier ", CurrentData.GetID())),
            NStr("en = 'Permanently delete the selected method?';
                 |ru = 'Удалить выбранный метод?'"),
            QuestionDialogMode.YesNo, , DialogReturnCode.No);     
        
    EndIf;
    
EndProcedure // DeleteMethod()

#EndRegion // FormCommandHandlers

#Region ServiceProceduresAndFunctions

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
            
    EndIf;
    
EndProcedure // DoAfterChooseChannelToDelete()

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
            
    EndIf;
    
EndProcedure // DoAfterChooseEventToDelete()

// Deletes the selected method.
//
// Parameters:
//  QuestionResult       - DialogReturnCode - system enumeration value 
//                  or a value related to a clicked button. If a dialog 
//                  is closed on timeout, the value is Timeout. 
//  AdditionalParameters - Arbitrary        - the value specified when the 
//                              NotifyDescription object was created.
//
&AtClient
Procedure DoAfterChooseMethodToDelete(QuestionResult, 
    AdditionalParameters) Export
    
    Var Identifier;
    
    If QuestionResult = DialogReturnCode.Yes
        AND TypeOf(AdditionalParameters) = Type("Structure")
        AND AdditionalParameters.Property("Identifier", Identifier) Then
            
        SearchResult = Methods.FindByID(Identifier);
        If SearchResult <> Undefined Then
            Methods.Delete(SearchResult);                
         EndIf;
            
    EndIf;
    
EndProcedure // DoAfterChooseMethodToDelete()

&AtServer
Procedure SetMethodMatches()
    
    Matched = True;
    For Each Item In Methods Do
        
        Item.MethodMatched = Upper(XMLString(Item.Ref)) = Upper(Item.Method);
        Item.RESTMatched   = Item.Ref.RESTMethod = Item.RESTMethod;
        Item.CRUDResolved  = Item.Ref.CRUDMethod = Item.CRUDMethod;
        
        If NOT Item.MethodMatched
            OR NOT Item.RESTMatched 
            OR NOT Item.CRUDResolved Then
            Matched = False;
        EndIf;
        
    EndDo;
    
    If NOT Matched Then
        Items.MethodsPage.Picture = PictureLib.FL_ExplanationMark;
        Items.MethodsPage.Title = NStr(
            "en = 'Methods (there are methods that require attention)'; 
            |ru = 'Методы (есть методы которые требуют внимания)'");
    Else
        Items.MethodsPage.Picture = PictureLib.FL_Ok;
        Items.MethodsPage.Title = NStr(
            "en = 'Methods'; 
            |ru = 'Методы'");     
    EndIf;
        
EndProcedure // SetMethodMatches()

&AtServer
Procedure SetChannelMatches()
        
    Matched = True;
    For Each Item In Channels Do
        
        Item.ChannelMatched = Upper(XMLString(Item.Ref)) = Upper(Item.Channel);
        Item.ConnectedMatched = Item.Ref.Connected = Item.Connected;
        Item.ChannelGuidMatched = Item.Ref.BasicChannelGuid = Item.BasicChannelGuid;
        
        If NOT Item.ChannelMatched
            OR NOT Item.ConnectedMatched 
            OR NOT Item.ChannelGuidMatched Then
            Matched = False;
        EndIf;
        
    EndDo;
    
    If NOT Matched Then
        Items.ChannelsPage.Picture = PictureLib.FL_ExplanationMark;
        Items.ChannelsPage.Title = NStr(
            "en = 'Channels (there are channels that require attention)'; 
            |ru = 'Каналы (есть каналы которые требуют внимания)'");
    Else
        Items.ChannelsPage.Picture = PictureLib.FL_Ok;
        Items.ChannelsPage.Title = NStr("en = 'Channels'; ru = 'Каналы'");     
    EndIf;
    
EndProcedure // SetChannelMatches()

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
        Items.EventsPage.Title = NStr(
            "en = 'Events (there are events that require attention)'; 
            |ru = 'События (есть события которые требуют внимания)'");
    Else
        Items.EventsPage.Picture = PictureLib.FL_Ok;
        Items.EventsPage.Title = NStr("en = 'Events'; ru = 'События'");     
    EndIf;
    
EndProcedure // SetEventMatches()

&AtServer
Procedure SetExchangeMatches()
    
EndProcedure // SetExchangeMatches()

#Region Formats

// Begins running an external application or opens an application file with 
// the associated name.
//
// Parameters:
//  CodeReturn           - Number, Undefined - the code of return, if a relevant
//                          input parameter <WaitForCompletion> is not specified. 
//  AdditionalParameters - Arbitrary         - the value specified when the 
//                              NotifyDescription object was created.
//
&AtClient
Procedure DoAfterBeginRunningApplication(CodeReturn, AdditionalParameters) Export
    
    If CodeReturn <> 0 Then 
        Explanation = NStr("
            |en = 'Unexpected error has happened.';
            |ru = 'Произошла непредвиденная ошибка.'");
    
        ShowUserNotification(Title, , Explanation, PictureLib.FL_Logotype64);
        
    EndIf;   
    
EndProcedure // DoAfterBeginRunningApplication()

// Fills basic format info.
//
&AtServer
Procedure LoadBasicFormatInfo()

    FormatProcessor = Catalogs.FL_Exchanges.NewFormatProcessor(
        BasicFormatGuid);
        
    Catalogs.FL_Exchanges.FillFormatDescription(ThisObject, FormatProcessor);
    
EndProcedure // LoadBasicFormatInfo()

// Returns link to the formal document from the Internet Engineering Task Force 
// (IETF) that is the result of committee drafting and subsequent review 
// by interested parties.
//
&AtServer
Function FormatStandardLink() 
    
    FormatProcessor = Catalogs.FL_Exchanges.NewFormatProcessor(
        BasicFormatGuid);     
    Return FormatProcessor.FormatStandardLink();
    
EndFunction // FormatStandardLink()

#EndRegion // Formats

#EndRegion // ServiceProceduresAndFunctions