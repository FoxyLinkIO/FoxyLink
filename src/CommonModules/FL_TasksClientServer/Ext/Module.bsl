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

#Region ProgramInterface

// Updates a poll interval;
// 
// Parameters:
//  PollOptions - Structure - see function FL_TasksClientServer.NewPollOptions. 
// 
Procedure UpdatePollInterval(PollOptions) Export

    PollOptions.PollInterval = PollOptions.PollInterval * PollOptions.PollIncreaseMultiplier;
    If PollOptions.PollInterval > PollOptions.MaxInterval Then
        PollOptions.PollInterval = PollOptions.MaxInterval;
    EndIf;
        
EndProcedure // UpdatePollInterval()

// Returns a new poll options structure for background job with default values..
// 
// Returns:
//  Structure - with values:
//      * MinInterval            - Number - minimum background job polling time
//                          Default value: 1.
//      * MaxInterval            - Number - maximum background job polling time.
//                          Default value: 20.
//      * PollInterval           - Number - period (seconds) accurate to 1/10 of a seconds that has to elapse 
//                                          before the procedure is called (positive number). If the set value 
//                                          is less than 1, then the value of the third parameter should be True
//                                          of the procedure AttachIdleHandler.
//                          Default value: 1.
//      * PollIncreaseMultiplier - Number - multiplier to increase the background job polling time.  
//                          Default value: 1.5.
//
Function NewPollOptions() Export
 
    PollOptions = New Structure;
    PollOptions.Insert("MinInterval", 1);
    PollOptions.Insert("MaxInterval", 20);
    PollOptions.Insert("PollInterval", 1);
    PollOptions.Insert("PollIncreaseMultiplier", 1.5);
    
    Return PollOptions;  
    
EndFunction // NewPollOptions()

// Returns a new task structure that represents a single operation 
// that can return a value and that usually executes asynchronously.
//
// Returns:
//  Structure - with values:
//      * Context           - UUID      - the UUID of the object containing the temporary storage.
//                                  Default value: Undefined.
//      * Description       - String    - task description.
//      * Key               - String    - task key. If this key is set, it should be 
//              unique among keys of the active background job, which have 
//              the same method's name as current background job does.
//      * MethodName        - String    - the name of exported procedure or a function
//              of a non-global server module which could be performed at the server. 
//      * Parameters        - Array     - array of parameters passed to the method. 
//              Number and types of parameters should correspond to the method 
//              parameters.All passed parameters should support serialization. 
//              Otherwise, an exception is generated and the background job will
//              not be launched. If last parameters of the method have default 
//              values, it is allowed not to set them in the array.
//                                  Default value: Array.
//      * SafeMode          - Boolean   - executes the method with pre-establishing 
//                                          a safe mode of code execution.
//                                  Default value: True.
//      * StorageAddress    - String    - the address of the temporary storage 
//              where the procedure result must be stored. If the address is 
//              not set, it is generated automatically.
//      * WithoutExtensions - Boolean   - initiates executing of the backround 
//                                          task without loading extensions.
//                                   Default value: False.
//      * ConfigureAwait    - Number    - background task completion timeout, in seconds.
//                                        If set to 0, means "do not wait for completion."
//                          - Undefined - wait for completion if Undefined.
//                                  Default value: 0.
//      * Wait              - Boolean   -  if True, the job always runs 
//              in the current thread rather than in background.
//                                  Default value: False.   
//                  
Function NewTask() Export
    
    Task = New Structure;
    Task.Insert("Context");
    Task.Insert("Description");
    Task.Insert("Key");
    Task.Insert("MethodName");
    Task.Insert("Parameters", New Array);
    Task.Insert("SafeMode", True);
    Task.Insert("StorageAddress", "");
    Task.Insert("WithoutExtensions", False);
    Task.Insert("ConfigureAwait", 0);
    Task.Insert("Wait", False);
    
    Return Task;
    
EndFunction // NewTask()

#EndRegion // ProgramInterface