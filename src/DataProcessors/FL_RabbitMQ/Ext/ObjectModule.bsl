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

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region ChannelDescription

// The name of the standard API used in this channel.
//
// Returns:
//  String - name of the standard API.
//
Function ChannelStandard() Export
    
    Return "AMPQ";
    
EndFunction // ChannelStandard()

// Returns the link to the description of the standard API that is used 
// in this channel.
//
// Returns:
//  String - the link to the description of the standard API.
//
Function ChannelStandardLink() Export
    
    Return "https://www.rabbitmq.com";
    
EndFunction // ChannelStandardLink()

// Returns short channel name.
//
// Returns:
//  String - channel short name.
// 
Function ChannelShortName() Export
    
    Return "RabbitMQ";    
    
EndFunction // ChannelShortName()

// Returns full channel name.
//
// Returns:
//  String - channel full name.
//
Function ChannelFullName() Export
    
    Return "RabbitMQ Messaging";    
    
EndFunction // ChannelFullName()

#EndRegion // ChannelDescription 

#Region ProgramInterface

// Invalidates the channel data. 
//
// Returns:
//  Boolean - if True channel was disconnected successfully.
//
Function Disconnect() Export
    
    Return True;
    
EndFunction // Disconnect() 

// Returns the boolean value whether preauthorization is required.
//
// Returns:
//  Boolean - if True preauthorization is required.
//
Function PreauthorizationRequired() Export
    
    Return True;
    
EndFunction // PreauthorizationRequired()

// Returns the boolean value whether resources are required.
//
// Returns:
//  Boolean - if True resources are required.
//
Function ResourcesRequired() Export
    
    Return True;
    
EndFunction // ResourcesRequired()

