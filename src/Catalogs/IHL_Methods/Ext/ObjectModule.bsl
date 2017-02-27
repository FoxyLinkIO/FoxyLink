
#Region ServiceInterface

Procedure BeforeWrite(Cancel)
    
    For Index = 1 To StrLen(Description) Do
        Symbol = Mid(Description, Index, 1);
        If Not IHL_CommonUseClientServer.IsLatinLetter(Symbol) Then
            IHL_CommonUseClientServer.NotifyUser(
                НСтр("en = 'Method name contains illegal characters, Latin letters are allowed only!';
                    |ru = 'Имя метода содержит запрещенные символы, разрешены только латинские буквы!'"),
                ,
                "Object.Description",
                ,
                Cancel);
        EndIf;
    EndDo;   
    
EndProcedure // BeforeWrite()

#EndRegion // ServiceInterface
