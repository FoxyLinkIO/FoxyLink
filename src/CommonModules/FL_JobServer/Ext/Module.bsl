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

// Runs the specified scheduled job in this infobase immediately.
//
// Parameters:
//  ScheduledJob - ScheduledJob - sheduled job linked to background job.
//  SafeMode     - Boolean      - executes the method with pre-establishing 
//              a safe mode of code execution.
//                  Default value: True.
//
Procedure RunScheduledJob(ScheduledJob, SafeMode = True) Export
    
    Task = FL_Tasks.NewTask();
    Task.Description = ScheduledJob.Description;
    Task.Key = ScheduledJob.Key;
    Task.MethodName = ScheduledJob.Metadata.MethodName; 
    Task.SafeMode = SafeMode;
    
    FL_Tasks.Run(Task); 
    
EndProcedure // RunScheduledJob()

// Stops the specified scheduled job in this infobase immediately.
//
// Parameters:
//  ScheduledJob - ScheduledJob - sheduled job linked to background job.
//
Procedure StopScheduledJob(ScheduledJob) Export
        
    BackgroundJobsFilter = NewBackgroundJobsFilter();
    BackgroundJobsFilter.State = BackgroundJobState.Active;
    FillPropertyValues(BackgroundJobsFilter, ScheduledJob, , "Description, UUID");
    FL_CommonUseClientServer.RemoveValueFromStructure(BackgroundJobsFilter);
        
    BackgroundJobsByFilter = BackgroundJobsByFilter(BackgroundJobsFilter);
    For Each BackgroundJob In BackgroundJobsByFilter Do
        BackgroundJob.Cancel();        
    EndDo;
            
EndProcedure // StopScheduledJob()

// Returns registered or register the job server in the current infobase.
// 
// Returns:
//  ScheduledJob - job server.
//
Function JobServer() Export

    JobServer = ScheduledJob(Metadata.ScheduledJobs.FL_JobServer);
    Return JobServer;

EndFunction // JobServer()

// Returns registered or register the job routing in the current infobase.
// 
// Returns:
//  ScheduledJob - job routing.
//
Function JobRouting() Export

    JobRouting = ScheduledJob(Metadata.ScheduledJobs.FL_JobRouting);
    Return JobRouting;

EndFunction // JobRouting()

// Returns the server state - active or non-active.
// 
// Parameters:
//  ScheduledJob - ScheduledJob - scheduled job to get state. 
//
// Returns:
//  Boolean - True if the server state is active.
//
Function ServerWatchDog(ScheduledJob) Export
    
    BackgroundJobsFilter = NewBackgroundJobsFilter();
    BackgroundJobsFilter.State = BackgroundJobState.Active;
    FillPropertyValues(BackgroundJobsFilter, ScheduledJob, , "Description, UUID");
    FL_CommonUseClientServer.RemoveValueFromStructure(BackgroundJobsFilter);
        
    BackgroundJobsByFilter = BackgroundJobsByFilter(BackgroundJobsFilter);
    Return BackgroundJobsByFilter.Count() > 0; 
    
EndFunction // ServerWatchDog()

#EndRegion // ProgramInterface

#Region ServiceInterface

