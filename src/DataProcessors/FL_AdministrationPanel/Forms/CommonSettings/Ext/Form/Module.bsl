////////////////////////////////////////////////////////////////////////////////
// This file is part of FoxyLink.
// Copyright © 2016-2017 Petro Bazeliuk.
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
        Return;
    EndIf;
    
    // No dependencies.
    FormConstantsSet = FL_InteriorUse.SetOfConstants(ConstantsSet);
    
    // Update items states.
    SetEnabled();

EndProcedure // OnCreateAtServer()

#EndRegion // FormEventHandlers

#Region FormItemsEventHandlers

&AtClient
Procedure FL_UseFoxyLinkOnChange(Item)
    
    Attachable_OnAttributeChange(Item, True);
    
EndProcedure // FL_UseFoxyLinkOnChange()

&AtClient
Procedure FL_WorkerCountOnChange(Item)
    
    Attachable_OnAttributeChange(Item, False);    
    
EndProcedure // FL_WorkerCountOnChange()

&AtClient
Procedure FL_RetryAttemptsOnChange(Item)
    
    Attachable_OnAttributeChange(Item, False);
    
EndProcedure // FL_RetryAttemptsOnChange()

#EndRegion // FormItemsEventHandlers

#Region ServiceProceduresAndFunctions

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

&AtClient
Procedure RefreshApplicationInterface()

    If RefreshInterface Then
        RefreshInterface = False;
        FL_InteriorUseClient.RefreshApplicationInterface();
    EndIf;

EndProcedure // RefreshApplicationInterface()

&AtServer
Function OnAttributeChangeServer(ItemName)

    Result = New Structure;
    
    AttributePathToData = Items[ItemName].DataPath;
    
    SaveAttributeValue(AttributePathToData, Result);
    
    SetEnabled(AttributePathToData);
    
    RefreshReusableValues();
    
    Return Result;

EndFunction // OnAttributeChangeServer()

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
    
    If ConstantName = "FL_UseFoxyLink" AND ConstantValue Then
        FL_InteriorUse.InitializeSubsystem();
    EndIf;

EndProcedure // SaveAttributeValue()

&AtServer
Procedure SetEnabled(AttributePathToData = "")

    If AttributePathToData = "ConstantsSet.FL_UseFoxyLink" 
        OR IsBlankString(AttributePathToData) Then
        
        ConstantValue = ConstantsSet.FL_UseFoxyLink;
        
        FL_InteriorUse.SetFormItemProperty(Items, "GroupJobServer", 
            "ReadOnly", NOT ConstantValue);
    
    EndIf;

EndProcedure // SetEnabled()

#EndRegion // ServiceProceduresAndFunctions