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
// along with FoxyLink. If not, see <http://www.gnu.org/licenses/agpl-3.0>.
//
////////////////////////////////////////////////////////////////////////////////

#Region ProgramInterface

// Updates a current task result structure with actual data.
//
// Parameters:
//   TaskResults - Structure - see function FL_Tasks.NewTaskResults. 
//
Procedure UpdateTaskResult(TaskResults) Export

    BackgroundJob = FL_JobServer.BackgroundJobByUUID(TaskResults.TaskId);
    If BackgroundJob = Undefined Then
    
        TaskResults.State = "Failed";
        TaskResults.ErrorInformation = FL_ErrorsClientServer
            .BackgroundJobAbnormalTermination();        
        FL_InteriorUse.WriteLog("FoxyLink.Tasks.TaskCompleted", 
            EventLogLevel.Error,
            Metadata.CommonModules.FL_Tasks,
            TaskResults.ErrorInformation);
        Return; 
        
    EndIf;

    Messages = New Array(TaskResults.Messages);
    FL_CommonUseClientServer.ExtendArray(Messages, FL_JobServer
        .BackgroundJobMessages(BackgroundJob));    
    TaskResults.Messages = FL_CommonUse.FixedData(Messages);     
        
    If BackgroundJob.State = BackgroundJobState.Active Then
        Return;
    EndIf;

    If BackgroundJob.State = BackgroundJobState.Canceled Then
        
        SetPrivilegedMode(True);
        
        FL_InteriorUseReUse.SetSessionParameters();
        SearchResult = SessionParameters.FL_CanceledBackgroundJobs.Find(
            TaskResults.TaskId);
            
        SetPrivilegedMode(False);
        
        If SearchResult = Undefined Then
            TaskResults.State = "Failed";
            TaskResults.ErrorInformation = FL_ErrorsClientServer
                .BackgroundJobWasCanceled(); 
        Else
            TaskResults.State = "Canceled";
        EndIf;
        
        Return;
        
    EndIf;

    If BackgroundJob.State = BackgroundJobState.Failed Then
        
        TaskResults.State = "Failed";
        TaskResults.ErrorInformation = BackgroundJob.ErrorInfo;
        Return;
        
    EndIf;

    TaskResults.State = "Completed";

EndProcedure // UpdateTaskResult() 

// Queues the specified work to run on backgroud and returns a BackgroundJob
// object that represents that work.
//
// Parameters:
//  Task - Structure - see function FL_TasksClientServer.NewTask.
//
// Returns:
//  Structure - see function FL_Tasks.NewTaskResults. 
//
Function Run(Task) Export
    
    RunSync = False;
    
    FileInfobase = FL_CommonUse.FileInfobase();
    FillStorageAddress(Task);
    
    #If ExternalConnection Then
    
    If Task.WithoutExtensions AND FileInfobase Then
        Raise FL_ErrorsClientServer.CannotStartBackgroundJobWithoutExtensions();
    EndIf;
    
    RunSync = FileInfobase OR Task.Wait;

    #Else
        
    RunSync = Task.Wait;    
    If FileInfobase Then 
        RunSync = RunSync OR ValueIsFilled(FL_JobServer.ActiveBackgroundJobs());
    EndIf;
    
    #EndIf

    If FileInfobase AND NOT RunSync Then
        CheckRunModeForFileInfobase(Task);    
    EndIf;
    
    If RunSync Then
        Return RunTaskSynchronously(Task);        
    EndIf;
    
    Return RunTaskAsynchronously(Task);
            
EndFunction // Run()

#EndRegion // ProgramInterface

#Region ServiceInterface

// Saves a serialized value to a temporary storage.
//
// Parameters:
//  Data           - Arbitrary - data that should be placed in the temporary storage.
//  StorageAddress - String    - address in the temporary storage.
//
//
Procedure PutDataToTempStorage(Data, StorageAddress) Export
    
    If IsTempStorageURL(StorageAddress) Then
        PutToTempStorage(Data, StorageAddress);
    EndIf;
    
EndProcedure // PutDataToTempStorage()

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
//
Procedure TaskAction(MethodName, Parameters, SafeMode) Export
    
    ParametersCount = -1;
    If TypeOf(Parameters) = Type("Array") Then
        ParametersCount = Parameters.UBound();     
    EndIf;
    
    MemoryStream = New MemoryStream;
    DataWriter = New DataWriter(MemoryStream, , , Chars.CR + Chars.LF, "");
    DataWriter.WriteChars(MethodName);
    DataWriter.WriteChars("(");
    
    For Index = 0 To ParametersCount Do
        
        DataWriter.WriteChars("Parameters[");
        DataWriter.WriteChars(String(Index));
        DataWriter.WriteChars("]");
        If Index <> ParametersCount Then
            DataWriter.WriteChars(",");
        EndIf;

    EndDo;
    
    DataWriter.WriteChars(")");
    DataWriter.Close();
    Algorithm = GetStringFromBinaryData(MemoryStream.CloseAndGetBinaryData());
    
    Try
        If SafeMode Then
            FL_RunInSafeMode.ExecuteInSafeMode(Algorithm, Parameters);    
        Else
            Execute Algorithm;
        EndIf;
    Except
        Raise;
    EndTry;
    
EndProcedure // TaskAction() 

#EndRegion // ServiceInterface 

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
Procedure CheckRunModeForFileInfobase(Task)
    
    If CurrentRunMode() = Undefined Then
        
        Session = GetCurrentInfoBaseSession();
        If Task.ConfigureAwait = Undefined AND Session.ApplicationName = "BackgroundJob" Then
            Raise FL_ErrorsClientServer.CannotExecuteSimultaneouslyBackgroundJob();
        ElsIf Session.ApplicationName = "COMConnection" Then
            Raise FL_ErrorsClientServer.CannotStartBackgroundJobInCOMConnection();
        EndIf;   
        
    EndIf;     
    
