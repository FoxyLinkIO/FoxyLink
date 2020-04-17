////////////////////////////////////////////////////////////////////////////////
// This file is part of FoxyLink.
// Copyright © 2016-2020 Petro Bazeliuk.
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

// Performs initial filling of the subsystem.
//
Procedure UpdateSubsystem() Export
    
    UpdateApps();
    UpdateConstants();
    UpdateHandlers();
    UpdateOperations();
    UpdateStates();
    
EndProcedure // UpdateSubsystem() 

#EndRegion // ProgramInterface

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
Procedure UpdateApps()
    
    Try
    
        SelfFilesProcessor = FL_InteriorUse.NewAppEndpointProcessor(
            "595e752d-57f4-4398-a1cb-e6c5a6aaa65c");
        
        SelfFiles = Catalogs.FL_Channels.SelfFiles.GetObject();
        SelfFiles.DataExchange.Load = True;
        SelfFiles.BasicChannelGuid = SelfFilesProcessor.LibraryGuid();
        SelfFiles.Connected = True;
        SelfFiles.Log = False;
        SelfFiles.Version = SelfFilesProcessor.Version();
        SelfFiles.Write();
        
    Except
        
        ErrorInformation = ErrorInfo();
        FL_InteriorUse.WriteLog(
            "FoxyLink.UpdateSubsystem.UpdateApps", 
            EventLogLevel.Error,
            Metadata.Catalogs.FL_Channels,
            ErrorInformation);
        
    EndTry;
        
EndProcedure // UpdateApps() 

// Only for internal use.
//
Procedure UpdateConstants()
    
    RetryAttempts = Constants.FL_RetryAttempts.Get();
    If RetryAttempts = 0 Then
        FL_JobServer.SetRetryAttempts(FL_JobServer.DefaultRetryAttempts());    
    EndIf;
    
    WorkerCount = Constants.FL_WorkerCount.Get();
    If WorkerCount = 0 Then
        FL_JobServer.SetWorkerCount(FL_JobServer.DefaultWorkerCount());    
    EndIf;
    
    WorkerJobsLimit = Constants.FL_WorkerJobsLimit.Get();
    If WorkerJobsLimit = 0 Then
        FL_JobServer.SetWorkerJobsLimit(FL_JobServer.DefaultWorkerJobsLimit());    
    EndIf;
    
EndProcedure // UpdateConstants()

// Only for internal use.
//
Procedure UpdateHandlers()
    
    PlugableFormats = FL_InteriorUse.PluggableSubsystem("Formats");
    For Each Item In PlugableFormats.Content Do
        
        If Metadata.DataProcessors.Contains(Item) Then
            
            Try
                                
                DataProcessor = DataProcessors[Item.Name].Create();
                
                LibraryGuid = DataProcessor.LibraryGuid();
                HandlerRef = FL_CommonUse.ReferenceByUUID(
                    Metadata.Catalogs.FL_Handlers, LibraryGuid);
                    
                If NOT FL_CommonUse.RefExists(HandlerRef) Then 
                    
                    Object = Catalogs.FL_Handlers.CreateItem();
                    Object.SetNewObjectRef(HandlerRef);
                    
                    Object.Description = DataProcessor.BaseDescription();
                    Object.FormatFileExtension = Upper(DataProcessor.FormatFileExtension());
                    Object.FormatFullName = DataProcessor.FormatFullName();
                    Object.FormatMediaType = Upper(DataProcessor.FormatMediaType());
                    Object.FormatShortName = DataProcessor.FormatShortName();
                    Object.FormatStandard = DataProcessor.FormatStandard();
                    Object.FormatStandardLink = DataProcessor.FormatStandardLink();
                    Object.HandlerType = Enums.FL_HandlerTypes.FormatHandler;
                    Object.RegisteredHandlerName = Item.Name;
                    Object.Version = DataProcessor.Version();
                    Object.Write();
                    
                EndIf;
                    
            Except
                
                FL_CommonUseClientServer.NotifyUser(ErrorDescription());
                
            EndTry;
            
        EndIf;
        
    EndDo;
        
