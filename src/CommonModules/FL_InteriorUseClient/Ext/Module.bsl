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

// Works with a special dialog that saves a file to selected a directory.
//
// Parameters:
//  FileExtensionAttached - Boolean   - the result value passed by the second parameter when the 
//                                       method was called with help ExecuteNotifyProcessing. 
//  AdditionalParameters  - Structure - see function FL_InteriorUseClientServer.NewFileProperties.
//
Procedure SaveFileAs(FileExtensionAttached, 
    AdditionalParameters) Export
    
    If FileExtensionAttached Then
        
        FileDialog = New FileDialog(FileDialogMode.Save);
        FileDialog.Multiselect = False;
        FileDialog.FullFileName = AdditionalParameters.Name;
        FileDialog.DefaultExt = AdditionalParameters.Extension;
        FileDialog.Filter = StrTemplate(NStr("en = 'All files (*.%1)|*.%1';
            |ru = 'Все файлы (*.%1)|*.%1'"), AdditionalParameters.Extension);
        
        If NOT FileDialog.Choose() Then
            Return;
        EndIf;
        
        Ki = 1024;
        SizeKB = AdditionalParameters.Size / Ki;
        
        ShowUserNotification(, , StrTemplate(NStr("en = 'Saving file ""%1"" (%2 KB)
                    |Please, wait...'; ru = 'Сохраняется файл ""%1"" (%2 KB)
                    |Пожалуйста, подождите...'"),
                AdditionalParameters.Name, String(SizeKB)), 
            PictureLib.FL_Logotype64);
        
        TransferableFile = New TransferableFileDescription(
            FileDialog.FullFileName, AdditionalParameters.StorageAddress);
        TransferableFiles = New Array;
        TransferableFiles.Add(TransferableFile);
        
        ReceivedFiles = New Array;
        If GetFiles(TransferableFiles, ReceivedFiles, , False) Then
            ShowUserNotification(NStr("en = 'The file was successfully saved.';
                    |ru = 'Файл успешно сохранен.'"), , 
                FileDialog.FullFileName); 
        EndIf;
        
    EndIf;
    
EndProcedure // SaveFileAs()

// Updates the application interface saving the current active window. 
//
Procedure RefreshApplicationInterface() Export

    CurrentActiveWindow = ActiveWindow();
    RefreshInterface();
    If CurrentActiveWindow <> Undefined Then
        CurrentActiveWindow.Activate();
    EndIf;

EndProcedure // RefreshApplicationInterface()

// Begins running an external application or opens an application file with 
// associated name.
//
// Parameters:
//  FileExtensionAttached - Boolean   - the result value passed by the second 
//                                     parameter when the method was called
//                                     with help ExecuteNotifyProcessing. 
//  AdditionalParameters  - Structure - see function FL_InteriorUseClient.NewRunApplicationParameters.
//
Procedure Attachable_RunApplication(FileExtensionAttached, 
    AdditionalParameters) Export
    
    If FileExtensionAttached Then
        BeginRunningApplication(AdditionalParameters.NotifyDescription, 
            AdditionalParameters.CommandLine,
            AdditionalParameters.CurrentDirectory,
            AdditionalParameters.WaitForCompletion);
    EndIf;
    
EndProcedure // Attachable_RunApplication()
    
// Begins attaching the extension for working with files.
//
// Parameters:
//  NotifyDescription - NotifyDescription - notify description to execute after 
//                                          attaching extension. 
//
Procedure Attachable_FileSystemExtension(NotifyDescription) Export
    
    BeginAttachingFileSystemExtension(New NotifyDescription(
        "DoAfterAttachFileSystemExtension", 
        FL_InteriorUseClient, 
        NotifyDescription));
    
EndProcedure // Attachable_FileSystemExtension()

#EndRegion // ProgramInterface

#Region ServiceInterface

// Attaches the extension for working with files. 
//
// Parameters:
//  Connected         – Boolean           - the connection result. 
//                              True - extension is successfully connected. 
//  NotifyDescription - NotifyDescription - value specified when the 
//                              NotifyDescription object was created.
//
Procedure DoAfterAttachFileSystemExtension(Connected, 
    NotifyDescription) Export

    If Connected AND TypeOf(NotifyDescription) = Type("NotifyDescription") Then
        ExecuteNotifyProcessing(NotifyDescription, True);        
    Else
        BeginInstallFileSystemExtension(New NotifyDescription(
            "DoAfterInstallFileSystemExtension", 
            FL_InteriorUseClient, 
            NotifyDescription));    
    EndIf;
    
EndProcedure // DoAfterAttachFileSystemExtension() 

// Installs the extension for working with files. 
//
// Parameters:
//  NotifyDescription - NotifyDescription - value specified when the 
//                              NotifyDescription object was created.
//
Procedure DoAfterInstallFileSystemExtension(NotifyDescription) Export

    If TypeOf(NotifyDescription) = Type("NotifyDescription") Then
        ExecuteNotifyProcessing(NotifyDescription, True);           
    EndIf;
    
EndProcedure // DoAfterInstallFileSystemExtension()

// Returns a run application parameters.
//
// Returns:
//  Structure - the invocation data structure with keys:
//      * NotifyDescription - NotifyDescription - contains description of the 
//                                  procedure which will be called upon completion. 
//      * CommandLine       - String            - command line for launching 
//                                  the application or the file name associated 
//                                  with a given application. 
//      * CurrentDirectory  - String            - sets the current directory 
//                                  of the application being launched.
//                                  Is ignored in in the web-client mode. 
//                              Default value: "".
//      * WaitForCompletion - Boolean           - True - wait for completion of 
//                                  running application before the work continues.
//                              Default value: False.
//
Function NewRunApplicationParameters() Export
    
    RunApplicationParameters = New Structure;
    RunApplicationParameters.Insert("NotifyDescription");
    RunApplicationParameters.Insert("CommandLine");
    RunApplicationParameters.Insert("CurrentDirectory", "");
    RunApplicationParameters.Insert("WaitForCompletion", False);
    Return RunApplicationParameters;
    
EndFunction // NewRunApplicationParameters()    
    
#EndRegion // ServiceInterface