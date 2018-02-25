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

#Region ProgramInterface

// Creates a new fire-and-forget job based on a given method call expression.
//
// Parameters:
//  InvocationData - Structure - see function FL_BackgroundJob.NewInvocationData. 
//                          Default value: Undefined.
//
// Returns:
//  CatalogRef.FL_Jobs - ref to created background job or 
//                       Undefined, if it was not created.
//
Function Enqueue(InvocationData) Export

    Return Catalogs.FL_Jobs.Create(InvocationData, InvocationData.State);
    
EndFunction // Enqueue()

// Changes state of a job with the specified Job to the DeletedState. 
// If FromState value is not undefined, state change will be performed 
// only if the current state name of the job equal to the given value.
//
// Parameters:
//  Job       - CatalogRef.FL_Jobs   - .
//            - UUID                 - .
//  FromState - CatalogRef.FL_States - current state assertion.
//            - String               - .
//                  Default value: Undefined.
//
// Returns:
//  Boolean - True, if state change succeeded, otherwise False.
//
Function Delete(Job, FromState = Undefined) Export

    Return False;
    
EndFunction // Delete()

// Changes state of a job with the specified parameter Job to the EnqueuedState.
// If FromState value is not undefined, state change will be performed 
// only if the current state name of the job equal to the given value.
//
// Parameters:
//  Job       - CatalogRef.FL_Jobs   - .
//            - UUID                 - .
//  FromState - CatalogRef.FL_States - current state assertion.
//            - String               - .
//                  Default value: Undefined.
//
// Returns:
//  Boolean - True, if state change succeeded, otherwise False.
//
Function Requeue(Job, FromState = Undefined) Export

    Return False;
    
EndFunction // Requeue()

// Creates a new background job that will wait for a successful completion 
// of another background job to be triggered in the EnqueuedState.
//
// Returns:
//  CatalogRef.FL_Jobs - ref to created background job or 
//                       Undefined, if it was not created.
//
Function ContinueWith() Export

    Return False;
    
EndFunction // ContinueWith()

// Creates a new background job based on a specified instance method
// call expression and schedules it to be enqueued after a given delay.
//
// Returns:
//  CatalogRef.FL_Jobs - ref to created background job or 
//                       Undefined, if it was not created.
//
Function Schedule() Export

    Return False;
    
EndFunction // Schedule()

#EndRegion // ProgramInterface

#Region ServiceIterface

// Adds data to invocation context.
//
// Parameters:
//  Context    - ValueTable - see function FL_BackgroundJob.NewInvocationContext. 
//  PrimaryKey - String     - the name of primary key.
//  Value      - Arbitrary  - the value of primary key.
//  Filter     - Boolean    - defines if primary key is used.
//                  Default value: False.
//
Procedure AddToInvocationContext(Context, PrimaryKey, Value, 
    Filter = False) Export
      
    NewContextItem = Context.Add();
    NewContextItem.Filter = Filter;
    NewContextItem.PrimaryKey = Upper(PrimaryKey);
    NewContextItem.XMLValue = XMLString(Value);
    FillPropertyValues(NewContextItem, XMLTypeOf(Value));
    
EndProcedure // AddToInvocationContext()

// Fills invocation context data.
//
// Parameters:
//  Source         - Arbitrary - source object.
//  InvocationData - Structure - see function FL_BackgroundJob.NewInvocationData. 
//
Procedure FillInvocationContext(Source, InvocationData) Export
    
    MetadataObject = InvocationData.MetadataObject;
    If FL_CommonUseReUse.IsReferenceTypeObjectCached(MetadataObject) Then
        
        AddToInvocationContext(InvocationData.InvocationContext, "Ref", 
            Source.Ref, True);
            
    ElsIf FL_CommonUseReUse.IsInformationRegisterTypeObjectCached(MetadataObject)
        OR FL_CommonUseReUse.IsAccumulationRegisterTypeObjectCached(MetadataObject) Then

        PrimaryKeys = FL_CommonUse.PrimaryKeysByMetadataObject(
            MetadataObject(Source, MetadataObject));
        FillRegisterInvocationContext(InvocationData.InvocationContext, 
            Source.Filter, PrimaryKeys, AttributeValues(Source));
              
    EndIf;
    
    // Do not change this line. It is easy to break passing by reference.
    FL_CommonUse.RemoveDuplicatesFromValueTable(
        InvocationData.InvocationContext);
    
EndProcedure // FillInvocationContext() 

