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
    
    If Parameters.Property("AutoTest") Then
        Return;
    EndIf;
    
    Parameters.Property("Channel", Channel);
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

#Region FormCommandHandlers

&AtClient
Procedure SaveAndClose(Command)
        
    If IsBlankString(FileName) Then
        FL_CommonUseClientServer.NotifyUser(NStr("
                |en='Field {File name} must be filled.';
                |ru='Поле {Имя файла} должно быть заполнено.';
                |en_CA='Field {File name} must be filled.'"), , 
            "FileName");
        Return;    
    EndIf;
    
    ResourceRow = Object.ChannelResources.Add();
    ResourceRow.FieldName = "FileName";
    ResourceRow.FieldValue = FileName;
        
    Close(Object);
    
EndProcedure // SaveAndClose()

#EndRegion // FormCommandHandlers