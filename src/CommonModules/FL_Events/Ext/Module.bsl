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
        Raise NStr("en='It is not possible to cancel an accepted license.';
            |ru='Невозможно аннулировать принятую лицензию.';
            |en_CA='It is not possible to cancel an accepted license.'");    
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
        
    ApplyInvocationData(Source, ?(Source.IsNew(), 
        Catalogs.FL_Operations.Create, 
        Catalogs.FL_Operations.Update));
    
EndProcedure // CatalogBeforeWrite()

// Handler of BeforeDelete catalog event subscription.
//
// Parameters:
//  Source - CatalogObject - catalog object.
//  Cancel - Boolean       - object deletion cancellation flag. If the True value
//                      parameter is included in the procedure-processing body, 
//                      then deletion is not performed.
//                  Default value: False. 
//
Procedure CatalogBeforeDelete(Source, Cancel) Export
    
    If Source.DataExchange.Load OR Cancel Then
        Return;
    EndIf;
        
    ApplyInvocationData(Source, Catalogs.FL_Operations.Delete);
        
    // Full serialization or only guid / code / description?
    //EnqueueEvent(Source);
    
EndProcedure // CatalogBeforeDelete()

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
    
    ApplyInvocationData(Source, ?(Source.IsNew(), 
        Catalogs.FL_Operations.Create, 
        Catalogs.FL_Operations.Update));
     
EndProcedure // DocumentBeforeWrite()

// Handler of BeforeDelete document event subscription.
//
// Parameters:
//  Source - DocumentObject - catalog object.
//  Cancel - Boolean        - document delete flag. If in the body of the handler
//                          procedure a value of this parameter is set to True, 
//                          document deletion will not be executed.
//                  Default value: False. 
//
Procedure DocumentBeforeDelete(Source, Cancel) Export
    
    If Source.DataExchange.Load OR Cancel Then
        Return;
    EndIf;
        
    ApplyInvocationData(Source, Catalogs.FL_Operations.Delete);
        
    // Full serialization or only guid / code / description?
    //EnqueueEvent(Source);
    
EndProcedure // CatalogBeforeDelete()

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
    
    //SourceMetadata = Source.Metadata();
    //MetadataObject = SourceMetadata.FullName();
    //If IsEventPublisher(MetadataObject) Then
    //    
    //    InvocationData = FL_BackgroundJob.NewInvocationData();
    //    InvocationData.MetadataObject = MetadataObject;
    //    
    //    If Replacing Then
    //        
    //        Records = FL_CommonUse.RegisterRecordValues(SourceMetadata, 
    //            Source.Filter);
    //            
    //        InvocationData.Arguments = Records;
    //        InvocationData.Operation = Catalogs.FL_Operations.Delete;
    //        InvocationData.State = Catalogs.FL_States.Awaiting;
    //        
    //        SessionRecords = New Structure;
    //        SessionRecords.Insert("Records", Records);
    //        SessionRecords.Insert("Filter", Source.Filter);
    //        
    //        NewSessionContext = InvocationData.SessionContext.Add();
    //        NewSessionContext.MetadataObject = MetadataObject;
    //        NewSessionContext.Session = FL_EventsReUse.SessionHash();
    //        NewSessionContext.ValueStorage = New ValueStorage(SessionRecords, 
    //            New Deflation(9));
    //        
    //    Else
    //        InvocationData.Operation = Catalogs.FL_Operations.Create;    
    //    EndIf;
    //    
    //    Source.AdditionalProperties.Insert("InvocationData", 
    //        InvocationData);
    //    
    //EndIf;    
          
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

    ApplyInvocationData(Source, Catalogs.FL_Operations.Update, Replacing);
            
EndProcedure // AccumulationRegisterBeforeWrite()

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
    
    If Source.DataExchange.Load OR Cancel Then
        Return;
    EndIf;
    
    //Properties = Source.AdditionalProperties;
    //If NOT IsInvocationDataFilled(InvocationData, Properties) Then
    //    Return;    
    //EndIf;
    //    
    //If Replacing Then
    //    EnqueueEvent(Source);
    //Else
    //    
    //    Query = New Query;
    //    Query.Text = "
    //        |SELECT 
    //        |   SessionContext.Ref AS Ref,
    //        |   SessionContext.ValueStorage AS ValueStorage
    //        |FROM 
    //        |   Catalog.FL_Jobs.SessionContext AS SessionContext
    //        |WHERE 
    //        |    SessionContext.Session = &Session
    //        |AND SessionContext.MetadataObject = &MetadataObject
    //        |";
    //    Query.SetParameter("Session", FL_EventsReUse.SessionHash());
    //    Query.SetParameter("MetadataObject", InvocationData.MetadataObject);
    //    QueryResult = Query.Execute();
    //    
    //EndIf;
    
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
    
    Var InvocationData;
    
    Properties = Source.AdditionalProperties;
    If NOT IsInvocationDataFilled(InvocationData, Properties) Then
        Return;
    EndIf;
    
    // Start measuring.
    InvocationData.CreatedAt = CurrentUniversalDateInMilliseconds();
    FL_BackgroundJob.FillInvocationContext(Source, InvocationData); 

    If InvocationData.Owner = Undefined Then
        
        Publishers = FL_EventsReUse.EventPublishers(InvocationData.MetadataObject, 
            InvocationData.Operation);
            
    Else
        
        Publishers = New Array;
        Publishers.Add(InvocationData.Owner);
        
    EndIf;

    For Each Publisher In Publishers Do
            
        InvocationData.Owner = Publisher;
        InvocationData.Priority = FL_EventsReUse.EventPriority(Publisher, 
            InvocationData.Operation);        
        InvocationData.Source = Source;
        
        FL_BackgroundJob.Enqueue(InvocationData);
        
    EndDo;
      
EndProcedure // EnqueueEvent()

// Returns a new source mock.
//
// Returns:
//  Structure - mock of source event object.
//      * Ref                  - AnyRef     - ref to object.
//      * Filter               - Filter     - it contains the object Filter, for
//                                  which current filtration of records is performed.
//      * AttributeValues      - ValueTable - value table with primary keys values.
//      * AdditionalProperties - Structure  - additional properties.
//          * InvocationData - Structure - see function FL_BackgroundJob.NewInvocationData.
//
Function NewSourceMock() Export
    
    SourceMock = New Structure;
    SourceMock.Insert("Ref");
    SourceMock.Insert("Filter");
    SourceMock.Insert("AttributeValues");
    SourceMock.Insert("AdditionalProperties", New Structure);
    SourceMock.AdditionalProperties.Insert("InvocationData", 
        FL_BackgroundJob.NewInvocationData());     
    Return SourceMock;
    
EndFunction // NewSourceMock()

#EndRegion // ServiceInterface

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
Procedure ApplyInvocationData(Source, Operation, Replacing = False)

    SourceMetadata = Source.Metadata();
    MetadataObject = SourceMetadata.FullName();
    Publishers = FL_EventsReUse.EventPublishers(MetadataObject, Operation);
    If Publishers.Count() = 0 Then
        Return;
    EndIf;

    InvocationData = FL_BackgroundJob.NewInvocationData();
    InvocationData.MetadataObject = MetadataObject;
    InvocationData.Operation = Operation;

    If Replacing Then
        
        If FL_CommonUseReUse.IsAccumulationRegisterTypeObjectCached(MetadataObject) Then
            
            PrimaryKeys = FL_CommonUse.PrimaryKeysByMetadataObject(
                SourceMetadata);
            AttributeValues = FL_CommonUse.RegisterAttributeValues(
                SourceMetadata, Source.Filter, PrimaryKeys);
                     
            FL_BackgroundJob.FillRegisterInvocationContext(InvocationData.InvocationContext, 
                Source.Filter, PrimaryKeys, AttributeValues);
                
            // Do not change this line. It is easy to break passing by reference.
            FL_CommonUse.RemoveDuplicatesFromValueTable(
                InvocationData.InvocationContext);
            
        EndIf;
                
    EndIf;

    Source.AdditionalProperties.Insert("InvocationData", 
        InvocationData);
    
EndProcedure // ApplyInvocationData()

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
    
    If NOT InvocationData.Property("Operation") 
        OR InvocationData.Operation = Undefined Then
        Return False;
    EndIf;
    
    Return True;
    
EndFunction // IsInvocationDataFilled()

#EndRegion // ServiceProceduresAndFunctions