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

// Evaluates expression with pre-establishing a safe mode of code execution and
// safe mode for all splitters that exist in the configuration. 
// As a result, when expression is been evaluated: 
//  - attempts to set up privileged mode are ignored;
//  - all external (in relation to platform 1C:Enterprise) actions (COM,
//      external components import, launch of external applications and operating system
//      commands, access to the file system and Internet resources) are prohibited;
//  - it is prohibited to set off the usage of session splitters;
//  - it is prohibited to change values of session splitters (if separation with this 
//      splitter isn't disabled conditionally);
//  - it is prohibited to change objects that control the state of conditional separation.
//
// Parameters:
//  Expression - String    - expression to be evaluated.
//  Parameters - Arbitrary - through this parameter it is possible to transfer the value 
//                              that is required to evaluate expression.
//
// Returns: 
//  Arbitrary - evaluation result.
//
Function EvalInSafeMode(Val Expression, Val Parameters = Undefined) Export

    SetSafeMode(True);

    SplittersArray = FL_CommonUseReUse.ConfigurationSplitters();
    For Each SplitterName In SplittersArray Do
        SetDataSeparationSafeMode(SplitterName, True); 
    EndDo;

    Return Eval(Expression);

EndFunction // EvalInSafeMode()

// Executes an algorithm with pre-establishing a safe mode of code execution and
// safe mode for all splitters that exist in the configuration.
// As a result, when algorithm is been executed: 
//  - attempts to set up privileged mode are ignored;
//  - all external (in relation to platform 1C:Enterprise) actions (COM,
//      external components import, launch of external applications and operating system
//      commands, access to the file system and Internet resources) are prohibited;
//  - it is prohibited to set off the usage of session splitters;
//  - it is prohibited to change values of session splitters (if separation with this 
//      splitter isn't disabled conditionally);
//  - it is prohibited to change objects that control the state of conditional separation.
//
// Parameters:
//  Algorithm  - String    - the arbitrary algorithm that is written with
//                              1C:Enterprise embedded language.
//  Parameters - Arbitrary - through this parameter it is possible to transfer the value 
//                              that is required to execute the algorithm.
//
Procedure ExecuteInSafeMode(Val Algorithm, Val Parameters = Undefined) Export

    SetSafeMode(True);

    SplittersArray = FL_CommonUseReUse.ConfigurationSplitters();
    For Each SplitterName In SplittersArray Do
        SetDataSeparationSafeMode(SplitterName, True); 
    EndDo;

    Execute Algorithm;

EndProcedure // ExecuteInSafeMode()

#EndRegion // ProgramInterface 