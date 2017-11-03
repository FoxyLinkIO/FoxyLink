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

#Region ProgramInterface

// Returns an fixed array of splitters that exist in the configuration.
//
// Returns: 
//  FixedArray(String) - an array of common attribute names, that are used as splitters.
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

#EndRegion // ProgramInterface 