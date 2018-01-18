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

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
    
    If Parameters.Property("AutoTest") Then
        // Return if the form for analysis is received.
        Return;
    EndIf;
    
    // No dependencies.
    FormConstantsSet = FL_InteriorUse.SetOfConstants(ConstantsSet);
    
    License = GetCommonTemplate("FL_LICENSE");    
    Items.AcceptLicenseTerms.Visible = NOT Constants.FL_LicenseAccepted.Get();    
    
    // Update items states.
    SetEnabled();
    
EndProcedure // OnCreateAtServer()

#EndRegion // FormEventHandlers

#Region FormCommandHandlers

&AtClient
Procedure AcceptLicenseTerms(Command)
    
    ConstantsSet.FL_LicenseAccepted = True;
    
    Attachable_OnAttributeChange("ConstantsSet.FL_LicenseAccepted");
    
    If ConstantsSet.FL_LicenseAccepted Then
        Close();
    EndIf;
    
EndProcedure // AcceptLicenseTerms()

#EndRegion // FormCommandHandlers

#Region ServiceProceduresAndFunctions

&AtClient
Procedure Attachable_OnAttributeChange(AttributePathToData, 
    RefreshingInterface = True)

    Result = OnAttributeChangeServer(AttributePathToData);

    If RefreshingInterface Then
        RefreshInterface();
    EndIf;
    
    If Result.Property("NotificationForms") Then
        Notify(Result.NotificationForms.EventName, 
            Result.NotificationForms.Parameter, 
            Result.NotificationForms.Source);
    EndIf;

EndProcedure // Attachable_OnAttributeChange()

&AtServer
Function OnAttributeChangeServer(AttributePathToData)

    Result = New Structure;
    
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
    If ConstantName <> "" Then
        
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

&AtServer
Procedure SetEnabled(AttributePathToData = "")

    If AttributePathToData = "ConstantsSet.FL_LicenseAccepted" 
        OR IsBlankString(AttributePathToData) Then
        
        ConstantValue = ConstantsSet.FL_LicenseAccepted;
        
        FL_InteriorUse.SetFormItemProperty(Items, "AcceptLicenseTerms", 
            "Visible", NOT ConstantValue);
    
    EndIf;

EndProcedure // SetEnabled()

#EndRegion // ServiceProceduresAndFunctions