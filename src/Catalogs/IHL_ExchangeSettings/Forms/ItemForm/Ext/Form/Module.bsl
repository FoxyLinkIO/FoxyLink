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

&AtServer
Var BasicFormatObject;

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
    
    If IsBlankString(Object.BasicFormatGuid) Then
        For Each Format In Catalogs.IHL_ExchangeSettings.AvailableFormats() Do
            FillPropertyValues(Items.BasicFormatGuid.ChoiceList.Add(), Format);    
        EndDo;
        Items.HeaderPagesFormat.CurrentPage = Items.HeaderPageSelectFormat; 
    Else
        LoadBasicFormatData();    
    EndIf;
    
EndProcedure // OnCreateAtServer()

&AtClient
Procedure OnOpen(Cancel)
    
    
    
EndProcedure // OnOpen()

#EndRegion // FormEventHandlers

#Region FormItemsEventHandlers

&AtClient
Procedure BasicFormatGuidOnChange(Item)
    
    If Not IsBlankString(Object.BasicFormatGuid) Then
        LoadBasicFormatData();   
    EndIf;
    
EndProcedure // BasicFormatGuidOnChange()

&AtClient
Procedure FormatStandardClick(Item, StandardProcessing)
    
    StandardProcessing = False;
    RunApp(FormatStandardLink());
    
EndProcedure // FormatStandardClick()

#EndRegion // FormItemsEventHandlers

#Region FormCommandHandlers

#EndRegion // FormCommandHandlers

#Region ServiceProceduresAndFunctions

// Fills basic format info.
//
&AtServer
Procedure LoadBasicFormatData()

    Items.HeaderPagesFormat.CurrentPage = Items.HeaderPageBasicFormat;
    FormatProcessor = Catalogs.IHL_ExchangeSettings.NewFormatProcessor(
        FormatProcessorName, Object.BasicFormatGuid);
        
    FormatName = StrTemplate("%1 (%2)", FormatProcessor.FormatFullName(),
        FormatProcessor.FormatShortName());
        
    FormatStandard = FormatProcessor.FormatStandard();
        
    FormatPluginVersion = FormatProcessor.Version();

EndProcedure // LoadBasicFormatData() 



// Returns link to the formal document from the Internet Engineering Task Force 
// (IETF) that is the result of committee drafting and subsequent review 
// by interested parties.
//
&AtServer
Function FormatStandardLink() 
    
     FormatProcessor = Catalogs.IHL_ExchangeSettings.NewFormatProcessor(
        FormatProcessorName, Object.BasicFormatGuid);     
     Return FormatProcessor.FormatStandardLink();
    
EndFunction // FormatStandardLink()

//&AtClient
//Procedure DoAfterChooseAvailableFormat(SelectedElement, 
//    AdditionalParameters) Export
//    
//    If SelectedElement = Undefined Then 
//        Close();    
//    EndIf;
//    
//EndProcedure // DoAfterChooseAvailableFormat() 

#EndRegion // ServiceProceduresAndFunctions



