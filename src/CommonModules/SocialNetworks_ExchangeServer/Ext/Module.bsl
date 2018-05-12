////////////////////////////////////////////////////////////////////////////////
// This file is part of FoxyLink.
// Copyright © 2018 Petro Bazeliuk.
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
// along with this program. If not, see <http://www.gnu.org/licenses/agpl-3.0>.
//
////////////////////////////////////////////////////////////////////////////////

#Region ProgramInterface

// Runs the exchange server in this infobase immediately.
//
// Parameters:
//  SafeMode   - Boolean - executes the method with pre-establishing 
//              a safe mode of code execution.
//                  Default value: False.
//
Procedure RunExchangeServer(SafeMode = False) Export
    
    ExchangeServer = ExchangeServer();
    
    Task = FL_Tasks.NewTask();
    Task.Description = ExchangeServer.Description;
    Task.Key = ExchangeServer.Key;
    Task.MethodName = ExchangeServer.Metadata.MethodName; 
    Task.SafeMode = SafeMode;
    
    FL_Tasks.Run(Task); 
    
EndProcedure // RunExchangeServer()

// Stops the specified exchange server immediately.
//
Procedure StopExchangeServer() Export
    
    ExchangeServer = ExchangeServer();
    
    BackgroundJobsFilter = FL_JobServer.NewBackgroundJobsFilter();
    BackgroundJobsFilter.State = BackgroundJobState.Active;
    FillPropertyValues(BackgroundJobsFilter, ExchangeServer, , 
        "Description, UUID");
    FL_CommonUseClientServer.RemoveValueFromStructure(BackgroundJobsFilter);
        
    BackgroundJobsByFilter = FL_JobServer.BackgroundJobsByFilter(BackgroundJobsFilter);
    For Each BackgroundJob In BackgroundJobsByFilter Do
        BackgroundJob.Cancel();        
    EndDo;
            
EndProcedure // StopExchangeServer()

// Returns registered the exchange server in the current infobase.
// 
// Returns:
//  ScheduledJob - job server.
//
Function ExchangeServer() Export

    ExchangeServer = FL_JobServer.ScheduledJob(
        Metadata.ScheduledJobs.SocialNetworks_ExchangeServer);
    Return ExchangeServer;

EndFunction // ExchangeServer()

#EndRegion // ProgramInterface

#Region ServiceInterface

// Default ExchangeServer action.
// 
Procedure ExchangeServerAction() Export
    
    LastDate = GetLastDate();
    
    ConversationsFilter = New CollaborationSystemConversationsFilter;
    ConversationsFilter.StartDate = LastDate;
    ConversationsFilter.SortDirection = SortDirection.Asc;
    ConversationsFilter.CurrentUserIsMember = False;
    
    SetPrivilegedMode(True);
    Conversations = CollaborationSystem.GetConversations(ConversationsFilter);
    SetPrivilegedMode(False);
    
    For Each Conversation In Conversations Do
        
        SocialConversation = Catalogs.SocialNetworks_Conversations
            .SocialNetworkConversationByConversationId(
                String(Conversation.ID));
        
        If SocialConversation = Undefined Then
            Continue;
        EndIf;
        
        ProcessCollaborationMessages(SocialConversation, Conversation, 
            LastDate);
        
    EndDo;
    
EndProcedure // ExchangeServerAction()

// Sets a last processed message date for this database.
//
// Parameters:
//  LastDate - Date - the last processed message date for this database. 
//
Procedure SetLastDate(LastDate) Export
    
    Constants.SocialNetworks_LastDate.Set(LastDate);
    
EndProcedure // SetLastDate()

// Returns the last processed message date for this database.
//
// Returns:
//  Date - the last processed message date for this database.
//
Function GetLastDate() Export
    
    SetPrivilegedMode(True);
    Return Constants.SocialNetworks_LastDate.Get();
    
EndFunction // GetLastDate() 

