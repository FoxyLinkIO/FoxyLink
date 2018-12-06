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

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
    
    If Parameters.Property("AutoTest") Then
        Return;
    EndIf;
    
    If Parameters.Property("AppEndpoint", AppEndpoint)
        AND NOT Parameters.Property("ChannelData") 
        AND NOT Parameters.Property("EncryptedData") Then
        
        For Each Item In AppEndpoint.ChannelData Do
            FillPropertyValues(Object.ChannelData.Add(), Item);
        EndDo;
        
        For Each Item In AppEndpoint.EncryptedData Do
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
    ElsIf Items.RabbitMQPages.CurrentPage = Items.PageExchanges Then
        FillExchangesPage(MainObject);
    ElsIf Items.RabbitMQPages.CurrentPage = Items.PageQueues Then
        FillQueuesPage(MainObject);
    EndIf;
    
    ValueToFormAttribute(MainObject, "Object");
    
EndProcedure // UpdateRabbitMQView()

&AtServer
Procedure FillOverviewPage(MainObject)
    
    Var Temp;
    
    ClearOverviewPage();
    
    Response = DeliverToAppEndpoint(MainObject, "Overview");
    If Response = Undefined Then
        Return;
    EndIf;
     
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
        PublishRate      = Temp["publish_details"]["rate"]; 
        ConfirmRate      = Temp["confirm_details"]["rate"];
        Deliver_rate     = Temp["deliver_details"]["rate"];
        RedeliverRate    = Temp["redeliver_details"]["rate"];
        AckRate          = Temp["ack_details"]["rate"];
        GetRate          = Temp["get_details"]["rate"];
        DeliverNoAckRate = Temp["deliver_no_ack_details"]["rate"];
        If Temp.Get("get_no_ack_details") <> Undefined Then
            GetNoAckRate = Temp["get_no_ack_details"]["rate"];
        EndIf;
        ReturnUnroutableRate = Temp["return_unroutable_details"]["rate"];
    EndIf;
    
    Temp = Response["queue_totals"];
    If TypeOf(Temp) = Type("Map") Then 
        Messages                = Temp["messages"];
        MessagesReady          = Temp["messages_ready"];
        MessagesUnacknowledged = Temp["messages_unacknowledged"];
    EndIf;     
  
EndProcedure // FillOverviewPage()

&AtServer
Procedure FillConnectionsPage(MainObject)
    
    ClearConnectionsPage(); 
    
    Response = DeliverToAppEndpoint(MainObject, "Connections");
    If TypeOf(Response) = Type("Array") Then
        FL_CommonUse.ExtendValueTableFromArray(Response, Connections);
    EndIf;
    
EndProcedure // FillConnectionsPage()

&AtServer
Procedure FillChannelsPage(MainObject)
    
    ClearChannelsPage(); 
    
    Response = DeliverToAppEndpoint(MainObject, "Channels");    
    If TypeOf(Response) <> Type("Array") Then
        Return;
    EndIf;
    
    For Each Item In Response Do
        
        NewChannel = Channels.Add();
        
        ConnectionDetails = Item["connection_details"];
        If TypeOf(ConnectionDetails) = Type("Map") Then
            NewChannel.peer_host = ConnectionDetails["peer_host"];
            NewChannel.peer_port = ConnectionDetails["peer_port"];
        EndIf;
        
        NewChannel.consumer_count = Item["consumer_count"];
        NewChannel.node = Item["node"];
        NewChannel.user = Item["user"];
        NewChannel.state = Item["state"];
        
        If Item["transactional"] Then
            NewChannel.mode = "T";
        EndIf;
        
        If Item["confirm"] Then
            NewChannel.mode = "C";
        EndIf;
        
        NewChannel.messages_unconfirmed    = Item["messages_unconfirmed"];
        NewChannel.prefetch_count          = Item["prefetch_count"];
        NewChannel.messages_unacknowledged = Item["messages_unacknowledged"];
        
        MessageStats = Item["message_stats"];
        If TypeOf(MessageStats) = Type("Map") Then
            NewChannel.publish     = MessageStats["publish"];
            NewChannel.deliver_get = MessageStats["deliver_get"];
            NewChannel.ack         = MessageStats["ack"];
        EndIf;
        
    EndDo;

