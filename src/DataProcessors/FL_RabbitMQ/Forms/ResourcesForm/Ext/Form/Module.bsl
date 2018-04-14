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
    
    PropTimestamp = True;
    PropDeliveryMode = "non-persistent";
    
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
    
    If IsBlankString(PayloadEncoding) Then
        PayloadEncoding = "string";
    EndIf;
         
EndProcedure // OnCreateAtServer()

#EndRegion // FormEventHandlers

#Region FormCommandHandlers

&AtClient
Procedure SaveAndClose(Command)
            
    If IsBlankString(RoutingKey) Then
        FL_CommonUseClientServer.NotifyUser(NStr("
                |en='Field {Routing key} must be filled.';
                |ru='Поле {Ключ маршрутизации} должно быть заполнено.';
                |uk='Поле {Ключ маршрутизації} повинно бути заповненим.';
                |en_CA='Field {Routing key} must be filled.'"), , 
            "RoutingKey");
        Return;  
    EndIf;
    
    ResourceRow = Object.ChannelResources.Add();
    ResourceRow.FieldName = "Path";
    ResourceRow.FieldValue = "PublishToExchange";
    
    ResourceRow = Object.ChannelResources.Add();
    ResourceRow.FieldName = "Exchange";
    ResourceRow.FieldValue = Exchange;
    
    ResourceRow = Object.ChannelResources.Add();
    ResourceRow.FieldName = "VirtualHost";
    ResourceRow.FieldValue = VirtualHost;
    
    ResourceRow = Object.ChannelResources.Add();
    ResourceRow.FieldName = "RoutingKey";
    ResourceRow.FieldValue = RoutingKey;
     
    ResourceRow = Object.ChannelResources.Add();
    ResourceRow.FieldName = "PayloadEncoding";
    ResourceRow.FieldValue = PayloadEncoding;

    ResourceRow = Object.ChannelResources.Add();
    ResourceRow.FieldName = "PropDeliveryMode";
    ResourceRow.FieldValue = PropDeliveryMode;
    
    ResourceRow = Object.ChannelResources.Add();
    ResourceRow.FieldName = "PropExpiration";
    ResourceRow.FieldValue = PropExpiration;
    
    ResourceRow = Object.ChannelResources.Add();
    ResourceRow.FieldName = "PropPriority";
    ResourceRow.FieldValue = PropPriority;
    
    ResourceRow = Object.ChannelResources.Add();
    ResourceRow.FieldName = "PropType";
    ResourceRow.FieldValue = PropType;
    
    ResourceRow = Object.ChannelResources.Add();
    ResourceRow.FieldName = "PropUserId";
    ResourceRow.FieldValue = PropUserId;
    
    Close(Object);
    
EndProcedure // SaveAndClose()

#EndRegion // FormCommandHandlers