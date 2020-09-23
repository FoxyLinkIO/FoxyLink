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

#Region FormItemsEventHandlers

&AtClient
Procedure OpenAPISelection(Item, SelectedRow, Field, StandardProcessing)
    
    TreeItem = OpenApi.FindByID(SelectedRow);
    If TreeItem = Undefined Then
        Return;
    EndIf;
    
    If StrFind(TreeItem.Type, "requestBody") = 0 
        AND StrFind(TreeItem.Type, "response") = 0 Then
        Return;    
    EndIf;
    
    If IsTempStorageURL(OpenAPIStorage) Then
        
        Path = New Map;
        AddToPath(Path, TreeItem.GetItems());
        
        ClosureResult = New Structure;
        ClosureResult.Insert("OpenAPI", GetFromTempStorage(OpenAPIStorage));
        ClosureResult.Insert("Path", Path);
        Close(ClosureResult);
                
    EndIf;
    
EndProcedure // OpenAPISelection() 

#EndRegion // FormItemsEventHandlers

#Region FormCommandHandlers

&AtClient
Procedure ConnectToSwagger(Command)

    If IsBlankString(ConnectionPath) Then
        
        FL_CommonUseClientServer.NotifyUser(NStr("
                |en='Fill the connection path.';
                |ru='Заполните путь для подключения.';
                |uk='Заповніть шлях для підключення.';
                |en_CA='Fill the connection path.'"),
            ,
            "ConnectionPath");
        Return;
        
    EndIf;
    
    ConnectToSwaggerAtServer();
         
EndProcedure // ConnectToSwagger() 

#EndRegion // FormCommandHandlers 

#Region ServiceProceduresAndFunctions

&AtClient
Procedure AddToPath(Path, TreeItems)
    
    For Each Item In TreeItems Do
        
        If ValueIsFilled(Item.Schema) Then
            Path.Insert(Item.Type, Item.Schema);       
        Else
            SubPath = New Map;
            Path.Insert(Item.Type, SubPath);
            AddToPath(SubPath, Item.GetItems());
        EndIf;
        
    EndDo;
    
EndProcedure // AddToPath()

&AtServer
Procedure ConnectToSwaggerAtServer()

    URIStructure = FL_CommonUseClientServer.URIStructure(ConnectionPath);
    URIStructure.Login = Login;
    URIStructure.Password = Password;
    
    StringURI = FL_CommonUseClientServer.StringURI(URIStructure);
    
    // Getting HTTP request.
    HTTPRequest = FL_InteriorUse.NewHTTPRequest(URIStructure.PathOnServer);
        
    // Getting HTTP connection.
    HTTPConnection = FL_InteriorUse.NewHTTPConnection(StringURI);
    
    JobResult = Catalogs.FL_Jobs.NewJobResult(True);
    FL_InteriorUse.CallHTTPMethod(HTTPConnection, HTTPRequest, "GET", 
        JobResult);
        
    If JobResult.Success Then
        Invocation = Catalogs.FL_Jobs.GetFromJobResult(JobResult, "Invocation");
        OpenApiObject = Catalogs.FL_Messages.ReadInvocationPayload(Invocation);
        FillOpenAPITree(OpenApiObject);
    Else
        LogAttribute = JobResult.LogAttribute;
    EndIf;
    
EndProcedure // ConnectToSwaggerAtServer()

&AtServer
Procedure FillOpenAPITree(OpenApiObject)
    
    OpenApiTree = FormAttributeToValue("OpenAPI", Type("ValueTree"));
    
    Paths = OpenApiObject.Get("paths");
    OpenAPIStorage = PutToTempStorage(OpenApiObject, UUID);
    For Each Path In Paths Do
        AddPathMethods(Path.Key, Path.Value, OpenApiTree);      
    EndDo;
    
    ValueToFormAttribute(OpenApiTree, "OpenAPI");
    Items.Pages.CurrentPage = Items.OpenApiPage;   
    
EndProcedure // FillOpenAPITree()

&AtServerNoContext
Procedure AddPathMethods(Path, Methods, ValueTree)
    
    PathTemplate = "%1 %2";
    For Each Method In Methods Do
            
        NewRow = ValueTree.Rows.Add();
        NewRow.Path = StrTemplate(PathTemplate, Upper(Method.Key), Path);
        
        AddTypes(Method.Value, NewRow);
        
    EndDo;   
    
EndProcedure // AddPathMethods()

&AtServerNoContext
Procedure AddTypes(Types, ValueTree)
    
    Responses = Types.Get("responses");
    If ValueIsFilled(Responses) Then
        
        ResponseTemplate = "response:%1";
        For Each Response In Responses Do
            NewRow = ValueTree.Rows.Add();
            NewRow.Type = StrTemplate(ResponseTemplate, Response.Key);
            ProcessSchema(Response.Value, NewRow);
        EndDo;
        
    EndIf;
          
    RequestBody = Types.Get("requestBody");
    If ValueIsFilled(RequestBody) Then
        NewRow = ValueTree.Rows.Add();
        NewRow.Type = "requestBody"; 
        ProcessSchema(RequestBody, NewRow);
    EndIf;
    
EndProcedure // AddMethods()

&AtServerNoContext
Procedure ProcessSchema(Map, ValueTree)
    
    Content = Map.Get("content");
    If NOT ValueIsFilled(Content) Then
        Return;
    EndIf;
    
    ContentType = Content.Get("application/json");
    If NOT ValueIsFilled(Content) Then
        Return;
    EndIf;
    
    Schema = ContentType.Get("schema");
    If NOT ValueIsFilled(Schema) Then
        Return;
    EndIf;
    
    AddToSchema(Schema, ValueTree);
    
EndProcedure // ProcessSchema()

&AtServerNoContext
Procedure AddToSchema(Schema, ValueTree)
    
    Type = Schema.Get("type");
    If ValueIsFilled(Type) Then
        
        NewRow = ValueTree.Rows.Add();
        NewRow.Type = Type;
        
        Items = Schema.Get("items");
        If ValueIsFilled(Items) Then
            AddToSchema(Items, NewRow);     
        EndIf;
        
    Else
        
        For Each Item In Schema Do
            NewRow = ValueTree.Rows.Add();
            NewRow.Type = Item.Key;
            NewRow.Schema = Item.Value;    
        EndDo;
        
    EndIf;
    
EndProcedure // AddToSchema()

#EndRegion // ServiceProceduresAndFunctions