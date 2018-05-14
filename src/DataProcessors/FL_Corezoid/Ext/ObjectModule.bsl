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
    
    Return "Corezoid";
    
EndFunction // ChannelStandard()

// Returns the link to the description of the standard API that is used 
// in this channel.
//
// Returns:
//  String - the link to the description of the standard API.
//
Function ChannelStandardLink() Export
    
    Return "https://new.corezoid.com/";
    
EndFunction // ChannelStandardLink()

// Returns short channel name.
//
// Returns:
//  String - channel short name.
// 
Function ChannelShortName() Export
    
    Return "Corezoid";    
    
EndFunction // ChannelShortName()

// Returns full channel name.
//
// Returns:
//  String - channel full name.
//
Function ChannelFullName() Export
    
    Return "Corezoid process engine";    
    
EndFunction // ChannelFullName()

#EndRegion // ChannelDescription 

#Region ProgramInterface

// Delivers a data object to the Elasticsearch application.
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
    
    If Properties <> Undefined 
        AND ValueIsFilled(Properties.ReplyTo) Then
        ResourceAddress = Properties.ReplyTo;
    Else
        ResourceAddress = FL_EncryptionClientServer.FieldValue(
            ChannelResources, "Resource");
    EndIf;
    
    // Getting HTTP method.
    HTTPMethod = FL_EncryptionClientServer.FieldValueNoException(ChannelResources, 
        "HTTPMethod");
    If HTTPMethod = Undefined Then
        HTTPMethod = "POST";
    EndIf;
    
    // Getting HTTP request.
    HTTPRequest = FL_InteriorUse.NewHTTPRequest(ResourceAddress, Headers, 
        Payload);
        
    // Getting HTTP connection.
    HTTPConnection = FL_InteriorUse.NewHTTPConnection(
        FL_EncryptionClientServer.FieldValue(ChannelData, "StringURI"));
    
    If Log Then
        JobResult.LogAttribute = "";     
    EndIf;
    
    FL_InteriorUse.CallHTTPMethod(HTTPConnection, HTTPRequest, HTTPMethod, 
        JobResult);
            
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
    
    PluggableSettings = FL_InteriorUse.NewPluggableSettings();   
    PluggableSettings.Name = 
        NStr("en='Social networks: receive and send messages';
            |ru='Социальные сети: получение и отсылка сообщений';
            |uk='Соціальні мережі: отримання та відправка повідомлень';
            |en_CA='Social networks: receive and send messages'");
    PluggableSettings.Template = "SocialNetworkMessage";
    PluggableSettings.ToolTip = 
        NStr("en='This settings helps to receive and send messages from\to social networks.';
            |ru='Настройки обмена для получения и отправки сообщений социальных сетей.';
            |uk='Налаштування обміну для отримання та відправки повідомлень соціальних мереж.';
            |en_CA='This settings helps to receive and send messages from\to social networks.'");
    PluggableSettings.Version = "1.0.0";
    SuppliedIntegrations.Add(PluggableSettings);
    
    PluggableSettings = FL_InteriorUse.NewPluggableSettings();   
    PluggableSettings.Name = 
        NStr("en='Social networks: users';
            |ru='Социальные сети: пользователи';
            |uk='Соціальні мережі: користувачі';
            |en_CA='Social networks: users'");
    PluggableSettings.Template = "SocialNetworkUsers";
    PluggableSettings.ToolTip = 
        NStr("en='This settings helps to create and update users.';
            |ru='Настройки создания и обновления пользователей.';
            |uk='Налаштування створення та оновлення користувачів.';
            |en_CA='This settings helps to create and update users.'");
    PluggableSettings.Version = "1.0.2";
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
        NStr("en='Corezoid (%1) application endpoint data processor, ver. %2';
            |ru='Обработчик конечной точки приложения Corezoid (%1), вер. %2';
            |uk='Обработчик кінцевої точки додатку Corezoid (%1), вер. %2';
            |en_CA='Corezoid (%1) application endpoint data processor, ver. %2'");
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
    
    Return "ef9dc415-9ad2-4980-97dc-b39fc1261f76";
    
EndFunction // LibraryGuid()

#EndRegion // ExternalDataProcessorInfo

#EndIf