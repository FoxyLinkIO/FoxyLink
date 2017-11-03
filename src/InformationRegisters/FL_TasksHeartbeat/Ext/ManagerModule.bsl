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

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region ProgramInterface

Procedure AddRecords(NewRecord) Export
    
    //AvailableFilterFields();
    
    //RecordSet = InformationRegisters.FL_TasksHeartbeat.CreateRecordSet();
    //RecordSet.Filter.Job.Add(Filter);
    //RecordSet.Write();
    
EndProcedure // AddRecords()

Procedure DeleteRecordsByFilter(Filter) Export
    
    
    // TODO: Full refactor.
    
    RecordSet = InformationRegisters.FL_TasksHeartbeat.CreateRecordSet();
    // RecordSet.Filter.Job.ComparisonType = ComparisonType.InList;
    // RecordSet.Filter.Job.
    For Each FilterItem In Filter.Job Do
        RecordSet.Filter.Job.Set(FilterItem);
        RecordSet.Write();
    EndDo;
    
EndProcedure // DeleteRecordsByFilter()

#EndRegion // ProgramInterface

#EndIf