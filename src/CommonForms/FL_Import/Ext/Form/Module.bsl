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
        
    Parameters.Property("LibraryGuid", LibraryGuid);
    Parameters.Property("Template", Template);
    
    If NOT IsBlankString(LibraryGuid) AND NOT IsBlankString(Template) Then 
        
        ChannelProcessor = Catalogs.FL_Channels.NewChannelProcessor(
            LibraryGuid);
        BinaryData = ChannelProcessor.GetTemplate(Template);
        JSONReader = New JSONReader;
        JSONReader.OpenStream(BinaryData.OpenStreamForRead());
        ImportStructure = ReadJSON(JSONReader);
        
        // Methods load.
        FL_CommonUseClientServer.ExtendValueTable(FL_InteriorUse
            .LoadImportedMethods(ImportStructure.Methods), Methods);
        SetMethodMatches();
        
        // Channels load.
        FL_CommonUseClientServer.ExtendValueTable(FL_InteriorUse
            .LoadImportedChannels(ImportStructure.Channels), Channels);
        FL_CommonUse.RemoveDuplicatesFromValueTable(Channels);
        SetChannelMatches();
        
        // Events load.
        FL_CommonUseClientServer.ExtendValueTable(ImportStructure.Events, 
            Events);
        FL_CommonUse.RemoveDuplicatesFromValueTable(Events);
        SetEventMatches();
        
    EndIf;
    
EndProcedure // OnCreateAtServer() 

#EndRegion // FormEventHandlers

#Region ServiceProceduresAndFunctions

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
        Items.GroupMethods.TitleTextColor = FL_CommonUseClientServer.NewColor(
            255, 0, 0);
        Items.GroupMethods.CollapsedRepresentationTitle = NStr(
            "en = 'Methods (there are methods that require attention)'; 
            |ru = 'Методы (есть методы которые требуют внимания)'");    
    EndIf;
        
EndProcedure // SetMethodMatches()

&AtServer
Procedure SetChannelMatches()
        
    Matched = True;
    For Each Item In Channels Do
        
        Item.ChannelMatched = Upper(XMLString(Item.Ref)) = Upper(Item.Channel);
        Item.ConnectedMatched = Item.Ref.Connected;
        
        If NOT Item.ChannelMatched
            OR NOT Item.ConnectedMatched Then
            Matched = False;
        EndIf;
        
    EndDo;
    
    If NOT Matched Then
        Items.GroupChannels.TitleTextColor = FL_CommonUseClientServer.NewColor(
            255, 0, 0);
        Items.GroupChannels.CollapsedRepresentationTitle = NStr(
            "en = 'Channels (there are channels that require attention)'; 
            |ru = 'Каналы (есть каналы которые требуют внимания)'");    
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
        Items.GroupEvents.TitleTextColor = FL_CommonUseClientServer.NewColor(
            255, 0, 0);
        Items.GroupEvents.CollapsedRepresentationTitle = NStr(
            "en = 'Events (there are events that require attention)'; 
            |ru = 'События (есть события которые требуют внимания)'");    
    EndIf;
    
EndProcedure // SetEventMatches()

#EndRegion // ServiceProceduresAndFunctions