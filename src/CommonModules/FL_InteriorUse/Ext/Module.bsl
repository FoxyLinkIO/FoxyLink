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

#Region ConstantsInteraction

// Returns the composition of a set of constants.
//
// Parameters:
//  Set - ConstantsSet - set of constants.
//
// Returns:
//  Structure - with keys:
//      * Key - String - constant name from set.
//
Function SetOfConstants(Set) Export

    Result = New Structure;
    For Each MetaConstant In Metadata.Constants Do
        If FL_CommonUseClientServer.IsObjectAttribute(Set, MetaConstant.Name) Then
            Result.Insert(MetaConstant.Name);
        EndIf;
    EndDo;
    Return Result;

EndFunction // SetOfConstants()

#EndRegion // ConstantsInteraction

#Region HTTPInteraction

// Creates HTTPConnection object. 
//
// Parameters:
//  StringURI           - String        - reference to the resource in the format:
//    <schema>://<login>:<password>@<host>:<port>/<path>?<parameters>#<anchor>.
//  Proxy               - InternetProxy - proxy used to connect to server.
//                              Default value: Undefined.
//  Timeout             - Number        - defines timeout for connection and 
//                                        operations in seconds.
//                              Default value: 0 - timeout is not set.
//  UseOSAuthentication - Boolean       - enables NTLM or Negotiate authentication on the server.
//                              Default value: False. 
//
// Returns:
//  HTTPConnection - an object to interact with external systems by HTTP 
//                   protocol, including file transfer.  
//
Function NewHTTPConnection(StringURI, Proxy = Undefined, Timeout = 0, 
    UseOSAuthentication = False) Export
    
    URIStructure = FL_CommonUseClientServer.URIStructure(StringURI);
    If Upper(URIStructure.Schema) = Upper("https") Then 
        SecureConnection = New OpenSSLSecureConnection(Undefined, Undefined);      
    Else 
        SecureConnection = Undefined;
    EndIf;

    HTTPConnection = New HTTPConnection(
        URIStructure.Host,
        URIStructure.Port,
        URIStructure.Login,
        URIStructure.Password,
        Proxy,
        Timeout,
        SecureConnection,
        UseOSAuthentication);
        
    Return HTTPConnection;        
    
EndFunction // NewHTTPConnection()

// Creates HTTPRequest object.
//
// Parameters:
//  ResourceAddress - String - line of the http resource.
//  Headers         - Map    - request headers.
//                          Default value: Undefined.
//  BodyAsString    - String - a request body as string.
//                          Default value: "".
//
// Returns:
//  HTTPRequest - describes the HTTP-requests. 
//
Function NewHTTPRequest(ResourceAddress, Headers = Undefined, 
    BodyAsString = "") Export
    
    If Headers = Undefined Then
        Headers = New Map;
    EndIf;
    
    HTTPRequest = New HTTPRequest(ResourceAddress, Headers);
    HTTPRequest.SetBodyFromString(BodyAsString);
    Return HTTPRequest;
    
EndFunction // NewHTTPRequest()

// Sends data at the specified address to be processed using 
// the specified HTTP-method.
//
// Parameters:
//  HTTPConnection - HTTPConnection - an object to interact with external 
//                          systems by HTTP protocol, including file transfer.
//  HTTPRequest    - HTTPRequest    - describes the HTTP-requests sent using 
//                                      the HTTPConnection object.
//  HTTPMethod     - HTTPMethod     - HTTP method name.
//  StatusCode     - Number         - HTTP server status (response) code.
//  ResponseBody   - String         - response body as a string.
//  LogAttribute   - String         - if attribute is set, measuring data will
//                                      be collected.
//                          Default value: Undefined.
//
// Returns:
//  HTTPResponse - provides access to contents of a HTTP server response to a request. 
//
Function CallHTTPMethod(HTTPConnection, HTTPRequest, HTTPMethod, StatusCode, 
    ResponseBody, LogAttribute = Undefined) Export
    
    If LogAttribute <> Undefined Then
        LogObject = StartLogHTTPRequest(HTTPConnection, HTTPRequest, 
            HTTPMethod);
    EndIf;

    Try
        HTTPResponse = HTTPConnection.CallHTTPMethod(HTTPMethod, HTTPRequest);
        StatusCode = HTTPResponse.StatusCode;
        ResponseBody = HTTPResponse.GetBodyAsString();
    Except
        HTTPResponse = Undefined;
        StatusCode = CodeStatusInternalServerError();
        ResponseBody = ErrorDescription();     
    EndTry;
    
    If LogAttribute <> Undefined Then
        LogAttribute = LogAttribute + EndLogHTTPRequest(LogObject, StatusCode, 
            ResponseBody);    
    EndIf;

    Return HTTPResponse;
    
