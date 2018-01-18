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

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
    
    If Parameters.Property("AutoTest") Then
        // Return if the form for analysis is received.
        Return;
    EndIf;
    
    If Parameters.Property("ResponseHandler") Then
        FormattedDocument.SetFormattedString(New FormattedString(
            Parameters.ResponseHandler));   
    EndIf;
    
    FormattedTextParameters = NewFormattedTextParameters(
        Items.FormattedDocument.Font);    
    
EndProcedure // OnCreateAtServer()

#EndRegion // FormEventHandlers

#Region FormCommandHandlers

&AtClient
Procedure SaveAndClose(Command)
    
    Close(FormattedDocument.GetText());
    
EndProcedure // SaveAndClose()

#EndRegion // FormCommandHandlers

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
&AtServerNoContext
Function NewFormattedTextParameters(Font)
    
    FormattedTextParameters = New Structure;
    
    // Colors
    FormattedTextParameters.Insert("Colors", New Structure);
    FormattedTextParameters.Colors.Insert("Red",   New Color(255, 0, 0));
    FormattedTextParameters.Colors.Insert("Green", New Color(0, 128, 0));
    FormattedTextParameters.Colors.Insert("Blue",  New Color(0, 0, 255));
    FormattedTextParameters.Colors.Insert("Black", New Color(0, 0, 1));
    FormattedTextParameters.Colors.Insert("Brown", New Color(150, 50, 0));

    // Fonts
    FormattedTextParameters.Insert("Fonts", New Structure);
    FormattedTextParameters.Fonts.Insert("ErrorFont", New Font(Font, , , True));

    // Key words array
    FormattedTextParameters.Insert("KeyWords", New Array);
    FormattedTextParameters.KeyWords.Add("if");
    FormattedTextParameters.KeyWords.Add("если");
    FormattedTextParameters.KeyWords.Add("then");
    FormattedTextParameters.KeyWords.Add("тогда");
    FormattedTextParameters.KeyWords.Add("elsif");
    FormattedTextParameters.KeyWords.Add("иначеесли");
    FormattedTextParameters.KeyWords.Add("else");
    FormattedTextParameters.KeyWords.Add("иначе");
    FormattedTextParameters.KeyWords.Add("endif");
    FormattedTextParameters.KeyWords.Add("конецесли");
    FormattedTextParameters.KeyWords.Add("do");
    FormattedTextParameters.KeyWords.Add("цикл");
    FormattedTextParameters.KeyWords.Add("for");
    FormattedTextParameters.KeyWords.Add("для");
    FormattedTextParameters.KeyWords.Add("to");
    FormattedTextParameters.KeyWords.Add("по");
    FormattedTextParameters.KeyWords.Add("each");
    FormattedTextParameters.KeyWords.Add("каждого");
    FormattedTextParameters.KeyWords.Add("in");
    FormattedTextParameters.KeyWords.Add("из");
    FormattedTextParameters.KeyWords.Add("while");
    FormattedTextParameters.KeyWords.Add("пока");
    FormattedTextParameters.KeyWords.Add("endDo");
    FormattedTextParameters.KeyWords.Add("конеццикла");
    FormattedTextParameters.KeyWords.Add("procedure");
    FormattedTextParameters.KeyWords.Add("процедура");
    FormattedTextParameters.KeyWords.Add("endprocedure");
    FormattedTextParameters.KeyWords.Add("конецпроцедуры");
    FormattedTextParameters.KeyWords.Add("function");
    FormattedTextParameters.KeyWords.Add("функция");
    FormattedTextParameters.KeyWords.Add("endfunction");
    FormattedTextParameters.KeyWords.Add("конецфункции");
    FormattedTextParameters.KeyWords.Add("var");
    FormattedTextParameters.KeyWords.Add("перем");
    FormattedTextParameters.KeyWords.Add("export");
    FormattedTextParameters.KeyWords.Add("экспорт");
    FormattedTextParameters.KeyWords.Add("goto");
    FormattedTextParameters.KeyWords.Add("перейти");
    FormattedTextParameters.KeyWords.Add("and");
    FormattedTextParameters.KeyWords.Add("и");
    FormattedTextParameters.KeyWords.Add("or");
    FormattedTextParameters.KeyWords.Add("или");
    FormattedTextParameters.KeyWords.Add("not");
    FormattedTextParameters.KeyWords.Add("не");
    FormattedTextParameters.KeyWords.Add("val");
    FormattedTextParameters.KeyWords.Add("знач");
    FormattedTextParameters.KeyWords.Add("break");
    FormattedTextParameters.KeyWords.Add("прервать");
    FormattedTextParameters.KeyWords.Add("continue");
    FormattedTextParameters.KeyWords.Add("продолжить");
    FormattedTextParameters.KeyWords.Add("return");
    FormattedTextParameters.KeyWords.Add("возврат");
    FormattedTextParameters.KeyWords.Add("try");
    FormattedTextParameters.KeyWords.Add("попытка");
    FormattedTextParameters.KeyWords.Add("except");
    FormattedTextParameters.KeyWords.Add("исключение");
    FormattedTextParameters.KeyWords.Add("endtry");
    FormattedTextParameters.KeyWords.Add("конецпопытки");
    FormattedTextParameters.KeyWords.Add("raise");
    FormattedTextParameters.KeyWords.Add("вызватьисключение");
    FormattedTextParameters.KeyWords.Add("false");
    FormattedTextParameters.KeyWords.Add("ложь");
    FormattedTextParameters.KeyWords.Add("true");
    FormattedTextParameters.KeyWords.Add("истина");
    FormattedTextParameters.KeyWords.Add("undefined");
    FormattedTextParameters.KeyWords.Add("неопределено");
    FormattedTextParameters.KeyWords.Add("null");
    FormattedTextParameters.KeyWords.Add("new");
    FormattedTextParameters.KeyWords.Add("новый");
    FormattedTextParameters.KeyWords.Add("execute");
    FormattedTextParameters.KeyWords.Add("выполнить");
                                     
    FormattedTextParameters.Insert("SelectionBeginning", Undefined);
    FormattedTextParameters.Insert("SelectionEnding", Undefined);
    Return FormattedTextParameters;
     
EndFunction // NewFormattedTextParameters() 

#EndRegion // ServiceProceduresAndFunctions