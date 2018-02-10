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

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region ChannelDescription

// The name of the standard API used in this channel.
//
// Returns:
//  String - name of the standard API.
//
Function ChannelStandard() Export
    
    Return "FoxyLink";
    
EndFunction // ChannelStandard()

// Returns the link to the description of the standard API that is used 
// in this channel.
//
// Returns:
//  String - the link to the description of the standard API.
//
Function ChannelStandardLink() Export
    
    Return "https://github.com/FoxyLinkIO/FoxyLink";
    
EndFunction // ChannelStandardLink()

// Returns short channel name.
//
// Returns:
//  String - channel short name.
// 
Function ChannelShortName() Export
    
    Return "FoxyLink";    
    
EndFunction // ChannelShortName()

// Returns full channel name.
//
// Returns:
//  String - channel full name.
//
Function ChannelFullName() Export
    
    Return "FoxyLink self-messaging";    
    
EndFunction // ChannelFullName()

#EndRegion // ChannelDescription     
    
#Region ProgramInterface

// Delivers a stream object to the current channel.
//
// Parameters:
//  Stream         - Stream       - a data stream that can be read successively 
//                              or/and where you can record successively. 
//                 - MemoryStream - specialized version of Stream object for 
//                              operation with the data located in the RAM.
//                 - FileStream   - specialized version of Stream object for 
//                              operation with the data located in a file on disk.
//  Properties     - Structure    - channel parameters.
//
// Returns:
//  Structure - see function Catalogs.FL_Channels.NewChannelDeliverResult.
//
Function DeliverMessage(Stream, Properties) Export
    
    SuccessCode = 200;
    DeliveryResult = Catalogs.FL_Channels.NewChannelDeliverResult();
    
    If TypeOf(Stream) = Type("MemoryStream") Then
        
        Stream.Seek(0, PositionInStream.Begin);
        
        DataReader = New DataReader(Stream);
        BinaryData = DataReader.Read().GetBinaryData();
        DataReader.Close();
        
        DeliveryResult.OriginalResponse = New ValueStorage(BinaryData, 
            New Deflation(9));
        DeliveryResult.StringResponse = GetStringFromBinaryData(BinaryData);
        DeliveryResult.StatusCode = SuccessCode;
        DeliveryResult.Success = True;
        
    EndIf;
    
    Return DeliveryResult;
    
EndFunction // DeliverMessage() 

// Invalidates the channel data. 
//
// Returns:
//  Boolean - if True channel was disconnected successfully.
//
Function Disconnect() Export
    
    Return True;
    
EndFunction // Disconnect() 

// Returns the boolean value whether preauthorization is required.
//
// Returns:
//  Boolean - if True preauthorization is required.
//
Function PreauthorizationRequired() Export
    
    Return False;
    
EndFunction // PreauthorizationRequired()

// Returns the boolean value whether resources are required.
//
// Returns:
//  Boolean - if True resources are required.
//
Function ResourcesRequired() Export
    
    Return False;
    
EndFunction // ResourcesRequired()

// Returns array of supplied integrations for this configuration.
//
// Returns:
//  Array - array filled by supplied integrations.
//      * ArrayItem - Structure - see function FL_InteriorUse.NewPluggableSettings.
//
Function SuppliedIntegrations() Export
    
    SuppliedIntegrations = New Array;
    
    BasicPhrases = New Array;
    BasicPhrases.Add(NStr("en='Exchange description service helps to transfer ';
        |ru='Сервис описания обменов помогает переносить обмены из одной ';
        |en_CA='Exchange description service helps to transfer '"));
    BasicPhrases.Add(NStr("en='exchanges from one accounting system to another.';
        |ru='учетной системы в другие.';
        |en_CA='exchanges from one accounting system to another.'"));
    
    PluggableSettings = FL_InteriorUse.NewPluggableSettings();   
    PluggableSettings.Name = NStr("en='Exchange description service';
        |ru='Сервис описания обменов';
        |en_CA='Exchange description service'");
    PluggableSettings.Template = "Self";
    PluggableSettings.ToolTip = StrConcat(BasicPhrases);
    PluggableSettings.Version = "1.1.4";
    SuppliedIntegrations.Add(PluggableSettings);
    
    Return SuppliedIntegrations;
          
EndFunction // SuppliedIntegration()

#EndRegion // ProgramInterface    

#Region ExternalDataProcessorInfo

// Returns object version.
//
// Returns:
//  String - object version.
//
Function Version() Export
    
    Return "1.1.5";
    
EndFunction // Version()

// Returns base object description.
//
// Returns:
//  String - base object description.
//
Function BaseDescription() Export
    
    BaseDescription = NStr("en='FoxyLink (%1) channel data processor, ver. %2';
        |ru='Обработчик канала FoxyLink (%1), вер. %2';
        |en_CA='FoxyLink (%1) channel data processor, ver. %2'");
    BaseDescription = StrTemplate(BaseDescription, ChannelStandard(), Version());      
    Return BaseDescription;    
    
EndFunction // BaseDescription()

// Returns library guid which is used to identify different implementations 
// of specific channel.
//
// Returns:
//  String - library guid. 
//  
Function LibraryGuid() Export
    
    Return "7fdeb371-1ad5-47e7-b1d6-f9acc55d893e";
    
EndFunction // LibraryGuid()

#EndRegion // ExternalDataProcessorInfo

#EndIf