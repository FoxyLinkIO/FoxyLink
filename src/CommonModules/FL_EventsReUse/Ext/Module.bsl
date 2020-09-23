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
// along with this program. If not, see <http://www.gnu.org/licenses/agpl-3.0>.
//
////////////////////////////////////////////////////////////////////////////////

#Region Public

// Defines if event is a message publisher.
//
// Parameters:
//  EventSource - String                   - the full name of a event object as a term.
//  Operation   - CatalogRef.FL_Operations - reference to the FL_Operations catalog.
//              - String                   - item name of FL_Operations catalog.
//
// Returns:
//  Boolean - True, if it is message publisher, otherwise False.
//
Function IsMessagePublisher(EventSource, Operation) Export
    
    OperationRef = Operation;
    If TypeOf(OperationRef) = Type("String") Then
        OperationRef = FL_CommonUse.ReferenceByDescription(
            Metadata.Catalogs.FL_Operations, OperationRef);
    EndIf;
    
    Query = New Query;
    Query.Text = QueryTextIsMessagePublisher();
    Query.SetParameter("EventSource", EventSource);
    Query.SetParameter("Operation", OperationRef);
    
    Return NOT Query.Execute().IsEmpty();
    
EndFunction // IsMessagePublisher()

// Defines if event is a publisher.
//
// Parameters:
//  EventSource - String - the full name of a event object as a term.
//
// Returns:
//  Boolean - True, if it is publisher, otherwise False.
//
Function IsPublisher(EventSource) Export
    
    Query = New Query;
    Query.Text = QueryTextIsPublisher();
    Query.SetParameter("EventSource", EventSource);
    Return NOT Query.Execute().IsEmpty();
    
EndFunction // IsPublisher()

#EndRegion // Public

#Region Private

// Only for internal use.
//
Function QueryTextIsMessagePublisher()

    Return "
        |SELECT 
        |   MessagePublishers.EventSource AS EventSource,
        |   MessagePublishers.Operation AS Operation,
        |   MessagePublishers.InUse AS InUse
        |FROM
        |   InformationRegister.FL_MessagePublishers AS MessagePublishers 
        |WHERE
        |   MessagePublishers.EventSource = &EventSource
        |AND MessagePublishers.Operation = &Operation
        |AND MessagePublishers.InUse
        |";
    
EndFunction // QueryTextIsMessagePublisher()

// Only for internal use.
//
Function QueryTextIsPublisher()

    Return "
        |SELECT 
        |   MessagePublishers.EventSource AS EventSource
        |FROM
        |   InformationRegister.FL_MessagePublishers AS MessagePublishers 
        |WHERE
        |   MessagePublishers.EventSource = &EventSource
        |AND MessagePublishers.InUse
        |";
    
EndFunction // QueryTextIsPublisher()

#EndRegion // Private