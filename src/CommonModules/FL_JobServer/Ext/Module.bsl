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

// Returns a new task structure that represents a single operation 
// that does not return a value and that usually executes asynchronously.
//
// Returns:
//  Structure - with values:
//      * MethodName  - String  - the name of exported procedure or a function
//              of a non-global server module which could be performed at the 
//              server. 
//      * Parameters  - Array   - array of parameters passed to the method. 
//              Number and types of parameters should correspond to the method 
//              parameters.All passed parameters should support serialization. 
//              Otherwise, an exception is generated and the background job will
//              not be launched. If last parameters of the method have default 
//              values, it is allowed not to set them in the array.
//      * Key         - String  - task key. If this key is set, it should be 
//              unique among keys of the active background job, which have 
//              the same method's name as current background job does.  
//      * Description - String  - task description.
//      * SafeMode    - Boolean - executes the method with pre-establishing 
//              a safe mode of code execution.
//
Function NewTask() Export
    
    Task = New Structure;
    Task.Insert("MethodName");
    Task.Insert("Parameters", New Array);
    Task.Insert("Key");
    Task.Insert("Description");
    Task.Insert("SafeMode", True);
    // TODO: Under construction. 
    Task.Insert("CancellationToken");
    Return Task;
    
EndFunction // NewTask()

// Queues the specified work to run on backgroud and returns a BackgroundJob
// object that represents that work.
//
// Parameters:
//  MethodName  - String  - the name of exported procedure or a function
//              of a non-global general module which could be performed at the 
//              server, in the ModuleName.MethodName form.
//  Parameters  - Array   - array of parameters passed to the method. 
//              Number and types of parameters should correspond to the method 
//              parameters.All passed parameters should support serialization. 
//              Otherwise, an exception is generated and the background job will
//              not be launched. If last parameters of the method have default 
//              values, it is allowed not to set them in the array.
//                      Default value: Undefined.
//  Key         - String  - task key. If this key is set, it should be 
//              unique among keys of the active background job, which have 
//              the same method's name as current background job does.
//                      Default value: Undefined.
//  Description - String  - task description.
//                      Default value: Undefined.
//  SafeMode    - Boolean - executes the method with pre-establishing 
//              a safe mode of code execution.
//                      Default value: True.
//
// Returns:
//  BackgroundJob - object that represents queued work. 
//
Function RunTask(MethodName, Parameters = Undefined, Key = Undefined, 
    Description = Undefined, SafeMode = True) Export
    
    Task = NewTask();
    Task.MethodName  = MethodName;
    Task.Parameters  = Parameters;
    Task.Key         = Key;
    Task.Description = Description;
    Task.SafeMode    = SafeMode;
    Return StartTask(Task);
    
EndFunction // RunTask()

// Starts the Task, scheduling it for execution to the current TaskScheduler.
//
// Parameters:
//  Task - Structure - see function FL_JobServer.NewTask.
//
// Returns:
//  BackgroundJob - object that represents the queued Task. 
//
Function StartTask(Task) Export
    
    CallExceptionIfNoAdministrativeRights();
    
    Parameters = New Array;
    Parameters.Add(Task.MethodName);
    Parameters.Add(Task.Parameters);
    Parameters.Add(Task.SafeMode);
    Parameters.Add(CurrentUniversalDateInMilliseconds());
    
    BackgroundJob = BackgroundJobs.Execute(
        "FL_JobServer.TaskAction", 
        Parameters, 
        Task.Key,
        Task.Description);
        
    Return BackgroundJob;
    
EndFunction // StartTask()

#EndRegion // ProgramInterface

#Region ServiceInterface

// BackgroundJobState.Active
// BackgroundJobState.Canceled
// BackgroundJobState.Completed
// BackgroundJobState.Failed

#Region Actions

