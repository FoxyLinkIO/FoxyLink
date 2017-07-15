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
    
    If IsBlankString(Object.BasicChannelGuid) Then
        For Each Channel In Catalogs.IHL_ExchangeChannels.AvailableChannels() Do
            FillPropertyValues(Items.BasicChannelGuid.ChoiceList.Add(), Channel);    
        EndDo;
        Items.HeaderPagesChannel.CurrentPage = Items.HeaderPageSelectChannel;
        Items.MainGroup.Visible = False;
        Items.HeaderGroupLeft.Visible = False;
    Else
        LoadBasicChannelInfo();    
    EndIf;
    
EndProcedure // OnCreateAtServer() 

#EndRegion // FormEventHandlers

#Region FormItemsEventHandlers

&AtClient
Procedure BasicChannelGuidOnChange(Item)
    
    If Not IsBlankString(Object.BasicChannelGuid) Then
        LoadBasicChannelInfo();   
    EndIf;
    
EndProcedure // BasicChannelGuidOnChange()

&AtClient
Procedure ChannelStandardClick(Item, StandardProcessing)
    
    StandardProcessing = False;
    BeginRunningApplication(New NotifyDescription(
        "DoAfterBeginRunningApplication", ThisObject), 
        ChannelStandardLink());
    
EndProcedure // ChannelStandardClick()

#EndRegion // FormItemsEventHandlers

#Region ServiceProceduresAndFunctions

&AtClient
Procedure DoAfterBeginRunningApplication(CodeReturn, AdditionalParameters) Export
    
    // TODO: Some checks   
    
EndProcedure // DoAfterBeginRunningApplication()



// Fills basic channel info.
//
&AtServer
Procedure LoadBasicChannelInfo()

    Items.MainGroup.Visible = True;
    Items.HeaderGroupLeft.Visible = True;
    Items.HeaderPagesChannel.CurrentPage = Items.HeaderPageBasicChannel;
    ChannelProcessor = Catalogs.IHL_ExchangeChannels.NewChannelProcessor(
        ChannelProcessorName, Object.BasicChannelGuid);
        
    ChannelName = StrTemplate("%1 (%2)", ChannelProcessor.ChannelFullName(),
        ChannelProcessor.ChannelShortName());    
    ChannelStandard = ChannelProcessor.ChannelStandard();      
    ChannelPluginVersion = ChannelProcessor.Version();
     
EndProcedure // LoadBasicChannelInfo()

// Returns link to the channel document from the Internet.
//
&AtServer
Function ChannelStandardLink() 
    
    ChannelProcessor = Catalogs.IHL_ExchangeChannels.NewChannelProcessor(
        ChannelProcessorName, Object.BasicChannelGuid);     
    Return ChannelProcessor.ChannelStandardLink();
    
EndFunction // ChannelStandardLink()

#EndRegion // ServiceProceduresAndFunctions   
    