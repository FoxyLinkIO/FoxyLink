////////////////////////////////////////////////////////////////////////////////
// This file is part of FoxyLink.
// Copyright © 2018 Petro Bazeliuk.
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
    
    Return "GMS-Worldwide";
    
EndFunction // ChannelStandard()

// Returns the link to the description of the standard API that is used 
// in this channel.
//
// Returns:
//  String - the link to the description of the standard API.
//
Function ChannelStandardLink() Export
    
    Return "https://www.gms-worldwide.com/";
    
EndFunction // ChannelStandardLink()

// Returns short channel name.
//
// Returns:
//  String - channel short name.
// 
Function ChannelShortName() Export
    
    Return "GMS-Worldwide";    
    
EndFunction // ChannelShortName()

// Returns full channel name.
//
// Returns:
//  String - channel full name.
//
Function ChannelFullName() Export
    
    Return "Global Messaging Provider";    
    
EndFunction // ChannelFullName()

#EndRegion // ChannelDescription 

#Region ProgramInterface

// Delivers a data object to the GMS application endpoint.
//
// Parameters:
//  Payload    - Arbitrary - the data that can be read successively and 
//                               delivered to the app endpoint.
//  Properties - Structure - see function Catalogs.FL_Exchanges.NewProperties.
//  JobResult  - Structure - see function Catalogs.FL_Jobs.NewJobResult.
//
Procedure DeliverMessage(Payload, Properties, JobResult) Export
        
    Headers = New Map;
    Headers.Insert("Accept", "application/json"); 
    Headers.Insert("Content-Type", "application/json");
    
    ResourceAddress = "/2024";
    
    // Getting HTTP method.
    HTTPMethod = FL_EncryptionClientServer.FieldValueNoException(
        ChannelResources, "HTTPMethod");
    If HTTPMethod = Undefined Then
        HTTPMethod = "POST";
    EndIf;
    
    // Getting HTTP request.
    HTTPRequest = FL_InteriorUse.NewHTTPRequest(ResourceAddress, Headers, 
        Payload);
        
    // Getting HTTP connection.
    HTTPConnection = FL_InteriorUse.NewHTTPConnection(
        FL_EncryptionClientServer.FieldValue(ChannelData, "StringURI"));
    
    FL_InteriorUse.CallHTTPMethod(HTTPConnection, HTTPRequest, HTTPMethod, 
        JobResult);
          
    If HTTPMethod = "GET" 
        AND JobResult.StatusCode = 405 Then
        JobResult.Success = True;
    EndIf;
            
EndProcedure // DeliverMessage() 

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
    
    Return True;
    
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
    
    PluggableSettings = FL_InteriorUse.NewPluggableSettings();   
    PluggableSettings.Name = 
        NStr("en='GMS-Worldwide: Viber\SMS integration';
            |ru='GMS-Worldwide: интеграция Viber\SMS';
            |uk='GMS-Worldwide: інтеграція Viber\SMS';
            |en_CA='GMS-Worldwide: Viber\SMS integration'");
    PluggableSettings.Template = "GMS_Worldwide";
    PluggableSettings.ToolTip = 
        NStr("en='This settings helps to send messages through Viber.';
            |ru='Эти настройки позволяют отправлять сообщения через Viber.';
            |uk='Ці налаштування допомагають надсилати повідомлення через Viber.';
            |en_CA='This settings helps to send messages through Viber.'");
    PluggableSettings.Version = "1.0.0";
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
    
    Return "1.0.1";
    
EndFunction // Version()

// Returns base object description.
//
// Returns:
//  String - base object description.
//
Function BaseDescription() Export
    
    BaseDescription = 
        NStr("en='GMS-Worldwide (%1) application endpoint data processor, ver. %2';
            |ru='Обработчик конечной точки приложения GMS-Worldwide (%1), вер. %2';
            |uk='Обработчик кінцевої точки додатку GMS-Worldwide (%1), вер. %2';
            |en_CA='GMS-Worldwide (%1) application endpoint data processor, ver. %2'");
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
    
    Return "b05d2d14-5bab-452a-af6c-06fa8a24beb6";
    
EndFunction // LibraryGuid()

#EndRegion // ExternalDataProcessorInfo

#EndIf