// Task action decorator.
//
// Parameters:
//  MethodName - String  - the name of exported procedure or a function
//              of a non-global server module which could be performed at the 
//              server.
//  Parameters - Array   - array of parameters passed to the method. 
//              Number and types of parameters should correspond to the method 
//              parameters.All passed parameters should support serialization. 
//              Otherwise, an exception is generated and the background job will
//              not be launched. If last parameters of the method have default 
//              values, it is allowed not to set them in the array.
//  SafeMode   - Boolean - executes the method with pre-establishing 
//              a safe mode of code execution.
//  StartTime  - Number  - the time in milliseconds that helps calculate latency.
//
Procedure TaskAction(MethodName, Parameters, SafeMode, StartTime) Export
    
    Latency = CurrentUniversalDateInMilliseconds() - StartTime;
    
    If TypeOf(Parameters) = Type("Array") Then
        ParametersCount = Parameters.UBound();
    Else
        ParametersCount = -1;       
    EndIf;
    
    MethodParameters = "";
    For Index = 0 To ParametersCount Do
        MethodParameters = MethodParameters + "Parameters[" + Index + "]";
        MethodParameters = MethodParameters + ?(Index = ParametersCount, "", ",");
    EndDo;
    
    Algorithm = StrTemplate("%1(%2)", MethodName, MethodParameters);

    
    StartPerformance = CurrentUniversalDateInMilliseconds();
    
    Try
        If SafeMode = True Then
            FL_RunInSafeMode.ExecuteInSafeMode(Algorithm, Parameters);    
        Else
            Execute Algorithm;
        EndIf;
    Except
        Raise;
        // TODO: Handle exception.
    EndTry;
    
    PerformanceDuration = CurrentUniversalDateInMilliseconds() - StartPerformance; 
    
EndProcedure // TaskAction() 

// Default JobServer action.
//
Procedure JobServerAction() Export
    
    RetryJobs = New Array;
    DeleteJobs = New Array;
    
    //Var ExpirationManagerTask;

    WorkerCount = GetWorkerCount();
    If Not ValueIsFilled(WorkerCount) Or WorkerCount = 0 Then
        WorkerCount = DefaultWorkerCount();    
    EndIf;
    
    PopJobServerState(WorkerCount, DeleteJobs, RetryJobs);    
    UpdateWorkerSlots(DeleteJobs);
    PushJobServerState(WorkerCount, RetryJobs);
    
    
    
    
    
    //While True Do
    
    // Read Jobs 
    
    // Renew queue state.
    //
    // Read from register 
    // check jobs
        
        
        
        
        // Sleep function.
        //StartDate = CurrentUniversalDate();
        //EndDate = StartDate + 60;
        //While EndDate > StartDate Do
        //    StartDate = CurrentUniversalDate();    
        //EndDo;
        
    //RunExpirationManager(ExpirationManagerTask);
         
    //EndDo;
    
EndProcedure // JobServerAction()

// Default ExpirationManager action.
//
// Parameters:
//  NumberOfRecordsInSinglePass - Number - number of records to be processed 
//                                          during this action execution. 
//
Procedure ExpirationManagerAction(NumberOfRecordsInSinglePass = 1000) Export
    
    Query = New Query;
    Query.Text = QueryTextExpiredJobs(NumberOfRecordsInSinglePass);    
    QueryResult = Query.Execute();
    If Not QueryResult.IsEmpty() Then
        
        QueryResultSelection = QueryResult.Select();
        While QueryResultSelection.Next() Do
            
            JobObject = QueryResultSelection.BackgroundJob.GetObject(); 
            Try 
                JobObject.Delete();
            Except
                // TODO: Process exception    
            EndTry;
            
        EndDo;
        
    EndIf;
    
EndProcedure // ExpirationManagerAction()

#EndRegion // Actions

// Runs the specified job server.
//
// Parameters:
//  JobServer - ScheduledJob - the server to be switched on.
//                  Default value: Undefined.
//
Procedure RunJobServer(JobServer = Undefined) Export
    
    If JobServer = Undefined Then
        JobServer = JobServer();
    EndIf;
    
    BackgroundJob = RunTask(JobServer.Metadata.MethodName,
        , 
        String(JobServer.UUID), 
        JobServer.Description); 
    
EndProcedure // RunJobServer()

// Stops the specified job server.
//
// Parameters:
//  JobServer - ScheduledJob - the server to be switched off.
//                  Default value: Undefined.
//
Procedure StopJobServer(JobServer = Undefined) Export
    
    If JobServer = Undefined Then
        JobServer = JobServer();
    EndIf;
    
    BackgroundJob = BackgroundJobByFilter();
    If BackgroundJob <> Undefined Then
        BackgroundJob.Cancel();        
    EndIf;
    
EndProcedure // StopJobServer()

// Runs an expiration manager task.
//
// Parameters:
//  ExpirationManagerTask - BackgroundJob - the expiration manager task.
//
Procedure RunExpirationManager(ExpirationManagerTask) Export
    
    If TypeOf(ExpirationManagerTask) = Type("BackgroundJob") Then
        
        ExpirationManagerTask = BackgroundJobByUUID(ExpirationManagerTask.UUID);
        If ExpirationManagerTask <> Undefined
            AND TypeOf(ExpirationManagerTask) = Type("BackgroundJob")
            AND ExpirationManagerTask.State = BackgroundJobState.Active Then 
            Return;      
        EndIf;
        
    EndIf; 
    
    ExpirationManagerTask = RunTask("FL_JobServer.ExpirationManagerAction", 
        , 
        , 
        "Expiration manager task (FL)");
    
