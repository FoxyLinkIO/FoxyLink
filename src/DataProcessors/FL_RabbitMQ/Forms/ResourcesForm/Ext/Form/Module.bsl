////////////////////////////////////////////////////////////////////////////////
// This file is part of FoxyLink.
// Copyright © 2016-2017 Petro Bazeliuk.
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
// along with this program. If not, see <http://www.gnu.org/licenses/agpl-3.0>.
//
////////////////////////////////////////////////////////////////////////////////

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
    
    If Parameters.Property("ChannelResources") Then
        
        ChannelResources = Parameters.ChannelResources;
        
        Attributes = GetAttributes();
        FilterParameters = New Structure("FieldName");
        For Each Attribute In Attributes Do
            
            FilterParameters.FieldName = Attribute.Name;
            SearchResult = ChannelResources.FindRows(FilterParameters);
            If SearchResult.Count() = 1 Then 
                ThisObject[Attribute.Name] = SearchResult[0].FieldValue;                   
            EndIf;
            
        EndDo;
        
    EndIf;
     
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
        FL_CommonUseClientServer.NotifyUser(NStr("
            |en = 'Field ''HTTPMethod'' must be filled.';
            |ru = 'Поле ''Метод HTTP'' должно быть заполнено.'"), , "HTTPMethod");
        Return;  
    EndIf;
    
    If IsBlankString(Resource) Then
        FL_CommonUseClientServer.NotifyUser(NStr("
            |en = 'Field ''Resource'' must be filled.';
            |ru = 'Поле ''Ресурс'' должно быть заполнено.'"), , "Resource");
        Return;    
    EndIf;
    
    ResourceRow = Object.ChannelResources.Add();
    ResourceRow.FieldName = "HTTPMethod";
    ResourceRow.FieldValue = HTTPMethod;
    
    ResourceRow = Object.ChannelResources.Add();
    ResourceRow.FieldName = "Resource";
    ResourceRow.FieldValue = Resource;
    ResourceRow.ExecutableCode = True;
    
    Close(Object);
    
EndProcedure // SaveAndClose()

#EndRegion // FormCommandHandlers

#Region ServiceProceduresAndFunctions

&AtClient
Procedure DoAfterChooseHTTPMethod(SelectedElement, AdditionalParameters) Export
    
    If SelectedElement <> Undefined Then
        HTTPMethod = String(SelectedElement.Value);    
    EndIf;
    
EndProcedure // DoAfterChooseHTTPMethod() 

// See function Catalogs.FL_Channels.ExchangeChannels.
//
&AtServerNoContext
Function HTTPMethods()
    
    Return Enums.FL_RESTMethods.Methods();
    
EndFunction // HTTPMethods()

#EndRegion // ServiceProceduresAndFunctions