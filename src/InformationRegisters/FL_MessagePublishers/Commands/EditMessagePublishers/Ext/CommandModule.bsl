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

#Region CommandHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
    
    FormParameters = New Structure;
    FormName = "InformationRegister.FL_MessagePublishers.Form.MessagePublishersForm";
    Uniqueness = FormName + ?(CommandExecuteParameters.Window = Undefined, 
        ".SingleWindow", "");
    OpenForm(FormName, FormParameters, CommandExecuteParameters.Source, 
        Uniqueness, CommandExecuteParameters.Window);
           
EndProcedure // CommandProcessing()

#EndRegion // CommandHandlers


