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

#Region ProgramInterface

// Returns a processing result.
//
// Parameters:
//  Invocation - Structure               - see function Catalogs.FL_Messages.NewInvocation.
//  Exchange   - CatalogRef.FL_Exchanges - reference of the FL_Exchanges catalog.
//  Stream     - Stream                  - message stream from an external system.
//  Sync       - Boolean                 - if True processing will be synchronous.
//
// Returns:
//  Structure - see fucntion Catalogs.FL_Jobs.NewJobResult. 
//
Function ProcessMessage(Invocation, Exchange, Stream, Sync = False) Export

    //Return Catalogs.FL_Jobs.Create(JobData);
    
EndFunction // Enqueue()

#EndRegion // ProgramInterface

#Region ServiceIterface


#EndRegion // ServiceIterface