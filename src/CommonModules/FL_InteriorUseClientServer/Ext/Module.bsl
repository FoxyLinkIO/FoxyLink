////////////////////////////////////////////////////////////////////////////////
// This file is part of FoxyLink.
// Copyright © 2016-2019 Petro Bazeliuk.
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

// Returns a new file properties structure.
//
// Parameters:
//  FileName - String - full name of the file or directory which is linked to the object to be created.
//                  Default value: Undefined.
//
// Returns:
//  Structure - with keys:
//      * Name                - String  - the name of the file.
//      * BaseName            - String  - the name of the file (without extension).
//      * FullName            - String  - the full name of the file (including the file path).
//      * Extension           - String  - the file name extension. 
//      * Path                - String  - the path to the file.
//      * Size                - Number  - the file size (in bytes).
//      * IsFile              - Boolean - defines whether a file object corresponds to a file or a directory.
//      * StorageAddress      - String  - address in the temporary storage. 
//      * ModificationTime    - Date    - local last modification time of the file. 
//      * ModificationTimeUTC - Date    - last file modification universal time. 
//      * ReadOnly            - Boolean - indicates that the "Read only" attribute is set for the file.
//      * Hidden              - Boolean - indicates that the "Hidden" attribute is set for the file.
//
Function NewFileProperties(FileName = Undefined) Export
    
    FileProperties = New Structure;
    FileProperties.Insert("Name");      // "FileName.json"
    FileProperties.Insert("BaseName");  // "FileName"
    FileProperties.Insert("FullName");  // "C:\FileName.json"
    FileProperties.Insert("Extension"); // ".json"
    FileProperties.Insert("Path");      // "C:\"
    FileProperties.Insert("Size");      
    FileProperties.Insert("IsFile");
    FileProperties.Insert("StorageAddress");
    FileProperties.Insert("ModificationTime");
    FileProperties.Insert("ModificationTimeUTC");
    FileProperties.Insert("ReadOnly");
    FileProperties.Insert("Hidden");
    
    If FileName <> Undefined Then
        
        File = New File(FileName);
        FileProperties.Name                = File.Name;    
        FileProperties.BaseName            = File.BaseName; 
        FileProperties.FullName            = File.FullName; 
        FileProperties.Extension           = File.Extension; 
        FileProperties.Path                = File.Path;      
        FileProperties.Size                = File.Size();      
        FileProperties.IsFile              = File.IsFile();
        FileProperties.ModificationTime    = File.GetModificationTime();
        FileProperties.ModificationTimeUTC = File.GetModificationUniversalTime();
        FileProperties.ReadOnly            = File.GetReadOnly();
        FileProperties.Hidden              = File.GetHidden();
        
    EndIf;
    
    Return FileProperties;
    
EndFunction // NewFileProperties()

// Checks if this version is newer than the current one.
// 
// Parameters:
//  VersionToCheck - String - version to check. 
//  CurrentVersion - String - current version.
//
// Returns:
//   Boolean - True if it is newer version; otherwise - False.
//
Function IsNewerVersion(Val NewerVersion, Val CurrentVersion) Export

    For Index = 0 To StrOccurrenceCount(NewerVersion, ".") Do
        
        NewerPtPosition = StrFind(NewerVersion, ".");
        CurrentPtPosition = StrFind(CurrentVersion, ".");
                
        Try
            If NewerPtPosition <> 0 AND CurrentPtPosition <> 0 Then
                NewerNumber = Number(Left(NewerVersion, NewerPtPosition - 1));
                CurrentNumber =  Number(Left(CurrentVersion, CurrentPtPosition - 1));
            Else
                NewerNumber = Number(NewerVersion);
                CurrentNumber =  Number(CurrentVersion);
            EndIf;
        Except
            Return False;
        EndTry;
        
        If NewerNumber > CurrentNumber Then
            Return True;
        ElsIf NewerNumber < CurrentNumber Then
            Return False;
        EndIf;
                      
        NewerVersion = Mid(NewerVersion, NewerPtPosition + 1);
        CurrentVersion = Mid(CurrentVersion, CurrentPtPosition + 1); 
        
    EndDo;

    Return False;

EndFunction // IsNewerVersion()

#EndRegion // ProgramInterface
