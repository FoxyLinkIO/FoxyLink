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
    
    BinaryDataAddress = PutToTempStorage("", New UUID);
    NotifyDescription = New NotifyDescription("Attachable_OpenImportForm", 
        ThisObject, BinaryDataAddress);
        
    FileProperties = FL_InteriorUseClientServer.NewFileProperties();
    FileProperties.Extension = ".json";
    FileProperties.StorageAddress = BinaryDataAddress;
    FileProperties.Insert("NotifyDescription", NotifyDescription);
    
    FL_InteriorUseClient.Attachable_FileSystemExtension(New NotifyDescription(
        "Attachable_LoadFile", FL_InteriorUseClient, FileProperties));
       
EndProcedure // CommandProcessing()

// Processes the loaded file and opens ImportForm.
//
// Parameters:
//  Result               - Boolean   - the result value passed by the second 
//                                      parameter when the method was called. 
//  AdditionalParameters - Arbitrary - the value, which was specified when the 
//                                      notification object was created. 
//
&AtClient
Procedure Attachable_OpenImportForm(Result, AdditionalParameters) Export
    
    If Result AND IsTempStorageURL(AdditionalParameters) Then
        
        OpenForm("Catalog.FL_Exchanges.Form.ImportForm",
            New Structure("BinaryDataAddress", AdditionalParameters),
            ThisObject,
            ,
            ,
            ,
            ,
            FormWindowOpeningMode.LockOwnerWindow);
            
    EndIf;
    
EndProcedure // Attachable_OpenImportForm()

#EndRegion // CommandHandlers