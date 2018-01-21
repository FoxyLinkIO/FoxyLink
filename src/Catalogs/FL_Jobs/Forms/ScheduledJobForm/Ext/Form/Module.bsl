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

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
    
    If Parameters.Property("AutoTest") Then
        // Return if the form for analysis is received.
        Return;
    EndIf;
    
    ScheduledJob = FL_JobServer.ScheduledJob(Parameters.ID);
    Schedule = ScheduledJob.Schedule;
    FillPropertyValues(ThisObject, ScheduledJob, "Use, 
        |Description, 
        |Predefined, 
        |Key, 
        |UserName, 
        |RestartCountOnFailure, 
        |RestartIntervalOnFailure");
    
    ID = String(ScheduledJob.UUID);
    If ScheduledJob.Metadata = Undefined Then
        MetadataName        = NStr("en='<no metadata>';ru='<нет метаданных>'");
        MetadataSynonym     = NStr("en='<no metadata>';ru='<нет метаданных>'");
        MetadataMethodName  = NStr("en='<no metadata>';ru='<нет метаданных>'");
    Else
        MetadataName = ScheduledJob.Metadata.Name;
        MetadataComment = ScheduledJob.Metadata.Comment;
        MetadataSynonym = ScheduledJob.Metadata.Synonym;
        MetadataMethodName = ScheduledJob.Metadata.MethodName;
    EndIf;
    
    For Each User In InfobaseUsers.GetUsers() Do
        Items.UserName.ChoiceList.Add(User.Name);
    EndDo;

EndProcedure // OnCreateAtServer()

&AtClient
Procedure OnOpen(Cancel)
    
    RefreshFormTitle();
    
EndProcedure // OnOpen()

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
    
    NotifyDescription = New NotifyDescription("SaveScheduledJobAndClose", 
        ThisObject);
    FL_InteriorUseClient.ShowFormClosingConfirmation(NotifyDescription, 
        Cancel);
  
EndProcedure // BeforeClose()

#EndRegion // FormEventHandlers

#Region FormItemsEventHandlers

&AtClient
Procedure DescriptionOnChange(Item)
    
    RefreshFormTitle();
    
EndProcedure // DescriptionOnChange()

#EndRegion // FormItemsEventHandlers

#Region FormCommandHandlers

&AtClient
Procedure SaveAndClose(Command)
    
    SaveScheduledJobAndClose();   
    
EndProcedure // SaveAndClose()

&AtClient
Procedure Save(Command)
    
    SaveScheduledJob();  
    
EndProcedure // Save()

&AtClient
Procedure ConfigureSchedule(Command)
    
    ScheduledJobDialog = New ScheduledJobDialog(Schedule);
    ScheduledJobDialog.Show(New NotifyDescription(
        "DoAfterCloseScheduledJobDialog", ThisObject));

EndProcedure // ConfigureSchedule()

#EndRegion // FormCommandHandlers

#Region ServiceProceduresAndFunctions

// Rewrites the current schedule.
//
// Parameters:
//  NewSchedule          - Schedule  - the dialog is closed using the "OK" 
//                                      button, Undefined - otherwise. 
//  AdditionalParameters - Arbitrary - the value specified when the 
//                                      NotifyDescription object was created.
//
&AtClient
Procedure DoAfterCloseScheduledJobDialog(NewSchedule, 
    AdditionalParameters) Export

    If NewSchedule <> Undefined Then
        Schedule = NewSchedule;
        Modified = True;
    EndIf;

EndProcedure // DoAfterCloseScheduledJobDialog()

&AtClient
Procedure RefreshFormTitle()

    TitleTemplate = NStr("en = '%1 (Scheduled job)';
        |ru = '%1 (Регламентное задание)'");
    
    If NOT IsBlankString(Description) Then
        Title = StrTemplate(TitleTemplate, Description);
    ElsIf NOT IsBlankString(MetadataSynonym) Then
        Title = StrTemplate(MetadataSynonym);
    Else
        Title = StrTemplate(MetadataName);
    EndIf;

EndProcedure // RefreshFormTitle()

// Saves the scheduled job and closes this form.
//
// Parameters:
//  Result               - Arbitrary - see procedure FL_InteriorUseClient.DoAfterConfirmFormClosing. 
//  AdditionalParameters - Arbitrary - the value specified when the 
//                                      NotifyDescription object was created.
//
&AtClient
Procedure SaveScheduledJobAndClose(Result = Undefined, 
    AdditionalParameters = Undefined) Export

    SaveScheduledJob();
    Modified = False;
    Close();

EndProcedure // SaveScheduledJobAndClose()

&AtClient
Procedure SaveScheduledJob()

    If NOT ValueIsFilled(MetadataName) Then
        Return;
    EndIf;

    SaveScheduledJobAtServer();
    RefreshFormTitle();

EndProcedure // SaveScheduledJob()

&AtServer
Procedure SaveScheduledJobAtServer()

    ScheduledJob = FL_JobServer.ScheduledJob(ID);
    FillPropertyValues(ScheduledJob, ThisObject, "Description,
        |Use,
        |UserName,
        |RestartIntervalOnFailure,
        |RestartCountOnFailure");
    ScheduledJob.Schedule = Schedule;
    ScheduledJob.Write();

    Modified = False;

EndProcedure // SaveScheduledJobAtServer()

#EndRegion // ServiceProceduresAndFunctions

