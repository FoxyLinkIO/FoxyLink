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

// Generates and outputs the message that can be connected to form managing item.
//
// Parameters:
//  Text     - String  - message type.
//  DataKey  - AnyRef  - to infobase object.
//                          Ref to object of the infobase to which
//                          this message relates or the record key.
//  Field    - String  - form attribute name.
//  DataPath - String  - path to data (path to form attribute).
//  Cancel   - Boolean - Output parameter.
//                          Always set to True value.
//
// Cases of incorrect usage:
//  1. Simultaneously pass the DataKey and DataPath parameters.
//  2. Transfer the parameter values in the DataKey type other than valid.
//  3. Set reference without setting field (and/or data path).
//
Procedure NotifyUser(Val Text, Val DataKey = Undefined, Val Field = "",
        Val DataPath = "", Cancel = False) Export

    Message = New UserMessage;
    Message.Text = Text;
    Message.Field = Field;

    IsObject = False;

    #If NOT ThinClient AND NOT WebClient Then
    If DataKey <> Undefined AND XMLTypeOf(DataKey) <> Undefined Then
        ValueType = XMLTypeOf(DataKey).TypeName;
        IsObject = Find(ValueType, "Object.") > 0;
    EndIf;
    #EndIf

    If IsObject Then
        Message.SetData(DataKey);
    Else
        Message.DataKey = DataKey;
    EndIf;

    If Not IsBlankString(DataPath) Then
        Message.DataPath = DataPath;
    EndIf;
        
    Message.Message();

    Cancel = True;

EndProcedure // NotifyUser()

// Saves a serialized value to a temporary storage.
//
// Parameters:
//  SerializedValue - Arbitrary - data that should be placed in the temporary storage.
//  Address         - String    - an address in the temporary storage where the data should be placed.
//  TTL             - UUID      - If you transfer UUID forms or address to a repository, the value will be 
//                                  automatically removed after closing the form.
//                                If you transfer UUIDwhich is not a unique form identifier, the value will be 
//                                  removed after the user session is completed.
//                                If the parameter is not specified, the placed value is deleted after the next 
//                                  server request from the common module, during a context or non-context server
//                                  call from a form, server call from a command module or when obtaining a form.
//                      Default value: Undefined.
//
Procedure PutSerializedValueToTempStorage(SerializedValue, Address, 
    TTL = Undefined) Export
    
    If IsTempStorageURL(Address) Then
        PutToTempStorage(SerializedValue, Address);
    Else
        Address = PutToTempStorage(SerializedValue, TTL);
    EndIf;
    
EndProcedure // PutDataToTempStorage()

// Deletes the values from FormDataObject by filter.
//
// Parameters:
//  FormDataObject   - FormDataCollection - collection in the managed form data.
//  FilterParameters - Structure          - filter parameter.
//      * Key   - String    - defines the column where to search.
//      * Value - Arbitrary - defines the desired value.
//  Modified         - Boolean            - Output parameter. 
//                              Always set to True value if FormDataObject is modified.
//
Procedure DeleteRowsByFilter(FormDataObject, FilterParameters, 
    Modified = True) Export
    
    FilterResults = FormDataObject.FindRows(FilterParameters);
    For Each Result In FilterResults Do
        Modified = True;
        FormDataObject.Delete(Result);        
    EndDo;
    
EndProcedure // DeleteRowsByFilter()

// Extends the target table with the data from the source table.
//
// Parameters:
//  SourceTable - ValueTable - table from which rows will be taken.
//  TargetTable - ValueTable - table to which rows will be added.
//  
Procedure ExtendValueTable(SourceTable, TargetTable) Export

    For Each SourceTableRow In SourceTable Do
        FillPropertyValues(TargetTable.Add(), SourceTableRow);
    EndDo;

EndProcedure // ExtendValueTable()

