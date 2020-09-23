////////////////////////////////////////////////////////////////////////////////
// This file is part of FoxyLink.
// Copyright © 2016-2019 Petro Bazeliuk.
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

// Used to run a job now. The information about triggered invocation will not 
// be recorded in the recurring job itself, and its next execution time will 
// not be recalculated from this running. For example, if you have a weekly job
// that runs on Wednesday, and you manually trigger it on Friday it will run on 
// the following Wednesday.
//
// Parameters:
//  Jobs          - Array              - array of references to the jobs to be triggered.
//                - CatalogRef.FL_Jobs - reference to the job to be triggered.
//  Invoke        - Boolean            - if True triggers all subordinate jobs during this call.
//                          Default value: False.
//  JobResultCopy - Structure          - returns the copy of last job result execution.
//                                       See function Catalogs.FL_Jobs.NewJobResult.
//                          Default value: Undefined.
//
Procedure Trigger(Jobs, Invoke = False, JobResultCopy = Undefined) Export
       
    ValidJobs = New Array;
    ValidateJobType(ValidJobs, Jobs);
    
    For Each Job In ValidJobs Do
        
        If TransactionActive() 
            OR FL_CommonUse.ObjectAttributeValue(Job, "Transactional") Then
            
            // Helps to avoid hierarchical transaction errors.
            ProcessJob(Job, Invoke, , JobResultCopy);
            
        Else
            
            StartTime = CurrentUniversalDateInMilliseconds();
            
            BeginTransaction();
            Try 
                
                ProcessJob(Job, Invoke, , JobResultCopy);
                CommitTransaction();
                
            Except
                
                RollbackTransaction();
                
                ErrorInfo = ErrorInfo();
                FL_InteriorUse.WriteLog("FoxyLink.Tasks.Trigger", 
                    EventLogLevel.Error,
                    Metadata.Catalogs.FL_Jobs,
                    ErrorInfo);
                                    
                Duration = CurrentUniversalDateInMilliseconds() - StartTime;
                ChangeState(Job, Catalogs.FL_States.Failed, , Duration);  
                
            EndTry;
            
        EndIf;
                
    EndDo;
           
EndProcedure // Trigger()

// Creates a new background job in a specified state.
//
// Parameters:
//  JobData - FixedStructure - job that should be processed in background.
//
// Returns:
//  CatalogRef.FL_Jobs - ref to created background job or Undefined, if it was 
//                       not created.
//
Function Create(JobData) Export
            
    JobObject = Catalogs.FL_Jobs.CreateItem();
    
    ListOfProperties = "CreatedAt, 
        |ExpireAt,
        |Invoke,
        |Isolated,
        |MethodName, 
        |Priority, 
        |State, 
        |Transactional";
    FillPropertyValues(JobObject, JobData, ListOfProperties); 
    CopyToInputOutputTable(JobObject.Input, JobData.Input);
    CopyToInputOutputTable(JobObject.Output, JobData.Output);
    
    If JobData.Property("Log") 
        AND TypeOf(JobData.Log) = Type("ValueTable") Then
        JobObject.Log.Load(JobData.Log);    
    EndIf;
    
    BeginTransaction();
    Try
        
        JobObject.Write();
        If JobData.Continuations <> Undefined Then
            InformationRegisters.FL_JobContinuations.RegisterContinuation(
                JobData.Continuations, JobObject.Ref);        
        EndIf;

        CommitTransaction();
        
    Except
        
        RollbackTransaction();
        
        FL_InteriorUse.WriteLog("FoxyLink.Tasks.Create", 
            EventLogLevel.Error,
            Metadata.Catalogs.FL_Jobs,
            ErrorDescription());
               
        Return Undefined;
        
    EndTry; 
        
    // End measuring and recording performance metrics.
    RecordJobObjectPerformanceMetrics(JobObject); 
      
    Return JobObject.Ref;

EndFunction // Create()

