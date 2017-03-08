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

#Region ProgramInterface

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
Function AddItemToItemFormCollection(Items, Parameters, Parent = Undefined) Export
        
    If TypeOf(Parameters) <> Type("Structure") Then
        
        ErrorMessage = StrTemplate(NStr(
            "en = 'Parameter(2) failed to convert. Expected type [%1] and received type is [%2].';
            |ru = 'Параметр(2) не удалось преобразовать. Ожидался тип [%1], а получили тип [%2].'"),
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
        And TypeOf(Parent) <> Type("FormGroup") 
        And TypeOf(Parent) <> Type("FormTable") 
        And TypeOf(Parent) <> Type("ManagedForm") Then
           
            ErrorMessage = StrTemplate(NStr(
                "en = 'Error: Parameter(3) failed to convert. Expected type [%1, %2, %3] and received type is [%4].';
                |ru = 'Ошибка: Тип параметра(3) не удалось преобразовать. Ожидался тип [%1, %2, %3], а получили тип [%4].'"),
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



// Returns metadata object: plugable formats subsystem.
//
// Returns:
//  MetadataObject: Subsystem - plugable formats subsystem.  
//
Function PlugableFormatsSubsystem() Export
    
    MainSubsystem = Metadata.Subsystems.Find("IHL");
    If MainSubsystem = Undefined Then
        
        ErrorMessage = NStr(
            "en = 'Failed to find main subsystem [IHL].';
            |ru = 'Не удалось найти основную подсистему [IHL].'");
        Raise ErrorMessage;
        
    EndIf;
    
    PluginsSubsystem = MainSubsystem.Subsystems.Find("Plugins");
    If PluginsSubsystem = Undefined Then
        
        ErrorMessage = NStr(
            "en = 'Failed to find [IHL -> Plugins] subsystem.';
            |ru = 'Не удалось найти подсистему [IHL -> Plugins].'");
        Raise ErrorMessage;
        
    EndIf;
    
    PlugableFormats = PluginsSubsystem.Subsystems.Find("PlugableFormats");
    If PlugableFormats = Undefined Then
        
        ErrorMessage = NStr(
            "en = 'Failed to find [IHL -> Plugins -> PlugableFormats] subsystem.';
            |ru = 'Не удалось найти подсистему [IHL -> Plugins -> PlugableFormats].'");
        Raise ErrorMessage;
        
    EndIf;
    
    Return PlugableFormats;
    
EndFunction // PlugableFormatsSubsystem() 

#EndRegion // ProgramInterface

#Region ServiceProceduresAndFunctions

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
        
    If Parameters.Property(PropertyName, ProperyValue) = False Then
        If PerformCheck Then
            Raise ErrorMessage;   
        EndIf;
    EndIf;
        
    If DeleteProperty = True Then 
        Parameters.Delete(PropertyName);
    EndIf;

    Return ProperyValue;

EndFunction // ParametersPropertyValue()

#EndRegion // ServiceProceduresAndFunctions
