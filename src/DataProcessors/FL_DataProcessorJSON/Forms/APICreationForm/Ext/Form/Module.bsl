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

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
    
    Var APISchemaAddress;
    
    MainObject = FormAttributeToValue("Object");
    Items.APISchemaType.ChoiceList.LoadValues(
        MainObject.SupportedTypes().UnloadValues());
        
    If Parameters.Property("APISchemaAddress", APISchemaAddress) Then
        If IsTempStorageURL(APISchemaAddress) Then
            
            ValueTree = GetFromTempStorage(APISchemaAddress);
            If TypeOf(ValueTree) = Type("ValueTree") Then
                ValueToFormAttribute(ValueTree, "Object.APISchema");        
            EndIf;
            
        EndIf;
    EndIf;
    
EndProcedure // OnCreateAtServer()

#EndRegion // FormEventHandlers

#Region FormItemsEventHandlers

&AtClient
Procedure APISchemaTurnedOffOnChange(Item)
    
    FL_CommonUseClientServer.HandleThreeStateCheckBox(
        Items.APISchema.CurrentData, "TurnedOff");
     
EndProcedure // APISchemaTurnedOffOnChange()

&AtClient
Procedure APISchemaNameOnChange(Item)
    
    CurrentData = Items.APISchema.CurrentData;
    If CurrentData <> Undefined Then
        CurrentData.Name = TrimAll(CurrentData.Name);        
    EndIf;
    
EndProcedure // APISchemaNameOnChange()

&AtClient
Procedure APISchemaTypeOnChange(Item)
    
    CurrentData = Items.APISchema.CurrentData;
    If CurrentData <> Undefined Then
        CurrentData.StructuredType = IsStructuredType(CurrentData.Type);        
    EndIf;
    
EndProcedure // APISchemaTypeOnChange()

