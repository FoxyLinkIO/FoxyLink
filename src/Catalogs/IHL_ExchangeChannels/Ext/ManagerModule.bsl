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
//  ChannelProcessorName - String - name of the object type depends on the data 
//                                 processor name in the configuration.
//  LibraryGuid - String - library guid which is used to identify 
//                         different implementations of specific channel.
//
// Returns:
//  DataProcessorObject.<Data processor name> - channel data processor.
//
Function NewChannelProcessor(ChannelProcessorName, Val LibraryGuid) Export
    
    If IsBlankString(ChannelProcessorName) Then
    
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
        
    Else
        
        ChannelProcessor = DataProcessors[ChannelProcessorName].Create();
        
    EndIf;
            
    Return ChannelProcessor;
    
EndFunction // NewChannelProcessor()

#EndRegion // ProgramInterface

#EndIf