// Attempts to change a state of a background job with a given identifier 
// to a specified one.
//
// Parameters:
//  Job           - CatalogRef.FL_Jobs           - job, whose state should be changed.
//  State         - CatalogRef.FL_States         - new state for a background job.
//  ExpectedState - String, CatalogRef.FL_States - value is not Undefined, 
//                          state change will be performed only if the current 
//                          state name of a job equal to the given value.
//                                  Default value: Undefined.
//  Duration      - Number                       - performance duration (ms).
//
// Returns:
//  Boolean - True, if a given state was applied successfully otherwise False.
//
Function ChangeState(Job, State, ExpectedState = Undefined, Duration = 0) Export
    
    CurrentState = FL_CommonUse.ObjectAttributeValue(Job, "State");
    If ExpectedState <> Undefined 
        AND Upper(String(ExpectedState)) <> Upper(String(CurrentState)) Then
        Return False;             
    EndIf;
    
    JobObject = Job.GetObject();
    SetExpirationDate(JobObject.ExpireAt);
    JobObject.State = State;
    JobObject.Write();
    
    RecordJobPerformanceMetrics(Job, State, Duration);
                
    Return True;
    
EndFunction // ChangeState()

#EndRegion // ProgramInterface

#Region ServiceInterface

// This procedure adds the value into input data parameters.
//
// Parameters:
//  JobData - Structure - see function Catalogs.FL_Jobs.NewJobData.
//  Name    - String    - parameter name.
//  Value   - Arbitrary - parameter value.
//
Procedure AddToJobInputData(JobData, Name, Value) Export
    
    InputParameter = JobData.Input.Add();
    InputParameter.Name = Name;
    InputParameter.Value = Value;
    
EndProcedure // AddToJobInputData()

// This procedure adds the value into output data parameters.
//
// Parameters:
//  JobData - Structure - see function Catalogs.FL_Jobs.NewJobData.
//  Name    - String    - parameter name.
//  Value   - Arbitrary - parameter value.
//
Procedure AddToJobOutputData(JobData, Name, Value) Export
    
    OutputParameter = JobData.Output.Add();
    OutputParameter.Name = Name;
    OutputParameter.Value = Value;
    
EndProcedure // AddToJobOutputData()

// This procedure adds the result to the output parameters table.
//
// Parameters:
//  JobResult - Structure - see function Catalogs.FL_Jobs.NewJobResult.
//  Name      - String    - parameter name.
//  Value     - Arbitrary - parameter value.
//
Procedure AddToJobResult(JobResult, Name, Value) Export
    
    NewOutputRow = JobResult.Output.Add();    
    NewOutputRow.Name = Name;
    NewOutputRow.Value = Value;
    
EndProcedure // AddToJobResult()

// The function returns field value by the passed field name from the job result.
//
// Parameters:
//  JobResult    - Structure - see function Catalogs.FL_Jobs.NewJobResult.
//  Name         - String    - parameter name.
//  DefaultValue - Arbitrary - default value if exist.
//                      Default value: Undefined.
//
// Returns:
//  Arbitrary - parameter value.
//  Undefined, Arbitrary - field value not found; default value returns.
// 
Function GetFromJobResult(JobResult, Name, DefaultValue = Undefined) Export
    
    FilterParameters = New Structure("Name", Name);
    FilterResults = JobResult.Output.FindRows(FilterParameters);
    If FilterResults.Count() = 1 Then
        Return FilterResults[0].Value;   
    EndIf;
    
    Return DefaultValue;
    
EndFunction // GetFromJobResult()