// Fills accumulation register invocation context.
//
// Parameters:
//  Context          - ValueTable - see function FL_BackgroundJob.NewInvocationContext.
//  Filter           - Filter     - it contains the object Filter, for which 
//                                  current filtration of records is performed.
//  PrimaryKeys      - Structure  - see function FL_CommonUse.PrimaryKeysByMetadataObject.
//  AttributesValues - ValueTable - value table with primary keys values.
//
Procedure FillRegisterInvocationContext(Context, Filter, 
    PrimaryKeys, AttributesValues) Export
    
    For Each PrimaryKey In PrimaryKeys Do
            
        FilterValue = Filter.Find(PrimaryKey.Key);
        If FilterValue <> Undefined Then
            AddToInvocationContext(Context, PrimaryKey.Key, 
                FilterValue.Value, FilterValue.Use);
            Continue;
        EndIf;
        
        ColumnValues = AttributesValues.UnloadColumn(PrimaryKey.Key);
        For Each ColumnValue In ColumnValues Do
            AddToInvocationContext(Context, PrimaryKey.Key, ColumnValue);   
        EndDo;
        
    EndDo;    
    
EndProcedure // FillRegisterInvocationContext()

// Returns a new invocation data for a service method.
//
// Returns:
//  Structure - the invocation data structure with keys:
//      * CreatedAt         - Number                   - invocation data creation time.
//      * MetadataObject    - String                   - the full name of a metadata
//                                                   object as a term.
//                                  Default value: "".
//      * MethodName        - String                   - name of non-global common 
//                                                    module method having the 
//                                                    ModuleName.MethodName form.
//                              Default value: "Catalogs.FL_Jobs.Trigger".
//      * Operation         - CatalogReg.FL_Operations - operation.
//      * Owner             - CatalogReg.FL_Exchanges  - an owner of invocation data.
//                                  Default value: Undefined.
//      * Priority          - Number(1,0)              - job priority.
//                                  Default value: 5.
//      * State             - CatalogRef.FL_States     - new state for a background job.
//                                  Default value: Catalogs.FL_States.Enqueued.
//      * InvocationContext - ValueTable               - invocation context.
//      * SessionContext    - ValueTable               - session context.
//      * Source            - AnyRef                   - an event source object.
//                                  Default value: Undefined.
//
Function NewInvocationData() Export
    
    NormalPriority = 5;
    
    InvocationData = New Structure;
    
    // Attributes section
    InvocationData.Insert("CreatedAt", CurrentUniversalDateInMilliseconds());
    InvocationData.Insert("MetadataObject", "");
    InvocationData.Insert("MethodName", "Catalogs.FL_Jobs.Trigger");
    InvocationData.Insert("Operation");
    InvocationData.Insert("Owner");
    InvocationData.Insert("Priority", NormalPriority);
    InvocationData.Insert("State", Catalogs.FL_States.Enqueued);
    
    // Tabular section
    InvocationData.Insert("InvocationContext", NewInvocationContext());
    InvocationData.Insert("SessionContext", NewSessionContext());

    // Technical section
    InvocationData.Insert("Source", Undefined);
    
    Return InvocationData;
    
EndFunction // NewInvocationData()

#EndRegion // ServiceIterface 

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
Function AttributeValues(SourceMock)
    
    If TypeOf(SourceMock) = Type("Structure") Then
        Return SourceMock.AttributeValues;    
    EndIf;
    
    Return SourceMock.Unload();       
    
EndFunction // AttributeValues()

// Only for internal use.
//
Function MetadataObject(SourceMock, MetadataObjectMock)
    
    If TypeOf(SourceMock) = Type("Structure") Then
        Return Metadata.FindByFullName(MetadataObjectMock);       
    EndIf;
    
    Return SourceMock.Metadata();
    
EndFunction // MetadataObject() 

// Only for internal use.
//
Function NewInvocationContext()
    
    KeyLength = 30;
    TypeLength = 50;
    ValueLenght = 100;
    
    Context = New ValueTable;
    Context.Columns.Add("Filter", New TypeDescription("Boolean"));
    Context.Columns.Add("NamespaceURI", FL_CommonUse.StringTypeDescription(
        TypeLength));
    Context.Columns.Add("PrimaryKey", FL_CommonUse.StringTypeDescription(
        KeyLength));
    Context.Columns.Add("TypeName", FL_CommonUse.StringTypeDescription(
        TypeLength));
    Context.Columns.Add("XMLValue", FL_CommonUse.StringTypeDescription(
        ValueLenght));
    Return Context;
    
EndFunction // NewInvocationContext()

// Only for internal use.
//
Function NewSessionContext()
    
    MaxSessionLength = 36;
    MaxMetadataObjectLength = 80;
    
    SessionContext = New ValueTable;
    SessionContext.Columns.Add("MetadataObject", 
        FL_CommonUse.StringTypeDescription(MaxMetadataObjectLength));
    SessionContext.Columns.Add("Session", 
        FL_CommonUse.StringTypeDescription(MaxSessionLength));
    SessionContext.Columns.Add("ValueStorage", 
        New TypeDescription("ValueStorage"));
    Return SessionContext;
    
EndFunction // NewSessionContext() 

#EndRegion // ServiceProceduresAndFunctions