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
//  Mediator   - Arbitrary - reserved, currently not in use.
//  Message    - Arbitrary - message to deliver.
//  Parameters - Structure - channel parameters.
//
// Returns:
//  Structure - message delivery result with values:
//      * Success          - Boolean   - shows whether delivery was successful.
//      * OriginalResponse - Arbitrary - original response object.
//      * StringResponse   - String    - string response presentation.
//
Function DeliverMessage(Mediator, Message, Parameters = Undefined) Export
    
    Var HTTPMethod, HTTPRequest;
    
    DeliveryResult = New Structure;
    DeliveryResult.Insert("Success");
    DeliveryResult.Insert("StatusCode");
    DeliveryResult.Insert("StringResponse");
    DeliveryResult.Insert("OriginalResponse");
    
    If TypeOf(Parameters) <> Type("Structure") Then   
        Raise FL_ErrorsClientServer.ErrorTypeIsDifferentFromExpected(
            "Parameters", Parameters, Type("Structure"));
    EndIf;

    If Parameters.Property("PredefinedAPI") Then
        ResolvePredefined(Parameters.PredefinedAPI, HTTPMethod, HTTPRequest);
    EndIf;
       
    If Log Then
        
        DeliveryResult.OriginalResponse = FL_InteriorUse.CallHTTPMethod(
            NewHTTPConnection(), 
            HTTPRequest, 
            HTTPMethod, 
            DeliveryResult.StatusCode, 
            DeliveryResult.StringResponse, 
            LogAttribute);
            
    Else
        
        DeliveryResult.OriginalResponse = FL_InteriorUse.CallHTTPMethod(
            NewHTTPConnection(), 
            HTTPRequest, 
            HTTPMethod, 
            DeliveryResult.StatusCode, 
            DeliveryResult.StringResponse);
            
    EndIf;
    
    DeliveryResult.Success = FL_InteriorUseReUse.IsSuccessHTTPStatusCode(
        DeliveryResult.StatusCode);
    Return DeliveryResult;
    
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
        NewHTTPConnection(StringURI),
        AlivenessHTTPRequest(VirtualHost),
        "GET",
        StatusCode,
        ResponseBody,
        ?(Log, LogAttribute, Undefined));
        
    If AlivenessTestSucceeded(StatusCode, ResponseBody) Then   
        NewRow = ChannelData.Add();
        NewRow.FieldName = "StringURI";
        NewRow.FieldValue = StringURI;
    EndIf;
    
EndProcedure // ConnectToRabbitMQ() 

// Converts a JSON string into Map or Array object.
//
// Parameters:
//  ResponseBody - String - JSON string to be converted.  
//
// Returns:
//  Map, Array - converted object.
//
Function ConvertResponseToMap(ResponseBody) Export
    
    JSONReader = New JSONReader;
    JSONReader.SetString(ResponseBody);
    Response = ReadJSON(JSONReader, True);
    JSONReader.Close();
    Return Response; 
    
EndFunction // ConvertResponseToMap()

#EndRegion // ServiceInterface

#Region ServiceProceduresAndFunctions

#Region Overview

// Only for internal use.
//
Function OverviewHTTPRequest()
    
    Return FL_InteriorUse.NewHTTPRequest("/api/overview", 
        NewHTTPRequestHeaders());
     
EndFunction // OverviewHTTPRequest()

#EndRegion // Overview

#Region Connections

// Only for internal use.
//
Function ConnectionsHTTPRequest()
    
    Return FL_InteriorUse.NewHTTPRequest("/api/connections", 
        NewHTTPRequestHeaders());
     
EndFunction // OverviewHTTPRequest()
    
#EndRegion // Connections 

#Region Channels

// Only for internal use.
//
Function ChannelsHTTPRequest()
    
    Return FL_InteriorUse.NewHTTPRequest("/api/channels", 
        NewHTTPRequestHeaders());
     
EndFunction // ChannelsHTTPRequest()

#EndRegion // Channels

#Region Exchanges

// Only for internal use.
//
Function ExchangesHTTPRequest()
    
    Return FL_InteriorUse.NewHTTPRequest("/api/exchanges", 
        NewHTTPRequestHeaders());
    
EndFunction // ExchangesHTTPRequest()

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

#Region Queues

// Only for internal use.
//
Function QueuesHTTPRequest()
    
    Return FL_InteriorUse.NewHTTPRequest("/api/queues", 
        NewHTTPRequestHeaders());
    
EndFunction // ExchangesHTTPRequest()

#EndRegion // Queues

#Region Aliveness

// Only for internal use.
//
Function AlivenessHTTPRequest(VirtualHost)
    
    Return FL_InteriorUse.NewHTTPRequest(StrTemplate("/api/aliveness-test/%1", 
            VirtualHost), 
        NewHTTPRequestHeaders());
    
EndFunction // AlivenessHTTPRequest()

// Only for internal use.
//
Function AlivenessTestSucceeded(StatusCode, ResponseBody) 
    
    Return FL_InteriorUseReUse.IsSuccessHTTPStatusCode(StatusCode) 
        AND ResponseBody = "{""status"":""ok""}";
    
EndFunction // AlivenessTestSucceeded()

#EndRegion // Aliveness 

// Only for internal use.
//
Procedure ResolvePredefined(Path, HTTPMethod, HTTPRequest, Message = Undefined)
    
    If Path = "Overview" Then
        HTTPMethod = "GET";
        HTTPRequest = OverviewHTTPRequest();
    ElsIf Path = "Connections" Then
        HTTPMethod = "GET";
        HTTPRequest = ConnectionsHTTPRequest();
    ElsIf Path = "Channels" Then
        HTTPMethod = "GET";
        HTTPRequest = ChannelsHTTPRequest();
    ElsIf Path = "Exchanges" Then
        HTTPMethod = "GET";
        HTTPRequest = ExchangesHTTPRequest();
    ElsIf Path = "Queues" Then
        HTTPMethod = "GET";
        HTTPRequest = QueuesHTTPRequest();
    EndIf;    
    
EndProcedure // ResolvePredefined()

// Only for internal use.
//
Function NewHTTPConnection(Val StringURI = "")
    
    If IsBlankString(StringURI) Then
        
        SearchResult = ChannelData.Find("StringURI", "FieldName");
        If SearchResult <> Undefined Then
            StringURI = SearchResult.FieldValue;
        EndIf;
        
    EndIf;
    
    Return FL_InteriorUse.NewHTTPConnection(StringURI);
    
EndFunction // NewHTTPConnection()

// Only for internal use.
//
Function NewHTTPRequestHeaders()
    
    Headers = New Map;
    Headers.Insert("Accept", "application/json"); 
    Headers.Insert("Content-Type", "application/json");
    Return Headers;
    
EndFunction // NewHTTPRequestHeaders()

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