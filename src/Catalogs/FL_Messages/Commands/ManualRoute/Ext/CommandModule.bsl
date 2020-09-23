////////////////////////////////////////////////////////////////////////////////
// This file is part of FoxyLink.
// Copyright © 2016-2020 Petro Bazeliuk.
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

#Region CommandHandlers

&AtClient
Procedure CommandProcessing(Messages, CommandExecuteParameters)
    
    If ValueIsFilled(Messages) Then
        
        ManualRoutingInBackground(Messages);    
        
    Else
        
        UserMessage = NStr("en='Select a message to route from the list.';
            |ru='Выберите сообщение для маршрутизации из списка.';
            |uk='Виберіть повідомлення для маршрутизації зі списку.';
            |en_CA='Select a message to route from the list.'"); 
        FL_CommonUseClientServer.NotifyUser(UserMessage);
        
    EndIf;

EndProcedure // CommandProcessing()

#EndRegion // CommandHandlers

#Region ServiceProceduresAndFunctions

&AtServer
Function ManualRoutingInBackground(Messages)
    
    Task = FL_TasksClientServer.NewTask();
    Task.Description = NStr("en='Manual message routing - is in a progress';
        |ru='Ручная маршрутизация сообщений - в процессе';
        |uk='Ручна маршрутизація повідомлень - триває';
        |en_CA='Manual message routing - is in a progress'");
    Task.MethodName = "Catalogs.FL_Messages.Route";
    Task.Parameters.Add(Messages);
    BackgroundJob = FL_Tasks.Run(Task);
    
EndFunction // ManualRoutingInBackground() 

#EndRegion // ServiceProceduresAndFunctions


