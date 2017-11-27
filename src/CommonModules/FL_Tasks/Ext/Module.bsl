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

// Queues the specified work to run on backgroud and returns a BackgroundJob
// object that represents that work.
//
// Parameters:
//  Task - Structure - see function FL_Tasks.NewTask.
//
// Returns:
//  BackgroundJob - object that represents queued work. 
//
Function Run(Task) Export
    
    FL_InteriorUse.AdministrativeRights();
    
    Parameters = New Array;
    Parameters.Add(Task.MethodName);
    Parameters.Add(Task.Parameters);
    Parameters.Add(Task.SafeMode);
    Parameters.Add(CurrentUniversalDateInMilliseconds());
    
    BackgroundJob = BackgroundJobs.Execute(
        "FL_Tasks.TaskAction", 
        Parameters, 
        Task.Key,
        Task.Description);
        
    Return BackgroundJob;
    
EndFunction // RunTask()

// Returns a new task structure that represents a single operation 
// that does not return a value and that usually executes asynchronously.
//
// Returns:
//  Structure - with values:
//      * MethodName        - String    - the name of exported procedure or a function
//              of a non-global server module which could be performed at the server. 
//      * Parameters        - Array     - array of parameters passed to the method. 
//              Number and types of parameters should correspond to the method 
//              parameters.All passed parameters should support serialization. 
//              Otherwise, an exception is generated and the background job will
//              not be launched. If last parameters of the method have default 
//              values, it is allowed not to set them in the array.
//                                  Default value: Array.
//      * Key               - String    - task key. If this key is set, it should be 
//              unique among keys of the active background job, which have 
//              the same method's name as current background job does.  
//      * Description       - String    - task description.
//      * SafeMode          - Boolean   - executes the method with pre-establishing 
//                                          a safe mode of code execution.
//                                  Default value: True.
//      * CancellationToken - Arbitrary - propagates notification that 
//                                          operations should be canceled.
//
Function NewTask() Export
    
    Task = New Structure;
    Task.Insert("MethodName");
    Task.Insert("Parameters", New Array);
    Task.Insert("Key");
    Task.Insert("Description");
    Task.Insert("SafeMode", True); 
    Task.Insert("CancellationToken");
    Return Task;
    
EndFunction // NewTask()

#EndRegion // ProgramInterface

#Region ServiceInterface

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
        If SafeMode Then
            FL_RunInSafeMode.ExecuteInSafeMode(Algorithm, Parameters);    
        Else
            Execute Algorithm;
        EndIf;
    Except
        Raise;
    EndTry;
    
    PerformanceDuration = CurrentUniversalDateInMilliseconds() - StartPerformance; 
    
EndProcedure // TaskAction() 

#EndRegion // ServiceInterface 