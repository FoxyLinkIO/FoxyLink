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
// along with FoxyLink. If not, see <http://www.gnu.org/licenses/agpl-3.0>.
//
////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
    
#Region ProgramInterface 

// This function returns a registered handler for the content-type.
//
// Parameters:
//  ContentType - String - content media type.
//
// Returns:
//  Undefined - format data processor not found.
//  DataProcessorObject.<Data processor name> - format data processor.
//  ExternalDataProcessorObject.<Data processor name> - external format data processor.
//
Function NewRegisteredHandlerForContentType(ContentType) Export
    
    Query = New Query;
    Query.Text = QueryTextRegisteredHandlerForContentType();
    Query.SetParameter("ContentType", ContentType);    
    Return NewDataProcessor(Query);
    
EndFunction // NewRegisteredHandlerForContentType()

// This function returns a registered handler for the file extension.
//
// Parameters:
//  FileExtension - String - file extension of media type.
//
// Returns:
//  Undefined - format data processor not found.
//  DataProcessorObject.<Data processor name> - format data processor.
//  ExternalDataProcessorObject.<Data processor name> - external format data processor.
//
Function NewRegisteredHandlerForFileExtension(FileExtension) Export
    
    Query = New Query;
    Query.Text = QueryTextRegisteredHandlerForFileExtension();
    Query.SetParameter("FileExtension", FileExtension);
    Return NewDataProcessor(Query);
    
EndFunction // NewRegisteredHandlerForFileExtension()

#EndRegion // ProgramInterface

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
Function NewDataProcessor(Query)
    
    QueryResult = Query.Execute();
    If QueryResult.IsEmpty() Then
        Return Undefined;
    EndIf;
    
    QueryResultSelection = QueryResult.Select();
    QueryResultSelection.Next();
    HandlerName = QueryResultSelection.RegisteredHandlerName;   
    Return DataProcessors[HandlerName].Create();
    
EndFunction // NewDataProcessor()

// Only for internal use.
// 
Function QueryTextRegisteredHandlerForContentType()
    
    Return "
        |SELECT
        |   Handlers.Ref AS Ref,
        |   Handlers.RegisteredHandlerName AS RegisteredHandlerName 
        |FROM
        |   Catalog.FL_Handlers AS Handlers
        |WHERE
        |   Handlers.DeletionMark = False
        |AND Handlers.FormatMediaType = &ContentType
        |";
    
EndFunction // QueryTextRegisteredHandlerForContentType()

// Only for internal use.
// 
Function QueryTextRegisteredHandlerForFileExtension()
    
    Return "
        |SELECT
        |   Handlers.Ref AS Ref,
        |   Handlers.RegisteredHandlerName AS RegisteredHandlerName 
        |FROM
        |   Catalog.FL_Handlers AS Handlers
        |WHERE
        |   Handlers.DeletionMark = False
        |AND Handlers.FormatFileExtension = &FileExtension
        |";
    
EndFunction // QueryTextRegisteredHandlerForFileExtension()

#EndRegion // ServiceProceduresAndFunctions 

#EndIf