// Returns a new job data for a service method.
//
// Returns:
//  Structure - the invocation data structure with keys:
//      * Continuations - CatalogRef.FL_Jobs   - job to be launched after 
//                              successful completion current background job.
//                                  Default value: Undefined.
//      * CreatedAt     - Number               - job data creation time.
//      * ExpireAt      - Number               - job data expiration time.
//      * Invoke        - Boolean              - if True triggers all subordinate jobs during single call.
//                                  Default value: False.
//      * Isolated      - Boolean              - helps to protect each job from other jobs.
//                                  Default value: False.      
//      * MethodName    - String               - name of non-global common 
//                              module method having the ModuleName.MethodName form.
//      * Priority      - Number(1,0)          - job priority.
//                                  Default value: 5.
//      * State         - CatalogRef.FL_States - new state for a background job.
//                                  Default value: Catalogs.FL_States.Enqueued.
//      * Transactional - Boolean              - method creates implicit transactions.
//                                  Default value: False.
//      * Input         - ValueTable           - input parameters.
//          ** Name  - String    - parameter name.
//          ** Value - Arbitrary - parameter value.
//      * Output        - ValueTable           - output parameters.
//          ** Name  - String    - parameter name.
//          ** Value - Arbitrary - parameter value.
//
Function NewJobData() Export
    
    NormalPriority = 5;
    JobData = New Structure;
    
    // Attributes section
    JobData.Insert("Continuations");
    JobData.Insert("CreatedAt", CurrentUniversalDateInMilliseconds());
    JobData.Insert("ExpireAt");
    JobData.Insert("Invoke", False);
    JobData.Insert("Isolated", False);
    JobData.Insert("MethodName");
    JobData.Insert("Priority", NormalPriority);
    JobData.Insert("State", Catalogs.FL_States.Enqueued);
    JobData.Insert("Transactional", False);
    
    // Tabular section
    JobData.Insert("Input", NewInputOutputTable());
    JobData.Insert("Output", NewInputOutputTable());

    Return JobData;
    
EndFunction // NewJobData()

// Returns a new job result structure.
//
// Parameters:
//  Log - Boolean - shows whether log is to be turned on.
//          Default value: False.
//
// Returns:
//  Structure - the new job result with values:
//      * AppEndpoint  - CatalogRef.FL_Channels - reference to the app endpoint.
//      * LogAttribute - String     - detailed log of the job processing.
//      * StatusCode   - Number     - state (reply) code returned by the service.
//      * Success      - Boolean    - shows whether delivery was successful.
//                          Default value: False.
//      * Output       - ValueTable - output parameters.
//          ** Name  - String    - parameter name.
//          ** Value - Arbitrary - parameter value.
//
Function NewJobResult(Log = False) Export

    JobResult = New Structure;
    JobResult.Insert("AppEndpoint");
    JobResult.Insert("LogAttribute");
    JobResult.Insert("StatusCode");
    JobResult.Insert("Success", False);
    JobResult.Insert("Output", NewInputOutputTable());

    If Log Then
        JobResult.LogAttribute = "";    
    EndIf;
    
    Return JobResult;
    
EndFunction // NewJobResult()

#EndRegion // ServiceInterface

#Region ServiceProceduresAndFunctions

#Region InputOutput

// Only for internal use.
//
Procedure AddToInputOutputTable(Row, Name = "", Value = Undefined)
    
    MaxDeflation = 9;
    Row.Name = Name;
    Row.Value = New ValueStorage(Value, New Deflation(MaxDeflation));
    
EndProcedure // AddToInputOutputTable()

// Only for internal use.
//
Procedure CopyToInputOutputTable(TabularSection, ValueTable)
    
    If TypeOf(ValueTable) <> Type("ValueTable") 
        OR NOT ValueIsFilled(ValueTable) Then
        Return;
    EndIf;
    
    For Each Row In ValueTable Do
        AddToInputOutputTable(TabularSection.Add(), Row.Name, Row.Value);
    EndDo;   
    
EndProcedure // CopyToInputOutputTable() 

// Only for internal use.
//
Function NewInputOutputTable()
    
    NameLength = 36;
    
    VTable = New ValueTable;
    VTable.Columns.Add("Name", FL_CommonUse.StringTypeDescription(NameLength));
    VTable.Columns.Add("Value");
    Return VTable;
    