#EndRegion // ServiceInterface

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
Procedure ProcessCollaborationMessages(SocialConversation, Conversation, 
    LastDate)

    MessagePointer = FL_CommonUse.ObjectAttributeValue(SocialConversation, 
        "MessagePointer");
    
    MessagesFilter = New CollaborationSystemMessagesFilter;
    MessagesFilter.Conversation = Conversation.ID;
    MessagesFilter.SortDirection = SortDirection.Asc;
    If ValueIsFilled(MessagePointer) Then
        MessagesFilter.After = New CollaborationSystemMessageID(
            MessagePointer);   
    EndIf;
    
    SetPrivilegedMode(True);
    CollaborationMessages = CollaborationSystem.GetMessages(MessagesFilter);
    SetPrivilegedMode(False);
    
    If CollaborationMessages.Count() = 0 Then
        Return;
    EndIf;
    
    ValueTable = InformationRegisters.SocialNetworks_MessageMatches
        .NewMessageMatchesValueTable();
    For Each CollaborationMessage In CollaborationMessages Do
        NewRow = ValueTable.Add();    
        NewRow.CSMessageID = String(CollaborationMessage.ID);
        NewRow.Date = CollaborationMessage.Date;
    EndDo; 
    
    Query = New Query;
    Query.Text = QueryTextMessagesWithoutMatches();
    Query.SetParameter("ValueTable", ValueTable);
    QueryResult = Query.Execute();
    If NOT QueryResult.IsEmpty() Then
        MessagesToSend = QueryResult.Unload();
        SendMessageReplies(SocialConversation, CollaborationMessages, 
            MessagesToSend);
    EndIf;
    
    LastMessage = CollaborationMessages[CollaborationMessages.UBound()];
    Catalogs.SocialNetworks_Conversations.UpdateMessagePointer(
        SocialConversation, String(LastMessage.ID));
        
EndProcedure // ProcessCollaborationMessages()

// Only for internal use.
//
Procedure SendMessageReplies(SocialConversation, CollaborationMessages, 
    MessagesToSend)
    
    Invocation = Catalogs.FL_Messages.NewInvocation();
    Invocation.EventSource = "SocialNetworks_ExchangeServer.SendMessageReplies";
    Invocation.Operation = Catalogs.FL_Operations.Send;
    
    Exchange = FL_CommonUse.ReferenceByDescription(
        Metadata.Catalogs.FL_Exchanges, "SocialNetwork_NewMessage");
    
    MessagesToSend.Indexes.Add("CSMessageID");
    For Each CollaborationMessage In CollaborationMessages Do
        
        CSMessageID = String(CollaborationMessage.ID);
        SearchResult = MessagesToSend.Find(CSMessageID, "CSMessageID");
        If SearchResult <> Undefined Then
            
            Catalogs.FL_Messages.AddToContext(Invocation.Context, "Ref", 
                SocialConversation, True);
            Catalogs.FL_Messages.AddToContext(Invocation.Context, "CSMessageID", 
                CSMessageID);
            Catalogs.FL_Messages.AddToContext(Invocation.Context, "Date", 
                SearchResult.Date);
            Catalogs.FL_Messages.AddToContext(Invocation.Context, "Text", 
                String(CollaborationMessage.Text));
                
            Catalogs.FL_Messages.Route(Invocation, Exchange);
            
            InformationRegisters.SocialNetworks_MessageMatches
                .WriteMessageMatch(CSMessageID);
            
            Invocation.Context.Clear();
            
        EndIf;
        
    EndDo;
    
EndProcedure // SendMessageReplies()    

// Only for internal use.
//
Function QueryTextMessagesWithoutMatches()
    
    QueryText = "
        |SELECT
        |   ValueTable.CSMessageID AS CSMessageID,
        |   ValueTable.Date AS Date
        |INTO ValueTable
        |FROM
        |   &ValueTable AS ValueTable
        |INDEX BY
        |   ValueTable.CSMessageID
        |;
        |
        |////////////////////////////////////////////////////////////////////////////////
        |SELECT
        |   ValueTable.CSMessageID AS CSMessageID,
        |   ValueTable.Date AS Date 
        |FROM
        |   ValueTable AS ValueTable
        |
        |LEFT JOIN InformationRegister.SocialNetworks_MessageMatches AS MessageMatches
        |ON MessageMatches.CSMessageID = ValueTable.CSMessageID
        |
        |WHERE
        |   MessageMatches.SNMessageID IS NULL
        |
        |ORDER BY
        |   Date ASC
        |;
        |
        |////////////////////////////////////////////////////////////////////////////////
        |DROP ValueTable
        |;
        |
        |";
    Return QueryText;
    
EndFunction // QueryMessagesWithoutMatches()

#EndRegion // ServiceProceduresAndFunctions