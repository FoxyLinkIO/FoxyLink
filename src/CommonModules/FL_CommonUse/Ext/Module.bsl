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

// Returns a structure containing attribute values that have been read from 
// the infobase through the object link.
// If there is no access to the attribute, access rights exception occurs.
//
// Parameters:
//  Ref        - AnyRef - object attributes values of which it is required to receive.
//  Attributes - String - comma separated attribute names in the format of structure 
//                  property requirements.
//             - Structure, FixedStructure - field alias name is transferred as a key 
//                  for the returned structure with the result and actual field name in
//                  the table is transferred (optionally) as the value.
//                  If the value is not specified, then the field name is taken from the key.
//             - Array, FixedArray - attribute names in the format of requirements 
//                  to the structure properties.
//
// Returns:
//  Structure - includes names (keys) and values of the requested attribute.
//      If a row of the claimed attributes is empty, then an empty structure returns.
//      If a null reference is transferred as an object, then all attributes return with the Undefined value.
//
Function ObjectAttributesValues(Ref, Val Attributes) Export

    If TypeOf(Attributes) = Type("String") Then
        If IsBlankString(Attributes) Then
            Return New Structure;
        EndIf;
        Attributes = StrSplit(Attributes, ",", True);
    EndIf;

    AttributesType = TypeOf(Attributes);
    If AttributesType = Type("Structure") Then 
        
        AttributesStructure = Attributes;    
        
    ElsIf AttributesType = Type("FixedStructure") Then
        
        AttributesStructure = New Structure(Attributes);
        
    ElsIf AttributesType = Type("Array") 
        Or AttributesType = Type("FixedArray") Then
        
        AttributesStructure = New Structure;
        For Each Attribute In Attributes Do
            AttributesStructure.Insert(StrReplace(Attribute, ".", ""), 
                Attribute);
        EndDo;
        
    Else
        
        Raise StrTemplate(NStr("en = 'Invalid type of Attributes second parameter: ''%1''.';
                |ru = 'Неверный тип второго параметра Реквизиты: ''%1''.'"),
            String(AttributesType));
            
    EndIf;

    FieldText = "";
    For Each KeyAndValue In AttributesStructure Do
        
        FieldName = ?(ValueIsFilled(KeyAndValue.Value),
            TrimAll(KeyAndValue.Value), TrimAll(KeyAndValue.Key));
        
        Alias = TrimAll(KeyAndValue.Key);
        
        FieldText = FieldText + ?(IsBlankString(FieldText), "", ",") + "
            |   " + FieldName + " AS " + Alias;
    EndDo;

    Query = New Query;
    Query.SetParameter("Ref", Ref);
    Query.Text = StrTemplate(
        "SELECT
        |   %1
        |FROM
        |   %2 AS SpecifiedTableAlias
        |WHERE 
        |   SpecifiedTableAlias.Ref = &Ref
        |", FieldText, Ref.Metadata().FullName());
    Selection = Query.Execute().Select();
    Selection.Next();

    FillPropertyValues(AttributesStructure, Selection);

    Return AttributesStructure;

EndFunction // ObjectAttributesValues()

// Returns an attribute value that has been read from the infobase through the object link.
// If there is no access to the attribute, access rights exception occurs.
// 
// Parameters:
//  Ref           - AnyRef - object reference.
//  AttributeName - String - attribute name.
// 
// Returns:
//  Arbitrary - attribute value.
// 
Function ObjectAttributeValue(Ref, AttributeName) Export

    Result = ObjectAttributesValues(Ref, AttributeName);
    Return Result[StrReplace(AttributeName, ".", "")];

EndFunction // ObjectAttributeValue()

// Creates a value table and copies all records of the set to it. 
// The structure of the resulting table matches the structure of the recordset.
//
// Parameters:
//  MetadataObject - MetadataObject - metadata object of which it is required 
//                                      to receive records values. 
//  Filter         - Filter         - it contains the object Filter, for which 
//                                      current filtration of records is  
//                                      performed when the set is read or written. 
//
// Returns:
//  ValueTable - creates a value table and copies all records of the set to it. 
//               The structure of the resulting table matches the structure of 
//               the recordset.
//
Function RegisterRecordsValues(MetadataObject, Filter) Export
    
    ObjectManager = FL_CommonUse.ObjectManagerByFullName(
        MetadataObject.FullName());
        
    RecordSet = ObjectManager.CreateRecordSet();
    For Each FilterValue In Filter Do
            
        If NOT FilterValue.Use Then
            Continue;
        EndIf;
        
        FilterRow = RecordSet.Filter.Find(FilterValue.Name);
        FilterRow.Value = FilterValue.Value;
        FilterRow.Use = True;
        
    EndDo;
    
    RecordSet.Read();
    Return RecordSet.Unload();   
    
EndFunction // RegisterRecordsValues()

// Creates a structure with properties named as value table row columns and 
// sets the values of these properties from the values table row.
//
// Parameters:
//  ValueTableRow - ValueTableRow - value table row.
//
// Returns:
//  Structure - with columns as keys and row values as values.
//
Function ValueTableRowIntoStructure(ValueTableRow) Export

    Structure = New Structure;
    For Each Column In ValueTableRow.Owner().Columns Do
        Structure.Insert(Column.Name, ValueTableRow[Column.Name]);
    EndDo;
    
    Return Structure;

EndFunction // ValueTableRowIntoStructure()

// Creates a structure with properties named as value table columns.
//
// Parameters:
//  Columns - ValueTableColumnCollection - value table column collection.
//
// Returns:
//  Structure - with columns as keys.
//
Function ValueTableColumnsIntoStructure(Columns) Export

    Structure = New Structure;
    For Each Column In Columns Do
        Structure.Insert(Column.Name);
    EndDo;
    
    Return Structure;

EndFunction // ValueTableColumnsIntoStructure()

// Extends the target table with the data from the source array.
//
// Parameters:
//  SourceArray - Array      - array from which rows will be taken.
//      * Map       - with values:
//          ** Key   - String    - a column name of target table.
//          ** Value - Arbitrary - a column value.
//      * Structure - with values:
//          ** Key   - String    - a column name of target table.
//          ** Value - Arbitrary - a column value.
//  TargetTable - ValueTable - table to which rows will be added.
//  
Procedure ExtendValueTableFromArray(SourceArray, TargetTable) Export

    If TypeOf(TargetTable) = Type("FormDataCollection") Then
        Columns = FormDataToValue(TargetTable, Type("ValueTable")).Columns;
    EndIf;
    
    For Each SourceItem In SourceArray Do
        TargetRow = TargetTable.Add();
        For Each Column In Columns Do
            TargetRow[Column.Name] = SourceItem[Column.Name];
        EndDo;
    EndDo;

EndProcedure // ExtendValueTableFromArray()

// Handles three state checkbox in the ValueTree object.
//
// Parameters:
//  TreeItem  - ValueTree - value tree item.
//  FieldName - String    - the column name.
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
        
        Parent = CurrentData.Parent;
        While Parent <> Undefined Do
            
            If ChangeParentValueOfThreeStateCheckBox(CurrentData, FieldName) Then
                Parent[FieldName] = CurrentData[FieldName];
            Else
                Parent[FieldName] = ThirdState;    
            EndIf;    
            
            CurrentData = Parent;
            Parent = Parent.Parent;
            
        EndDo;
                
    EndIf;
    
EndProcedure // HandleThreeStateCheckBox()

// Records data of the Structure, Map, Array types considering nesting.
//
// Parameters:
//  Data - Structure, Map, Array - collections the values of which are primitive types, 
//                  the values storage or can not be changed. Values types are supported:
//                  Boolean, String, Number, Date, Undefined, UUID,
//                  Null, Type, ValueStorage, CommonModule, MetadataObject,
//                  XDTOValueType, XDTOObjectType, AnyRef.
//
//  CallingException - Boolean - initial value is True. When set. False, then in case there 
//                  is uncommittable data, the exception will not be thrown. 
//                  The data will be recorded as well as possible.
//
// Returns:
//  Fixed data similar to the passed ones in the Data parameter.
// 
Function FixedData(Data, CallingException = True) Export

    If TypeOf(Data) = Type("Array") Then
        
        Array = New Array;
        For Each Value In Data Do
            
            If TypeOf(Value) = Type("Structure")
             OR TypeOf(Value) = Type("Map")
             OR TypeOf(Value) = Type("Array") Then
                
                Array.Add(FixedData(Value, CallingException));
            Else
                If CallingException Then
                    CheckingDataFixed(Value, True);
                EndIf;
                Array.Add(Value);
            EndIf;
        EndDo;
        
        Return New FixedArray(Array);
        
    ElsIf TypeOf(Data) = Type("Structure")
          OR TypeOf(Data) = Type("Map") Then
        
        If TypeOf(Data) = Type("Structure") Then
            Collection = New Structure;
        Else
            Collection = New Map;
        EndIf;
        
        For Each KeyAndValue In Data Do
            Value = KeyAndValue.Value;
            
            If TypeOf(Value) = Type("Structure")
             OR TypeOf(Value) = Type("Map")
             OR TypeOf(Value) = Type("Array") Then
                
                Collection.Insert(
                    KeyAndValue.Key, FixedData(Value, CallingException));
            Else
                If CallingException Then
                    CheckingDataFixed(Value, True);
                EndIf;
                Collection.Insert(KeyAndValue.Key, Value);
            EndIf;
        EndDo;
        
        If TypeOf(Data) = Type("Structure") Then
            Return New FixedStructure(Collection);
        Else
            Return New FixedMap(Collection);
        EndIf;
        
    ElsIf CallingException Then
        CheckingDataFixed(Data);
    EndIf;

    Return Data;

EndFunction // FixedData()

// Receives the configuration metadata tree with the specified filter by the metadata objects.
// 
// Parameters:
//  Filter - Structure - contains values of the filter items. If parameter is specified, 
//                  the metadata tree will be received according to the specified filter:
//      * Key   - String - name of metadata item property;
//      * Value - Array  - multiple values for filter.
// 
// Example:
//  Array = New Array;
//  Array.Add("Constant.UseDataSynchronization");
//  Array.Add("Catalog.Currencies");
//  Array.Add("Catalog.Companies");
//  Filter = New Structure;
//  Filter.Insert("FullName", Array);
//  ConfigurationMetadataTree(Filter);
//
//  Array = New Array;
//  Array.Add("Constant.*");
//  Array.Add("Catalog.*");
//  Filter = New Structure;
//  Filter.Insert("MetadataObjectClass", Array);
//  ConfigurationMetadataTree(Filter);
//
// 
// Returns:
//  ValueTree - tree of configuration metadata description.
//
Function ConfigurationMetadataTree(Filter = Undefined) Export

    UseFilter = Filter <> Undefined;
    PictureIndexSize = 2;
    PictureCatalogOrder                   = 1;
    PictureDocumentOrder                  = 2;
    PictureInformationRegisterOrder       = 3;
    PictureChartOfCharacteristicTypeOrder = 4;
    PictureAccountingRegisterOrder        = 5;
    PictureAccumulationRegisterOrder      = 6;
    PictureBusinessProcessOrder           = 7;
    PictureCalculationRegisterOrder       = 8;
    PictureChartOfCalculationTypeOrder    = 9;
    PictureTaskOrder                      = 16;
    PictureChartOfAccountOrder            = 32;

    CollectionsOfMetadataObjects = New ValueTable;
    CollectionsOfMetadataObjects.Columns.Add("Name");
    CollectionsOfMetadataObjects.Columns.Add("Synonym");
    CollectionsOfMetadataObjects.Columns.Add("Picture");
    CollectionsOfMetadataObjects.Columns.Add("ObjectPicture");
    CollectionsOfMetadataObjects.Columns.Add("PictureIndex", 
        NumberTypeDescription(PictureIndexSize));

    NewMetadataObjectCollectionRow(TypeNameConstants(),               
        NStr("en='Constants';ru='Константы'"),                 
        PictureLib.Constant,              
        PictureLib.Constant,        
        10,
        CollectionsOfMetadataObjects);
        
    NewMetadataObjectCollectionRow(TypeNameCatalogs(),             
        NStr("en='Catalogs';ru='Справочники'"),               
        PictureLib.Catalog,             
        PictureLib.Catalog,
        PictureCatalogOrder,
        CollectionsOfMetadataObjects);
        
    NewMetadataObjectCollectionRow(TypeNameDocuments(),               
        NStr("en='Documents';ru='Документы'"),                 
        PictureLib.Document,               
        PictureLib.DocumentObject,
        PictureDocumentOrder,
        CollectionsOfMetadataObjects);
        
    NewMetadataObjectCollectionRow(TypeNameChartsOfCharacteristicTypes(), 
        NStr("en='Charts of characteristics types';ru='Планы видов характеристик'"), 
        PictureLib.ChartOfCharacteristicTypes, 
        PictureLib.ChartOfCharacteristicTypesObject,
        PictureChartOfCharacteristicTypeOrder,
        CollectionsOfMetadataObjects);
        
    NewMetadataObjectCollectionRow(TypeNameChartsOfAccounts(),             
        NStr("en='Charts of accounts';ru='Планы счетов'"),              
        PictureLib.ChartOfAccounts,             
        PictureLib.ChartOfAccountsObject,
        PictureChartOfAccountOrder,
        CollectionsOfMetadataObjects);
        
    NewMetadataObjectCollectionRow(TypeNameChartsOfCalculationTypes(),       
        NStr("en='Charts of calculation types';ru='Планы видов расчета'"), 
        PictureLib.ChartOfCalculationTypes, 
        PictureLib.ChartOfCalculationTypesObject,
        PictureChartOfCalculationTypeOrder,
        CollectionsOfMetadataObjects);
        
    NewMetadataObjectCollectionRow(TypeNameInformationRegisters(),        
        NStr("en='Information registers';ru='Регистры сведений'"),         
        PictureLib.InformationRegister,        
        PictureLib.InformationRegister,
        PictureInformationRegisterOrder,
        CollectionsOfMetadataObjects);
        
    NewMetadataObjectCollectionRow(TypeNameAccumulationRegisters(),      
        NStr("en='Accumulation registers';ru='Регистры накопления'"),       
        PictureLib.AccumulationRegister,      
        PictureLib.AccumulationRegister,
        PictureAccumulationRegisterOrder,
        CollectionsOfMetadataObjects);
        
    NewMetadataObjectCollectionRow(TypeNameAccountingRegisters(),     
        NStr("en='Accounting registers';ru='Регистры бухгалтерии'"),      
        PictureLib.AccountingRegister,     
        PictureLib.AccountingRegister, 
        PictureAccountingRegisterOrder,
        CollectionsOfMetadataObjects);
        
    NewMetadataObjectCollectionRow(TypeNameCalculationRegisters(),         
        NStr("en='Calculation registers';ru='Регистры расчета'"),          
        PictureLib.CalculationRegister,         
        PictureLib.CalculationRegister,
        PictureCalculationRegisterOrder,
        CollectionsOfMetadataObjects);
        
    NewMetadataObjectCollectionRow(TypeNameBusinessProcess(),          
        NStr("en='Business processes';ru='Бизнес-процессы'"),           
        PictureLib.BusinessProcess,          
        PictureLib.BusinessProcessObject,
        PictureBusinessProcessOrder,
        CollectionsOfMetadataObjects);
        
    NewMetadataObjectCollectionRow(TypeNameTasks(),                  
        NStr("en='Tasks';ru='Задания'"),                    
        PictureLib.Task,                 
        PictureLib.TaskObject,
        PictureTaskOrder,
        CollectionsOfMetadataObjects);

    // Return value of the function.
    MetadataTree = New ValueTree;
    MetadataTree.Columns.Add("Name");
    MetadataTree.Columns.Add("FullName");
    MetadataTree.Columns.Add("Synonym");
    MetadataTree.Columns.Add("Picture");
    MetadataTree.Columns.Add("Check", New TypeDescription("Number"));
    MetadataTree.Columns.Add("PictureIndex", New TypeDescription("Number"));
    
    For Each CollectionRow In CollectionsOfMetadataObjects Do
        
        TreeRow = MetadataTree.Rows.Add();
        FillPropertyValues(TreeRow, CollectionRow);
        For Each MetadataObject In Metadata[CollectionRow.Name] Do
            
            If UseFilter Then
                
                ObjectPassedFilter = True;
                For Each FilterItem In Filter Do
                    
                    If FilterItem.Key = "MetadataObjectClass" Then
                        FullNameMO = MetadataObject.FullName();
                        Position = StrFind(FullNameMO, "."); 
                        Value = StrTemplate("%1%2", Left(FullNameMO, Position), "*");
                    ElsIf FilterItem.Key = "FullName" Then
                        Value = MetadataObject.FullName();
                    Else
                        Value = MetadataObject[FilterItem.Key];
                    EndIf;
                    
                    If FilterItem.Value.Find(Value) = Undefined Then
                        ObjectPassedFilter = False;
                        Break;
                    EndIf;
                    
                EndDo;
                
                If Not ObjectPassedFilter Then
                    Continue;
                EndIf;
                
            EndIf;
            
            MOTreeRow = TreeRow.Rows.Add();
            MOTreeRow.Name         = MetadataObject.Name;
            MOTreeRow.FullName     = MetadataObject.FullName();
            MOTreeRow.Synonym      = MetadataObject.Synonym;
            MOTreeRow.Picture      = CollectionRow.ObjectPicture;
            MOTreeRow.PictureIndex = CollectionRow.PictureIndex;
            
        EndDo;
        
    EndDo;

    // Delete rows without subordinate items.
    If UseFilter Then
        
        // Use the reverse order of the tree values bypass.
        CollectionItemsQuantity = MetadataTree.Rows.Count();
        
        For ReverseIndex = 1 To CollectionItemsQuantity Do
            
            CurrentIndex = CollectionItemsQuantity - ReverseIndex;
            TreeRow = MetadataTree.Rows[CurrentIndex];
            If TreeRow.Rows.Count() = 0 Then
                MetadataTree.Rows.Delete(CurrentIndex);
            EndIf;
            
        EndDo;

    EndIf;

    Return MetadataTree;

EndFunction // ConfigurationMetadataTree()

#Region ObjectTypes

// Checks if the passed type is a reference data type.
// 
// Parameters: 
//  Type - Type - type that is needed to check.  
//
// Returns:
//  Boolean - False is returned for the Undefined type.
//
Function IsReference(Type) Export

    Return Type <> Type("Undefined") 
      AND (Catalogs.AllRefsType().ContainsType(Type)
        OR Documents.AllRefsType().ContainsType(Type)
        OR Enums.AllRefsType().ContainsType(Type)
        OR ChartsOfCharacteristicTypes.AllRefsType().ContainsType(Type)
        OR ChartsOfAccounts.AllRefsType().ContainsType(Type)
        OR ChartsOfCalculationTypes.AllRefsType().ContainsType(Type)
        OR BusinessProcesses.AllRefsType().ContainsType(Type)
        OR BusinessProcesses.RoutePointsAllRefsType().ContainsType(Type)
        OR Tasks.AllRefsType().ContainsType(Type)
        OR ExchangePlans.AllRefsType().ContainsType(Type));
    
EndFunction // IsReference()

// Constructs a TypeDescription that contains the String type.
//
// Parameters:
//  StringLength - Number - allowed string length. If a parameter is not 
//                          specified, the string length is unlimited.
//                      Default value: 0. 
//
// Returns:
//  TypeDescription - the description of types based on specified types and 
//                    qualifiers for Number, String, Date types. 
//
Function StringTypeDescription(StringLength = 0) Export

    QualifierRows = New StringQualifiers(StringLength, AllowedLength.Variable);
    Return New TypeDescription("String", , QualifierRows);

EndFunction // StringTypeDescription()

// Constructs a TypeDescription that contains the Number type.
//
// Parameters:
//  Digits         - Number      - total number of number digits
//                      Default value: 0.
//  FractionDigits - Number      - number of digits after the decimal point.
//                      Default value: 0.
//  AllowedSign    - AllowedSign - allowed number sign.
//
// Returns:
//  TypeDescription - the description of types based on specified types and 
//                    qualifiers for Number, String, Date types.
//
Function NumberTypeDescription(Digits = 0, FractionDigits = 0, 
    AllowedSign = Undefined) Export

    If AllowedSign = Undefined Then
        NumberQualifier = New NumberQualifiers(Digits, FractionDigits);
    Else
        NumberQualifier = New NumberQualifiers(Digits, FractionDigits, 
            AllowedSign);
    EndIf;

    Return New TypeDescription("Number", NumberQualifier);

EndFunction // NumberTypeDescription()

// Constructs a TypeDescription that contains the Date type.
//
// Parameters:
//  DateFractions - DateFractions - allowed date fractions.
//
// Returns:
//  TypeDescription - the description of types based on specified types and 
//                    qualifiers for Number, String, Date types.
//
Function DateTypeDescription(DateFractions) Export

    Return New TypeDescription("Date", , , New DateQualifiers(DateFractions));

EndFunction // DateTypeDescription()

#EndRegion // ObjectTypes

#Region MetadataObjectTypes
 
// Returns the value to identify the common type of "ExchangePlans".
//
// Returns:
//  String.
//
Function TypeNameExchangePlans() Export

    Return "ExchangePlans";

EndFunction // TypeNameExchangePlans()

// Returns the value to identify the common type of "ScheduledJobs".
//
// Returns:
//  String.
//
Function TypeNameScheduledJobs() Export

    Return "ScheduledJobs";

EndFunction // TypeNameScheduledJobs()

// Returns the value to identify the common type of "Constants".
//
// Returns:
//  String.
//
Function TypeNameConstants() Export

    Return "Constants";

EndFunction // TypeNameConstants()

// Returns the value to identify the common type of "Catalogs".
//
// Returns:
//  String.
//
Function TypeNameCatalogs() Export

    Return "Catalogs";

EndFunction // TypeNameCatalogs()

// Returns the value to identify the common type of "Documents".
//
// Returns:
//  String.
//
Function TypeNameDocuments() Export

    Return "Documents";

EndFunction // TypeNameDocuments()

// Returns the value to identify the common type of "Sequences".
//
// Returns:
//  String.
//
Function TypeNameSequences() Export

    Return "Sequences";

EndFunction // TypeNameSequences()

// Returns the value to identify the common type of "DocumentJournals".
//
// Returns:
//  String.
//
Function TypeNameDocumentJournals() Export

    Return "DocumentJournals";

EndFunction // TypeNameDocumentJournals()

// Returns the value to identify the common type of "Enums".
//
// Returns:
//  String.
//
Function TypeNameEnums() Export

    Return "Enums";

EndFunction // TypeNameEnums()

// Returns the value to identify the common type of "Reports".
//
// Returns:
//  String.
//
Function TypeNameReports() Export

    Return "Reports";

EndFunction // TypeNameReports()

// Returns the value to identify the common type of "DataProcessors".
//
// Returns:
//  String.
//
Function TypeNameDataProcessors() Export

    Return "DataProcessors";
    
EndFunction // TypeNameDataProcessors()

// Returns the value to identify the common type of "ChartsOfCharacteristicTypes".
//
// Returns:
//  String.
//
Function TypeNameChartsOfCharacteristicTypes() Export

    Return "ChartsOfCharacteristicTypes";

EndFunction // TypeNameChartsOfCharacteristicTypes() 

// Returns the value to identify the common type of "ChartsOfAccounts".
//
// Returns:
//  String.
//
Function TypeNameChartsOfAccounts() Export

    Return "ChartsOfAccounts";

EndFunction // TypeNameChartsOfAccounts()

// Returns the value to identify the common type of "ChartsOfCalculationTypes".
//
// Returns:
//  String.
//
Function TypeNameChartsOfCalculationTypes() Export

    Return "ChartsOfCalculationTypes";

EndFunction // TypeNameChartsOfCalculationTypes()

// Returns the value to identify the common type of "InformationRegisters".
//
// Returns:
//  String.
//
Function TypeNameInformationRegisters() Export

    Return "InformationRegisters";

EndFunction // TypeNameInformationRegisters()

// Returns the value to identify the common type of "AccumulationRegisters".
//
// Returns:
//  String.
//
Function TypeNameAccumulationRegisters() Export

    Return "AccumulationRegisters";

EndFunction // TypeNameAccumulationRegisters()

// Returns the value to identify the common type of "AccountingRegisters".
//
// Returns:
//  String.
//
Function TypeNameAccountingRegisters() Export

    Return "AccountingRegisters";

EndFunction // TypeNameAccountingRegisters()

// Returns the value to identify the common type of "CalculationRegisters".
//
// Returns:
//  String.
//
Function TypeNameCalculationRegisters() Export

    Return "CalculationRegisters";

EndFunction // TypeNameCalculationRegisters()

// Returns the value to identify the common type of "Recalculations".
//
// Returns:
//  String.
//
Function TypeNameRecalculations() Export
 
    Return "Recalculations";
 
EndFunction // TypeNameRecalculations()

// Returns the value to identify the common type of "BusinessProcesses".
//
// Returns:
//  String.
//
Function TypeNameBusinessProcess() Export

    Return "BusinessProcesses";

EndFunction // TypeNameBusinessProcess()

// Returns the value to identify the common type of "Tasks".
//
// Returns:
//  String.
//
Function TypeNameTasks() Export

    Return "Tasks";

EndFunction // TypeNameTasks()

#EndRegion // MetadataObjectTypes

#Region MetadataObjectTypesDefinition

// Defines if passed a metadata object belongs to the register type.
// 
// Parameters:
//  MetadataObject - MetadataObject - object for which it is required to define 
//                                      whether it belongs to the specified type.
// 
// Returns:
//  Boolean.
//
Function IsRegister(MetadataObject) Export

    Return Metadata.InformationRegisters.Contains(MetadataObject)
        Or Metadata.AccumulationRegisters.Contains(MetadataObject)
        Or Metadata.AccountingRegisters.Contains(MetadataObject)
        Or Metadata.CalculationRegisters.Contains(MetadataObject);
        
EndFunction // IsRegister()

// Defines if passed a metadata object belongs to the reference type.
// 
// Parameters:
//  MetadataObject - MetadataObject - object for which it is required to define 
//                                    whether it belongs to the specified type.
// 
// Returns:
//   Boolean.
//
Function IsReferenceTypeObject(MetadataObject) Export

    Return IsReferenceTypeObjectByMetadataObjectName(
        MetadataObject.FullName());

EndFunction // IsReferenceTypeObject()

// Defines if passed a metadata object name belongs to the reference type.
// 
// Parameters:
//  MetadataObjectName - String - object name for which it is required to define 
//                                whether it belongs to the specified type.
// 
// Returns:
//   Boolean.
//
Function IsReferenceTypeObjectByMetadataObjectName(MetadataObjectName) Export
    
    Position = Find(MetadataObjectName, ".");
    If Position > 0 Then 
        
        BaseTypes = FL_CommonUseReUse.BaseReferenceTypeNameSynonyms();
        BaseTypeName = Upper(Left(MetadataObjectName, Position - 1));
        Return BaseTypes.Get(BaseTypeName) <> Undefined;
        
    EndIf;
    
    Return False;
    
EndFunction // IsReferenceTypeObjectByFullName()

#EndRegion // MetadataObjectTypesDefinition

// Returns the name of base type based on the metadata object.
// 
// Parameters:
//  MetadataObject - metadata object for which it is necessary to define the base type.
// 
// Returns:
//  String - the name of base type based on the metadata object.
//
Function BaseTypeNameByMetadataObject(MetadataObject) Export
    
    If Metadata.Catalogs.Contains(MetadataObject) Then
        Return TypeNameCatalogs();
        
    ElsIf Metadata.Documents.Contains(MetadataObject) Then
        Return TypeNameDocuments();
        
    ElsIf Metadata.DataProcessors.Contains(MetadataObject) Then
        Return TypeNameDataProcessors();
        
    ElsIf Metadata.Enums.Contains(MetadataObject) Then
        Return TypeNameEnums();
        
    ElsIf Metadata.InformationRegisters.Contains(MetadataObject) Then
        Return TypeNameInformationRegisters();
        
    ElsIf Metadata.AccumulationRegisters.Contains(MetadataObject) Then
        Return TypeNameAccumulationRegisters();
        
    ElsIf Metadata.AccountingRegisters.Contains(MetadataObject) Then
        Return TypeNameAccountingRegisters();
        
    ElsIf Metadata.CalculationRegisters.Contains(MetadataObject) Then
        Return TypeNameCalculationRegisters();
        
    ElsIf Metadata.ExchangePlans.Contains(MetadataObject) Then
        Return TypeNameExchangePlans();
        
    ElsIf Metadata.ChartsOfCharacteristicTypes.Contains(MetadataObject) Then
        Return TypeNameChartsOfCharacteristicTypes();
        
    ElsIf Metadata.BusinessProcesses.Contains(MetadataObject) Then
        Return TypeNameBusinessProcess();
        
    ElsIf Metadata.Tasks.Contains(MetadataObject) Then
        Return TypeNameTasks();
        
    ElsIf Metadata.ChartsOfAccounts.Contains(MetadataObject) Then
        Return TypeNameChartsOfAccounts();
        
    ElsIf Metadata.ChartsOfCalculationTypes.Contains(MetadataObject) Then
        Return TypeNameChartsOfCalculationTypes();
        
    ElsIf Metadata.Constants.Contains(MetadataObject) Then
        Return TypeNameConstants();
        
    ElsIf Metadata.DocumentJournals.Contains(MetadataObject) Then
        Return TypeNameDocumentJournals();
        
    ElsIf Metadata.Sequences.Contains(MetadataObject) Then
        Return TypeNameSequences();
        
    ElsIf Metadata.ScheduledJobs.Contains(MetadataObject) Then
        Return TypeNameScheduledJobs();
        
    ElsIf Metadata.CalculationRegisters.Contains(MetadataObject.Parent())
        AND MetadataObject.Parent().Recalculations.Find(MetadataObject.Name) = MetadataObject Then
        Return TypeNameRecalculations();
        
    Else
        
        Return "";
        
    EndIf;
    
EndFunction // BaseTypeNameByMetadataObject() 

// Returns the metadata object name of the manager name.
// 
// Parameters:
//  ManagerName - String - the object manager name.
// 
// Returns:
//  String - the metadata object name.
//
Function MetadataObjectNameByManagerName(ManagerName) Export

    Position = Find(ManagerName, ".");
    If Position = 0 Then
        Return "CommonModule." + ManagerName;
    EndIf;
    ManagerType = Left(ManagerName, Position - 1);

    TypesNames = New Map;
    TypesNames.Insert(TypeNameExchangePlans(),               "ExchangePlan");
    TypesNames.Insert(TypeNameConstants(),                   "Constant");
    TypesNames.Insert(TypeNameCatalogs(),                    "Catalog");
    TypesNames.Insert(TypeNameDocuments(),                   "Document");
    TypesNames.Insert(TypeNameDocumentJournals(),            "DocumentJournal");
    TypesNames.Insert(TypeNameEnums(),                       "Enum");
    TypesNames.Insert(TypeNameReports(),                     "Report");
    TypesNames.Insert(TypeNameDataProcessors(),              "DataProcessor");
    TypesNames.Insert(TypeNameChartsOfCharacteristicTypes(), "ChartOfCharacteristicTypes");
    TypesNames.Insert(TypeNameChartsOfAccounts(),            "ChartOfAccounts");
    TypesNames.Insert(TypeNameChartsOfCalculationTypes(),    "ChartOfCalculationTypes");
    TypesNames.Insert(TypeNameInformationRegisters(),        "InformationRegister");
    TypesNames.Insert(TypeNameAccumulationRegisters(),       "AccumulationRegister");
    TypesNames.Insert(TypeNameAccountingRegisters(),         "AccountingRegister");
    TypesNames.Insert(TypeNameCalculationRegisters(),        "CalculationRegister");
    TypesNames.Insert(TypeNameBusinessProcess(),             "BusinessProcess");
    TypesNames.Insert(TypeNameTasks(),                       "Task");
    
    TypeName = TypesNames[ManagerType];
    If TypeName = Undefined Then
        Return ManagerName;
    EndIf;

    Return TypeName + Mid(ManagerName, Position);
    
EndFunction // MetadataObjectNameByManagerName()

// Returns the object manager by a full metadata object name.
//
// Parameters:
//  FullName - String - full metadata object name. 
//                  Example: "AccumulationRegister.Inventory".
//
// Returns:
//  ObjectManager.
//
Function ObjectManagerByFullName(FullName) Export
    
    Parts = StrSplit(FullName, ".");
    If Parts.Count() >= 2 Then
        MOType = Upper(Parts[0]);
        MOName = Parts[1];
    EndIf;
    
    If MOType = "EXCHANGEPLAN" 
        Or MOType = "ПЛАНОБМЕНА" Then
        Manager = ExchangePlans;
    ElsIf MOType = "CATALOG"    
        Or MOType = "СПРАВОЧНИК" Then
        Manager = Catalogs;
    ElsIf MOType = "DOCUMENT" 
        Or MOType = "ДОКУМЕНТ" Then
        Manager = Documents;
    ElsIf MOType = "DOCUMENTJOURNAL" 
        Or MOType = "ЖУРНАЛДОКУМЕНТОВ" Then
        Manager = DocumentJournals;
    ElsIf MOType = "ENUM" 
        Or MOType = "ПЕРЕЧИСЛЕНИЕ" Then
        Manager = Enums;
    ElsIf MOType = "REPORT" 
        Or MOType = "ОТЧЕТ" Then
        Manager = Reports;
    ElsIf MOType = "DATAPROCESSOR" 
        Or MOType = "ОБРАБОТКА" Then
        Manager = DataProcessors;
    ElsIf MOType = "CHARTOFCHARACTERISTICTYPES" 
        Or MOType = "ПЛАНВИДОВХАРАКТЕРИСТИК" Then
        Manager = ChartsOfCharacteristicTypes;
    ElsIf MOType = "CHARTOFACCOUNTS" 
        Or MOType = "ПЛАНСЧЕТОВ" Then
        Manager = ChartsOfAccounts;
    ElsIf MOType = "CHARTOFCALCULATIONTYPES" 
        Or MOType = "ПЛАНВИДОВРАСЧЕТА" Then
        Manager = ChartsOfCalculationTypes;
    ElsIf MOType = "INFORMATIONREGISTER" 
        Or  MOType = "РЕГИСТРСВЕДЕНИЙ" Then
        Manager = InformationRegisters;
    ElsIf MOType = "ACCUMULATIONREGISTER" 
        Or MOType = "РЕГИСТРНАКОПЛЕНИЯ" Then
        Manager = AccumulationRegisters;
    ElsIf MOType = "ACCOUNTINGREGISTER" 
        Or MOType = "РЕГИСТРБУХГАЛТЕРИИ" Then
        Manager = AccountingRegisters;
    ElsIf MOType = "CALCULATIONREGISTER"
        Or MOType = "РЕГИСТРРАСЧЕТА" Then
        
        If Parts.Count() = 2 Then
            // Calculation register
            Manager = CalculationRegisters;
        Else
            MOSubordinate = Upper(Parts[2]);
            SlaveName = Parts[3];
            If MOSubordinate = "RECALCULATION" 
                Or MOSubordinate = "ПЕРЕРАСЧЕТ" Then
                // Recalculation
                Try
                    Manager = CalculationRegisters[MOName].Recalculations;
                    MOName = SlaveName;
                Except
                    Manager = Undefined;
                EndTry;
            EndIf;
        EndIf;
        
    ElsIf MOType = "BUSINESSPROCESS"
        Or MOType = "БИЗНЕСПРОЦЕСС" Then
        Manager = BusinessProcesses;
    ElsIf MOType = "TASK"
        Or MOType = "ЗАДАЧА" Then
        Manager = Tasks;
    ElsIf MOType = "CONSTANT" 
        Or MOType = "КОНСТАНТА" Then
        Manager = Constants;
    ElsIf MOType = "SEQUENCE" 
        Or MOType = "ПОСЛЕДОВАТЕЛЬНОСТЬ" Then
        Manager = Sequences;
    EndIf;
    
    If Manager <> Undefined Then
        Try
            Return Manager[MOName];
        Except
            Manager = Undefined;
        EndTry;
    EndIf;
    
    Raise StrTemplate(NStr("en = 'Unknown type of metadata object ''%1''.';
            |ru = 'Неизвестный тип объекта метаданных ''%1''.'"), FullName);
    
EndFunction // ObjectManagerByFullName()

// Checks if the passed attribute name is included in the subset of standard attributes.
// 
// Parameters:
//  StandardAttributes - StandardAttributesDescription - type and value describes the
//                          collection of settings for various standard attributes.
//  AttributeName      - String - attribute name to be checked.
// 
// Returns:
//  Boolean - True if the attribute is included in the subset of standard attributes.
//
Function IsStandardAttribute(StandardAttributes, AttributeName) Export

    Synonyms = FL_CommonUseReUse.StandardAttributeSynonyms();
    
    Name = Upper(AttributeName);
    For Each Attribute In StandardAttributes Do
        If Upper(Attribute.Name) = Name Or Upper(Attribute.Name) = Synonyms[Name] Then
            Return True;
        EndIf;
    EndDo;
    Return False;

EndFunction // IsStandardAttribute()

#Region ValueConversion 

// Serializes an array of reference data type objects into JSONWriter.
//
// Parameters:
//  JSONWriter - JSONWriter - sequentially writes JSON objects and texts.
//  Source     - Array      - the array of reference data type objects. 
//      * AnyRef - reference data type object.
//
Procedure SerializeArrayOfRefsToJSON(JSONWriter, Source) Export
    
    JSONWriter.WriteStartArray();
    
    For Each Item In Source Do
        XDTOSerializer.WriteJSON(JSONWriter, Item.GetObject(), 
            XMLTypeAssignment.Explicit);
    EndDo;
    
    JSONWriter.WriteEndArray();
    
EndProcedure // SerializeArrayOfRefsToJSON()

// Serializes the value into JSON string representation.
//
// Parameters:
//  Value - Arbitrary - the value to be serialized.
//
// Returns:
//  String - JSON string representation.
//
Function ValueToJSONString(Value) Export

    JSONWriter = New JSONWriter();
    JSONWriter.SetString();
    XDTOSerializer.WriteJSON(JSONWriter, Value, XMLTypeAssignment.Explicit);
    Return JSONWriter.Close();

EndFunction // ValueToJSONString()

// Returns conversion result.
//
// Parameters:
//  Value          - Arbitrary - value to be converted.
//  SupportedTypes - Array     - array of types.
//      * ArrayItem - Type - type to which you want to convert.
//
// Returns:
//  Structure - see function FL_CommonUse.NewConversionResult.
//
Function ConvertValueIntoPlatformObject(Val Value, SupportedTypes) Export

    ValueType = TypeOf(Value);
    ConversionResult = NewConversionResult();

    For Each Type In SupportedTypes Do
        
        If Type = ValueType Then
            ConversionResult.ConvertedValue = Value;
            ConversionResult.TypeConverted  = True;
        ElsIf Type = Type("String") Then
            ConvertValueIntoString(Value, ConversionResult);
        //ElsIf Type = Type("Number") Then
        //    ConvertValueIntoNumber(Value, ConversionResult);
        //ElsIf Type = Type("Date") Then
        //    ConvertValueIntoDate(Value, ConversionResult);
        //ElsIf Type = Type("StandardPeriod") Then
        //    ConvertValueIntoStandardPeriod(Value, ConversionResult);
        //ElsIf IsReference(Type) Then
        //    ConvertValueIntoRef(Value, Type, ConversionResult);
        EndIf;
        
        If ConversionResult.TypeConverted Then
            Break;
        EndIf;
        
    EndDo;

    Return ConversionResult;
        
EndFunction // ConvertValueIntoPlatformObject()

#EndRegion // ValueConversion

#EndRegion // ProgramInterface

#Region ServiceIterface

// Defines the operation mode of the infobase. It can be file (True) or server (False).
// During checking InfobaseConnectionRow is used that can clearly be recognized.
//
// Parameters:
//  InfobaseConnectionString - String - parameter is used if it is required 
//                  to check a connection string not of the current infobase.
//
// Returns:
//  Boolean.
//
Function FileInfobase(Val InfobaseConnectionString = "") Export
            
    If IsBlankString(InfobaseConnectionString) Then
        InfobaseConnectionString = InfobaseConnectionString();
    EndIf;
    Return Find(Upper(InfobaseConnectionString), "FILE=") = 1;

EndFunction // FileInfobase()

#EndRegion // FileInfobase

#Region ServiceProceduresAndFunctions

#Region ValueTreeOperations

// Only for internal use.
//
Procedure SetValueOfThreeStateCheckBox(CurrentData, FieldName)

    TreeItems = CurrentData.Rows;
    For Each TreeItem In TreeItems Do
        TreeItem[FieldName] = CurrentData[FieldName];
        SetValueOfThreeStateCheckBox(TreeItem, FieldName);
    EndDo;

EndProcedure // SetValueOfThreeStateCheckBox()

// Only for internal use.
//
Function ChangeParentValueOfThreeStateCheckBox(CurrentData, FieldName)

    TreeItems = CurrentData.Parent.Rows;
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
Procedure NewMetadataObjectCollectionRow(Name, Synonym, Picture, ObjectPicture, 
    PictureIndex, Tab)

    NewRow = Tab.Add();
    NewRow.Name          = Name;
    NewRow.Synonym       = Synonym;
    NewRow.Picture       = Picture;
    NewRow.ObjectPicture = ObjectPicture;
    NewRow.PictureIndex  = PictureIndex;

EndProcedure // NewMetadataObjectCollectionRow()

// Only for internal use.
//
Procedure CheckingDataFixed(Data, DataInValueOfFixedTypes = False)

    DataType = TypeOf(Data);

    If DataType = Type("ValueStorage")
     OR DataType = Type("FixedArray")
     OR DataType = Type("FixedStructure")
     OR DataType = Type("FixedMap") Then
        Return;
    EndIf;

    If DataInValueOfFixedTypes Then
        
        If DataType = Type("Boolean")
         OR DataType = Type("String")
         OR DataType = Type("Number")
         OR DataType = Type("Date")
         OR DataType = Type("Undefined")
         OR DataType = Type("UUID")
         OR DataType = Type("Null")
         OR DataType = Type("Type")
         OR DataType = Type("ValueStorage")
         OR DataType = Type("CommonModule")
         OR DataType = Type("MetadataObject")
         OR DataType = Type("XDTOValueType")
         OR DataType = Type("XDTOObjectType")
         OR IsReference(DataType) Then
            
            Return;
        EndIf;
    EndIf;

    Raise StrTemplate(NStr(
        "en = 'An error occurred in the ''FixedData'' function of the FL_CommonUse common module.
            |Data of the ''%1'' type can not be recorded.';
        |ru = 'Ошибка в функции ''FixedData'' общего модуля FL_CommonUse.
            |Данные типа ''%1'' не могут быть зафиксированы.'"),
        String(DataType));

EndProcedure // CheckingDataFixed()

#Region ValueConversion

// Converts value into "String" type.
//
// Parameters:
//  Value            - Arbitrary - value to be converted into "String" type.
//  ConversionResult - Structure - see function FL_CommonUse.NewConversionResult.
//
Procedure ConvertValueIntoString(Value, ConversionResult)

    TypeMatch = ValueTypeMatchExpected(Value, Type("String"), ConversionResult);    
    If TypeMatch Then
        ConversionResult.ConvertedValue = Value;
        ConversionResult.TypeConverted  = True;
    EndIf;
                        
EndProcedure // ConvertValueIntoString()

// Returns base convertion result structure.
//
// Returns:
//  Structure - convertion result structure.
//      * ConvertedValue - Arbitrary - converted value.
//      * TypeConverted  - Boolean   - initial value 'False', when 'True' is set 
//                                    it means value conversion was successful.
//                          Default value: False.
//
Function NewConversionResult()

    ConversionResult = New Structure;
    ConversionResult.Insert("ConvertedValue");
    ConversionResult.Insert("TypeConverted", False);
    Return ConversionResult;

EndFunction // NewConversionResult()

// Checks value type to the expected type. 
//
// Parameters:
//  Value            - Arbitrary - value to be converted into expected type.
//  ExpectedType     - Type      - expected type.
//  ConversionResult - Structure - see function FL_CommonUse.NewConversionResult.
//
// Returns:
//  Boolean - If the value is 'True' the type is macthed expected type, 
//              else - value doesn't match expected type.  
//
Function ValueTypeMatchExpected(Value, ExpectedType, ConversionResult)

    If TypeOf(Value) <> ExpectedType Then
        
        // FL_ErrorsClientServer.ErrorTypeIsDifferentFromExpected(
        //      "SettingsComposer", Value, ExpectedType);
        
        Return False;
            
    EndIf;
        
    Return True;

EndFunction // ValueTypeMatchExpected()

#EndRegion // ValueConversion

#EndRegion // ServiceProceduresAndFunctions