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

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
    
#Region ProgramInterface

// Returns social network conversation.
//
// Parameters:
//  SocialUser - CatalogRef.SocialNetworks_Users - social user reference. 
//  ChatId     - String                          - social network chat id.
//
// Returns:
//  CatalogRef.SocialNetworks_Conversations - reference to the social conversation.  
//
Function SocialNetworkConversation(SocialUser, ChatId) Export
    
    Query = New Query;
    Query.Text = QueryTextSocialNetworkConversationByChatId();
    Query.SetParameter("ChatId", ChatId);
    Query.SetParameter("SocialUser", SocialUser);
    QueryResult = Query.Execute();
    SocialConversation = SocialConversationFromQueryResult(QueryResult);
    
    UserRef = FL_CommonUse.ObjectAttributeValue(SocialUser, "UserRef");
    If UserRef = Undefined OR UserRef.IsEmpty() Then
        
        If SocialConversation = Undefined Then
            
            SocialConversation = CreateSocialNetworkConversation(SocialUser, 
                UserRef, ChatId);
                
        EndIf;
   
    Else
        
        Query = New Query;
        Query.Text = QueryTextSocialNetworkConversationByUserRef();
        Query.SetParameter("UserRef", UserRef);
        QueryResult = Query.Execute();
        SocialConversationUR = SocialConversationFromQueryResult(QueryResult);
        
        If SocialConversation = Undefined
            AND SocialConversationUR = Undefined Then
            
            SocialConversation = CreateSocialNetworkConversation(SocialUser, 
                UserRef, ChatId);
                
        ElsIf SocialConversation <> Undefined 
            AND SocialConversationUR = Undefined Then
            
            UpdateSocialNetworkConversation(SocialConversation, SocialUser, 
                UserRef);
                
        ElsIf SocialConversation = Undefined
            AND SocialConversationUR <> Undefined Then
            
            SocialConversation = SocialConversationUR;
            UpdateSocialNetworkConversation(SocialConversation, SocialUser, 
                UserRef, ChatId);
                
        ElsIf SocialConversation <> SocialConversationUR Then
            
            UpdateSocialNetworkConversation(SocialConversationUR, SocialUser, 
                UserRef, ChatId);
            
            TransferMessages(SocialConversation, SocialConversationUR);
            
            SocialConversationObject = SocialConversation.GetObject();
            
            Try
                DataProcessors.FL_CollaborationSystem
                    .DeleteCollaborationSystemConversation(
                        SocialConversationObject.ConversationId);
            Except
            EndTry; 
            
            SocialConversationObject.Delete();
            
            SocialConversation = SocialConversationUR;
                
        EndIf;
        
    EndIf;
    
    Return SocialConversation;
    
EndFunction // SocialNetworkConversation()

// Returns a conversation by collaboration system conversation id.
//
// Parameters:
//  ConversationId - String - collaboration system conversation id.
//
// Returns:
//  CatalogRef.SocialNetworks_Conversations, Undefined - reference to the social conversation.
//
Function SocialNetworkConversationByConversationId(ConversationId) Export
    
    Query = New Query;
    Query.Text = QueryTextSocialNetworkConversationByConversationId();
    Query.SetParameter("ConversationId", ConversationId);
    QueryResult = Query.Execute();
    If QueryResult.IsEmpty() Then
        Return Undefined;
    EndIf;
    
    Return SocialConversationFromQueryResult(QueryResult);
    
EndFunction // SocialNetworkConversationByConversationId()
    
#EndRegion // ProgramInterface

#Region ServiceInterface

// Updates message pointer for social conversation.
//
// Parameters:
//  SocialConversation - CatalogRef.SocialNetworks_Conversations - social conversation.
//  MessagePointer     - String - a new messsage pointer for social conversation.
//
Procedure UpdateMessagePointer(SocialConversation, MessagePointer) Export
    
    ConversationObject = SocialConversation.GetObject();   
    ConversationObject.MessagePointer = MessagePointer;
    ConversationObject.Write();
    
EndProcedure // UpdateMessagePointer()

#EndRegion // ServiceInterface

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
Procedure TransferMessages(Source, Receiver)
    
    Query = New Query;
    Query.Text = QueryTextSocialNetworkConversationMessages();
    Query.SetParameter("SocialConversation", Source);
    ValueTable = Query.Execute().Unload();
    
    For Each Row In ValueTable Do
        
        InformationRegisters.SocialNetworks_Messages.DeleteSocialMessage(Row);
        Row.SocialConversation = Receiver;
        Row.CollaborationMessageId = Undefined;
        InformationRegisters.SocialNetworks_Messages.CreateSocialMessage(Row);
        
    EndDo;
    