EndFunction // CallHTTPMethod()

#EndRegion // HTTPInteraction

#Region FormInteraction

// Moves a collection item.
//
// Parameters:
//  Items      - FormAllItems - collection of all managed form items.
//  ItemName   - String       - item to be moved.
//  ParentName - String       - new parent of the item. May be the same as the old one.
//  Location   - String       - item before which the moved item should be placed. If it 
//                              is not specified, the item is moved to the collection end.
//                  Default value: "".
//
Procedure MoveItemInItemFormCollection(Items, ItemName, 
    ParentName, Location = "") Export
    
    Items.Move(Items.Find(ItemName), Items.Find(ParentName), 
        Items.Find(Location));
    
EndProcedure // MoveItemInItemFormCollection()

// Moves a collection item. 
//
// Parameters:
//  Items    - FormAllItems - collection of all managed form items.
//  Item     - FormGroup, FormTable, FormDecoration, FormButton, FormField - item to be moved.
//  Parent   - FormGroup, FormTable, ManagedForm - new parent of the item. May be the same as the old one.
//  Location - FormGroup, FormTable, FormDecoration, FormButton, FormField - item before 
//                      which the moved item should be placed. If it is not specified, 
//                      the item is moved to the collection end.
//                  Default value: Undefined.
//
Procedure MoveItemInItemFormCollectionNoSearch(Items, Item, 
    Parent, Location = Undefined) Export

    Items.Move(Item, Parent, Location);

EndProcedure // MoveItemInItemFormCollectionNoSearch()