EndProcedure // RunExpirationManager()





// Returns registered or register the job server in the current infobase.
// 
// Returns:
//  ScheduledJob - job server.
//
Function JobServer() Export

    CallExceptionIfNoAdministrativeRights();
    
    JobServer = ScheduledJobs.FindByUUID(GetJobServerId());
    If JobServer <> Undefined Then
        Return JobServer;
    EndIf;
        
    FilterResult = ScheduledJobs.GetScheduledJobs(
        NewScheduledJobsFilter("Key, Metadata", True));
    If FilterResult.Count() = 0 Then
        JobServer = ScheduledJobs.CreateScheduledJob(
            Metadata.ScheduledJobs.FL_JobServer);
        JobServer.Write();
    Else
        JobServer = FilterResult[0];
    EndIf;
    
    IsOk = SetJobServerId(JobServer.UUID);
    If IsOk = False Then
        // TODO: Process exception.    
    EndIf;
    
    Return JobServer;

EndFunction // JobServer()

Function JobServerIsRunning() Export
    
    JobServer = ScheduledJobs.FindByUUID(GetJobServerId());
    If JobServer <> Undefined Then
                
        BackgroundJob = BackgroundJobByFilter();
        If BackgroundJob = Undefined Then
            Return False;        
        EndIf;
        
        If BackgroundJob.State = BackgroundJobState.Active Then
            Return True;    
        EndIf;
        
    EndIf; 
    
    Return False;
    
EndFunction // JobServerWatchDog()

#EndRegion // ServiceInterface

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
Procedure PopJobServerState(WorkerCount, DeleteJobs, RetryJobs) 
    
    bjsActive    = BackgroundJobState.Active;
    bjsCanceled  = BackgroundJobState.Canceled;
    bjsCompleted = BackgroundJobState.Completed;
    bjsFailed    = BackgroundJobState.Failed;
    
    FinalStates = Catalogs.FL_States.FinalStates();
    
    RetryAttempts = GetRetryAttempts();
    If Not ValueIsFilled(RetryAttempts) Then
        RetryAttempts = DefaultRetryAttempts();    
    EndIf;
  
    Query = New Query;
    Query.Text = QueryTextTasksHeartbeat();
    QueryResult = Query.Execute();
    If Not QueryResult.IsEmpty() Then
        
        WorkersTable = QueryResult.Unload();
        For Each Worker In WorkersTable Do
                
            BackgroundJob = BackgroundJobByUUID(Worker.TaskId);
            If BackgroundJob = Undefined 
                OR BackgroundJob.State = bjsCanceled
                Or BackgroundJob.State = bjsCompleted
                Or BackgroundJob.State = bjsFailed Then
                
                If FinalStates.FindByValue(Worker.Job.State) <> Undefined Then
                    DeleteJobs.Add(Worker.Job);
                Else
                    
                    If Worker.RetryAttempts >= RetryAttempts Then
                        DeleteJobs.Add(Worker.Job);   
                    Else
                        RetryJobs.Add(Worker.Job);        
                    EndIf;        
                    
                EndIf;
                
            Else // BackgroundJob.State = bjsActive
                
                WorkerCount = WorkerCount - 1;    
                
            EndIf;
            
        EndDo;
        
    EndIf;
    
EndProcedure // PopJobServerState()

// Only for internal use.
//
Procedure PushJobServerState(WorkerCount, RetryJobs) 
    
    EnqueuedJobs = New Array;
    //FL_CommonUseClientServer.ExtendArray(QueueArray, RetryArray, True);
 
    WorkerCount = WorkerCount - RetryJobs.Count();
    If WorkerCount > 0 Then
        
        Query = New Query;
        Query.Text = QueryTextEnqueuedJobs(WorkerCount);
        QueryResult = Query.Execute();
        If Not QueryResult.IsEmpty() Then
            EnqueuedJobs = QueryResult.Unload().UnloadColumn("Job");    
        EndIf;
        
    EndIf;
    
    // Move to EnqueuedState
    For Each Job In RetryJobs Do
        // TODO: correct state change.
        //Catalogs.FL_Jobs.ChangeState(Job, Catalogs.FL_States.
        Parameters = New Array;
        Parameters.Add(Job);
        Task = RunTask("Catalogs.FL_Jobs.ProcessMessage", 
            Parameters, 
            , 
            "Background job task (FoxyLink)",
            False);
            
        RecordManager = InformationRegisters.FL_TasksHeartbeat.CreateRecordManager();
        RecordManager.Job = Job;
        RecordManager.Read();
        If Not RecordManager.Selected() Then
            RecordManager.Job = Job;        
        EndIf;
        RecordManager.TaskId = Task.UUID;
        RecordManager.RetryAttempts = RecordManager.RetryAttempts + 1;
        RecordManager.Write();
            
    EndDo;
    
    For Each Job In EnqueuedJobs Do
        
        Parameters = New Array;
        Parameters.Add(Job);
        
        Task = RunTask("Catalogs.FL_Jobs.ProcessMessage", 
            Parameters, 
            , 
            "Background job task (FoxyLink)",
            False);
            
        RecordManager = InformationRegisters.FL_TasksHeartbeat.CreateRecordManager();
        RecordManager.Job = Job;
        RecordManager.TaskId = Task.UUID;
        RecordManager.RetryAttempts = 0;    
        RecordManager.Write();
        
    EndDo;
        
