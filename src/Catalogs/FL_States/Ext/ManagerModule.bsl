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

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region ProgramInterface

// Returns list of the all states from this catalog.
//
// Returns:
//  ValueList - list of the states. 
//
Function States() Export
    
    ValueList = New ValueList;
    
    Query = New Query;
    Query.Text = QueryTextStates();
    QueryResult = Query.Execute();
    
    If NOT QueryResult.IsEmpty() Then
        
        ValueTable = QueryResult.Unload();
        For Each Item In ValueTable Do
            ValueList.Add(Item.Ref, Item.Description);        
        EndDo;

    EndIf;
    
    Return ValueList;    
    
EndFunction // States()

// Returns list of the final states from this catalog.
//
// Returns:
//  ValueList - list of the final states. 
//
Function FinalStates() Export

    ValueList = New ValueList;
    
    Query = New Query;
    Query.Text = QueryTextFinalStates();
    QueryResult = Query.Execute();
    
    If NOT QueryResult.IsEmpty() Then
        ValueTable = QueryResult.Unload();
        ValueList.LoadValues(ValueTable.UnloadColumn("Ref"));
    EndIf;
    
    Return ValueList;

EndFunction // FinalStates()

#EndRegion // ProgramInterface 

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
Function QueryTextStates()

    QueryText = "
        |SELECT
        |   States.Ref AS Ref,
        |   States.Description AS Description
        |FROM
        |   Catalog.FL_States AS States
        |";
    Return QueryText;

EndFunction // QueryTextStates()

// Only for internal use.
//
Function QueryTextFinalStates()

    QueryText = "
        |SELECT
        |   States.Ref AS Ref   
        |FROM
        |   Catalog.FL_States AS States
        |WHERE
        |    States.DeletionMark = False
        |AND States.IsFinal      = True
        |";
    Return QueryText;

EndFunction // QueryTextFinalStates()

#EndRegion // ServiceProceduresAndFunctions
 
#EndIf
