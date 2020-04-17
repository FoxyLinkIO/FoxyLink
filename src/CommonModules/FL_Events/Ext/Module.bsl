////////////////////////////////////////////////////////////////////////////////
// This file is part of FoxyLink.
// Copyright © 2016-2020 Petro Bazeliuk.
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
//  Cancel - Boolean - a write cancel flag. If this parameter is set to True in 
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
            |uk='Неможливо анулювати прийняту ліцензію.';
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
        
    ApplyInvocation(Source, ?(Source.IsNew(), Catalogs.FL_Operations.Create, 
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
        
    ApplyInvocation(Source, Catalogs.FL_Operations.Delete);
    EnqueueEvent(Source);
    
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

// Handler of BeforeWrite chart of characteristic types event subscription.
//
// Parameters:
//  Source - ChartOfCharacteristicTypesObject - chart of characteristic type object.
//  Cancel - Boolean - write cancel flag. If this parameter is set to True in the body 
//                  of the handler procedure, the write transaction will not be completed.
//
Procedure ChartOfCharacteristicTypesBeforeWrite(Source, Cancel) Export
    
    If Source.DataExchange.Load OR Cancel Then
        Return;
    EndIf;
        
    ApplyInvocation(Source, ?(Source.IsNew(), Catalogs.FL_Operations.Create, 
        Catalogs.FL_Operations.Update));
    
EndProcedure // ChartOfCharacteristicTypesBeforeWrite()

// Handler of BeforeDelete chart of characteristic types event subscription.
//
// Parameters:
//  Source - ChartOfCharacteristicTypesObject - catalog object.
//  Cancel - Boolean - object deletion cancellation flag. If the True value
//                      parameter is included in the procedure-processing body, 
//                      then deletion is not performed.
//                  Default value: False. 
//
Procedure ChartOfCharacteristicTypesBeforeDelete(Source, Cancel) Export
    
    If Source.DataExchange.Load OR Cancel Then
        Return;
    EndIf;
        
    ApplyInvocation(Source, Catalogs.FL_Operations.Delete);
    EnqueueEvent(Source);
    
EndProcedure // ChartOfCharacteristicTypesBeforeDelete()

// Handler of OnWrite chart of characteristic types event subscription.
//
// Parameters:
//  Source - ChartOfCharacteristicTypesObject - catalog object.
//  Cancel - Boolean - write cancel flag. If this parameter is set to True in the body 
//                  of the handler procedure, the write transaction will not be completed.
//
Procedure ChartOfCharacteristicTypesOnWrite(Source, Cancel) Export
    
    If Source.DataExchange.Load OR Cancel Then
        Return;
    EndIf;
        
    EnqueueEvent(Source);
    
EndProcedure // ChartOfCharacteristicTypesOnWrite()

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
    
    ApplyInvocation(Source, ?(Source.IsNew(), Catalogs.FL_Operations.Create, 
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
        
    ApplyInvocation(Source, Catalogs.FL_Operations.Delete);
    EnqueueEvent(Source);
    
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

// Handler of BeforeWrite information, accumulation register event subscription.
//
// Parameters:
//  Source    - InformationRegisterRecordSet  - represents a collection of 
//                                  records of information register in memory.
//            - AccumulationRegisterRecordSet - represents a collection of 
//                                  records of accumulation register in memory.
//  Cancel    - Boolean - action execution cancel flag. 
//  Replacing - Boolean - sets write mode. 
//          True  - the set records in the database are replaced by writing.
//          False - the current record set is added to the database by writing. 
//
Procedure RegisterBeforeWrite(Source, Cancel, Replacing) Export
   
    Var DBSource, DBTablePrimaryKeys;
    
    If Source.DataExchange.Load OR Cancel Then
        Return;
    EndIf;
    
    SourceMetadata = Source.Metadata();
    EventSource = SourceMetadata.FullName();
    If NOT Catalogs.FL_Messages.IsPublisher(EventSource) Then
        Return;    
    EndIf;
    
    RecordsCount = Source.Count();
    DBRecordsCount = 0; 
    
    // If Replacing = True, it is needed to check database records if exists
    // to make desicion about the type of operation.
    If Replacing Then
        
        DBTablePrimaryKeys = FL_CommonUse.PrimaryKeysByMetadataObject(
            SourceMetadata);
        DBSource = FL_CommonUse.RegisterAttributeValues(SourceMetadata, 
            Source.Filter, DBTablePrimaryKeys);
        DBRecordsCount = DBSource.Count();
        
    EndIf;
        
    // It is nothing to register, return.
    If RecordsCount = 0 AND DBRecordsCount = 0 Then
        Return;
    EndIf;
    
    Operation = RegisterMessageOperation(RecordsCount, DBRecordsCount, Replacing);
    If NOT Catalogs.FL_Messages.IsMessagePublisher(EventSource, Operation) Then
        Return;    
    EndIf;
    
    Invocation = Catalogs.FL_Messages.NewInvocation();
    Invocation.EventSource = EventSource;
    Invocation.Operation = Operation;
    
    // Saving invocation context.
    If Replacing Then
        FillRegisterContext(Invocation, DBTablePrimaryKeys, Source.Filter, 
            DBSource);   
    EndIf;

    Source.AdditionalProperties.Insert("Invocation", Invocation); 
         
EndProcedure // RegisterBeforeWrite()

// Handler of OnWrite information, accumulation register event subscription.
//
// Parameters:
//  Source    - InformationRegisterRecordSet  - represents a collection of 
//                                  records of information register in memory.
//            - AccumulationRegisterRecordSet - represents a collection of 
//                                  records of accumulation register in memory.
//  Cancel    - Boolean - action execution cancel flag. 
//  Replacing - Boolean - sets write mode. 
//          True  - the set records in the database are replaced by writing.
//          False - the current record set is added to the database by writing. 
//
Procedure RegisterOnWrite(Source, Cancel, Replacing) Export
    
    If Source.DataExchange.Load OR Cancel Then
        Return;
    EndIf;
    
    EnqueueEvent(Source); 
    
EndProcedure // RegisterOnWrite()

#EndRegion // ProgramInterface

#Region ServiceInterface

// Handles event subscription.
//
// Parameters:
//  Source - Arbitrary - arbitrary object.
//
Procedure EnqueueEvent(Source) Export
    
    Var Invocation;
    
    Properties = Source.AdditionalProperties;
    If NOT IsInvocationFilled(Invocation, Properties) Then
        Return;
    EndIf;
    
    // Start measuring.
    Catalogs.FL_Messages.FillContext(Source, Invocation); 
    Catalogs.FL_Messages.Create(Invocation);
    
    // Clear context. 
    Properties.Delete("Invocation");
    
EndProcedure // EnqueueEvent()

#EndRegion // ServiceInterface

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
Procedure ApplyInvocation(Source, Operation)

    SourceMetadata = Source.Metadata();
    EventSource = SourceMetadata.FullName();
    If NOT Catalogs.FL_Messages.IsMessagePublisher(EventSource, Operation) Then
        Return;    
    EndIf;
    
    Invocation = Catalogs.FL_Messages.NewInvocation();
    Invocation.EventSource = EventSource;
    Invocation.Operation = Operation;

    Source.AdditionalProperties.Insert("Invocation", Invocation);
    
EndProcedure // ApplyInvocationData()

// Only for internal use.
//
Procedure FillRegisterContext(Invocation, PrimaryKeys, Filter, Values) 
    
    If FL_CommonUseReUse.IsAccumulationRegisterTypeObjectCached(Invocation.EventSource) 
        OR FL_CommonUseReUse.IsInformationRegisterTypeObjectCached(Invocation.EventSource) Then
               
        Catalogs.FL_Messages.FillRegisterContext(Invocation, Filter, 
            PrimaryKeys, Values);
            
        // Do not change this line. It is easy to break passing by reference.
        FL_CommonUse.RemoveDuplicatesFromValueTable(Invocation.Context);
        
    EndIf;
    
EndProcedure // FillRegisterContext()

// Only for internal use.
//
Function RegisterMessageOperation(RecordsCount, DBRecordsCount, Replacing)
    
    Operation = Catalogs.FL_Operations.Create;    
    If Replacing Then
        
        If RecordsCount > 0 AND DBRecordsCount > 0 Then
            
            // Rewriting records to the database.
            Operation = Catalogs.FL_Operations.Update;
            
        ElsIf RecordsCount > 0 Then    
            
            // Adding current record set to the database.
            Operation = Catalogs.FL_Operations.Create;
            
        Else 
            
            // Deleting current record set from the database.
            Operation = Catalogs.FL_Operations.Delete;
            
        EndIf; 
        
    EndIf;
    
    Return Operation;
    
EndFunction // RegisterMessageOperation()

// Only for internal use.
//
Function IsInvocationFilled(Invocation, Properties)
        
    If NOT Properties.Property("Invocation", Invocation) 
        OR TypeOf(Invocation) <> Type("Structure") Then
        Return False;    
    EndIf;
    
    If NOT Invocation.Property("EventSource")
        OR IsBlankString(Invocation.EventSource) Then
        Return False;
    EndIf;
    
    If NOT Invocation.Property("Operation") 
        OR Invocation.Operation = Undefined Then
        Return False;
    EndIf;
    
    Return True;
    
EndFunction // IsInvocationFilled()

#EndRegion // ServiceProceduresAndFunctions