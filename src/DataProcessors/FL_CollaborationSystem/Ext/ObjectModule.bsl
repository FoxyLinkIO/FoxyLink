////////////////////////////////////////////////////////////////////////////////
// This file is part of FoxyLink.
// Copyright © 2018-2019 Petro Bazeliuk.
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
    
    Return NStr("en='CollaborationSystem';
        |ru='СистемаВзаимодействия';
        |uk='СистемаВзаємодії';
        |en_CA='CollaborationSystem'");
    
EndFunction // ChannelStandard()

// Returns the link to the description of the standard API that is used 
// in this channel.
//
// Returns:
//  String - the link to the description of the standard API.
//
Function ChannelStandardLink() Export
    
    Return "https://its.1c.ru/db/v8310doc/bookmark/dev/TI000001900";
    
EndFunction // ChannelStandardLink()

// Returns short channel name.
//
// Returns:
//  String - channel short name.
// 
Function ChannelShortName() Export
    
    Return NStr("en='Collaboration system';
        |ru='Система взаимодействия';
        |uk='Система взаємодії';
        |en_CA='Collaboration system'");   
    
EndFunction // ChannelShortName()

// Returns full channel name.
//
// Returns:
//  String - channel full name.
//
Function ChannelFullName() Export
    
    Return NStr("en='1C:Enterprise collaboration system';
        |ru='Система взаимодействия 1С:Предприятие';
        |uk='Система взаємодії 1С:Предприятие';
        |en_CA='1C:Enterprise collaboration system'");    
    
EndFunction // ChannelFullName()

#EndRegion // ChannelDescription 

#Region ProgramInterface

// Delivers a data object to the Elasticsearch application.
//
// Parameters:
//  Invocation - Structure - see function Catalogs.FL_Messages.NewInvocation.
//  JobResult  - Structure - see function Catalogs.FL_Jobs.NewJobResult.
//
Procedure DeliverMessage(Invocation, JobResult) Export
    
    JobResult.StatusCode = FL_InteriorUseReUse.OkStatusCode();
    SocialMessage = InformationRegisters.SocialNetworks_Messages
        .DeserializeSocialMessage(Invocation.Payload, Invocation, JobResult);
    
    If FL_InteriorUseReUse.IsSuccessHTTPStatusCode(JobResult.StatusCode)     
        AND SocialMessage.Property("CollaborationMessageId")
        AND IsBlankString(SocialMessage.CollaborationMessageId) Then
            
        DataProcessors.FL_CollaborationSystem.CollaborationSystemMessage(
            SocialMessage);
            
    EndIf;
    
    JobResult.Success = FL_InteriorUseReUse.IsSuccessHTTPStatusCode(
        JobResult.StatusCode);
            
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
        NStr("en='Collaboration system: receive and send messages';
            |ru='Система взаимодействий: получение и отсылка сообщений';
            |uk='Система взаємодії: отримання та відправка повідомлень';
            |en_CA='Collaboration system: receive and send messages'");
    PluggableSettings.Template = "CollaborationSystemMessage";
    PluggableSettings.ToolTip = 
        NStr("en='This settings helps to receive and send messages from\to collaboration system.';
            |ru='Настройки обмена для получения и отправки сообщений системы взаимодействий.';
            |uk='Налаштування обміну для отримання та відправки повідомлень система взаємодії.';
            |en_CA='This settings helps to receive and send messages from\to collaboration system.'");
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
    
    Return "1.0.0";
    
EndFunction // Version()

// Returns base object description.
//
// Returns:
//  String - base object description.
//
Function BaseDescription() Export
    
    BaseDescription = 
        NStr("en='Collaboration system (%1) application endpoint data processor, ver. %2';
            |ru='Обработчик конечной точки приложения системы взаимодействия (%1), вер. %2';
            |uk='Обработчик кінцевої точки додатку системи взаємодії (%1), вер. %2';
            |en_CA='Collaboration system (%1) application endpoint data processor, ver. %2'");
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
    
    Return "32056f6f-ba75-497b-bcd3-c2a84ed7e80e";
    
EndFunction // LibraryGuid()

#EndRegion // ExternalDataProcessorInfo

#EndIf