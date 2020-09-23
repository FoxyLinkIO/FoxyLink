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

#Region Variables

&AtClient
Var ContextPollOptions;

&AtClient
Var RoutesPollOptions;

#EndRegion // Variables

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
    
    MessageId = XMLString(Object.Ref);    
    
EndProcedure // OnCreateAtServer() 

&AtClient
Procedure OnOpen(Cancel)
    
    LoadContextData();
    TimestampToDate();
    
EndProcedure // OnOpen()

#EndRegion // FormEventHandlers

#Region FormItemsEventHandlers

&AtClient
Procedure ContextSelection(Item, SelectedRow, Field, StandardProcessing)
    
    CurrentData = Item.CurrentData;
    If CurrentData = Undefined Then
        Return;
    EndIf;
    
    If Field.Name = "ContextValue" Then
        ShowValue(, CurrentData.Value);     
    EndIf;
    
EndProcedure // ContextSelection()

&AtClient
Procedure PropTimestampOnChange(Item)
    
    TimestampToDate();
    
EndProcedure // PropTimestampOnChange()

#EndRegion // FormItemsEventHandlers

#Region FormCommandHandlers

&AtClient
Procedure CancelLoadingContext(Command)

    If TypeOf(ContextTaskResult) = Type("Structure") 
        AND ContextTaskResult.Property("TaskId") Then 
        StopBackgroundJob(ContextTaskResult.TaskId);
        AfterContextTaskComplete();
    EndIf;
    
EndProcedure // CancelLoadingContext()

#EndRegion // FormCommandHandlers

#Region ServiceProceduresAndFunctions

// Loads a message context data into this form.
//
&AtClient
Procedure LoadContextData()
    
    Items.ContextPages.CurrentPage = Items.ContextLoadingPage;
    AttachIdleHandler("Attachable_LoadContextData", 0.2, True);   
    
EndProcedure // LoadContextData()

// Converts timestamp to a local date string.
//
&AtClient
Procedure TimestampToDate() 
    
    Items.Timestamp.Title = FL_CommonUseClientServer.TimestampToLocalDateString(
        Object.Timestamp);   
    
EndProcedure // TimestampToDate() 

#Region AttachableAndNotifyProceduresAndFunctions

&AtClient
Procedure Attachable_CheckLoadContextData()

    UpdateTaskResult(ContextTaskResult);
    
    If ContextTaskResult.State = "Completed" Then
        AfterContextTaskComplete();
    Else
        FL_TasksClientServer.UpdatePollInterval(ContextPollOptions);
        AttachIdleHandler("Attachable_CheckLoadContextData", 
            ContextPollOptions.PollInterval, True); 
    EndIf;
    
EndProcedure // Attachable_CheckLoadContextData()

&AtClient
Procedure Attachable_LoadContextData()
    
    FillContextDataInBackground();
    
    If ContextTaskResult.State = "Completed" Then
        AfterContextTaskComplete();
    Else
        ContextPollOptions = FL_TasksClientServer.NewPollOptions();    
        AttachIdleHandler("Attachable_CheckLoadContextData", 
            ContextPollOptions.PollInterval, True);
    EndIf;
    
EndProcedure // Attachable_LoadContextData()

&AtServer
Procedure FillContextDataInBackground()
    
    Task = FL_TasksClientServer.NewTask();
    Task.Context = UUID;
    Task.MethodName = "Catalogs.FL_Messages.NewInvocationFromMessage";
    Task.Parameters.Add(Object.Ref);
    ContextTaskResult = FL_Tasks.Run(Task);
                                 
EndProcedure // FillContextDataInBackground()

#EndRegion // AttachableAndNotifyProceduresAndFunctions

#Region TaskHandlers

&AtServer
Procedure AfterContextTaskComplete()
    
    If IsTempStorageURL(ContextTaskResult.StorageAddress) Then
        
        Invocation = GetFromTempStorage(ContextTaskResult.StorageAddress);
        If TypeOf(Invocation) = Type("Structure") Then
            Context.Load(Invocation.Context);
        EndIf;
        
    EndIf;

    Items.ContextPages.CurrentPage = Items.ContextPage;
    
EndProcedure // AfterContextTaskComplete()

&AtServerNoContext
Procedure UpdateTaskResult(TaskResults)
    FL_Tasks.UpdateTaskResult(TaskResults);
EndProcedure // UpdateTaskResult()

&AtServerNoContext
Procedure StopBackgroundJob(UUID)
    FL_JobServer.StopBackgroundJob(UUID);
EndProcedure // StopBackgroundJob()

#EndRegion // TaskHandlers 

#EndRegion // ServiceProceduresAndFunctions
