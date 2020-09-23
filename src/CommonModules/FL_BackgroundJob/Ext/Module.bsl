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

// Creates a new fire-and-forget job based on a given method call expression.
//
// Parameters:
//  JobData - Structure - see function FL_BackgroundJob.NewJobData. 
//
// Returns:
//  CatalogRef.FL_Jobs - ref to created background job or Undefined, if it was 
//                       not created.
//
Function Enqueue(JobData) Export

    Return Catalogs.FL_Jobs.Create(JobData);
    
EndFunction // Enqueue()

// Changes state of a job with the specified Job to the Deleted state. 
// If FromState value is not undefined, state change will be performed 
// only if the current state name of the job equal to the given value.
//
// Parameters:
//  Job       - CatalogRef.FL_Jobs   - reference to the background job.
//  FromState - CatalogRef.FL_States - current state assertion.
//                  Default value: Undefined.
//
// Returns:
//  Boolean - True, if state change succeeded, otherwise False.
//
Function Delete(Job, FromState = Undefined) Export

    Return Catalogs.FL_Jobs.ChangeState(Job, Catalogs.FL_States.Deleted, 
        FromState);
    
EndFunction // Delete()

// Changes state of a job with the specified parameter Job to the Enqueued state.
// If FromState value is not undefined, state change will be performed 
// only if the current state name of the job equal to the given value.
//
// Parameters:
//  Job       - CatalogRef.FL_Jobs   - reference to the background job.
//  FromState - CatalogRef.FL_States - current state assertion.
//                  Default value: Undefined.
//
// Returns:
//  Boolean - True, if state change succeeded, otherwise False.
//
Function Requeue(Job, FromState = Undefined) Export

    Return Catalogs.FL_Jobs.ChangeState(Job, Catalogs.FL_States.Enqueued, 
        FromState);
    
EndFunction // Requeue()

// Creates a new background job that will wait for a successful completion 
// of another background job to be triggered in the Enqueued state.
//
// Parameters:
//  Job     - CatalogRef.FL_Jobs - reference to the background job.
//  JobData - Structure          - see function FL_BackgroundJob.NewJobData. 
//                          Default value: Undefined.
//
// Returns:
//  CatalogRef.FL_Jobs - ref to created background job or Undefined, if it was 
//                       not created.
//
Function ContinueWith(Job, JobData) Export

    JobData.Continuations = Job;
    JobData.State = Catalogs.FL_States.Awaiting;
    Return Enqueue(JobData);
    
EndFunction // ContinueWith()

// Creates a new background job based on a specified instance method
// call expression and schedules it to be enqueued after a given delay.
//
// Parameters:
//  JobData - Structure - see function FL_BackgroundJob.NewJobData.
//
// Returns:
//  CatalogRef.FL_Jobs - ref to created background job or Undefined, if it was 
//                       not created.
//
Function Schedule(JobData) Export

    Return False;
    
EndFunction // Schedule()

#EndRegion // ProgramInterface

#Region ServiceIterface

// This procedure adds the value into input data parameters.
//
// Parameters:
//  JobData - Structure - see function Catalogs.FL_Jobs.NewJobData.
//  Name    - String    - parameter name.
//  Value   - Arbitrary - parameter value.
//
Procedure AddToJobInputData(JobData, Name, Value) Export
      
    Catalogs.FL_Jobs.AddToJobInputData(JobData, Name, Value);   
    
EndProcedure // AddToJobInputData()

// This procedure adds the value into output data parameters.
//
// Parameters:
//  JobData - Structure - see function Catalogs.FL_Jobs.NewJobData.
//  Name    - String    - parameter name.
//  Value   - Arbitrary - parameter value.
//
Procedure AddToJobOutputData(JobData, Name, Value) Export
    
    Catalogs.FL_Jobs.AddToJobOutputData(JobData, Name, Value);
    
EndProcedure // AddToJobOutputData()

// Returns a new job data for a service method.
//
// Returns:
//  Structure - see function Catalogs.FL_Jobs.NewJobData.
//
Function NewJobData() Export
    
    Return Catalogs.FL_Jobs.NewJobData();
    
EndFunction // NewJobData()

#EndRegion // ServiceIterface