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

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
    
#Region ProgramInterface

// Returns list of available operations from catalog.
//
// Returns:
//  ValueList - list of of available operations. 
//
Function AvailableOperations() Export

    ValueList = New ValueList;
    
    QueryOperation = New Query;
    QueryOperation.Text = QueryTextOperations();
    QueryResult = QueryOperation.Execute();
    
    If NOT QueryResult.IsEmpty() Then
        ValueTable = QueryResult.Unload();
        ValueList.LoadValues(ValueTable.UnloadColumn("Ref"));
    EndIf;
    
    Return ValueList;

EndFunction // AvailableOperations()

#EndRegion // ProgramInterface 

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
Function QueryTextOperations()

    QueryText = "
        |SELECT
        |   Operations.Ref AS Ref   
        |FROM
        |   Catalog.FL_Operations AS Operations
        |WHERE
        |   Operations.DeletionMark = False
        |";
    Return QueryText;

EndFunction // QueryTextOperations()

#EndRegion // ServiceProceduresAndFunctions

#EndIf