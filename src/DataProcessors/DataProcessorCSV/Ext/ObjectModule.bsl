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

Var RefTypesCache;
Var StreamWriter;

#Region ProgramInterface

// Constructor of stream object.
//
// Parameters:
//  OpenFile - String - output filename.
//             Default value: Empty string.
//
Procedure Initialize(OpenFile = "") Export
    
    RefTypesCache = New Map;
    
EndProcedure // Initialize()

#EndRegion // ProgramInterface

#Region ServiceProgramInterface

// Outputs sequentially result of the data composition shema into stream object.
//
// Parameters:
//  Item            - DataCompositionResultItem         - a data composition result item.
//  DataCompositionProcessor - DataCompositionProcessor - object that performs data composition.
//  TemplateColumns - Structure - see function IHLDataComposition.TemplateColumns.
//  GroupNames      - Structure - see function IHLDataComposition.GroupNames.
//
Procedure MemorySavingOutput(Item, DataCompositionProcessor, TemplateColumns, 
    GroupNames) Export
    
EndProcedure // MemorySavingOutput()

// Outputs fast result of the data composition shema into stream object.
// 
// Note:
//  Additional memory in use.
//
// Parameters:
//  Item            - DataCompositionResultItem         - a data composition result item.
//  DataCompositionProcessor - DataCompositionProcessor - object that performs data composition.
//  TemplateColumns - Structure - see function IHLDataComposition.TemplateColumns.
//  GroupNames      - Structure - see function IHLDataComposition.GroupNames.
//
Procedure FastOutput(Item, DataCompositionProcessor, TemplateColumns, 
    GroupNames) Export 
    
EndProcedure // FastOutput()

#EndRegion // ServiceProgramInterface