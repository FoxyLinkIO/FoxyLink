////////////////////////////////////////////////////////////////////////////////
// This file is part of IHL (Integration happiness library).
// Copyright © 2016-2017 Petro Bazeliuk.
// 
// IHL is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as 
// published by the Free Software Foundation, either version 3 
// of the License, or any later version.
// 
// IHL is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public 
// License along with IHL. If not, see <http://www.gnu.org/licenses/>.
//
////////////////////////////////////////////////////////////////////////////////

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
    
    Var APIDefinitionAddress;
    
    MainObject = FormAttributeToValue("Object");
    Items.APIDefinitionType.ChoiceList.LoadValues(
        MainObject.SupportedTypes().UnloadValues());
        
    If Parameters.Property("APIDefinitionAddress", APIDefinitionAddress) Then
        If IsTempStorageURL(APIDefinitionAddress) Then
            
            ValueTree = GetFromTempStorage(APIDefinitionAddress);
            If TypeOf(ValueTree) = Type("ValueTree") Then
                ValueToFormAttribute(ValueTree, "Object.APIDefinition");        
            EndIf;
            
        EndIf;
    EndIf;
    
EndProcedure // OnCreateAtServer()

#EndRegion // FormEventHandlers

#Region FormItemsEventHandlers

&AtClient
Procedure APIDefinitionTypeChoiceProcessing(Item, SelectedValue, StandardProcessing)
    
    CurrentData = Items.APIDefinition.CurrentData;
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
    
EndProcedure // APIDefinitionTypeChoiceProcessing()

#EndRegion // FormItemsEventHandlers

#Region FormCommandHandlers

&AtClient
Procedure SaveAndClose(Command)
    
    Close(PutValueTreeToTempStorage(ThisObject.FormOwner.UUID));
    
EndProcedure // SaveAndClose()

&AtClient
Procedure AddRowToAPITable(Command)
    
    CurrentData = Items.APIDefinition.CurrentData;
    If CurrentData = Undefined Then
        
        If Object.APIDefinition.GetItems().Count() = 0 Then 
            
            NewItem = Object.APIDefinition.GetItems().Add();
            NewItem.Name = "RootItem";
            NewItem.RowPicture = False;
            
            // Set focus on root item.
            Items.APIDefinition.CurrentRow = NewItem.GetID();
            
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
                "Object.APIDefinition[" + CurrentData.GetId() + "].Name");
            
            Return;
            
        EndIf;
        
        If IsBlankString(CurrentData.Type) Then 
            
            ErrorMessage = NStr(
                "en = 'Failed to add new item. Type is empty.';
                |ru = 'Не удалось добавить новый элемент. Тип не заполнен.'");

            IHL_CommonUseClientServer.NotifyUser(ErrorMessage, , 
                "Object.APIDefinition[" + CurrentData.GetId() + "].Type");
            
            Return;
            
        EndIf;
        
        If Not TypeCanHaveNestedItems(CurrentData.Type) Then
         
            ErrorMessage = NStr(
                "en = 'Failed to add new item. Type can not have nested items.';
                |ru = 'Не удалось добавить новый элемент. Тип не может иметь вложенных элементов.'");

            IHL_CommonUseClientServer.NotifyUser(ErrorMessage, , 
                "Object.APIDefinition[" + CurrentData.GetId() + "].Type");
            
            Return;
            
        Else
            
            CurrentId = CurrentData.GetId();
            Parent = Object.APIDefinition.FindByID(CurrentId);
            
            NewItem = Parent.GetItems().Add();
            NewItem.RowPicture = True;
            
            If CurrentData.Type = "Array" Then
                NewItem.Name = "ArrayItem";    
            EndIf;
            
            If Not Items.APIDefinition.Expanded(CurrentId) Then
                Items.APIDefinition.Expand(CurrentId);    
            EndIf;    
          
        EndIf; 
                
    EndIf;
    
EndProcedure // AddRowToAPITable()

#EndRegion // FormCommandHandlers

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
&AtServer
Function PutValueTreeToTempStorage(Val OwnerUUID)
    
    ValueTree = FormAttributeToValue("Object.APIDefinition", Type("ValueTree"));
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