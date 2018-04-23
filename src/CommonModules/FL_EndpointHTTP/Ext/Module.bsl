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

// Returns the external event handler info structure for this module.
//
// Returns:
//  Structure - see function FL_InteriorUse.NewExternalEventHandlerInfo.
//
Function EventHandlerInfo() Export
    
    EventHandlerInfo = FL_InteriorUse.NewExternalEventHandlerInfo();
    EventHandlerInfo.EventHandler = "FL_EndpointHTTP.ProcessMessage";
    EventHandlerInfo.Default = True;
    EventHandlerInfo.Version = "1.0.2";
    EventHandlerInfo.Description = StrTemplate(NStr("
            |en='Standard HTTP event handler, ver. %1.';
            |ru='Стандартный обработчик событий HTTP, вер. %1.';
            |uk='Стандартний обробник подій HTTP, вер. %1.';
            |en_CA='Standard HTTP event handler, ver. %1.'"), 
        EventHandlerInfo.Version);
        
    EventSources = New Array;
    EventSources.Add(Upper("HTTPService.FL_AppEndpoint"));
    EventSources.Add(Upper("HTTPСервис.FL_AppEndpoint"));
    
    AvailableOperations = Catalogs.FL_Operations.AvailableOperations();
    For Each AvailableOperation In AvailableOperations Do
        EventHandlerInfo.Publishers.Insert(AvailableOperation.Value, 
            EventSources);    
    EndDo;
       
    Return FL_CommonUse.FixedData(EventHandlerInfo);
    
EndFunction // EventHandlerInfo()

#EndRegion // ServiceIterface