// Extends the receiver array with values from the source array.
//
// Parameters:
//  Receiver - Array   - array in which new values will be added.
//  Source   - Array   - array of values for filling. 
//  Unique   - Boolean - if True - only unique values will be added to the receiver
//                          array, otherwise all values from the source.
// 
Procedure ExtendArray(Receiver, Source, Unique = False) Export

    For Each ArrayItem In Source Do
        If NOT Unique OR Receiver.Find(ArrayItem) = Undefined Then
            Receiver.Add(ArrayItem);
        EndIf;
    EndDo;

EndProcedure // ExtendArray() 

// Extends the receiver collection with values from the source collection.
//
// Parameters:
//  Receiver        - Structure          - collection to which new values 
//                                          will be added.
//  Source          - Structure          - collection from which pairs Key and
//                                          Value for filling will be read.
//  WithReplacement - Boolean, Undefined - what to do in intersection places of 
//                                          the source keys and receiver.
//                  - True      - replace receiver values (the quickest method).
//                  - False     - do not replace receiver values (skip).
//                  - Undefined - value by default. Throw exception.
//
Procedure ExtendStructure(Receiver, Source, WithReplacement = Undefined) Export

    SearchKey = WithReplacement = Undefined Or NOT WithReplacement;
    For Each KeyAndValue In Source Do
        If SearchKey AND Receiver.Property(KeyAndValue.Key) Then
            If NOT WithReplacement Then
                Continue;
            Else
                Raise StrTemplate(NStr("en='Source and receiver structures intersection by key {%1}.';
                    |ru='Пересечение структур источника и приемника по ключу {%1}.';
                    |en_CA='Source and receiver structures intersection by key {%1}.'"),
                    KeyAndValue.Key);
            EndIf;
        EndIf;
        Receiver.Insert(KeyAndValue.Key, KeyAndValue.Value);
    EndDo;

EndProcedure // ExtendStructure()

// Removes duplicates from source array.
//
// Parameters:
//  Source - Array - array of values to remove duplicates.
//
Procedure RemoveDuplicatesFromArray(Source) Export
    
    Receiver = New Array;
    ExtendArray(Receiver, Source, True);
    Source = Receiver;
    
EndProcedure // RemoveDuplicatesFromArray()

// Removes value from source structure.
//
// Parameters:
//  Source - Structure - structure of keys and values to remove from.
//  Value  - Arbitrary - value to remove.
//                  Default value: Undefined.
//
Procedure RemoveValueFromStructure(Source, Value = Undefined) Export
    
    RemoveArray = New Array;
    For Each KeyValue In Source Do
        If KeyValue.Value = Value Then
            RemoveArray.Add(KeyValue.Key);    
        EndIf;
    EndDo;
    
    For Each Item In RemoveArray Do
        Source.Delete(Item);        
    EndDo;
    
EndProcedure // RemoveValuesFromStructure()

// Creates an instance copy of the specified object.
//
// Parameters:
//  Source - Arbitrary - object that is required to be copied.
//
// Returns:
//  Arbitrary - copy of the source object.
//
// Note:
//  Function can not be used for object types (CatalogObject, DocumentObject etc.).
//
Function CopyRecursive(Source) Export
    
    Var Receiver;
    
    SourceType = TypeOf(Source);
    If SourceType = Type("Structure") Then
        Receiver = CopyStructure(Source);
    ElsIf SourceType = Type("Map") Then
        Receiver = CopyMap(Source);
    ElsIf SourceType = Type("Array") Then
        Receiver = CopyArray(Source);
    ElsIf SourceType = Type("ValueList") Then
        Receiver = CopyValueList(Source);
    #If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
    ElsIf SourceType = Type("ValueTable") Then
        Receiver = Source.Copy();
    #EndIf
    Else
        Receiver = Source;
    EndIf;
    
    Return Receiver;
    
EndFunction // CopyRecursive()

// Creates copy of the Structure value type.
// 
// Parameters:
//  SourceStructure - Structure - copied structure.
// 
// Returns:
//  Structure - copy of the source structure.
//
Function CopyStructure(SourceStructure) Export
    
    ResultStructure = New Structure;
    
    For Each KeyAndValue In SourceStructure Do
        ResultStructure.Insert(KeyAndValue.Key, CopyRecursive(KeyAndValue.Value));
    EndDo;
    
    Return ResultStructure;
    
EndFunction // CopyStructure()

// Creates value copy of the Match type.
// 
// Parameters:
//  SourceMap - Map - copied map.
// 
// Returns:
//  Map - copy of the source match.
//
Function CopyMap(SourceMap) Export
    
    ResultMap = New Map;
    
    For Each KeyAndValue In SourceMap Do
        ResultMap.Insert(KeyAndValue.Key, CopyRecursive(KeyAndValue.Value));
    EndDo;
    
    Return ResultMap;
    
EndFunction // CopyMap() 

// Creates the value copy of the Array type.
// 
// Parameters:
//  ArraySource - Array - copied array.
// 
// Returns:
//  Array - copy of the source array.
//
Function CopyArray(ArraySource) Export
    
    ResultArray = New Array;
    
    For Each Item In ArraySource Do
        ResultArray.Add(CopyRecursive(Item));
    EndDo;
    
    Return ResultArray;
    
EndFunction // CopyArray()

// Create the value copy of the ValuesList type.
// 
// Parameters:
//  SourceList - ValueList - copied values list.
// 
// Returns:
//  ValueList - copy of the source values list.
//
Function CopyValueList(SourceList) Export
    
    ResultList = New ValueList;
    
    For Each ItemOfList In SourceList Do
        ResultList.Add(CopyRecursive(ItemOfList.Value), 
            ItemOfList.Presentation, 
            ItemOfList.Check, 
            ItemOfList.Picture);
    EndDo;
    
    Return ResultList;
    
EndFunction // CopyValueList() 

// Create the value copy of the TypeDescription type.
// 
// Parameters:
//  SourceTypeDescription - TypeDescription - copied description of type.
//  AddedTypes            - Array, String   - array of Type values consisting 
//                      of types that will be used in the object, or a string 
//                      containing values of type names, separated by commas. 
//                        - TypeDescription - description of types. 
//  RemovedTypes          - Array, String   - array of Type type values 
//                      consisting of types that will be removed from the source
//                      description set as the first parameter.
//                        - TypeDescription -  description of types.
// 
// Returns:
//  TypeDescription - copy of the source description of type.
//
Function CopyTypeDescription(SourceTypeDescription, AddedTypes = Undefined, 
    RemovedTypes = Undefined) Export
    
    Add = Undefined;
    If TypeOf(AddedTypes) = Type("TypeDescription") Then
        Add = AddedTypes.Types();
    Else
        Add = AddedTypes;   
    EndIf;
    
    Remove = Undefined;
    If TypeOf(RemovedTypes) = Type("TypeDescription") Then
        Remove = RemovedTypes.Types();
    Else
        Remove = RemovedTypes;   
    EndIf;
    
    Return New TypeDescription(SourceTypeDescription, Add, Remove);
    
EndFunction // CopyTypeDescription()

// Checks whether an transferred attribute name is the attribute of the object.
//
// Parameters:
//  Object        - Arbitrary - object for which it is necessary to check the 
//                              attribute name.
//  AttributeName - String    - attribute name to be checked.
//
// Returns:
//  Boolean - True if the attribute name is included in the subset of the 
//            object attributes. Otherwise - False.
//
Function IsObjectAttribute(Object, AttributeName) Export

    UniquenessKey = New UUID;
    AttributeStructure = New Structure(AttributeName, UniquenessKey);
    FillPropertyValues(AttributeStructure, Object);
    Return AttributeStructure[AttributeName] <> UniquenessKey;

EndFunction // IsObjectAttribute()

#Region StringOperations

// Removes insignificant characters to the left of the first significant 
// character and trailing spaces to the right of the last significant character
// in a string.
//
// Parameters:
//  String - String - source line. 
//
// Returns:
//  String - string after trailing spaces removing. 
//
Function Trim(String) Export
    
    Return TrimAll(String);    
    
EndFunction // TrimAll()

// Checks if variable name is correct.
//
// Parameters:
//  VariableName - String - variable name.
//
// Returns:
//  Boolean - check result.
//
Function IsCorrectVariableName(VariableName) Export
    
    If (IsBlankString(VariableName)) Then
        Return False;    
    EndIf;
        
    For Position = 1 To StrLen(VariableName) Do 
        
        Character = Mid(VariableName, Position, 1);
        If Character = "_" Then
            Continue;    
        EndIf;
        
        If Position = 1 И IsNumber(Character) Then
            Return False;    
        EndIf;
        
        If IsSpecialSymbol(Character) Then
            Return False;    
        EndIf;
                
    EndDo;
    
    Return True;    
    
EndFunction // IsCorrectVariableName()

// Check if a character is a special symbol.
//
// Parameters:
//  Character - String - character to be checked.
//
// Returns:
//  Boolean - True if a character is a special symbol; False in other case.
//
Function IsSpecialSymbol(Character) Export
    
    Return ?(IsNumber(Character) 
          OR IsLetter(Character), False, True);
    
EndFunction // IsSpecialSymbol()

// Check if a character is a number.
//
// Parameters:
//  Character - String - character to be checked.
//
// Returns:
//  Boolean - True if a character is a number; False in other case.
//
Function IsNumber(Character) Export
    
    // Value corresponds to 0.
    FirstNumber = 47;
    
    // Value corresponds to 9.
    LastNumber = 58;
    
    Code = CharCode(Character);
    Return ?(Code <= FirstNumber OR Code >= LastNumber, False, True);
    
EndFunction // IsNumber()

// Check if a character is a letter.
//
// Parameters:
//  Character - String - character to be checked.
//
// Returns:
//  Boolean - True if a character is a letter; False in other case.
//
Function IsLetter(Character) Export
    
    Return ?(IsLatinLetter(Character) 
          OR IsCyrillicLetter(Character), True, False);
    
EndFunction // IsLetter()

// Check if a character is a latin letter.
//
// Parameters:
//  Character - String - character to be checked.
//
// Returns:
//  Boolean - True if a character is a latin letter; False in other case.
//
Function IsLatinLetter(Character) Export
    
    // Value corresponds to a.
    FirstLowLetter = 97;
    
    // Value corresponds to z.
    LastLowLetter = 122;
    
    // Value corresponds to A.
    FirstUpperLetter = 65;
    
    // Value corresponds to Z.
    LastUpperLetter = 90;
    
    Code = CharCode(Character);
    Return ?((Code >= FirstUpperLetter AND Code <= LastUpperLetter) 
          OR (Code >= FirstLowLetter   AND Code <= LastLowLetter), True, False);
    
EndFunction // IsLatinLetter() 

// Check if a character is a cyrillic letter.
//
// Parameters:
//  Character - String - character to be checked.
//
// Returns:
//  Boolean - True if a character is a cyrillic letter; False in other case.
//
Function IsCyrillicLetter(Character) Export
    
    // Value corresponds to А.
    FirstUpperLetter = 1040;
    
    // Value corresponds to ы.
    LastLowLetter = 1103;
    
    Code = CharCode(Character);
    Return ?(Code >= FirstUpperLetter AND Code <= LastLowLetter, True, False);
    
EndFunction // IsCyrillicLetter()

#EndRegion // StringOperations

#Region ValueTreeOperations 

// Handles three state checkbox in the FormDataTree object.
//
// Parameters:
//  TreeItem  - FormDataTreeItem - form data tree item.
//  FieldName - String           - the column name.
//
Procedure HandleThreeStateCheckBox(TreeItem, FieldName) Export
    
    // Third state checkbox value.
    ThirdState = 2;
    
    CurrentData = TreeItem;
    If CurrentData <> Undefined Then
        
        If CurrentData[FieldName] = ThirdState Then
            CurrentData[FieldName] = 0;    
        EndIf;
        
        SetValueOfThreeStateCheckBox(CurrentData, FieldName);
        
        Parent = CurrentData.GetParent();
        While Parent <> Undefined Do
            
            If ChangeParentValueOfThreeStateCheckBox(CurrentData, FieldName) Then
                Parent[FieldName] = CurrentData[FieldName];
            Else
                Parent[FieldName] = ThirdState;    
            EndIf;    
            
            CurrentData = Parent;
            Parent = Parent.GetParent();
            
        EndDo;
                
    EndIf;
    
EndProcedure // HandleThreeStateCheckBox()

#EndRegion // ValueTreeOperations

// Dissembles URI string and returns it as a structure.
// Based on RFC 3986.
//
// Parameters:
//  StringURI - String - reference to the resource in the format:
//                          <schema>://<login>:<password>@<host>:<port>/<path>?<parameters>#<anchor>.
//
// Returns:
//  Structure - with keys:
//      * Schema       - String - schema.
//      * Login        - String - user login.
//      * Password     - String - user password.
//      * ServerName   - String - part <host>:<port> from the StringURI.
//      * Host         - String - host name.
//      * Port         - Number - port number.
//      * PathOnServer - String - part <path >?<parameters>#<anchor> from the StringURI.
//      * Parameters   - Map    - parsed parameters from the StringURI. 
//
Function URIStructure(Val StringURI) Export

    StringURI = TrimAll(StringURI);
    
    URIComponents = NewURIComponents();
    URIComponents.Schema = URISchema(StringURI);
    URIComponents.PathOnServer = URIPathOnServer(StringURI);
    URIComponents.Parameters = URIParameters(URIComponents.PathOnServer);
    URIComponents.ServerName = URIServerName(StringURI);
    URIComponents.Login = URILogin(StringURI);
    URIComponents.Password = URIPassword(StringURI);
    URIComponents.Host = URIHost(URIComponents.ServerName);
    URIComponents.Port = URIPort(URIComponents.Schema, 
        URIComponents.ServerName);

    Return URIComponents;
    
EndFunction // URIStructure()

// Assembles URI string and returns it.
// Based on RFC 3986.
//
// Parameters:
//  URIStructure - Structure - uri structure.
//      * Schema       - String - schema.
//      * Login        - String - user login.
//      * Password     - String - user password.
//      * ServerName   - String - part <host>:<port> from the StringURI.
//      * Host         - String - host name.
//      * Port         - Number - port number.
//      * PathOnServer - String - part <path >?<parameters>#<anchor> from the StringURI.
//      * Parameters   - Map    - parsed parameters from the StringURI.
//
// Returns:
//  StringURI - String - reference to the resource in the format:
//                          <schema>://<login>:<password>@<host>:<port>/<path>?<parameters>#<anchor>. 
//
Function StringURI(Val URIStructure) Export

    TemplateURI = "%1://%2:%3@%4/%5";
    Return StrTemplate(TemplateURI, 
        URIStructure.Schema,
        URIStructure.Login,
        URIStructure.Password,
        URIStructure.ServerName,
        URIStructure.PathOnServer);
    
EndFunction // StringURI()
    
#EndRegion // ProgramInterface

#Region ServiceProceduresAndFunctions

#Region ValueTreeOperations

// Only for internal use.
//
Procedure SetValueOfThreeStateCheckBox(CurrentData, FieldName)

    TreeItems = CurrentData.GetItems();
    For Each TreeItem In TreeItems Do
        TreeItem[FieldName] = CurrentData[FieldName];
        SetValueOfThreeStateCheckBox(TreeItem, FieldName);
    EndDo;

EndProcedure // SetValueOfThreeStateCheckBox()

// Only for internal use.
//
Function ChangeParentValueOfThreeStateCheckBox(CurrentData, FieldName)

    TreeItems = CurrentData.GetParent().GetItems();
    For Each TreeItem In TreeItems Do
        If TreeItem[FieldName] <> CurrentData[FieldName] Then
            Return False;
        EndIf;
    EndDo;
    
    Return True;

EndFunction // ChangeParentValueOfThreeStateCheckBox()

#EndRegion // ValueTreeOperations

// Only for internal use.
//
Function URISchema(StringURI, Substring = "://")
    
    Schema = "";
    SubstringLen = StrLen(Substring);
    
    Position = StrFind(StringURI, Substring);
    If Position > 0 Then
        Schema = Lower(Left(StringURI, Position - 1));
        StringURI = Mid(StringURI, Position + SubstringLen);
    EndIf;
    
    Return Schema;
    
EndFunction // URISchema()

// Only for internal use.
//
Function URIPathOnServer(StringURI)
        
    PathOnServer = "";
    
    Position = StrFind(StringURI, "/");
    If Position > 0 Then
        PathOnServer = Mid(StringURI, Position + 1);
        StringURI = Left(StringURI, Position - 1);
    EndIf;
    
    Return PathOnServer;
    
EndFunction // PathOnServer()

// Only for internal use.
//
Function URIParameters(PathOnServer)
        
    Parameters = New Map;
    
    Position = StrFind(PathOnServer, "?");
    If Position > 0 Then
        ParametersString = Mid(PathOnServer, Position + 1);        
        ParametersArray = StrSplit(ParametersString, "&");
        For Each Parameter In ParametersArray Do
            Position = StrFind(Parameter, "=");
            If Position > 1 Then
                Parameters.Insert(Left(Parameter, Position - 1), 
                    Mid(Parameter, Position + 1));    
            EndIf;    
        EndDo;
    EndIf;
    
    Return Parameters;
    
EndFunction // URIParameters()

// Only for internal use.
//
Function URIServerName(StringURI)
    
    ServerName = StringURI;
    
    Position = StrFind(StringURI, "@");
    If Position > 0 Then
        ServerName = Mid(StringURI, Position + 1);
        StringURI = Left(StringURI, Position - 1);
    Else
        StringURI = "";    
    EndIf;
    
    Return ServerName;
    
EndFunction // URIServerName()

// Only for internal use.
//
Function URILogin(StringURI)
        
    Login = StringURI;
    
    Position = StrFind(StringURI, ":");
    If Position > 0 Then
        Login = Left(StringURI, Position - 1);
    EndIf;

    Return Login;
    
EndFunction // URILogin()

// Only for internal use.
//
Function URIPassword(StringURI)
    
    Password = "";
    
    Position = StrFind(StringURI, ":");
    If Position > 0 Then
        Password = Mid(StringURI, Position + 1);
    EndIf;

    Return Password;
    
EndFunction // URIPassword()

// Only for internal use.
//
Function URIHost(ServerName)
    
    Host = ServerName;
    
    Position = StrFind(ServerName, ":");
    If Position > 0 Then
       Host = Left(ServerName, Position - 1);
    EndIf;
    
    Return Host;
  
EndFunction // URIHost()

// Only for internal use.
//
Function URIPort(Schema, ServerName)
    
    Port = Undefined;
    
    Position = StrFind(ServerName, ":");
    If Position > 0 Then
        
        Port = Mid(ServerName, Position + 1);
        For Index = 1 To StrLen(Port) Do
            Symbol = Mid(Port, Index, 1);
            If NOT IsNumber(Symbol) Then
                Port = Undefined;
                Break;    
            EndIf;
            
        EndDo;
        
    EndIf;

    If Port = Undefined Then
        If Schema = "http" Then
            Port = 80;
        ElsIf Schema = "https" Then
            Port = 443;
        EndIf;
    Else
        Port = Number(Port);    
    EndIf;
    
    Return Port;
    
EndFunction // URIPort()

// Only for internal use.
//
Function NewURIComponents()
    
    URIComponents = New Structure;
    URIComponents.Insert("Schema");
    URIComponents.Insert("Login");
    URIComponents.Insert("Password");
    URIComponents.Insert("ServerName");
    URIComponents.Insert("Host");
    URIComponents.Insert("Port");
    URIComponents.Insert("PathOnServer");
    URIComponents.Insert("Parameters");
    
    Return URIComponents;
    
EndFunction // NewURIComponents() 

#EndRegion // ServiceProceduresAndFunctions