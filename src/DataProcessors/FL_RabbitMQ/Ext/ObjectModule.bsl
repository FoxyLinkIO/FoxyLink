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
//                               delivered to the app endpoint.
//  Properties - Structure - see function Catalogs.FL_Exchanges.NewProperties.
//  JobResult  - Structure - see function Catalogs.FL_Jobs.NewJobResult.
//
Procedure DeliverMessage(Payload, Properties, JobResult) Export
    
    If Log Then
        JobResult.LogAttribute = "";        
    EndIf;
    
    Path = FL_EncryptionClientServer.FieldValueNoException(ChannelResources, 
        "Path");
    
    If Path = "Aliveness" Then
        AMQPNetAliveness(JobResult);
        HTTPManagementAPIAliveness(JobResult);       
    ElsIf Path = "PublishToExchange" OR Path = Undefined Then
        PublishMessage(Payload, Properties, JobResult);    
    Else
        HTTPManagementAPI(Path, JobResult);
    EndIf;
    
    JobResult.Success = FL_InteriorUseReUse.IsSuccessHTTPStatusCode(
        JobResult.StatusCode);
                
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

#Region HTTPManagementAPI

// Only for internal use.
//
Procedure HTTPManagementAPIAliveness(JobResult)
    
    StringURI = FL_EncryptionClientServer.FieldValueNoException(ChannelData, 
        "StringURI");
    If StringURI = Undefined Then
        Return;
    EndIf;
    
    VirtualHost = FL_EncryptionClientServer.FieldValue(ChannelResources, 
        "VirtualHost");
    If NOT ValueIsFilled(VirtualHost) Then
        VirtualHost = "%2F";
    EndIf;
    
    ResourceAddress = StrTemplate("/api/aliveness-test/%1", VirtualHost);
    HTTPRequest = FL_InteriorUse.NewHTTPRequest(ResourceAddress, 
        NewHTTPRequestHeaders());
    
    If JobResult.StatusCode = Undefined 
        OR FL_InteriorUseReUse.IsSuccessHTTPStatusCode(JobResult.StatusCode) Then
    
        FL_InteriorUse.CallHTTPMethod(FL_InteriorUse.NewHTTPConnection(
                StringURI), HTTPRequest, "GET", JobResult);
                
        BinaryData = JobResult.Output[0].Value;
        Response = ConvertResponseToMap(BinaryData.OpenStreamForRead());
        If TypeOf(Response) <> Type("Map")
            OR TypeOf(Response.Get("status")) <> Type("String")
            OR Upper(Response.Get("status")) <> "OK" Then
            
            JobResult.StatusCode = FL_InteriorUseReUse
                .InternalServerErrorStatusCode();
                
        EndIf;
                
    EndIf;        
 
EndProcedure // HTTPManagementAPIAliveness()

