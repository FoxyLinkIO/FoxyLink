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

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region ProgramInterface

// Returns available plugable formats.
//
// Returns:
//  ValueList - with values:
//      * Value - String - format library guid.
//
Function AvailableFormats() Export
    
    ValueList = New ValueList;

    PlugableFormats = IHL_InteriorUse.PlugableFormatsSubsystem(); 
    For Each Item In PlugableFormats.Content Do
        
        If Metadata.DataProcessors.Contains(Item) Then
            
            Try
            
                DataProcessor = DataProcessors[Item.Name].Create();                
                ValueList.Add(DataProcessor.LibraryGuid(),
                    StrTemplate("%1 (%2), ver. %3", 
                        DataProcessor.FormatShortName(),
                        DataProcessor.FormatStandard(),
                        DataProcessor.Version()));
            
            Except
                
                IHL_CommonUseClientServer.NotifyUser(ErrorDescription());
                Continue;
                
            EndTry;
            
        EndIf;
        
    EndDo;
    
    Return ValueList;
    
EndFunction // AvailableFormats()

// Returns new format data processor for every server call.
//
// Parameters:
//  FormatProcessorName - String - name of the object type depends on the data 
//                                 processor name in the configuration.
//  LibraryGuid         - String - library guid which is used to identify 
//                                 different implementations of specific format.
//
// Returns:
//  DataProcessorObject.<Data processor name> - format data processor.
//
Function NewFormatProcessor(FormatProcessorName, Val LibraryGuid) Export
    
    If IsBlankString(FormatProcessorName) Then
        
        PlugableFormats = IHL_InteriorUse.PlugableFormatsSubsystem();
        For Each Item In PlugableFormats.Content Do
            
            If Metadata.DataProcessors.Contains(Item) Then
                
                Try
                
                    FormatProcessor = DataProcessors[Item.Name].Create();
                    If FormatProcessor.LibraryGuid() = LibraryGuid Then
                        FormatProcessorName = Item.Name;
                        Break;
                    EndIf;
                
                Except
                    
                    IHL_CommonUseClientServer.NotifyUser(ErrorDescription());
                    Continue;
                    
                EndTry;
                
            EndIf;
            
        EndDo;
        
    Else
        
        FormatProcessor = DataProcessors[FormatProcessorName].Create();
        
    EndIf;
    
    Return FormatProcessor;
    
EndFunction // NewFormatProcessor()

#EndRegion // ProgramInterface
       
#EndIf