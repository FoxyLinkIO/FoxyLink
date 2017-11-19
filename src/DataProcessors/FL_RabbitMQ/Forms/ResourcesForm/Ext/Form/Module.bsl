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
// along with FoxyLink. If not, see <http://www.gnu.org/licenses/agpl-3.0>.
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
    
    If IsBlankString(PayloadEncoding) Then
        PayloadEncoding = "string";
    EndIf;
     
EndProcedure // OnCreateAtServer()

#EndRegion // FormEventHandlers

#Region FormCommandHandlers

&AtClient
Procedure SaveAndClose(Command)
        
    If IsBlankString(ExchangeName) Then
        FL_CommonUseClientServer.NotifyUser(NStr("
                |en = 'Field ''Exchange name'' must be filled.';
                |ru = 'Поле ''Имя обмена'' должно быть заполнено.'"), , 
            "ExchangeName");
        Return;    
    EndIf;
    
    If IsBlankString(RoutingKey) Then
        FL_CommonUseClientServer.NotifyUser(NStr("
                |en = 'Field ''Routing key'' must be filled.';
                |ru = 'Поле ''Ключ маршрутизации'' должно быть заполнено.'"), , 
            "RoutingKey");
        Return;  
    EndIf;
    
    If IsBlankString(VirtualHost) Then
        VirtualHost = "%2F";       
    EndIf;
    
    ResourceRow = Object.ChannelResources.Add();
    ResourceRow.FieldName = "Path";
    ResourceRow.FieldValue = "PublishToExchange";
    
    ResourceRow = Object.ChannelResources.Add();
    ResourceRow.FieldName = "VirtualHost";
    ResourceRow.FieldValue = VirtualHost;
    
    ResourceRow = Object.ChannelResources.Add();
    ResourceRow.FieldName = "ExchangeName";
    ResourceRow.FieldValue = ExchangeName;
    
    ResourceRow = Object.ChannelResources.Add();
    ResourceRow.FieldName = "RoutingKey";
    ResourceRow.FieldValue = RoutingKey;
    
    ResourceRow = Object.ChannelResources.Add();
    ResourceRow.FieldName = "ResourceAddress";
    ResourceRow.FieldValue = StrTemplate("/api/exchanges/%1/%2/publish", 
        VirtualHost, ExchangeName);
    
    ResourceRow = Object.ChannelResources.Add();
    ResourceRow.FieldName = "PayloadEncoding";
    ResourceRow.FieldValue = PayloadEncoding;
 
    Close(Object);
    
EndProcedure // SaveAndClose()

#EndRegion // FormCommandHandlers