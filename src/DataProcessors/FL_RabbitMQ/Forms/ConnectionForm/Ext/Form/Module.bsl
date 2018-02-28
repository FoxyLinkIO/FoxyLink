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
    
    Object.Log = True;
    
EndProcedure // OnCreateAtServer()

#EndRegion // FormEventHandlers

#Region FormCommandHandlers

&AtClient
Procedure ConnectToRabbitMQ(Command)
    
    If IsBlankString(ConnectionPath) Then
        
        FL_CommonUseClientServer.NotifyUser(NStr("en='Fill the connection path.';
                |ru='Заполните путь для подключения.';
                |uk='Заповніть шлях для підключення.';
                |en_CA='Fill the connection path.'"),
            ,
            "ConnectionPath");
        Return;
        
    EndIf;
    
    ConnectToRabbitMQAtServer();
    
    FilterParameters = New Structure("FieldName", "StringURI");
    FilterResult = Object.ChannelData.FindRows(FilterParameters);
    If FilterResult.Count() = 1 Then
        Close(Object); 
    Else
        Explanation = NStr("en='Failed to connect to RabbitMQ.';
            |ru='Не удалось подключиться к RabbitMQ.';
            |uk='Не вдалось підключитись до RabbitMQ.';
            |en_CA='Failed to connect to RabbitMQ.'");
        ShowUserNotification(Title, , Explanation, PictureLib.FL_Logotype64);   
    EndIf;
     
EndProcedure // ConnectToRabbitMQ() 

#EndRegion // FormCommandHandlers 

#Region ServiceProceduresAndFunctions

&AtServer
Procedure ConnectToRabbitMQAtServer()

    URIStructure = FL_CommonUseClientServer.URIStructure(ConnectionPath);
    URIStructure.Login = Login;
    URIStructure.Password = Password;
    
    If IsBlankString(VirtualHost) Then
        VirtualHost = "%2F";    
    EndIf;
    
    MainObject = FormAttributeToValue("Object");
    MainObject.ChannelData.Clear();
    
    NewRow = MainObject.ChannelData.Add();
    NewRow.FieldName = "StringURI";
    NewRow.FieldValue = FL_CommonUseClientServer.StringURI(URIStructure);
    
    DeliveryResult = MainObject.DeliverMessage(Undefined, New Structure(
        "Path, VirtualHost", "Aliveness", VirtualHost));
    
    LogAttribute = LogAttribute + DeliveryResult.LogAttribute;
    
    If DeliveryResult.Success 
        AND DeliveryResult.StringResponse = "{""status"":""ok""}" Then
        ValueToFormAttribute(MainObject.ChannelData, "Object.ChannelData");    
    EndIf;
        
EndProcedure // ConnectToRabbitMQAtServer()

#EndRegion // ServiceProceduresAndFunctions