// Only for internal use.
//
Procedure HTTPManagementAPI(Path, JobResult)
    
    StringURI = FL_EncryptionClientServer.FieldValueNoException(ChannelData, 
        "StringURI");
    If StringURI = Undefined Then
        
        JobResult.StatusCode = FL_InteriorUseReUse
            .InternalServerErrorStatusCode();
        JobResult.LogAttribute = NStr(
            "en='App endpoint is not connected to HTTP management API.';
            |ru='Конечная точка приложения не подключена к HTTP management API.';
            |uk='Кінцева точка додатку не підключена до HTTP management API.';
            |en_CA='App endpoint is not connected to HTTP management API.'");
        Return;
        
    EndIf;
    
    If Path = "Overview" Then
        ResourceAddress = "/api/overview";  
    ElsIf Path = "Connections" Then
        ResourceAddress = "/api/connections";
    ElsIf Path = "Channels" Then
        ResourceAddress = "/api/channels";
    ElsIf Path = "Exchanges" Then
        ResourceAddress = "/api/exchanges";
    ElsIf Path = "Queues" Then
        ResourceAddress = "/api/queues";
    Else
        
        JobResult.StatusCode = FL_InteriorUseReUse
            .InternalServerErrorStatusCode();
        JobResult.LogAttribute = StrTemplate(
            NStr("en='HTTP management API: unknown path {%1}.';
                |ru='HTTP management API: неизвестный путь {%1}.';
                |uk='HTTP management API: невідомий шлях {%1}.';
                |en_CA='HTTP management API: unknown path {%1}'"), 
            String(Path));
        Return;
        
    EndIf;
    
    HTTPRequest = FL_InteriorUse.NewHTTPRequest(ResourceAddress, 
        NewHTTPRequestHeaders());
    FL_InteriorUse.CallHTTPMethod(FL_InteriorUse.NewHTTPConnection(StringURI), 
        HTTPRequest, "GET", JobResult);
 
EndProcedure // HTTPManagementAPI()

// Only for internal use.
//
Procedure HTTPManagementAPIPublish(Payload, Properties, StringURI, JobResult)
    
    PreparedPayload = NewPublishToExchangePayload(Payload, Properties); 
    
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
    
    HTTPRequest = FL_InteriorUse.NewHTTPRequest(ResourceAddress, 
        NewHTTPRequestHeaders(), PreparedPayload);
    FL_InteriorUse.CallHTTPMethod(FL_InteriorUse.NewHTTPConnection(StringURI), 
        HTTPRequest, "POST", JobResult);
    
EndProcedure // HTTPManagementAPIPublish() 

// Only for internal use.
//
Procedure HTTPManagementAPIProcessProps(JSONWriter, Properties)
    
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
    
EndProcedure // HTTPManagementAPIProcessProps()

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
        PayloadEncoding = "string";
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
        
    HTTPManagementAPIProcessProps(JSONWriter, Properties);
    
    JSONWriter.WriteEndObject();
    JSONWriter.Close();
    
    Return MemoryStream.CloseAndGetBinaryData();
    
EndFunction // NewPublishToExchangePayload()
   
#EndRegion // HTTPManagementAPI 

#Region AMQPNet

// Only for internal use.
//
Procedure AMQPNetAliveness(JobResult)
    
    AMQPURI = FL_EncryptionClientServer.FieldValueNoException(ChannelData, 
        "AMQPURI");
    If AMQPURI = Undefined Then
        Return;        
    EndIf;
    
    V8Publisher = NewV8Publisher(AMQPURI, JobResult);
    If V8Publisher <> Undefined Then
        V8Publisher.Dispose();
    EndIf;
    
EndProcedure // AMQPNetAliveness()    

// Only for internal use.
//
Procedure AMQPNetPublish(Payload, Properties, AMQPURI, JobResult)
    
    V8Publisher = NewV8Publisher(AMQPURI, JobResult);
    If V8Publisher = Undefined Then
        Return;
    EndIf;
        
    Exchange = FL_EncryptionClientServer.FieldValueNoException(
        ChannelResources, "Exchange");
    If NOT ValueIsFilled(Exchange) Then
        Exchange = "";
    EndIf;

    If ValueIsFilled(Properties.ReplyTo) Then
        Exchange = "";
        RoutingKey = Properties.ReplyTo;
    Else
        RoutingKey = FL_EncryptionClientServer.FieldValue(ChannelResources, 
            "RoutingKey");
    EndIf;
    
    AMQPNetProcessProps(V8Publisher, Properties);
    
    Result = V8Publisher.SendMessage(Payload, Exchange, RoutingKey);
    If Result = "Delivered successfully." Then
        
        JobResult.StatusCode = FL_InteriorUseReUse.OkStatusCode();
        If Log Then
            JobResult.LogAttribute = Result;        
        EndIf;
        
    Else
        
        JobResult.StatusCode = FL_InteriorUseReUse
            .InternalServerErrorStatusCode();
        JobResult.LogAttribute = Result;
        
    EndIf;
        
    V8Publisher.Dispose();
    
EndProcedure // AMQPNetPublish()

// Only for internal use.
//
Procedure AMQPNetProcessProps(V8Publisher, Properties)
    
    // Identifier of the application that produced the message.
    V8Publisher.AppId = Properties.AppId;
    
    // Non-persistent (1) or persistent (2).
    PropDeliveryMode = FL_EncryptionClientServer.FieldValueNoException(
        ChannelResources, "PropDeliveryMode");
    If ValueIsFilled(PropDeliveryMode) Then    
        V8Publisher.DeliveryMode = ?(PropDeliveryMode = "non-persistent", 1, 2);
    EndIf;
    
    // MIME content type.
    V8Publisher.ContentType = Properties.ContentType;

    // MIME content encoding.
    V8Publisher.ContentEncoding = Properties.ContentEncoding;
            
    // Message correlated to this one, e.g. what request this message is a reply to.
    If ValueIsFilled(Properties.CorrelationId) Then
        V8Publisher.CorrelationId = Properties.CorrelationId;
    EndIf;
    
    // Expiration time after which the message will be deleted.
    PropExpiration = FL_EncryptionClientServer.FieldValueNoException(
        ChannelResources, "PropExpiration");
    If ValueIsFilled(PropExpiration) Then
        V8Publisher.Expiration = PropExpiration;
    EndIf;
    
    // Application message identifier.
    V8Publisher.MessageId = Properties.MessageId;
    
    // Message priority.
    PropPriority = FL_EncryptionClientServer.FieldValueNoException(
        ChannelResources, "PropPriority");
    If ValueIsFilled(PropPriority) Then
        V8Publisher.Priority = Number(PropPriority);
    EndIf;
    
    // Message type.
    PropType = FL_EncryptionClientServer.FieldValueNoException(
        ChannelResources, "PropType");
    If ValueIsFilled(PropType) Then
        V8Publisher.Type = PropType;
    EndIf;
    
    // Message timestamp.
    V8Publisher.Timestamp = Format(Properties.Timestamp, "NG=0");
    
    // Optional user ID.
    PropUserId = FL_EncryptionClientServer.FieldValueNoException(
        ChannelResources, "PropUserId");
    If ValueIsFilled(PropUserId) Then
        V8Publisher.UserId = PropUserId;
    EndIf;
    
    V8Publisher.AddHeader("EventSource", Properties.EventSource);
    V8Publisher.AddHeader("FileExtension", Properties.FileExtension);
    V8Publisher.AddHeader("Operation", String(Properties.Operation));
    V8Publisher.AddHeader("UserId", Properties.UserId);
    
EndProcedure // AMQPNetProcessProps() 

// Only for internal use.
//
Function NewV8Publisher(AMQPURI, JobResult) 
    
    V8LoaderTemplate = GetTemplate("V8Loader");
    V8LoaderAddress = PutToTempStorage(V8LoaderTemplate);
    
    Try
        
        Attached = AttachAddIn(V8LoaderAddress, "V8", AddInType.Native); 
        If NOT Attached Then
            Raise NStr("en='Failed to attach AddIn {V8Loader}.';
                |ru='Не удалось подключить внешнюю компоненту {V8Loader}.';
                |uk='Не вдалось підключити зовнішню компоненту {V8Loader}.';
                |en_CA='Failed to attach AddIn {V8Loader}.'");
        EndIf;
        
        V8Publisher = New("AddIn.V8.V8Loader");
        V8Publisher.CreateObject(GetTemplate("V8Publisher"), 
            "_1CV8Publisher.V8Publisher");
        
        AddInMessage = V8Publisher.Initialize(AMQPURI);
        If AddInMessage <> "Connected successfully." Then
            Raise AddInMessage;  
        EndIf;
        
        JobResult.StatusCode = FL_InteriorUseReUse.OkStatusCode();
        
    Except
        
        JobResult.StatusCode = FL_InteriorUseReUse
            .InternalServerErrorStatusCode();
            
        If V8Publisher <> Undefined Then
            JobResult.LogAttribute = V8Publisher.GetLastError();
            V8Publisher = Undefined;
        EndIf;
        
        If IsBlankString(JobResult.LogAttribute) Then
            JobResult.LogAttribute = ErrorDescription();
        EndIf;
        
    EndTry;
    
    Return V8Publisher;
    
EndFunction // NewV8Publisher()

#EndRegion // AMQPNet

// Only for internal use.
//
Procedure PublishMessage(Payload, Properties, JobResult)
    
    Mib = 1048576;
    Mib300 = 314572800;
    Size = PayloadSize(Payload);
    
    AMQPURI = FL_EncryptionClientServer.FieldValueNoException(ChannelData, 
        "AMQPURI");
    StringURI = FL_EncryptionClientServer.FieldValueNoException(ChannelData, 
        "StringURI");
    
    If Size <= Mib AND ValueIsFilled(StringURI) Then
        HTTPManagementAPIPublish(Payload, Properties, StringURI, JobResult);   
    ElsIf Size <= Mib300 AND ValueIsFilled(AMQPURI) Then
        AMQPNetPublish(Payload, Properties, AMQPURI, JobResult);
    Else
        
        JobResult.StatusCode = FL_InteriorUseReUse
            .InternalServerErrorStatusCode();
        JobResult.LogAttribute = NStr(
            "en='App endpoint is not connected or payload size exceeded the maximum.';
            |ru='Конечная точка приложения не подключена или размер сообщения превышает максимальный допустимый.';
            |uk='Кінцева точка додатку не підключена або розмір повідомлення перевищує максимально допустимий.';
            |en_CA='App endpoint is not connected or payload size exceeded the maximum.'");
    
    EndIf;
    
EndProcedure // PublishMessage()

// Only for internal use.
//
Function NewHTTPRequestHeaders()
    
    Headers = New Map;
    Headers.Insert("Accept", "application/json"); 
    Headers.Insert("Content-Type", "application/json");
    Return Headers;
    
EndFunction // NewHTTPRequestHeaders()

// Only for internal use.
//
Function PayloadSize(Payload)
    
    If TypeOf(Payload) = Type("BinaryData") Then
        Return Payload.Size();
    EndIf;
    
    Return 0;
    
EndFunction // PayloadSize()

#EndRegion // ServiceProceduresAndFunctions

#Region ExternalDataProcessorInfo

// Returns object version.
//
// Returns:
//  String - object version.
//
Function Version() Export
    
    Return "1.3.14";
    
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