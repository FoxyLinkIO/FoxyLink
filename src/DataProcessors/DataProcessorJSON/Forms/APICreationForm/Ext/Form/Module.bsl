////////////////////////////////////////////////////////////////////////////////
// This file is part of IHL (Integration happiness library).
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
    Items.APIDefinitionType.ChoiceList.LoadValues(
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
Procedure APISchemaTypeChoiceProcessing(Item, SelectedValue, StandardProcessing)
    
    CurrentData = Items.APISchema.CurrentData;
    If CurrentData <> Undefined Then
        
        If IsBlankString(CurrentData.Type) Then 
            Return;
        EndIf;
        
        If TypeCanHaveNestedItems(CurrentData.Type) = True 
          And TypeCanHaveNestedItems(SelectedValue) = False Then
          
            CurrentData.GetItems().Clear();        
            Message = StrTemplate(
                NStr(
                    "en = 'The new type [%1] cannot have nested items. Nested items have just been cleared.';
                    |ru = 'Новый тип [%1] не может иметь вложенные элементы. Вложенные элементы были удалены.'"), 
                SelectedValue);
                
            IHL_CommonUseClientServer.NotifyUser(Message);  
            
        EndIf;
            
        If SelectedValue = "Array" Then 
            For Each Item In CurrentData.GetItems() Do
                Item.Name = "ArrayItem";    
            EndDo;
        EndIf;
        
        If SelectedValue = "Object" Then 
            For Each Item In CurrentData.GetItems() Do
                Item.Name = "";    
            EndDo;
        EndIf;
        
    EndIf;
    
EndProcedure // APISchemaTypeChoiceProcessing()

#EndRegion // FormItemsEventHandlers

#Region FormCommandHandlers

&AtClient
Procedure SaveAndClose(Command)
    
    Close(PutValueTreeToTempStorage(ThisObject.FormOwner.UUID));
    
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
                
            IHL_CommonUseClientServer.NotifyUser(ErrorMessage);  
            
        EndIf;  
        
    Else
        
        If IsBlankString(CurrentData.Name) Then 
            
            ErrorMessage = NStr(
                "en = 'Failed to add new item. Field name is empty.';
                |ru = 'Не удалось добавить новый элемент. Имя поля не заполнено.'");

            IHL_CommonUseClientServer.NotifyUser(ErrorMessage, , 
                "Object.APISchema[" + CurrentData.GetId() + "].Name");
            
            Return;
            
        EndIf;
        
        If IsBlankString(CurrentData.Type) Then 
            
            ErrorMessage = NStr(
                "en = 'Failed to add new item. Type is empty.';
                |ru = 'Не удалось добавить новый элемент. Тип не заполнен.'");

            IHL_CommonUseClientServer.NotifyUser(ErrorMessage, , 
                "Object.APISchema[" + CurrentData.GetId() + "].Type");
            
            Return;
            
        EndIf;
        
        If Not TypeCanHaveNestedItems(CurrentData.Type) Then
         
            ErrorMessage = NStr(
                "en = 'Failed to add new item. Type can not have nested items.';
                |ru = 'Не удалось добавить новый элемент. Тип не может иметь вложенных элементов.'");

            IHL_CommonUseClientServer.NotifyUser(ErrorMessage, , 
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
Procedure DoAfterChooseRowToDelete(QuestionResult, 
    AdditionalParameters) Export
    
    Var Identifier;
    
    If QuestionResult = DialogReturnCode.Yes Then
        If TypeOf(AdditionalParameters) = Type("Structure")
            And AdditionalParameters.Property("Identifier", Identifier) Then
            
            SearchResult = Object.APISchema.FindByID(Identifier);
            If SearchResult <> Undefined Then
                SearchResult.GetParent().GetItems().Delete(SearchResult);     
                Modified = True;     
            EndIf;
                        
        EndIf; 
    EndIf;
    
EndProcedure // DoAfterChooseRowToDelete()


// Only for internal use.
//
&AtServer
Function PutValueTreeToTempStorage(Val OwnerUUID)
    
    ValueTree = FormAttributeToValue("Object.APISchema", Type("ValueTree"));
    Return PutToTempStorage(ValueTree, OwnerUUID);
    
EndFunction // PutValueTreeToTempStorage()

// Check if a type can have nested items.
//
// Parameters:
//  TypeName  - String - type name.
//
// Returns:
//   Boolean - True if this type can have nested items; False in other case.
//
&AtServer
Function TypeCanHaveNestedItems(TypeName)

    MainObject = FormAttributeToValue("Object");
    Return MainObject.TypeCanHaveNestedItems(TypeName);

EndFunction // TypeCanHaveNestedItems() 

#EndRegion // ServiceProceduresAndFunctions