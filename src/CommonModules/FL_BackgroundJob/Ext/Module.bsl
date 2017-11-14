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

// Creates a new fire-and-forget job based on a given method call expression.
//
// Parameters:
//  Method         -                - method call expression that will be 
//                                      marshalled to the Server.
//  InvocationData - FixedStructure - contains data for a service method 
//                                      invocation.
//
// Returns:
//  UUID - unique identifier of a created background job or undefined, 
//          if it was not created.
//
Function Enqueue(Method, InvocationData) Export

    Return False;
    
EndFunction // Enqueue()

// Changes state of a job with the specified Job to the DeletedState. 
// If FromState value is not undefined, state change will be performed 
// only if the current state name of the job equal to the given value.
//
// Parameters:
//  Job   - UUID                -
//        - CatalogRef.FL_Jobs -
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
//  Job   - UUID                -
//        - CatalogRef.FL_Jobs -
//  State -                     - current state assertion.
//                  Default value: Undefined.
//
// Returns:
//  Boolean - True, if state change succeeded, otherwise False.
//
Function Requeue(Job, FromState = Undefined) Export

    Return False;
    
EndFunction // Requeue()

Function ContinueWith() Export

    Return False;
    
EndFunction // ContinueWith()

// Creates a new background job based on a specified instance method
// call expression and schedules it to be enqueued after a given delay.
//
Function Schedule() Export

    Return False;
    
EndFunction // Schedule()

#EndRegion // ProgramInterface