// Add an item to item form collection.
// 
// Parameters:
//  Items      - FormAllItems - collection of all managed form items.
//  Parameters - Structure    - parameters of the new form item.
//  Parent     - FormGroup, FormTable, ManagedForm - parent of the new form item.
//
// Returns:
//  FormDecoration, FormGroup, FormButton, FormTable, FormField - the new form item.
//
Function AddItemToItemFormCollection(Items, Parameters, 
    Parent = Undefined) Export
        
    If TypeOf(Parameters) <> Type("Structure") Then
        
        ErrorMessage = StrTemplate(NStr(
            "en = 'Parameter(2) failed to convert. Expected type ''%1'' and received type is ''%2''.';
            |ru = 'Параметр(2) не удалось преобразовать. Ожидался тип ''%1'', а получили тип ''%2''.'"),
            String(Type("Structure")),
            String(TypeOf(Parameters)));

        Raise ErrorMessage;
        
    EndIf;

    ItemName = ParametersPropertyValue(Parameters, "Name", 
        NStr("en = 'Error: Item name is not set.'; 
            |ru = 'Ошибка: Имя элемента не задано.'"), True, True);
                                                    
    ElementType = ParametersPropertyValue(Parameters, "ElementType", 
        NStr("en = 'Error: The element type is not specified.';
            |ru = 'Ошибка: Тип элемента не задан.'"), True, True);
                                                    
    ItemType = ParametersPropertyValue(Parameters, "Type", 
        NStr("en = 'Error: Type of element is not specified.';
            |ru = 'Ошибка: Вид элемента не задан.'"), False, True);

    If Parent <> Undefined 
        AND TypeOf(Parent) <> Type("FormGroup") 
        AND TypeOf(Parent) <> Type("FormTable") 
        AND TypeOf(Parent) <> Type("ManagedForm") Then
           
        ErrorMessage = StrTemplate(NStr("en = 'Error: Parameter(3) failed to convert. 
                |Expected type ''%1'', ''%2'', ''%3'' and received type is ''%4''.';
                |ru = 'Ошибка: Тип параметра(3) не удалось преобразовать. 
                |Ожидался тип ''%1'', ''%2'', ''%3'', а получили тип ''%4''.'"),
            String(Type("ManagedForm")),
            String(Type("FormGroup")),
            String(Type("FormTable")),
            String(TypeOf(Parent)));
            
        Raise ErrorMessage;
            
    EndIf;
        
    NewFormItem = Items.Add(ItemName, ElementType, Parent);
    If ItemType <> Undefined Then
        NewFormItem.Type = ItemType;
    EndIf;

    FillPropertyValues(NewFormItem, Parameters);

    Return NewFormItem;
    
EndFunction // AddItemToItemFormCollection()

// Sets the value into property of the form item.
// Applied when the form item can not be on form because user does not have 
// rights to an object, attribute or command.
//
// Parameters:
//  FormItems    - FormItems - property of the managed form.
//  ItemName     - String    - form item name.
//  PropertyName - String    - name of the set form item property.
//  Value        - Arbitrary - new item value.
// 
Procedure SetFormItemProperty(FormItems, ItemName, PropertyName, Value) Export

    FormItem = FormItems.Find(ItemName);
    If FormItem <> Undefined AND FormItem[PropertyName] <> Value Then
        FormItem[PropertyName] = Value;
    EndIf;

EndProcedure // SetFormItemProperty() 

#Endregion // FormInteraction

#Region SubsystemInteraction

// Performs initial filling of the subsystem.
//
Procedure InitializeSubsystem() Export
    
    InitializeStates();
    InitializeMethods();
    InitializeConstants();
    
EndProcedure // InitializeSubsystem() 

// Returns metadata object: pluggable subsystem.
//
// Parameters:
//  SubsystemName - String - plugable subsystem name.
//
// Returns:
//  MetadataObject: Subsystem - plugable subsystem.  
//
Function PluggableSubsystem(SubsystemName) Export
    
    MainSubsystem = Metadata.Subsystems.Find("FoxyLink");
    If MainSubsystem = Undefined Then
        
        ErrorMessage = NStr(
            "en = 'Failed to find main subsystem ''FoxyLink''.';
            |ru = 'Не удалось найти основную подсистему ''FoxyLink''.'");
        Raise ErrorMessage;
        
    EndIf;
    
    PluginsSubsystem = MainSubsystem.Subsystems.Find("Plugins");
    If PluginsSubsystem = Undefined Then
        
        ErrorMessage = NStr(
            "en = 'Failed to find ''FoxyLink -> Plugins'' subsystem.';
            |ru = 'Не удалось найти подсистему ''FoxyLink -> Plugins''.'");
        Raise ErrorMessage;
        
    EndIf;
    
    PluggableSubsystem = PluginsSubsystem.Subsystems.Find(SubsystemName);
    If PluggableSubsystem = Undefined Then
        
        ErrorMessage = StrTemplate(NStr(
                "en = 'Failed to find ''FoxyLink -> Plugins -> %1'' subsystem.';
                |ru = 'Не удалось найти подсистему ''FoxyLink -> Plugins -> %1''.'"),
            SubsystemName);
        Raise ErrorMessage;
        
    EndIf;
    
    Return PluggableSubsystem;
    
EndFunction // PluggableSubsystem()

#EndRegion // SubsystemInteraction

#Region RightsInteraction

// Verifies administrative access rights.
//
Procedure AdministrativeRights() Export

    If NOT PrivilegedMode() Then
        VerifyAccessRights("Administration", Metadata);
    EndIf;

EndProcedure // AdministrativeRights()

#EndRegion // RightsInteraction

#EndRegion // ProgramInterface

#Region ServiceProceduresAndFunctions

#Region HTTPInteraction

// Only for internal use.
//
Function CodeStatusInternalServerError()
    
    Return 500;
    
EndFunction // CodeStatusInternalServerError()

#EndRegion // HTTPInteraction

#Region FormInteraction

// Returns property value from structure.
// 
// Parameters:
//  Parameters     - Structure - an object that stores property values.
//  PropertyName   - String    - a property name (key).
//  ErrorMessage   - String    - error message to display if property not found.
//  PerformCheck   - Boolean   - if value is 'True' and the object does not contain the 
//                               property name (key), exception occurs.
//                          Default value: False.
//  DeleteProperty - Boolean   - if value is 'True', property will be deleted from the object.
//                          Default value: False.
//
// Returns:
//  Arbitrary - property value.
//
Function ParametersPropertyValue(Parameters, PropertyName, ErrorMessage, 
    PerformCheck = False, DeleteProperty = False)

    Var ProperyValue;
        
    If NOT Parameters.Property(PropertyName, ProperyValue)
        AND PerformCheck Then
        
        Raise ErrorMessage;   
            
    EndIf;
        
    If DeleteProperty Then 
        Parameters.Delete(PropertyName);
    EndIf;

    Return ProperyValue;

EndFunction // ParametersPropertyValue()

#EndRegion // FormInteraction

#Region SubsystemInteraction

// Only for internal use.
//
Procedure InitializeStates()
    
    DeletedState = Catalogs.FL_States.Deleted.GetObject();
    If NOT DeletedState.IsFinal Then
        DeletedState.IsFinal = True;
        DeletedState.Write();
    EndIf;
    
    SucceededState = Catalogs.FL_States.Succeeded.GetObject();
    If NOT SucceededState.IsFinal Then
        SucceededState.IsFinal = True;
        SucceededState.Write();
    EndIf;
    
EndProcedure // InitializeStates()

// Only for internal use.
//
Procedure InitializeMethods()
    
    CreateMethod = Catalogs.FL_Methods.Create.GetObject();
    If CreateMethod.RESTMethod.IsEmpty() 
        AND CreateMethod.CRUDMethod.IsEmpty() Then
        
        CreateMethod.RESTMethod = Enums.FL_RESTMethods.POST;
        CreateMethod.CRUDMethod = Enums.FL_CRUDMethods.CREATE;
        CreateMethod.Write();
        
    EndIf;
    
    ReadMethod = Catalogs.FL_Methods.Read.GetObject();
    If ReadMethod.RESTMethod.IsEmpty() 
        AND ReadMethod.CRUDMethod.IsEmpty() Then
        
        ReadMethod.RESTMethod = Enums.FL_RESTMethods.GET;
        ReadMethod.CRUDMethod = Enums.FL_CRUDMethods.READ;
        ReadMethod.Write();
        
    EndIf;
    
    UpdateMethod = Catalogs.FL_Methods.Update.GetObject();
    If UpdateMethod.RESTMethod.IsEmpty() 
        AND UpdateMethod.CRUDMethod.IsEmpty() Then
        
        UpdateMethod.RESTMethod = Enums.FL_RESTMethods.PUT;
        UpdateMethod.CRUDMethod = Enums.FL_CRUDMethods.UPDATE;
        UpdateMethod.Write();
        
    EndIf;
    
    DeleteMethod = Catalogs.FL_Methods.Delete.GetObject();
    If DeleteMethod.RESTMethod.IsEmpty() 
        AND DeleteMethod.CRUDMethod.IsEmpty() Then
        
        DeleteMethod.RESTMethod = Enums.FL_RESTMethods.DELETE;
        DeleteMethod.CRUDMethod = Enums.FL_CRUDMethods.DELETE;
        DeleteMethod.Write();
        
    EndIf;
    
EndProcedure // InitMethods()

// Only for internal use.
//
Procedure InitializeConstants()
    
    WorkerCount = FL_JobServer.GetWorkerCount();
    If WorkerCount = 0 Then
        FL_JobServer.SetWorkerCount(FL_JobServer.DefaultWorkerCount());    
    EndIf;
    
    RetryAttempts = FL_JobServer.GetRetryAttempts();
    If RetryAttempts = 0 Then
        FL_JobServer.SetRetryAttempts(FL_JobServer.DefaultRetryAttempts());    
    EndIf;
    
EndProcedure // InitializeConstants() 

#EndRegion // SubsystemInteraction

#Region LogInteraction 

// Returns a log message object that must be passed to the function 
// FL_InteriorUse.EndLogHTTPRequest.
//
// Parameters:
//  HTTPConnection - HTTPConnection - an object to interact with external 
//                          systems by HTTP protocol, including file transfer.
//  HTTPRequest    - HTTPRequest    - describes the HTTP-requests sent using 
//                          the HTTPConnection object. 
//  HTTPMethod     - String         - HTTP method name.
//
// Returns:
//  Structure - see function FL_InteriorUse.NewLogMessageHTTP.
//
Function StartLogHTTPRequest(HTTPConnection, HTTPRequest, HTTPMethod)
    
    LogMessage = NewLogMessageHTTP();
    LogMessage.HostURL = HTTPConnection.Host;
    LogMessage.HTTPMethod = Upper(HTTPMethod);
    LogMessage.ResourceAddress = HTTPRequest.ResourceAddress;
    If FL_InteriorUseReUse.IsHTTPMethodWithoutBody(Upper(HTTPMethod)) Then
        LogMessage.Delete("RequestBody");
    Else
        LogMessage.RequestBody = HTTPRequest.GetBodyAsString();   
    EndIf;
    Return LogMessage;
    
EndFunction // StartLogHTTPRequest()

// Returns complete log message.
//
// Parameters:
//  LogObject    - Structure - see function FL_InteriorUse.NewLogMessageHTTP.
//  StatusCode   - Number    - HTTP server status (response) code.
//  ResponseBody - String    - response body as a string.
//
// Returns:
//  String - complete log message.
//
Function EndLogHTTPRequest(LogObject, StatusCode, ResponseBody)
    
    LogObject.StatusCode = StatusCode;
    LogObject.ResponseBody = ResponseBody;
    LogObject.DoneResponse = CurrentUniversalDate();   
    LogObject.Elapsed = CurrentUniversalDateInMilliseconds() - LogObject.Elapsed;
    
    If LogObject.Property("RequestBody") Then
        
        Return StrTemplate("BeginRequest: %1
                |
                |REQUEST URL
                |Host URL: %2
                |Resource: %3 %4
                |
                |REQUEST BODY
                |%5
                |
                |RESPONSE BODY
                |Result: %6
                |%7
                |
                |DoneResponse: %8
                |Overall Elapsed: %9 ms
                |----------------------------------------------------------------------
                |", 
            LogObject.BeginRequest,
            LogObject.HostURL,
            LogObject.HTTPMethod,
            LogObject.ResourceAddress,
            LogObject.RequestBody,
            LogObject.StatusCode,
            LogObject.ResponseBody,
            LogObject.DoneResponse,
            LogObject.Elapsed);
        
    Else
        
        Return StrTemplate("BeginRequest: %1
                |
                |REQUEST URL
                |Host URL: %2
                |Resource: %3 %4
                |
                |RESPONSE BODY 
                |Result: %5
                |%6
                |
                |DoneResponse: %7
                |Overall Elapsed: %8 ms
                |----------------------------------------------------------------------
                |", 
            LogObject.BeginRequest,
            LogObject.HostURL,
            LogObject.HTTPMethod,
            LogObject.ResourceAddress,
            LogObject.StatusCode,
            LogObject.ResponseBody,
            LogObject.DoneResponse,
            LogObject.Elapsed);
        
    EndIf;
    
EndFunction // EndLogHTTPRequest()

// Returns a new basic HTTP log message.
//
// Returns:
//  Structure - the new basic HTTP log message:
//      * BeginRequest    - Date   - time at which this HTTP request began.
//      * HostURL         - String - host name.
//      * HTTPMethod      - String - the name of the HTTP method.
//      * ResourceAddress - String - line of the http resource. 
//      * RequestBody     - String - request body as a string.  
//      * StatusCode      - Number - HTTP server status (response) code.
//      * ResponseBody    - String - response body as a string.
//      * DoneResponse    - Date   - HTTP request processed time.             
//      * Elapsed         - Date   - time at which this HTTP request began.
//                        - Number - request execution time in ms.
//
Function NewLogMessageHTTP()
    
    LogMessageHTTP = New Structure;
    LogMessageHTTP.Insert("BeginRequest", CurrentUniversalDate());
    LogMessageHTTP.Insert("HostURL");
    LogMessageHTTP.Insert("HTTPMethod");
    LogMessageHTTP.Insert("ResourceAddress");
    LogMessageHTTP.Insert("RequestBody");
    LogMessageHTTP.Insert("StatusCode");
    LogMessageHTTP.Insert("ResponseBody");
    LogMessageHTTP.Insert("DoneResponse");
    LogMessageHTTP.Insert("Elapsed", CurrentUniversalDateInMilliseconds());
    Return LogMessageHTTP;
    
EndFunction // NewLogMessageHTTP()

#EndRegion // LogInteraction

#EndRegion // ServiceProceduresAndFunctions
