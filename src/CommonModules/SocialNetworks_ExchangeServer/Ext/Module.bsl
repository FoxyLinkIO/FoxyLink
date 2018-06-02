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
    
    Filter = New CollaborationSystemConversationsFilter;
    Filter.StartDate = LastDate;
    Filter.SortDirection = SortDirection.Asc;
    Filter.CurrentUserIsMember = False;
    
    CollaborationConversations = DataProcessors.FL_CollaborationSystem
        .CollaborationSystemConversations(Filter);    
    For Each Conversation In CollaborationConversations Do
        
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
    
    Filter = New CollaborationSystemMessagesFilter;
    Filter.Conversation = Conversation.ID;
    Filter.SortDirection = SortDirection.Asc;
    If ValueIsFilled(MessagePointer) Then
        Filter.After = New CollaborationSystemMessageID(
            MessagePointer);   
    EndIf;
        
    CollaborationMessages = DataProcessors.FL_CollaborationSystem
        .CollaborationSystemMessages(Filter);
    If CollaborationMessages.Count() = 0 Then
        Return;
    EndIf;
    
    ValueTable = InformationRegisters.SocialNetworks_Messages
        .NewMessageMatchesValueTable();
    For Each CollaborationMessage In CollaborationMessages Do
        NewRow = ValueTable.Add();
        NewRow.SocialConversation = SocialConversation;
        NewRow.CollaborationMessageId = String(CollaborationMessage.ID);
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
        Metadata.Catalogs.FL_Exchanges, "SocialNetworkMessage");
    
    MessagesToSend.Indexes.Add("CollaborationMessageId");
    For Each CollaborationMessage In CollaborationMessages Do
        
        CollaborationMessageId = String(CollaborationMessage.ID);
        SearchResult = MessagesToSend.Find(CollaborationMessageId, 
            "CollaborationMessageId");
        If SearchResult <> Undefined Then
            
            Catalogs.FL_Messages.AddToContext(Invocation.Context, "Ref", 
                SocialConversation, True);
            Catalogs.FL_Messages.AddToContext(Invocation.Context, 
                "CollaborationMessageId", CollaborationMessageId);
            Catalogs.FL_Messages.AddToContext(Invocation.Context, "Date", 
                SearchResult.Date);
            Catalogs.FL_Messages.AddToContext(Invocation.Context, "Text", 
                String(CollaborationMessage.Text));
            Catalogs.FL_Messages.AddToContext(Invocation.Context, "User", 
                String(CollaborationMessage.Author));
                
            Catalogs.FL_Messages.Route(Invocation, Exchange);
            
            Invocation.Context.Clear();
            
        EndIf;
        
    EndDo;
    
EndProcedure // SendMessageReplies()    

// Only for internal use.
//
Function QueryTextMessagesWithoutMatches()
    
    QueryText = "
        |SELECT
        |   ValueTable.SocialConversation AS SocialConversation,
        |   ValueTable.CollaborationMessageId AS CollaborationMessageId,
        |   ValueTable.Date AS Date
        |INTO CollaborationMessages
        |FROM
        |   &ValueTable AS ValueTable
        |INDEX BY
        |   ValueTable.SocialConversation
        |;
        |
        |////////////////////////////////////////////////////////////////////////////////
        |SELECT
        |   CollaborationMessages.SocialConversation AS SocialConversation,
        |   CollaborationMessages.CollaborationMessageId AS CollaborationMessageId,
        |   CollaborationMessages.Date AS Date 
        |FROM
        |   CollaborationMessages AS CollaborationMessages
        |
        |LEFT JOIN InformationRegister.SocialNetworks_Messages AS SocialMessages
        |ON SocialMessages.SocialConversation = CollaborationMessages.SocialConversation 
        |AND SocialMessages.CollaborationMessageId = CollaborationMessages.CollaborationMessageId
        |
        |WHERE
        |   SocialMessages.MessageId IS NULL
        |
        |ORDER BY
        |   Date ASC
        |;
        |
        |////////////////////////////////////////////////////////////////////////////////
        |DROP CollaborationMessages
        |;
        |
        |";
    Return QueryText;
    
EndFunction // QueryMessagesWithoutMatches()

#EndRegion // ServiceProceduresAndFunctions