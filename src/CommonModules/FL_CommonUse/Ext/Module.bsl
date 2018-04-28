////////////////////////////////////////////////////////////////////////////////
// This file is part of FoxyLink.
// Copyright © 2016-2018 Petro Bazeliuk.
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
        
        ErrorMessage = NStr("en='Invalid type of Attributes second parameter: {%1}.';
            |ru='Неверный тип второго параметра Реквизиты: {%1}.';
            |en_CA='Invalid type of Attributes second parameter: {%1}.'");
        
        Raise StrTemplate(ErrorMessage, String(AttributesType));
            
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

// Returns reference by a description.
//
// Parameters:
//  MetadataObject - MetadataObject - metadata object from which it is required 
//                                      to receive reference by description. 
//  Description    - String         - the description of reference. 
//
// Returns:
//  AnyRef, Undefined - reference by the description. 
//
Function ReferenceByDescription(MetadataObject, Description) Export
    
    Query = New Query;
    Query.Text = StrTemplate(QueryTextReferenceByDescription(), 
        MetadataObject.FullName());
    Query.SetParameter("Description", Description);
    QueryResultSelection = Query.Execute().Select();
    
    Return ?(QueryResultSelection.Next(), QueryResultSelection.Ref, Undefined);
    
EndFunction // ReferenceByDescription()

// Returns reference by a predefined data name.
//
// Parameters:
//  MetadataObject - MetadataObject - metadata object from which it is required 
//                                      to receive reference by predefined data name.
//  PredefinedDataName - String - the predefined data name of reference. 
//
// Returns:
//  AnyRef, Undefined - reference by the predefined data name. 
//
Function ReferenceByPredefinedDataName(MetadataObject, 
    PredefinedDataName) Export
       
    If IsBlankString(PredefinedDataName) Then
        Return Undefined;
    EndIf;

    Query = New Query;
    Query.Text = StrTemplate(QueryTextReferenceByPredefinedDataName(), 
        MetadataObject.FullName());
    Query.SetParameter("PredefinedDataName", PredefinedDataName);
    
    Try
        QueryResultSelection = Query.Execute().Select();
    Except
        Return Undefined;
    EndTry; 
    
    Return ?(QueryResultSelection.Next(), QueryResultSelection.Ref, Undefined);
    
EndFunction // ReferenceByPredefinedDataName()

// Returns a value table and copies all records of the set to it. 
// The structure of the resulting table matches the structure of the recordset.
//
// Parameters:
//  MetadataObject - MetadataObject - metadata object of which it is required 
//                                      to receive records values. 
//  Filter         - Filter         - it contains the object Filter, for which 
//                                      current filtration of records is  
//                                      performed when the set is read or written.
//  Attributes     - String         - comma separated attribute names in the format of
//                                      structure property requirements.
//                          Default value: "".
//                 - Structure, FixedStructure - field alias name is transferred
//                                      as a key for the returned structure with 
//                                      the result and actual field name in the 
//                                      table is transferred (optionally) as the value.
//                                      If the value is not specified, then the 
//                                      field name is taken from the key.
//
// Returns:
//  ValueTable - returns a value table and copies all records of the set to it. 
//               The structure of the resulting table matches the structure of 
//               the recordset.
//
Function RegisterAttributeValues(MetadataObject, Filter, 
    Val Attributes = "") Export
    
    FieldText = "";
    FieldTemplate = "%1SpecifiedTableAlias.%2 AS %2";
    FilterText = "";
    FilterTemplate = "%1SpecifiedTableAlias.%2 = &%2";
    
    If TypeOf(Attributes) = Type("String") Then
        
        AttributesStructure = New Structure;
        If NOT IsBlankString(Attributes) Then
            AttributesStructure = New Structure(Attributes);
        EndIf;
        
    Else
        
        AttributesStructure = Attributes;
        
    EndIf;
    
    For Each KeyAndValue In AttributesStructure Do
        
        FieldText = FieldText + StrTemplate(FieldTemplate, 
            ?(IsBlankString(FieldText), "", ","), KeyAndValue.Key);
        
    EndDo;
    
    If IsBlankString(FieldText) Then
        FieldText = "*";             
    EndIf;

    Query = New Query;
    For Each FilterValue In Filter Do
        If FilterValue.Use Then
            
            Query.SetParameter(FilterValue.Name, FilterValue.Value);
            FilterText = FilterText + StrTemplate(FilterTemplate, 
                ?(IsBlankString(FilterText), "", " AND "), FilterValue.Name); 
            
        EndIf;
    EndDo;    
    
    If NOT IsBlankString(FilterText) Then
        FilterText = " WHERE " + FilterText;
    EndIf;
    
    Query.Text = StrTemplate(
        "SELECT
        |   %1
        |FROM
        |   %2 AS SpecifiedTableAlias
        |   %3
        |", FieldText, MetadataObject.FullName(), FilterText);
    Return Query.Execute().Unload();
    
EndFunction // RegisterAttributeValues()

// Returns a value table and copies records values to column which matched 
// attribute name. 
//
// Parameters:
//  MetadataObject - MetadataObject - metadata object of which it is required 
//                                      to receive records values. 
//  Filter         - Filter         - it contains the object Filter, for which 
//                                      current filtration of records is  
//                                      performed when the set is read or written.
//  AttributeName  - String         - attribute name.
//
// Returns:
//  ValueTable - returns a value table and copies all records values to column 
//               which matched attribute name.
//
Function RegisterAttributeValue(MetadataObject, Filter, 
    AttributeName) Export
    
    Return RegisterAttributeValues(MetadataObject, Filter, AttributeName);
    
EndFunction // RegisterAttributeValue()

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
    Else
        Columns = TargetTable.Columns;    
    EndIf;
    
    For Each SourceItem In SourceArray Do
        TargetRow = TargetTable.Add();
        For Each Column In Columns Do
            TargetRow[Column.Name] = SourceItem[Column.Name];
        EndDo;
    EndDo;

EndProcedure // ExtendValueTableFromArray()

// Removes duplicates from source value table.
//
// Parameters:
//  Source - ValueTable - value table to remove duplicates.
//
Procedure RemoveDuplicatesFromValueTable(Source) Export
    
    If TypeOf(Source) = Type("FormDataCollection") Then
        TemporaryTable = Source.Unload();
    Else
        TemporaryTable = Source;    
    EndIf;
    
    GroupColumns = "";
    NotFirstColumn = False;
    For Each Column In TemporaryTable.Columns Do
        
        If NotFirstColumn Then
            GroupColumns = GroupColumns + ", ";    
        EndIf;
        
        GroupColumns = GroupColumns + Column.Name;
        NotFirstColumn = True;
        
    EndDo;
    
    TemporaryTable.GroupBy(GroupColumns);
    
    If TypeOf(Source) = Type("FormDataCollection") Then
        Source.Load(TemporaryTable);
    EndIf;
        
EndProcedure // RemoveDuplicatesFromValueTable() 

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

    PictureIndexSize = 2;
    CollectionsOfMetadataObjects = New ValueTable;
    CollectionsOfMetadataObjects.Columns.Add("Name");
    CollectionsOfMetadataObjects.Columns.Add("Synonym");
    CollectionsOfMetadataObjects.Columns.Add("Picture");
    CollectionsOfMetadataObjects.Columns.Add("ObjectPicture");
    CollectionsOfMetadataObjects.Columns.Add("PictureIndex", 
        NumberTypeDescription(PictureIndexSize));
        
    AddScheduledJob(CollectionsOfMetadataObjects);
    AddHTTPService(CollectionsOfMetadataObjects);
        
    AddConstant(CollectionsOfMetadataObjects);
    AddCatalog(CollectionsOfMetadataObjects);
    AddDocument(CollectionsOfMetadataObjects);
    AddChartOfCharacteristicTypes(CollectionsOfMetadataObjects);
    AddChartOfAccounts(CollectionsOfMetadataObjects);
    AddChartOfCalculationTypes(CollectionsOfMetadataObjects);
    
    AddInformationRegister(CollectionsOfMetadataObjects);
    AddAccumulationRegister(CollectionsOfMetadataObjects);
    AddAccountingRegister(CollectionsOfMetadataObjects);
    AddCalculationRegister(CollectionsOfMetadataObjects);
    
    AddBusinessProcess(CollectionsOfMetadataObjects); 
    AddTask(CollectionsOfMetadataObjects);
     
    // Return value of the function.
    MetadataTree = New ValueTree;
    MetadataTree.Columns.Add("Name");
    MetadataTree.Columns.Add("FullName");
    MetadataTree.Columns.Add("Synonym");
    MetadataTree.Columns.Add("Picture");
    MetadataTree.Columns.Add("Check", New TypeDescription("Number"));
    MetadataTree.Columns.Add("PictureIndex", New TypeDescription("Number"));
    
    FillMetadataTreeCollection(MetadataTree, CollectionsOfMetadataObjects, 
        Filter);

    // Delete rows without subordinate items.
    If Filter <> Undefined Then
        
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

// Specifies that the metadata object belongs to the catalog type.
// 
// Parameters:
//  MetadataObject - MetadataObject - object for which it is necessary to specify 
//                                    whether it belongs to the catalog type.
// 
// Returns:
//  Boolean - True if metadata object belongs to the catalog type.
//
Function IsCatalog(MetadataObject) Export

    Return Metadata.Catalogs.Contains(MetadataObject);

EndFunction // IsCatalog()

// Checks if the record about the passed reference value is actually in the data infobase.
// 
// Parameters:
//  AnyRef - AnyRef - value of any data infobase reference.
// 
// Returns:
//  Boolean - True if reference exists.
//
Function RefExists(AnyRef) Export

    QueryText = StrTemplate("SELECT
        |   Ref AS Ref
        |FROM
        |   %1
        |WHERE
        |   Ref = &Ref
        |", TableNameByRef(AnyRef));
    
    Query = New Query;
    Query.Text = QueryText;
    Query.SetParameter("Ref", AnyRef);

    SetPrivilegedMode(True);

    Return NOT Query.Execute().IsEmpty();

EndFunction // RefExists()

// Returns a full name of metadata object by the passed reference value.
// 
// Parameters:
//  Ref - AnyRef - object for which it is required to receive table name.
// 
// Returns:
//  String - the full name of the metadata object for the specified reference.
//
Function TableNameByRef(Ref) Export

    Return Ref.Metadata().FullName();

EndFunction // TableNameByRef()

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

// Returns the value to identify the common type of "HTTPServices".
//
// Returns:
//  String.
//
Function TypeNameHTTPServices() Export

    Return "HTTPServices";

EndFunction // TypeNameHTTPServices()

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
//  Boolean - True, if register type; otherwise - False.
//
Function IsRegister(MetadataObject) Export

    FullName = MetadataObject.FullName();
    Return FL_CommonUseReUse.IsRegisterTypeObjectCached(FullName);
        
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

    FullName = MetadataObject.FullName();    
    Return FL_CommonUseReUse.IsReferenceTypeObjectCached(FullName);

EndFunction // IsReferenceTypeObject()

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
        If Upper(Attribute.Name) = Name Or Upper(Attribute.Name) = Synonyms.Get(Name) Then
            Return True;
        EndIf;
    EndDo;
    Return False;

EndFunction // IsStandardAttribute()

#EndRegion // MetadataObjectTypesDefinition

// Returns the name of base type based on the metadata object.
// 
// Parameters:
//  MetadataObject - MetadataObject - metadata object for which it is necessary 
//                                      to define primary keys.
//
//  Returns:
//      Structure - with primary keys:
//          * Key   - String - name of the primary key.
//          * Value - String - type name of primary key.
//
Function PrimaryKeysByMetadataObject(MetadataObject) Export

    FullName = MetadataObject.FullName();

    PrimaryKeys = New Structure;
    If FL_CommonUseReUse.IsReferenceTypeObjectCached(FullName) Then

        ObjectManager = ObjectManagerByFullName(FullName);
        
        Types = New Array;
        Types.Add(TypeOf(ObjectManager.EmptyRef()));
        PrimaryKeys.Insert("Ref", Types);
        
    ElsIf FL_CommonUseReUse.IsInformationRegisterTypeObjectCached(FullName) Then
        
        FillInformationRegisterPrimaryKeys(MetadataObject, PrimaryKeys);
        
    ElsIf FL_CommonUseReUse.IsAccumulationRegisterTypeObjectCached(FullName) Then
        
        FillAccumulationRegisterPrimaryKeys(MetadataObject, PrimaryKeys);
                
    EndIf;

    Return PrimaryKeys;
    
EndFunction // PrimaryKeysByMetadataObject()

// Returns the name of base type based on the metadata object.
// 
// Parameters:
//  MetadataObject - MetadataObject - metadata object for which it is necessary 
//                                      to define the base type.
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

// Returns a reference to the common or manager module by the provided module name.
//
// Parameters:
//  ModuleName - String - common module or manager module name.
//
// Returns:
//  CommonModule - reference to the common module. 
//  <Type>Manager.<Object name> - reference to the manager module.
//
Function CommonModule(Val ModuleName) Export

    Module = Undefined;
    PointPosition = StrFind(ModuleName, ".");
    If Metadata.CommonModules.Find(ModuleName) <> Undefined Then
        
        Module = FL_RunInSafeMode.EvalInSafeMode(ModuleName);
        
    ElsIf PointPosition > 0 Then
        
        SecondPart = Mid(ModuleName, PointPosition + 1);
        If Metadata.CommonModules.Find(SecondPart) <> Undefined Then
            Module = FL_RunInSafeMode.EvalInSafeMode(SecondPart);    
        Else
            Return ObjectManagerByFullName(ModuleName);
        EndIf;
        
    EndIf;

    If TypeOf(Module) <> Type("CommonModule") Then
        Raise StrTemplate(NStr("en='Common module {%1} is not found.';
            |ru='Общий модуль {%1} не найден.';
            |uk='Загальний модуль {%1} не знайдено.';
            |en_CA='Common module {%1} is not found.'"), ModuleName);
    EndIf;

    Return Module;

EndFunction // CommonModule()

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
    
    ManagerMap = New Map;
    If FL_CommonUseReUse.IsReferenceTypeObjectCached(FullName) Then
        
        ManagerMap.Insert("EXCHANGEPLAN", ExchangePlans);
        ManagerMap.Insert("ПЛАНОБМЕНА", ExchangePlans);
        ManagerMap.Insert("CATALOG", Catalogs);
        ManagerMap.Insert("СПРАВОЧНИК", Catalogs);
        ManagerMap.Insert("DOCUMENT", Documents);
        ManagerMap.Insert("ДОКУМЕНТ", Documents);
        ManagerMap.Insert("ENUM", Enums);
        ManagerMap.Insert("ПЕРЕЧИСЛЕНИЕ", Enums);
        ManagerMap.Insert("CHARTOFCHARACTERISTICTYPES", ChartsOfCharacteristicTypes);
        ManagerMap.Insert("ПЛАНВИДОВХАРАКТЕРИСТИК", ChartsOfCharacteristicTypes);
        ManagerMap.Insert("CHARTOFACCOUNTS", ChartsOfAccounts);
        ManagerMap.Insert("ПЛАНСЧЕТОВ", ChartsOfAccounts);
        ManagerMap.Insert("CHARTOFCALCULATIONTYPES", ChartsOfCalculationTypes);
        ManagerMap.Insert("ПЛАНВИДОВРАСЧЕТА", ChartsOfCalculationTypes);
        ManagerMap.Insert("BUSINESSPROCESS", BusinessProcesses);
        ManagerMap.Insert("БИЗНЕСПРОЦЕСС", BusinessProcesses);
        ManagerMap.Insert("TASK", Tasks);
        ManagerMap.Insert("ЗАДАЧА", Tasks);

    ElsIf FL_CommonUseReUse.IsRegisterTypeObjectCached(FullName) Then    
        
        ManagerMap.Insert("INFORMATIONREGISTER", InformationRegisters);
        ManagerMap.Insert("РЕГИСТРСВЕДЕНИЙ", InformationRegisters);
        ManagerMap.Insert("ACCUMULATIONREGISTER", AccumulationRegisters);
        ManagerMap.Insert("РЕГИСТРНАКОПЛЕНИЯ", AccumulationRegisters);
        ManagerMap.Insert("ACCOUNTINGREGISTER", AccountingRegisters);
        ManagerMap.Insert("РЕГИСТРБУХГАЛТЕРИИ", AccountingRegisters);
        ManagerMap.Insert("CALCULATIONREGISTER", CalculationRegisters);
        ManagerMap.Insert("РЕГИСТРРАСЧЕТА", CalculationRegisters);
        
    Else
        
        ManagerMap.Insert("DOCUMENTJOURNAL", DocumentJournals);
        ManagerMap.Insert("ЖУРНАЛДОКУМЕНТОВ", DocumentJournals);
        ManagerMap.Insert("REPORT", Reports);
        ManagerMap.Insert("ОТЧЕТ", Reports);
        ManagerMap.Insert("DATAPROCESSOR", DataProcessors);
        ManagerMap.Insert("ОБРАБОТКА", DataProcessors);
        ManagerMap.Insert("CONSTANT", Constants);
        ManagerMap.Insert("КОНСТАНТА", Constants);
        ManagerMap.Insert("SEQUENCE", Sequences);
        ManagerMap.Insert("ПОСЛЕДОВАТЕЛЬНОСТЬ", Sequences);
        
    EndIf;
     
    MetaObjectTypeIndex = 0;
    MetaObjectNameIndex = 1;
    Parts = StrSplit(FullName, ".");
    
    TwoNameParts = 2;
    If Parts.Count() >= TwoNameParts Then
        MetaObjectType = Upper(Parts[MetaObjectTypeIndex]);
        MetaObjectName = Parts[MetaObjectNameIndex];
    EndIf;
    
    Manager = ManagerMap.Get(MetaObjectType);
    
    FourNameParts = 4;
    If Parts.Count() = FourNameParts Then
        ProcessRecalculationObjectManager(Manager, Parts, MetaObjectName, 
            MetaObjectType);        
    EndIf;
       
    If Manager <> Undefined Then
        Try
            Return Manager[MetaObjectName];
        Except
            Manager = Undefined;
        EndTry;
    EndIf;
    
    ErrorMessage = NStr("en='Unknown type of metadata object {%1}.';
        |ru='Неизвестный тип объекта метаданных {%1}.';
        |uk='Невідомий тип метаданих {%1}.';
        |en_CA='Unknown type of metadata object {%1}.'");
    
    Raise StrTemplate(ErrorMessage, FullName);
    
EndFunction // ObjectManagerByFullName()

// Returns the object manager by a reference to object.
//
// Parameters:
//  Ref - AnyRef - the object for which it is required to receive object manager.
//
// Returns:
//  ObjectManager - object manager received by a reference to object.
//
Function ObjectManagerByReference(Ref) Export
    
    FullName = TableNameByRef(Ref);
    Return ObjectManagerByFullName(FullName);
    
EndFunction // ObjectManagerByReference()

#EndRegion // ObjectTypes

// Returns a value table mock for a metadata object.
// 
// Parameters:
//  MetadataObject - MetadataObject - metadata object for which it is necessary 
//                                      to create the value table mock.
// 
// Returns:
//  ValueTable - the mock of metadata object.
//
Function NewMockOfMetadataObjectAttributes(MetadataObject) Export
    
    // Return value of the function.
    Mock = New ValueTable;
    
    For Each Attribute In MetadataObject.Attributes Do
        Mock.Columns.Add(Attribute.Name, Attribute.Type, Attribute.Synonym); 
    EndDo;

    SynonymsRU = FL_CommonUseReUse.StandardAttributeSynonymsRU();
    For Each Attribute In MetadataObject.StandardAttributes Do
        
        AttributeName = SynonymsRU.Get(Upper(Attribute.Name));
        If AttributeName = Undefined Then
            AttributeName = Attribute.Name;
        EndIf;
        
        Mock.Columns.Add(AttributeName, Attribute.Type, Attribute.Synonym);
        
    EndDo;

    Return Mock;
    
EndFunction // NewMockOfMetadataObjectAttributes()

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

// Deserializes object from a JSON string.
//
// Parameters:
//  Value - String - the value to be deserialized.
//
// Returns:
//  Arbitrary - deserialized object from the JSON string.
//
Function ValueFromJSONString(Value) Export

    JSONReader = New JSONReader();
    JSONReader.SetString(Value);
    
    // Deserializes a value in JSON format. 
    Object = XDTOSerializer.ReadJSON(JSONReader);
    
    // Clear action.
    JSONReader.Close();
    
    Return Object;

EndFunction // ValueFromJSONString()

// Deserializes object from a XML string and XMLDataType.
//
// Parameters:
//  XMLValue     - String - the value to be deserialized.
//  TypeName     - String - XML type name. 
//  NamespaceURI - String - XML type URI namespace.
//
// Returns:
//  Arbitrary - deserialized object from the XML string and XMLDataType.
//
Function ValueFromXMLTypeAndValue(XMLValue, TypeName, NamespaceURI) Export
    
    Try
        
        Type = FromXMLType(TypeName, NamespaceURI);
        Return XMLValue(Type, XMLValue);
        
    Except
        
        WriteLogEvent("FoxyLink", 
            EventLogLevel.Error,
            Metadata.CommonModules.FL_CommonUse,
            ,
            ErrorDescription());
        
    EndTry;
    
    Return Undefined; 
    
EndFunction // ValueFromXMLTypeAndValue()

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
        ElsIf Type = Type("Number") Then
            ConvertValueIntoNumber(Value, ConversionResult);
        ElsIf Type = Type("Date") Then
            ConvertValueIntoDate(Value, ConversionResult);
        ElsIf Type = Type("StandardPeriod") Then
            ConvertValueIntoStandardPeriod(Value, ConversionResult);
        ElsIf IsReference(Type) Then
            ConvertValueIntoReference(Value, Type, ConversionResult);
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

#Region MetadataTree

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
Procedure AddToMetadataTreeCollection(MetadataTreeRow, CollectionRow, 
    MetadataObject, Filter)
                
    If Filter <> Undefined Then
        
        ObjectPassedFilter = True;
        For Each FilterItem In Filter Do
            
            FullNameMO = MetadataObject.FullName();
            If FilterItem.Key = "MetadataObjectClass" Then
                Position = StrFind(FullNameMO, "."); 
                Value = StrTemplate("%1%2", Left(FullNameMO, Position), "*");
            ElsIf FilterItem.Key = "FullName" Then
                Value = MetadataObject.FullName();
            Else
                Value = MetadataObject[FilterItem.Key];
            EndIf;
            
            If FilterItem.Value.Find(Value) = Undefined 
                AND FilterItem.Value.Find(FullNameMO) = Undefined Then
                ObjectPassedFilter = False;
                Break;
            EndIf;
            
        EndDo;
        
        If NOT ObjectPassedFilter Then
            Return;
        EndIf;
        
    EndIf;
    
    MOTreeRow = MetadataTreeRow.Rows.Add();
    MOTreeRow.Name         = MetadataObject.Name;
    MOTreeRow.FullName     = MetadataObject.FullName();
    MOTreeRow.Synonym      = MetadataObject.Synonym;
    MOTreeRow.Picture      = CollectionRow.ObjectPicture;
    MOTreeRow.PictureIndex = CollectionRow.PictureIndex;
                
EndProcedure // AddToMetadataTreeCollection() 

// Only for internal use.
//
Procedure FillMetadataTreeCollection(MetadataTree, CollectionsOfMetadataObjects, 
    Filter)
    
    For Each CollectionRow In CollectionsOfMetadataObjects Do
        
        TreeRow = MetadataTree.Rows.Add();
        FillPropertyValues(TreeRow, CollectionRow);
        For Each MetadataObject In Metadata[CollectionRow.Name] Do
            
            AddToMetadataTreeCollection(TreeRow, CollectionRow, MetadataObject, 
                Filter);
            
        EndDo;
        
    EndDo;
    
EndProcedure // FillMetadataTreeCollection() 

// Only for internal use.
//
Procedure AddScheduledJob(CollectionsOfMetadataObjects)
    
    NewMetadataObjectCollectionRow(TypeNameScheduledJobs(),               
        NStr("en='Scheduled jobs';
            |ru='Регламентные задания';
            |uk='Регламентні завдання';
            |en_CA='Scheduled jobs'"),                 
        PictureLib.ScheduledJob,              
        PictureLib.ScheduledJob,        
        FL_CommonUseReUse.ScheduledJobPicSequenceIndex(),
        CollectionsOfMetadataObjects);
    
EndProcedure // AddScheduledJob()

// Only for internal use.
//
Procedure AddHTTPService(CollectionsOfMetadataObjects)
    
    NewMetadataObjectCollectionRow(TypeNameHTTPServices(),               
        NStr("en='HTTP services';
            |ru='HTTP-сервисы';
            |uk='HTTP-сервіси';
            |en_CA='HTTP services'"),                 
        PictureLib.GeographicalSchema,              
        PictureLib.GeographicalSchema,        
        FL_CommonUseReUse.HTTPServicePicSequenceIndex(),
        CollectionsOfMetadataObjects);
    
EndProcedure // AddHTTPService()

// Only for internal use.
//
Procedure AddConstant(CollectionsOfMetadataObjects)
    
    NewMetadataObjectCollectionRow(TypeNameConstants(),               
        NStr("en='Constants';
            |ru='Константы';
            |uk='Константи';
            |en_CA='Constants'"),                 
        PictureLib.Constant,              
        PictureLib.Constant,        
        FL_CommonUseReUse.ConstantPicSequenceIndex(),
        CollectionsOfMetadataObjects);
    
EndProcedure // AddConstant()

// Only for internal use.
//
Procedure AddCatalog(CollectionsOfMetadataObjects)
    
    NewMetadataObjectCollectionRow(TypeNameCatalogs(),             
        NStr("en='Catalogs';
            |ru='Справочники';
            |uk='Довідники';
            |en_CA='Catalogs'"),               
        PictureLib.Catalog,             
        PictureLib.Catalog,
        FL_CommonUseReUse.CatalogPicSequenceIndex(),
        CollectionsOfMetadataObjects);

EndProcedure // AddCatalog()

// Only for internal use.
//
Procedure AddDocument(CollectionsOfMetadataObjects)
    
    NewMetadataObjectCollectionRow(TypeNameDocuments(),               
        NStr("en='Documents';
            |ru='Документы';
            |uk='Документи';
            |en_CA='Documents'"),                 
        PictureLib.Document,               
        PictureLib.DocumentObject,
        FL_CommonUseReUse.DocumentPicSequenceIndex(),
        CollectionsOfMetadataObjects);

EndProcedure // AddDocument()

// Only for internal use.
//
Procedure AddChartOfCharacteristicTypes(CollectionsOfMetadataObjects)
    
    NewMetadataObjectCollectionRow(TypeNameChartsOfCharacteristicTypes(), 
        NStr("en='Charts of characteristics types';
            |ru='Планы видов характеристик';
            |uk='Плани видів характеристик';
            |en_CA='Charts of characteristics types'"), 
        PictureLib.ChartOfCharacteristicTypes, 
        PictureLib.ChartOfCharacteristicTypesObject,
        FL_CommonUseReUse.ChartOfCharacteristicTypePicSequenceIndex(),
        CollectionsOfMetadataObjects);

EndProcedure // AddChartOfCharacteristicTypes() 

// Only for internal use.
//
Procedure AddChartOfAccounts(CollectionsOfMetadataObjects)
       
    NewMetadataObjectCollectionRow(TypeNameChartsOfAccounts(),             
        NStr("en='Charts of accounts';
            |ru='Планы счетов';
            |uk='Плани рахунків';
            |en_CA='Charts of accounts'"),              
        PictureLib.ChartOfAccounts,             
        PictureLib.ChartOfAccountsObject,
        FL_CommonUseReUse.ChartOfAccountPicSequenceIndex(),
        CollectionsOfMetadataObjects);

EndProcedure // AddChartOfAccounts()

// Only for internal use.
//
Procedure AddChartOfCalculationTypes(CollectionsOfMetadataObjects)

    NewMetadataObjectCollectionRow(TypeNameChartsOfCalculationTypes(),       
        NStr("en='Charts of calculation types';
            |ru='Планы видов расчета';
            |uk='Плани видів розрахунків';
            |en_CA='Charts of calculation types'"), 
        PictureLib.ChartOfCalculationTypes, 
        PictureLib.ChartOfCalculationTypesObject,
        FL_CommonUseReUse.ChartOfCalculationTypePicSequenceIndex(),
        CollectionsOfMetadataObjects);

EndProcedure // AddChartOfCalculationTypes()

// Only for internal use.
//
Procedure AddInformationRegister(CollectionsOfMetadataObjects)
    
    NewMetadataObjectCollectionRow(TypeNameInformationRegisters(),        
        NStr("en='Information registers';
            |ru='Регистры сведений';
            |uk='Регістр відомостей';
            |en_CA='Information registers'"),         
        PictureLib.InformationRegister,        
        PictureLib.InformationRegister,
        FL_CommonUseReUse.InformationRegisterPicSequenceIndex(),
        CollectionsOfMetadataObjects);
        
EndProcedure // AddInformationRegister()
        
// Only for internal use.
//
Procedure AddAccumulationRegister(CollectionsOfMetadataObjects)
        
    NewMetadataObjectCollectionRow(TypeNameAccumulationRegisters(),      
        NStr("en='Accumulation registers';
            |ru='Регистры накопления';
            |uk='Регістр накопичення';
            |en_CA='Accumulation registers'"),       
        PictureLib.AccumulationRegister,      
        PictureLib.AccumulationRegister,
        FL_CommonUseReUse.AccumulationRegisterPicSequenceIndex(),
        CollectionsOfMetadataObjects);
        
EndProcedure // AddAccumulationRegister()
       
// Only for internal use.
//
Procedure AddAccountingRegister(CollectionsOfMetadataObjects)
       
    NewMetadataObjectCollectionRow(TypeNameAccountingRegisters(),     
        NStr("en='Accounting registers';
            |ru='Регистры бухгалтерии';
            |uk='Регістр бехгалтерії';
            |en_CA='Accounting registers'"),      
        PictureLib.AccountingRegister,     
        PictureLib.AccountingRegister, 
        FL_CommonUseReUse.AccountingRegisterPicSequenceIndex(),
        CollectionsOfMetadataObjects);
        
EndProcedure // AddAccountingRegister()        

// Only for internal use.
//
Procedure AddCalculationRegister(CollectionsOfMetadataObjects)
       
    NewMetadataObjectCollectionRow(TypeNameCalculationRegisters(),         
        NStr("en='Calculation registers';
            |ru='Регистры расчета';
            |uk='Регістр розрахунків';
            |en_CA='Calculation registers'"),          
        PictureLib.CalculationRegister,         
        PictureLib.CalculationRegister,
        FL_CommonUseReUse.CalculationRegisterPicSequenceIndex(),
        CollectionsOfMetadataObjects);
        
EndProcedure // AddCalculationRegister()

// Only for internal use.
//
Procedure AddBusinessProcess(CollectionsOfMetadataObjects)
    
    NewMetadataObjectCollectionRow(TypeNameBusinessProcess(),          
        NStr("en='Business processes';
            |ru='Бизнес-процессы';
            |uk='Бізнес-процеси';
            |en_CA='Business processes'"),           
        PictureLib.BusinessProcess,          
        PictureLib.BusinessProcessObject,
        FL_CommonUseReUse.BusinessProcessPicSequenceIndex(),
        CollectionsOfMetadataObjects);
 
EndProcedure // AddBusinessProcess()
       
// Only for internal use.
//
Procedure AddTask(CollectionsOfMetadataObjects)
    
    NewMetadataObjectCollectionRow(TypeNameTasks(),                  
        NStr("en='Tasks';
            |ru='Задания';
            |uk='Завдання';
            |en_CA='Tasks'"),                    
        PictureLib.Task,                 
        PictureLib.TaskObject,
        FL_CommonUseReUse.TaskPicSequenceIndex(),
        CollectionsOfMetadataObjects);
        
EndProcedure // AddTask()

#EndRegion // MetadataTree 

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

    ErrorMessage = NStr("en='An error occurred in the {FixedData} function of the FL_CommonUse common module. 
        |Data of the {%1} type can not be recorded.';
        |ru='Ошибка в функции {FixedData} общего модуля FL_CommonUse.
        |Данные типа {%1} не могут быть зафиксированы.';
        |en_CA='An error occurred in the {FixedData} function of the FL_CommonUse common module.
        |Data of the {%1} type can not be recorded.'");
    
    Raise StrTemplate(ErrorMessage, String(DataType));

EndProcedure // CheckingDataFixed()

#Region ObjectTypes

// Only for internal use.
//
Procedure FillInformationRegisterPrimaryKeys(MetadataObject, PrimaryKeys)

    If MetadataObject.InformationRegisterPeriodicity <> 
        Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical Then
        
        Types = New Array;
        Types.Add(Type("Date"));
        PrimaryKeys.Insert("Period", Types);
        
    EndIf;
    
    If MetadataObject.WriteMode = 
        Metadata.ObjectProperties.RegisterWriteMode.RecorderSubordinate Then
        
        RecorderAttribute = MetadataObject.StandardAttributes.Recorder;
        PrimaryKeys.Insert("Recorder", RecorderAttribute.Type.Types());
        
    EndIf;

    For Each Dimension In MetadataObject.Dimensions Do
        PrimaryKeys.Insert(Dimension.Name, Dimension.Type.Types());    
    EndDo;

EndProcedure // FillInformationRegisterPrimaryKeys()

// Only for internal use.
//
Procedure FillAccumulationRegisterPrimaryKeys(MetadataObject, PrimaryKeys)
        
    StandardAttributes = MetadataObject.StandardAttributes;
    RecorderAttribute = StandardAttributes["Recorder"];
    PrimaryKeys.Insert("Recorder", RecorderAttribute.Type.Types());

    For Each Dimension In MetadataObject.Dimensions Do
        PrimaryKeys.Insert(Dimension.Name, Dimension.Type.Types());    
    EndDo;

EndProcedure // FillAccumulationRegisterPrimaryKeys()

// Only for internal use.
//
Procedure ProcessRecalculationObjectManager(Manager, Parts, MetaObjectName, MetaObjectType)
    
    MetaObjectTypeIndex = 2;
    MetaObjectNameIndex = 3;
    
    MetaObjectType = Upper(Parts[MetaObjectTypeIndex]);
    If MetaObjectType = "RECALCULATION"
        OR MetaObjectType = "ПЕРЕРАСЧЕТ" Then
        
        Try
            Manager = Manager[MetaObjectName].Recalculations;
            MetaObjectName = Parts[MetaObjectNameIndex];
        Except
            Manager = Undefined;
        EndTry;
        
    EndIf;

EndProcedure // ProcessRecalculationObjectManager()

#EndRegion // ObjectTypes

#Region ValueConversion

// Converts value into {String} type.
//
// Parameters:
//  Value            - Arbitrary - value to be converted into {String} type.
//  ConversionResult - Structure - see function FL_CommonUse.NewConversionResult.
//
Procedure ConvertValueIntoString(Value, ConversionResult)

    TypeMatch = ValueTypeMatchExpected(Value, Type("String"), 
        ConversionResult);    
    If TypeMatch Then
        ConversionResult.TypeConverted = True;
        ConversionResult.ConvertedValue = Value;
    EndIf;
                        
EndProcedure // ConvertValueIntoString()

// Converts value into {Number} type.
//
// Parameters:
//  Value            - Arbitrary - value to be converted into {Number} type.
//  ConversionResult - Structure - see function FL_CommonUse.NewConversionResult.
//
Procedure ConvertValueIntoNumber(Value, ConversionResult)

    TypeMatch = ValueTypeMatchExpected(Value, Type("Number"), 
        ConversionResult);    
    If TypeMatch Then
        ConversionResult.TypeConverted = True;
        ConversionResult.ConvertedValue = Value;
    EndIf;
                        
EndProcedure // ConvertValueIntoNumber()

// Converts value into {Date} type.
//
// Parameters:
//  Value            - Arbitrary - value to be converted into {Date} type.
//  ConversionResult - Structure - see function FL_CommonUse.NewConversionResult.
//
Procedure ConvertValueIntoDate(Value, ConversionResult)

    TypeMatch = ValueTypeMatchExpected(Value, Type("String"), 
        ConversionResult);
    If TypeMatch Then
    
        ConvertedValue = ConvertStringIntoDate(Value);
        TypeMatch = ValueTypeMatchExpected(ConvertedValue, Type("Date"), 
            ConversionResult);    
        If TypeMatch Then
            ConversionResult.TypeConverted = True;
            ConversionResult.ConvertedValue = ConvertedValue;
        EndIf;
        
    EndIf;
                        
EndProcedure // ConvertValueIntoDate()

// Converts value into {StandardPeriod} type.
//
// Parameters:
//  Value            - Arbitrary - value to be converted into {StandardPeriod} type.
//  ConversionResult - Structure - see function FL_CommonUse.NewConversionResult.
//
Procedure ConvertValueIntoStandardPeriod(Value, ConversionResult)

    Var StartDate, EndDate, Variant;

    TypeMatch = ValueTypeMatchExpected(Value, Type("Structure"), 
        ConversionResult);
    If NOT TypeMatch Then
        Return;
    EndIf;
        
    FoundVariant = Value.Property("Variant", Variant)
        OR Value.Property("Вариант", Variant);
        
    FoundStartDate = Value.Property("StartDate", StartDate)
        OR Value.Property("ДатаНачала", StartDate);
                   
    FoundEndDate = Value.Property("EndDate", EndDate)
        OR Value.Property("ДатаОкончания", EndDate);
        
    If FoundStartDate AND FoundEndDate Then
        ConvertValueIntoStandardPeriodUsingDate(StartDate, EndDate, 
            ConversionResult);   
    EndIf;
            
    If FoundVariant Then
        ConvertValueIntoStandardPeriodUsingVariant(Variant, ConversionResult);         
    EndIf;

    If NOT ConversionResult.TypeConverted Then
        
        ErrorMessage = StrTemplate(
            NStr("en='%1 Unable to parse {StandardPeriod} ({StartDate} and {EndDate} or {Variant} not found).'; 
                |ru='%1 Не удалось распознать {СтандартныйПериод} ({ДатаНачала} и {ДатаОкончания} или {Вариант} не найдены).'; 
                |uk='%1 Не вдалось розпізнати {СтандартнийПеріод} ({ДатаПочатку} та [ДатаЗакінчення} чи {Варіант} не знайдено).';
                |en_CA='%1 Unable to parse {StandardPeriod} ({StartDate} and {EndDate} or {Variant} not found).'"),
            FL_ErrorsClientServer.ErrorFailedToProcessParameterTemplate());
        ConversionResult.ErrorMessages.Add(ErrorMessage);                
            
    EndIf;      
        
EndProcedure // ConvertValueIntoStandardPeriod()

// Only for internal use.
//
Procedure ConvertValueIntoStandardPeriodUsingDate(StartDate, EndDate, 
    ConversionResult)
    
    If ConversionResult.TypeConverted Then
        Return;
    EndIf;
    
    StartDate = ConvertStringIntoDate(StartDate);
    TypeMatchSD = ValueTypeMatchExpected(StartDate, Type("Date"), 
        ConversionResult);
        
    EndDate = ConvertStringIntoDate(EndDate);
    TypeMatchED = ValueTypeMatchExpected(EndDate, Type("Date"), 
        ConversionResult);
        
    If TypeMatchSD AND TypeMatchED Then
        
        StandardPeriod = New StandardPeriod(StartDate, EndDate);
        If StandardPeriod.StartDate <= StandardPeriod.EndDate Then
            
            ConversionResult.TypeConverted = True;
            ConversionResult.ConvertedValue = StandardPeriod;
            Return;
            
        Else
            
            ErrorMessage = StrTemplate(
                NStr("en='%1 {StartDate} is greater than {EndDate}.'; 
                    |ru='%1 {ДатаНачала} не может быть больше {ДатаОкончания}.'; 
                    |uk='%1 {ДатаПочатку} не може бути більшою {ДатиЗакінення}.';
                    |en_CA='%1 {StartDate} is greater than {EndDate}.'"),
                FL_ErrorsClientServer.ErrorFailedToProcessParameterTemplate());
            ConversionResult.ErrorMessages.Add(ErrorMessage);
            
        EndIf;
        
    EndIf;
    
EndProcedure // ConvertValueIntoStandardPeriodUsingDate()

// Only for internal use.
//
Procedure ConvertValueIntoStandardPeriodUsingVariant(Variant, ConversionResult)

    If ConversionResult.TypeConverted Then
        Return;
    EndIf;
    
    TypeMatchV = ValueTypeMatchExpected(Variant, Type("String"), 
        ConversionResult);   
    If TypeMatchV Then
        
        Try
    
            StandardPeriod = New StandardPeriod(
                StandardPeriodVariant[Variant]);
                
            ConversionResult.TypeConverted = True;
            ConversionResult.ConvertedValue = StandardPeriod;
            Return;

        Except
            
            ErrorMessage = StrTemplate(
                NStr("en='%1 {Variant} is unknown. %2'; 
                    |ru='%1 {Вариант} неизвестен. %2'; 
                    |uk='%1 {Варіант} невідомий. %2';
                    |en_CA='%1 {Variant} is unknown. %2'"),
                FL_ErrorsClientServer.ErrorFailedToProcessParameterTemplate(), 
                ErrorDescription());        
            ConversionResult.ErrorMessages.Add(ErrorMessage);
            
        EndTry;
        
    EndIf; 
    
EndProcedure // ConvertValueIntoStandardPeriodUsingVariant()

// Converts value into {Reference} type.
//
// Parameters:
//  Value            - Arbitrary - value to be converted into {Reference} type.
//  Type             - Type      - the type of the object to which the value is converted. 
//  ConversionResult - Structure - see function FL_CommonUse.NewConversionResult.
//
Procedure ConvertValueIntoReference(Value, Type, ConversionResult)
    
    TypeMatch = ValueTypeMatchExpected(Value, Type("Structure"), 
        ConversionResult);
    If NOT TypeMatch Then
        Return;
    EndIf;
       
    Try
        TypeEmptyRef = New(Type);
    Except
        
        ErrorMessage = StrTemplate(
            NStr("en='%1 Unable to indetify object type for {%2}. %3.'; 
                |ru='%1 Не удалось идетифицировать тип значения для {%2}. %3.'; 
                |uk='%1 Не вдалось ідентифікувати тип значення для {%2}. %3.';
                |en_CA='%1 Unable to indetify object type for {%2}. %3.'"),
            FL_ErrorsClientServer.ErrorFailedToProcessParameterTemplate(), 
            String(Type), ErrorDescription()); 
        ConversionResult.ErrorMessages.Add(ErrorMessage);    
        Return;
        
    EndTry;
    
    Try
        ObjectManager = ObjectManagerByReference(TypeEmptyRef);
    Except
        
        ErrorMessage = StrTemplate(
            NStr("en='%1 Unable to indetify object manager for {%2}. %3.'; 
                |ru='%1 Не удалось идетифицировать менеджер значения для {%2}. %3.'; 
                |uk='%1 Не вдалось ідентифікувати менеджер значення для {%2}. %3.';
                |en_CA='%1 Unable to indetify object manager for {%2}. %3.'"),
            FL_ErrorsClientServer.ErrorFailedToProcessParameterTemplate(), 
            String(Type), ErrorDescription()); 
        ConversionResult.ErrorMessages.Add(ErrorMessage);    
        Return;
        
    EndTry;
    
    ConvertValueIntoReferenceUsingGUID(Value, Type, ConversionResult);
    ConvertValueIntoReferenceUsingCode(Value, Type, ObjectManager, 
        TypeEmptyRef, ConversionResult);
    ConvertValueIntoReferenceUsingEnum(Value, Type, ObjectManager,
        ConversionResult); 
    ConvertValueIntoReferenceUsingNumber(Value, Type, ObjectManager, 
        TypeEmptyRef, ConversionResult); 
    ConvertValueIntoReferenceUsingDescription(Value, Type, ObjectManager, 
        TypeEmptyRef, ConversionResult);
    
    If NOT ConversionResult.TypeConverted Then 
        
        ErrorMessage = StrTemplate(
            NStr("en='%1 Unable to find {%2}.'; 
                |ru='%1 Не удалось найти {%2}.'; 
                |uk='%1 Не вдалось знайти {%2}.'"),
            FL_ErrorsClientServer.ErrorFailedToProcessParameterTemplate(),        
            String(Type));
        ConversionResult.ErrorMessages.Add(ErrorMessage);
        
    EndIf;       
    
EndProcedure // ConvertValueIntoReference()

// Only for internal use.
//
Procedure ConvertValueIntoReferenceUsingGUID(Value, Type, ConversionResult)
    
    Var KeyValue;
    
    If ConversionResult.TypeConverted Then
        Return;
    EndIf;
    
    // Search for an object using a unique identifier.
    If Value.Property("Guid", KeyValue)
        OR Value.Property("УникальныйИдентификатор", KeyValue) Then
     
         If ValueMatchUniqueIdentifier(KeyValue, ConversionResult) Then
            
            ConvertedValue = XMLValue(Type, KeyValue);
            If RefExists(ConvertedValue) Then
                
                ConversionResult.TypeConverted = True;
                ConversionResult.ConvertedValue = ConvertedValue;
                Return;
                
            Else
                
                ErrorMessage = StrTemplate(
                    NStr("en='%1 Unable to find {%2} with guid {%3}.'; 
                        |ru='%1 Не удалось найти {%2} c уникальным идентификатором {%3}.'; 
                        |uk='%1 Не вдалось знайти {%2} з унікальним ідентифікатором {%3}.';
                        |en_CA='%1 Unable to find {%2} with guid {%3}.'"),
                    FL_ErrorsClientServer.ErrorFailedToProcessParameterTemplate(),                         
                    String(Type), KeyValue);   
                ConversionResult.ErrorMessages.Add(ErrorMessage);

            EndIf;
                        
        EndIf;
             
    EndIf;
    
EndProcedure // ConvertValueIntoReferenceUsingGUID()

// Only for internal use.
//
Procedure ConvertValueIntoReferenceUsingCode(Value, Type, ObjectManager, 
    TypeEmptyRef, ConversionResult)
    
    Var KeyValue;
    
    If ConversionResult.TypeConverted Then
        Return;
    EndIf;
    
    // Search for an object using a code.
    If Value.Property("Code", KeyValue)
        OR Value.Property("Код", KeyValue) Then
        
        If ValueMatchCodeType(KeyValue, TypeEmptyRef, ConversionResult) Then
            
            ConvertedValue = ObjectManager.FindByCode(KeyValue);
            If NOT ConvertedValue.IsEmpty() Then
                
                ConversionResult.TypeConverted = True;
                ConversionResult.ConvertedValue = ConvertedValue;
                Return;
                
            Else
                
                ErrorMessage = StrTemplate(
                    NStr("en='%1 Unable to find {%2} with Code {%3}.'; 
                        |ru='%1 Не удалось найти {%2} c Кодом {%3}.'; 
                        |uk='%1 Не вдалось знайти {%2} з Кодом {%3}.';
                        |en_CA='%1 Unable to find {%2} with Code {%3}.'"),
                    FL_ErrorsClientServer.ErrorFailedToProcessParameterTemplate(),  
                    String(Type), String(KeyValue));                                           
                ConversionResult.ErrorMessages.Add(ErrorMessage);
                
            EndIf;
            
        EndIf;
                
    EndIf;
        
EndProcedure // ConvertValueIntoReferenceUsingCode()

// Only for internal use.
//
Procedure ConvertValueIntoReferenceUsingEnum(Value, Type, ObjectManager, 
    ConversionResult)
    
    Var KeyValue;
    
    If ConversionResult.TypeConverted Then
        Return;
    EndIf;
    
    // Search for an object using a enum name.
    If Value.Property("EnumValueName", KeyValue)
        OR Value.Property("ПеречислениеИмяЗначения", KeyValue) Then
     
        ConvertValueIntoReferenceUsingEnumValueName(KeyValue, Type, 
            ObjectManager, ConversionResult);    
             
    EndIf;
    
    // Search for an object using a enum index.
    If Value.Property("EnumValueIndex", KeyValue)
        OR Value.Property("ПеречислениеИндексЗначения", KeyValue) Then
        
        ConvertValueIntoReferenceUsingEnumValueIndex(KeyValue, Type, 
            ObjectManager, ConversionResult);      
     
    EndIf;
    
EndProcedure // ConvertValueIntoReferenceUsingEnum()

// Only for internal use.
//
Procedure ConvertValueIntoReferenceUsingEnumValueName(Value, Type, 
    ObjectManager, ConversionResult)
    
    If ConversionResult.TypeConverted Then
        Return;
    EndIf;
    
    TypeMatch = ValueTypeMatchExpected(TypeOf(Value), 
        Type("String"), ConversionResult);
        
    If TypeMatch Then
        
        Try
            
            ConvertedValue = ObjectManager[Value];
            ConversionResult.TypeConverted = True;                
            ConversionResult.ConvertedValue = ConvertedValue;
            Return;
        
        Except
            
            ErrorMessage = StrTemplate(
                NStr("en='%1 Enum {%2} value name {%3} not found. %4.'; 
                    |ru='%1 Наименование значения {%3} перечисления {%2} не найдено. %4.'; 
                    |uk='%1 Назва значення {%3} переліку {%2} не знайдено. %4.';
                    |en_CA='%1 Enum {%2} value name {%3} not found. %4.'"),
                FL_ErrorsClientServer.ErrorFailedToProcessParameterTemplate(),                        
                String(Type), Value, ErrorDescription());
            ConversionResult.ErrorMessages.Add(ErrorMessage);    
            
        EndTry;
        
    EndIf;
    
EndProcedure // ConvertValueIntoReferenceUsingEnumValueName()

// Only for internal use.
//
Procedure ConvertValueIntoReferenceUsingEnumValueIndex(Value, Type, 
    ObjectManager, ConversionResult)
    
    If ConversionResult.TypeConverted Then
        Return;
    EndIf;
    
    TypeMatch = ValueTypeMatchExpected(TypeOf(Value), 
        Type("Number"), ConversionResult);
        
    If TypeMatch Then
        
        If Value >= 0 AND Value < ObjectManager.Count() Then
            
            ConvertedValue = ObjectManager.Get(Value);
            ConversionResult.TypeConverted = True;                
            ConversionResult.ConvertedValue = ConvertedValue;
            Return;
            
        Else
            
            ErrorMessage = StrTemplate(
                NStr("en='%1 Enum {%2} value index {%3} is out of range.'; 
                    |ru='%1 Индекс {%3} перечисления {%2} находится вне диапазона.'; 
                    |uk='%1 Індекс {%3} переліку {%2} знаходиться поза діапазоном.';
                    |en_CA='%1 Enum {%2} value index {%3} is out of range."),
                FL_ErrorsClientServer.ErrorFailedToProcessParameterTemplate(),                          
                String(Type), String(Value));
            ConversionResult.ErrorMessages.Add(ErrorMessage);
    
        EndIf;
        
    EndIf;       
    
EndProcedure // ConvertValueIntoReferenceUsingEnumValueIndex()

// Only for internal use.
//
Procedure ConvertValueIntoReferenceUsingNumber(Value, Type, ObjectManager, 
    TypeEmptyRef, ConversionResult)
    
    Var KeyValue;
    
    If ConversionResult.TypeConverted Then
        Return;
    EndIf;
    
    // Search for an object using a unique identifier.
    If Value.Property("Number", KeyValue)
        OR Value.Property("Номер", KeyValue) Then
      
        ErrorMessage = StrTemplate(
            NStr("en='%1 Currently search by {Number} field not supported.'; 
                |ru='%1 На текущий момент поиск по полю {Номер} не поддерживается.'; 
                |uk='%1 На даний час пошук по полю {Номер} не підтримується.';
                |en_CA='%1 Currently search by {Number} field not supported.'"),
            FL_ErrorsClientServer.ErrorFailedToProcessParameterTemplate());   
        ConversionResult.ErrorMessages.Add(ErrorMessage);
                       
    EndIf;
    
EndProcedure // ConvertValueIntoReferenceUsingNumber()

// Only for internal use.
//
Procedure ConvertValueIntoReferenceUsingDescription(Value, Type, ObjectManager, 
    TypeEmptyRef, ConversionResult)
    
    Var KeyValue;
    
    If ConversionResult.TypeConverted Then
        Return;
    EndIf;
    
    // Search for an object using a unique identifier.
    If Value.Property("Description", KeyValue)
        OR Value.Property("Наименование", KeyValue) Then
     
        ErrorMessage = StrTemplate(
            NStr("en='%1 Currently search by {Description} field not supported.'; 
                |ru='%1 На текущий момент поиск по полю {Наименование} не поддерживается.'; 
                |uk='%1 На даний час пошук по полю {Наименование} не підтримується.';
                |en_CA='%1 Currently search by {Description} field not supported.'"),
            FL_ErrorsClientServer.ErrorFailedToProcessParameterTemplate());   
        ConversionResult.ErrorMessages.Add(ErrorMessage);
             
    EndIf;
    
EndProcedure // ConvertValueIntoReferenceUsingDescription()

// Returns base convertion result structure.
//
// Returns:
//  Structure - convertion result structure.
//      * ConvertedValue - Arbitrary - converted value.
//      * TypeConverted  - Boolean   - initial value 'False', when 'True' is set 
//                                    it means value conversion was successful.
//                          Default value: False.
//      * ErrorMessages  - Array     - conversion error messages.
//          ** ArrayItem - String - conversion error message.
//
Function NewConversionResult()

    ConversionResult = New Structure;
    ConversionResult.Insert("ConvertedValue");
    ConversionResult.Insert("TypeConverted", False);
    ConversionResult.Insert("ErrorMessages", New Array);
    Return ConversionResult;

EndFunction // NewConversionResult()

// Converts a string into a date type value.
//
// Parameters:
//  StringDate - String - string to be converted to a date.
//
// Returns:
//  Date - converted value.
//
Function ConvertStringIntoDate(StringDate)
    
    Var ConvertedValue;

    If ConvertStringIntoDateByFormat(StringDate, JSONDateFormat.ISO, ConvertedValue) Then
        Return ConvertedValue;
    EndIf;

    If ConvertStringIntoDateByFormat(StringDate, JSONDateFormat.JavaScript, ConvertedValue) Then
        Return ConvertedValue;
    EndIf;

    If ConvertStringIntoDateByFormat(StringDate, JSONDateFormat.Microsoft, ConvertedValue) Then
        Return ConvertedValue;
    EndIf;

    Try
        ConvertedValue = Date(StringDate);
    Except
        ConvertedValue = Undefined;
    EndTry;

    Return ConvertedValue;    
    
EndFunction // ConvertStringIntoDate()

// Only for internal use.
//
Function ConvertStringIntoDateByFormat(Val StringDate, Format, ConvertedValue)

    Try
        ConvertedValue = ReadJSONDate(StringDate, Format);
    Except
        Return False; 
    EndTry;

    Return True;

EndFunction // ConvertStringIntoDateByFormat()

// Only for internal use.
//
Function ValueMatchUniqueIdentifier(Value, ConversionResult)
    
    If TypeOf(Value) = Type("UUID") Then
        Return True;
    EndIf;
    
    If TypeOf(Value) <> Type("String") Then
        
        ErrorMessage = StrTemplate(
            NStr("en='%1 Guid expected type {%2} and received type is {%3}.'; 
                |ru='%1 Уникальный идентификатор ожидался тип {%2}, а получили тип {%3}.'; 
                |uk='%1 Унікальний ідентифікатор очікувався тип {%2}, але отримали тип {%3}.';
                |en_CA='%1 Guid expected type {%2} and received type is {%3}.'"),
            FL_ErrorsClientServer.ErrorFailedToProcessParameterTemplate(),
            String(Type("String")), String(TypeOf(Value)));
        ConversionResult.ErrorMessages.Add(ErrorMessage);    
        Return False;
        
    EndIf;
        
    If IsBlankString(Value) Then
        
        ErrorMessage = StrTemplate(
            NStr("en='%1 Guid cannot be empty.'; 
                |ru='%1 Уникальный идентификатор не может быть пустым.'; 
                |uk='%1 Унікальний ідентифікатор не може бути порожнім.';
                |en_CA='%1 Guid cannot be empty.'"),
            FL_ErrorsClientServer.ErrorFailedToProcessParameterTemplate());
        ConversionResult.ErrorMessages.Add(ErrorMessage);    
        Return False;        
            
    EndIf;

    GuidLength = 36;
    If StrLen(TrimAll(Value)) <> GuidLength Then
        
         ErrorMessage = StrTemplate(
            NStr("en='%1 Guid must be 36 symbols long.'; 
                |ru='%1 Уникальный идентификатор должен иметь длину 36 символов.'; 
                |uk='%1 Унікальний ідентифікатор повинен мати довжину 36 символів.';
                |en_CA='%1 Guid must be 36 symbols long.'"),
            FL_ErrorsClientServer.ErrorFailedToProcessParameterTemplate());
        ConversionResult.ErrorMessages.Add(ErrorMessage);    
        Return False;
            
    EndIf;

    If NOT UniqueIdentifierHypenValid(Value) Then
        
        ErrorMessage = StrTemplate(
            NStr("en='%1 Guid must contain the symbol {-} on 9, 14, 19, 24 positions.'; 
                |ru='%1 Уникальный идентификатор должен содержать символ {-} на 9, 14, 19, 24 позициях.'; 
                |uk='%1 Унікальний ідентифікатор повинен містити символ {-} на 9, 14, 19, 24 позиціях.'
                |en_CA='%1 Guid must contain the symbol {-} on 9, 14, 19, 24 positions.'"),
            FL_ErrorsClientServer.ErrorFailedToProcessParameterTemplate());
        ConversionResult.ErrorMessages.Add(ErrorMessage);    
        Return False;
            
    EndIf;

    For Index = 1 To StrLen(Value) Do
        
        If NOT UniqueIdentifierHypenPosition(Index) Then
            
            Symbol = Mid(Value, Index, 1);
            If NOT FL_CommonUseClientServer.IsLatinLetter(Symbol)
               AND NOT  FL_CommonUseClientServer.IsNumber(Symbol) Then
               
                ErrorMessage = StrTemplate(
                    NStr("en='%1 Guid contains illegal characters. Latin letters and numbers are allowed only.';
                        |ru='%1 Уникальный идентификатор содержит запрещенные символы. Разрешены только латинские буквы и цифры.';
                        |uk='%1 Унікальний ідентифікатор містить заборонені символи. Дозволені тільки латинські літери та цифри.';
                        |en_CA='%1 Guid contains illegal characters. Latin letters and numbers are allowed only.'"),
                    FL_ErrorsClientServer.ErrorFailedToProcessParameterTemplate());
                ConversionResult.ErrorMessages.Add(ErrorMessage);    
                Return False;
               
            EndIf;
            
        EndIf;
                
    EndDo;
            
    Return True;

EndFunction // ValueMatchUniqueIdentifier()

// Only for internal use.
//
Function ValueMatchCodeType(Value, TypeEmptyRef, ConversionResult) 
        
    MetadataObject = TypeEmptyRef.Metadata();
    If IsCatalog(MetadataObject) Then
        Return ValueMatchCatalogCodeType(Value, MetadataObject, 
            ConversionResult);       
    Else
            
        ErrorMessage = StrTemplate(
            NStr("en='%1 Code in {%2} is not supported in configuration.'; 
                |ru='%1 Код в {%2} не поддерживается в конфигурации.'; 
                |uk='%1 Код в {%2} не підтримується в конфігурації.';
                |en_CA='%1 Code in {%2} is not supported in configuration.'"),
            FL_ErrorsClientServer.ErrorFailedToProcessParameterTemplate(), 
            String(TypeOf(TypeEmptyRef))); 
        ConversionResult.ErrorMessages.Add(ErrorMessage);    
        Return False;
                        
    EndIf;

    Return True;
        
EndFunction // ValueMatchCodeType()

// Only for internal use.
//
Function ValueMatchCatalogCodeType(Value, MetadataObject, ConversionResult)
    
    ObjectProperties = Metadata.ObjectProperties;
    If MetadataObject.CodeLength = 0 Then
        
        ErrorMessage =  StrTemplate(
            NStr("en='%1 Code in configuration has zero length.'; 
                |ru='%1 Длина поля Код в конфигурации равна нулю.'; 
                |uk='%1 Довжина поля Код в конфігурації рівна нулю.';
                |en_CA='%1 Code in configuration has zero length.'"),
            FL_ErrorsClientServer.ErrorFailedToProcessParameterTemplate());       
        ConversionResult.ErrorMessages.Add(ErrorMessage);    
        Return False;
            
    EndIf;

    CodeType = MetadataObject.CodeType;
    If CodeType = ObjectProperties.CatalogCodeType.String Then
        
        If TypeOf(Value) <> Type("String") Then 
            
            ErrorMessage = StrTemplate(
                NStr("en='%1 Expected Code type {%2} and received type is {%3}.'; 
                    |ru='%1 Тип Кода ожидался {%2}, а получили тип {%3}.'; 
                    |uk='%1 Тип Коду очікувався {%2}, але отримали тип {%3}.';
                    |en_CA='%1 Expected Code type {%2} and received type is {%3}.'"),
                FL_ErrorsClientServer.ErrorFailedToProcessParameterTemplate(),                          
                String(Type("String")), String(TypeOf(Value))); 
            ConversionResult.ErrorMessages.Add(ErrorMessage);    
            Return False;
                            
        EndIf;
        
    ElsIf CodeType = ObjectProperties.CatalogCodeType.Number Then
        
        If TypeOf(Value) <> Type("Number") Then
            
            ErrorMessage = StrTemplate(
                NStr("en='%1 Expected Code type {%2} and received type is {%3}.'; 
                    |ru='%1 Тип Кода ожидался {%2}, а получили тип {%3}.'; 
                    |uk='%1 Тип Коду очікувався {%2}, але отримали тип {%3}.';
                    |en_CA='%1 Expected Code type {%2} and received type is {%3}.'"),                
                FL_ErrorsClientServer.ErrorFailedToProcessParameterTemplate(),
                String(Type("String")), String(TypeOf(Value)));    
            ConversionResult.ErrorMessages.Add(ErrorMessage);    
            Return False;
            
        EndIf;
        
    Else
        
        ErrorMessage = StrTemplate(
            NStr("en='%1 Code type {%2} not supported.'; 
                |ru='%1 Тип Кода {%2} не поддерживается.'; 
                |uk='%1 Тип Коду {%2} не підтримується.';
                |en_CA='%1 Code type {%2} not supported.'"),
            FL_ErrorsClientServer.ErrorFailedToProcessParameterTemplate(),     
            String(CodeType));   
        ConversionResult.ErrorMessages.Add(ErrorMessage);    
        Return False;
        
    EndIf;
        
    If TypeOf(Value) = Type("Number") Then
        CodeLength = StrLen(Format(Value, "NG=0"));
    Else
        CodeLength = StrLen(TrimAll(Value));
    EndIf;
    
    If MetadataObject.CodeLength < CodeLength Then
        
        ErrorMessage = StrTemplate(
            NStr("en='%1 Code lenght is {%2} and maximum length is {%3}.'; 
                |ru='%1 Длина Кода равна {%2}, что больше максимальной длины {%3}.'; 
                |uk='%1 Довжина Коду рівна {%2}, що більше максимальної {%3}.';
                |en_CA='%1 Code lenght is {%2} and maximum length is {%3}.'"),
            FL_ErrorsClientServer.ErrorFailedToProcessParameterTemplate(),
            CodeLength, MetadataObject.CodeLength);
        ConversionResult.ErrorMessages.Add(ErrorMessage);    
        Return False;
                        
    EndIf;
    
    Return True;
    
EndFunction // ValueMatchCatalogCodeType()

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
        
        ErrorMessage = FL_ErrorsClientServer.ErrorTypeIsDifferentFromExpected(
            "%1", Value, ExpectedType);
        ConversionResult.ErrorMessages.Add(ErrorMessage);
        Return False;
        
    EndIf;
        
    Return True;

EndFunction // ValueTypeMatchExpected()

// Only for internal use.
//
Function UniqueIdentifierHypenValid(Value)
    
    GuidPart09 = 9;
    GuidPart14 = 14;
    GuidPart19 = 19;
    GuidPart24 = 24;
    
    Return Mid(Value, GuidPart09, 1) = "-" AND Mid(Value, GuidPart14, 1) = "-"
       AND Mid(Value, GuidPart19, 1) = "-" AND Mid(Value, GuidPart24, 1) = "-";
    
EndFunction // UniqueIdentifierHypenValid()

// Only for internal use.
//
Function UniqueIdentifierHypenPosition(Index)
    
    GuidPart09 = 9;
    GuidPart14 = 14;
    GuidPart19 = 19;
    GuidPart24 = 24;
    
    Return Index = GuidPart09 OR Index = GuidPart14 
        OR Index = GuidPart19 OR Index = GuidPart24;    
    
EndFunction // UniqueIdentifierHypenPosition()

#EndRegion // ValueConversion

// Only for internal use.
//
Function QueryTextReferenceByDescription()

    QueryText = "
        |SELECT
        |   MetadataObject.Ref AS Ref   
        |FROM
        |   %1 AS MetadataObject
        |WHERE
        |   MetadataObject.Description = &Description
        |";
    Return QueryText;

EndFunction // QueryTextReferenceByDescription() 

// Only for internal use.
//
Function QueryTextReferenceByPredefinedDataName()

    QueryText = "
        |SELECT
        |   MetadataObject.Ref AS Ref   
        |FROM
        |   %1 AS MetadataObject
        |WHERE
        |   MetadataObject.PredefinedDataName = &PredefinedDataName
        |";
    Return QueryText;

EndFunction // QueryTextReferenceByPredefinedDataName()

#EndRegion // ServiceProceduresAndFunctions