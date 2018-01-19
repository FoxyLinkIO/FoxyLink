////////////////////////////////////////////////////////////////////////////////
// This file is part of FoxyLink.
// Copyright © 2016-2018 Petro Bazeliuk.
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
    
    Parameters.Property("APIVersion", APIVersion);
    Parameters.Property("Exchange", Exchange);
    Parameters.Property("MetadataObject", MetadataObject);
    Parameters.Property("Method", Method);
    
    PrimaryKeys = FL_CommonUse.PrimaryKeysByMetadataObject(MetadataObject);
    
    InitializeForm(PrimaryKeys);
    InitializeDataCompositionSchema(PrimaryKeys);
    
EndProcedure // OnCreateAtServer()

#EndRegion // FormEventHandlers

#Region FormCommandHandlers

&AtClient
Procedure PreviewEvents(Command)
    PreviewEventsAtServer();
EndProcedure // PreviewEvents()

&AtClient
Procedure EnqueueEvents(Command)
    
    ShowQueryBox(New NotifyDescription("DoAfterChooseEventToDispatch", 
            ThisObject),
        NStr("en = 'Enqueue all objects from the events table?';
             |ru = 'Отправить в очередь все объекты из таблицы событий?'"),
        QuestionDialogMode.YesNo, , DialogReturnCode.No);   
    
EndProcedure // EnqueueEvents()

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

// Only for internal use.
//
&AtServer
Procedure InitializeForm(PrimaryKeys)
    
    NewAttribues = New Array;
    For Each PrimaryKey In PrimaryKeys Do
        NewAttribues.Add(New FormAttribute(PrimaryKey.Key, 
            New TypeDescription(PrimaryKey.Value), "EventsTable"));         
    EndDo;
    ChangeAttributes(NewAttribues);
    
    For Each PrimaryKey In PrimaryKeys Do
        
        FormField = FL_InteriorUse.NewFormField(FormFieldType.InputField);
        FormField.Name = PrimaryKey.Key;
        FormField.DataPath = StrTemplate("EventsTable.%1", PrimaryKey.Key);
        FL_InteriorUse.AddItemToItemFormCollection(Items, FormField, 
            Items.EventsTable);
            
    EndDo;
    
EndProcedure // InitializeForm()

// Only for internal use.
//
&AtServer
Procedure InitializeDataCompositionSchema(PrimaryKeys)
    
    DataSources = New Array;
    DataSource = FL_DataComposition.NewDataCompositionSchemaDataSource();
    DataSources.Add(DataSource);
    
    FieldText = "";
    DataSet = FL_DataComposition.NewDataCompositionSchemaDataSetQuery();
    For Each PrimaryKey In PrimaryKeys Do
        
        FieldText = FieldText + ?(IsBlankString(FieldText), "", ",") + "
            |   " + PrimaryKey.Key + " AS " + PrimaryKey.Key;
        
        Field = FL_DataComposition.NewDataCompositionSchemaDataSetField();
        Field.DataPath = PrimaryKey.Key;
        Field.Field = PrimaryKey.Key;
        Field.Title = PrimaryKey.Key;
        Field.ValueType = New TypeDescription(PrimaryKey.Value);
        DataSet.Fields.Add(Field);
        
    EndDo;
    
    DataSets = New Array;
    DataSets.Add(DataSet);
    DataSet.Query = StrTemplate("SELECT %1 FROM %2", FieldText, MetadataObject);
    
    FL_DataComposition.CreateDataCompositionSchema(DataSources, DataSets, 
        DataCompositionSchemaAddress, UUID);
    FL_DataComposition.InitSettingsComposer(ComposerSettings, 
        DataCompositionSchemaAddress);
        
    DataCompositionGroup = ComposerSettings.Settings.Structure.Add(
        Type("DataCompositionGroup"));
    DataCompositionGroup.Use = True;

    For Each PrimaryKey In PrimaryKeys Do 
        SelectedField = DataCompositionGroup.Selection.Items.Add(
            Type("DataCompositionSelectedField"));
        SelectedField.Field = New DataCompositionField(PrimaryKey.Key);
        SelectedField.Use = True;
    EndDo;
   
EndProcedure // InitializeDataCompositionSchema() 

// Only for internal use.
//
&AtServer
Procedure PreviewEventsAtServer()
    
    // Start measuring.
    StartTime = CurrentUniversalDateInMilliseconds();
    
    DataCompositionSchema = GetFromTempStorage(DataCompositionSchemaAddress);     
    DataCompositionSettings = ComposerSettings.GetSettings();

    DataCompositionTemplate = FL_DataComposition
        .NewTemplateComposerParameters();
    DataCompositionTemplate.Schema   = DataCompositionSchema;
    DataCompositionTemplate.Template = DataCompositionSettings;

    OutputParameters = FL_DataComposition.NewOutputParameters();
    OutputParameters.DCTParameters = DataCompositionTemplate;
    
    ValueTable = New ValueTable;
    FL_DataComposition.OutputInValueCollection(ValueTable, 
        OutputParameters);     
            
    // End measuring.
    TestingExecutionTime = CurrentUniversalDateInMilliseconds() - StartTime;

    EventsTable.Load(ValueTable);
    
EndProcedure // PreviewEventsAtServer()

// Only for internal use.
//
&AtServer
Procedure EnqueueEventsAtServer()
    
    For Each Event In EventsTable Do
    
        // Event mock
        SourceMock = FL_Events.NewSourceMock();
        SourceMock.Ref = Event.Ref;
        
        InvocationData = SourceMock.AdditionalProperties.InvocationData;
        InvocationData.APIVersion = APIVersion;
        InvocationData.MetadataObject = MetadataObject;
        InvocationData.Method = Method;
        InvocationData.Owner = Exchange;
        InvocationData.Arguments = Event.Ref;
        
        FL_Events.EnqueueEvent(SourceMock);
        
    EndDo;
        
EndProcedure // EnqueueEventsAtServer()

#EndRegion // ServiceProceduresAndFunctions