EndProcedure // TransferMessages()

// Only for internal use.
//
Procedure UpdateSocialNetworkConversation(SocialConversation, SocialUser, 
    UserRef, ChatId = Undefined)
    
    Description = FL_CommonUse.ObjectAttributeValue(SocialUser, 
        "Description");
    
    ConversationObject = SocialConversation.GetObject();
    ConversationObject.Description = Description;
    ConversationObject.UserRef = UserRef;
    
    If ChatId <> Undefined Then
        Chat = ConversationObject.Chats.Add();
        Chat.ChatId = ChatId;
        Chat.SocialUser = SocialUser;    
    EndIf;
    
    ConversationObject.Write();
    
    DataProcessors.FL_CollaborationSystem
        .CollaborationSystemConversationUpdateTitle(
            ConversationObject.ConversationId, Description);
    
EndProcedure // UpdateSocialNetworkConversation()

// Only for internal use.
//
Function CreateSocialNetworkConversation(SocialUser, UserRef, ChatId)
    
    Description = FL_CommonUse.ObjectAttributeValue(SocialUser, 
        "Description");
    
    SocialConversation = Catalogs.SocialNetworks_Conversations.GetRef();
            
    Conversation = CollaborationSystem.CreateConversation();
    Conversation.Title = String(SocialUser);
    Conversation.Key = String(SocialConversation.UUID());
    Conversation.Write();
    
    ConversationObject = Catalogs.SocialNetworks_Conversations
        .CreateItem();
    ConversationObject.SetNewObjectRef(SocialConversation);
    ConversationObject.Description = Description;
    ConversationObject.ConversationId = String(Conversation.ID);
    ConversationObject.UserRef = UserRef;
    
    Chat = ConversationObject.Chats.Add();
    Chat.ChatId = ChatId;
    Chat.SocialUser = SocialUser;
    
    ConversationObject.Write();
    
    Return SocialConversation;
    
EndFunction // CreateSocialNetworkConversation()

// Only for internal use.
//
Function SocialConversationFromQueryResult(QueryResult)
    
    QueryResultSelection = QueryResult.Select();
    Return ?(QueryResultSelection.Next(), 
        QueryResultSelection.SocialConversation,
        Undefined);
    
EndFunction // SocialConversationFromQueryResult()

// Only for internal use.
//
Function QueryTextSocialNetworkConversationByUserRef()

    QueryText = "
        |SELECT
        |   Conversations.Ref AS SocialConversation
        |FROM
        |   Catalog.SocialNetworks_Conversations AS Conversations
        |WHERE
        |   Conversations.UserRef = &UserRef
        |";  
    Return QueryText;

EndFunction // QueryTextSocialNetworkConversationByUserRef()

// Only for internal use.
//
Function QueryTextSocialNetworkConversationByChatId()

    QueryText = "
        |SELECT
        |   Conversations.Ref AS SocialConversation
        |FROM
        |   Catalog.SocialNetworks_Conversations.Chats AS Conversations
        |WHERE
        |   Conversations.SocialUser = &SocialUser
        |AND Conversations.ChatId = &ChatId
        |";  
    Return QueryText;

EndFunction // QueryTextSocialNetworkConversationByChatId()

// Only for internal use.
//
Function QueryTextSocialNetworkConversationByConversationId()
    
    QueryText = "
        |SELECT
        |   Conversations.Ref AS SocialConversation
        |FROM
        |   Catalog.SocialNetworks_Conversations AS Conversations
        |WHERE
        |   Conversations.ConversationId = &ConversationId
        |";  
    Return QueryText;
    
EndFunction // QueryTextSocialNetworkConversationByConversationId() 

// Only for internal use.
//
Function QueryTextSocialNetworkConversationMessages()

    QueryText = "
        |SELECT
        |   Messages.SocialConversation AS SocialConversation,
        |   Messages.SocialUser AS SocialUser,
        |   Messages.ChatId AS ChatId,
        |   Messages.MessageId AS MessageId,
        |   """" AS CollaborationMessageId,
        |   Messages.Date AS Date,
        |   Messages.Incoming AS Incoming,
        |   Messages.Outgoing AS Outgoing,
        |   Messages.Text AS Text,
        |   Messages.User AS User
        |
        |FROM
        |   InformationRegister.SocialNetworks_Messages AS Messages
        |
        |WHERE
        |   Messages.SocialConversation = &SocialConversation
        |";  
    Return QueryText;

EndFunction // QueryTextSocialNetworkConversationMessages()

#EndRegion // ServiceProceduresAndFunctions

#EndIf