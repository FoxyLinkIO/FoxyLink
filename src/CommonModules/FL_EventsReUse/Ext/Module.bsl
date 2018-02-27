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

#Region ProgramInterface

// Returns current session hash as base64-encoded string.
//
// Returns:
//  String - current session hash as base64-encoded string.
//
Function SessionHash() Export
    
    InfoBaseSession = GetCurrentInfoBaseSession();
    
    MemoryStream = New MemoryStream;
    DataWriter = New DataWriter(MemoryStream);
    DataWriter.WriteChars(InfoBaseSession.ApplicationName);
    DataWriter.WriteChars(InfoBaseSession.ComputerName);
    DataWriter.WriteInt32(InfoBaseSession.ConnectionNumber);
    DataWriter.WriteInt32(InfoBaseSession.SessionNumber);
    DataWriter.WriteChars(String(InfoBaseSession.SessionStarted));
    DataWriter.Close();
    
    MemoryStream.Seek(0, PositionInStream.Begin);
    Hash = FL_Encryption.Hash(MemoryStream, 
        HashFunction.MD5);
    MemoryStream.Close();
    
    Return Base64String(Hash);
    
EndFunction // SessionHash()

// Returns event publishers.
//
// Parameters:
//  MetadataObject - String - the full name of a metadata object as a term.   
//
// Returns:
//  Boolean - True, if it is event publisher, otherwise False.
//
Function IsEventPublisher(MetadataObject) Export
    
    Query = New Query;
    Query.Text = QueryTextIsEventPublisher();
    Query.SetParameter("MetadataObject", MetadataObject);
    Return NOT Query.Execute().IsEmpty();
    
EndFunction // IsEventPublisher()

// Returns event publishers.
//
// Parameters:
//  MetadataObject - String                   - the full name of a metadata object as a term.   
//  Operation      - CatalogRef.FL_Operations - reference to the FL_Operations catalog.
//
// Returns:
//  FixedArray - with event publishers:
//      * CatalogRef.FL_Exchanges - an event publisher.
//
Function EventPublishers(MetadataObject, Operation) Export
    
    Query = New Query;
    Query.Text = QueryTextEventPublishers();
    Query.SetParameter("MetadataObject", MetadataObject);
    Query.SetParameter("Operation", Operation);
    ValueTable = Query.Execute().Unload();
    Return New FixedArray(ValueTable.UnloadColumn("Exchange"));
    
EndFunction // EventPublishers()

// Returns event priority.
//
// Parameters:
//  Exchange  - CatalogRef.FL_Exchanges  - event publisher.   
//  Operation - CatalogRef.FL_Operations - event operation.
//
// Returns:
//  Number - event priority.
//
Function EventPriority(Exchange, Operation) Export
    
    NormalPriority = 5;
    
    Query = New Query;
    Query.Text = QueryTextEventPriority();
    Query.SetParameter("Exchange", Exchange);
    Query.SetParameter("Operation", Operation);
    QueryResultSelection = Query.Execute().Select();
    Return ?(QueryResultSelection.Next(), 
        QueryResultSelection.Priority, 
        NormalPriority);
    
EndFunction // EventPriority()

#EndRegion // ProgramInterface

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
Function QueryTextIsEventPublisher()

    QueryText = "
        |SELECT 
        |   EventTable.Ref AS Exchange
        |FROM
        |   Catalog.FL_Exchanges AS Exchanges 
        |
        |INNER JOIN Catalog.FL_Exchanges.Events AS EventTable
        // [OPPX|OPHP1 +] Attribute + Ref
        |ON  EventTable.MetadataObject = &MetadataObject
        |AND EventTable.Ref            = Exchanges.Ref
        |
        |WHERE
        |   Exchanges.InUse = True
        |";
    Return QueryText;
    
EndFunction // QueryTextIsEventPublisher()

// Only for internal use.
//
Function QueryTextEventPublishers()

    QueryText = "
        |SELECT 
        |   EventTable.Ref AS Exchange
        |FROM
        |   Catalog.FL_Exchanges AS Exchanges 
        |
        |INNER JOIN Catalog.FL_Exchanges.Events AS EventTable
        // [OPPX|OPHP1 +] Attribute + Ref
        |ON  EventTable.MetadataObject = &MetadataObject
        |AND EventTable.Ref            = Exchanges.Ref
        |AND EventTable.Operation      = &Operation
        |
        |WHERE
        |   Exchanges.InUse = True
        |";
    Return QueryText;
    
EndFunction // QueryTextEventPublishers()

// Only for internal use.
//
Function QueryTextEventPriority()

    QueryText = "
        |SELECT 
        |   Operations.Priority AS Priority
        |FROM
        |   Catalog.FL_Exchanges.Operations AS Operations 
        |
        |WHERE
        |   Operations.Ref = &Exchange
        |AND Operations.Operation = &Operation
        |";
    Return QueryText;
    
EndFunction // QueryTextEventPriority()

#EndRegion // ServiceProceduresAndFunctions