&AtClient
Procedure APISchemaTypeChoiceProcessing(Item, SelectedValue, StandardProcessing)
    
    CurrentData = Items.APISchema.CurrentData;
    If CurrentData <> Undefined Then
        
        If IsBlankString(CurrentData.Type) Then  
            Return;
        EndIf;
        
        If IsStructuredType(CurrentData.Type) = True
          And IsStructuredType(SelectedValue) = False Then
          
            CurrentData.GetItems().Clear();        
            Message = StrTemplate(
                NStr(
                    "en = 'The new type ''%1'' cannot have nested items. Nested items have just been cleared.';
                    |ru = 'Новый тип ''%1'' не может иметь вложенные элементы. Вложенные элементы были удалены.'"), 
                SelectedValue);
                
            FL_CommonUseClientServer.NotifyUser(Message);  
            
        EndIf;
                    
    EndIf;
    
EndProcedure // APISchemaTypeChoiceProcessing()

#EndRegion // FormItemsEventHandlers

#Region FormCommandHandlers

&AtClient
Procedure LoadSample(Command)
    
    If Object.APISchema.GetItems().Count() > 0 Then
        
        ShowQueryBox(New NotifyDescription("DoAfterChooseLoadSample", 
                ThisObject),
            NStr("en = 'The existing API schema description will be erased, continue loading sample?';
                 |ru = 'Существующее описание схемы API будет стерто, продолжить загрузку образца?'"),
            QuestionDialogMode.OKCancel, 
            , 
            DialogReturnCode.Cancel);
            
    Else
        DoAfterChooseLoadSample(DialogReturnCode.OK, Undefined);
    EndIf;
    
EndProcedure // LoadSample() 

&AtClient
Procedure SaveAndClose(Command)
    
    If Object.APISchema.GetItems().Count() > 0 Then
        Close(PutValueTreeToTempStorage(ThisObject.FormOwner.UUID));
    Else
        Close("");    
    EndIf;
    
EndProcedure // SaveAndClose()


&AtClient
Procedure AddRowAPITable(Command)
    
    CurrentData = Items.APISchema.CurrentData;
    If CurrentData = Undefined Then
        
        If Object.APISchema.GetItems().Count() = 0 Then 
            
            NewItem = Object.APISchema.GetItems().Add();
            NewItem.Name = "RootItem";
            NewItem.RowPicture = False;
            
            // Set focus on root item.
            Items.APISchema.CurrentRow = NewItem.GetID();
            
        Else
            
            ErrorMessage = NStr(
                "en = 'Failed to add another root item. The root item already exists.';
                |ru = 'Не удалось добавить еще один корневой элемент. Корневой элемент уже существует'");
                
            FL_CommonUseClientServer.NotifyUser(ErrorMessage);  
            
        EndIf;  
        
    Else
        
        If IsBlankString(CurrentData.Name) Then 
            
            ErrorMessage = NStr(
                "en = 'Failed to add new item. Field name is empty.';
                |ru = 'Не удалось добавить новый элемент. Имя поля не заполнено.'");

            FL_CommonUseClientServer.NotifyUser(ErrorMessage, , 
                "Object.APISchema[" + CurrentData.GetId() + "].Name");
            
            Return;
            
        EndIf;
        
        If IsBlankString(CurrentData.Type) Then 
            
            ErrorMessage = NStr(
                "en = 'Failed to add new item. Type is empty.';
                |ru = 'Не удалось добавить новый элемент. Тип не заполнен.'");

            FL_CommonUseClientServer.NotifyUser(ErrorMessage, , 
                "Object.APISchema[" + CurrentData.GetId() + "].Type");
            
            Return;
            
        EndIf;
        
        If Not IsStructuredType(CurrentData.Type) Then
         
            ErrorMessage = NStr(
                "en = 'Failed to add new item. Type can not have nested items.';
                |ru = 'Не удалось добавить новый элемент. Тип не может иметь вложенных элементов.'");

            FL_CommonUseClientServer.NotifyUser(ErrorMessage, , 
                "Object.APISchema[" + CurrentData.GetId() + "].Type");
            
            Return;
            
        Else
            
            CurrentId = CurrentData.GetId();
            Parent = Object.APISchema.FindByID(CurrentId);
            
            NewItem = Parent.GetItems().Add();
            NewItem.RowPicture = True;
            
            If CurrentData.Type = "Array" Then
                NewItem.Name = "ArrayItem";    
            EndIf;
            
            If Not Items.APISchema.Expanded(CurrentId) Then
                Items.APISchema.Expand(CurrentId);    
            EndIf;    
          
        EndIf; 
                
    EndIf;
    
EndProcedure // AddRowToAPITable()

&AtClient
Procedure DeleteRowAPITable(Command)
    
    CurrentData = Items.APISchema.CurrentData;
    If CurrentData <> Undefined Then
    
        ShowQueryBox(New NotifyDescription("DoAfterChooseRowToDelete", 
            ThisObject, 
            New Structure("Identifier ", CurrentData.GetID())),
            NStr("en = 'Delete the selected row?';
                 |ru = 'Удалить выбранную строку?'"),
            QuestionDialogMode.YesNo, 
            , 
            DialogReturnCode.No);
            
    EndIf;
    
EndProcedure // DeleteRowAPITable()

#EndRegion // FormCommandHandlers

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
&AtClient
Procedure DoAfterChooseLoadSample(QuestionResult, AdditionalParameters) Export
    
    If QuestionResult = DialogReturnCode.OK Then
        
        ShowInputString(New NotifyDescription("DoAfterInputStringSample", 
                ThisObject),
            ,
            NStr("en = 'Insert JSON format sample'; 
                 |ru = 'Вставьте образец формата JSON'"),
            ,
            True);
                
    EndIf;
    
EndProcedure // DoAfterChooseLoadSample()

// Only for internal use.
//
&AtClient
Procedure DoAfterInputStringSample(String, AdditionalParameters) Export
    
    If String <> Undefined And TypeOf(String) = Type("String") Then
        
        LoadSampleAtServer(String);
        APISchemaItems = Object.APISchema.GetItems();
        If APISchemaItems.Count() > 0 Then
            Items.APISchema.Expand(APISchemaItems.Get(0).GetID(), True);
        EndIf;
        
    EndIf;
    
EndProcedure // DoAfterInputStringSample()


// Only for internal use.
//
&AtClient
Procedure DoAfterChooseRowToDelete(QuestionResult, 
    AdditionalParameters) Export
    
    Var Identifier;
    
    If QuestionResult = DialogReturnCode.Yes Then
        If TypeOf(AdditionalParameters) = Type("Structure")
            And AdditionalParameters.Property("Identifier", Identifier) Then
            
            SearchResult = Object.APISchema.FindByID(Identifier);
            If SearchResult <> Undefined Then
                TreeItem = SearchResult.GetParent();
                If TreeItem = Undefined Then
                    TreeItem = Object.APISchema;             
                EndIf;
                TreeItem.GetItems().Delete(SearchResult);
                Modified = True;     
            EndIf;
                        
        EndIf; 
    EndIf;
    
EndProcedure // DoAfterChooseRowToDelete()



// Only for internal use.
//
&AtServer
Procedure LoadSampleAtServer(String)
    
    JSONReader = New JSONReader;
    JSONReader.SetString(String);
    Try
        SampleResult = ReadJSON(JSONReader, True);
        JSONReader.Close();
    Except
        
        ErrorMessage = StrTemplate(NStr(
                "en = 'Error: Failed to read JSON sample. %1.';
                |ru = 'Ошибка: Не удалось прочитать JSON образец. %1.'"),
            ErrorDescription());  
        Raise ErrorMessage;
        
    EndTry;
    
    ValueTree = FormAttributeToValue("Object.APISchema", Type("ValueTree"));
    ValueTree.Rows.Clear();
    
    FillAPISchema(ValueTree.Rows, "RootItem", SampleResult);
    
    ValueToFormAttribute(ValueTree, "Object.APISchema");
    
EndProcedure // LoadSampleAtServer()



// Only for internal use.
//
&AtServer
Function PutValueTreeToTempStorage(Val OwnerUUID)
    
    ValueTree = FormAttributeToValue("Object.APISchema", Type("ValueTree"));
    Return PutToTempStorage(ValueTree, OwnerUUID);
    
EndFunction // PutValueTreeToTempStorage()

// Checks if the type is a structured type.
//
// Parameters:
//  TypeName - String - type name.
//
// Returns:
//   Boolean - True if this type is a structured type; False in other case.
//
&AtServer
Function IsStructuredType(TypeName)

    MainObject = FormAttributeToValue("Object");
    Return MainObject.IsStructuredType(TypeName);

EndFunction // IsStructuredType() 



// Only for internal use.
//
&AtServerNoContext
Procedure FillAPISchema(Rows, Name, SampleResult)
    
    If TypeOf(SampleResult) = Type("Map") Then
        
        ObjectRows = AddRowToAPISchema(Rows, Name, "Object");
        For Each Item In SampleResult Do
            FillAPISchema(ObjectRows.Rows, Item.Key, Item.Value);             
        EndDo;
        
    ElsIf TypeOf(SampleResult) = Type("Array") Then
        
        ObjectRows = AddRowToAPISchema(Rows, Name, "Array");
        For Each Item In SampleResult Do
            FillAPISchema(ObjectRows.Rows, "ArrayItem", Item);             
        EndDo;
        
    ElsIf TypeOf(SampleResult) = Type("String") Then
        AddRowToAPISchema(Rows, Name, "String");
    ElsIf TypeOf(SampleResult) = Type("Number") Then
        AddRowToAPISchema(Rows, Name, "Number");
    ElsIf TypeOf(SampleResult) = Type("Boolean") Then
        AddRowToAPISchema(Rows, Name, "Boolean");
    Else
        AddRowToAPISchema(Rows, Name, "Null");    
    EndIf;    
    
EndProcedure // FillAPISchema() 


// Only for internal use.
//
&AtServerNoContext
Function AddRowToAPISchema(Rows, Name, Type)
    
    NewRow = Rows.Add();
    NewRow.Name = Name;
    NewRow.Type = Type;
    Return NewRow;
    
EndFunction // AddRowToAPISchema() 

#EndRegion // ServiceProceduresAndFunctions