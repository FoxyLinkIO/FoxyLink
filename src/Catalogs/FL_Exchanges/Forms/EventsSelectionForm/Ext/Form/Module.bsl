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
    
    Var Operation;
    
    If Parameters.Property("AutoTest") Then
        // Return if the form for analysis is received.
        Return;
    EndIf;
    
    Parameters.Property("Operation", Operation);
    If TypeOf(Operation) = Type("String") Then
        Operation = FL_CommonUse.ReferenceByDescription(
            Metadata.Catalogs.FL_Operations, Operation);
    EndIf;

    If TypeOf(Operation) <> Type("CatalogRef.FL_Operations") Then
        ErrorMessage = FL_ErrorsClientServer.ErrorTypeIsDifferentFromExpected(
            "Operation", Operation, Type("CatalogRef.FL_Operations"));
        Raise ErrorMessage;
    EndIf;
    
    Filter = New Structure;
    Filter.Insert("MetadataObjectClass", PublishersArray(Operation));
    ValueTree = FL_CommonUse.ConfigurationMetadataTree(Filter);
    
    For Each MarkedEvent In Parameters.MarkedEvents Do
        SearchResult = ValueTree.Rows.Find(MarkedEvent.Value, "FullName", 
            True);
        If SearchResult <> Undefined Then
            SearchResult.Check = 1;
            FL_CommonUse.HandleThreeStateCheckBox(SearchResult, "Check");
        EndIf;
    EndDo;
    
    ValueToFormData(ValueTree, EventsTree);
    
EndProcedure // OnCreateAtServer()

#EndRegion // FormEventHandlers

#Region FormEventHandlers

&AtClient
Procedure EventsTreeCheckOnChange(Item)
    
    FL_CommonUseClientServer.HandleThreeStateCheckBox(
        Items.EventsTree.CurrentData, "Check"); 
    
EndProcedure // EventsTreeCheckOnChange()

#EndRegion // FormEventHandlers

#Region FormCommandHandlers

&AtClient
Procedure SaveAndClose(Command)
    
    ValueList = New ValueList;
    For Each Events In EventsTree.GetItems() Do
        For Each Event In Events.GetItems() Do
            If Event.Check = 1 Then
                ValueList.Add(Event.FullName, Event.Synonym);
            EndIf;
        EndDo;
    EndDo;
    
    Close(ValueList);
    
EndProcedure // SaveAndClose()

#EndRegion // FormCommandHandlers

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
&AtServerNoContext
Function PublishersArray(Operation)
    
    Query = New Query;
    Query.Text = QueryTextOperationMessagePublishers();
    Query.SetParameter("Operation", Operation);
    QueryResult = Query.Execute();
    If QueryResult.IsEmpty() Then
        Return New Array;
    Else
        Return QueryResult.Unload().UnloadColumn("EventSource");
    EndIf;
     
EndFunction // PublishersArray()

// Only for internal use.
//
&AtServerNoContext
Function QueryTextOperationMessagePublishers()

    QueryText = "
        |SELECT 
        |   MessagePublishers.EventSource AS EventSource
        |FROM
        |   InformationRegister.FL_MessagePublishers AS MessagePublishers
        |WHERE
        |   MessagePublishers.Operation = &Operation
        |AND MessagePublishers.InUse
        |";
    Return QueryText;   
    
EndFunction // QueryTextOperationMessagePublishers()

#EndRegion // ServiceProceduresAndFunctions
