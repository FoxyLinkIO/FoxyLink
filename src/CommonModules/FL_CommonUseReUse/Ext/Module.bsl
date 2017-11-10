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

#Region ProgramInterface

// Returns fixed array of splitters that exist in the configuration.
//
// Returns: 
//  FixedArray(String) - fixed array of common attribute names, that are used as splitters.
//
Function ConfigurationSplitters() Export

    SplittersArray = New Array;

    For Each CommonAttribute In Metadata.CommonAttributes Do
        If CommonAttribute.DataSeparation = Metadata.ObjectProperties.CommonAttributeDataSeparation.Separate Then
            SplittersArray.Add(CommonAttribute.Name);
        EndIf;
    EndDo;

    Return New FixedArray(SplittersArray);

EndFunction // ConfigurationSplitters()

// Returns fixed map with standard attribute synonym names.
//
// Returns:
//  FixedMap - with standard attribute synonym names.
//
Function StandardAttributeSynonyms() Export
    
    Synonyms = New Map;
    
    // Catalog
    Synonyms.Insert("REF", "ССЫЛКА");
    Synonyms.Insert("CODE", "КОД");
    Synonyms.Insert("DESCRIPTION", "НАИМЕНОВАНИЕ");
    Synonyms.Insert("OWNER", "ВЛАДЕЛЕЦ");
    Synonyms.Insert("PARENT", "РОДИТЕЛЬ");
    Synonyms.Insert("ISFOLDER", "ЭТОГРУППА");
    Synonyms.Insert("DELETIONMARK", "ПОМЕТКАУДАЛЕНИЯ");
    Synonyms.Insert("PREDEFINED", "ПРЕДОПРЕДЕЛЕННЫЙ");
    Synonyms.Insert("PREDEFINEDDATANAME", "ИМЯПРЕДОПРЕДЕЛЕННЫХДАННЫХ");
    
    // Document
    Synonyms.Insert("NUMBER", "НОМЕР");
    Synonyms.Insert("DATE", "ДАТА");
    Synonyms.Insert("POSTED", "ПРОВЕДЕН");
    
    // Document journals
    Synonyms.Insert("TYPE", "ТИП"); 
    
    // Enumerations
    Synonyms.Insert("ORDER", "ПОРЯДОК");
    
    // Charts of characteristic types
    Synonyms.Insert("VALUETYPE", "ТИПЗНАЧЕНИЯ");
    
    // Charts of accounts
    Synonyms.Insert("OFFBALANCE", "ЗАБАЛАНСОВЫЙ");

    // Charts of calculation types
    Synonyms.Insert("ACTIONPERIODISBASIC", "ПЕРИОДДЕЙСТВИЯБАЗОВЫЙ");
    
    // Information registers
    Synonyms.Insert("PERIOD", "ПЕРИОД");
    Synonyms.Insert("RECORDER", "РЕГИСТРАТОР");
    Synonyms.Insert("LINENUMBER", "НОМЕРСТРОКИ");
    Synonyms.Insert("ACTIVE", "АКТИВНОСТЬ");
    
    // Accumulation registers
    Synonyms.Insert("RECORDTYPE", "ВИДДВИЖЕНИЯ");
    
    // Accounting registers
    Synonyms.Insert("ACCOUNT", "СЧЕТ");

    // Calculation registers
    Synonyms.Insert("REGISTRATIONPERIOD", "ПЕРИОДРЕГИСТРАЦИИ");
    Synonyms.Insert("CALCULATIONTYPE", "ВИДРАСЧЕТА");
    Synonyms.Insert("ACTIONPERIOD", "ПЕРИОДДЕЙСТВИЯ");
    Synonyms.Insert("BEGOFACTIONPERIOD", "ПЕРИОДДЕЙСТВИЯНАЧАЛО");
    Synonyms.Insert("ENDOFACTIONPERIOD", "ПЕРИОДДЕЙСТВИЯКОНЕЦ");
    Synonyms.Insert("BEGOFBASEPERIOD", "БАЗОВЫЙПЕРИОДНАЧАЛО");
    Synonyms.Insert("ENDOFBASEPERIOD", "БАЗОВЫЙПЕРИОДКОНЕЦ");
    Synonyms.Insert("REVERSINGENTRY", "СТОРНО");
    
    // Business processes
    Synonyms.Insert("HEADTASK", "ВЕДУЩАЯЗАДАЧА");
    Synonyms.Insert("STARTED", "СТАРТОВАН");
    Synonyms.Insert("COMPLETED", "ЗАВЕРШЕН");
    
    // Tasks
    Synonyms.Insert("BUSINESSPROCESS", "БИЗНЕСПРОЦЕСС");
    Synonyms.Insert("ROUTEPOINT", "ТОЧКАМАРШРУТА");
    Synonyms.Insert("EXECUTED", "ВЫПОЛНЕНА");
    
    // Catalog
    Synonyms.Insert("ССЫЛКА", "REF");
    Synonyms.Insert("КОД", "CODE");
    Synonyms.Insert("НАИМЕНОВАНИЕ", "DESCRIPTION");
    Synonyms.Insert("ВЛАДЕЛЕЦ", "OWNER");
    Synonyms.Insert("РОДИТЕЛЬ", "PARENT");
    Synonyms.Insert("ЭТОГРУППА", "ISFOLDER");
    Synonyms.Insert("ПОМЕТКАУДАЛЕНИЯ", "DELETIONMARK");
    Synonyms.Insert("ПРЕДОПРЕДЕЛЕННЫЙ", "PREDEFINED");
    Synonyms.Insert("ИМЯПРЕДОПРЕДЕЛЕННЫХДАННЫХ", "PREDEFINEDDATANAME");
    
    // Document
    Synonyms.Insert("НОМЕР", "NUMBER");
    Synonyms.Insert("ДАТА", "DATE");
    Synonyms.Insert("ПРОВЕДЕН", "POSTED");
    
    // Document journals
    Synonyms.Insert("ТИП", "TYPE");
    
    // Enumerations
    Synonyms.Insert("ПОРЯДОК", "ORDER");

    // Charts of characteristic types
    Synonyms.Insert("ТИПЗНАЧЕНИЯ", "VALUETYPE");
    
    // Charts of accounts
    Synonyms.Insert("ЗАБАЛАНСОВЫЙ", "OFFBALANCE");
    
    // Charts of calculation types
    Synonyms.Insert("ПЕРИОДДЕЙСТВИЯБАЗОВЫЙ", "ACTIONPERIODISBASIC");
    
    // Information registers
    Synonyms.Insert("ПЕРИОД", "PERIOD");
    Synonyms.Insert("РЕГИСТРАТОР", "RECORDER");
    Synonyms.Insert("НОМЕРСТРОКИ", "LINENUMBER");
    Synonyms.Insert("АКТИВНОСТЬ", "ACTIVE");
    
    // Accumulation registers
    Synonyms.Insert("ВИДДВИЖЕНИЯ", "RECORDTYPE"); 
    
    // Accounting registers
    Synonyms.Insert("СЧЕТ", "ACCOUNT");
    
    // Calculation registers
    Synonyms.Insert("ПЕРИОДРЕГИСТРАЦИИ", "REGISTRATIONPERIOD");
    Synonyms.Insert("ВИДРАСЧЕТА", "CALCULATIONTYPE");
    Synonyms.Insert("ПЕРИОДДЕЙСТВИЯ", "ACTIONPERIOD");
    Synonyms.Insert("ПЕРИОДДЕЙСТВИЯНАЧАЛО", "BEGOFACTIONPERIOD");
    Synonyms.Insert("ПЕРИОДДЕЙСТВИЯКОНЕЦ", "ENDOFACTIONPERIOD");
    Synonyms.Insert("БАЗОВЫЙПЕРИОДНАЧАЛО", "BEGOFBASEPERIOD");
    Synonyms.Insert("БАЗОВЫЙПЕРИОДКОНЕЦ", "ENDOFBASEPERIOD");
    Synonyms.Insert("СТОРНО", "REVERSINGENTRY");
    
    // Business processes
    Synonyms.Insert("ВЕДУЩАЯЗАДАЧА", "HEADTASK");
    Synonyms.Insert("СТАРТОВАН", "STARTED");
    Synonyms.Insert("ЗАВЕРШЕН", "COMPLETED");
    
    // Tasks
    Synonyms.Insert("БИЗНЕСПРОЦЕСС", "BUSINESSPROCESS");
    Synonyms.Insert("ТОЧКАМАРШРУТА", "ROUTEPOINT");
    Synonyms.Insert("ВЫПОЛНЕНА", "EXECUTED");

    Return New FixedMap(Synonyms);
    
EndFunction // StandardAttributeSynonyms()  

#EndRegion // ProgramInterface 