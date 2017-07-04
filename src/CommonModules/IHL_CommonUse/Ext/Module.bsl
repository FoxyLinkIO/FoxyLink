////////////////////////////////////////////////////////////////////////////////
// This file is part of IHL (Integration happiness library).
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
// along with this program. If not, see <http://www.gnu.org/licenses/agpl-3.0>.
//
////////////////////////////////////////////////////////////////////////////////

#Region ProgramInterface

// Check if the passed type is a reference data type.
// 
// Parameters: 
//  Type - Type - type that is needed to check.  
//
// Returns:
//  Boolean - False is returned for the Undefined type.
//
Function IsReference(Type) Export

    Return Type <> Type("Undefined") 
      AND (Catalogs.AllRefsType().ContainsType(Type)
        OR Documents.AllRefsType().ContainsType(Type)
        OR Enums.AllRefsType().ContainsType(Type)
        OR ChartsOfCharacteristicTypes.AllRefsType().ContainsType(Type)
        OR ChartsOfAccounts.AllRefsType().ContainsType(Type)
        OR ChartsOfCalculationTypes.AllRefsType().ContainsType(Type)
        OR BusinessProcesses.AllRefsType().ContainsType(Type)
        OR BusinessProcesses.RoutePointsAllRefsType().ContainsType(Type)
        OR Tasks.AllRefsType().ContainsType(Type)
        OR ExchangePlans.AllRefsType().ContainsType(Type));
    
EndFunction // IsReference()


#Region MetadataObjectTypes
 
// Returns the value to identify the common type of "ExchangePlans".
//
// Returns:
//  String.
//
Function TypeNameExchangePlans() Export

    Return "ExchangePlan";

EndFunction // TypeNameExchangePlans()

// Returns the value to identify the common type of "ScheduledJobs".
//
// Returns:
//  String.
//
Function TypeNameScheduledJobs() Export

    Return "ScheduledJob";

EndFunction // TypeNameScheduledJobs()

// Returns the value to identify the common type of "Constants".
//
// Returns:
//  String.
//
Function TypeNameConstants() Export

    Return "Constant";

EndFunction // TypeNameConstants()

// Returns the value to identify the common type of "Catalogs".
//
// Returns:
//  String.
//
Function TypeNameCatalogs() Export

    Return "Catalog";

EndFunction // TypeNameCatalogs()

// Returns the value to identify the common type of "Documents".
//
// Returns:
//  String.
//
Function TypeNameDocuments() Export

    Return "Document";

EndFunction // TypeNameDocuments()

// Returns the value to identify the common type of "Sequences".
//
// Returns:
//  String.
//
Function TypeNameSequences() Export

    Return "Sequence";

EndFunction // TypeNameSequences()

// Returns the value to identify the common type of "DocumentJournals".
//
// Returns:
//  String.
//
Function TypeNameDocumentJournals() Export

    Return "DocumentJournal";

EndFunction // TypeNameDocumentJournals()

// Returns the value to identify the common type of "Enums".
//
// Returns:
//  String.
//
Function TypeNameEnums() Export

    Return "Enum";

EndFunction // TypeNameEnums()

// Returns the value to identify the common type of "Reports".
//
// Returns:
//  String.
//
Function TypeNameReports() Export

    Return "Report";

EndFunction // TypeNameReports()

// Returns the value to identify the common type of "DataProcessors".
//
// Returns:
//  String.
//
Function TypeNameDataProcessors() Export

    Return "DataProcessor";
    
EndFunction // TypeNameDataProcessors()

// Returns the value to identify the common type of "ChartsOfCharacteristicTypes".
//
// Returns:
//  String.
//
Function TypeNameChartsOfCharacteristicTypes() Export

    Return "ChartsOfCharacteristicType";

EndFunction // TypeNameChartsOfCharacteristicTypes() 

// Returns the value to identify the common type of "ChartsOfAccounts".
//
// Returns:
//  String.
//
Function TypeNameChartsOfAccounts() Export

    Return "ChartsOfAccount";

EndFunction // TypeNameChartsOfAccounts()

// Returns the value to identify the common type of "ChartsOfCalculationTypes".
//
// Returns:
//  String.
//
Function TypeNameChartsOfCalculationTypes() Export

    Return "ChartsOfCalculationType";

EndFunction // TypeNameChartsOfCalculationTypes()

// Returns the value to identify the common type of "InformationRegisters".
//
// Returns:
//  String.
//
Function TypeNameInformationRegisters() Export

    Return "InformationRegister";

