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

// Registers a new linked object.
//
// Parameters:
//  AppEndpoint - CatalogRef.FL_Channels - a reference to application endpoint.
//  Object      - AnyRef                 - any valid reference in database.
//  Identifier  - String                 - the object identifier in the application endpoint.
//
Procedure RegisterLinkedObject(AppEndpoint, Object, Identifier) Export
    
    RecordManager = InformationRegisters.FL_LinkedObjects.CreateRecordManager();
    RecordManager.AppEndpoint = AppEndpoint;
    RecordManager.Object = Object;
    RecordManager.Read();
    If NOT RecordManager.Selected() Then
        RecordManager.AppEndpoint = AppEndpoint;
        RecordManager.Object = Object;
        If TypeOf(Identifier) = Type("Number") Then
            RecordManager.Identifier = Format(Identifier, "NDS=.; NGS=''; NZ=; NG=");    
        Else
            RecordManager.Identifier = Identifier;
        EndIf;  
    EndIf;
    
    RecordManager.Write();
    
EndProcedure // RegisterLinkedObject()

// Unregisters the linked object.
//
// Parameters:
//  AppEndpoint - CatalogRef.FL_Channels - a reference to application endpoint.
//  Object      - AnyRef                 - any valid reference in database.
//
Procedure UnregisterLinkedObject(AppEndpoint, Object) Export
    
    RecordSet = InformationRegisters.FL_LinkedObjects.CreateRecordSet();
    RecordSet.Filter.AppEndpoint.Set(AppEndpoint);
    RecordSet.Filter.Object.Set(Object);
    RecordSet.Write();
    
EndProcedure // UnregisterLinkedObject()

// Returns linked object identifier.
//
// Parameters:
//  AppEndpoint - CatalogRef.FL_Channels - a reference to application endpoint.
//  Object      - AnyRef                 - any valid reference in database.
//
// Returns:
//  String - the object identifier in the application endpoint. 
//
Function LinkedObjectId(AppEndpoint, Object) Export
    
    Query = New Query;
    Query.Text = QueryTextLinkedObjectId();
    Query.SetParameter("AppEndpoint", AppEndpoint);
    Query.SetParameter("Object", Object);
    QueryResultSelection = Query.Execute().Select();
    If QueryResultSelection.Next() Then
        Return QueryResultSelection.Identifier;
    EndIf;
    
    Return Undefined;
    
EndFunction // LinkedObjectId()

// Returns linked object.
//
// Parameters:
//  AppEndpoint  - CatalogRef.FL_Channels - a reference to application endpoint.
//  Identifier   - String                 - identifier as string.
//  ExpectedType - Type                   - expected type.
//
// Returns:
//  AnyRef - the object in this database. 
//
Function LinkedObject(AppEndpoint, Identifier, ExpectedType) Export
    
    Query = New Query;
    Query.Text = QueryTextLinkedObject();
    Query.SetParameter("AppEndpoint", AppEndpoint);
    Query.SetParameter("Identifier", Identifier);
    QueryResultSelection = Query.Execute().Select();
    While QueryResultSelection.Next() Do
        If TypeOf(QueryResultSelection.Object) = ExpectedType Then
            Return QueryResultSelection.Object;
        EndIf;
    EndDo;
    
    Return Undefined;
    
EndFunction // LinkedObject()

#EndRegion // ProgramInterface

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
Function QueryTextLinkedObject()

    QueryText = "
        |SELECT 
        |   LinkedObjects.Object AS Object
        |FROM
        |   InformationRegister.FL_LinkedObjects AS LinkedObjects 
        |WHERE
        |   LinkedObjects.AppEndpoint = &AppEndpoint
        |AND LinkedObjects.Identifier = &Identifier
        |";
    Return QueryText;
    
EndFunction // QueryTextLinkedObject()

// Only for internal use.
//
Function QueryTextLinkedObjectId()

    QueryText = "
        |SELECT 
        |   LinkedObjects.Identifier AS Identifier
        |FROM
        |   InformationRegister.FL_LinkedObjects AS LinkedObjects 
        |WHERE
        |   LinkedObjects.AppEndpoint = &AppEndpoint
        |AND LinkedObjects.Object = &Object
        |";
    Return QueryText;
    
EndFunction // QueryTextLinkedObjectId()

#EndRegion // ServiceProceduresAndFunctions 
    
#EndIf