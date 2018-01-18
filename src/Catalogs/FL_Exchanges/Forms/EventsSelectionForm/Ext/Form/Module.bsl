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
    
    MetadataObjectArray = New Array;
    //MetadataObjectArray.Add("ScheduledJob.FL_JobServer");
    //MetadataObjectArray.Add("РегламентноеЗадание.FL_JobServer");
    //MetadataObjectArray.Add("ScheduledJob.FL_RecurringServer");
    //MetadataObjectArray.Add("РегламентноеЗадание.FL_RecurringServer");
    MetadataObjectArray.Add("Catalog.*");
    MetadataObjectArray.Add("Справочник.*");
    MetadataObjectArray.Add("Document.*");
    MetadataObjectArray.Add("Документ.*");
    MetadataObjectArray.Add("InformationRegister.*");
    MetadataObjectArray.Add("РегистрСведений.*");
    MetadataObjectArray.Add("AccumulationRegister.*");
    MetadataObjectArray.Add("РегистрНакопления.*");

    Filter = New Structure;
    Filter.Insert("MetadataObjectClass", MetadataObjectArray);
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
    
    Array = New Array;
    For Each Events In EventsTree.GetItems() Do
        For Each Event In Events.GetItems() Do
            If Event.Check = 1 Then
                Array.Add(Event.FullName);
            EndIf;
        EndDo;
    EndDo;
    
    Close(Array);
    
EndProcedure // SaveAndClose()

#EndRegion // FormCommandHandlers
