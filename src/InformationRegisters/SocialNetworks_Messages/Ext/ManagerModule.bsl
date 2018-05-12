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

// Creates social message.
//
// Parameters:
//  SocialMessage - Strucute - see function InformationRegister.SocialNetworks_Messages.NewSocialMessage.
//
Procedure CreateSocialMessage(SocialMessage) Export
    
    Conversation = Catalogs.SocialNetworks_Conversations
        .CollaborationSystemConversation(SocialMessage.SocialConversation);
    If Conversation = Undefined Then 
        
        Raise NStr(
                "en='Failed to find collaboration system conversation.';
                |ru='Не удалось найти обсуждение системы взаимодействия.';
                |uk='Не вдалось знайти обговорення системи взаємодії.';
                |en_CA='Failed to find collaboration system conversation.'");
        
    EndIf;
    
    If NOT ValueIsFilled(SocialMessage.CSMessageID) Then
        
        SetPrivilegedMode(True);
        
        Message = CollaborationSystem.CreateMessage(Conversation.ID);
        Message.Author = Catalogs.SocialNetworks_Users.CollaborationSystemUserID();
        FillPropertyValues(Message, SocialMessage);
        Message.Write();
        
        SetPrivilegedMode(False);
        
        SocialMessage.CSMessageID = String(Message.ID);
        
    EndIf;
    
    InformationRegisters.SocialNetworks_MessageMatches.WriteMessageMatch(
        SocialMessage.CSMessageID, SocialMessage.MessageId);
    
    RecordSet = InformationRegisters.SocialNetworks_Messages.CreateRecordSet();    
    RecordSet.Filter.SocialConversation.Set(SocialMessage.SocialConversation);
    RecordSet.Filter.SocialUser.Set(SocialMessage.SocialUser);
    RecordSet.Filter.ChatId.Set(SocialMessage.ChatId);
    RecordSet.Filter.MessageId.Set(SocialMessage.MessageId);
    
    FillPropertyValues(RecordSet.Add(), SocialMessage);
    
    RecordSet.Write();    
    
EndProcedure // CreateSocialMessage()

// Deletes social message.
//
// Parameters:
//  SocialMessage - Strucute - see function InformationRegister.SocialNetworks_Messages.NewSocialMessage.
//
Procedure DeleteSocialMessage(SocialMessage) Export
    
    RecordSet = InformationRegisters.SocialNetworks_Messages.CreateRecordSet();
    RecordSet.Filter.SocialConversation.Set(SocialMessage.SocialConversation);
    RecordSet.Filter.SocialUser.Set(SocialMessage.SocialUser);
    RecordSet.Filter.ChatId.Set(SocialMessage.ChatId);
    RecordSet.Filter.MessageId.Set(SocialMessage.MessageId);
    RecordSet.Write();
    
    If ValueIsFilled(SocialMessage.CSMessageID) Then
        
        InformationRegisters.SocialNetworks_MessageMatches.DeleteMessageMatch(
            SocialMessage.CSMessageID, SocialMessage.MessageId);
            
        SetPrivilegedMode(True);
        
        Try
            CollaborationSystem.DeleteMessage(New CollaborationSystemMessageID(
                SocialMessage.CSMessageID));
        Except
        EndTry;
            
        SetPrivilegedMode(False);
        
    EndIf;
    
EndProcedure // DeleteSocialMessage()

// Returns new social message.
//
// Returns:
//  Structure - with keys:
//      * SocialConversation - CatalogRef.SocialNetworks_Conversations - social conversation.
//      * SocialUser         - CatalogRef.SocialNetworks_Users         - social user.
//      * ChatId             - String                                  - chat identifier.
//      * MessageId          - String                                  - message identifier.
//      * Date               - Date                                    - message creation date.
//      * Incoming           - Boolean                                 - if True it is income message.
//      * Outgoing           - Boolean                                 - if True it is outgoing message.
//      * Text               - String                                  - message body.
//      * User               - CatalogRef.Users                        - Information base user.
//      * CSMessageID        - String                                  - сollaboration system message ID.
//
Function NewSocialMessage() Export
 
    SocialMessage = New Structure;
    SocialMessage.Insert("SocialConversation");
    SocialMessage.Insert("SocialUser");
    SocialMessage.Insert("ChatId");
    SocialMessage.Insert("MessageId");
    SocialMessage.Insert("Date");
    SocialMessage.Insert("Incoming");
    SocialMessage.Insert("Outgoing");
    SocialMessage.Insert("Text");
    SocialMessage.Insert("User");
    SocialMessage.Insert("CSMessageID");
    
    Return SocialMessage;
    
EndFunction // NewSocialMessage() 

#EndRegion // ProgramInterface

#EndIf