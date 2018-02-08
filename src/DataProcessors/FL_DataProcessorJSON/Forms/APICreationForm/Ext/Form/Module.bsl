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
// along with this program. If not, see <http://www.gnu.org/licenses/agpl-3.0>.
//
////////////////////////////////////////////////////////////////////////////////

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
        CurrentData.RowPicture = RowPictureNumber(CurrentData.Type);
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
        
        If IsStructuredType(CurrentData.Type)
          AND NOT IsStructuredType(SelectedValue) Then
          
            APISchemaItems = CurrentData.GetItems();        
            If APISchemaItems.Count() > 0 Then
                
                APISchemaItems.Clear();
                
                Explanation = StrTemplate(
                    NStr("en='The new type {%1} cannot have nested items. Nested items have just been cleared.';
                        |ru='Новый тип {%1} не может иметь вложенные элементы. Вложенные элементы были удалены.';
                        |en_CA='The new type {%1} cannot have nested items. Nested items have just been cleared.'"), 
                    SelectedValue);
                
                ShowUserNotification(Title, , Explanation, 
                    PictureLib.FL_Logotype64);
                                
            EndIf;
            
        EndIf;
                    
    EndIf;
    
EndProcedure // APISchemaTypeChoiceProcessing()

#EndRegion // FormItemsEventHandlers

#Region FormCommandHandlers

&AtClient
Procedure LoadSample(Command)
    
    If Object.APISchema.GetItems().Count() > 0 Then
        
        ShowQueryBox(New NotifyDescription("DoAfterChooseSampleToLoad", 
                ThisObject),
            NStr("en='The existing API schema description will be erased, continue loading sample?';
                |ru='Существующее описание схемы API будет стерто, продолжить загрузку образца?';
                |en_CA='The existing API schema description will be erased, continue loading sample?'"),
            QuestionDialogMode.OKCancel, 
            , 
            DialogReturnCode.Cancel);
            
    Else
        DoAfterChooseSampleToLoad(DialogReturnCode.OK, Undefined);
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
Procedure AddObjectItem(Command)
    
    AddRowToAPISchema("Object");
    
EndProcedure // AddObjectItem()

&AtClient
Procedure AddArrayItem(Command)
    
    AddRowToAPISchema("Array");
    
EndProcedure // AddArrayItem()

&AtClient
Procedure AddStringItem(Command)
    
    AddRowToAPISchema("String");
    
EndProcedure // AddStringItem()

&AtClient
Procedure AddNumberItem(Command)
    
    AddRowToAPISchema("Number");
    
EndProcedure // AddNumberItem() 

&AtClient
Procedure AddBooleanItem(Command)
    
    AddRowToAPISchema("Boolean");
    
EndProcedure // AddBooleanItem()

&AtClient
Procedure AddNullItem(Command)
    
    AddRowToAPISchema("Null");
    
EndProcedure // AddNullItem() 

&AtClient
Procedure AddRowAPITable(Command)
    
    AddRowToAPISchema("");
    
EndProcedure // AddRowToAPITable()

&AtClient
Procedure DeleteRowAPITable(Command)
    
    CurrentData = Items.APISchema.CurrentData;
    If CurrentData <> Undefined Then
    
        ShowQueryBox(New NotifyDescription("DoAfterChooseRowToDelete", 
            ThisObject, 
            New Structure("Identifier ", CurrentData.GetID())),
            NStr("en='Delete the selected row?';
                |ru='Удалить выбранную строку?';
                |en_CA='Delete the selected row?'"),
            QuestionDialogMode.YesNo, 
            , 
            DialogReturnCode.No);
            
    EndIf;
    
EndProcedure // DeleteRowAPITable()

#EndRegion // FormCommandHandlers

#Region ServiceProceduresAndFunctions

// Shows an input string dialog if user has clicked «OK» button.
//
// Parameters:
//  QuestionResult       - DialogReturnCode - system enumeration value 
//                  or a value related to a clicked button. If a dialog 
//                  is closed on timeout, the value is Timeout. 
//  AdditionalParameters - Arbitrary        - the value specified when the 
//                              NotifyDescription object was created.
//
&AtClient
Procedure DoAfterChooseSampleToLoad(QuestionResult, AdditionalParameters) Export
    
    If QuestionResult = DialogReturnCode.OK Then
        
        ShowInputString(New NotifyDescription("DoAfterInputStringSample", 
                ThisObject),
            ,
            NStr("en='Insert JSON format sample';
                |ru='Вставьте образец формата JSON';
                |en_CA='Insert JSON format sample'"),
            ,
            True);
                
    EndIf;
    
EndProcedure // DoAfterChooseSampleToLoad()

// Procedure that will be called after the string entry window is closed.
//
// String               - String, Undefined - the entered string value or 
//                              undefined if the user has not entered anything. 
// AdditionalParameters - Arbitrary         - the value specified when the 
//                              NotifyDescription object was created.
//
&AtClient
Procedure DoAfterInputStringSample(String, AdditionalParameters) Export
    
    If String <> Undefined AND TypeOf(String) = Type("String") Then
        
        LoadSampleAtServer(String);
        APISchemaItems = Object.APISchema.GetItems();
        If APISchemaItems.Count() > 0 Then
            Items.APISchema.Expand(APISchemaItems.Get(0).GetID(), True);
        EndIf;
        
    EndIf;
    
EndProcedure // DoAfterInputStringSample()

// Deletes the selected row if user has clicked «OK» button.
//
// Parameters:
//  QuestionResult       - DialogReturnCode - system enumeration value 
//                  or a value related to a clicked button. If a dialog 
//                  is closed on timeout, the value is Timeout. 
//  AdditionalParameters - Arbitrary        - the value specified when the 
//                              NotifyDescription object was created.
//
&AtClient
Procedure DoAfterChooseRowToDelete(QuestionResult, AdditionalParameters) Export
    
    Var Identifier;
    
    If QuestionResult = DialogReturnCode.Yes
        AND TypeOf(AdditionalParameters) = Type("Structure")
        AND AdditionalParameters.Property("Identifier", Identifier) Then
            
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
    
EndProcedure // DoAfterChooseRowToDelete()

// Only for internal use.
//
&AtClient
Procedure AddRowToAPISchema(Type)
    
    CurrentData = Items.APISchema.CurrentData;
    If CurrentData = Undefined Then
        
        If Object.APISchema.GetItems().Count() = 0 Then 
            
            NewItem = NewAPISchemaRow(Object.APISchema.GetItems(), "RootItem", 
                Type);
            NewItem.StructuredType = IsStructuredType(Type);
            
            // Set focus on root item.
            Items.APISchema.CurrentRow = NewItem.GetID();
            
        Else
            
            Explanation = NStr("en='Failed to add another root item. The root item already exists.';
                |ru='Не удалось добавить еще один корневой элемент. Корневой элемент уже существует';
                |en_CA='Failed to add another root item. The root item already exists.'");
                
            ShowUserNotification(Title, , Explanation, 
                PictureLib.FL_Logotype64);  
            
        EndIf;  
        
    Else
                
        If IsBlankString(CurrentData.Type) Then 
            
            Explanation = NStr("en='Failed to add new item. Type is empty.';
                |ru='Не удалось добавить новый элемент. Тип не заполнен.';
                |en_CA='Failed to add new item. Type is empty.'");

            ShowUserNotification(Title, , Explanation, 
                PictureLib.FL_Logotype64);
            
            Return;
            
        EndIf;
        
        If Not IsStructuredType(CurrentData.Type) Then
         
            Explanation = NStr("en='Failed to add new item. Type can not have nested items.';
                |ru='Не удалось добавить новый элемент. Тип не может иметь вложенных элементов.';
                |en_CA='Failed to add new item. Type can not have nested items.'");

            ShowUserNotification(Title, , Explanation, 
                PictureLib.FL_Logotype64);
            
        Else
            
            CurrentId = CurrentData.GetId();
            Parent = Object.APISchema.FindByID(CurrentId);
            
            NewItem = NewAPISchemaRow(Parent.GetItems(), "", Type);
            NewItem.StructuredType = IsStructuredType(Type);
                        
            If Not Items.APISchema.Expanded(CurrentId) Then
                Items.APISchema.Expand(CurrentId);    
            EndIf;    
          
        EndIf; 
                
    EndIf;    
    
EndProcedure // AddRowToAPISchema()

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
        
        ErrorMessage = StrTemplate(NStr("en='Error: Failed to read JSON sample. %1.';
            |ru='Ошибка: Не удалось прочитать JSON образец. %1.';
            |en_CA='Error: Failed to read JSON sample. %1.'"),
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
    FillCheckAPISchema(ValueTree.Rows); 
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
        
        ObjectRows = NewAPISchemaRow(Rows, Name, "Object");
        ObjectRows.StructuredType = True;
        For Each Item In SampleResult Do
            FillAPISchema(ObjectRows.Rows, Item.Key, Item.Value);             
        EndDo;
        
    ElsIf TypeOf(SampleResult) = Type("Array") Then
        
        ObjectRows = NewAPISchemaRow(Rows, Name, "Array");
        ObjectRows.StructuredType = True;
        For Each Item In SampleResult Do
            FillAPISchema(ObjectRows.Rows, "ArrayItem", Item);             
        EndDo;
        
    ElsIf TypeOf(SampleResult) = Type("String") Then
        NewAPISchemaRow(Rows, Name, "String");
    ElsIf TypeOf(SampleResult) = Type("Number") Then
        NewAPISchemaRow(Rows, Name, "Number");
    ElsIf TypeOf(SampleResult) = Type("Boolean") Then
        NewAPISchemaRow(Rows, Name, "Boolean");
    Else
        NewAPISchemaRow(Rows, Name, "Null");    
    EndIf;    
    
EndProcedure // FillAPISchema() 

// Only for internal use.
//
&AtServerNoContext
Procedure FillCheckAPISchema(Rows)
    
    For Each Row In Rows Do
        
        If IsBlankString(Row.Name) OR IsBlankString(Row.Type) Then
            
            ErrorMessage = NStr("en='Content type or field name is empty. Cannot save API schema.';
                |ru='Тип или имя поля не заданы. Невозможно сохранить схему API.';
                |en_CA='Content type or field name is empty. Cannot save API schema.'");
            
            Raise ErrorMessage;
            
        EndIf;
        
        If Row.Rows.Count() > 0 Then
            FillCheckAPISchema(Row.Rows);        
        EndIf;
        
    EndDo;
    
EndProcedure // FillCheckAPISchema()

// Only for internal use.
//
&AtClientAtServerNoContext
Function RowPictureNumber(Type)
    
    If Type = "String" Then
        Number = 1;   
    ElsIf Type = "Boolean" Then
        Number = 2;    
    ElsIf Type = "Number" Then
        Number = 3;
    ElsIf Type = "Null" Then
        Number = 4;
    ElsIf Type = "Object" Then
        Number = 5;
    ElsIf Type = "Array" Then
        Number = 6; 
    Else
        Number = 0;    
    EndIf;
    
    Return Number;

EndFunction // RowPictureNumber()
    
// Only for internal use.
//
&AtClientAtServerNoContext
Function NewAPISchemaRow(Rows, Name, Type)
    
    NewRow = Rows.Add();
    NewRow.Name = Name;
    NewRow.Type = Type;
    NewRow.RowPicture = RowPictureNumber(Type);    
    Return NewRow;
    
EndFunction // NewAPISchemaRow()

#EndRegion // ServiceProceduresAndFunctions