EndProcedure // PushJobServerState()

// Only for internal use.
//
Procedure UpdateWorkerSlots(DeleteJobs) 
    
    If DeleteJobs.Count() > 0 Then
        InformationRegisters.FL_TasksHeartbeat.DeleteRecordsByFilter(
            New Structure("Job", DeleteJobs));
    EndIf;
    
EndProcedure // UpdateWorkerSlots()



// Only for internal use.
//
Procedure CallExceptionIfNoAdministrativeRights()

    If Not PrivilegedMode() Then
        VerifyAccessRights("Administration", Metadata);
    EndIf;

EndProcedure // CallExceptionIfNoAdministrativeRights()






// Only for internal use.
//
Function NewScheduledJobsFilter(Keys = Undefined, UseMetadata = False)
    
    BasicFilter = New Structure;
    BasicFilter.Insert("Use");
    BasicFilter.Insert("Key");
    BasicFilter.Insert("UUID");
    BasicFilter.Insert("Metadata");
    BasicFilter.Insert("Predefined");
    BasicFilter.Insert("Description");
    
    If UseMetadata = True Then
        MetaSJ                  = Metadata.ScheduledJobs.FL_JobServer;
        BasicFilter.Use         = MetaSJ.Use;
        BasicFilter.Key         = MetaSJ.Key;
        BasicFilter.Metadata    = MetaSJ;
        BasicFilter.Predefined  = MetaSJ.Predefined;
        BasicFilter.Description = MetaSJ.Name;
    EndIf;
    
    If TypeOf(Keys) = Type("String") And Not IsBlankString(Keys) Then
        SpecificFilter = New Structure(Keys);
        FillPropertyValues(SpecificFilter, BasicFilter);
        Return SpecificFilter;
    EndIf;
    
    Return BasicFilter;
    
EndFunction // NewScheduledJobsFilter()

// Only for internal use.
//
Function NewBackgroundJobsFilter(Keys = Undefined, UseMetadata = False)
    
    BasicFilter = New Structure;
    BasicFilter.Insert("Key");
    BasicFilter.Insert("UUID");
    BasicFilter.Insert("State");
    BasicFilter.Insert("Begin");
    BasicFilter.Insert("End");
    BasicFilter.Insert("Description");
    BasicFilter.Insert("MethodName");
    BasicFilter.Insert("ScheduledJob");
    
    If UseMetadata = True Then
        MetaSJ                  = Metadata.ScheduledJobs.FL_JobServer;
        BasicFilter.Key         = String(GetJobServerId());
        BasicFilter.MethodName  = MetaSJ.MethodName;
        BasicFilter.Description = MetaSJ.Name;
    EndIf;
    
    If TypeOf(Keys) = Type("String") And Not IsBlankString(Keys) Then
        SpecificFilter = New Structure(Keys);
        FillPropertyValues(SpecificFilter, BasicFilter);
        Return SpecificFilter;
    EndIf;
    
    Return BasicFilter;
    
EndFunction // NewBackgroundJobsFilter()



// Only for internal use.
//
Function GetRetryAttempts()

    Return Constants.FL_RetryAttempts.Get();
    
EndFunction // GetRetryAttempts()

// Only for internal use.
//
Function SetRetryAttempts(Count)
    
    Try
        Constants.FL_RetryAttempts.Set(Count);
    Except
        // TODO: Log exception.  
        Return False;
    EndTry;
    
    Return True;
    
EndFunction // SetRetryAttempts()

// Only for internal use.
//
Function DefaultRetryAttempts()
    
    Return 5;
    
EndFunction // DefaultRetryAttempts() 


// Only for internal use.
//
Function GetWorkerCount()

    Return Constants.FL_WorkerCount.Get();
    
