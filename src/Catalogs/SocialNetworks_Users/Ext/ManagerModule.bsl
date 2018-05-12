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
    
    If ID = Undefined Then
        ID = Constants.SocialNetworks_UserIdentifier.Get();    
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
    
    // This method requires privileged mode.
    SetPrivilegedMode(True);
    Try
        CollaborationSystemUserID = CollaborationSystem.GetUserID(ID);
    Except
        CollaborationSystemUser = CollaborationSystem.CreateUser(InfoBaseUser);
        CollaborationSystemUser.Write();
        CollaborationSystemUserID = CollaborationSystemUser.ID;
    EndTry;
    
    Return CollaborationSystemUserID;
    
EndFunction // CollaborationSystemUserID()

// Returns social network user by user id.
//
// Parameters:
//  UserId        - String                 - social user id.
//  SocialNetwork - EnumRef.SocialNetworks - social network.
//  Description   - String                 - social user description.
//                          Default value: Undefined.
//  UserRef       - CatalogRef.Partners    - reference to partner.
//                          Default value: Undefined. 
//
// Returns:
//  CatalogRef.SocialNetworks_Users - reference to the social user.  
//
Function SocialNetworkUser(UserId, SocialNetwork, 
    Description = Undefined, UserRef = Undefined) Export
    
    Query = New Query;
    If TypeOf(UserId) = Type("String") Then
        Query.Text = QueryTextSocialNetworkByUserId();  
    EndIf;
    Query.SetParameter("UserId", UserId);
    Query.SetParameter("SocialNetwork", SocialNetwork);
    QueryResult = Query.Execute();
    If QueryResult.IsEmpty() Then
        SocialUser = CreateSocialNetworkUser(UserId, UserRef, SocialNetwork, 
            Description);    
    Else
        
        QueryResultSelection = QueryResult.Select();
        QueryResultSelection.Select();
        QueryResultSelection.Next();
        SocialUser = QueryResultSelection.SocialUser;
        If UserRef <> Undefined 
            AND QueryResultSelection.UserRef <> UserRef Then
            UpdateSocialNetworkUser(SocialUser, UserRef);        
        EndIf;
        
    EndIf;
    
    Return SocialUser;
    
EndFunction // SocialNetworkUser()

#EndRegion // ProgramInterface

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
Procedure UpdateSocialNetworkUser(SocialUser, UserRef)
    
    Description = FL_CommonUse.ObjectAttributeValue(UserRef, 
        "Description");
    
    SocialUserObject = SocialUser.GetObject();
    SocialUserObject.Description = Description;
    SocialUserObject.UserRef = UserRef;
    SocialUserObject.Write(); 
    
EndProcedure // UpdateSocialNetworkUser()

// Only for internal use.
//
Function CreateSocialNetworkUser(UserId, UserRef, SocialNetwork, 
    Val Description) 
    
    If UserRef <> Undefined Then
        Description = FL_CommonUse.ObjectAttributeValue(UserRef, 
            "Description");
    EndIf;
    
    SocialUserObject = Catalogs.SocialNetworks_Users.CreateItem();
    SocialUserObject.Description = Description;
    SocialUserObject.Following = True;
    SocialUserObject.SocialNetwork = SocialNetwork;
    SocialUserObject.UserId = UserId;
    SocialUserObject.UserRef = UserRef;
    SocialUserObject.Write();
    
    Return SocialUserObject.Ref;    
    
EndFunction // CreateSocialNetworkUser()

// Only for internal use.
//
Function QueryTextSocialNetworkByUserId()

    QueryText = "
        |SELECT
        |   Users.Ref AS SocialUser,
        |   Users.UserRef AS UserRef
        |FROM
        |   Catalog.SocialNetworks_Users AS Users
        |WHERE
        |   Users.UserId = &UserId
        |AND Users.SocialNetwork = &SocialNetwork
        |";  
    Return QueryText;

EndFunction // QueryTextSocialNetworkByUserId()

#EndRegion // ServiceProceduresAndFunctions

#EndIf