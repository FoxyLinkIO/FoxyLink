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
// along with this program. If not, see <http://www.gnu.org/licenses/agpl-3.0>.
//
////////////////////////////////////////////////////////////////////////////////

#Region ProgramInterface

// Occurs before license accepted constant recording is executed. A handler 
// procedure is called after the recording transaction is begun but before 
// the recording of the constant is begun.
//
// Parameters:
//  Source - ConstantValueManager.FL_LicenseAccepted - constant object.
//  Cancel - Boolean - write cancel flag. If this parameter is set to True in 
//                     the body of the handler procedure, the write transaction 
//                     will not be completed.
//
Procedure LicenseAcceptedOnWrite(Source, Cancel) Export
    
    If Source.DataExchange.Load OR Cancel Then
        Return;
    EndIf;
    
    ConstantName = Source.Metadata().Name;
    ConstantValue = Source.Value;
    
    If NOT Source.Value Then
        Raise NStr("en = 'It is not possible to cancel an accepted license.';
            |ru = 'Невозможно аннулировать принятую лицензию.'");    
    EndIf;
    
EndProcedure // LicenseAcceptedOnWrite()

// Handler of BeforeWrite catalog event subscription.
//
// Parameters:
//  Source - CatalogObject - catalog object.
//  Cancel - Boolean       - write cancel flag. If this parameter is set to True in the body 
//                  of the handler procedure, the write transaction will not be completed.
//
Procedure CatalogBeforeWrite(Source, Cancel) Export
    
    If Source.DataExchange.Load OR Cancel Then
        Return;
    EndIf;
        
    MetadataObject = Source.Metadata().FullName();
    If IsEventPublisher(MetadataObject) Then 
    
        InvocationData = FL_BackgroundJob.NewInvocationData();
        InvocationData.MetadataObject = MetadataObject;
        
        If Source.IsNew() Then
            InvocationData.Method = Catalogs.FL_Methods.Create;        
        Else
            If Source.DeletionMark Then
                InvocationData.Method = Catalogs.FL_Methods.Delete;       
            Else
                InvocationData.Method = Catalogs.FL_Methods.Update;         
            EndIf;
        EndIf;

        Source.AdditionalProperties.Insert("InvocationData", 
            InvocationData);
        
    EndIf;
    
EndProcedure // CatalogBeforeWrite()

// Handler of BeforeWrite accumulation register event subscription.
//
// Parameters:
//  Source    - AccumulationRegisterRecordSet - represents a collection of 
//                                  records of accumulation register in memory.
//  Cancel    - Boolean - action execution cancel flag. 
//  Replacing - Boolean - sets write mode. 
//          True  - the set records in the database are replaced by writing.
//          False - the current record set is added to the database by writing. 
//
Procedure AccumulationRegisterBeforeWrite(Source, Cancel, Replacing) Export
    
    If Source.DataExchange.Load OR Cancel Then
        Return;
    EndIf;
       
    SourceMetadata = Source.Metadata();
    MetadataObject = SourceMetadata.FullName();
    If IsEventPublisher(MetadataObject) Then
        
        InvocationData = FL_BackgroundJob.NewInvocationData();
        InvocationData.MetadataObject = MetadataObject;
        InvocationData.Method = Catalogs.FL_Methods.Update;
        
        If Replacing Then
            InvocationData.Arguments = FL_CommonUse.RegisterRecordsValues(
                SourceMetadata, Source.Filter);
        EndIf;
        
        Source.AdditionalProperties.Insert("InvocationData", 
            InvocationData);
        
    EndIf;    
          
EndProcedure // AccumulationRegisterBeforeWrite()

// Handler of OnWrite catalog event subscription.
//
// Parameters:
//  Source - CatalogObject - catalog object.
//  Cancel - Boolean       - write cancel flag. If this parameter is set to True in the body 
//                  of the handler procedure, the write transaction will not be completed.
//
Procedure CatalogOnWrite(Source, Cancel) Export
    
    If Source.DataExchange.Load OR Cancel Then
        Return;
    EndIf;
        
    EnqueueEvent(Source);
    
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
Procedure AccumulationRegisterOnWrite(Source, Cancel, Replacing) Export
    
    If Source.DataExchange.Load OR Cancel Then
        Return;
    EndIf;
    
    EnqueueEvent(Source);
    
EndProcedure // AccumulationRegisterOnWrite()

#EndRegion // ProgramInterface

#Region ServiceInterface

// Handles event subscription.
//
// Parameters:
//  Source - Arbitrary - arbitrary object.
//
Procedure EnqueueEvent(Source) Export
    
    Var InvocationData, Arguments;
    
    If NOT IsValidInvocationData(Source, InvocationData) Then
        Return;
    EndIf;
        
    InvocationData.Property("Arguments", Arguments); 
    If TypeOf(Arguments) = Type("ValueTable") Then
        
        FilterItem = Source.Filter.Find("Recorder");
        If FilterItem <> Undefined Then
             InvocationData.SourceObject = FilterItem.Value;    
        EndIf;
        
        FL_CommonUseClientServer.ExtendValueTable(Source.Unload(), 
            Arguments);
            
    ElsIf FL_CommonUse.IsReferenceTypeObjectByMetadataObjectName(
        InvocationData.MetadataObject) Then
        
        InvocationData.Arguments = Source.Ref;
        InvocationData.SourceObject = Source.Ref;
        
    EndIf;
                    
    Query = New Query;
    Query.Text = QueryTextSubscribers(InvocationData.Owner);
    Query.SetParameter("MetadataObject", InvocationData.MetadataObject);
    Query.SetParameter("Method", InvocationData.Method);
    Query.SetParameter("Owner", InvocationData.Owner);
    QueryResult = Query.Execute();
    If NOT QueryResult.IsEmpty() Then
        
        QueryResultSelection = QueryResult.Select();
        While QueryResultSelection.Next() Do
            
            FillPropertyValues(InvocationData, QueryResultSelection);
            FL_BackgroundJob.Enqueue("Catalogs.FL_Jobs.ProcessMessage", 
                InvocationData);   
        EndDo;
        
    EndIf;  
    
EndProcedure // EnqueueEvent()

// Returns a new source mock.
//
// Returns:
//  Structure - mock of source event object.
//      * Ref                  - AnyRef    - ref to object.
//      * AdditionalProperties - Structure - additional properties.
//          * InvocationData - Structure - see function FL_BackgroundJob.NewInvocationData.
//
Function NewSourceMock() Export
    
    SourceMock = New Structure;
    SourceMock.Insert("Ref");
    SourceMock.Insert("AdditionalProperties", New Structure);
    SourceMock.AdditionalProperties.Insert("InvocationData", 
        FL_BackgroundJob.NewInvocationData());     
    Return SourceMock;
    
EndFunction // NewSourceMock()

#EndRegion // ServiceInterface

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
Function IsEventPublisher(MetadataFullName)
    
    EventPublishers = FL_EventsReUse.EventPublishers();
    If EventPublishers.Find(MetadataFullName) <> Undefined Then 
        Return True;    
    Else
        Return False;
    EndIf;
    
EndFunction // IsEventPublisher()

// Only for internal use.
//
Function IsValidInvocationData(Source, InvocationData)
    
    If Source.AdditionalProperties.Property("ResponseHandler")
        AND Source.AdditionalProperties.FL_ResponseHandler Then
        Return False;    
    EndIf;
    
    If NOT Source.AdditionalProperties.Property("InvocationData", InvocationData) 
        OR TypeOf(InvocationData) <> Type("Structure") Then
        Return False;    
    EndIf;
    
    If InvocationData.Method = Undefined 
        OR IsBlankString(InvocationData.MetadataObject) Then
        Return False;
    EndIf;
    
    Return True;
    
EndFunction // IsValidInvocationData()

// Only for internal use.
//
Function QueryTextSubscribers(Owner)
    
    QueryText = StrTemplate("
        |SELECT
        |   Events.Ref              AS Owner,
        |   Events.APIVersion       AS APIVersion
        |FROM
        |   Catalog.FL_Exchanges.Events AS Events
        |WHERE
        // [OPPX|OPHP1 +] Attribute + Ref
        |    Events.MetadataObject = &MetadataObject 
        |%1
        |AND Events.Method         = &Method
        |
        |", ?(Owner = Undefined, "", "AND Events.Ref = &Owner "));
    Return QueryText;
    
EndFunction // QueryTextSubscribers()

#EndRegion // ServiceProceduresAndFunctions