////////////////////////////////////////////////////////////////////////////////
// This file is part of FoxyLink.
// Copyright © 2016-2020 Petro Bazeliuk.
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
    
    // File functions.
    MaximumMessageSize = FL_InteriorUseReUse.MaximumMessageSize() / 1024;
    JobExpirationTimeout = FL_InteriorUseReUse.JobExpirationTimeout() 
        / FL_InteriorUseReUse.DayInMilliseconds();
    
    Integrations = Catalogs.FL_Channels.SuppliedIntegrations();
    FL_CommonUseClientServer.ExtendValueTable(Integrations, 
        SuppliedIntegrations);
    
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
Procedure FL_AppIdentifierOnChange(Item)
    
    Attachable_OnAttributeChange(Item, False);
    
EndProcedure // FL_AppIdentifierOnChange()

&AtClient
Procedure MaximumMessageSizeOnChange(Item)
    
    If MaximumMessageSize = 0 Then
        ErrorMessage = NStr("
            |en='Field {Maximum message size} is empty.';
            |ru='Поле {Максимальный размер сообщения} не заполнено.';
            |uk='Поле {Максимальний розмір повідомлення} не заповнено.';
            |en_CA='Field {Maximum message size} is empty.'");
        FL_CommonUseClientServer.NotifyUser(ErrorMessage, , "MaximumMessageSize");
        Return;
    EndIf;

    Attachable_OnAttributeChange(Item, False);

EndProcedure // MaximumMessageSizeOnChange()

&AtClient
Procedure FL_RetryAttemptsOnChange(Item)
    
    Attachable_OnAttributeChange(Item, False);
    
EndProcedure // FL_RetryAttemptsOnChange()

&AtClient
Procedure FL_WorkerCountOnChange(Item)
    
    Attachable_OnAttributeChange(Item, False);    
    
EndProcedure // FL_WorkerCountOnChange()

&AtClient
Procedure JobExpirationTimeoutOnChange(Item)
    
    If JobExpirationTimeout = 0 Then
        ErrorMessage = NStr("
            |en='Field {Job expiration timeout} is empty.';
            |ru='Поле {Тайм-аут удаления заданий } не заполнено.';
            |uk='Поле {Тайм-аут видалення завдань} не заповнено.';
            |en_CA='Field {Job expiration timeout} is empty.'");
        FL_CommonUseClientServer.NotifyUser(ErrorMessage, , "JobExpirationTimeout");
        Return;
    EndIf;

    Attachable_OnAttributeChange(Item, False);
    
EndProcedure // JobExpirationTimeoutOnChange()

&AtClient
Procedure FL_WorkerJobsLimitOnChange(Item)
    
    Attachable_OnAttributeChange(Item, False);
    
EndProcedure // FL_WorkerJobsLimitOnChange()

&AtClient
Procedure SuppliedIntegrationsOnActivateRow(Item)
    
    CurrentData = Item.CurrentData; 
    If CurrentData <> Undefined Then
        Items.Tooltip.Title = CurrentData.Tooltip;
    EndIf;
    
EndProcedure // SuppliedIntegrationsOnActivateRow()

#EndRegion // FormItemsEventHandlers

#Region FormCommandHandlers

&AtClient
Procedure InstallIntegration(Command)
    
    CurrentData = Items.SuppliedIntegrations.CurrentData;
    If CurrentData <> Undefined Then
        
        OpenForm("Catalog.FL_Exchanges.Form.ImportForm",
            New Structure("LibraryGuid, Template", CurrentData.LibraryGuid, 
                CurrentData.Template),
            ThisObject,
            ,
            ,
            ,
            ,
            FormWindowOpeningMode.LockOwnerWindow);

    EndIf;
    
EndProcedure // InstallIntegration() 

#EndRegion // FormCommandHandlers

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
        If AttributePathToData = "MaximumMessageSize" Then
            ConstantsSet.FL_MaximumMessageSize = MaximumMessageSize * 1024;
            ConstantName = "FL_MaximumMessageSize";
        ElsIf AttributePathToData = "JobExpirationTimeout" Then
            ConstantsSet.FL_JobExpirationTimeout = JobExpirationTimeout 
                * FL_InteriorUseReUse.DayInMilliseconds();
            ConstantName = "FL_JobExpirationTimeout";
        EndIf;
        
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
        
        FL_ConfigurationUpdate.UpdateSubsystem();
        Read();
        
    EndIf;

EndProcedure // SaveAttributeValue()

&AtServer
Procedure SetEnabled(AttributePathToData = "")

    If AttributePathToData = "ConstantsSet.FL_UseFoxyLink" 
        OR IsBlankString(AttributePathToData) Then
        
        ConstantValue = ConstantsSet.FL_UseFoxyLink;
         
        FL_InteriorUse.SetFormItemProperty(Items, "GroupAppSettings", 
            "Visible", ConstantValue);
        FL_InteriorUse.SetFormItemProperty(Items, "GroupJobServer", 
            "Visible", ConstantValue);
        FL_InteriorUse.SetFormItemProperty(Items, "GroupSuppliedIntegrations", 
            "Visible", ConstantValue);
    
    EndIf;

EndProcedure // SetEnabled()

#EndRegion // ServiceProceduresAndFunctions