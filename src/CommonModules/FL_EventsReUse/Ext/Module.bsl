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
// Returns:
//  FixedArray - with event publishers:
//      * String - an event publisher.
//
Function EventPublishers() Export
    
    Query = New Query;
    Query.Text = QueryTextEventPublishers();
    ValueTable = Query.Execute().Unload();
    Return New FixedArray(ValueTable.UnloadColumn("MetadataObject"));
    
EndFunction // EventPublishers()

#EndRegion // ProgramInterface

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
Function QueryTextEventPublishers()

    QueryText = "
        |SELECT 
        |    ExchangeEvents.MetadataObject AS MetadataObject
        |FROM
        |   Catalog.FL_Exchanges AS Exchanges
        |
        |INNER JOIN Catalog.FL_Exchanges.Events AS ExchangeEvents
        |ON ExchangeEvents.Ref = Exchanges.Ref 
        |
        |WHERE
        |    Exchanges.InUse = True
        |";
    Return QueryText;
    
EndFunction // QueryTextEventPublishers()

#EndRegion // ServiceProceduresAndFunctions
