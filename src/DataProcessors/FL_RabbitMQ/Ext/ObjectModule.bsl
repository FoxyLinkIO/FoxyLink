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

// Delivers a data object to the RabbitMQ application.
//
// Parameters:
//  Payload    - Arbitrary - the data that can be read successively and 
//                               delivered to RabbitMQ.
//  Properties - Structure - RabbitMQ resources and message parameters.
//  JobResult  - Structure - see function Catalogs.FL_Jobs.NewJobResult.
//
Procedure DeliverMessage(Payload, Properties, JobResult) Export
    
    Path = FL_EncryptionClientServer.FieldValueNoException(ChannelResources, 
        "Path");
    
    HTTPMethod = "GET";
    If Path = "PublishToExchange" OR Path = Undefined Then
        
        HTTPMethod = "POST";
        HTTPRequest = ExchangePublish(NewPublishToExchangePayload(Payload, 
            Properties));
            
    ElsIf Path = "Overview" Then
        HTTPRequest = Overview();
    ElsIf Path = "Connections" Then
        HTTPRequest = Connections();
    ElsIf Path = "Channels" Then
        HTTPRequest = Channels();
    ElsIf Path = "Exchanges" Then
        HTTPRequest = Exchanges();
    ElsIf Path = "Queues" Then
        HTTPRequest = Queues();
    ElsIf Path = "Aliveness" Then
        HTTPRequest = Aliveness();
    EndIf;
        
    If Log Then
        JobResult.LogAttribute = "";     
    EndIf;
    
    FL_InteriorUse.CallHTTPMethod(NewHTTPConnection(), HTTPRequest, HTTPMethod, 
        JobResult);
            
EndProcedure // DeliverMessage() 

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

// Returns array of supplied integrations for this configuration.
//
// Returns:
//  Array - array filled by supplied integrations.
//      * ArrayItem - Structure - see function FL_InteriorUse.NewPluggableSettings.
//
Function SuppliedIntegrations() Export
    
    SuppliedIntegrations = New Array;    
    Return SuppliedIntegrations;
          
EndFunction // SuppliedIntegration()

#EndRegion // ProgramInterface

#Region ServiceInterface

// Converts a JSON stream into Map or Array object.
//
// Parameters:
//  Stream - Stream - JSON stream to be read and converted.  
//
// Returns:
//  Map, Array - converted object.
//
Function ConvertResponseToMap(Stream) Export
    
    JSONReader = New JSONReader;
    JSONReader.OpenStream(Stream);
    Response = ReadJSON(JSONReader, True);
    JSONReader.Close();
    Return Response; 
    
EndFunction // ConvertResponseToMap()

#EndRegion // ServiceInterface

#Region ServiceProceduresAndFunctions

#Region Overview

// Only for internal use.
//
Function Overview()
    
    Return FL_InteriorUse.NewHTTPRequest("/api/overview", 
        NewHTTPRequestHeaders());
     
EndFunction // Overview()

#EndRegion // Overview

#Region Connections

// Only for internal use.
//
Function Connections()
    
    Return FL_InteriorUse.NewHTTPRequest("/api/connections", 
        NewHTTPRequestHeaders());
     
EndFunction // Connections()
    
#EndRegion // Connections 

#Region Channels

// Only for internal use.
//
Function Channels()
    
    Return FL_InteriorUse.NewHTTPRequest("/api/channels", 
        NewHTTPRequestHeaders());
     
EndFunction // Channels()

#EndRegion // Channels

#Region Exchanges

// Only for internal use.
//
Procedure ProcessMessageProperties(JSONWriter, Properties)
    
    // Properties
    JSONWriter.WritePropertyName("properties");
    JSONWriter.WriteStartObject();
    
        // Identifier of the application that produced the message. 
        JSONWriter.WritePropertyName("app_id");
        JSONWriter.WriteValue(Properties.AppId);
        
        // Non-persistent (1) or persistent (2).
        PropDeliveryMode = FL_EncryptionClientServer.FieldValueNoException(
            ChannelResources, "PropDeliveryMode");
        If ValueIsFilled(PropDeliveryMode) Then    
            JSONWriter.WritePropertyName("delivery_mode");
            JSONWriter.WriteValue(?(PropDeliveryMode = "non-persistent", 1, 2));
        EndIf;

        // MIME content type. 
        JSONWriter.WritePropertyName("content_type");
        JSONWriter.WriteValue(Properties.ContentType);
    
        // MIME content encoding. 
        JSONWriter.WritePropertyName("content_encoding");
        JSONWriter.WriteValue(Properties.ContentEncoding);
        
        // Message correlated to this one, e.g. what request this message is a reply to. 
        If ValueIsFilled(Properties.CorrelationId) Then
            JSONWriter.WritePropertyName("correlation_id");
            JSONWriter.WriteValue(Properties.CorrelationId);
        EndIf;
        
        // Expiration time after which the message will be deleted.
        PropExpiration = FL_EncryptionClientServer.FieldValueNoException(
            ChannelResources, "PropExpiration");
        If ValueIsFilled(PropExpiration) Then
            JSONWriter.WritePropertyName("expiration");
            JSONWriter.WriteValue(PropExpiration);
        EndIf;
        
        // Application message identifier.
        JSONWriter.WritePropertyName("message_id");
        JSONWriter.WriteValue(Properties.MessageId);
        
        // Message priority.
        PropPriority = FL_EncryptionClientServer.FieldValueNoException(
            ChannelResources, "PropPriority");
        If ValueIsFilled(PropPriority) Then
            JSONWriter.WritePropertyName("priority");
            JSONWriter.WriteValue(Number(PropPriority));
        EndIf;
        
        // Message type.
        PropType = FL_EncryptionClientServer.FieldValueNoException(
            ChannelResources, "PropType");
        If ValueIsFilled(PropType) Then
            JSONWriter.WritePropertyName("type");
            JSONWriter.WriteValue(PropType);
        EndIf;
    
        // Message timestamp.
        JSONWriter.WritePropertyName("timestamp");
        JSONWriter.WriteValue(Properties.Timestamp);
        
        // Optional user ID.
        PropUserId = FL_EncryptionClientServer.FieldValueNoException(
            ChannelResources, "PropUserId");
        If ValueIsFilled(PropUserId) Then
            JSONWriter.WritePropertyName("user_id");
            JSONWriter.WriteValue(PropUserId);
        EndIf;
        
        JSONWriter.WritePropertyName("headers");
        JSONWriter.WriteStartObject();
        
            // Provides access to the event source name.
            JSONWriter.WritePropertyName("EventSource");
            JSONWriter.WriteValue(Properties.EventSource);
            
            JSONWriter.WritePropertyName("FileExtension");
            JSONWriter.WriteValue(Properties.FileExtension);

            JSONWriter.WritePropertyName("Operation");
            JSONWriter.WriteValue(String(Properties.Operation));
            
            // The user id of change experienced.
            JSONWriter.WritePropertyName("UserId");
            JSONWriter.WriteValue(Properties.UserId);

        JSONWriter.WriteEndObject();
    
    JSONWriter.WriteEndObject();   
    
