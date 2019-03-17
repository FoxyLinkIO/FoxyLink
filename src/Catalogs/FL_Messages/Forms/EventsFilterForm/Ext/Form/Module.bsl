////////////////////////////////////////////////////////////////////////////////
// This file is part of FoxyLink.
// Copyright © 2016-2019 Petro Bazeliuk.
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
     
    Parameters.Property("DataCompositionSchemaAddress", 
        DataCompositionSchemaAddress);
    Parameters.Property("DataCompositionSettingsAddress", 
        DataCompositionSettingsAddress);
    Parameters.Property("EventSource", EventSource);
    
    // It's needed to create a new data composition schema for event source.
    If NOT ValueIsFilled(Parameters.DataCompositionSchemaAddress) Then
        
        DataCompositionSchema = FL_DataComposition
            .CreateEventSourceDataCompositionSchema(EventSource, 1, True);   
        DataCompositionSchemaAddress = PutToTempStorage(DataCompositionSchema, 
            UUID);
            
    Else

        FL_DataComposition.CopyDataCompositionSchema(
            DataCompositionSchemaAddress,
            Parameters.DataCompositionSchemaAddress);        
         
    EndIf;
 
    // It isn't error, we have to continue loading event filter form to fix
    // bugs if configuration is changed.
    Try
        
        FL_DataComposition.InitSettingsComposer(ComposerSettings, 
            DataCompositionSchemaAddress, DataCompositionSettingsAddress);
            
    Except
        
        FL_CommonUseClientServer.NotifyUser(ErrorDescription());    
        
    EndTry;      
        
EndProcedure // OnCreateAtServer() 

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
    
    #If ThickClientOrdinaryApplication Or ThickClientManagedApplication Then
        
    If TypeOf(ChoiceSource) = Type("DataCompositionSchemaWizard")
        AND TypeOf(SelectedValue) = Type("DataCompositionSchema") Then
        
        UpdateDataCompositionSchema(SelectedValue);    
        
    EndIf;
        
    #EndIf
    
EndProcedure // ChoiceProcessing()

#EndRegion // FormEventHandlers 

#Region FormItemsEventHandlers

&AtClient
Procedure ComposerSettingsFilterAvailableFieldsSelection(Item, SelectedRow, 
    Field, StandardProcessing)
    
    Modified = True;
    
EndProcedure // ComposerSettingsFilterAvailableFieldsSelection()

&AtClient
Procedure ComposerSettingsFilterOnChange(Item)
    
    Modified = True;
    
EndProcedure // ComposerSettingsFilterOnChange()

#EndRegion // FormItemsEventHandlers

#Region FormCommandHandlers

&AtClient
Procedure DeleteEventFilter(Command)
    
    Close(NewClosureResult());
    
EndProcedure // DeleteEventFilter()

&AtClient
Procedure EditDataCompositionSchema(Command)
    
    FL_DataCompositionClient.RunDataCompositionSchemaWizard(ThisObject,
        DataCompositionSchemaAddress);
    
EndProcedure // EditDataCompositionSchema()

&AtClient
Procedure SaveAndClose(Command)
   
    Close(CreateClosureResult(ThisObject.FormOwner.UUID));
    
EndProcedure // SaveAndClose()

#EndRegion // FormCommandHandlers

#Region ServiceProceduresAndFunctions

// Applies changes to data composition schema.
//
// Parameters:
//  DataCompositionSchema - DataCompositionSchema - updated data composition schema.
//
&AtServer
Procedure UpdateDataCompositionSchema(DataCompositionSchema)

    Changes = False;
    FL_DataComposition.CopyDataCompositionSchema(
        DataCompositionSchemaAddress, 
        DataCompositionSchema, 
        True, 
        Changes);

    Modified = Modified Or Changes;
   
    If Changes Then
        
        // Init data composer by new data composition schema.
        FL_DataComposition.InitSettingsComposer(ComposerSettings, 
            DataCompositionSchemaAddress);

    EndIf;

EndProcedure // UpdateDataCompositionSchema()

&AtServer
Function CreateClosureResult(Val OwnerUUID)

    ClosureResult = NewClosureResult();
    ClosureResult.DataCompositionSchemaAddress = PutToTempStorage(
        GetFromTempStorage(DataCompositionSchemaAddress), OwnerUUID);
    ClosureResult.DataCompositionSettingsAddress = PutToTempStorage(
        ComposerSettings.GetSettings(), OwnerUUID);
    ClosureResult.FilterPresentation = String(ComposerSettings.Settings.Filter);
    Return ClosureResult;
    
EndFunction // CreateClosureResult()

&AtServerNoContext
Function NewClosureResult()

    ClosureResult = New Structure;
    ClosureResult.Insert("DataCompositionSchemaAddress");
    ClosureResult.Insert("DataCompositionSettingsAddress");
    ClosureResult.Insert("FilterPresentation");
    Return ClosureResult;
    
EndFunction // NewClosureResult()
   
#EndRegion // ServiceProceduresAndFunctions 