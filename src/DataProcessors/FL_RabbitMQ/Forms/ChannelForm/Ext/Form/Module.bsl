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

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
    
    Var ChannelRef;
    
    If Parameters.Property("ChannelRef", ChannelRef) Then
        
        For Each Item In ChannelRef.ChannelData Do
            FillPropertyValues(Object.ChannelData.Add(), Item);
        EndDo;
        
        For Each Item In ChannelRef.EncryptedData Do
            FillPropertyValues(Object.EncryptedData.Add(), Item);
        EndDo;
            
    Else
        
        CopyFormData(Parameters.ChannelData, Object.ChannelData);
        CopyFormData(Parameters.EncryptedData, Object.EncryptedData);
        
    EndIf;
    
    UpdateRabbitMQView();
    
EndProcedure // OnCreateAtServer()

#EndRegion // FormEventHandlers

#Region FormItemsEventHandlers

&AtClient
Procedure RabbitMQPagesOnCurrentPageChange(Item, CurrentPage)
   
    UpdateRabbitMQView();
    
EndProcedure // RabbitMQPagesOnCurrentPageChange()

#EndRegion // FormItemsEventHandlers

#Region ServiceProceduresAndFunctions

&AtServer
Procedure UpdateRabbitMQView()
    
    MainObject = FormAttributeToValue("Object");
    If Items.RabbitMQPages.CurrentPage = Items.PageOverview Then
        FillOverviewPage(MainObject);
    ElsIf Items.RabbitMQPages.CurrentPage = Items.PageConnections Then 
        FillConnectionsPage(MainObject);
    ElsIf Items.RabbitMQPages.CurrentPage = Items.PageChannels Then
        FillChannelsPage(MainObject);    
    EndIf;
    
    ValueToFormAttribute(MainObject, "Object");
    
EndProcedure // UpdateRabbitMQView()

&AtServer
Procedure FillOverviewPage(MainObject)
    
    Var Temp;
    
    ClearOverviewPage();
    
    DeliveryResult = MainObject.DeliverMessage(Undefined, Undefined, 
        New Structure("PredefinedAPI", "Overview"));
    If DeliveryResult.Success Then
        
        Response = MainObject.ConvertResponseToMap(
            DeliveryResult.StringResponse);  
            
        ClusterName = Response["cluster_name"];
        Erlang_version = Response["erlang_version"];
        RabbitMQVersion = Response["rabbitmq_version"];
        
        Temp = Response["listeners"];
        If TypeOf(Temp) = Type("Array") Then
            FL_CommonUse.ExtendValueTableFromArray(Temp, Listeners);
        EndIf;

        Temp = Response["contexts"];
        If TypeOf(Temp) = Type("Array") Then
            FL_CommonUse.ExtendValueTableFromArray(Temp, Contexts); 
        EndIf;

        Temp = Response["object_totals"];
        If TypeOf(Temp) = Type("Map") Then 
            ConnectionsCount = Temp["connections"];
            ChannelsCount    = Temp["channels"];
            ExchangesCount   = Temp["exchanges"];
            QueuesCount      = Temp["queues"];
            ConsumersCount   = Temp["consumers"];    
        EndIf;
        
        Temp = Response["message_stats"];
        If TypeOf(Temp) = Type("Map") Then 
            PublishRate           = Temp["publish_details"]["rate"]; 
            ConfirmRate           = Temp["confirm_details"]["rate"];
            Deliver_rate           = Temp["deliver_details"]["rate"];
            RedeliverRate         = Temp["redeliver_details"]["rate"];
            AckRate               = Temp["ack_details"]["rate"];
            GetRate               = Temp["get_details"]["rate"];
            DeliverNoAckRate    = Temp["deliver_no_ack_details"]["rate"];
            GetNoAckRate        = Temp["get_no_ack_details"]["rate"];
            ReturnUnroutableRate = Temp["return_unroutable_details"]["rate"];
        EndIf;
        
        Temp = Response["queue_totals"];
        If TypeOf(Temp) = Type("Map") Then 
            Messages                = Temp["messages"];
            MessagesReady          = Temp["messages_ready"];
            MessagesUnacknowledged = Temp["messages_unacknowledged"];
        EndIf;     
               
    EndIf;
  
EndProcedure // FillOverviewPage()

&AtServer
Procedure FillConnectionsPage(MainObject)
    
    ClearConnectionsPage(); 
    
    DeliveryResult = MainObject.DeliverMessage(Undefined, Undefined, 
        New Structure("PredefinedAPI", "Connections"));
    If DeliveryResult.Success Then

        Response = MainObject.ConvertResponseToMap(
            DeliveryResult.StringResponse);
        If TypeOf(Response) = Type("Array") Then
            FL_CommonUse.ExtendValueTableFromArray(Response, Connections);
        EndIf;
        
    EndIf;
    
EndProcedure // FillConnectionsPage()

&AtServer
Procedure FillChannelsPage(MainObject)
    
    ClearChannelsPage(); 
    
    DeliveryResult = MainObject.DeliverMessage(Undefined, Undefined, 
        New Structure("PredefinedAPI", "Channels"));
    If DeliveryResult.Success Then

        Response = MainObject.ConvertResponseToMap(
            DeliveryResult.StringResponse);
        If TypeOf(Response) = Type("Array") Then
            FL_CommonUse.ExtendValueTableFromArray(Response, Channels);
        EndIf;
        
    EndIf;
    
EndProcedure // FillChannelsPage()

&AtServer
Procedure ClearOverviewPage()
    
    Contexts.Clear();
    Listeners.Clear();
    
    ClusterName = Undefined;
    Erlang_version = Undefined;
    RabbitMQVersion = Undefined;
    
    ConnectionsCount = 0;
    ChannelsCount = 0;
    ExchangesCount = 0;
    QueuesCount = 0;
    ConsumersCount = 0;
    
    PublishRate = 0;          
    ConfirmRate = 0;          
    Deliver_rate = 0;          
    RedeliverRate = 0;        
    AckRate = 0;            
    GetRate = 0;              
    DeliverNoAckRate = 0;    
    GetNoAckRate = 0;      
    ReturnUnroutableRate = 0;
    
    Messages = 0;              
    MessagesReady = 0;       
    MessagesUnacknowledged = 0;
    
EndProcedure // ClearOverviewPage() 

&AtServer
Procedure ClearConnectionsPage()
    
    Connections.Clear();       
    
EndProcedure // ClearConnectionsPage()

&AtServer
Procedure ClearChannelsPage()
    
    Channels.Clear();       
    
EndProcedure // ClearChannelsPage()

#EndRegion // ServiceProceduresAndFunctions 