EndProcedure // ProcessMessageProperties()

// Only for internal use.
//
Function ExchangePublish(Payload)
    
    Exchange = FL_EncryptionClientServer.FieldValueNoException(
        ChannelResources, "Exchange");
    If NOT ValueIsFilled(Exchange) Then
        Exchange = "amq.default";
    EndIf;
    
    VirtualHost = FL_EncryptionClientServer.FieldValueNoException(
        ChannelResources, "VirtualHost");
    If NOT ValueIsFilled(VirtualHost) Then
        VirtualHost = "%2F";
    EndIf;
    
    ResourceAddress = StrTemplate("/api/exchanges/%1/%2/publish", VirtualHost, 
        Exchange);
    
    Return FL_InteriorUse.NewHTTPRequest(ResourceAddress, 
        NewHTTPRequestHeaders(), Payload);    
    
EndFunction // ExchangePublish()

// Only for internal use.
//
Function Exchanges()
    
    Return FL_InteriorUse.NewHTTPRequest("/api/exchanges", 
        NewHTTPRequestHeaders());
    
EndFunction // Exchanges()

// Only for internal use.
//
Function NewPublishToExchangePayload(Payload, Properties)
    
    If ValueIsFilled(Properties.ReplyTo) Then
        RoutingKey = Properties.ReplyTo;
    Else
        RoutingKey = FL_EncryptionClientServer.FieldValue(ChannelResources, 
            "RoutingKey");
    EndIf;
    
    PayloadEncoding = FL_EncryptionClientServer.FieldValueNoException(
        ChannelResources, "PayloadEncoding");
    If NOT ValueIsFilled(PayloadEncoding) Then
        PayloadEncoding = "base64";
    EndIf;
    
    JSONWriter = New JSONWriter;
    MemoryStream = New MemoryStream;
    JSONWriter.OpenStream(MemoryStream);
    
    JSONWriter.WriteStartObject();
    
    // Routing key.
    JSONWriter.WritePropertyName("routing_key");
    JSONWriter.WriteValue(RoutingKey);
    
    // Payload encoding.
    JSONWriter.WritePropertyName("payload_encoding");
    JSONWriter.WriteValue(PayloadEncoding);
    
    JSONWriter.WritePropertyName("payload");
    If PayloadEncoding = "string" Then
        JSONWriter.WriteValue(GetStringFromBinaryData(Payload));    
    Else
        JSONWriter.WriteValue(Base64String(Payload));
    EndIf;
        
    ProcessMessageProperties(JSONWriter, Properties);
    
    JSONWriter.WriteEndObject();
    JSONWriter.Close();
    
    Return MemoryStream.CloseAndGetBinaryData();
    
EndFunction // NewPublishToExchangePayload()

#EndRegion // Exchanges    

#Region Queues

// Only for internal use.
//
Function Queues()
    
    Return FL_InteriorUse.NewHTTPRequest("/api/queues", 
        NewHTTPRequestHeaders());
    
EndFunction // Queues()

#EndRegion // Queues

#Region Aliveness

// Only for internal use.
//
Function Aliveness()
    
    VirtualHost = FL_EncryptionClientServer.FieldValue(ChannelResources, 
        "VirtualHost");
    
    If NOT ValueIsFilled(VirtualHost) Then
        VirtualHost = "%2F";
    EndIf;
    
    ResourceAddress = StrTemplate("/api/aliveness-test/%1", VirtualHost);
    
    Return FL_InteriorUse.NewHTTPRequest(ResourceAddress, 
        NewHTTPRequestHeaders());
    
EndFunction // Aliveness()

#EndRegion // Aliveness 

// Only for internal use.
//
Function NewHTTPConnection()
                                     
    Return FL_InteriorUse.NewHTTPConnection(
        FL_EncryptionClientServer.FieldValue(ChannelData, "StringURI"));
        
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
    
    Return "1.1.37";
    
EndFunction // Version()

// Returns base object description.
//
// Returns:
//  String - base object description.
//
Function BaseDescription() Export
    
    BaseDescription = NStr("en='RabbitMQ (%1) application endpoint data processor, ver. %2';
        |ru='Обработчик конечной точки приложения RabbitMQ (%1), вер. %2';
        |uk='Обробник кінцевої точки додатку RabbitMQ (%1), вер. %2';
        |en_CA='RabbitMQ (%1) application endpoint data processor, ver. %2'");
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