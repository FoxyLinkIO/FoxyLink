
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
    
    FileProperties = ExportObject(CommandParameter);
    If FileProperties = Undefined Then        
        Return;    
    EndIf;
    
    FL_InteriorUseClient.Attachable_FileSystemExtension(New NotifyDescription(
        "Attachable_SaveFileAs", FL_InteriorUseClient, FileProperties));
       
EndProcedure // CommandProcessing()

&AtServer
Function ExportObject(ObjectRef)
    
    If TypeOf(ObjectRef) = Type("CatalogRef.FL_Exchanges") Then
        Return Catalogs.FL_Exchanges.ExportObject(ObjectRef);
    EndIf;
    
    Return Undefined;
    
EndFunction // ExportObject() 