EndProcedure // UpdateHandlers()

// Only for internal use.
//
Procedure UpdateOperations()
    
    CreateOperation = Catalogs.FL_Operations.Create.GetObject();
    If CreateOperation.RESTMethod.IsEmpty() 
        AND CreateOperation.CRUDMethod.IsEmpty() Then
        
        CreateOperation.RESTMethod = Enums.FL_RESTMethods.POST;
        CreateOperation.CRUDMethod = Enums.FL_CRUDMethods.CREATE;
        CreateOperation.Write();
        
    EndIf;
    
    ReadOperation = Catalogs.FL_Operations.Read.GetObject();
    If ReadOperation.RESTMethod.IsEmpty() 
        AND ReadOperation.CRUDMethod.IsEmpty() Then
        
        ReadOperation.RESTMethod = Enums.FL_RESTMethods.GET;
        ReadOperation.CRUDMethod = Enums.FL_CRUDMethods.READ;
        ReadOperation.Write();
        
    EndIf;
    
    UpdateOperation = Catalogs.FL_Operations.Update.GetObject();
    If UpdateOperation.RESTMethod.IsEmpty() 
        AND UpdateOperation.CRUDMethod.IsEmpty() Then
        
        UpdateOperation.RESTMethod = Enums.FL_RESTMethods.PUT;
        UpdateOperation.CRUDMethod = Enums.FL_CRUDMethods.UPDATE;
        UpdateOperation.Write();
        
    EndIf;
    
    DeleteOperation = Catalogs.FL_Operations.Delete.GetObject();
    If DeleteOperation.RESTMethod.IsEmpty() 
        AND DeleteOperation.CRUDMethod.IsEmpty() Then
        
        DeleteOperation.RESTMethod = Enums.FL_RESTMethods.DELETE;
        DeleteOperation.CRUDMethod = Enums.FL_CRUDMethods.DELETE;
        DeleteOperation.Write();
        
    EndIf;
    
EndProcedure // UpdateOperations()

// Updates states according to the configuration language.
//
Procedure UpdateStates()
    
    AwaitingState = Catalogs.FL_States.Awaiting.GetObject();
    AwaitingState.Description = NStr("en='Awaiting';
        |ru='В ожидании';
        |uk='В очікуванні';
        |en_CA='Awaiting'");
    AwaitingState.Write();
    
    DeletedState = Catalogs.FL_States.Deleted.GetObject();
    DeletedState.IsFinal = True;
    DeletedState.Description = NStr("en='Deleted';
        |ru='Удаленные';
        |uk='Видалені';
        |en_CA='Deleted'");
    DeletedState.Write();
    
    EnqueuedState = Catalogs.FL_States.Enqueued.GetObject();
    EnqueuedState.Description = NStr("en='Enqueued';
        |ru='В очереди';
        |uk='В черзі';
        |en_CA='Enqueued'");
    EnqueuedState.Write();
    
    FailedState = Catalogs.FL_States.Failed.GetObject();
    FailedState.Description = NStr("en='Failed';
        |ru='Неудачные';
        |uk='Невдалі';
        |en_CA='Failed'");
    FailedState.Write();

    ProcessingState = Catalogs.FL_States.Processing.GetObject();
    ProcessingState.Description = NStr("en='Processing';
        |ru='В процессе обработки';
        |uk='В процесі обробки';
        |en_CA='Processing'");
    ProcessingState.Write();

    ScheduledState = Catalogs.FL_States.Scheduled.GetObject();
    ScheduledState.Description = NStr("en='Scheduled';
        |ru='Запланированные';
        |uk='Заплановані';
        |en_CA='Scheduled'");
    ScheduledState.Write();

    SucceededState = Catalogs.FL_States.Succeeded.GetObject();
    SucceededState.IsFinal = True;
    SucceededState.Description = NStr("en='Succeeded';
        |ru='Успешные';
        |uk='Успішні';
        |en_CA='Succeeded'");
    SucceededState.Write();

EndProcedure // UpdateStates()

#EndRegion // ServiceProceduresAndFunctions