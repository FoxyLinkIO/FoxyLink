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

    AttributesStructure = New Structure;
    If TypeOf(Attributes) = Type("Structure") 
        Or TypeOf(Attributes) = Type("FixedStructure") Then
        
        AttributesStructure = Attributes;
        
    ElsIf TypeOf(Attributes) = Type("Array") 
        Or TypeOf(Attributes) = Type("FixedArray") Then
        
        For Each Attribute In Attributes Do
            AttributesStructure.Insert(StrReplace(Attribute, ".", ""), 
                Attribute);
        EndDo;
        
    Else
        
        Raise StrTemplate(NStr("en = 'Invalid type of Attributes second parameter: %1';
                |ru = 'Неверный тип второго параметра Реквизиты: %1'"),
            String(TypeOf(Attributes)));
            
    EndIf;

    FieldText = "";
    For Each KeyAndValue In AttributesStructure Do
        
        FieldName = ?(ValueIsFilled(KeyAndValue.Value),
                      TrimAll(KeyAndValue.Value),
                      TrimAll(KeyAndValue.Key));
        
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

    Result = New Structure;
    For Each KeyAndValue In AttributesStructure Do
        Result.Insert(KeyAndValue.Key);
    EndDo;
    FillPropertyValues(Result, Selection);

    Return Result;

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



// Creates a structure with properties named as value table row columns and 
// sets the values of these properties from the values table row.
//
// Parameters:
//  ValueTableRow - ValueTableRow - value table row.
//
// Returns:
//  Structure.
//
Function ValueTableRowIntoStructure(ValueTableRow) Export

    Structure = New Structure;
    For Each Column In ValueTableRow.Owner().Columns Do
        Structure.Insert(Column.Name, ValueTableRow[Column.Name]);
    EndDo;
    
    Return Structure;

EndFunction // ValueTableRowIntoStructure()


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
        
        IndexOf = Data.Count() - 1;
        
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

    UseFilter = (Filter <> Undefined);

    CollectionsOfMetadataObjects = New ValueTable;
    CollectionsOfMetadataObjects.Columns.Add("Name");
    CollectionsOfMetadataObjects.Columns.Add("Synonym");
    CollectionsOfMetadataObjects.Columns.Add("Picture");
    CollectionsOfMetadataObjects.Columns.Add("ObjectPicture");
    CollectionsOfMetadataObjects.Columns.Add("PictureIndex", New TypeDescription("Number"));

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
        1,
        CollectionsOfMetadataObjects);
        
    NewMetadataObjectCollectionRow(TypeNameDocuments(),               
        NStr("en='Documents';ru='Документы'"),                 
        PictureLib.Document,               
        PictureLib.DocumentObject,
        2,
        CollectionsOfMetadataObjects);
        
    NewMetadataObjectCollectionRow(TypeNameChartsOfCharacteristicTypes(), 
        NStr("en='Charts of characteristics types';ru='Планы видов характеристик'"), 
        PictureLib.ChartOfCharacteristicTypes, 
        PictureLib.ChartOfCharacteristicTypesObject,
        4,
        CollectionsOfMetadataObjects);
        
    NewMetadataObjectCollectionRow(TypeNameChartsOfAccounts(),             
        NStr("en='Charts of accounts';ru='Планы счетов'"),              
        PictureLib.ChartOfAccounts,             
        PictureLib.ChartOfAccountsObject,
        32,
        CollectionsOfMetadataObjects);
        
    NewMetadataObjectCollectionRow(TypeNameChartsOfCalculationTypes(),       
        NStr("en='Charts of calculation types';ru='Планы видов расчета'"), 
        PictureLib.ChartOfCharacteristicTypes, 
        PictureLib.ChartOfCharacteristicTypesObject,
        9,
        CollectionsOfMetadataObjects);
        
    NewMetadataObjectCollectionRow(TypeNameInformationRegisters(),        
        NStr("en='Information registers';ru='Регистры сведений'"),         
        PictureLib.InformationRegister,        
        PictureLib.InformationRegister,
        3,
        CollectionsOfMetadataObjects);
        
    NewMetadataObjectCollectionRow(TypeNameAccountingRegisters(),      
        NStr("en='Accumulation registers';ru='Регистры накопления'"),       
        PictureLib.AccumulationRegister,      
        PictureLib.AccumulationRegister,
        6,
        CollectionsOfMetadataObjects);
        
    NewMetadataObjectCollectionRow(TypeNameAccountingRegisters(),     
        NStr("en='Accounting registers';ru='Регистры бухгалтерии'"),      
        PictureLib.AccountingRegister,     
        PictureLib.AccountingRegister, 
        5,
        CollectionsOfMetadataObjects);
        
    NewMetadataObjectCollectionRow(TypeNameCalculationRegisters(),         
        NStr("en='Calculation registers';ru='Регистры расчета'"),          
        PictureLib.CalculationRegister,         
        PictureLib.CalculationRegister,
        8,
        CollectionsOfMetadataObjects);
        
    NewMetadataObjectCollectionRow(TypeNameBusinessProcess(),          
        NStr("en='Business processes';ru='Бизнес-процессы'"),           
        PictureLib.BusinessProcess,          
        PictureLib.BusinessProcessObject,
        7,
        CollectionsOfMetadataObjects);
        
    NewMetadataObjectCollectionRow(TypeNameTasks(),                  
        NStr("en='Tasks';ru='Задания'"),                    
        PictureLib.Task,                 
        PictureLib.TaskObject,
        16,
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
    TypesNames.Insert(TypeNameExchangePlans(),              "ExchangePlan");
    TypesNames.Insert(TypeNameConstants(),                  "Constant");
    TypesNames.Insert(TypeNameCatalogs(),                   "Catalog");
    TypesNames.Insert(TypeNameDocuments(),                  "Document");
    TypesNames.Insert(TypeNameDocumentJournals(),           "DocumentJournal");
    TypesNames.Insert(TypeNameEnums(),                      "Enum");
    TypesNames.Insert(TypeNameReports(),                    "Report");
    TypesNames.Insert(TypeNameDataProcessors(),             "DataProcessor");
    TypesNames.Insert(TypeNameChartsOfCharacteristicTypes(),"ChartOfCharacteristicTypes");
    TypesNames.Insert(TypeNameChartsOfAccounts(),           "ChartOfAccounts");
    TypesNames.Insert(TypeNameChartsOfCalculationTypes(),   "ChartOfCalculationTypes");
    TypesNames.Insert(TypeNameInformationRegisters(),       "InformationRegister");
    TypesNames.Insert(TypeNameAccumulationRegisters(),      "AccumulationRegister");
    TypesNames.Insert(TypeNameAccountingRegisters(),        "AccountingRegister");
    TypesNames.Insert(TypeNameCalculationRegisters(),       "CalculationRegister");
    TypesNames.Insert(TypeNameBusinessProcess(),            "BusinessProcess");
    TypesNames.Insert(TypeNameTasks(),                      "Task");
    
    TypeName = TypesNames[ManagerType];
    If TypeName = Undefined Then
        Return ManagerName;
    EndIf;

    Return TypeName + Mid(ManagerName, Position);
    
EndFunction // MetadataObjectNameByManagerName()


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

    Synonyms = New Map;
    Synonyms.Insert("ССЫЛКА", "REF");
    Synonyms.Insert("REF", "ССЫЛКА");
    
    Name = Upper(AttributeName);
    For Each Attribute In StandardAttributes Do
        If Upper(Attribute.Name) = Name Or Upper(Attribute.Name) = Synonyms[Name] Then
            Return True;
        EndIf;
    EndDo;
    Return False;

EndFunction // IsStandardAttribute()

#EndRegion // MetadataObjectTypes

#Region ValueConversion 

// Serializes the value into XML string representation.
//
// Parameters:
//  Value - Arbitrary - the value to be serialized.
//
// Returns:
//  String - XML string representation.
//
Function ValueToXMLString(Value) Export

    XMLWriter = New XMLWriter();
    XMLWriter.SetString();
    XDTOSerializer.WriteXML(XMLWriter, Value, XMLTypeAssignment.Explicit);
    Return XMLWriter.Close();

EndFunction // ValueToXMLString()

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
        
        if ConversionResult.TypeConverted Then
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
//      * Mediator       - Arbitrary - reserved, currently not in use.
//      * ConvertedValue - Arbitrary - converted value.
//      * TypeConverted  - Boolean   - initial value 'False', when 'True' is set 
//                                    it means value conversion was successful.
//                          Default value: False.
//
Function NewConversionResult()

    ConversionResult = New Structure;
    ConversionResult.Insert("Mediator");
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
        
        // Mediator
        // FL_ErrorsClientServer.ErrorTypeIsDifferentThanExpected(
        //      "SettingsComposer", Value, ExpectedType);
        
        Return False;
            
    EndIf;
        
    Return True;

EndFunction // ValueTypeMatchExpected()

#EndRegion // ValueConversion

#EndRegion // ServiceProceduresAndFunctions