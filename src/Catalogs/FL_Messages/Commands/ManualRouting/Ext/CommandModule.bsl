////////////////////////////////////////////////////////////////////////////////
// This file is part of FoxyLink.
// Copyright © 2016-2019 Petro Bazeliuk.
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
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
    
    //For Each Message In Messages Do
    //    Catalogs.FL_Messages.Route(Message);
    //EndDo;
    
    // Insert handler content.
    //FormParameters = New Structure("", );
    //OpenForm("Catalog.FL_Messages.ListForm", FormParameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL);
EndProcedure // CommandProcessing()

#EndRegion // CommandHandlers

#Region ServiceProceduresAndFunctions

&AtServer
Function ManualRoutingInBackground(Val Source)
    
    Task = FL_TasksClientServer.NewTask();
    Task.Description = NStr("en='Manual message routing - is in a progress';
        |ru='Ручная маршрутизация сообщений - в процессе';
        |uk='Ручна маршрутизація повідомлень - триває';
        |en_CA='Manual message routing - is in a progress'");
    Task.MethodName = "Catalogs.FL_Messages.Route";
    Task.Parameters.Add(Source);
    BackgroundJob = FL_Tasks.Run(Task);
    
EndFunction // ManualRoutingInBackground() 

#EndRegion // ServiceProceduresAndFunctions


