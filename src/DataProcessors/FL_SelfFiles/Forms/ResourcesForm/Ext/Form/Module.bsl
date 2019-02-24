////////////////////////////////////////////////////////////////////////////////
// This file is part of FoxyLink.
// Copyright © 2016-2019 Petro Bazeliuk.
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
    FL_InteriorUse.FillAppEndpointResourcesFormData(ThisObject, Parameters);
    
    If IsBlankString(ZipCompressionMethod) Then
        ZipCompressionMethod = "Deflate";
    EndIf;
    
    If IsBlankString(ZipCompressionLevel) Then
        ZipCompressionLevel = "Optimal";
    EndIf;
    
    If IsBlankString(ZipEncryptionMethod) Then
        ZipEncryptionMethod = "Zip20";
    EndIf;
    
EndProcedure // OnCreateAtServer()

&AtClient
Procedure OnOpen(Cancel)
    
    AddTimestampOnChange(Items.AddTimestamp);
    CompressOutputOnChange(Items.CompressOutput);
    
EndProcedure // OnOpen()

#EndRegion // FormEventHandlers

#Region FormItemsEventHandlers

&AtClient
Procedure AddTimestampOnChange(Item)
    
    Items.GroupFormatString.Visible = AddTimestamp; 
    
EndProcedure // AddTimestampOnChange()

&AtClient
Procedure CompressOutputOnChange(Item)
    
    Items.GroupZipSettings.Visible = CompressOutput;        
    
EndProcedure // CompressOutputOnChange()

#EndRegion // FormItemsEventHandlers

#Region FormCommandHandlers

&AtClient
Procedure SaveAndClose(Command)
        
    If IsBlankString(Path) Then
        FL_CommonUseClientServer.NotifyUser(
            NStr("en='Field {Path} must be filled.';
                |ru='Поле {Путь} должно быть заполнено.';
                |uk='Поле {Шлях} повинно бути заповненим.';
                |en_CA='Field {Path} must be filled.'"), , 
            "Path");
        Return;    
    EndIf;
        
    FL_EncryptionClientServer.SetFieldValue(Object.ChannelResources, "Path", 
        Path);
    
    If ValueIsFilled(BaseName) Then    
        FL_EncryptionClientServer.SetFieldValue(Object.ChannelResources, 
            "BaseName", BaseName);
    EndIf;
    
    FL_EncryptionClientServer.SetFieldValue(Object.ChannelResources, 
        "AddTimestamp", AddTimestamp);
    FL_EncryptionClientServer.SetFieldValue(Object.ChannelResources, 
        "FormatString", FormatString);
    
    FL_EncryptionClientServer.SetFieldValue(Object.ChannelResources, 
        "CompressOutput", CompressOutput);
    FL_EncryptionClientServer.SetFieldValue(Object.ChannelResources, 
        "ZipPassword", ZipPassword);
    FL_EncryptionClientServer.SetFieldValue(Object.ChannelResources, 
        "ZipCommentaries", ZipCommentaries);
    FL_EncryptionClientServer.SetFieldValue(Object.ChannelResources, 
        "ZipCompressionMethod", ZipCompressionMethod);
    FL_EncryptionClientServer.SetFieldValue(Object.ChannelResources, 
        "ZipCompressionLevel", ZipCompressionLevel);
    FL_EncryptionClientServer.SetFieldValue(Object.ChannelResources, 
        "ZipEncryptionMethod", ZipEncryptionMethod);
    
    If ValueIsFilled(Extension) Then
        FL_EncryptionClientServer.SetFieldValue(Object.ChannelResources, 
            "Extension", Extension);
    EndIf;
            
    Close(Object);
    
EndProcedure // SaveAndClose()

#EndRegion // FormCommandHandlers