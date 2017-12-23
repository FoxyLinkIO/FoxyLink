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

// Returns method reference by a method description.
//
// Parameters:
//  Description - String - method description. 
//
// Returns:
//  CatalogRef.FL_Methods - method reference. 
//
Function MethodByDescription(Description) Export
    
    Query = New Query;
    Query.Text = QueryTextMethodByDescription();
    Query.SetParameter("Description", Description);
    QueryResultSelection = Query.Execute().Select();
    
    Return ?(QueryResultSelection.Next(), QueryResultSelection.Ref, Undefined);
    
EndFunction // MethodByDescription()

// Returns method reference by a predefined data name.
//
// Parameters:
//  PredefinedDataName - String - method predefined data name. 
//
// Returns:
//  CatalogRef.FL_Methods - method reference. 
//
Function MethodByPredefinedDataName(PredefinedDataName) Export
    
    Query = New Query;
    Query.Text = QueryTextMethodByPredefinedDataName();
    Query.SetParameter("PredefinedDataName", PredefinedDataName);
    QueryResultSelection = Query.Execute().Select();
    
    Return ?(QueryResultSelection.Next(), QueryResultSelection.Ref, Undefined);
    
EndFunction // MethodByPredefinedDataName()

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
    
    If NOT QueryResult.IsEmpty() Then
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
        |SELECT
        |   Methods.Ref AS Ref   
        |FROM
        |   Catalog.FL_Methods AS Methods
        |WHERE
        |   Methods.DeletionMark = False
        |";
    Return QueryText;

EndFunction // QueryTextMethods()

// Only for internal use.
//
Function QueryTextMethodByDescription()

    QueryText = "
        |SELECT
        |   Methods.Ref AS Ref   
        |FROM
        |   Catalog.FL_Methods AS Methods
        |WHERE
        |   Methods.Description = &Description
        |";
    Return QueryText;

EndFunction // QueryTextMethodByDescription()

// Only for internal use.
//
Function QueryTextMethodByPredefinedDataName()

    QueryText = "
        |SELECT
        |   Methods.Ref AS Ref   
        |FROM
        |   Catalog.FL_Methods AS Methods
        |WHERE
        |   Methods.PredefinedDataName = &PredefinedDataName
        |";
    Return QueryText;

EndFunction // QueryTextMethodByPredefinedDataName()

#EndRegion // ServiceProceduresAndFunctions

#EndIf