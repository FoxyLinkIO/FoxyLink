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

#Region ProgramInterface

// Updates the application interface saving the current active window. 
//
Procedure RefreshApplicationInterface() Export

    CurrentActiveWindow = ActiveWindow();
    RefreshInterface();
    If CurrentActiveWindow <> Undefined Then
        CurrentActiveWindow.Activate();
    EndIf;

EndProcedure // RefreshApplicationInterface()

// Prompts whether the action that results in loss of changes should be 
// continued. For use in the BeforeClosing event handler of forms modules.
//  
// Parameters:
//  NotifyDescription - NotifyDescription - contains the name of the procedure
//                                          that is called when you click the OK.
//  Cancel            - Boolean           - return parameter, shows that you 
//                                          canceled the executed action.
//  WarningText       - String            - overridable alert text displayed to 
//                                          user.
//
Procedure ShowFormClosingConfirmation(NotifyDescription, Cancel, 
    WarningText = "") Export

    ManagedForm = NotifyDescription.Module;
    If NOT ManagedForm.Modified Then
        Return;
    EndIf;

    Cancel = True;

    If IsBlankString(WarningText) Then
        QuestionText = NStr("en='Data was changed. Save the changes?';
            |ru='Данные были изменены. Сохранить изменения?';
            |en_CA='Data was changed. Save the changes?'");
    Else
        QuestionText = WarningText;
    EndIf;
    
    ShowQueryBox(New NotifyDescription("DoAfterConfirmFormClosing", ThisObject, 
            NotifyDescription), 
        QuestionText, 
        QuestionDialogMode.YesNoCancel, 
        ,
        DialogReturnCode.No);

EndProcedure // ShowFormClosingConfirmation()

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

// Works with a special dialog that saves a file to a selected directory.
//
// Parameters:
//  FileExtensionAttached - Boolean   - the result value passed by the second parameter when the 
//                                       method was called with help ExecuteNotifyProcessing. 
//  AdditionalParameters  - Structure - see function FL_InteriorUseClientServer.NewFileProperties.
//
Procedure Attachable_SaveFileAs(FileExtensionAttached, 
    AdditionalParameters) Export
    
    If FileExtensionAttached Then
        
        FileDialog = New FileDialog(FileDialogMode.Save);
        FileDialog.Multiselect = False;
        FileDialog.FullFileName = AdditionalParameters.Name;
        FileDialog.DefaultExt = AdditionalParameters.Extension;
        FileDialog.Filter = StrTemplate(NStr("en='All files (*%1)|*%1';
                |ru='Все файлы (*%1)|*%1';en_CA='All files (*%1)|*%1'"), 
            AdditionalParameters.Extension);
        FileDialog.Show(New NotifyDescription("DoAfterSelectSaveFileAs", 
            FL_InteriorUseClient, AdditionalParameters)); 
        
    EndIf;
    
EndProcedure // Attachable_SaveFileAs()

#EndRegion // ProgramInterface

#Region ServiceInterface

// Processes the confirmation result on BeforeClosing event of forms modules.
// 
// Parameters:
//  QuestionResult    - DialogReturnCode  - system enumeration value or a value
//                                          related to a clicked button.
//  NotifyDescription - NotifyDescription - the value specified when the 
//                                          NotifyDescription object was created.
//
Procedure DoAfterConfirmFormClosing(QuestionResult, NotifyDescription) Export

    If QuestionResult = DialogReturnCode.Yes Then
        ExecuteNotifyProcessing(NotifyDescription);
    ElsIf QuestionResult = DialogReturnCode.No Then
        ManagedForm = NotifyDescription.Module;
        ManagedForm.Modified = False;
        ManagedForm.Close();
    Else
        ManagedForm = NotifyDescription.Module;
        ManagedForm.Modified = True;
    EndIf;

EndProcedure // DoAfterConfirmFormClosing()

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

// Begins saving the file to the selected directory.
//
// Parameters:
//  SelectedFiles        - Array     - an array of selected file names or 
//                                     Undefined, if no selection is made. 
//  AdditionalParameters - Arbitrary - see function FL_InteriorUseClientServer.NewFileProperties.
//
Procedure DoAfterSelectSaveFileAs(SelectedFiles, AdditionalParameters) Export
    
    If SelectedFiles <> Undefined
        AND TypeOf(SelectedFiles) = Type("Array") Then
                                               
        Ki = 1024;
        SizeKB = Format(AdditionalParameters.Size / Ki, "NFD=2");
        
        ShowUserNotification(, , StrTemplate(NStr("en='Saving file %1 (%2 KB) 
                    |Please, wait...'; ru='Сохраняется файл %1 (%2 KB)
                    |Пожалуйста, подождите...';en_CA='Saving file %1 (%2 KB)
                    |Please, wait...'"),
                AdditionalParameters.Name, String(SizeKB)), 
            PictureLib.FL_Logotype64);
            
        TransferableFiles = New Array;
        For Each SelectedFile In SelectedFiles Do
            
            TransferableFile = New TransferableFileDescription(SelectedFile, 
                AdditionalParameters.StorageAddress);
            TransferableFiles.Add(TransferableFile);
            
        EndDo;
        
        BeginGettingFiles(New NotifyDescription("DoAfterBeginGettingFiles", 
            FL_InteriorUseClient), TransferableFiles, , False);

    EndIf;
    
EndProcedure // DoAfterSelectSaveFileAs() 

// Begins getting a set of files and saves them to the local user's file system.
//
// Parameters:
//  ReceivedFiles        - TransferedFileDescription - array of the objects or 
//                                  Undefined, if the files are not received.
//  AdditionalParameters - Arbitrary                 - value specified when 
//                                  the NotifyDescription object was created. 
//
Procedure DoAfterBeginGettingFiles(ReceivedFiles, 
    AdditionalParameters = Undefined) Export 

    If ReceivedFiles <> Undefined 
        AND TypeOf(ReceivedFiles) = Type("Array") Then
        
        For Each ReceivedFile In ReceivedFiles Do
            
            AppParameters = NewRunApplicationParameters();
            AppParameters.NotifyDescription = New NotifyDescription(
                "DoAfterBeginRunningApplication", FL_InteriorUseClient);
            AppParameters.CommandLine = ReceivedFile.Name;
            AppParameters.WaitForCompletion = True;
            NotifyDescription =  New NotifyDescription(
                "DoActionOpenFolderOnClick", FL_InteriorUseClient, AppParameters);
            
            ShowUserNotification(NStr("en='The file was successfully saved.';
                |ru='Файл успешно сохранен.';
                |en_CA='The file was successfully saved.'"), 
                NotifyDescription, 
                ReceivedFile.Name, 
                PictureLib.FL_Logotype64);
                
        EndDo;
        
    EndIf;
    
EndProcedure // DoAfterBeginGettingFiles()     

// Begins opening file folder after click on the user notification.
//
// Parameters:
//  AdditionalParameters - Arbitrary - value specified when the NotifyDescription
//                                     object was created.
//
Procedure DoActionOpenFolderOnClick(AdditionalParameters) Export
    
    File = New File(AdditionalParameters.CommandLine);
    BeginRunningApplication(AdditionalParameters.NotifyDescription, 
        File.Path, 
        AdditionalParameters.CurrentDirectory, 
        AdditionalParameters.WaitForCompletion);      
    
EndProcedure // DoActionOpenFolderOnClick() 

// Begins running an external application or opens an application file with 
// the associated name.
//
// Parameters:
//  CodeReturn           - Number, Undefined - the code of return, if a relevant
//                          input parameter <WaitForCompletion> is not specified. 
//  AdditionalParameters - Arbitrary         - the value specified when the 
//                              NotifyDescription object was created.
//
Procedure DoAfterBeginRunningApplication(CodeReturn, AdditionalParameters) Export
    
    If CodeReturn <> 0 Then 
        
        Explanation = NStr("en='Unexpected error has happened.';
            |ru='Произошла непредвиденная ошибка.';
            |en_CA='Unexpected error has happened.'");
    
        ShowUserNotification(NStr("en='Something went wrong.';
            |ru='Что-то пошло не так.';
            |en_CA='Something went wrong.'"), 
            , 
            Explanation, 
            PictureLib.FL_Logotype64);
        
    EndIf;
    
EndProcedure // DoAfterBeginRunningApplication()

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