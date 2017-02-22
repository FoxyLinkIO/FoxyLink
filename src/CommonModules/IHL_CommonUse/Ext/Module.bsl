////////////////////////////////////////////////////////////////////////////////
// This file is part of IHL (Integration happiness library).
// Copyright © 2016-2017 Petro Bazeliuk.
// 
// IHL is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as 
// published by the Free Software Foundation, either version 3 
// of the License, or any later version.
// 
// IHL is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public 
// License along with IHL. If not, see <http://www.gnu.org/licenses/>.
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

#EndRegion // ProgramInterface