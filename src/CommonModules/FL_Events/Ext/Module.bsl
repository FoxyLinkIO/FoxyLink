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

// Handler of BeforeWrite document event subscription.
//
// Parameters:
//  Source      - DocumentObject      - document object.
//  Cancel      - Boolean             - write cancel flag. If this parameter is
//                  set to True in the body of the handler procedure, the write 
//                  transaction will not be completed.
//  WriteMode   - DocumentWriteMode   - write cancel flag. If the parameter value 
//                  is set to True in the body of the handler procedure, writing 
//                  is not performed and the exception is raised.
//  PostingMode - DocumentPostingMode - a current posting mode is passed to this 
//                  parameter. Changing this parameter enables the user to change 
//                  the posting mode. 
//
Procedure DocumentBeforeWrite(Source, Cancel, WriteMode, PostingMode) Export
    
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
    
EndProcedure // DocumentBeforeWrite()

// Handler of BeforeWrite information register event subscription.
//
// Parameters:
//  Source    - InformationRegisterRecordSet - represents a collection of 
//                                  records of information register in memory.
//  Cancel    - Boolean - action execution cancel flag. 
//  Replacing - Boolean - sets write mode. 
//          True  - the set records in the database are replaced by writing.
//          False - the current record set is added to the database by writing. 
//
Procedure InformationRegisterBeforeWrite(Source, Cancel, Replacing) Export
    
    If Source.DataExchange.Load OR Cancel Then
        Return;
    EndIf;
    
    SourceMetadata = Source.Metadata();
    MetadataObject = SourceMetadata.FullName();
    If IsEventPublisher(MetadataObject) Then
        
        InvocationData = FL_BackgroundJob.NewInvocationData();
        InvocationData.MetadataObject = MetadataObject;
        
        If Replacing Then
            
            Records = FL_CommonUse.RegisterRecordValues(SourceMetadata, 
                Source.Filter);
                
            InvocationData.Arguments = Records;
            InvocationData.Method = Catalogs.FL_Methods.Delete;
            InvocationData.State = Catalogs.FL_States.Awaiting;
            
            SessionRecords = New Structure;
            SessionRecords.Insert("Records", Records);
            SessionRecords.Insert("Filter", Source.Filter);
            
            NewSessionContext = InvocationData.SessionContext.Add();
            NewSessionContext.MetadataObject = MetadataObject;
            NewSessionContext.Session = FL_EventsReUse.SessionHash();
            NewSessionContext.ValueStorage = New ValueStorage(SessionRecords, 
                New Deflation(9));
            
        Else
            InvocationData.Method = Catalogs.FL_Methods.Create;    
        EndIf;
        
        Source.AdditionalProperties.Insert("InvocationData", 
            InvocationData);
        
    EndIf;    
          
