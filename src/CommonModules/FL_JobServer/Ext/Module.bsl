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

// Runs the job server in this infobase immediately.
//
// Parameters:
//  SafeMode   - Boolean - executes the method with pre-establishing 
//              a safe mode of code execution.
//                  Default value: True.
//
Procedure RunJobServer(SafeMode = True) Export
    
    JobServer = JobServer();
    
    Task = FL_Tasks.NewTask();
    Task.Description = JobServer.Description;
    Task.Key = JobServer.Key;
    Task.MethodName = JobServer.Metadata.MethodName; 
    Task.SafeMode = SafeMode;
    
    FL_Tasks.Run(Task); 
    
EndProcedure // RunJobServer()

// Stops the specified job server immediately.
//
Procedure StopJobServer() Export
    
    JobServer = JobServer();
    
    BackgroundJobsFilter = NewBackgroundJobsFilter();
    BackgroundJobsFilter.State = BackgroundJobState.Active;
    FillPropertyValues(BackgroundJobsFilter, JobServer, , "Description, UUID");
    FL_CommonUseClientServer.RemoveValueFromStructure(BackgroundJobsFilter);
        
    BackgroundJobsByFilter = BackgroundJobsByFilter(BackgroundJobsFilter);
    For Each BackgroundJob In BackgroundJobsByFilter Do
        BackgroundJob.Cancel();        
    EndDo;
            
EndProcedure // StopJobServer()

// Runs an expiration manager task.
//
// Parameters:
//  BackgroundJob - BackgroundJob - the expiration manager task.
//
Procedure RunExpirationManager(BackgroundJob) Export
    
    If TypeOf(BackgroundJob) = Type("BackgroundJob") Then
        
        BackgroundJob = BackgroundJobByUUID(BackgroundJob.UUID);
        If BackgroundJob <> Undefined
            AND TypeOf(BackgroundJob) = Type("BackgroundJob")
            AND BackgroundJob.State = BackgroundJobState.Active Then 
            Return;      
        EndIf;
        
    EndIf; 
    
    Task = FL_Tasks.NewTask();
    Task.MethodName = "FL_JobServer.ExpirationManagerAction";
    Task.Description = "Expiration manager task (FL)";
    BackgroundJob = FL_Tasks.Run(Task);

EndProcedure // RunExpirationManager()

// Returns registered or register the job server in the current infobase.
// 
// Returns:
//  ScheduledJob - job server.
//
Function JobServer() Export

    JobServer = ScheduledJob(Metadata.ScheduledJobs.FL_JobServer);
    Return JobServer;

EndFunction // JobServer()

// Returns the server state - active or non-active.
// 
// Returns:
//  Boolean - True if the server state is active.
//
Function JobServerWatchDog() Export
    
    JobServer = JobServer();
    
    BackgroundJobsFilter = NewBackgroundJobsFilter();
    BackgroundJobsFilter.State = BackgroundJobState.Active;
    FillPropertyValues(BackgroundJobsFilter, JobServer, , "Description, UUID");
    FL_CommonUseClientServer.RemoveValueFromStructure(BackgroundJobsFilter);
        
    BackgroundJobsByFilter = BackgroundJobsByFilter(BackgroundJobsFilter);
    Return BackgroundJobsByFilter.Count() > 0; 
    