EndFunction // GetUniqueJobServerId()

// Only for internal use.
//
Function SetWorkerCount(Count)
    
    Try
        Constants.FL_WorkerCount.Set(Count);
    Except
        // TODO: Log exception.  
        Return False;
    EndTry;
    
    Return True;
    
EndFunction // SetWorkerCount()

// Only for internal use.
//
Function DefaultWorkerCount()
    
    Return 20;
    
EndFunction // DefaultWorkerCount() 


// Only for internal use.
//
Function GetJobServerId()

    Return Constants.FL_JobServerID.Get();
    
EndFunction // GetJobServerId()

// Only for internal use.
//
Function SetJobServerId(Id)
    
    Try
        Constants.FL_JobServerID.Set(Id);
    Except
        // TODO: Log exception.  
        Return False;
    EndTry;
    
    Return True;
    
EndFunction // SetJobServerId()

// Only for internal use.
//
Function DefaultJobServerId()
    
    Return New UUID("00000000-0000-0000-0000-000000000000");
    
EndFunction // DefaultJobServerId() 


// Only for internal use.
//
Function BackgroundJobByUUID(UUID)
    
    Return BackgroundJobs.FindByUUID(UUID);    
    
EndFunction // BackgroundJobByUUID()

// Only for internal use.
//
Function BackgroundJobByFilter(Filter = Undefined)
    
    If Filter = Undefined Then
        BackgroundJobsFilter = NewBackgroundJobsFilter("Key", True);    
    Else
        BackgroundJobsFilter = Filter;    
    EndIf;
    
    FilterResult = BackgroundJobs.GetBackgroundJobs(BackgroundJobsFilter);
    If FilterResult.Count() > 0 Then
        Return FilterResult[0]; 
    EndIf; 
    
    Return Undefined;
    
EndFunction // BackgroundJobByFilter()



// Only for internal use.
//
Function QueryTextTasksHeartbeat()
    
    QueryText = "
        |SELECT
        |   TasksHeartbeat.Job           AS Job,
        |   TasksHeartbeat.TaskId        AS TaskId,
        |   TasksHeartbeat.RetryAttempts AS RetryAttempts
        |FROM
        |   InformationRegister.FL_TasksHeartbeat AS TasksHeartbeat
        |";  
    Return QueryText;
    
EndFunction // QueryTextTasksHeartbeat()

// Only for internal use.
//
Function QueryTextEnqueuedJobs(WorkerCount)
    
    QueryText = StrTemplate("
        |SELECT
        |   TasksHeartbeat.Job AS Job
        |INTO TasksHeartbeatCache
        |FROM
        |   InformationRegister.FL_TasksHeartbeat AS TasksHeartbeat
        |
        |INDEX BY
        |   Job 
        |;
        |
        |////////////////////////////////////////////////////////////////////////////////
        |SELECT TOP %1
        |   Jobs.Ref AS Job
        |FROM
        |   Catalog.FL_Jobs AS Jobs
        |WHERE
        |    Jobs.State = Value(Catalog.FL_States.Enqueued)  
        |And Jobs.Ref NOT IN (Select Job From TasksHeartbeatCache)
        |
        |;
        |
        |////////////////////////////////////////////////////////////////////////////////
        |DROP TasksHeartbeatCache
        |;
        |", Format(WorkerCount, "NG=0"));  
    Return QueryText;
    
EndFunction // QueryTextEnqueuedJobs()
 
// Only for internal use.
//
Function QueryTextExpiredJobs(NumberOfRecordsInSinglePass)
    
    QueryText = StrTemplate("
        |SELECT
        |   States.Ref AS State   
        |INTO StatesCache
        |FROM
        |   Catalog.FL_States AS States
        |WHERE
        |    States.DeletionMark = False
        |AND States.IsFinal = True
        |
        |UNION ALL
        |
        |Select
        |   Value(Catalog.FL_States.EmptyRef)
        |
        |INDEX BY
        |   State
        |;
        |
        |////////////////////////////////////////////////////////////////////////////////
        |SELECT TOP %1
        |   BackgroundJobs.Ref AS BackgroundJob        
        |FROM
        |   Catalog.FL_Jobs AS BackgroundJobs
        |
        |INNER JOIN StatesCache AS States
        |ON States.State = BackgroundJobs.State 
        |   
        |;
        |
        |////////////////////////////////////////////////////////////////////////////////
        |DROP StatesCache
        |;
        |", Format(NumberOfRecordsInSinglePass, "NG=0"));  
    Return QueryText;
    
EndFunction // QueryTextExpiredJobs()

#EndRegion // ServiceProceduresAndFunctions
