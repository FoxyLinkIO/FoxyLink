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

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
    
#Region ProgramInterface

// Registers continuation for the parent background job.
//
// Parameters:
//  ParentJob - CatalogRef.FL_Jobs - reference to the parent background job.
//  Job       - CatalogRef.FL_Jobs - reference to the continuation background job.
//
Procedure RegisterContinuation(ParentJob, Job) Export
    
    Try
        
        RecordManager = InformationRegisters.FL_JobContinuations
            .CreateRecordManager();
        RecordManager.ParentJob = ParentJob;
        RecordManager.Job = Job;
        RecordManager.Read();
        If NOT RecordManager.Selected() Then
            RecordManager.ParentJob = ParentJob;
            RecordManager.Job = Job;
        EndIf;
        
        RecordManager.Write();
        
    Except
        
         FL_InteriorUse.WriteLog("FoxyLink.Tasks.RegisterContinuation", 
            EventLogLevel.Error,
            Metadata.InformationRegisters.FL_JobContinuations,
            ErrorDescription());
        
    EndTry;
    
EndProcedure // RegisterContinuation()

#EndRegion // ProgramInterface

#EndIf