// Returns ScheduledJob from infobase.
// 
// Parameters:
//  ID - MetadataObject - metadata object of scheduled job for predefined 
//                          scheduled job search.
//     - String         - scheduled job name for which it is required to define 
//                          metadata object of scheduled job for predefined 
//                          scheduled job search.
//     - String         - scheduled job unique UUID string.
//     - UUID           - scheduled job UUID.
//     - ScheduledJob   - scheduled job from which need to get unique identifier
//                          for get fresh copy of scheduled job.
// 
// Returns:
//  ScheduledJob - it is read from database.
//
Function ScheduledJob(Val ID) Export
    
    FL_InteriorUse.AdministrativeRights();
    SetPrivilegedMode(True);

    If TypeOf(ID) = Type("ScheduledJob") Then
        ID = ID.UUID;
    EndIf;

    If TypeOf(ID) = Type("String") Then
        
        SearchResult = Metadata.FindByFullName(ID);
        If SearchResult <> Undefined Then
            ID = SearchResult;
        Else
            ID = New UUID(ID);
        EndIf;
        
    EndIf;

    If TypeOf(ID) = Type("MetadataObject") Then
        ScheduledJob = ScheduledJobs.FindPredefined(ID);
    Else
        ScheduledJob = ScheduledJobs.FindByUUID(ID);
    EndIf;

    If ScheduledJob = Undefined Then
        Raise NStr("en='Scheduled job is not found. Perhaps, it has been deleted by another user.';
            |ru='Регламентное задание не найдено. Возможно, оно удалено другим пользователем.';
            |en_CA='Scheduled job is not found. Perhaps, it has been deleted by another user.'");
    EndIf;

    Return ScheduledJob;

EndFunction // ScheduledJob()

// Returns BackgroundJob by UUID.
//
// Parameters:
//  UUID - UUID - background job ID.
//
// Returns:
//  BackgroundJob, Undefined - if job is not found for the specified identifier, 
//                             then returns Undefined.  
//
Function BackgroundJobByUUID(UUID) Export
    
    Return BackgroundJobs.FindByUUID(UUID);    
    
EndFunction // BackgroundJobByUUID()

// Returns array of BackgroundJob objects by specified filter.
//
// Parameters:
//  Filter - Structure - see fucntion FL_JobServer.NewBackgroundJobsFilter.
//
// Returns:
//  Array - array of BackgroundJob objects.
//
Function BackgroundJobsByFilter(Filter) Export
    
    Return BackgroundJobs.GetBackgroundJobs(Filter);    
    
EndFunction // BackgroundJobsByFilter()

// Returns a new background jobs filter.
//
// Returns:
//  Structure - with keys:
//      * UUID         - UUID               - unique ID of job.
//      * Key          - String             - applicable unique ID. 
//      * State        - BackgroundJobState - job state.
//      * Begin        - Date               - job launch date.
//      * End          - Date               - date of job completion.
//      * Description  - String             - job description.
//      * MethodName   - String             - name of non-global common module method. 
//      * ScheduledJob - ScheduledJob       - sheduled job linked to background job.
//
Function NewBackgroundJobsFilter() Export
    
    BackgroundJobsFilter = New Structure; 
    BackgroundJobsFilter.Insert("UUID");
    BackgroundJobsFilter.Insert("Key");
    BackgroundJobsFilter.Insert("State");
    BackgroundJobsFilter.Insert("Begin");
    BackgroundJobsFilter.Insert("End");
    BackgroundJobsFilter.Insert("Description");
    BackgroundJobsFilter.Insert("MethodName");
    BackgroundJobsFilter.Insert("ScheduledJob");
        
    Return BackgroundJobsFilter;
    
EndFunction // NewBackgroundJobsFilter()

#Region Actions

// Default ExpirationManager action. 
//
Procedure JobExpirationAction() Export
    
    Query = New Query;
    Query.Text = QueryTextExpiredJobs();
    Query.SetParameter("CurrentUTCTime", CurrentUniversalDateInMilliseconds()); 
    QueryResult = Query.Execute();
    If NOT QueryResult.IsEmpty() Then
        
        QueryResultSelection = QueryResult.Select();
        While QueryResultSelection.Next() Do
            
            Try 
                JobObject = QueryResultSelection.Job.GetObject(); 
                JobObject.Delete();
            Except
               
                FL_InteriorUse.WriteLog("FoxyLink.Tasks.JobExpirationAction", 
                    EventLogLevel.Error,
                    Metadata.ScheduledJobs.FL_JobExpiration,
                    ErrorDescription());
                
            EndTry;
            
        EndDo;
        
    EndIf;
    
EndProcedure // JobExpirationAction()

// Default JobRecurring action.
//
Procedure JobRecurringAction() Export
    
    Return;
    
EndProcedure // JobRecurringAction()

// Default JobRouting action.
//
Procedure JobRoutingAction() Export
    
    Catalogs.FL_Messages.Route();    
    
EndProcedure // JobRoutingAction()

// Default JobServer action.
//
Procedure JobServerAction() Export
    
    RetryJobs = NewHeartbeatTable();
    ProcessingJobs = NewHeartbeatTable();
    
    WorkerCount = GetWorkerCount();
    
    PopJobServerState(WorkerCount, ProcessingJobs, RetryJobs);
    ClearJobServerState();
    PushJobServerState(WorkerCount, ProcessingJobs, RetryJobs);
        
EndProcedure // JobServerAction()

#EndRegion // Actions

// Sets a new retry attempts value.
//
// Parameters:
//  Count - Number - the new retry attempts value. 
//
Procedure SetRetryAttempts(Count) Export
    
    Constants.FL_RetryAttempts.Set(Count);
    
EndProcedure // SetRetryAttempts()

// Returns a retry attemps value.
//
// Returns:
//  Number - the retry attemps value.
//
Function GetRetryAttempts() Export

    RetryAttempts = Constants.FL_RetryAttempts.Get();
    If NOT ValueIsFilled(RetryAttempts) Then
        RetryAttempts = DefaultRetryAttempts();    
    EndIf;
    
    Return RetryAttempts;
    
EndFunction // GetRetryAttempts()

// Returns default retry attemps value.
//
// Returns:
//  Number - default retry attemps value.
//
Function DefaultRetryAttempts() Export
    
    Return 5;
    
EndFunction // DefaultRetryAttempts() 

// Sets a new worker count value.
//
// Parameters:
//  Count - Number - the new worker count value. 
//
Procedure SetWorkerCount(Count) Export

    Constants.FL_WorkerCount.Set(Count);

EndProcedure // SetWorkerCount()

// Returns a worker count value.
//
// Returns:
//  Number - the worker count value. 
//
Function GetWorkerCount() Export

    WorkerCount = Constants.FL_WorkerCount.Get();
    If NOT ValueIsFilled(WorkerCount) OR WorkerCount = 0 Then
        WorkerCount = DefaultWorkerCount();    
    EndIf;
    
    Return WorkerCount;
    
EndFunction // GetWorkerCount()

// Returns default worker count value.
//
// Returns:
//  Number - default worker count value. 
//
Function DefaultWorkerCount() Export
    
    Return 5;
    
EndFunction // DefaultWorkerCount() 

// Sets a new worker jobs limit value.
//
// Parameters:
//  Limit - Number - the new worker jobs limit value. 
//
Procedure SetWorkerJobsLimit(Limit) Export

    Constants.FL_WorkerJobsLimit.Set(Limit);

EndProcedure // SetWorkerJobsLimit()

// Returns a worker jobs limit value.
//
// Returns:
//  Number - the worker jobs limit value. 
//
Function GetWorkerJobsLimit() Export

    Limit = Constants.FL_WorkerJobsLimit.Get();
    If NOT ValueIsFilled(Limit) OR Limit = 0 Then
        Limit = DefaultWorkerJobsLimit();    
    EndIf;
    
    Return Limit;
    
EndFunction // GetWorkerJobsLimit()

// Returns default worker jobs limit value.
//
// Returns:
//  Number - default worker jobs limit value. 
//
Function DefaultWorkerJobsLimit() Export
    
    Return 5;
    
EndFunction // DefaultWorkerJobsLimit() 

#EndRegion // ServiceInterface

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
Procedure PopJobServerState(WorkerCount, ProcessingJobs, RetryJobs) 
    
    RetryAttempts = GetRetryAttempts();

    FinalStates = Catalogs.FL_States.FinalStates();
    
    BackgroundJobCache = New Map; 
    FilterResults = BackgroundJobsByFilter(New Structure("MethodName", 
        "FL_Tasks.TaskAction"));
    For Each FilterResult In FilterResults Do
        BackgroundJobCache.Insert(FilterResult.UUID, FilterResult.State);    
    EndDo;
    
    Query = New Query;
    Query.Text = QueryTextTasksHeartbeat();
    JobTable = Query.Execute().Unload();
    
    For Each Item In JobTable Do

        CurrentState = FL_CommonUse.ObjectAttributeValue(Item.Job, "State");
        If FinalStates.FindByValue(CurrentState) <> Undefined Then
            
            // Final state: Succeeded or Deleted, skip and continue.
            Continue;
            
        ElsIf BackgroundJobCache.Get(Item.TaskId) = BackgroundJobState.Active Then
            FillPropertyValues(ProcessingJobs.Add(), Item);
        ElsIf Item.RetryAttempt < RetryAttempts Then
            FillPropertyValues(RetryJobs.Add(), Item);            
        EndIf;
        
    EndDo;
    
    WorkerTable = FL_CommonUse.RemoveDuplicatesFromValueTable(
        JobTable.Copy(, "TaskId"));
    ReduceAvailableWorkerCount(WorkerCount, WorkerTable, BackgroundJobCache);
     
EndProcedure // PopJobServerState()

// Only for internal use.
//
Procedure PushJobServerState(WorkerCount, ProcessingJobs, RetryJobs) 
    
    Limit = GetWorkerJobsLimit();
    MaxCapacity = WorkerCount * Limit;
    
    HeartbeatTable = NewHeartbeatTable();
    
    // Add processing jobs to heartbeat table.
    FL_CommonUseClientServer.ExtendValueTable(ProcessingJobs, HeartbeatTable);
    
    // Retries go without worker count control.
    ProcessRetryJobsDelay(RetryJobs, HeartbeatTable);
    RunBackgroundJobs(RetryJobs, HeartbeatTable, WorkerCount, Limit);
    
    If WorkerCount > 0 Then
        
        Query = New Query;
        Query.Text = QueryTextEnqueuedJobs(MaxCapacity);
        Query.SetParameter("ProcessingJobs", ProcessingJobs);
        Query.SetParameter("RetryJobs", RetryJobs);
        QueryResult = Query.Execute();
        EnqueuedJobs = QueryResult.Unload();    
        RunBackgroundJobs(EnqueuedJobs, HeartbeatTable, WorkerCount, Limit);
        
    EndIf;
    
    RecordSet = InformationRegisters.FL_TasksHeartbeat.CreateRecordSet();
    RecordSet.Load(HeartbeatTable);
    RecordSet.Write();
    
EndProcedure // PushJobServerState()

// Only for internal use.
//
Procedure ClearJobServerState() 
    
    RecordSet = InformationRegisters.FL_TasksHeartbeat.CreateRecordSet(); 
    RecordSet.Write();
    
EndProcedure // ClearJobServerState()

// Only for internal use.
//
Procedure ReduceAvailableWorkerCount(WorkerCount, WorkerTable, 
    BackgroundJobCache)
    
    BJSActive = BackgroundJobState.Active;
    For Each Worker In WorkerTable Do
        If BackgroundJobCache.Get(Worker.TaskId) = BJSActive Then
            WorkerCount = WorkerCount - 1;    
        EndIf;
    EndDo;
    
EndProcedure // ReduceAvailableWorkerCount()

// Only for internal use.
//
Procedure ProcessRetryJobsDelay(RetryJobs, HeartbeatTable)
    
    CurrentDate = CurrentUniversalDateInMilliseconds();
    RetryPeriod = 45000;   
    
    Index = RetryJobs.Count() - 1;
    While Index >= 0 Do
        
        Item = RetryJobs[Index];
        If Item.RetryAt = 0 Then
            
            Item.RetryAt = CurrentDate + RetryPeriod;
            FillPropertyValues(HeartbeatTable.Add(), Item);
            RetryJobs.Delete(Index);
            
        ElsIf CurrentDate > Item.RetryAt Then 
            
            Item.RetryAttempt = Item.RetryAttempt + 1;
            NextRetry = Item.RetryAttempt + 1;
            Item.RetryAt = CurrentDate + NextRetry * NextRetry * RetryPeriod;
            
        Else
            
            FillPropertyValues(HeartbeatTable.Add(), Item);
            RetryJobs.Delete(Index);    
            
        EndIf;    
        
        Index = Index - 1;
        
    EndDo;
    
EndProcedure // ProcessRetryJobsDelay()

// Only for internal use.
//
Procedure RunBackgroundJobs(JobTable, HeartbeatTable, WorkerCount, Val Limit)
    
    BoostTable = NewHeartbeatTable();
    JobCount = JobTable.Count() - 1;
    For Index = 0 To JobCount Do

        If WorkerCount <= 0 Then
            Break;
        EndIf;
        
        If JobTable[Index].Isolated Then
            
            BackgroundJob = TriggerJobs(JobTable[Index].Job, WorkerCount);
            
            NewItem = HeartbeatTable.Add();
            FillPropertyValues(NewItem, JobTable[Index]);
            NewItem.TaskId = BackgroundJob.UUID;
            
        Else
            
            FillPropertyValues(BoostTable.Add(), JobTable[Index]);
            
        EndIf;
        
        If Limit = BoostTable.Count()
            OR Index = JobCount Then
            
            BackgroundJob = TriggerJobs(BoostTable.UnloadColumn("Job"), 
                WorkerCount);
            
            For Each Item In BoostTable Do
                Item.TaskId = BackgroundJob.UUID;        
            EndDo;
            
            FL_CommonUseClientServer.ExtendValueTable(BoostTable, 
                HeartbeatTable);
                        
            BoostTable.Clear();
            
        EndIf;
            
    EndDo;
    
EndProcedure // RunBackgroundJobs()

// Only for internal use.
//
Function TriggerJobs(Jobs, WorkerCount)
    
    // Reducing workers count
    WorkerCount = WorkerCount - 1;
    
    If TypeOf(Jobs) = Type("CatalogRef.FL_Jobs") Then
        Catalogs.FL_Jobs.ChangeState(Jobs, Catalogs.FL_States.Processing);
    Else
        For Each Job In Jobs Do
            Catalogs.FL_Jobs.ChangeState(Job, Catalogs.FL_States.Processing);
        EndDo;     
    EndIf;
    
    Task = FL_Tasks.NewTask();
    Task.MethodName = "Catalogs.FL_Jobs.Trigger";
    Task.Parameters.Add(Jobs);
    Task.Description = "Background job task (FoxyLink)";
    Task.SafeMode = False;
    Return FL_Tasks.Run(Task);
        
EndFunction // TriggerJobs()

// Only for internal use.
//
Function NewHeartbeatTable()
    
    RetryAtCapacity = 15;
    RetryAttemptsCapacity = 5;
    
    HeartbeatTable = New ValueTable;
    HeartbeatTable.Columns.Add("Job", New TypeDescription(
        "CatalogRef.FL_Jobs"));
    HeartbeatTable.Columns.Add("TaskId", New TypeDescription("UUID"));
    HeartbeatTable.Columns.Add("Isolated", New TypeDescription("Boolean"));
    HeartbeatTable.Columns.Add("RetryAt", FL_CommonUse.NumberTypeDescription(
        RetryAtCapacity, , AllowedSign.Nonnegative));
    HeartbeatTable.Columns.Add("RetryAttempt", FL_CommonUse.NumberTypeDescription(
        RetryAttemptsCapacity, , AllowedSign.Nonnegative));
    Return HeartbeatTable;
    
EndFunction // NewHeartbeatTable()

// Only for internal use.
//
Function NewScheduledJobsFilter()
    
    ScheduledJobsFilter = New Structure;
    ScheduledJobsFilter.Insert("Use");
    ScheduledJobsFilter.Insert("Key");
    ScheduledJobsFilter.Insert("UUID");
    ScheduledJobsFilter.Insert("Metadata");
    ScheduledJobsFilter.Insert("Predefined");
    ScheduledJobsFilter.Insert("Description");
    
    Return ScheduledJobsFilter;
    
EndFunction // NewScheduledJobsFilter()

// Only for internal use.
//
Function QueryTextTasksHeartbeat()
    
    QueryText = "
        |SELECT
        |   TasksHeartbeat.Job          AS Job,
        |   TasksHeartbeat.TaskId       AS TaskId,
        |   TasksHeartbeat.Isolated     AS Isolated,
        |   TasksHeartbeat.RetryAt      AS RetryAt,
        |   TasksHeartbeat.RetryAttempt AS RetryAttempt
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
        |   ProcessingJobs.Job AS Job
        |INTO ProcessingJobsCache
        |FROM
        |   &ProcessingJobs AS ProcessingJobs
        |;
        |
        |////////////////////////////////////////////////////////////////////////////////
        |SELECT
        |   RetryJobs.Job AS Job
        |INTO RetryJobsCache
        |FROM
        |   &RetryJobs AS RetryJobs
        |;
        |
        |////////////////////////////////////////////////////////////////////////////////
        |SELECT
        |   ProcessingJobs.Job AS Job
        |INTO TasksHeartbeatCache
        |FROM
        |   ProcessingJobsCache AS ProcessingJobs
        |
        |UNION ALL
        |
        |SELECT
        |   RetryJobs.Job AS Job
        |FROM
        |   RetryJobsCache AS RetryJobs
        |
        |INDEX BY
        |   Job 
        |;
        |
        |////////////////////////////////////////////////////////////////////////////////
        |SELECT TOP %1
        |   Jobs.Ref AS Job,
        |   Jobs.Isolated AS Isolated
        |FROM
        |   Catalog.FL_Jobs AS Jobs
        |WHERE
        |    Jobs.State = Value(Catalog.FL_States.Enqueued)  
        |AND Jobs.Ref NOT IN (Select Job From TasksHeartbeatCache)
        |
        |ORDER BY
        |   Jobs.Priority, Jobs.Code ASC   
        |;
        |
        |////////////////////////////////////////////////////////////////////////////////
        |DROP ProcessingJobsCache
        |;
        |
        |////////////////////////////////////////////////////////////////////////////////
        |DROP RetryJobsCache
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
Function QueryTextExpiredJobs()
    
    QueryText = "
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
        |SELECT
        |   Value(Catalog.FL_States.EmptyRef)
        |
        |INDEX BY
        |   State
        |;
        |
        |////////////////////////////////////////////////////////////////////////////////
        |SELECT 
        |   Jobs.Ref AS Job        
        |FROM
        |   Catalog.FL_Jobs AS Jobs
        |
        |INNER JOIN StatesCache AS States
        |ON States.State = Jobs.State
        |
        |WHERE
        |   Jobs.ExpireAt < &CurrentUTCTime   
        |;
        |
        |////////////////////////////////////////////////////////////////////////////////
        |DROP StatesCache
        |;
        |";  
    Return QueryText;
    
EndFunction // QueryTextExpiredJobs()

#EndRegion // ServiceProceduresAndFunctions