EndProcedure // FillChannelsPage()

&AtServer
Procedure FillExchangesPage(MainObject)
    
    ClearExchangesPage(); 
    
    Response = DeliverToAppEndpoint(MainObject, "Exchanges");
    If TypeOf(Response) = Type("Array") Then
        For Each Item In Response Do
            
            NewExchange = Exchanges.Add();
            NewExchange.name = Item["name"];
            NewExchange.type = Item["type"];
            NewExchange.auto_delete = Item["auto_delete"];
            NewExchange.durable = Item["durable"];
            NewExchange.internal = Item["internal"];
            NewExchange.policy = Item["policy"];
            
            MessageStats = Item["message_stats"];
            If TypeOf(MessageStats) = Type("Map") Then
                NewExchange.publish_in  = MessageStats["publish_in"];
                NewExchange.publish_out = MessageStats["publish_out"];
            EndIf;
            
        EndDo;
    EndIf;
    
EndProcedure // FillExchangesPage()

&AtServer
Procedure FillQueuesPage(MainObject)
    
    ClearQueuesPage(); 
    
    Response = DeliverToAppEndpoint(MainObject, "Queues");
    If TypeOf(Response) = Type("Array") Then
        For Each Item In Response Do
            
            NewQueue = Queues.Add();
            NewQueue.name = Item["name"];
            
            SlaveNodes = Item["slave_nodes"]; 
            If TypeOf(SlaveNodes) = Type("Array")
                AND SlaveNodes.Count() > 0 Then
                NewQueue.node = StrTemplate("%1 +%2", Item["node"], 
                    SlaveNodes.Count());
            Else
                NewQueue.node = Item["node"];    
            EndIf;    
            
            NewQueue.auto_delete = Item["auto_delete"];
            NewQueue.durable = Item["durable"];
            
            OwnerPidDetails = Item["owner_pid_details"];
            If TypeOf(OwnerPidDetails) = Type("Map") Then 
                NewQueue.exclusive = OwnerPidDetails["name"];
            EndIf;    
                
            NewQueue.policy = Item["policy"];
            NewQueue.state = Item["state"];
            NewQueue.messages_ready = Item["messages_ready"];
            NewQueue.messages_unacknowledged = Item["messages_unacknowledged"];
            NewQueue.messages = Item["messages"];
                        
        EndDo;
    EndIf;
    
EndProcedure // FillQueuesPage()

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

&AtServer
Procedure ClearExchangesPage()
    
    Exchanges.Clear();       
    
EndProcedure // ClearExchangesPage()

&AtServer
Procedure ClearQueuesPage()
    
    Queues.Clear();       
    
EndProcedure // ClearQueuesPage()

&AtServer
Function DeliverToAppEndpoint(MainObject, ResourceName)
    
    MainObject.ChannelResources.Clear();
    FL_EncryptionClientServer.AddFieldValue(MainObject.ChannelResources, 
        "Path", ResourceName);
    
    JobResult = Catalogs.FL_Jobs.NewJobResult();
    MainObject.DeliverMessage(Undefined, Undefined, JobResult); 
        
    LogAttribute = LogAttribute + JobResult.LogAttribute;
    If NOT JobResult.Success Then
        Return Undefined;
    EndIf;
    
    BinaryData = JobResult.Output[0].Value;
    Return MainObject.ConvertResponseToMap(BinaryData.OpenStreamForRead());
    
EndFunction // DeliverToAppEndpoint()

#EndRegion // ServiceProceduresAndFunctions 