EndFunction // TypeNameInformationRegisters()

// Returns the value to identify the common type of "AccumulationRegisters".
//
// Returns:
//  String.
//
Function TypeNameAccumulationRegisters() Export

    Return "AccumulationRegister";

EndFunction // TypeNameAccumulationRegisters()

// Returns the value to identify the common type of "AccountingRegisters".
//
// Returns:
//  String.
//
Function TypeNameAccountingRegisters() Export

    Return "AccountingRegister";

EndFunction // TypeNameAccountingRegisters()

// Returns the value to identify the common type of "CalculationRegisters".
//
// Returns:
//  String.
//
Function TypeNameCalculationRegisters() Export

    Return "CalculationRegister";

EndFunction // TypeNameCalculationRegisters()

// Returns the value to identify the common type of "Recalculations".
//
// Returns:
//  String.
//
Function TypeNameRecalculations() Export
 
    Return "Recalculation";
 
EndFunction // TypeNameRecalculations()

// Returns the value to identify the common type of "BusinessProcesses".
//
// Returns:
//  String.
//
Function TypeNameBusinessProcess() Export

    Return "BusinessProcess";

EndFunction // TypeNameBusinessProcess()

// Returns the value to identify the common type of "Tasks".
//
// Returns:
//  String.
//
Function TypeNameTasks() Export

    Return "Task";

EndFunction // TypeNameTasks()



// Returns the name of base type based on the metadata object.
// 
// Parameters:
//  MetadataObject - metadata object for which it is necessary to define the base type.
// 
// Returns:
//  String - the name of base type based on the metadata object.
//
Function BaseTypeNameByMetadataObject(MetadataObject) Export
    
    If Metadata.Catalogs.Contains(MetadataObject) Then
        Return TypeNameCatalogs();
        
    ElsIf Metadata.Documents.Contains(MetadataObject) Then
        Return TypeNameDocuments();
        
    ElsIf Metadata.DataProcessors.Contains(MetadataObject) Then
        Return TypeNameDataProcessors();
        
    ElsIf Metadata.Enums.Contains(MetadataObject) Then
        Return TypeNameEnums();
        
    ElsIf Metadata.InformationRegisters.Contains(MetadataObject) Then
        Return TypeNameInformationRegisters();
        
    ElsIf Metadata.AccumulationRegisters.Contains(MetadataObject) Then
        Return TypeNameAccumulationRegisters();
        
    ElsIf Metadata.AccountingRegisters.Contains(MetadataObject) Then
        Return TypeNameAccountingRegisters();
        
    ElsIf Metadata.CalculationRegisters.Contains(MetadataObject) Then
        Return TypeNameCalculationRegisters();
        
    ElsIf Metadata.ExchangePlans.Contains(MetadataObject) Then
        Return TypeNameExchangePlans();
        
    ElsIf Metadata.ChartsOfCharacteristicTypes.Contains(MetadataObject) Then
        Return TypeNameChartsOfCharacteristicTypes();
        
    ElsIf Metadata.BusinessProcesses.Contains(MetadataObject) Then
        Return TypeNameBusinessProcess();
        
    ElsIf Metadata.Tasks.Contains(MetadataObject) Then
        Return TypeNameTasks();
        
    ElsIf Metadata.ChartsOfAccounts.Contains(MetadataObject) Then
        Return TypeNameChartsOfAccounts();
        
    ElsIf Metadata.ChartsOfCalculationTypes.Contains(MetadataObject) Then
        Return TypeNameChartsOfCalculationTypes();
        
    ElsIf Metadata.Constants.Contains(MetadataObject) Then
        Return TypeNameConstants();
        
    ElsIf Metadata.DocumentJournals.Contains(MetadataObject) Then
        Return TypeNameDocumentJournals();
        
    ElsIf Metadata.Sequences.Contains(MetadataObject) Then
        Return TypeNameSequences();
        
    ElsIf Metadata.ScheduledJobs.Contains(MetadataObject) Then
        Return TypeNameScheduledJobs();
        
    ElsIf Metadata.CalculationRegisters.Contains(MetadataObject.Parent())
        AND MetadataObject.Parent().Recalculations.Find(MetadataObject.Name) = MetadataObject Then
        Return TypeNameRecalculations();
        
    Else
        
        Return "";
        
    EndIf;
    
EndFunction // BaseTypeNameByMetadataObject() 

#EndRegion // MetadataObjectTypes

#EndRegion // ProgramInterface