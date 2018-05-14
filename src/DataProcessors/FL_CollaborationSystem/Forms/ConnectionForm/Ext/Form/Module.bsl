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

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
    
    Object.Log = True;    
    
EndProcedure // OnCreateAtServer()

#EndRegion // FormEventHandlers

#Region FormCommandHandlers

&AtClient
Procedure ConnectToCollaborationSystem(Command)
        
    If InfoBaseRegistered() Then
        
        Close(Object);
        
    Else 
        
        LogMessage = NStr("en='This infobase is not registered in the collaboration system.';
            |ru='Текущая информационная база не зарегистрирована в системе взаимодействия.';
            |uk='Поточна інформаційна база не зареєстрована в системі взаємодії.';
            |en_CA='This infobase is not registered in the collaboration system.'");
        LogAttribute = LogAttribute + LogMessage;    
        
    EndIf;
       
EndProcedure // ConnectToCorezoid() 

#EndRegion // FormCommandHandlers 

#Region ServiceProceduresAndFunctions

&AtServer
Function InfoBaseRegistered()

    SetPrivilegedMode(True);
    Return CollaborationSystem.InfoBaseRegistered();
        
EndFunction // InfoBaseRegistered()

#EndRegion // ServiceProceduresAndFunctions