EndProcedure // InformationRegisterBeforeWrite()

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
            InvocationData.Arguments = FL_CommonUse.RegisterRecordValues(
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

// Handler of OnWrite document event subscription.
//
// Parameters:
//  Source - DocumentObject - document object.
//  Cancel - Boolean       - write cancel flag. If this parameter is set to True in the body 
//                  of the handler procedure, the write transaction will not be completed.
//
Procedure DocumentOnWrite(Source, Cancel) Export
    
    If Source.DataExchange.Load OR Cancel Then
        Return;
    EndIf;
        
    EnqueueEvent(Source);
    
EndProcedure // DocumentOnWrite()

// Handler of OnWrite information register event subscription.
//
// Parameters:
//  Source    - InformationRegisterRecordSet - represents a collection of 
//                                  records of information register in memory.
//  Cancel    - Boolean - action execution cancel flag. 
//  Replacing - Boolean - sets write mode. 
//          True  - the set records in the database are replaced by writing.
//          False - the current record set is added to the database by writing. 
//
Procedure InformationRegisterOnWrite(Source, Cancel, Replacing) Export
    
    Var InvocationData;
    
    If Source.DataExchange.Load OR Cancel Then
        Return;
    EndIf;
    
    Properties = Source.AdditionalProperties;
    If NOT IsInvocationDataFilled(InvocationData, Properties) Then
        Return;    
    EndIf;
        
    If Replacing Then
        EnqueueEvent(Source);
    Else
        
        Query = New Query;
        Query.Text = "
            |SELECT 
            |   SessionContext.Ref AS Ref,
            |   SessionContext.ValueStorage AS ValueStorage
            |FROM 
            |   Catalog.FL_Jobs.SessionContext AS SessionContext
            |WHERE 
            |    SessionContext.Session = &Session
            |AND SessionContext.MetadataObject = &MetadataObject
            |";
        Query.SetParameter("Session", FL_EventsReUse.SessionHash());
        Query.SetParameter("MetadataObject", InvocationData.MetadataObject);
        QueryResult = Query.Execute();
        
    EndIf;
    
EndProcedure // InformationRegisterOnWrite()

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
// Returns:
//  Array - refs to enqueued background jobs.
//
Procedure EnqueueEvent(Source) Export
    
    Var InvocationData, Arguments;
    
    Properties = Source.AdditionalProperties;
    If NOT IsInvocationDataFilled(InvocationData, Properties) Then
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
            
    ElsIf FL_CommonUseReUse.IsReferenceTypeObjectCached(
        InvocationData.MetadataObject) Then
        
        InvocationData.Arguments = Source.Ref;
        InvocationData.SourceObject = Source.Ref;
        
    EndIf;
    
    EnqueueBackgroundJobs(InvocationData);  
    
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

// Enqueues a new fire-and-forget jobs based on invocation data.
//
// Parameters:
//  InvocationData - Structure - see function FL_BackgroundJob.NewInvocationData.
//
Procedure EnqueueBackgroundJobs(InvocationData)
    
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
            FL_BackgroundJob.Enqueue("Catalogs.FL_Jobs.Trigger", 
                InvocationData);   
        EndDo;
        
    EndIf;
    
EndProcedure // EnqueueBackgroundJobs()

// Only for internal use.
//
Function IsInvocationDataFilled(InvocationData, Properties)
        
    If NOT Properties.Property("InvocationData", InvocationData) 
        OR TypeOf(InvocationData) <> Type("Structure") Then
        Return False;    
    EndIf;
    
    If NOT InvocationData.Property("MetadataObject")
        OR IsBlankString(InvocationData.MetadataObject) Then
        Return False;
    EndIf;
    
    If NOT InvocationData.Property("Method") 
        OR InvocationData.Method = Undefined Then
        Return False;
    EndIf;
    
    Return True;
    
EndFunction // IsInvocationDataFilled()

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
Function QueryTextSubscribers(Owner)
    
    QueryText = StrTemplate("
        |SELECT
        |   Events.APIVersion       AS APIVersion,
        |   Exchanges.Ref           AS Owner,
        |   Methods.Priority        AS Priority
        |FROM
        |   Catalog.FL_Exchanges AS Exchanges
        |
        |INNER JOIN Catalog.FL_Exchanges.Events AS EventTable
        // [OPPX|OPHP1 +] Attribute + Ref
        |ON  EventTable.MetadataObject = &MetadataObject
        |AND EventTable.Ref            = Exchanges.Ref
        |AND EventTable.Method         = &Method
        |
        |INNER JOIN Catalog.FL_Exchanges.Methods AS MethodTable
        |ON  MethodTable.Ref        = Exchanges.Ref
        |AND MethodTable.Method     = EventTable.Method
        |AND MethodTable.APIVersion = EventTable.APIVersion
        |
        |WHERE
        |%1 
        |   Exchanges.InUse = True
        |
        |", ?(Owner = Undefined, "", "Exchanges.Ref = &Owner AND "));
    Return QueryText;
    
EndFunction // QueryTextSubscribers()

#EndRegion // ServiceProceduresAndFunctions