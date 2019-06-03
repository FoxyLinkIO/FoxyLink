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

#Region FormCommandHandlers

&AtClient
Procedure ConnectToCorezoid(Command)
    
    If IsBlankString(ConnectionPath) Then
        
        FL_CommonUseClientServer.NotifyUser(
            NStr("en='Fill the connection path.';
                |ru='Заполните путь для подключения.';
                |uk='Заповніть шлях для підключення.';
                |en_CA='Fill the connection path.'"),
            ,
            "ConnectionPath");
        Return;
        
    EndIf;
    
    ConnectToCorezoidAtServer();
    
    FilterParameters = New Structure("FieldName", "StringURI");
    FilterResult = Object.ChannelData.FindRows(FilterParameters);
    If FilterResult.Count() = 1 Then
        Close(Object);
    Else
        FL_CommonUseClientServer.NotifyUser(
            NStr("en='Failed to connect.';
                |ru='Не удалось подключиться.';
                |uk='Не вдалось підключитись.';
                |en_CA='Failed to connect.'"));    
    EndIf;
     
EndProcedure // ConnectToCorezoid() 

#EndRegion // FormCommandHandlers 

#Region ServiceProceduresAndFunctions

&AtServer
Procedure ConnectToCorezoidAtServer()

    URIStructure = FL_CommonUseClientServer.URIStructure(ConnectionPath);
    URIStructure.Login = Login;
    URIStructure.Password = Password;
    
    MainObject = FormAttributeToValue("Object");
    MainObject.ChannelData.Clear();
    MainObject.ChannelResources.Clear();
    
    FL_EncryptionClientServer.AddFieldValue(MainObject.ChannelData, 
        "StringURI", FL_CommonUseClientServer.StringURI(URIStructure));
    FL_EncryptionClientServer.AddFieldValue(MainObject.ChannelResources, 
        "HTTPMethod", "GET");
    FL_EncryptionClientServer.AddFieldValue(MainObject.ChannelResources, 
        "Resource", "");
    
    JobResult = Catalogs.FL_Jobs.NewJobResult(True);
    MainObject.DeliverMessage(Undefined, Undefined, JobResult);
    
    LogAttribute = JobResult.LogAttribute;
    If JobResult.Success Then     
        ValueToFormAttribute(MainObject.ChannelData, "Object.ChannelData");
    EndIf;
    
EndProcedure // ConnectToCorezoidAtServer()

#EndRegion // ServiceProceduresAndFunctions