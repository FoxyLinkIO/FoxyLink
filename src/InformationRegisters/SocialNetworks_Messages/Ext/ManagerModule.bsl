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
    
EndProcedure // DeleteSocialMessage()

// Deserializes a social message.
//
// Parameters:
//  Payload    - BinaryData - serialized social message.
//  Properties - Structure  - see function Catalogs.FL_Exchanges.NewProperties.
//  JobResult  - Structure  - see function Catalogs.FL_Jobs.NewJobResult.
//                  Default value: Undefined.
//
// Returns:
//  Strucute - see function InformationRegister.SocialNetworks_Messages.NewSocialMessage. 
//
Function DeserializeSocialMessage(Payload, Properties, JobResult = Undefined) Export
    
    // #110 https://github.com/FoxyLinkIO/FoxyLink/issues/110
    JSONReader = New JSONReader;
    JSONReader.OpenStream(Payload.OpenStreamForRead(), 
        Properties.ContentEncoding);
    SocialMessage = ReadJSON(JSONReader);
    JSONReader.Close();
    
    MessagesMetadata = Metadata.InformationRegisters.SocialNetworks_Messages;
    Dimensions = MessagesMetadata.Dimensions;
    Resources = MessagesMetadata.Resources;
    Attributes = MessagesMetadata.Attributes;
    
    ProcessSocialAttribute(SocialMessage, Dimensions.SocialConversation, JobResult);
    ProcessSocialAttribute(SocialMessage, Dimensions.SocialUser, JobResult);
    ProcessSocialAttribute(SocialMessage, Resources.Date, JobResult);
    ProcessSocialAttribute(SocialMessage, Attributes.User, JobResult);
    
    Return SocialMessage;
    
EndFunction // DeserializeSocialMessage()
 
// Returns new social message.
//
// Returns:
//  Structure - with keys:
//      * SocialConversation     - CatalogRef.SocialNetworks_Conversations - social conversation.
//      * SocialUser             - CatalogRef.SocialNetworks_Users         - social user.
//      * ChatId                 - String                                  - chat identifier.
//      * MessageId              - String                                  - message identifier.
//      * ConversationId         - String                                  - сollaboration system conversation ID
//      * CollaborationMessageId - String                                  - сollaboration system message ID.
//      * Date                   - Date                                    - message creation date.
//      * Incoming               - Boolean                                 - if True it is income message.
//                                          Default value: False.
//      * Outgoing               - Boolean                                 - if True it is outgoing message.
//                                          Default value: False.
//      * Text                   - String                                  - message body.
//      * User                   - CatalogRef.Users                        - Information base user.
//
Function NewSocialMessage() Export
 
    SocialMessage = New Structure;
    SocialMessage.Insert("SocialConversation");
    SocialMessage.Insert("SocialUser");
    SocialMessage.Insert("ChatId");
    SocialMessage.Insert("MessageId");
    SocialMessage.Insert("ConversationId");
    SocialMessage.Insert("CollaborationMessageId");
    SocialMessage.Insert("Date");
    SocialMessage.Insert("Incoming", False);
    SocialMessage.Insert("Outgoing", False);
    SocialMessage.Insert("Text");
    SocialMessage.Insert("User");
    
    Return SocialMessage;
    
EndFunction // NewSocialMessage() 

#EndRegion // ProgramInterface

#Region ServiceInterface

// Returns new value table of matches.
//
// Returns:
//  ValueTable - with columns:
//      * Date                   - Date   - message timestamp.
//      * MessageId              - String - collaboration system message ID.
//      * CollaborationMessageId - String - social network message id.
//
Function NewMessageMatchesValueTable() Export
    
    MessageIdLength = 36;
    CollaborationMessageIdLength = 50;
    
    ValueTable = New ValueTable;
    ValueTable.Columns.Add("SocialConversation", 
        New TypeDescription("CatalogRef.SocialNetworks_Conversations"));
    ValueTable.Columns.Add("Date", FL_CommonUse.DateTypeDescription(
        DateFractions.DateTime));
    ValueTable.Columns.Add("MessageId", FL_CommonUse.StringTypeDescription(
        MessageIdLength));
    ValueTable.Columns.Add("CollaborationMessageId", 
        FL_CommonUse.StringTypeDescription(CollaborationMessageIdLength));
   
    Return ValueTable;
    
EndFunction // NewMessageMatchesValueTable()

#EndRegion // ServiceInterface

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
Procedure ProcessSocialAttribute(SocialMessage, Attribute, JobResult)
    
    Var Value;
    
    ErrorMessages = New Array;
    If SocialMessage.Property(Attribute.Name, Value) Then
        
        ConversionResult = FL_CommonUse.ConvertValueIntoPlatformObject(
            Value, Attribute.Type.Types());
        
        If ConversionResult.TypeConverted Then
            SocialMessage[Attribute.Name] = ConversionResult.ConvertedValue;
        Else
            
            FL_ErrorsClientServer.PersonalizeErrorsWithKey(
                ConversionResult.ErrorMessages, ErrorMessages, Attribute.Name);
            
            FL_InteriorUse.WriteLog(
                "InformationRegisters.SocialNetworks_Messages.DeserializeSocialMessage",
                EventLogLevel.Error,
                Metadata.InformationRegisters.SocialNetworks_Messages,
                ErrorMessages,
                JobResult);
                
        EndIf;
        
    EndIf;    
    
EndProcedure // ProcessSocialAttribute()

#EndRegion // ServiceProceduresAndFunctions

#EndIf