// Delivers a message to the current channel.
//
// Parameters:
//  Mediator        - Arbitrary - reserved, currently not in use.
//  Message         - Arbitrary - message to deliver.
//  QueryParameters - Structure - channel parameters.
//
// Returns:
//  Structure - message delivery result with values:
//      * Success          - Boolean   - shows whether delivery was successful.
//      * OriginalResponse - Arbitrary - original response object.
//      * StringResponse   - String    - string response presentation.
//
Function DeliverMessage(Mediator, Message, QueryParameters = Undefined) Export
    
    If TypeOf(QueryParameters) <> Type("Structure") Then
        ErrorMessage = StrTemplate(NStr(
                "en = 'Error: Failed to read parameter ''QueryParameters''. Expected type ''%1'' and received type is ''%2''.'.'; 
                |ru = 'Ошибка: Не удалось прочитать параметр ''QueryParameters''. Ожидался тип ''%1'', а получили тип ''%2''.'"),
            String(Type("Structure")),
            String(TypeOf(QueryParameters)));    
        Raise ErrorMessage;
    EndIf;

    
    If QueryParameters.Property("StringURI") = False Then
       
        SearchResult = ChannelData.Find("StringURI", "FieldName");
        If SearchResult <> Undefined Then
            QueryParameters.Insert("StringURI", 
                SearchResult.FieldValue);
        Else
            // Error    
        EndIf;
        
    EndIf;
    
    If QueryParameters.Property("HTTPMethod") = False Then
       
        SearchResult = ChannelResources.Find("HTTPMethod", "FieldName");
        If SearchResult <> Undefined Then
            QueryParameters.Insert(SearchResult.FieldName, 
                SearchResult.FieldValue);
        Else
            // Error    
        EndIf;
        
    EndIf;
    
    If QueryParameters.Property("Resource") = False Then
       
        SearchResult = ChannelResources.Find("Resource", "FieldName");
        If SearchResult <> Undefined Then
            QueryParameters.Insert(SearchResult.FieldName, 
                SearchResult.FieldValue);
        Else
            // Error    
        EndIf;
        
    EndIf;
        
    If QueryParameters.Property("Headers") = False Then
        QueryParameters.Insert("Headers", New Map);
        QueryParameters.Headers.Insert("Accept", "application/json"); 
        QueryParameters.Headers.Insert("Content-Type", "application/json");
    EndIf;
    
    If TypeOf(QueryParameters.Headers) <> Type("Map") Then
        ErrorMessage = StrTemplate(NStr(
                "en = 'Error: Failed to read parameter ''Headers''. Expected type ''%1'' and received type is ''%2''.';
                |ru = 'Ошибка: Не удалось прочитать параметр ''Headers''. Ожидался тип ''%1'', а получили тип ''%2''.'"),
            String(Type("Map")),
            String(TypeOf(QueryParameters.Headers)));
        Raise ErrorMessage;    
    EndIf;
    
    HTTPRequest = New HTTPRequest(QueryParameters.Resource);
    HTTPRequest.SetBodyFromString(Message);
    For Each Header In QueryParameters.Headers Do 
        HTTPRequest.Headers.Insert(Header.Key, Header.Value);
    EndDo;
    
    HTTPConnection = FL_InteriorUse.NewHTTPConnection(QueryParameters.StringURI);  
    HTTPResponse = HTTPConnection.CallHTTPMethod(QueryParameters.HTTPMethod, 
        HTTPRequest);
    
    DeliveryResponse = New Structure;
    If HTTPResponse.StatusCode = 200 AND HTTPResponse.GetBodyAsString() = "{""routed"": true}" Then
        DeliveryResponse.Insert("Success", HTTPResponse.StatusCode = 200);
    Else
        DeliveryResponse.Insert("Success", False);   
    EndIf;
    DeliveryResponse.Insert("OriginalResponse", HTTPResponse);
    DeliveryResponse.Insert("StringResponse", HTTPResponse.GetBodyAsString());  
    Return DeliveryResponse;
    
EndFunction // DeliverMessage() 

#EndRegion // ProgramInterface

#Region ServiceInterface

// Connects to RabbitMQ server.
// 
// Parameters:
//  StringURI   - String - reference to the resource in the format:
//    <schema>://<login>:<password>@<host>:<port>/<path>?<parameters>#<anchor>.
//  VirtualHost - String - provides logical grouping and separation of resources.
//  
Procedure ConnectToRabbitMQ(StringURI, Val VirtualHost) Export
    
    Var StatusCode, ResponseBody;
    
    If IsBlankString(VirtualHost) Then
        VirtualHost = "%2F";
    EndIf;
    
    FL_InteriorUse.CallHTTPMethod(
        FL_InteriorUse.NewHTTPConnection(StringURI),
        FL_InteriorUse.NewHTTPRequest(AlivenessTestURL(VirtualHost)),
        "GET",
        StatusCode,
        ResponseBody,
        LogAttribute);
        
    If AlivenessTestSucceeded(StatusCode, ResponseBody) Then   
        NewRow = ChannelData.Add();
        NewRow.FieldName = "StringURI";
        NewRow.FieldValue = StringURI;
    EndIf;
    
EndProcedure // ConnectToRabbitMQ() 

#EndRegion // ServiceInterface

#Region ServiceProceduresAndFunctions

#Region Exchanges

// Only for internal use.
//
Function ExchangesURL(VirtualHost = "")
    
    Return StrTemplate("/api/exchanges/%1", VirtualHost);
    
EndFunction // ExchangesURL()

// Only for internal use.
//
Function ExchangeNameURL(VirtualHost, Name)
    
    Return StrTemplate("/api/exchanges/%1/%2", VirtualHost, Name);
    
EndFunction // ExchangeNameURL()

// Only for internal use.
//
Function ExchangeNameBindingsSourceURL(VirtualHost, Name)
    
    Return StrTemplate("/api/exchanges/%1/%2/bindings/source", 
        VirtualHost, Name);
    
EndFunction // ExchangeNameBindingsSourceURL()

// Only for internal use.
//
Function ExchangeNameBindingsDestinationURL(VirtualHost, Name)
    
    Return StrTemplate("/api/exchanges/%1/%2/bindings/destination", 
        VirtualHost, Name);
    
EndFunction // ExchangeNameBindingsDestinationURL()

// Only for internal use.
//
Function ExchangeNamePublishURL(VirtualHost, Name)
    
    Return StrTemplate("/api/exchanges/%1/%2/publish", 
        VirtualHost, Name);        
    
EndFunction // ExchangeNamePublishURL()

#EndRegion // Exchanges    
    
#Region Aliveness

// Only for internal use.
//
Function AlivenessTestURL(VirtualHost)
    
    Return StrTemplate("/api/aliveness-test/%1", VirtualHost);    
    
EndFunction // AlivenessTestURL()

// Only for internal use.
//
Function AlivenessTestSucceeded(StatusCode, ResponseBody) 
    
    If StatusCode = 200 AND ResponseBody = "{""status"":""ok""}" Then
        Return True;
    EndIf;
    
    Return False;
    
EndFunction // AlivenessTestSucceeded()

#EndRegion // Aliveness 

#EndRegion // ServiceProceduresAndFunctions

#Region ExternalDataProcessorInfo

// Returns object version.
//
// Returns:
//  String - object version.
//
Function Version() Export
    
    Return "1.0.0.0";
    
EndFunction // Version()

// Returns base object description.
//
// Returns:
//  String - base object description.
//
Function BaseDescription() Export
    
    BaseDescription = NStr("en = 'RabbitMQ (%1) channel data processor, ver. %2'; 
        |ru = 'Обработчик канала RabbitMQ (%1), вер. %2'");
    BaseDescription = StrTemplate(BaseDescription, ChannelStandard(), Version());      
    Return BaseDescription;    
    
EndFunction // BaseDescription()

// Returns library guid which is used to identify different implementations 
// of specific channel.
//
// Returns:
//  String - library guid. 
//  
Function LibraryGuid() Export
    
    Return "bbd3b9ba-80ee-46e9-bd6d-a9f938557443";
    
EndFunction // LibraryGuid()

#EndRegion // ExternalDataProcessorInfo

#EndIf