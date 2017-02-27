////////////////////////////////////////////////////////////////////////////////
// This file is part of IHL (Integration happiness library).
// Copyright © 2016-2017 Petro Bazeliuk.
// 
// IHL is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as 
// published by the Free Software Foundation, either version 3 
// of the License, or any later version.
// 
// IHL is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public 
// License along with IHL. If not, see <http://www.gnu.org/licenses/>.
//
////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
    
#Region ProgramInterface

// Returns method reference by method description.
//
// Returns:
//  CatalogRef.IHL_Methods - method reference. 
//
Function MethodByDescription(Description) Export
    
    Query = New Query;
    Query.Text = QueryTextMethodByDescription();
    Query.SetParameter("Description", Description);
    QueryResultSelection = Query.Execute().Select();
    
    Return ?(QueryResultSelection.Next(), QueryResultSelection.Ref, Undefined);
    
EndFunction // MethodByDescription()

// Returns list of available methods from catalog.
//
// Returns:
//  ValueList - list of of available methods. 
//
Function AvailableMethods() Export

    ValueList = New ValueList;
    
    Query = New Query;
    Query.Text = QueryTextMethods();
    QueryResult = Query.Execute();
    
    If QueryResult.IsEmpty() = False Then
        ValueTable = QueryResult.Unload();
        ValueList.LoadValues(ValueTable.UnloadColumn("Ref"));
    EndIf;
    
    Return ValueList;

EndFunction // AvailableMethods()

#EndRegion // ProgramInterface 

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
Function QueryTextMethods()

    QueryText = "
        |Select
        |   Methods.Ref As Ref   
        |From
        |   Catalog.IHL_Methods As Methods
        |Where
        |   Methods.DeletionMark = False
        |";
    Return QueryText;

EndFunction // QueryTextMethods()

// Only for internal use.
//
Function QueryTextMethodByDescription()

    QueryText = "
        |Select
        |   Methods.Ref As Ref   
        |From
        |   Catalog.IHL_Methods As Methods
        |Where
        |   Methods.Description = &Description
        |";
    Return QueryText;

EndFunction // QueryTextMethodByDescription()

#EndRegion // ServiceProceduresAndFunctions

#EndIf