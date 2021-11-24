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

Function MessageHandler(Request)
    
    Var Exchange, Operation, Async, Exec;
    
    ProcessURLParameters(Request.URLParameters, Exchange, Operation, Async, Exec);
    
    Headers = FL_InteriorUse.HeadersFromRequestResponse(Request);
    Invocation = Catalogs.FL_Messages.NewInvocation();
    
    Catalogs.FL_Messages.FillContentTypeFromHeaders(Invocation, Headers);
    
    // Helps to resolve problem with english and russian configurations. 
    Invocation.EventSource = Metadata.HTTPServices.FL_AppEndpoint.Fullname();
    
    Invocation.Operation = Operation;
    Invocation.Payload = Request.GetBodyAsBinaryData(); 
    Invocation.ReplyTo = Headers.Get("REPLYTO");
    Invocation.CorrelationId = Headers.Get("CORRELATIONID");
    
    Timestamp = Headers.Get("TIMESTAMP");
    If ValueIsFilled(Timestamp) Then
        Invocation.Timestamp = Timestamp;
    EndIf;
    
    UserId = Headers.Get("USERID");
    If ValueIsFilled(UserId) Then 
        Invocation.UserId = UserId;
    EndIf;
    
    AppEndpoint = Undefined;
    If ValueIsFilled(Invocation.ReplyTo) Then
        AppEndpoint = FL_CommonUse.ReferenceByDescription(
            Metadata.Catalogs.FL_Channels, Headers.Get("APPID"));
    EndIf;
    
    // Avoid using hierarchical transactions. 
    Invocation.Routed = True;
    Message = Catalogs.FL_Messages.Create(Invocation);
    
    If Async Then
        Catalogs.FL_Messages.Route(Message, Exchange, AppEndpoint, True);
    ElsIf Exec Then
        
        JobResult = Catalogs.FL_Messages.RouteAndRunOutputResult(
            Message, Exchange, AppEndpoint);
            
        OutInvocation = Catalogs.FL_Jobs.GetFromJobResult(
            JobResult, "Invocation");
        
    Else 
        Catalogs.FL_Messages.RouteAndRun(Message, Exchange, AppEndpoint);
    EndIf;
    
    Response = New HTTPServiceResponse(FL_InteriorUseReUse.OkStatusCode());
    
    If Exec Then
        Response.SetBodyFromBinaryData(OutInvocation.Payload);
    EndIf;
    
    Return Response;
    
EndFunction // MessageHandler()

#EndRegion // ProgramInterface

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
Procedure ProcessURLParameters(URLParameters, Exchange, Operation, Async, Exec)
    
    ExchangeName = URLParameters.Get("Exchange");
    Exchange = FL_CommonUse.ReferenceByDescription(
        Metadata.Catalogs.FL_Exchanges, ExchangeName);
    If Exchange = Undefined Then
        
        ErrorMessage = StrTemplate(NStr("
                |en='Error: Exchange settings {%1} not found.'; 
                |ru='Ошибка: Настройки обмена {%1} не найдены.'; 
                |uk='Помилка: Налаштування обміну {%1} не знайдено.';
                |en_CA='Error: Exchange settings {%1} not found.'"),
            ExchangeName);   
        Raise ErrorMessage;
         
    EndIf;
    
    OperationName = URLParameters.Get("Operation");
    Operation = FL_CommonUse.ReferenceByDescription(
        Metadata.Catalogs.FL_Operations, OperationName);
    If Operation = Undefined Then
        
        ErrorMessage = StrTemplate(NStr("
                |en='Error: Operation {%1} not found.'; 
                |ru='Ошибка: Операция {%1} не найдена.'; 
                |uk='Помилка: Операція {%1} не знайдена.';
                |en_CA='Error: Operation {%1} not found.'"),
            OperationName);   
        Raise ErrorMessage;
         
    EndIf;
   
    Async = Upper(URLParameters.Get("Type")) = "ASYNC";
    Exec = Upper(URLParameters.Get("Type")) = "EXEC";
    
EndProcedure // ProcessURLParameters()

#EndRegion // ServiceProceduresAndFunctions