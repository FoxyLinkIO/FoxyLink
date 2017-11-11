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

// Returns HTTP methods.
//
// Returns:
//  ValueList - with values:
//      * Value - EnumRef.FL_RESTMethods - reference to the HTTP method.
//
Function Methods() Export
    
    ValueList = New ValueList;

    Query = New Query;
    Query.Text = QueryTextMethods();
    QueryResult = Query.Execute();
    If NOT QueryResult.IsEmpty() Then
        
        ValueTable = QueryResult.Unload();
        For Each Item In ValueTable Do
            ValueList.Add(Item.Ref);  
        EndDo;
        
    EndIf;
        
    Return ValueList;
    
EndFunction // Methods()

#EndRegion // ProgramInterface

#Region ServiceProceduresAndFunctions

// Only for internal use.
// 
Function QueryTextMethods()
    
    QueryText = "
        |SELECT
        |   RESTMethods.Ref AS Ref
        |FROM
        |   Enum.FL_RESTMethods AS RESTMethods
        |";
    Return QueryText;
    
EndFunction // QueryTextMethods()

#EndRegion // ServiceProceduresAndFunctions

#EndIf