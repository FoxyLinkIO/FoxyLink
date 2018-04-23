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
    
    URLParameters = Request.URLParameters;
    ExchangeName = URLParameters.Get("Exchange");
    OperationName = URLParameters.Get("Operation");
    Sync = Upper(URLParameters.Get("Type")) = "SYNC";
    
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
    
    Invocation = Catalogs.FL_Messages.NewInvocation();
    Invocation.AppId = URLParameters.Get("AppId"); 
    Invocation.ContentEncoding = "TODO:";
    Invocation.ContentType = "TODO:";
    Invocation.CorrelationId = URLParameters.Get("CorrelationId");
    Invocation.EventSource = URLParameters.Get("EventSource");
    Invocation.Operation = Operation;
    Invocation.ReplyTo = URLParameters.Get("ReplyTo");
    
    Timestamp = URLParameters.Get("Timestamp");
    If ValueIsFilled(Timestamp) Then
        Invocation.Timestamp = Timestamp;
    EndIf;
    
    UserId = URLParameters.Get("UserId");
    If ValueIsFilled(UserId) Then 
        Invocation.UserId = UserId;
    EndIf;
        
    Response = New HTTPServiceResponse(FL_InteriorUseReUse.OkStatusCode());
    Return Response;
    
EndFunction // MessageHandler()

#EndRegion // ProgramInterface
