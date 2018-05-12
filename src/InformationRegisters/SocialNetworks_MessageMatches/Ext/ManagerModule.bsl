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

// Writes message match between collaboration system message and social network message.
//
// Parameters:
//  CSMessageID - String - collaboration system message ID.
//  SNMessageID - String - social network message id.
//                  Default value: "".
//
Procedure WriteMessageMatch(CSMessageID, SNMessageID = "") Export
    
    MessageMatch = NewMessageMatch();
    MessageMatch.CSMessageID = CSMessageID;
    MessageMatch.SNMessageID = SNMessageID;
    
    CreateMessageMatch(MessageMatch);
    
EndProcedure // WriteMessageMatch()

// Deletes message match between collaboration system message and social 
// network message.
//
// Parameters:
//  CSMessageID - String - collaboration system message ID.
//  SNMessageID - String - social network message id.
//
Procedure DeleteMessageMatch(CSMessageID, SNMessageID) Export
    
    RecordSet = InformationRegisters.SocialNetworks_MessageMatches
        .CreateRecordSet();    
    RecordSet.Filter.CSMessageID.Set(CSMessageID);
    RecordSet.Filter.SNMessageID.Set(SNMessageID);
    
    RecordSet.Write();
    
EndProcedure // DeleteMessageMatch()

// Returns new value table of matches.
//
// Returns:
//  ValueTable - with columns:
//      * Date        - Date   - message timestamp.
//      * CSMessageID - String - collaboration system message ID.
//      * SNMessageID - String - social network message id.
//
Function NewMessageMatchesValueTable() Export
    
    CSMessageIDLength = 36;
    SNMessageIDLength = 50;
    
    ValueTable = New ValueTable;
    ValueTable.Columns.Add("Date", FL_CommonUse.DateTypeDescription(
        DateFractions.DateTime));
    ValueTable.Columns.Add("CSMessageID", FL_CommonUse.StringTypeDescription(
        CSMessageIDLength));
    ValueTable.Columns.Add("SNMessageID", FL_CommonUse.StringTypeDescription(
        SNMessageIDLength));
   
    Return ValueTable;
    
EndFunction // NewMessageMatchesValueTable()

#EndRegion // ProgramInterface

#Region ServiceProceduresAndFunctions

// Creates message match between collaboration system message and social network message.
//
// Parameters:
//  MessageMatch - Strucute - see function InformationRegister.SocialNetworks_MessageMatches.NewMessageMatch.
//
Procedure CreateMessageMatch(MessageMatch)
    
    RecordSet = InformationRegisters.SocialNetworks_MessageMatches
        .CreateRecordSet();    
    RecordSet.Filter.CSMessageID.Set(MessageMatch.CSMessageID);
    RecordSet.Filter.SNMessageID.Set(MessageMatch.SNMessageID);
    
    FillPropertyValues(RecordSet.Add(), MessageMatch);
    
    RecordSet.Write();    
    
EndProcedure // CreateSocialMessage()

// Returns new message match.
//
// Returns:
//  Structure - with keys:
//      * CSMessageID - String - collaboration system message ID.
//      * SNMessageID - String - social network message id.
//
Function NewMessageMatch()
 
    MessageMatch = New Structure;
    MessageMatch.Insert("CSMessageID");
    MessageMatch.Insert("SNMessageID");    
    Return MessageMatch;
    
EndFunction // NewMessageMatch() 

#EndRegion // #Region ServiceProceduresAndFunctions

#EndIf
