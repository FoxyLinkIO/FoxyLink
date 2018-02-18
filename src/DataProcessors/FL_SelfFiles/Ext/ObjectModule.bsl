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
    
    Return "FoxyLink file-messaging";    
    
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
    
    Var PayLoad, FileName;
    
    SuccessCode = 200;
    DeliveryResult = Catalogs.FL_Channels.NewChannelDeliverResult();    
    
    If TypeOf(Properties) <> Type("Structure") Then   
        Raise FL_ErrorsClientServer.ErrorTypeIsDifferentFromExpected(
            "Properties", Properties, Type("Structure"));
    EndIf;

    Properties.Property("FileName", FileName);
    If TypeOf(FileName) <> Type("String") Then   
        Raise FL_ErrorsClientServer.ErrorTypeIsDifferentFromExpected(
            "FileName", FileName, Type("String"));
    EndIf; 
    
    FileStream = New FileStream(FileName, FileOpenMode.Create, 
        FileAccess.Write);
    DataWriter = New DataWriter(FileStream);
    DataReader = New DataReader(Stream);
    DataReader.CopyTo(DataWriter);
    
    DataReader.Close();
    DataWriter.Close();
    FileStream.Close();
        
    If Log Then
        DeliveryResult.LogAttribute = "200 Success";
    EndIf;
    DeliveryResult.Success = True;
    DeliveryResult.StatusCode = SuccessCode;
    DeliveryResult.StringResponse = "200 Success";
    
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
    
    Return True;
    
EndFunction // ResourcesRequired()

// Returns array of supplied integrations for this configuration.
//
// Returns:
//  Array - array filled by supplied integrations.
//      * ArrayItem - Structure - see function FL_InteriorUse.NewPluggableSettings.
//
Function SuppliedIntegrations() Export
    
    SuppliedIntegrations = New Array;    
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
    
    Return "1.0.1";
    
EndFunction // Version()

// Returns base object description.
//
// Returns:
//  String - base object description.
//
Function BaseDescription() Export
    
    BaseDescription = NStr("en='Export data to file (%1) channel processor, ver. %2'; 
        |ru='Обработчик канала экспорта данных в файл (%1), вер. %2';
        |en_CA='Export data to file (%1) channel processor, ver. %2'");
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
    
    Return "595e752d-57f4-4398-a1cb-e6c5a6aaa65c";
    
EndFunction // LibraryGuid()

#EndRegion // ExternalDataProcessorInfo

#EndIf