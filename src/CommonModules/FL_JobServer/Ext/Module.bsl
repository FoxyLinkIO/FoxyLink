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
// along with FoxyLink. If not, see <http://www.gnu.org/licenses/agpl-3.0>.
//
////////////////////////////////////////////////////////////////////////////////

#Region ProgramInterface

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
    
    Task = FL_Tasks.NewTask();
    Task.MethodName = JobServer.Metadata.MethodName;
    Task.Key = String(JobServer.UUID); 
    Task.Description = JobServer.Description;
    FL_Tasks.Run(Task); 
    
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

#EndRegion // ProgramInterface

#Region ServiceInterface

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

// Returns registered or register the job server in the current infobase.
// 
// Returns:
//  ScheduledJob - job server.
//
Function JobServer() Export

    FL_InteriorUse.AdministrativeRights();
    
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
    If NOT IsOk Then
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

// Returns default job server id.
//
// Returns:
//  UUID - default job server id.
//
Function DefaultJobServerId() Export
    
    Return New UUID("00000000-0000-0000-0000-000000000000");
    
EndFunction // DefaultJobServerId() 

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
    If NOT ValueIsFilled(RetryAttempts) Then
        RetryAttempts = DefaultRetryAttempts();    
    EndIf;
  
    Query = New Query;
    Query.Text = QueryTextTasksHeartbeat();
    QueryResult = Query.Execute();
    If NOT QueryResult.IsEmpty() Then
        
        WorkersTable = QueryResult.Unload();
        For Each Worker In WorkersTable Do
                
            BackgroundJob = BackgroundJobByUUID(Worker.TaskId);
            If BackgroundJob = Undefined 
                OR BackgroundJob.State = bjsCanceled
                OR BackgroundJob.State = bjsCompleted
                OR BackgroundJob.State = bjsFailed Then
                
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
Function NewScheduledJobsFilter(Keys = Undefined, UseMetadata = False)
    
    BasicFilter = New Structure;
    BasicFilter.Insert("Use");
    BasicFilter.Insert("Key");
    BasicFilter.Insert("UUID");
    BasicFilter.Insert("Metadata");
    BasicFilter.Insert("Predefined");
    BasicFilter.Insert("Description");
    
    If UseMetadata Then
        MetaSJ                  = Metadata.ScheduledJobs.FL_JobServer;
        BasicFilter.Use         = MetaSJ.Use;
        BasicFilter.Key         = MetaSJ.Key;
        BasicFilter.Metadata    = MetaSJ;
        BasicFilter.Predefined  = MetaSJ.Predefined;
        BasicFilter.Description = MetaSJ.Name;
    EndIf;
    
    If TypeOf(Keys) = Type("String") AND NOT IsBlankString(Keys) Then
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
    
    If UseMetadata Then
        MetaSJ                  = Metadata.ScheduledJobs.FL_JobServer;
        BasicFilter.Key         = String(GetJobServerId());
        BasicFilter.MethodName  = MetaSJ.MethodName;
        BasicFilter.Description = MetaSJ.Name;
    EndIf;
    
    If TypeOf(Keys) = Type("String") AND NOT IsBlankString(Keys) Then
        SpecificFilter = New Structure(Keys);
        FillPropertyValues(SpecificFilter, BasicFilter);
        Return SpecificFilter;
    EndIf;
    
    Return BasicFilter;
    
EndFunction // NewBackgroundJobsFilter()

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
