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

// Defines if HTTP method has no body.
//
// Parameters:
//  HTTPMethod - String - HTTP method name.  
//
// Returns:
//  Boolean - if True HTTP method has no body, False in opposite case.
//
Function IsHTTPMethodWithoutBody(HTTPMethod) Export
    
    HTTPMethods = New Structure;
    HTTPMethods.Insert("GET");
    HTTPMethods.Insert("HEAD");
    HTTPMethods.Insert("TRACE");
    HTTPMethods.Insert("DELETE");
    HTTPMethods.Insert("CONNECT");
    HTTPMethods.Insert("MKCOL");
    HTTPMethods.Insert("COPY");
    HTTPMethods.Insert("MOVE");
    HTTPMethods.Insert("UNLOCK");
    HTTPMethods.Insert("OPTIONS");
    Return HTTPMethods.Property(HTTPMethod);
    
EndFunction // IsHTTPMethodWithoutBody()
 
// Returns HTTP success status codes 2xx.
//
// Returns:
//  FixedMap - with HTTP success status codes:
//      * Key   - Number - HTTP server status (response) code.
//      * Value - String - string representation of status code.
//
Function SuccessHTTPStatusCodes() Export
    
    Map = New Map;
    Map.Insert(200, "200 OK");
    Map.Insert(201, "201 Created");
    Map.Insert(202, "202 Accepted");
    Map.Insert(203, "203 Non-Authoritative Information");
    Map.Insert(204, "204 No Content");
    Map.Insert(205, "205 Reset Content");
    Map.Insert(206, "206 Partial Content");
    Map.Insert(207, "207 Multi-Status");
    Map.Insert(208, "208 Already Reported");
    Map.Insert(226, "226 IM Used");
    Return New FixedMap(Map);
    
EndFunction // SuccessHTTPStatusCodes()

// Defines if it is success status code.
//
// Parameters:
//  StatusCode - Number - HTTP server status (response) code.
//
// Returns:
//  Boolean - if True it is success status code.  
//
Function IsSuccessHTTPStatusCode(StatusCode) Export
    
    Return FL_InteriorUseReUse.SuccessHTTPStatusCodes().Get(StatusCode) <> Undefined;
    
EndFunction // IsSuccessHTTPStatusCode() 

#EndRegion // ProgramInterface