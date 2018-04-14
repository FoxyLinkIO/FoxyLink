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

#EndRegion // FormCommandHandlers 

#Region ServiceProceduresAndFunctions

&AtServerNoContext
Procedure ManualRoutingAtServer(Val Messages)
    
    For Each Message In Messages Do
        Catalogs.FL_Messages.Route(Message);
    EndDo;
    
EndProcedure // ManualRoutingAtServer()

#EndRegion // ServiceProceduresAndFunctions