EndFunction // NewInputOutputTable()

// Only for internal use.
//
Function ParentJobsOutputTable(Job)
    
    Query = New Query;
    Query.Text = QueryTextParentJobsOutputTable();
    Query.SetParameter("Job", Job);
    
    QueryResult = Query.Execute();
    If QueryResult.IsEmpty() Then
        Return New ValueTable;
    EndIf;
    
    OutputTable = QueryResult.Unload();
    For Each Item In OutputTable Do
        
        If Item.State <> Catalogs.FL_States.Succeeded Then
            
            ErrorMessage = StrTemplate(Nstr("
                    |en='Error: Not all parent jobs are successfully finished {%1}.';
                    |ru='Ошибка: Не все родительские задания успешно завершены {%1}.';
                    |uk='Помилка: Не всі батьківські завдання успішно завершені {%1}.';
                    |en_CA='Error: Not all parent jobs are successfully finished {%1}.'"),
                String(Item.Ref)); 
            Raise ErrorMessage;    
            
        EndIf;
        
    EndDo;
    
    Return OutputTable; 
    
EndFunction // ParentJobsOutputTable() 

// Only for internal use.
//
Function QueryTextParentJobsOutputTable()

    QueryText = "
        |SELECT
        |   Jobs.CreatedAt AS CreatedAt,
        |   Jobs.Ref AS Ref,
        |   Jobs.Priority AS Priority,
        |   Jobs.State AS State
        |INTO ParentJobs
        |FROM
        |   Catalog.FL_Jobs AS Jobs   
        |
        |INNER JOIN InformationRegister.FL_JobContinuations AS Continuations  
        |ON Continuations.ParentJob = Jobs.Ref
        |AND Continuations.Job = &Job
        |
        |INDEX BY
        |   Jobs.Ref   
        |;
        |
        |////////////////////////////////////////////////////////////////////////////////
        |SELECT
        |   Jobs.Ref AS Ref,
        |   Jobs.State AS State,
        |   Outputs.Value AS Value
        |FROM
        |   ParentJobs AS Jobs
        |
        |INNER JOIN Catalog.FL_Jobs.Output AS Outputs
        |ON Outputs.Ref = Jobs.Ref
        |
        |ORDER BY
        |   Jobs.CreatedAt, 
        |   Jobs.Priority, 
        |   Outputs.LineNumber ASC   
        |;
        |
        |////////////////////////////////////////////////////////////////////////////////
        |DROP ParentJobs
        |;
        |";  
    Return QueryText;

EndFunction // QueryTextParentJobsOutputTable()

#EndRegion // InputOutput

// Only for internal use.
//
Procedure ProcessJob(Job, Invoke, Output = Undefined, JobResultCopy = Undefined)
       
    Var BasicResult;
    
    StartTime = CurrentUniversalDateInMilliseconds();
    
    JobObject = Job.GetObject();
    JobObject.Output.Clear();
    If JobObject.Invoke Then
        Invoke = JobObject.Invoke;   
    EndIf;

    Algorithm = BuildAlgorithm(JobObject, Output);
    Execute Algorithm;
    
    If TypeOf(BasicResult) = Type("Structure") Then
        FinalResult = BasicResult;
    Else
        
        FinalResult = NewJobResult();
        FinalResult.Success = True;
        
        // Add to JobResult output table Payload value. 
        AddToJobResult(FinalResult, "Payload", BasicResult);
        
    EndIf;
        
    NewLogRow = JobObject.Log.Add();
    NewLogRow.InitializedAt = StartTime;
    FinalResult.Property("LogAttribute", NewLogRow.LogAttribute);
    FinalResult.Property("StatusCode", NewLogRow.StatusCode);
    FinalResult.Property("Success", NewLogRow.Success);
    
    JobObject.State = Catalogs.FL_States.Succeeded;
    If NOT FinalResult.Success Then
        JobObject.State = Catalogs.FL_States.Failed;       
    EndIf;

    If TypeOf(JobResultCopy) = Type("Structure") Then
        JobResultCopy = FL_CommonUseClientServer.CopyStructure(FinalResult);   
    EndIf;
    
    // If message size exceeded the maximum we have to process 
    // parent job output in the place. 
    SizeExceeded = MessageSizeExceeded(FinalResult);
    If NOT SizeExceeded Then
        CopyToInputOutputTable(JobObject.Output, FinalResult.Output);    
    EndIf;
    
    // Setting an expiration date for this job.
    SetExpirationDate(JobObject.ExpireAt);
    
    // Writing this job object into database.
    JobObject.Write();

    // End measuring and recording performance metrics.
    RecordJobObjectPerformanceMetrics(JobObject, StartTime); 
    
    ProcessSubordinateJobs(Job, FinalResult.Output, JobResultCopy, 
        JobObject.State, Invoke, SizeExceeded);
        
EndProcedure // ProcessJob()

// Only for internal use.
//
Procedure ProcessSubordinateJobs(ParentJob, Output, JobResultCopy, State, 
    Invoke, SizeExceeded)
    
    If State <> Catalogs.FL_States.Succeeded Then
        Return;
    EndIf;
    
    SubordinateJobs = SubordinateJobs(ParentJob);
    For Each SubordinateJob In SubordinateJobs Do
        
        If Invoke OR SizeExceeded Then
            
            // It is not needed to change state here because transaction is active
            // ChangeState(SubordinateJob, Catalogs.FL_States.Processing);.
            ProcessJob(SubordinateJob, Invoke, Output, JobResultCopy);
            
            // If the message size of parent job is exceeded the maximum 
            // or invoke is set, it is needed to check child job state. 
            // If child job is failed, it is needed to mark parent job as failed too.
            CurrentState = FL_CommonUse.ObjectAttributeValue(
                SubordinateJob, "State");   
            If CurrentState <> Catalogs.FL_States.Succeeded Then   
                ChangeState(ParentJob, Catalogs.FL_States.Failed);    
            EndIf;    
            
        Else
            
            // It is needed to change state here because the child job 
            // will be processed in a different background thread.
            ChangeState(SubordinateJob, Catalogs.FL_States.Enqueued);   
            
        EndIf;
                              
    EndDo;
    
EndProcedure // ProcessSubordinateJobs()

// Only for internal use.
//
Procedure RecordJobPerformanceMetrics(Job, State, PerformanceDuration, 
    InitializedAt = Undefined) 
    
    RecordManager = InformationRegisters.FL_JobState.CreateRecordManager();
    RecordManager.Job = Job;
    RecordManager.State = State;
    RecordManager.CreatedAt = CurrentUniversalDateInMilliseconds();
    RecordManager.InitializedAt = InitializedAt;
    RecordManager.PerformanceDuration = PerformanceDuration; 
    RecordManager.Write();
    
EndProcedure // RecordJobPerformanceMetrics()

// Only for internal use.
//
Procedure RecordJobObjectPerformanceMetrics(JobObject, StartTime = Undefined)

    If StartTime = Undefined Then
        StartTime = JobObject.CreatedAt;     
    EndIf;
    
    Duration = CurrentUniversalDateInMilliseconds() - StartTime;
    RecordJobPerformanceMetrics(JobObject.Ref, JobObject.State, Duration, 
        StartTime);
    
EndProcedure // RecordJobObjectPerformanceMetrics()

// Only for internal use.
//
Procedure SetExpirationDate(ExpirationDate)
    
    ExpirationDate = CurrentUniversalDateInMilliseconds() 
        + FL_InteriorUseReUse.JobExpirationTimeout();  
    
EndProcedure // SetExpirationDate()

// Only for internal use.
//
Procedure ValidateJobType(ValidJobs, Job)
    
    If TypeOf(Job) = Type("CatalogRef.FL_Jobs") Then
        
        ValidJobs.Add(Job);
        
    ElsIf TypeOf(Job) = Type("Array") Then
        
        For Each Item In Job Do
            ValidateJobType(ValidJobs, Item);        
        EndDo;
        
    Else
        
        ErrorMessage = FL_ErrorsClientServer.ErrorTypeIsDifferentFromExpected(
            "Jobs", Job, "Array, CatalogRef.FL_Jobs");
        Raise ErrorMessage;
        
    EndIf;    
    
EndProcedure // ValidateJobType()

// Only for internal use.
//
Function BuildAlgorithm(JobObject, Output)
    
    FirstParameter = True;
    
    MemoryStream = New MemoryStream;
    DataWriter = New DataWriter(MemoryStream);
    DataWriter.WriteChars("BasicResult = ");
    DataWriter.WriteChars(JobObject.MethodName);
    DataWriter.WriteChars("(");
    
    ParametersSignature = "JobObject.%1[%2].Value.Get()";
    For Index = 0 To JobObject.Input.Count() - 1 Do

        If NOT FirstParameter Then
            DataWriter.WriteChars(", ");
        Else
            FirstParameter = False;        
        EndIf;
        
        TemplateResult = StrTemplate(ParametersSignature, "Input", 
            Format(Index, "NZ=; NG=0"));
        DataWriter.WriteChars(TemplateResult);      
            
    EndDo;
    
    ParametersSignature = "Output[%1].Value";
    If Output = Undefined Then
        ParametersSignature = "Output[%1].Value.Get()";
        Output = ParentJobsOutputTable(JobObject.Ref);
    EndIf;    
    
    For Index = 0 To Output.Count() - 1 Do
    
        If NOT FirstParameter Then
            DataWriter.WriteChars(", ");
        Else
            FirstParameter = False;    
        EndIf;
        
        TemplateResult = StrTemplate(ParametersSignature, 
            Format(Index, "NZ=; NG=0")); 
        DataWriter.WriteChars(TemplateResult);      
    
    EndDo;
    
    DataWriter.WriteChars(")");

    DataWriter.Close();
    BinaryData = MemoryStream.CloseAndGetBinaryData();
    Return GetStringFromBinaryData(BinaryData);
    
EndFunction // BuildAlgorithm()

// Only for internal use.
//
Function MessageSizeExceeded(JobResult)
    
    Var Value;
    
    MaximunMessageSize = FL_InteriorUseReUse.MaximumMessageSize();
    For Each Result In JobResult.Output Do
        
        If TypeOf(Result.Value) = Type("Structure") Then
            Result.Value.Property("Payload", Value);
        EndIf;
        
        If TypeOf(Value) = Type("BinaryData") 
            AND Value.Size() > MaximunMessageSize Then
            Return True;
        EndIf;
        
    EndDo;
    
    Return False;
    
EndFunction // MessageSizeExceeded()

// Only for internal use.
//
Function SubordinateJobs(ParentJob)
    
    Query = New Query;
    Query.Text = QueryTextSubordinateJobs();
    Query.SetParameter("ParentJob", ParentJob);
    Return Query.Execute().Unload().UnloadColumn("Job");
    
EndFunction // SubordinateJobs()

// Only for internal use.
//
Function QueryTextSubordinateJobs()

    QueryText = "
        |SELECT
        |   Continuations.Job AS Job
        |FROM
        |   InformationRegister.FL_JobContinuations AS Continuations
        |
        |INNER JOIN Catalog.FL_Jobs AS Jobs
        |ON Jobs.Ref = Continuations.Job
        |
        |INNER JOIN Catalog.FL_States AS States
        |ON States.Ref = Jobs.State
        |
        |WHERE
        |   Continuations.ParentJob = &ParentJob 
        |AND NOT States.IsFinal
        |";  
    Return QueryText;

EndFunction // QueryTextSubordinateJobs()

#EndRegion // ServiceProceduresAndFunctions

#EndIf