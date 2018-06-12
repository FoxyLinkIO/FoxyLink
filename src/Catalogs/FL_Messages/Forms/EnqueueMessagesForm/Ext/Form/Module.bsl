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
    
    Parameters.Property("Exchange", Exchange);
    Parameters.Property("EventSource", EventSource);
    Parameters.Property("Operation", Operation);
    
    PrimaryKeys = FL_CommonUse.PrimaryKeysByMetadataObject(
        Metadata.FindByFullName(EventSource));

    InitializeDataCompositionSchema(PrimaryKeys); 
    
EndProcedure // OnCreateAtServer()

#EndRegion // FormEventHandlers

#Region FormItemsEventHandlers

&AtClient
Procedure PreviewSpreadsheetDocumentDetailProcessing(Item, Details, 
    StandardProcessing)
    
    StandardProcessing = False;
    
    DataCompositionDetails = GetFromTempStorage(DetailsDataAddress);
    FieldDetailsItem = DataCompositionDetails.Items[Details];
    FieldDetailsValues = FieldDetailsItem.GetFields();
    If FieldDetailsValues.Count() = 1 Then
        ShowValue(, FieldDetailsValues[0].Value);    
    EndIf;
        
EndProcedure // PreviewSpreadsheetDocumentDetailProcessing()

#EndRegion // FormItemsEventHandlers

#Region FormCommandHandlers

&AtClient
Procedure PreviewEvents(Command)
    PreviewEventsAtServer();
EndProcedure // PreviewEvents()

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
Procedure InitializeDataCompositionSchema(PrimaryKeys)
    
    MaxResults = 500;
    
    DataSource = FL_DataComposition.NewDataCompositionSchemaDataSource();
    DataSources = New Array;
    DataSources.Add(DataSource);
           
    DataSet = FL_DataComposition.NewDataCompositionSchemaDataSetQuery();
    DataSet.Query = StrTemplate("SELECT * FROM %1", EventSource);
    DataSets = New Array;
    DataSets.Add(DataSet);
     
    FL_DataComposition.CreateDataCompositionSchema(DataSources, DataSets, 
        DataCompositionSchemaAddress, UUID);
    FL_DataComposition.InitSettingsComposer(ComposerSettings, 
        DataCompositionSchemaAddress);
        
    FoxyLinkGroup = ComposerSettings.Settings.Structure.Add(
        Type("DataCompositionGroup"));
    FoxyLinkGroup.Use = True;
    FoxyLinkGroup.Name = "FoxyLinkGroup";
    FoxyLinkGroup.Order.Items.Add(
        Type("DataCompositionAutoOrderItem"));
    FoxyLinkGroup.Selection.Items.Add(
        Type("DataCompositionAutoSelectedField"));
    FoxyLinkGroup.OutputParameters.SetParameterValue("RecordsCount", 
        MaxResults);
    
    SelectionFields = ComposerSettings.Settings.Selection.Items;
    AvailableFields = ComposerSettings.Settings.Selection
        .SelectionAvailableFields.Items;
    For Each PrimaryKey In PrimaryKeys Do
        
        AvailableField = AvailableFields.Find(PrimaryKey.Key);
        If AvailableField <> Undefined Then
            
            SelectedField = SelectionFields.Add(
                Type("DataCompositionSelectedField"));
            SelectedField.Field = New DataCompositionField(
                AvailableField.Field);
            SelectedField.Use = True;
            
        EndIf;
        
    EndDo;
       
EndProcedure // InitializeDataCompositionSchema() 

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
    
    FoxyLinkGroup = ComposerSettings.Settings.Structure.Get(0);
    ParameterValue = FoxyLinkGroup.OutputParameters.Items.Find("RecordsCount");
    If ParameterValue <> Undefined Then
        ParameterValue.Use = False;
    EndIf;
    
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
            
    If FL_CommonUseReUse.IsReferenceTypeObjectCached(EventSource) Then
        EnqueueReferenceEvents(EventsTable);    
    ElsIf FL_CommonUseReUse.IsInformationRegisterTypeObjectCached(EventSource)
        OR FL_CommonUseReUse.IsAccumulationRegisterTypeObjectCached(EventSource) Then
        EnqueueRegisterEvents(EventsTable);    
    EndIf;
            
EndProcedure // EnqueueEventsAtServer()

// Only for internal use.
//
&AtServer
Procedure EnqueueReferenceEvents(Events)
    
    Var AttributeName;
    
    Synonyms = FL_CommonUseReUse.StandardAttributeSynonyms();
    
    BaseAttributeName = "REF";
    SynonymAttributeName = Synonyms.Get(BaseAttributeName);
    
    If Events.Columns.Find(BaseAttributeName) <> Undefined Then
        AttributeName = BaseAttributeName;
    ElsIf Events.Columns.Find(SynonymAttributeName) <> Undefined Then
        AttributeName = SynonymAttributeName;    
    EndIf;
    
    // Invocation mock
    Invocation = Catalogs.FL_Messages.NewInvocation();
    Invocation.EventSource = EventSource;
    Invocation.Operation = Operation;    
    If ValueIsFilled(AttributeName) Then
        
        // The code in the comment written in one line is below this comment.
        // To edit the code, remove the comment.
        // For more information about the code in 1 line see http://infostart.ru/public/71130/.

        //For Each Event In Events Do
        //    
        //  Catalogs.FL_Messages.AddToContext(Invocation.Context, 
        //      BaseAttributeName, Event[AttributeName], True);
        //    
        //  Catalogs.FL_Messages.Route(Invocation, Exchange);
        //           
        //  Invocation.Context.Clear();
        //
        //EndDo;
        
        For Each Event In Events Do Catalogs.FL_Messages.AddToContext(Invocation.Context, BaseAttributeName, Event[AttributeName], True); Catalogs.FL_Messages.Route(Invocation, Exchange); Invocation.Context.Clear(); EndDo;
              
    EndIf;
      
EndProcedure // EnqueueReferenceEvents()

// Only for internal use.
//
&AtServer
Procedure EnqueueRegisterEvents(Events)
    
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
    //        Catalogs.FL_Messages.AddToContext(Invocation.Context, 
    //            Column.Name, Event[Column.Name], True);
    //    EndDo;
    //
    //    Catalogs.FL_Messages.Route(Invocation, Exchange);
    //              
    //    Invocation.Context.Clear();
    //    
    //EndDo;
    
    For Each Event In Events Do For Each Column In Events.Columns Do Catalogs.FL_Messages.AddToContext(Invocation.Context, Column.Name, Event[Column.Name], True); EndDo; Catalogs.FL_Messages.Route(Invocation, Exchange); Invocation.Context.Clear(); EndDo;
      
EndProcedure // EnqueueRegisterEvents()

#EndRegion // ServiceProceduresAndFunctions