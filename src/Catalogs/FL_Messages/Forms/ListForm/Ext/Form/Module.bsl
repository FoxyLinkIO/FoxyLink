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
    
    UpdateJobRoutingStateAtServer();   
    
EndProcedure // OnCreateAtServer()

&AtClient
Procedure OnOpen(Cancel)
    
    AttachIdleHandler("UpdateJobRoutingState", 10, False);
    
EndProcedure // OnOpen()

#EndRegion // FormEventHandlers 

#Region FormCommandHandlers

&AtClient
Procedure ManualRouting(Command)
    
    CurrentData = Items.List.CurrentData;
    If CurrentData <> Undefined Then
        ManualRoutingAtServer(Items.List.SelectedRows);
    Else
        UserMessage = NStr("en='Select a message to route from the list.';
            |ru='Выберите сообщение для маршрутизации из списка.';
            |uk='Виберіть повідомлення для маршрутизації зі списку.';
            |en_CA='Select a message to route from the list.'"); 
        FL_CommonUseClientServer.NotifyUser(UserMessage);
     EndIf;

EndProcedure // ManualRouting()

// See procedure FL_JobServer.RunScheduledJob.
//
&AtClient
Procedure StartJobRouting(Command)
    
    StartJobRoutingAtServer();
    
EndProcedure // StartJobRouting()

// See procedure FL_JobServer.StopScheduledJob.
//
&AtClient
Procedure StopJobRouting(Command)
    
    StopJobRoutingAtServer();
        
    ShowUserNotification(
        NStr("en='Job routing (FoxyLink)';
            |ru='Маршрутизация заданий (FoxyLink)';
            |uk='Маршрутизація завдань (FoxyLink)';
            |en_CA='Job routing (FoxyLink)'"),
        ,
        NStr("en='Job routing is stopped, but the stopped status will be set by the server just in a few seconds.';
            |ru='Маршрутизацию заданий остановлено, но состояние остановки будет установлено сервером через несколько секунд.';
            |uk='Маршрутизацію завдань зупинено, але стан зупинки буде встановлено сервером через декілька секунд.';
            |en_CA='Job routing is stopped, but the stopped status will be set by the server just in a few seconds.'"),
        PictureLib.FL_Logotype64
        );

EndProcedure // StopJobRouting()

#EndRegion // FormCommandHandlers 

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
&AtClient
Procedure UpdateJobRoutingState() Export
    
    UpdateJobRoutingStateAtServer();
    
EndProcedure // UpdateJobRoutingState() 

// Only for internal use.
//
&AtServer
Procedure UpdateJobRoutingStateAtServer()
     
    If FL_JobServer.ServerWatchDog(FL_JobServer.JobRouting()) Then
        Items.GroupJobRoutingPages.CurrentPage = Items.GroupJobRoutingRunning;
    Else
        Items.GroupJobRoutingPages.CurrentPage = Items.GroupJobRoutingStopped; 
    EndIf;
    
EndProcedure // UpdateJobRoutingStateAtServer()

// See procedure FL_JobServer.RunScheduledJob.
// 
&AtServer
Procedure StartJobRoutingAtServer()
    
    FL_JobServer.RunScheduledJob(FL_JobServer.JobRouting()); 
    UpdateJobRoutingStateAtServer();
    
EndProcedure // StartJobRoutingAtServer()

// See procedure FL_JobServer.StopScheduledJob.
//
&AtServer
Procedure StopJobRoutingAtServer()
    
    FL_JobServer.StopScheduledJob(FL_JobServer.JobRouting());
    
EndProcedure // StopJobRoutingAtServer() 

&AtServerNoContext
Procedure ManualRoutingAtServer(Val Messages)
    
    For Each Message In Messages Do
        Catalogs.FL_Messages.Route(Message);
    EndDo;
    
EndProcedure // ManualRoutingAtServer()

#EndRegion // ServiceProceduresAndFunctions

