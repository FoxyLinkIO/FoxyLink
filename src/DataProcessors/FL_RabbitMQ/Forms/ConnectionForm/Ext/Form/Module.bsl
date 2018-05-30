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

    V8Loader = False;
    V8Publisher = False;
    
    Templates = Metadata.DataProcessors.FL_RabbitMQ.Templates;
    For Each Template In Templates Do
        
        If Upper(Template.Name) = Upper("V8Loader") Then
            V8Loader = True;
        ElsIf Upper(Template.Name) = Upper("V8Publisher") Then
            V8Publisher = True;    
        EndIf;
        
    EndDo;
    
    Items.UseAMQPNET.ReadOnly = NOT (V8Loader AND V8Publisher);    
    
EndProcedure // OnCreateAtServer()

#EndRegion // FormEventHandlers

#Region FormItemsEventHandlers

&AtClient
Procedure UseHTTPOnChange(Item)
    
    Items.GroupConnectionPath.Visible = UseManagementHTTPAPI;
    
EndProcedure // UseHTTPOnChange()

&AtClient
Procedure UseAMQPNETOnChange(Item)
    
    Items.GroupConnectionPathAMQPNET.Visible = UseAMQPNET;
    
EndProcedure // UseAMQPNETOnChange()

#EndRegion // FormItemsEventHandlers

#Region FormCommandHandlers

&AtClient
Procedure ConnectToRabbitMQ(Command)
    
    If UseManagementHTTPAPI AND NOT ConnectionPathIsFilled("ConnectionPath") Then
        Return;         
    EndIf;
    
    If UseAMQPNET AND NOT ConnectionPathIsFilled("AMQPConnectionPath") Then
        Return;         
    EndIf;
        
    ConnectToRabbitMQAtServer();
    
    ManagementHTTPSuccess = True;
    If UseManagementHTTPAPI Then
        FilterParameters = New Structure("FieldName", "StringURI");
        FilterResult = Object.ChannelData.FindRows(FilterParameters);
        ManagementHTTPSuccess = FilterResult.Count() = 1;
    EndIf;
    
    AMQPNETSuccess = True;
    If UseAMQPNET Then
        FilterParameters = New Structure("FieldName", "AMQPURI");
        FilterResult = Object.ChannelData.FindRows(FilterParameters);
        AMQPNETSuccess = FilterResult.Count() = 1;
    EndIf;
    
    If ManagementHTTPSuccess AND AMQPNETSuccess Then
        Close(Object); 
    Else
        Explanation = NStr("
            |en='Failed to connect to RabbitMQ.';
            |ru='Не удалось подключиться к RabbitMQ.';
            |uk='Не вдалось підключитись до RabbitMQ.';
            |en_CA='Failed to connect to RabbitMQ.'");
        ShowUserNotification(Title, , Explanation, PictureLib.FL_Logotype64);   
    EndIf;
     
EndProcedure // ConnectToRabbitMQ() 

#EndRegion // FormCommandHandlers 

#Region ServiceProceduresAndFunctions

&AtClient
Function ConnectionPathIsFilled(FieldName)
                 
    If IsBlankString(ThisObject[FieldName]) Then
    
        FL_CommonUseClientServer.NotifyUser(NStr("
                |en='Fill the connection path.';
                |ru='Заполните путь для подключения.';
                |uk='Заповніть шлях для підключення.';
                |en_CA='Fill the connection path.'"),
            ,
            FieldName);
            
        Return False;
        
    EndIf;
    
    Return True;
    
EndFunction // ConnectionPathIsFilled()

&AtServer
Procedure ConnectToRabbitMQAtServer()

    MainObject = FormAttributeToValue("Object");
    MainObject.ChannelData.Clear();
    MainObject.ChannelResources.Clear();

    If UseManagementHTTPAPI Then 
        
        URIStructure = FL_CommonUseClientServer.URIStructure(ConnectionPath);
        URIStructure.Login = Login;
        URIStructure.Password = Password;
        
        If IsBlankString(VirtualHost) Then
            VirtualHost = "%2F";    
        EndIf;
        
        FL_EncryptionClientServer.AddFieldValue(MainObject.ChannelData, 
            "StringURI", FL_CommonUseClientServer.StringURI(URIStructure));
        FL_EncryptionClientServer.AddFieldValue(MainObject.ChannelResources, 
            "VirtualHost", VirtualHost);    
        
    EndIf;
    
    If UseAMQPNET Then
        FL_EncryptionClientServer.AddFieldValue(MainObject.ChannelData, 
            "AMQPURI", AMQPConnectionPath);
    EndIf;
    
    FL_EncryptionClientServer.AddFieldValue(MainObject.ChannelResources, 
        "Path", "Aliveness");
        
    JobResult = Catalogs.FL_Jobs.NewJobResult();
    MainObject.DeliverMessage(Undefined, Undefined, JobResult);
    
    LogAttribute = LogAttribute + JobResult.LogAttribute;
    
    If JobResult.Success Then
        ValueToFormAttribute(MainObject.ChannelData, "Object.ChannelData");
    EndIf;
        
EndProcedure // ConnectToRabbitMQAtServer()

#EndRegion // ServiceProceduresAndFunctions