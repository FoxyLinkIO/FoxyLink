
#Region FormEventHandlers

&AtClient
Procedure OnOpen(Cancel)
    
    TimestampToDate();
    
EndProcedure // OnOpen()

#EndRegion // FormEventHandlers

#Region ServiceProceduresAndFunctions

// Converts timestamp to a local date string.
//
&AtClient
Procedure TimestampToDate() 
    
    Items.TimestampCreatedAt.Title = FL_CommonUseClientServer.TimestampToLocalDateString(
        Object.CreatedAt);
    Items.TimestampExpireAt.Title = FL_CommonUseClientServer.TimestampToLocalDateString(
        Object.ExpireAt);
    
EndProcedure // TimestampToDate() 

#EndRegion // ServiceProceduresAndFunctions