EndFunction // JobServerWatchDog()

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
        Raise NStr("en='Scheduled job is not found.
            |Perhaps, it has been deleted by another user.';
            |ru='Регламентное задание не найдено.
            |Возможно, оно удалено другим пользователем.'");
    EndIf;

    Return ScheduledJob;

EndFunction // ScheduledJob()

#Region Actions

// Default JobServer action.
//
Procedure JobServerAction() Export
    
    RetryJobs = New Array;
    DeleteJobs = New Array;
    
    //Var ExpirationManagerTask;

    WorkerCount = GetWorkerCount();
    If NOT ValueIsFilled(WorkerCount) OR WorkerCount = 0 Then
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
    If NOT QueryResult.IsEmpty() Then
        
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

    Return Constants.FL_WorkerCount.Get();
    
EndFunction // GetWorkerCount()

// Returns default worker count value.
//
// Returns:
//  Number - default worker count value. 
//
Function DefaultWorkerCount() Export
    
    Return 20;
    
EndFunction // DefaultWorkerCount() 

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

    Return Constants.FL_RetryAttempts.Get();
    
EndFunction // GetRetryAttempts()

// Returns default retry attemps value.
//
// Returns:
//  Number - default retry attemps value.
//
Function DefaultRetryAttempts() Export
    
    Return 5;
    
EndFunction // DefaultRetryAttempts() 

#EndRegion // ServiceInterface

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
Procedure PopJobServerState(WorkerCount, DeleteJobs, RetryJobs) 
    
    BJSActive    = BackgroundJobState.Active;
    BJSCanceled  = BackgroundJobState.Canceled;
    BJSCompleted = BackgroundJobState.Completed;
    BJSFailed    = BackgroundJobState.Failed;
   
    FinalStates = Catalogs.FL_States.FinalStates();
    
    RetryAttempts = GetRetryAttempts();
    If NOT ValueIsFilled(RetryAttempts) Then
        RetryAttempts = DefaultRetryAttempts();    
    EndIf;
  
    Query = New Query;
    Query.Text = QueryTextTasksHeartbeat();
    WorkersTable = Query.Execute().Unload();
    For Each Worker In WorkersTable Do
            
        BackgroundJob = BackgroundJobByUUID(Worker.TaskId);
        If BackgroundJob = Undefined 
            OR BackgroundJob.State = BJSCanceled
            OR BackgroundJob.State = BJSCompleted
            OR BackgroundJob.State = BJSFailed Then
            
            If FinalStates.FindByValue(Worker.Job.State) <> Undefined 
                OR Worker.RetryAttempts >= RetryAttempts Then
                
                DeleteJobs.Add(Worker.Job);
                
            Else
                
                RetryJobs.Add(Worker.Job);
                
            EndIf;
            
        ElsIf BackgroundJob.State = BJSActive Then
            
            WorkerCount = WorkerCount - 1;    
            
        EndIf;
        
    EndDo;
 
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
        If NOT QueryResult.IsEmpty() Then
            EnqueuedJobs = QueryResult.Unload().UnloadColumn("Job");    
        EndIf;
        
    EndIf;
    
    // Move to EnqueuedState
    For Each Job In RetryJobs Do
        
        Task = FL_Tasks.NewTask();
        Task.MethodName = "Catalogs.FL_Jobs.Trigger";
        Task.Parameters.Add(Job);
        Task.Description = "Background job task (FoxyLink)";
        Task.SafeMode = False;
        BackgroundJob = FL_Tasks.Run(Task);
        
        // TODO: correct state change.
        //Catalogs.FL_Jobs.ChangeState(Job, Catalogs.FL_States.
          
        RecordManager = InformationRegisters.FL_TasksHeartbeat
            .CreateRecordManager();
        RecordManager.Job = Job;
        RecordManager.Read();
        If NOT RecordManager.Selected() Then
            RecordManager.Job = Job;        
        EndIf;
        RecordManager.TaskId = BackgroundJob.UUID;
        RecordManager.RetryAttempts = RecordManager.RetryAttempts + 1;
        RecordManager.Write();
            
    EndDo;
    
    For Each Job In EnqueuedJobs Do
        
        Task = FL_Tasks.NewTask();
        Task.MethodName = "Catalogs.FL_Jobs.Trigger";
        Task.Parameters.Add(Job);
        Task.Description = "Background job task (FoxyLink)";
        Task.SafeMode = False;
        BackgroundJob = FL_Tasks.Run(Task);
            
        RecordManager = InformationRegisters.FL_TasksHeartbeat.CreateRecordManager();
        RecordManager.Job = Job;
        RecordManager.TaskId = BackgroundJob.UUID;
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
Function NewBackgroundJobsFilter()
    
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

// Only for internal use.
//
Function BackgroundJobByUUID(UUID)
    
    Return BackgroundJobs.FindByUUID(UUID);    
    
EndFunction // BackgroundJobByUUID()

// Only for internal use.
//
Function BackgroundJobsByFilter(Filter)
    
    Return BackgroundJobs.GetBackgroundJobs(Filter);    
    
EndFunction // BackgroundJobsByFilter()

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
        |AND Jobs.Ref NOT IN (Select Job From TasksHeartbeatCache)
        |
        |ORDER BY
        |   Jobs.Priority ASC   
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
