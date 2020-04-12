////////////////////////////////////////////////////////////////////////////////
// This file is part of FoxyLink.
// Copyright © 2016-2020 Petro Bazeliuk.
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

// Returns app identifier for this database.
//
// Returns:
//  String - app identifier for this database.
//
Function AppIdentifier() Export
    
    SetPrivilegedMode(True);
    Return Constants.FL_AppIdentifier.Get();
    
EndFunction // AppIdentifier() 

// Returns day in milliseconds.
//
// Returns:
//  Number - day in milliseconds.
//
Function DayInMilliseconds() Export
    
    Return 86400000;
    
EndFunction // DayInMilliseconds()

// Returns job expiration timeout.
//
// Returns:
//  Number - job expiration timeout.
//
Function JobExpirationTimeout() Export
    
    SetPrivilegedMode(True);
    Return Constants.FL_JobExpirationTimeout.Get();
    
EndFunction // JobExpirationTimeout()

// Returns maximum message size.
//
// Returns:
//  Number - maximum message size in bytes.
//
Function MaximumMessageSize() Export
    
    SetPrivilegedMode(True);
    Return Constants.FL_MaximumMessageSize.Get();
    
EndFunction // MaximumMessageSize() 

// Function is intended for initiating session parameters of the FoxyLink 
// subsystem.
//
// Returns:
//  Boolean - always True.
// 
Function SetSessionParameters() Export
    
    SetPrivilegedMode(True);
    SessionParameters.FL_CanceledBackgroundJobs = New FixedArray(New Array);
    SetPrivilegedMode(False);
    
    Return True;
    
EndFunction // SetSessionParameters()

#Region SubsystemInteraction

// Returns available events handlers for an operation.
//
// Parameters:
//  Operation      - CatalogRef.FL_Operations - the operation reference.
//  MetadataObject - String                   - the event metadata object.
//
// Returns:
//  FixedArray - array of available events handlers.
//               See function FL_InteriorUse.NewExternalEventHandlerInfo. 
//
Function AvailableEventHandlers(Operation, Val MetadataObject = Undefined) Export
    
    ObjectTypeName = Undefined;
    
    If ValueIsFilled(MetadataObject) Then
        MetadataObject = Upper(MetadataObject);
        ObjectTypeName = Left(MetadataObject, StrFind(MetadataObject, ".")) + "*";
    EndIf;
    
    PublishersArray = New Array;
    PluggableHandlers = FL_InteriorUse.PluggableSubsystem("EventHandlers");
    For Each Item In PluggableHandlers.Content Do
        
        Try
            
            FullName = Item.FullName();
            CommonModule = FL_CommonUse.CommonModule(FullName); 
            
            EventHandlerInfo = CommonModule.EventHandlerInfo();
            EventSources = EventHandlerInfo.Publishers.Get(Operation);
            
            If TypeOf(EventSources) = Type("FixedArray") Then
                
                If NOT ValueIsFilled(MetadataObject) 
                    OR EventSources.Find(MetadataObject) <> Undefined 
                    OR EventSources.Find(ObjectTypeName) <> Undefined Then
                    
                    PublishersArray.Add(EventHandlerInfo);
                    
                EndIf;
                
            EndIf;
            
        Except
            
            FL_CommonUseClientServer.NotifyUser(ErrorDescription());
            
        EndTry;
            
    EndDo;
    
    Return New FixedArray(PublishersArray);
    
EndFunction // AvailableEventHandlers()

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

#EndRegion // SubsystemInteraction

// Returns ok status code.
//
// Returns:
//  Number - ok status code. 
//
Function OkStatusCode() Export
    
    Return 200;
    
EndFunction // OkStatusCode()

// Returns internal server error status code.
//
// Returns:
//  Number - internal server error status code. 
//
Function InternalServerErrorStatusCode() Export
    
    Return 500;
    
EndFunction // InternalServerErrorStatusCode()

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