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
// along with FoxyLink. If not, see <http://www.gnu.org/licenses/agpl-3.0>.
//
////////////////////////////////////////////////////////////////////////////////

#Region VariablesDescription

&AtClient
Var RefreshInterface;

#EndRegion // VariablesDescription

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
    
    If Parameters.Property("AutoTest") Then
        // Return if the form for analysis is received.
        Return;
    EndIf;
    
    // No dependencies.
    FormConstantsSet = FL_InteriorUse.SetOfConstants(ConstantsSet);
    
EndProcedure // OnCreateAtServer()

#EndRegion // FormEventHandlers

#Region FormItemsEventHandlers

&AtClient
Procedure SocialNetworks_UserIdentifierOnChange(Item)
    
    Attachable_OnAttributeChange(Item, False);
    
EndProcedure // SocialNetworks_UserIdentifierOnChange()

&AtClient
Procedure SocialNetworks_UserIdentifierStartChoice(Item, ChoiceData, 
    StandardProcessing)
    
    ShowChooseFromList(New NotifyDescription("DoAfterChooseUser",
        ThisObject), AvailableUsers(), Items.SocialNetworks_UserIdentifier);
    
EndProcedure // SocialNetworks_UserIdentifierStartChoice()

#EndRegion // FormItemsEventHandlers

#Region ServiceProceduresAndFunctions

// Sets a new user to the constant SocialNetworks_UserIdentifier.
//
// Parameters:
//  SelectedElement      - ValueListItem - the selected list item or Undefined 
//                                          if the user has not selected anything. 
//  AdditionalParameters - Arbitrary     - the value specified when the 
//                                          NotifyDescription object was created.  
//
&AtClient
Procedure DoAfterChooseUser(SelectedElement, 
    AdditionalParameters) Export
    
    If SelectedElement <> Undefined Then
        
        FillCollaborationSystemUserID(SelectedElement.Value);
        ConstantsSet.SocialNetworks_UserIdentifier = SelectedElement.Value; 
        SocialNetworks_UserIdentifierOnChange(
            Items.SocialNetworks_UserIdentifier);
            
    EndIf;
    
EndProcedure // DoAfterChooseUser()

// Only for internal use.
//
&AtServer
Procedure FillCollaborationSystemUserID(Value)
    
    Catalogs.SocialNetworks_Users.CollaborationSystemUserID(Value);
    
EndProcedure // FillCollaborationSystemUserID()

// Only for internal use.
//
&AtClient
Procedure Attachable_OnAttributeChange(Item, RefreshingInterface = True)

    Result = OnAttributeChangeServer(Item.Name);

    If RefreshingInterface Then
        AttachIdleHandler("RefreshApplicationInterface", 1, True);
        RefreshInterface = True;
    EndIf;

    If Result.Property("NotificationForms") Then
        Notify(Result.NotificationForms.EventName, 
            Result.NotificationForms.Parameter, 
            Result.NotificationForms.Source);
    EndIf;

EndProcedure // Attachable_OnAttributeChange()

// Only for internal use.
//
&AtClient
Procedure RefreshApplicationInterface()

    If RefreshInterface Then
        RefreshInterface = False;
        FL_InteriorUseClient.RefreshApplicationInterface();
    EndIf;

EndProcedure // RefreshApplicationInterface()

// Only for internal use.
//
&AtServer
Function OnAttributeChangeServer(ItemName)

    Result = New Structure;
    
    AttributePathToData = Items[ItemName].DataPath;
    
    SaveAttributeValue(AttributePathToData, Result);
    
    RefreshReusableValues();
    
    Return Result;

EndFunction // OnAttributeChangeServer()

// Only for internal use.
//
&AtServer
Procedure SaveAttributeValue(AttributePathToData, Result)

    // Save attribute values not connected with constants directly.
    If AttributePathToData = "" Then
        Return;
    EndIf;

    // Definition of constant name.
    ConstantName = "";
    If Lower(Left(AttributePathToData, 13)) = Lower("ConstantsSet.") Then
        // If the path to attribute data is specified through "ConstantsSet".
        ConstantName = Mid(AttributePathToData, 14);
    Else
        
        // Definition of name and attribute value record in the corresponding 
        // constant from "ConstantsSet".
        // Used for the attributes of the form directly connected with constants.
        
    EndIf;

    // Saving the constant value.
    If NOT IsBlankString(ConstantName) Then
        
        ConstantManager = Constants[ConstantName];
        ConstantValue = ConstantsSet[ConstantName];
        If ConstantManager.Get() <> ConstantValue Then
            ConstantManager.Set(ConstantValue);
        EndIf;
        
        NotificationForms = New Structure("EventName, Parameter, Source",
            "Record_ConstantsSet", New Structure, ConstantName);
        Result.Insert("NotificationForms", NotificationForms);
        
    EndIf;
    
EndProcedure // SaveAttributeValue()

// Only for internal use.
//
&AtServer
Function AvailableUsers()
    
    AvailableUsers = New ValueList;
    
    Users = InfoBaseUsers.GetUsers();
    For Each User In Users Do
        AvailableUsers.Add(User.UUID, User.FullName);   
    EndDo;
    
    Return AvailableUsers;
    
EndFunction // AvailableUsers()

#EndRegion // ServiceProceduresAndFunctions