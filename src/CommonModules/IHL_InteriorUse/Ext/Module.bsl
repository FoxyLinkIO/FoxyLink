////////////////////////////////////////////////////////////////////////////////
// This file is part of IHL (Integration happiness library).
// Copyright © 2016-2017 Petro Bazeliuk.
// 
// IHL is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as 
// published by the Free Software Foundation, either version 3 
// of the License, or any later version.
// 
// IHL is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public 
// License along with IHL. If not, see <http://www.gnu.org/licenses/>.
//
////////////////////////////////////////////////////////////////////////////////

#Region ProgramInterface

// Returns metadata object: plugable formats subsystem.
//
// Returns:
//  MetadataObject: Subsystem - plugable formats subsystem.  
//
Function PlugableFormatsSubsystem() Export
    
    MainSubsystem = Metadata.Subsystems.Find("IHL");
    If MainSubsystem = Undefined Then
        
        ErrorMessage = NStr(
            "en = 'Failed to find main subsystem [IHL].';
            |ru = 'Не удалось найти основную подсистему [IHL].'");
        Raise ErrorMessage;
        
    EndIf;
    
    PluginsSubsystem = MainSubsystem.Subsystems.Find("Plugins");
    If PluginsSubsystem = Undefined Then
        
        ErrorMessage = NStr(
            "en = 'Failed to find [IHL -> Plugins] subsystem.';
            |ru = 'Не удалось найти подсистему [IHL -> Plugins].'");
        Raise ErrorMessage;
        
    EndIf;
    
    PlugableFormats = PluginsSubsystem.Subsystems.Find("PlugableFormats");
    If PlugableFormats = Undefined Then
        
        ErrorMessage = NStr(
            "en = 'Failed to find [IHL -> Plugins -> PlugableFormats] subsystem.';
            |ru = 'Не удалось найти подсистему [IHL -> Plugins -> PlugableFormats].'");
        Raise ErrorMessage;
        
    EndIf;
    
    Return PlugableFormats;
    
EndFunction // PlugableFormatsSubsystem() 

#EndRegion // ProgramInterface