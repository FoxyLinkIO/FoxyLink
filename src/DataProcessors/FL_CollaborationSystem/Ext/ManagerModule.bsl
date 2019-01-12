////////////////////////////////////////////////////////////////////////////////
// This file is part of FoxyLink.
// Copyright © 2018-2019 Petro Bazeliuk.
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

#Region ProgramInterface

// Returns reference to the user.
//
// Parameters:
//  ID - String - ID of the collaboration system user. 
//
// Returns:
//  CatalogRef.User - reference to the infobase user object.
//
Function UserByCollaborationSystemUserID(ID) Export
    
    // Collaboration methods requires privileged mode.
    SetPrivilegedMode(True);
    
    UUID = CollaborationSystem.GetInfoBaseUserID(
        New CollaborationSystemUserID(ID));
    User = User(UUID);
    If User = Undefined OR User.IsEmpty() Then
        User = Constants.SocialNetworks_DefaultUser.Get();
    EndIf;
    
    Return User;
    
EndFunction // UserByCollaborationSystemUserID()

// Returns a CollaborationSystemUserID object.
// 
// Parameters:
//  ID - UUID      - unique ID of the infobase user.
//     - String    - unique ID of the infobase user in string presentation.
//     - Undefined - default unique ID of the infobase user.
// 
// Returns:
//  CollaborationSystemUserID - a CollaborationSystemUserID object.
//
Function CollaborationSystemUserID(Val ID = Undefined) Export
    
    // Collaboration methods requires privileged mode.
    SetPrivilegedMode(True);
    
    If ID = Undefined Then
        ID = UserId(); 
    EndIf;
    
    If TypeOf(ID) = Type("String") Then
        
        SupportedTypes = New Array;
        SupportedTypes.Add(Type("UUID"));
        ConversionResult = FL_CommonUse.ConvertValueIntoPlatformObject(ID, 
            SupportedTypes);
        If NOT ConversionResult.TypeConverted Then       
            Return Undefined;
        EndIf;
        
        ID = ConversionResult.ConvertedValue; 
            
    EndIf;
    
    InfoBaseUser = Undefined;
    If TypeOf(ID) = Type("UUID") Then
        InfoBaseUser = InfoBaseUsers.FindByUUID(ID);    
    EndIf;
    
    If InfoBaseUser = Undefined Then
        Return Undefined;
    EndIf;
    
    Try
        CollaborationSystemUserID = CollaborationSystem.GetUserID(ID);
    Except
        CollaborationSystemUser = CollaborationSystem.CreateUser(InfoBaseUser);
        CollaborationSystemUser.Write();
        CollaborationSystemUserID = CollaborationSystemUser.ID;
    EndTry;
    
    Return CollaborationSystemUserID;
    
EndFunction // CollaborationSystemUserID()

// Adds a new member to the collaboration system conversation.
//
// Parameters:
//  ConversationId - String    - a conversation ID.
//  ID             - UUID      - unique ID of the infobase user.
//                 - String    - unique ID of the infobase user in string presentation.
//  SocialMessage  - Structure - InformationRegisters.SocialNetworks_Messages.NewSocialMessage.
//
Procedure CollaborationSystemConversationAddMember(ConversationId, ID, 
    SocialMessage) Export
    
    // Collaboration methods requires privileged mode.
    SetPrivilegedMode(True);
    
    Conversation = CollaborationSystemConversation(ConversationId); 
    Conversation.Members.Add(CollaborationSystemUserID(ID));
    Conversation.Write();
    
    SocialMessage.User = User(ID);
    InformationRegisters.SocialNetworks_Messages.CreateSocialMessage(
        SocialMessage);   
    
EndProcedure // CollaborationSystemConversationAddMember()

// Updates collaboration system conversation title.
//
// Parameters:
//  ConversationId - String - a conversation ID.
//  Title          - String - new title of conversation.
//
Procedure CollaborationSystemConversationUpdateTitle(ConversationId, 
    Title) Export
    
    // Collaboration methods requires privileged mode.
    SetPrivilegedMode(True);
    
    Conversation = CollaborationSystemConversation(ConversationId);
    Conversation.Title = Title;
    Conversation.Write();   
    
EndProcedure // CollaborationSystemConversationUpdateTitle()

// Deletes all messages in collaboration system conversation and members.
//
// Parameters:
//  ConversationId - String - a conversation ID. 
//
Procedure DeleteCollaborationSystemConversation(ConversationId) Export
    
    // Collaboration methods requires privileged mode.
    SetPrivilegedMode(True);
    
    Filter = New CollaborationSystemMessagesFilter();
    Filter.Conversation = New CollaborationSystemConversationID(
        ConversationId);
    CollaborationMessages = CollaborationSystemMessages(Filter);
    For Each CollaborationMessage In CollaborationMessages Do
        CollaborationSystem.DeleteMessage(CollaborationMessage.ID);   
    EndDo;
    
    //Conversation = CollaborationSystemConversation(ConversationId);
    //Conversation.Members.Clear();
    //Conversation.Write();
    