EndProcedure // CheckRunModeForFileInfobase()

// Only for internal use.
//
Procedure FillStorageAddress(Task)
    
    If TypeOf(Task.Context) = Type("UUID") Then
        If NOT IsTempStorageURL(Task.StorageAddress) Then
            
            StorageAddress = PutToTempStorage(Undefined, Task.Context);
            Task.StorageAddress = StorageAddress; 
            Task.Parameters.Add(StorageAddress);
            
        EndIf;
    EndIf;
    
EndProcedure // FillStorageAddress()

// Only for internal use.
//
Procedure FillTaskResultErrorInformation(TaskResults, BackgroundJob = Undefined)
    
    TaskResults.State = "Failed";    
    If BackgroundJob <> Undefined AND BackgroundJob.ErrorInfo <> Undefined Then
        TaskResults.ErrorInformation = BackgroundJob.ErrorInfo;
    Else
        TaskResults.ErrorInformation = ErrorInfo();
    EndIf;
      
EndProcedure // FillTaskResultErrorInformation()

// Only for internal use.
//
Procedure TaskAwaiting(BackgroundJob, TaskResults, ConfigureAwait)
    
    If ConfigureAwait <> 0 Then
        
        Try
            
            If FL_CommonUseReUse.IsAppVersion_8_3_13_OrHigher() Then
                BackgroundJob.WaitForExecutionCompletion(ConfigureAwait);
            Else
                BackgroundJob.WaitForCompletion(ConfigureAwait);    
            EndIf;
            
            TaskResults.Messages = FL_JobServer.BackgroundJobMessages(
                BackgroundJob);

        Except
            // No special processing is required. 
            // Perhaps the exception was raised because a timeout occurred.
        EndTry;
        
    EndIf;

EndProcedure // TaskAwaiting()

// Only for internal use.
//
Function RunTaskSynchronously(Task)
    
    TaskResults = NewTaskResults(Task);
    
    Try
            
        TaskAction(Task.MethodName, Task.Parameters, Task.SafeMode); 
        TaskResults.State = "Completed";
        
    Except
        
        FillTaskResultErrorInformation(TaskResults);
        FL_InteriorUse.WriteLog("FoxyLink.Tasks.RunTaskSynchronously", 
            EventLogLevel.Error,
            Metadata.CommonModules.FL_Tasks,
            TaskResults.ErrorInformation);
        
    EndTry; 
    
    Return TaskResults;
    
EndFunction // RunTaskSynchronously()

// Only for internal use.
//
Function RunTaskAsynchronously(Task)
    
    TaskResults = NewTaskResults(Task);
    
    Try
        
        Parameters = New Array;
        Parameters.Add(Task.MethodName);
        Parameters.Add(Task.Parameters);
        Parameters.Add(Task.SafeMode);
        
        Description = Task.Description;
        If NOT ValueIsFilled(Description) Then
            Description = Task.MethodName;
        EndIf;
    
        If Task.WithoutExtensions Then
            BackgroundJob = ConfigurationExtensions
                .ExecuteBackgroundJobWithoutExtensions("FL_Tasks.TaskAction", 
                    Parameters, Task.Key, Description);
        Else
            BackgroundJob = BackgroundJobs.Execute("FL_Tasks.TaskAction", 
                Parameters, Task.Key, Description);
        EndIf;

    Except
        
        FillTaskResultErrorInformation(TaskResults, BackgroundJob);                
        Return TaskResults;
        
    EndTry;
    
    If BackgroundJob <> Undefined AND BackgroundJob.ErrorInfo <> Undefined Then
        
        FillTaskResultErrorInformation(TaskResults, BackgroundJob);
        Return TaskResults;
        
    EndIf;

    TaskResults.TaskId = BackgroundJob.UUID;
    TaskAwaiting(BackgroundJob, TaskResults, Task.ConfigureAwait);
    
    UpdateTaskResult(TaskResults);

    Return TaskResults;
    
EndFunction // RunTaskAsynchronously()

// Returns a new structure of task execution that represents a single 
// background task with assigned job for asynchronous execution.
//
// Parameters:
//  BackgroundJob - BackgroundJob - background job that performs asynchronous 
//                                      operation. 
//
// Returns:
//  Structure - with values: 
//   * State                  - String     - "Active" if the job is running.
//                                           "Completed " if the job has completed.
//                                           "Failed" if the job has completed with error.
//                                           "Canceled" if the job is canceled by a user or by an administrator.
//                                  Default value: "Active".
//   * TaskId                 - UUID       - contains the ID of the background job.
//                                  Default value: Undefined.      
//   * StorageAddress         - String     - the address of the temporary storage where the procedure 
//                                           result must be (or already is) stored.
//   * ErrorInformation       - ErrorInfo  - contains structured information about error (exception).
//                            - String     - unstructured error information.
//   * Messages               - FixedArray - an array of UserMessage objects generated 
//                                           in the process of executing a background job.
//
Function NewTaskResults(Task)
    
    TaskResults = New Structure;
    TaskResults.Insert("State", "Active");
    TaskResults.Insert("TaskId", Undefined);
    TaskResults.Insert("StorageAddress", Task.StorageAddress);
    TaskResults.Insert("ErrorInformation");
    TaskResults.Insert("Messages", New FixedArray(New Array));
    
    Return TaskResults;    
    
EndFunction // NewTaskResults()

#EndRegion // ServiceProceduresAndFunctions