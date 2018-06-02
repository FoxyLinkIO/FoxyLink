﻿////////////////////////////////////////////////////////////////////////////////
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

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
    
    UpdateExchangeServerStateAtServer();   
    
EndProcedure // OnCreateAtServer()

&AtClient
Procedure OnOpen(Cancel)
    
    AttachIdleHandler("UpdateExchangeServerState", 10, False);
    
EndProcedure // OnOpen()

#EndRegion // FormEventHandlers

#Region FormCommandHandlers

&AtClient
Procedure ConnectConversation(Command)
    
    CurrentData = Items.List.CurrentData;
    If CurrentData <> Undefined Then
        ConnectConversationAtServer(CurrentData.Ref);    
    EndIf;
    
EndProcedure // ConnectConversation()

// See procedure FL_JobServer.RunScheduledJob.
//
&AtClient
Procedure StartExchangeServer(Command)
    
    StartExchangeServerAtServer();
    
EndProcedure // StartExchangeServer()

// See procedure FL_JobServer.StopScheduledJob.
//
&AtClient
Procedure StopExchangeServer(Command)
    
    StopExchangeServerAtServer();
        
    ShowUserNotification(
        NStr("en='Exchange server (SocialNetworks)';
            |ru='Сервер обменов (SocialNetworks)';
            |uk='Сервер обмінів (SocialNetworks)';
            |en_CA='Exchange server (SocialNetworks)'"),
        ,
        NStr("en='Exchange server is stopped, but the stopped status will be set by the server just in a few seconds.';
            |ru='Сервер обменов остановлен, но состояние остановки будет установлено сервером через несколько секунд.';
            |uk='Сервер обмінів зупинено, але стан зупинки буде встановлено сервером через декілька секунд.';
            |en_CA='Exchange server is stopped, but the stopped status will be set by the server just in a few seconds.'"),
        PictureLib.FL_Logotype64
        );
         
EndProcedure // StopExchangeServer()

#EndRegion // FormCommandHandlers

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
&AtClient
Procedure UpdateExchangeServerState() Export
    
    UpdateExchangeServerStateAtServer();
    
EndProcedure // UpdateExchangeServerState() 

// Updates exchange server state.
//
&AtServer
Procedure UpdateExchangeServerStateAtServer()
     
    If FL_JobServer.ServerWatchDog(SocialNetworks_ExchangeServer.ExchangeServer()) Then
        Items.GroupExchangeServerPages.CurrentPage = Items.GroupExchangeServerRunning;
    Else
        Items.GroupExchangeServerPages.CurrentPage = Items.GroupExchangeServerrStopped; 
    EndIf;
    
EndProcedure // UpdateExchangeServerStateAtServer() 

&AtServer
Procedure ConnectConversationAtServer(SocialConversation)
    
    CurrentUser = InfoBaseUsers.CurrentUser();
    TextTemplate = NStr("en='%1 connected to conversation...';
        |ru='%1 подключился к обсуждению...';
        |uk='%1 підключився до обговорення...';
        |en_CA='%1 connected to conversation...'");
    
    SocialMessage = InformationRegisters.SocialNetworks_Messages
        .NewSocialMessage();
    SocialMessage.SocialConversation = SocialConversation;
    SocialMessage.MessageId = String(New UUID);
    SocialMessage.Date = CurrentSessionDate();
    SocialMessage.Text = StrTemplate(TextTemplate, CurrentUser.FullName);
    
    ConversationId = FL_CommonUse.ObjectAttributeValue(SocialConversation, 
        "ConversationId");
    DataProcessors.FL_CollaborationSystem
        .CollaborationSystemConversationAddMember(ConversationId, 
            CurrentUser.UUID, SocialMessage); 
   
EndProcedure // ConnectConversationAtServer()

// See procedure FL_JobServer.RunScheduledJob.
// 
&AtServer
Procedure StartExchangeServerAtServer()
    
    FL_JobServer.RunScheduledJob(
        SocialNetworks_ExchangeServer.ExchangeServer(), False);
    UpdateExchangeServerStateAtServer();
    
EndProcedure // StartExchangeServerAtServer()

// See procedure FL_JobServer.StopScheduledJob.
//
&AtServer
Procedure StopExchangeServerAtServer()
    
    FL_JobServer.StopScheduledJob(
        SocialNetworks_ExchangeServer.ExchangeServer());
    
EndProcedure // StopExchangeServerAtServer() 

#EndRegion // ServiceProceduresAndFunctions