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

// Returns a new file properties structure.
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
Function NewFileProperties() Export
    
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
    Return FileProperties;
    
EndFunction // NewFileProperties()

#EndRegion // ProgramInterface
