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

#Region ProgramInterface

// Handler of BeforeWrite catalog event subscription.
//
// Parameters:
//  Source - CatalogObject - catalog object.
//  Cancel - Boolean       - write cancel flag. If this parameter is set to True in the body 
//                  of the handler procedure, the write transaction will not be completed.
//
Procedure CatalogBeforeWrite(SourceObject, Cancel) Export
    
    If Cancel = False Then
        
        AdditionalProperties = NewAdditionalProperties();
        AdditionalProperties.IsNew = SourceObject.IsNew();
        SourceObject.AdditionalProperties.Insert("FL_EventProperties", 
            AdditionalProperties);
            
    EndIf;
    
EndProcedure // CatalogBeforeWrite()


// Handler of OnWrite catalog event subscription.
//
// Parameters:
//  SourceObject - CatalogObject - catalog object.
//  Cancel       - Boolean       - write cancel flag. If this parameter is set to True in the body 
//                  of the handler procedure, the write transaction will not be completed.
//
Procedure CatalogOnWrite(SourceObject, Cancel) Export
    
    Var Method;
    
    If SourceObject.AdditionalProperties.Property("FL_ResponseHandler")
     And SourceObject.AdditionalProperties.FL_ResponseHandler = True Then
        Return;    
    EndIf;
    
    If Cancel = False Then
        
        // Start measuring.
        StartTime = CurrentUniversalDateInMilliseconds();
        
        MetadataObject = SourceObject.Metadata().FullName();
        
        AdditionalProperties = SourceObject.AdditionalProperties.FL_EventProperties;
        If AdditionalProperties.IsNew = True Then
            Method = Catalogs.FL_Methods.Create;        
        Else
            If SourceObject.DeletionMark = False Then
                Method = Catalogs.FL_Methods.Update;        
            Else
                Method = Catalogs.FL_Methods.Delete;    
            EndIf;
        EndIf;
        
        Query = New Query;
        Query.Text = QueryTextSubscribers();
        Query.SetParameter("Method", Method);
        Query.SetParameter("MetadataObject", MetadataObject);
        QueryResult = Query.Execute();
        
        If QueryResult.IsEmpty() = False Then
            
            ValueTable = QueryResult.Unload();
            For Each TableRow In ValueTable Do
                Catalogs.FL_Jobs.CreateMessage(SourceObject.Ref,
                    FL_CommonUse.ValueTableRowIntoStructure(TableRow));      
            EndDo;
            
        EndIf;
        
        // End measuring.
        ExecutionTime = CurrentUniversalDateInMilliseconds() - StartTime;
                
    EndIf;
    
EndProcedure // CatalogOnWrite()

// Handler of OnWrite accumulation register event subscription.
//
// Parameters:
//  Source    - AccumulationRegisterRecordSet - represents a collection of 
//                                  records of accumulation register in memory.
//  Cancel    - Boolean - action execution cancel flag. 
//  Replacing - Boolean - sets write mode. 
//          True  - the set records in the database are replaced by writing.
//          False - the current record set is added to the database by writing. 
//
Procedure FL_AccumulationRegisterOnWrite(Source, Cancel, Replacing) Export
    
    If Cancel = False Then
        
        
        
    EndIf;
    
EndProcedure // FL_AccumulationRegisterOnWrite()

#EndRegion // ProgramInterface

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
Function NewAdditionalProperties()
    
    AdditionalProperties = New Structure;
    AdditionalProperties.Insert("IsNew");
    Return AdditionalProperties;
    
EndFunction // NewAdditionalProperties()

// Only for internal use.
//
Function QueryTextSubscribers()

    QueryText = "
        |SELECT
        |   Events.Ref              AS Owner,
        |   Events.APIVersion       AS APIVersion,
        //|   Events.EventName        AS EventName,
        |   Events.MetadataObject   AS MetadataObject, 
        |   Events.Method           AS Method
        |FROM
        |   Catalog.FL_Exchanges.Events AS Events
        |WHERE
        |    Events.MetadataObject = &MetadataObject
        |AND Events.Method         = &Method
        |";
    Return QueryText;
    
EndFunction // QueryTextSubscribers()

#EndRegion // ServiceProceduresAndFunctions
