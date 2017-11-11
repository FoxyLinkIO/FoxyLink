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

#Region ProgramInterface

// Identifies a plugin data processor name from library guid.
//
// Parameters:
//  LibraryGuid        - String - library guid which is used to identify 
//                         different implementations of a specific plugin.
//  PluggableSubsystem - String - plugable subsystem name.
//
// Returns:
//  String - the plugin data processor name.
//
Function IdentifyPluginProcessorName(LibraryGuid, PluggableSubsystem) Export
    
    Var DataProcessorName;
    
    PluggableSubsystem = FL_InteriorUse.PluggableSubsystem(PluggableSubsystem);
    For Each Item In PluggableSubsystem.Content Do
        
        If Metadata.DataProcessors.Contains(Item) Then
            
            Try
            
                DataProcessor = DataProcessors[Item.Name].Create();
                If Upper(DataProcessor.LibraryGuid()) = Upper(LibraryGuid) Then
                    DataProcessorName = Item.Name;
                    Break;
                EndIf;
            
            Except
                
                FL_CommonUseClientServer.NotifyUser(ErrorDescription());
                Continue;
                
            EndTry;
            
        EndIf;
        
    EndDo;
                    
    Return DataProcessorName;
    
EndFunction // IdentifyPluginProcessorName()

#EndRegion // ProgramInterface