EndProcedure // DeleteCollaborationSystemConversation()

// Returns a conversation by ID. 
//
// Parameters:
//  ConversationId - String - a conversation ID.
//
// Returns:
//  CollaborationSystemConversation - colaboration system conversation.
//
Function CollaborationSystemConversation(ConversationId) Export
    
    // Collaboration methods requires privileged mode.
    SetPrivilegedMode(True);
    
    CSConversationID = New CollaborationSystemConversationID(ConversationId);
    Return CollaborationSystem.GetConversation(CSConversationID); 
    
EndFunction // CollaborationSystemConversation()

// Returns the list of conversations that meet the specified filter criteria. 
//
// Parameters:
//  Filter - CollaborationSystemConversationsFilter - contains filter and sorting settings. 
//
// Returns:
//  CollaborationSystemConversation - objects array of the CollaborationSystemConversation type.
//
Function CollaborationSystemConversations(Filter) Export
    
    // Collaboration methods requires privileged mode.
    SetPrivilegedMode(True);
    
    CollaborationConversations = CollaborationSystem.GetConversations(Filter);
    Return CollaborationConversations; 
    
EndFunction // CollaborationSystemConversation()

// Returns a collaboration system message.
//
// Parameters:
//  SocialMessage - Structure - InformationRegisters.SocialNetworks_Messages.NewSocialMessage.
//
// Returns:
//  CollaborationSystemMessage - a message in a discussion.
//
Function CollaborationSystemMessage(SocialMessage) Export
    
    Var UserId;
    
    // Collaboration methods requires privileged mode.
    SetPrivilegedMode(True);
    
    UserId = UserId(SocialMessage.User);
    
    CollaborationMessage = CollaborationSystem.CreateMessage(
        New CollaborationSystemConversationID(SocialMessage.ConversationId));
    CollaborationMessage.Author = CollaborationSystemUserID(UserId);
    FillPropertyValues(CollaborationMessage, SocialMessage);
    CollaborationMessage.Write();
    
    SocialMessage.CollaborationMessageId = String(CollaborationMessage.ID);
    InformationRegisters.SocialNetworks_Messages.CreateSocialMessage(
        SocialMessage);
        
    Return CollaborationMessage;
    
EndFunction // CollaborationSystemMessage()

// Returns a collaboration system messages.
//
// Parameters:
//  Filter - CollaborationSystemMessagesFilter - contains the specified filtering 
//                                               and sorting values to receive 
//                                               messages of the collaboration system.
//
// Returns:
//  Array - objects array of the CollaborationSystemMessage type.
//
Function CollaborationSystemMessages(Filter) Export
    
    // Collaboration methods requires privileged mode.
    SetPrivilegedMode(True);
    
    CollaborationMessages = CollaborationSystem.GetMessages(Filter);   
    Return CollaborationMessages;
    
EndFunction // CollaborationSystemMessages()

#EndRegion // ProgramInterface

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
Function User(UUID) 
    
    Query = New Query;

    ConfigurationName = Metadata.Name;
    If Upper(ConfigurationName) = Upper("УправлениеТорговлей") Then
        Query.Text = QueryTextUser_TradeManagement();
    EndIf;
    
    Query.SetParameter("UUID", UUID);
    QueryResultSelection = Query.Execute().Select();
    Return ?(QueryResultSelection.Next(), 
        QueryResultSelection.User,
        Undefined);
    
EndFunction // User() 

// Only for internal use.
//
Function UserId(User = Undefined) 
    
    If User = Undefined OR User.IsEmpty() Then
        User = Constants.SocialNetworks_DefaultUser.Get();    
    EndIf;
    
    ConfigurationName = Metadata.Name;
    If Upper(ConfigurationName) = Upper("УправлениеТорговлей") 
        AND TypeOf(User) = Type("CatalogRef.Пользователи") 
        AND NOT User.IsEmpty() Then
        
        UserId = FL_CommonUse.ObjectAttributeValue(User, 
            "ИдентификаторПользователяИБ");      
        
    EndIf;
    
    Return UserId;
    
EndFunction // UserId() 

// Only for internal use.
//
Function QueryTextUser_TradeManagement() 
 
    QueryText = "
        |SELECT
        |   Users.Ref AS User
        |FROM
        |   Catalog.Пользователи AS Users
        |WHERE
        |   Users.ИдентификаторПользователяИБ = &UUID
        |";
    Return QueryText;   
    
EndFunction // QueryTextUser_TradeManagement()
    
#EndRegion // ServiceProceduresAndFunctions

#EndIf