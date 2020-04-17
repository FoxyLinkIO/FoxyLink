////////////////////////////////////////////////////////////////////////////////
// This file is part of FoxyLink.
// Copyright © 2016-2020 Petro Bazeliuk.
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

#Region FormCommandHandlers

&AtClient
Procedure ConnectToSwagger(Command)
    
    If IsBlankString(ConnectionPath) Then
        
        FL_CommonUseClientServer.NotifyUser(NStr("
                |en='Fill the connection path.';
                |ru='Заполните путь для подключения.';
                |uk='Заповніть шлях для підключення.';
                |en_CA='Fill the connection path.'"),
            ,
            "ConnectionPath");
        Return;
        
    EndIf;
    
    ConnectToSwaggerAtServer();
         
EndProcedure // ConnectToSwagger() 

#EndRegion // FormCommandHandlers 

#Region ServiceProceduresAndFunctions

&AtServer
Procedure ConnectToSwaggerAtServer()

    URIStructure = FL_CommonUseClientServer.URIStructure(ConnectionPath);
    URIStructure.Login = Login;
    URIStructure.Password = Password;
    
    StringURI = FL_CommonUseClientServer.StringURI(URIStructure);
    
    // Getting HTTP request.
    HTTPRequest = FL_InteriorUse.NewHTTPRequest(URIStructure.PathOnServer);
        
    // Getting HTTP connection.
    HTTPConnection = FL_InteriorUse.NewHTTPConnection(StringURI);
    
    JobResult = Catalogs.FL_Jobs.NewJobResult(True);
    FL_InteriorUse.CallHTTPMethod(HTTPConnection, HTTPRequest, "GET", 
        JobResult);
        
    If JobResult.Success Then
        
        Invocation = Catalogs.FL_Jobs.GetFromJobResult(JobResult, "Invocation");
        DataObject = Catalogs.FL_Messages.ReadInvocationPayload(Invocation);
        
        
    Else
        LogAttribute = JobResult.LogAttribute;
    EndIf;
    
EndProcedure // ConnectToSwaggerAtServer()

#EndRegion // ServiceProceduresAndFunctions