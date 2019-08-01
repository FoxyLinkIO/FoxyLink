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

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
    
    If Parameters.Property("AutoTest") Then
        Return;
    EndIf;
    
    FL_InteriorUse.FillAppEndpointResourcesFormData(ThisObject, Parameters);
     
EndProcedure // OnCreateAtServer()

#EndRegion // FormEventHandlers

#Region FormItemsEventHandlers

&AtClient
Procedure HTTPMethodStartChoice(Item, ChoiceData, StandardProcessing)
    
    StandardProcessing = False;
    
    ShowChooseFromList(New NotifyDescription("DoAfterChooseHTTPMethod",
        ThisObject), HTTPMethods(), Item);
    
EndProcedure // HTTPMethodStartChoice()

#EndRegion // FormItemsEventHandlers

#Region FormCommandHandlers

&AtClient
Procedure SaveAndClose(Command)
    
    If IsBlankString(HTTPMethod) Then
        FL_CommonUseClientServer.NotifyUser(
            NStr("en='Field {HTTPMethod} must be filled.';
                |ru='Поле {Метод HTTP} должно быть заполнено.';
                |uk='Поле {Методу HTTP} повинно бути заповненим.';
                |en_CA='Field {HTTPMethod} must be filled.'"), , "HTTPMethod");
        Return;  
    EndIf;
    
    If IsBlankString(Resource) Then
        FL_CommonUseClientServer.NotifyUser(
            NStr("en='Field {Resource} must be filled.';
                |ru='Поле {Ресурс} должно быть заполнено.';
                |uk='Поле {Ресурс} повинно бути заповненим.';
                |en_CA='Field {Resource} must be filled.'"), , "Resource");
        Return;    
    EndIf;
    
    FL_EncryptionClientServer.AddFieldValue(Object.ChannelResources, 
        "HTTPMethod", HTTPMethod);
    
    FL_EncryptionClientServer.AddFieldValue(Object.ChannelResources, 
        "Resource", Resource);
        
    Close(Object);
    
EndProcedure // SaveAndClose()

#EndRegion // FormCommandHandlers

#Region ServiceProceduresAndFunctions

// Adds new channel to operation to ThisObject.
//
// Parameters:
//  SelectedElement      - ValueListItem - the selected list item or Undefined 
//                                          if the user has not selected anything. 
//  AdditionalParameters - Arbitrary     - the value specified when the 
//                                          NotifyDescription object was created.
//
&AtClient
Procedure DoAfterChooseHTTPMethod(SelectedElement, AdditionalParameters) Export
    
    If SelectedElement <> Undefined Then
        HTTPMethod = String(SelectedElement.Value);    
    EndIf;
    
EndProcedure // DoAfterChooseHTTPMethod() 

// Only for internal use.
//
&AtServerNoContext
Function HTTPMethods()
    
    Return Enums.FL_RESTMethods.Methods();
    
EndFunction // HTTPMethods()

#EndRegion // ServiceProceduresAndFunctions