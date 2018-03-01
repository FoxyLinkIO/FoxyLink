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

// Delivers a stream object to the current channel.
//
// Parameters:
//  Stream         - Stream       - a data stream that can be read successively 
//                              or/and where you can record successively. 
//                 - MemoryStream - specialized version of Stream object for 
//                              operation with the data located in the RAM.
//                 - FileStream   - specialized version of Stream object for 
//                              operation with the data located in a file on disk.
//  Properties     - Structure    - channel parameters.
//
// Returns:
//  Structure - see function Catalogs.FL_Channels.NewChannelDeliverResult.
//
Function DeliverMessage(Stream, Properties) Export
    
    Var HTTPMethod, HTTPRequest, PayLoad;
    
    DeliveryResult = Catalogs.FL_Channels.NewChannelDeliverResult();    
    If TypeOf(Properties) <> Type("Structure") Then   
        Raise FL_ErrorsClientServer.ErrorTypeIsDifferentFromExpected(
            "Properties", Properties, Type("Structure"));
    EndIf;
    
    If Stream <> Undefined Then
        
        DataReader = New DataReader(Stream);
        BinaryData = DataReader.Read().GetBinaryData();
        PayLoad = GetStringFromBinaryData(BinaryData);
        DataReader.Close();
        
    EndIf;
    
    ResolveProperties(Properties, HTTPMethod, HTTPRequest, Payload);
    
    If Log Then
        DeliveryResult.LogAttribute = "";     
    EndIf;
    
    FL_InteriorUse.CallHTTPMethod(NewHTTPConnection(), HTTPRequest, 
        HTTPMethod, DeliveryResult);
        
    Return DeliveryResult;
    
EndFunction // DeliverMessage() 

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
Function ExchangePublishHTTPRequest(Properties, Payload)
    
    Return FL_InteriorUse.NewHTTPRequest(Properties.ResourceAddress,  
        NewHTTPRequestHeaders(), NewExchangePublishPayload(Properties, 
            Payload));
    
EndFunction // ExchangePublishHTTPRequest()

// Only for internal use.
//
Function NewExchangePublishPayload(Properties, Payload)
    
    JSONWriter = New JSONWriter;
    JSONWriter.SetString();
    
    JSONWriter.WriteStartObject();
    
    // Routing key.
    JSONWriter.WritePropertyName("routing_key");
    JSONWriter.WriteValue(Properties.RoutingKey);
    
    // Payload encoding.
    JSONWriter.WritePropertyName("payload_encoding");
    JSONWriter.WriteValue(Properties.PayloadEncoding);
    
    // Properties
    JSONWriter.WritePropertyName("properties");
    JSONWriter.WriteStartObject();
    JSONWriter.WriteEndObject();
    
    // Payload.
    JSONWriter.WritePropertyName("payload");
    If Properties.PayloadEncoding = "string" Then
        JSONWriter.WriteValue(Payload);    
    Else
        JSONWriter.WriteValue(Base64String(GetBinaryDataFromString(Payload)));
    EndIf;
    
    JSONWriter.WriteEndObject();
    Return JSONWriter.Close();
    
EndFunction // NewExchangePublishPayload()

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

#EndRegion // Aliveness 

// Only for internal use.
//
Procedure ResolveProperties(Properties, HTTPMethod, HTTPRequest, 
    Payload = Undefined)
    
    HTTPMethod = "GET";
    If Properties.Path = "PublishToExchange" Then
        
        HTTPMethod = "POST";     
        HTTPRequest = ExchangePublishHTTPRequest(Properties, Payload);
        
    ElsIf Properties.Path = "Overview" Then
        
        HTTPRequest = OverviewHTTPRequest();
        
    ElsIf Properties.Path = "Connections" Then
        
        HTTPRequest = ConnectionsHTTPRequest();
        
    ElsIf Properties.Path = "Channels" Then
        
        HTTPRequest = ChannelsHTTPRequest();
        
    ElsIf Properties.Path = "Exchanges" Then
        
        HTTPRequest = ExchangesHTTPRequest();
        
    ElsIf Properties.Path = "Queues" Then
        
        HTTPRequest = QueuesHTTPRequest();
        
    ElsIf Properties.Path = "Aliveness" Then
        
        VirtualHost = Properties.VirtualHost;
        HTTPRequest = AlivenessHTTPRequest(VirtualHost);
        
    EndIf;    
    
EndProcedure // ResolveProperties()

// Only for internal use.
//
Function ReadChannelDataValue(FieldName)
    
    SearchResult = ChannelData.Find(FieldName, "FieldName");
    If SearchResult <> Undefined Then
        Return SearchResult.FieldValue;
    EndIf;
    
    Return Undefined;
    
EndFunction // ReadChannelDataValue()

// Only for internal use.
//
Function NewHTTPConnection()
                                     
    Return FL_InteriorUse.NewHTTPConnection(ReadChannelDataValue("StringURI"));
    
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
    
    Return "1.0.4";
    
EndFunction // Version()

// Returns base object description.
//
// Returns:
//  String - base object description.
//
Function BaseDescription() Export
    
    BaseDescription = NStr("en='RabbitMQ (%1) channel data processor, ver. %2';
        |ru='Обработчик канала RabbitMQ (%1), вер. %2';
        |en_CA='RabbitMQ (%1) channel data processor, ver. %2'");
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