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

#Region ProgramInterface

// Creates an instance copy of the specified object.
//
// Parameters:
//  Source - Arbitrary - object that is required to be copied.
//
// Returns:
//  Arbitrary - copy of the source object.
//
// Note:
//  Function can not be used for object types (CatalogObject, DocumentObject etc.).
//
Function CopyRecursive(Source) Export
    
    Var Receiver;
    
    SourceType = TypeOf(Source);
    If SourceType = Type("Structure") Then
        Receiver = CopyStructure(Source);
    ElsIf SourceType = Type("Map") Then
        Receiver = CopyMap(Source);
    ElsIf SourceType = Type("Array") Then
        Receiver = CopyArray(Source);
    ElsIf SourceType = Type("ValueList") Then
        Receiver = CopyValueList(Source);
    #If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
    ElsIf SourceType = Type("ValueTable") Then
        Receiver = Source.Copy();
    #EndIf
    Else
        Receiver = Source;
    EndIf;
    
    Return Receiver;
    
EndFunction // CopyRecursive()

// Creates copy of the Structure value type.
// 
// Parameters:
//  SourceStructure - Structure - copied structure.
// 
// Returns:
//  Structure - copy of the source structure.
//
Function CopyStructure(SourceStructure) Export
    
    ResultStructure = New Structure;
    
    For Each KeyAndValue In SourceStructure Do
        ResultStructure.Insert(KeyAndValue.Key, CopyRecursive(KeyAndValue.Value));
    EndDo;
    
    Return ResultStructure;
    
EndFunction // CopyStructure()

// Creates value copy of the Match type.
// 
// Parameters:
//  SourceMap - Map - copied map.
// 
// Returns:
//  Map - copy of the source match.
//
Function CopyMap(SourceMap) Export
    
    ResultMap = New Map;
    
    For Each KeyAndValue IN SourceMap Do
        ResultMap.Insert(KeyAndValue.Key, CopyRecursive(KeyAndValue.Value));
    EndDo;
    
    Return ResultMap;
    
EndFunction // CopyMap() 

// Creates the value copy of the Array type.
// 
// Parameters:
//  ArraySource - Array - copied array.
// 
// Returns:
//  Array - copy of the source array.
//
Function CopyArray(ArraySource) Export
    
    ResultArray = New Array;
    
    For Each Item IN ArraySource Do
        ResultArray.Add(CopyRecursive(Item));
    EndDo;
    
    Return ResultArray;
    
EndFunction // CopyArray()

// Create the value copy of the ValuesList type.
// 
// Parameters:
//  SourceList - ValueList - copied values list.
// 
// Returns:
//  ValueList - copy of the source values list.
//
Function CopyValueList(SourceList) Export
    
    ResultList = New ValueList;
    
    For Each ItemOfList IN SourceList Do
        ResultList.Add(CopyRecursive(ItemOfList.Value), 
            ItemOfList.Presentation, 
            ItemOfList.Check, 
            ItemOfList.Picture);
    EndDo;
    
    Return ResultList;
    
EndFunction // CopyValueList() 


#Region StringOperations

Function IsCorrectVariableName(VariableName) Export
    
    If (IsBlankString(VariableName)) Then
        Return False;    
    EndIf;
        
    For Position = 1 To StrLen(VariableName) Do 
        
        Character = Mid(VariableName, Position, 1);
        If Character = "_" Then
            Continue;    
        EndIf;
        
        If Position = 1 И IsNumber(Character) Then
            Return False;    
        EndIf;
        
        If IsSpecialSymbol(Character) Then
            Return False;    
        EndIf;
                
    EndDo;
    
    Return True;    
    
EndFunction // IsCorrectVariableName()

// Check if a character is a special symbol.
//
// Parameters:
//  Character - String - character to be checked.
//
// Returns:
//  Boolean - True if a character is a special symbol; False in other case.
//
Function IsSpecialSymbol(Character) Export
    
    Return ?(IsNumber(Character) 
          Or IsLetter(Character), False, True);
    
EndFunction // IsSpecialSymbol()

// Check if a character is a number.
//
// Parameters:
//  Character - String - character to be checked.
//
// Returns:
//  Boolean - True if a character is a number; False in other case.
//
Function IsNumber(Character) Export
    
    Code = CharCode(Character);
    Return ?(Code <= 47 Or Code >= 58, False, True);
    
EndFunction // IsNumber()

// Check if a character is a letter.
//
// Parameters:
//  Character - String - character to be checked.
//
// Returns:
//  Boolean - True if a character is a letter; False in other case.
//
Function IsLetter(Character) Export
    
    Return ?(IsLatinLetter(Character) 
          Or IsCyrillicLetter(Character), True, False);
    
EndFunction // IsLetter()

// Check if a character is a latin letter.
//
// Parameters:
//  Character - String - character to be checked.
//
// Returns:
//  Boolean - True if a character is a latin letter; False in other case.
//
Function IsLatinLetter(Character) Export
    
    Code = CharCode(Character);
    Return ?((Code > 64 And Code < 91) 
          Or (Code > 96 And Code < 123), True, False);
    
EndFunction // IsLatinLetter() 

// Check if a character is a cyrillic letter.
//
// Parameters:
//  Character - String - character to be checked.
//
// Returns:
//  Boolean - True if a character is a cyrillic letter; False in other case.
//
Function IsCyrillicLetter(Character) Export
    
    Code = CharCode(Character);
    Return ?(Code > 1039 And Code < 1104, True, False);
    
EndFunction // IsCyrillicLetter()

#EndRegion // StringOperations

#EndRegion // ProgramInterface