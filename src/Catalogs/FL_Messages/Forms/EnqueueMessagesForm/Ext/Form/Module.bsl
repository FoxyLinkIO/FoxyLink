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
    
    Parameters.Property("Exchange", Exchange);
    Parameters.Property("DataCompositionSchemaFilterAddress", 
        DataCompositionSchemaFilterAddress);
    Parameters.Property("DataCompositionSettingsFilterAddress", 
        DataCompositionSettingsFilterAddress);
    Parameters.Property("EventSource", EventSource);
    Parameters.Property("Operation", Operation);
    
    DataCompositionSchema = FL_DataComposition
        .CreateEventSourceDataCompositionSchema(EventSource);   
    DataCompositionSchemaAddress = PutToTempStorage(DataCompositionSchema, UUID); 
    FL_DataComposition.InitSettingsComposer(ComposerSettings, 
        DataCompositionSchemaAddress, DataCompositionSettingsFilterAddress);
        
    SetMaxOutputRecordsCount(ComposerSettings);     
        
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
Procedure PreviewSpreadsheetDocumentDetailProcessing(Item, Details, 
    StandardProcessing)
    
    FL_InteriorUseClient.DetailProcessing(GetFromTempStorage(DetailsDataAddress), 
        Details, StandardProcessing);
            
EndProcedure // PreviewSpreadsheetDocumentDetailProcessing()

#EndRegion // FormItemsEventHandlers

#Region FormCommandHandlers

&AtClient
Procedure EditDataCompositionSchema(Command)
    
    FL_DataCompositionClient.RunDataCompositionSchemaWizard(ThisObject,
        DataCompositionSchemaAddress);
    
EndProcedure // EditDataCompositionSchema()

&AtClient
Procedure EnqueueEvents(Command)
    
    ShowQueryBox(New NotifyDescription("DoAfterChooseEventToDispatch", 
            ThisObject),
        NStr("en='Enqueue all objects from the events table?';
            |ru='Отправить в очередь все объекты из таблицы событий?';
            |uk='Помістити в чергу всі елементи з таблиці подій?';
            |en_CA='Enqueue all objects from the events table?'"),
        QuestionDialogMode.YesNo, , DialogReturnCode.No);   
    
EndProcedure // EnqueueEvents()

&AtClient
Procedure PreviewEvents(Command)
    PreviewEventsAtServer();
EndProcedure // PreviewEvents()

#EndRegion // FormCommandHandlers

#Region ServiceProceduresAndFunctions

// Adds new subscriptions on events.
//
// Parameters:
//  QuestionResult       - DialogReturnCode - system enumeration value 
//                  or a value related to a clicked button. If a dialog 
//                  is closed on timeout, the value is Timeout. 
//  AdditionalParameters - Arbitrary        - the value specified when the 
//                              NotifyDescription object was created.
//
&AtClient
Procedure DoAfterChooseEventToDispatch(QuestionResult, 
    AdditionalParameters) Export
    
    If QuestionResult = DialogReturnCode.Yes Then
        EnqueueEventsAtServer();
        Close();
    EndIf;
    
EndProcedure // DoAfterChooseEventToDispatch() 

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
        
    If Changes Then
        
        // Init data composer by new data composition schema.
        FL_DataComposition.InitSettingsComposer(ComposerSettings, 
            DataCompositionSchemaAddress);

    EndIf;

EndProcedure // UpdateDataCompositionSchema()

// Only for internal use.
//
&AtServer
Procedure PreviewEventsAtServer()
    
    PreviewSpreadsheetDocument.Clear();
    
    // Start measuring.
    StartTime = CurrentUniversalDateInMilliseconds();
    
    DetailsData = New DataCompositionDetailsData;
    DataCompositionTemplate = FL_DataComposition
        .NewTemplateComposerParameters();
    DataCompositionTemplate.Schema = GetFromTempStorage(
        DataCompositionSchemaAddress);
    DataCompositionTemplate.Template = ComposerSettings.GetSettings();
    DataCompositionTemplate.DetailsData = DetailsData;

    OutputParameters = FL_DataComposition.NewOutputParameters();
    OutputParameters.DCTParameters = DataCompositionTemplate;
    OutputParameters.DetailsData = DetailsData;
    
    FL_DataComposition.OutputInSpreadsheetDocument(PreviewSpreadsheetDocument, 
        OutputParameters);
           
    // End measuring.
    TestingExecutionTime = CurrentUniversalDateInMilliseconds() - StartTime;
    
    DetailsDataAddress = PutToTempStorage(DetailsData, UUID);
    
EndProcedure // PreviewEventsAtServer()

// Only for internal use.
//
&AtServer
Procedure EnqueueEventsAtServer()
    
    SetMaxOutputRecordsCount(ComposerSettings, 0);
    
    DataCompositionTemplate = FL_DataComposition
        .NewTemplateComposerParameters();
    DataCompositionTemplate.Schema = GetFromTempStorage(
        DataCompositionSchemaAddress);
    DataCompositionTemplate.Template = ComposerSettings.GetSettings();

    OutputParameters = FL_DataComposition.NewOutputParameters();
    OutputParameters.DCTParameters = DataCompositionTemplate;
    
    EventsTable = New ValueTable;
    FL_DataComposition.OutputInValueCollection(EventsTable, 
        OutputParameters);
            
    EnqueueEventsTable(EventsTable);    
            
EndProcedure // EnqueueEventsAtServer()

// Only for internal use.
//
&AtServer
Procedure EnqueueEventsTable(Events)
    
    // Invocation mock
    Invocation = Catalogs.FL_Messages.NewInvocation();
    Invocation.EventSource = EventSource;
    Invocation.Operation = Operation;
        
    // The code in the comment written in one line is below this comment.
    // To edit the code, remove the comment.
    // For more information about the code in 1 line see http://infostart.ru/public/71130/.
    
    //For Each Event In Events Do
    //    
    //    For Each Column In Events.Columns Do
    //        Catalogs.FL_Messages.AddToContext(Invocation, 
    //            Column.Name, Event[Column.Name], True);
    //    EndDo;
    //
    //    Catalogs.FL_Messages.Route(Invocation, Exchange);
    //              
    //    Invocation.Context.Clear();
    //    
    //EndDo;
    
    For Each Event In Events Do For Each Column In Events.Columns Do Catalogs.FL_Messages.AddToContext(Invocation, Column.Name, Event[Column.Name], True); EndDo; Catalogs.FL_Messages.Route(Invocation, Exchange); Invocation.Context.Clear(); EndDo;
      
EndProcedure // EnqueueEventsTable()

// Only for internal use.
//
&AtServerNoContext
Procedure SetMaxOutputRecordsCount(ComposerSettings, MaxResults = 500)
    
    FoxyLinkGroup = ComposerSettings.Settings.Structure.Get(0);
    ParameterValue = FoxyLinkGroup.OutputParameters.Items.Find("RecordsCount");
    If ParameterValue <> Undefined Then
        If MaxResults = 0 Then
            ParameterValue.Use = False;
        Else
            ParameterValue.Value = MaxResults;
        EndIf;
    EndIf;
    
EndProcedure // SetMaxOutputRecordsCount()

#EndRegion // ServiceProceduresAndFunctions