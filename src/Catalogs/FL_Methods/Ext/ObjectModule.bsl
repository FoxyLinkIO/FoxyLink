////////////////////////////////////////////////////////////////////////////////
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
//
////////////////////////////////////////////////////////////////////////////////

#Region ServiceInterface

Procedure BeforeWrite(Cancel)
    
    If DataExchange.Load Then
        Return;
    EndIf;
    
    For Index = 1 To StrLen(Description) Do
        Symbol = Mid(Description, Index, 1);
        If Not FL_CommonUseClientServer.IsLatinLetter(Symbol) Then
            FL_CommonUseClientServer.NotifyUser(
                NStr("en = 'Method name contains illegal characters, Latin letters are allowed only.';
                    |ru = 'Имя метода содержит запрещенные символы, разрешены только латинские буквы.'"),
                ,
                "Object.Description",
                ,
                Cancel);
        EndIf;
    EndDo;   
    
EndProcedure // BeforeWrite()

#EndRegion // ServiceInterface
