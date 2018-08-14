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
    
    LoadBasicEventPublishers();
    LoadAvailableOperations();    
    LoadMessagePublishers();
    
EndProcedure // OnCreateAtServer()

#EndRegion // FormEventHandlers

#Region FormEventHandlers

&AtClient
Procedure PublishersTreeCheckOnChange(Item)
    
    FL_CommonUseClientServer.HandleThreeStateCheckBox(
        Items.PublishersTree.CurrentData, "Check"); 
    
EndProcedure // PublishersTreeCheckOnChange()

#EndRegion // FormEventHandlers

#Region FormCommandHandlers

&AtClient
Procedure SaveAndClose(Command)
    
    SaveMessagePublishers();
    Close();
    
EndProcedure // SaveAndClose()

#EndRegion // FormCommandHandlers

#Region ServiceProceduresAndFunctions

&AtServer
Procedure SaveMessagePublishers()
    
    OperationCache = NewOperationCache();
    ValueTree = FormAttributeToValue("PublishersTree");
    For Each RootItem In ValueTree.Rows Do
        SaveMessagePublishersToRegister(RootItem.Rows, OperationCache);        
    EndDo;
    
EndProcedure // SaveMessagePublishers()

&AtServer
Procedure SaveMessagePublishersToRegister(Rows, OperationCache)
    
    RecordSet = InformationRegisters.FL_MessagePublishers.CreateRecordSet();
    For Each Row In Rows Do
            
        RecordSet.Filter.EventSource.Set(Row.FullName);
        If Row.Check = 1 Then
            For Each Item In OperationCache Do
                NewRecord = RecordSet.Add();
                NewRecord.EventSource = Row.FullName;
                NewRecord.Operation = Item.Key;
                NewRecord.InUse = Row[Item.Value];
            EndDo;
        EndIf;
        
        RecordSet.Write();
        RecordSet.Clear();
        
    EndDo;
    
EndProcedure // SaveMessagePublishersToRegister()

&AtServer
Procedure LoadBasicEventPublishers()
    
    PublishersArray = New Array;
    PublishersArray.Add("HTTPService.FL_AppEndpoint");
    PublishersArray.Add("HTTPСервис.FL_AppEndpoint");
    PublishersArray.Add("Catalog.*");
    PublishersArray.Add("Справочник.*");
    PublishersArray.Add("Document.*");
    PublishersArray.Add("Документ.*");                               
    PublishersArray.Add("ChartOfCharacteristicTypes.*");   
    PublishersArray.Add("ПланВидовХарактеристик.*");
    PublishersArray.Add("InformationRegister.*");
    PublishersArray.Add("РегистрСведений.*");
    PublishersArray.Add("AccumulationRegister.*");
    PublishersArray.Add("РегистрНакопления.*");

    Filter = New Structure;
    Filter.Insert("MetadataObjectClass", PublishersArray);
    ValueTree = FL_CommonUse.ConfigurationMetadataTree(Filter);
    
    // Avoiding possible stack overflow
    SearchResult = ValueTree.Rows.Find("FL_Messages", "Name", True);
    If SearchResult <> Undefined Then
        SearchResult.Parent.Rows.Delete(SearchResult);
    EndIf;
        
    ValueToFormData(ValueTree, PublishersTree);
    
EndProcedure // LoadBasicEventPublishers()

&AtServer
Procedure LoadAvailableOperations()
    
    AttributesToBeAdded = New Array;
    For Each Operation In Catalogs.FL_Operations.AvailableOperations() Do
        
        OperationRef = "_" + StrReplace(XMLString(Operation.Value), "-", "_");
        FromAttribute = New FormAttribute(OperationRef, 
            New TypeDescription("Boolean"), 
            "PublishersTree", 
            Operation.Value.Description, 
            True);
            
        AttributesToBeAdded.Add(FromAttribute); 
        
    EndDo;
    
    ChangeAttributes(AttributesToBeAdded);

    For Each FormAttribute In AttributesToBeAdded Do
        
        FormField = FL_InteriorUse.NewFormField(FormFieldType.InputField);
        FormField.DataPath = StrTemplate("%1.%2", FormAttribute.Path, 
            FormAttribute.Name);
        FillPropertyValues(FormField, FormAttribute);
        FL_InteriorUse.AddItemToItemFormCollection(Items, FormField, 
            Items.PublishersTree);
            
    EndDo;
    
EndProcedure // LoadAvailableOperations()

&AtServer
Procedure LoadMessagePublishers()
    
    Query = New Query;
    Query.Text = QueryTextMessagePublishers();
    QueryResult = Query.Execute();
    If QueryResult.IsEmpty() Then
        Return;
    EndIf;
    
    OperationCache = NewOperationCache();
    ValueTree = FormAttributeToValue("PublishersTree");
    
    QueryResultSelection = QueryResult.Select();
    While QueryResultSelection.Next() Do
        
        OperationName = OperationCache.Get(QueryResultSelection.Operation);
        If OperationName = Undefined Then
            Continue;
        EndIf;
        
        SearchResult = ValueTree.Rows.Find(QueryResultSelection.EventSource, 
            "FullName", True);
        If SearchResult = Undefined Then
            Continue;    
        EndIf;
         
        SearchResult.Check = 1;
        SearchResult[OperationName] = QueryResultSelection.InUse;
        FL_CommonUse.HandleThreeStateCheckBox(SearchResult, "Check");
        
    EndDo;
    
    ValueToFormData(ValueTree, PublishersTree);
         
EndProcedure // LoadMessagePublishers()

// Only for internal use.
//
&AtServerNoContext
Function NewOperationCache()
    
    OperationCache = New Map;
    For Each Operation In Catalogs.FL_Operations.AvailableOperations() Do
        OperationRef = "_" + StrReplace(XMLString(Operation.Value), "-", "_");
        OperationCache.Insert(Operation.Value, OperationRef);        
    EndDo;
    
    Return OperationCache;
    
EndFunction // NewOperationCache()

// Only for internal use.
//
&AtServerNoContext
Function QueryTextMessagePublishers()

    QueryText = "
        |SELECT 
        |   MessagePublishers.EventSource AS EventSource,
        |   MessagePublishers.Operation AS Operation,
        |   MessagePublishers.InUse AS InUse
        |FROM
        |   InformationRegister.FL_MessagePublishers AS MessagePublishers
        |";
    Return QueryText;
    
EndFunction // QueryTextIsMessagePublisher()

#EndRegion // ServiceProceduresAndFunctions


