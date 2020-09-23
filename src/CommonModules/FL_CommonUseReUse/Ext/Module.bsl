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
// along with this program. If not, see <http://www.gnu.org/licenses/agpl-3.0>.
//
////////////////////////////////////////////////////////////////////////////////

#Region ProgramInterface

// Returns an fixed array of splitters that exist in the configuration.
//
// Returns: 
//  FixedArray(String) - an array of common attribute names, that are used as splitters.
//
Function ConfigurationSplitters() Export

    SplittersArray = New Array;

    For Each CommonAttribute In Metadata.CommonAttributes Do
        If CommonAttribute.DataSeparation = Metadata.ObjectProperties.CommonAttributeDataSeparation.Separate Then
            SplittersArray.Add(CommonAttribute.Name);
        EndIf;
    EndDo;

    Return New FixedArray(SplittersArray);

EndFunction // ConfigurationSplitters()

// Defines if passed a metadata object name belongs to the reference type.
// 
// Parameters:
//  FullName - String - object name for which it is required to define whether
//                      it belongs to the specified type.
// 
// Returns:
//   Boolean - True, if reference type; otherwise - False.
//
Function IsReferenceTypeObjectCached(FullName) Export
    
    MetadataObjectParts = 2;
    
    Parts = StrSplit(FullName, ".");
    If Parts.Count() <> MetadataObjectParts Then
        Return False;    
    EndIf;
    
    BaseName = Parts[0];
    BaseTypes = FL_CommonUseReUse.BaseReferenceTypeNameSynonyms();
    Return IsValueInFixedMapCollection(BaseName, BaseTypes);
    
EndFunction // IsReferenceTypeObjectCached()

// Defines if passed a metadata object name belongs to the register type.
// 
// Parameters:
//  FullName - String - object name for which it is required to define whether
//                      it belongs to the specified type.
// 
// Returns:
//   Boolean - True, if register type; otherwise - False.
//
Function IsRegisterTypeObjectCached(FullName) Export
    
    BaseName = StrSplit(FullName, ".")[0];
    BaseTypes = FL_CommonUseReUse.BaseRegisterTypeNameSynonyms();
    Return IsValueInFixedMapCollection(BaseName, BaseTypes);
    
EndFunction // IsRegisterTypeObjectCached()

// Defines if passed a metadata object name belongs to the information register type.
// 
// Parameters:
//  FullName - String - object name for which it is required to define whether
//                      it belongs to the specified type.
// 
// Returns:
//   Boolean - True, if information register type; otherwise - False.
//
Function IsInformationRegisterTypeObjectCached(FullName) Export
    
    BaseName = StrSplit(FullName, ".")[0];
    Synonyms = New Map;
    Synonyms.Insert("INFORMATIONREGISTER", "РЕГИСТРСВЕДЕНИЙ");
    BaseTypes = New FixedMap(BuildSynonymCombinations(Synonyms));
    Return IsValueInFixedMapCollection(BaseName, BaseTypes);
    
EndFunction // IsInformationRegisterTypeObjectCached()

// Defines if passed a metadata object name belongs to the accumulation register type.
// 
// Parameters:
//  FullName - String - object name for which it is required to define whether
//                      it belongs to the specified type.
// 
// Returns:
//   Boolean - True, if accumulation register type; otherwise - False.
//
Function IsAccumulationRegisterTypeObjectCached(FullName) Export
    
    BaseName = StrSplit(FullName, ".")[0];
    Synonyms = New Map;
    Synonyms.Insert("ACCUMULATIONREGISTER", "РЕГИСТРНАКОПЛЕНИЯ");
    BaseTypes = New FixedMap(BuildSynonymCombinations(Synonyms));
    Return IsValueInFixedMapCollection(BaseName, BaseTypes);
    
EndFunction // IsAccumulationRegisterTypeObjectCached()

// Defines if passed a metadata object name belongs to the accounting register type.
// 
// Parameters:
//  FullName - String - object name for which it is required to define whether
//                      it belongs to the specified type.
// 
// Returns:
//   Boolean - True, if accounting register type; otherwise - False.
//
Function IsAccountingRegisterTypeObjectCached(FullName) Export
    
    BaseName = StrSplit(FullName, ".")[0];
    Synonyms = New Map;
    Synonyms.Insert("ACCOUNTINGREGISTER", "РЕГИСТРБУХГАЛТЕРИИ");
    BaseTypes = New FixedMap(BuildSynonymCombinations(Synonyms));
    Return IsValueInFixedMapCollection(BaseName, BaseTypes);
    
EndFunction // IsAccountingRegisterTypeObjectCached()

// Defines if passed a metadata object name belongs to the calculation register type.
// 
// Parameters:
//  FullName - String - object name for which it is required to define whether
//                      it belongs to the specified type.
// 
// Returns:
//   Boolean - True, if calculation register type; otherwise - False.
//
Function IsCalculationRegisterTypeObjectCached(FullName) Export
    
    BaseName = StrSplit(FullName, ".")[0];
    Synonyms = New Map;
    Synonyms.Insert("CALCULATIONREGISTER", "РЕГИСТРРАСЧЕТА");
    BaseTypes = New FixedMap(BuildSynonymCombinations(Synonyms));
    Return IsValueInFixedMapCollection(BaseName, BaseTypes);
    
EndFunction // IsCalculationRegisterTypeObjectCached()

// Defines if an application version is 8.3.13 or higher.
//
Function IsAppVersion_8_3_13_OrHigher() Export
    
    SystemInfo = New SystemInfo;
    AppVersion = SystemInfo.AppVersion;
    Return FL_InteriorUseClientServer.IsNewerVersion(AppVersion, "8.3.13.0");
    
EndFunction // IsAppVersion_8_3_13_OrHigher() 

// Returns a fixed map with base reference type name synonyms.
//
// Returns:
//  FixedMap - with base reference type name synonyms.
//
Function BaseReferenceTypeNameSynonyms() Export
    
    Synonyms = New Map;
    Synonyms.Insert("EXCHANGEPLAN", "ПЛАНОБМЕНА");
    Synonyms.Insert("CATALOG", "СПРАВОЧНИК");
    Synonyms.Insert("DOCUMENT", "ДОКУМЕНТ");
    Synonyms.Insert("ENUM", "ПЕРЕЧИСЛЕНИЕ");
    Synonyms.Insert("CHARTOFCHARACTERISTICTYPES", "ПЛАНВИДОВХАРАКТЕРИСТИК");
    Synonyms.Insert("CHARTOFACCOUNTS", "ПЛАНСЧЕТОВ");
    Synonyms.Insert("CHARTOFCALCULATIONTYPES", "ПЛАНВИДОВРАСЧЕТА");
    Synonyms.Insert("BUSINESSPROCESS", "БИЗНЕСПРОЦЕСС");
    Synonyms.Insert("TASK", "ЗАДАЧА");
        
    Return New FixedMap(BuildSynonymCombinations(Synonyms));
    
EndFunction // BaseReferenceTypeNameSynonyms()

// Returns a fixed map with base register type name synonyms.
//
// Returns:
//  FixedMap - with base register type name synonyms.
//
Function BaseRegisterTypeNameSynonyms() Export
    
    Synonyms = New Map;
    Synonyms.Insert("INFORMATIONREGISTER", "РЕГИСТРСВЕДЕНИЙ");
    Synonyms.Insert("ACCUMULATIONREGISTER", "РЕГИСТРНАКОПЛЕНИЯ");
    Synonyms.Insert("ACCOUNTINGREGISTER", "РЕГИСТРБУХГАЛТЕРИИ");
    Synonyms.Insert("CALCULATIONREGISTER", "РЕГИСТРРАСЧЕТА");
    
    Return New FixedMap(BuildSynonymCombinations(Synonyms));
    
EndFunction // BaseRegisterTypeNameSynonyms()

// Returns a fixed map with standard attribute synonym names.
//
// Returns:
//  FixedMap - with standard attribute synonym names.
//
Function StandardAttributeSynonyms() Export
      
    Return New FixedMap(BuildSynonymCombinations(FL_CommonUseReUse
        .StandardAttributeSynonymsEN()));
    
EndFunction // StandardAttributeSynonyms()  

// Returns a fixed map with standard attribute synonym names in english.
//
// Returns:
//  FixedMap - with standard attribute synonym names in english.
//
Function StandardAttributeSynonymsEN() Export
    
    Synonyms = New Map;
    
    // Catalog
    Synonyms.Insert("REF", "ССЫЛКА");
    Synonyms.Insert("CODE", "КОД");
    Synonyms.Insert("DESCRIPTION", "НАИМЕНОВАНИЕ");
    Synonyms.Insert("OWNER", "ВЛАДЕЛЕЦ");
    Synonyms.Insert("PARENT", "РОДИТЕЛЬ");
    Synonyms.Insert("ISFOLDER", "ЭТОГРУППА");
    Synonyms.Insert("DELETIONMARK", "ПОМЕТКАУДАЛЕНИЯ");
    Synonyms.Insert("PREDEFINED", "ПРЕДОПРЕДЕЛЕННЫЙ");
    Synonyms.Insert("PREDEFINEDDATANAME", "ИМЯПРЕДОПРЕДЕЛЕННЫХДАННЫХ");
    
    // Document
    Synonyms.Insert("NUMBER", "НОМЕР");
    Synonyms.Insert("DATE", "ДАТА");
    Synonyms.Insert("POSTED", "ПРОВЕДЕН");
    
    // Document journals
    Synonyms.Insert("TYPE", "ТИП"); 
    
    // Enumerations
    Synonyms.Insert("ORDER", "ПОРЯДОК");
    
    // Charts of characteristic types
    Synonyms.Insert("VALUETYPE", "ТИПЗНАЧЕНИЯ");
    
    // Charts of accounts
    Synonyms.Insert("OFFBALANCE", "ЗАБАЛАНСОВЫЙ");

    // Charts of calculation types
    Synonyms.Insert("ACTIONPERIODISBASIC", "ПЕРИОДДЕЙСТВИЯБАЗОВЫЙ");
    
    // Information registers
    Synonyms.Insert("PERIOD", "ПЕРИОД");
    Synonyms.Insert("RECORDER", "РЕГИСТРАТОР");
    Synonyms.Insert("LINENUMBER", "НОМЕРСТРОКИ");
    Synonyms.Insert("ACTIVE", "АКТИВНОСТЬ");
    
    // Accumulation registers
    Synonyms.Insert("RECORDTYPE", "ВИДДВИЖЕНИЯ");
    
    // Accounting registers
    Synonyms.Insert("ACCOUNT", "СЧЕТ");

    // Calculation registers
    Synonyms.Insert("REGISTRATIONPERIOD", "ПЕРИОДРЕГИСТРАЦИИ");
    Synonyms.Insert("CALCULATIONTYPE", "ВИДРАСЧЕТА");
    Synonyms.Insert("ACTIONPERIOD", "ПЕРИОДДЕЙСТВИЯ");
    Synonyms.Insert("BEGOFACTIONPERIOD", "ПЕРИОДДЕЙСТВИЯНАЧАЛО");
    Synonyms.Insert("ENDOFACTIONPERIOD", "ПЕРИОДДЕЙСТВИЯКОНЕЦ");
    Synonyms.Insert("BEGOFBASEPERIOD", "БАЗОВЫЙПЕРИОДНАЧАЛО");
    Synonyms.Insert("ENDOFBASEPERIOD", "БАЗОВЫЙПЕРИОДКОНЕЦ");
    Synonyms.Insert("REVERSINGENTRY", "СТОРНО");
    
    // Business processes
    Synonyms.Insert("HEADTASK", "ВЕДУЩАЯЗАДАЧА");
    Synonyms.Insert("STARTED", "СТАРТОВАН");
    Synonyms.Insert("COMPLETED", "ЗАВЕРШЕН");
    
    // Tasks
    Synonyms.Insert("BUSINESSPROCESS", "БИЗНЕСПРОЦЕСС");
    Synonyms.Insert("ROUTEPOINT", "ТОЧКАМАРШРУТА");
    Synonyms.Insert("EXECUTED", "ВЫПОЛНЕНА");
    
    Return New FixedMap(Synonyms);
    
EndFunction // StandardAttributeSynonymsEN()

// Returns a fixed map with standard attribute synonym names in russian.
//
// Returns:
//  FixedMap - with standard attribute synonym names in russian.
//
Function StandardAttributeSynonymsRU() Export
    
    // Caching
    SynonymsEN = FL_CommonUseReUse.StandardAttributeSynonymsEN();
    
    SynonymRU = New Map;
    For Each Synonym In SynonymsEN Do
        SynonymRU.Insert(Synonym.Value, Synonym.Key);
    EndDo;
    
    Return New FixedMap(SynonymRU);
    
EndFunction // StandardAttributeSynonymsRU() 

// Returns current session hash as base64-encoded string.
//
// Returns:
//  String - current session hash as base64-encoded string.
//
Function SessionHash() Export
    
    InfoBaseSession = GetCurrentInfoBaseSession();
    
    MemoryStream = New MemoryStream;
    DataWriter = New DataWriter(MemoryStream);
    DataWriter.WriteChars(InfoBaseSession.ApplicationName);
    DataWriter.WriteChars(InfoBaseSession.ComputerName);
    DataWriter.WriteInt32(InfoBaseSession.ConnectionNumber);
    DataWriter.WriteInt32(InfoBaseSession.SessionNumber);
    DataWriter.WriteChars(String(InfoBaseSession.SessionStarted));
    DataWriter.Close();
    
    MemoryStream.Seek(0, PositionInStream.Begin);
    Hash = FL_Encryption.Hash(MemoryStream, 
        HashFunction.MD5);
    MemoryStream.Close();
    
    Return Base64String(Hash);
    
EndFunction // SessionHash()

#Region PictureLibrary

// Returns the sequence number for the fullname of metadata 
// in the FL_MetadataObjects collection.
//
// Parameters:
//  FullName - String - full metadata object name. 
//                  Example: "AccumulationRegister.Inventory".
//
// Returns:
//  Number - the sequence number of the picture.
//
Function PicSequenceIndexByFullName(FullName) Export
    
    Map = New Map;
    Map.Insert("CONSTANT", ConstantPicSequenceIndex());
    Map.Insert("КОНСТАНТА", ConstantPicSequenceIndex());
    Map.Insert("SCHEDULEDJOB", ScheduledJobPicSequenceIndex());
    Map.Insert("РЕГЛАМЕНТНОЕЗАДАНИЕ", ScheduledJobPicSequenceIndex());   
    Map.Insert("HTTPSERVICE", HTTPServicePicSequenceIndex());
    Map.Insert("HTTPСЕРВИС", HTTPServicePicSequenceIndex());
    Map.Insert("CATALOG", CatalogPicSequenceIndex());
    Map.Insert("СПРАВОЧНИК", CatalogPicSequenceIndex());
    Map.Insert("DOCUMENT", DocumentPicSequenceIndex());
    Map.Insert("ДОКУМЕНТ", DocumentPicSequenceIndex());
    Map.Insert("CHARTOFCHARACTERISTICTYPES", ChartOfCharacteristicTypePicSequenceIndex());
    Map.Insert("ПЛАНВИДОВХАРАКТЕРИСТИК", ChartOfCharacteristicTypePicSequenceIndex());
    Map.Insert("CHARTOFACCOUNTS", ChartOfAccountPicSequenceIndex());
    Map.Insert("ПЛАНСЧЕТОВ", ChartOfAccountPicSequenceIndex());
    Map.Insert("CHARTOFCALCULATIONTYPES", ChartOfCalculationTypePicSequenceIndex());
    Map.Insert("ПЛАНВИДОВРАСЧЕТА", ChartOfCalculationTypePicSequenceIndex());
    Map.Insert("BUSINESSPROCESS", BusinessProcessPicSequenceIndex());
    Map.Insert("БИЗНЕСПРОЦЕСС", BusinessProcessPicSequenceIndex());
    Map.Insert("TASK", TaskPicSequenceIndex());
    Map.Insert("ЗАДАЧА", TaskPicSequenceIndex()); 
    Map.Insert("INFORMATIONREGISTER", InformationRegisterPicSequenceIndex());
    Map.Insert("РЕГИСТРСВЕДЕНИЙ", InformationRegisterPicSequenceIndex());
    Map.Insert("ACCUMULATIONREGISTER", AccumulationRegisterPicSequenceIndex());
    Map.Insert("РЕГИСТРНАКОПЛЕНИЯ", AccumulationRegisterPicSequenceIndex());
    Map.Insert("ACCOUNTINGREGISTER", AccountingRegisterPicSequenceIndex());
    Map.Insert("РЕГИСТРБУХГАЛТЕРИИ", AccountingRegisterPicSequenceIndex());
    Map.Insert("CALCULATIONREGISTER", CalculationRegisterPicSequenceIndex());
    Map.Insert("РЕГИСТРРАСЧЕТА", CalculationRegisterPicSequenceIndex());
    
    Parts = StrSplit(FullName, ".");
    Return Map.Get(Upper(Parts[0]));
    
EndFunction // PicSequenceIndexByFullName()

// Returns the sequence number of the scheduled job picture in the FL_MetadataObjects collection.
//
// Returns:
//  Number - the sequence number of the picture.
//
Function ScheduledJobPicSequenceIndex() Export
    
    Return 38;
    
EndFunction // ScheduledJobPicSequenceIndex()

// Returns the sequence number of the HTTP service picture in the FL_MetadataObjects collection.
//
// Returns:
//  Number - the sequence number of the picture.
//
Function HTTPServicePicSequenceIndex() Export
    
    Return 39;
    
EndFunction // HTTPServicePicSequenceIndex()

// Returns the sequence number of the constant picture in the FL_MetadataObjects collection.
//
// Returns:
//  Number - the sequence number of the picture.
//
Function ConstantPicSequenceIndex() Export
    
    Return 10;
    
EndFunction // ConstantPicSequenceIndex()

// Returns the sequence number of the catalog picture in the FL_MetadataObjects collection.
//
// Returns:
//  Number - the sequence number of the picture.
//
Function CatalogPicSequenceIndex() Export
    
    Return 1;
    
EndFunction // CatalogPicSequenceIndex()

// Returns the sequence number of the document picture in the FL_MetadataObjects collection.
//
// Returns:
//  Number - the sequence number of the picture.
//
Function DocumentPicSequenceIndex() Export
    
    Return 2;
    
EndFunction // DocumentPicSequenceIndex()

// Returns the sequence number of the chart of characteristic type picture in the FL_MetadataObjects collection.
//
// Returns:
//  Number - the sequence number of the picture.
//
Function ChartOfCharacteristicTypePicSequenceIndex() Export
    
    Return 4;
    
EndFunction // ChartOfCharacteristicTypePicSequenceIndex()

// Returns the sequence number of the chart of account picture in the FL_MetadataObjects collection.
//
// Returns:
//  Number - the sequence number of the picture.
//
Function ChartOfAccountPicSequenceIndex() Export
    
    Return 32;
    
EndFunction // ChartOfAccountPicSequenceIndex()

// Returns the sequence number of the chart of calculation type picture in the FL_MetadataObjects collection.
//
// Returns:
//  Number - the sequence number of the picture.
//
Function ChartOfCalculationTypePicSequenceIndex() Export
    
    Return 9;
    
EndFunction // ChartOfCalculationTypePicSequenceIndex()

// Returns the sequence number of the information register picture in the FL_MetadataObjects collection.
//
// Returns:
//  Number - the sequence number of the picture.
//
Function InformationRegisterPicSequenceIndex() Export
    
    Return 3;
    
EndFunction // InformationRegisterPicSequenceIndex()

// Returns the sequence number of the accumulation register picture in the FL_MetadataObjects collection.
//
// Returns:
//  Number - the sequence number of the picture.
//
Function AccumulationRegisterPicSequenceIndex() Export
    
    Return 6;
    
EndFunction // AccumulationRegisterPicSequenceIndex()

// Returns the sequence number of the accounting register picture in the FL_MetadataObjects collection.
//
// Returns:
//  Number - the sequence number of the picture.
//
Function AccountingRegisterPicSequenceIndex() Export
    
    Return 5;
    
EndFunction // AccountingRegisterPicSequenceIndex()

// Returns the sequence number of the calculation register picture in the FL_MetadataObjects collection.
//
// Returns:
//  Number - the sequence number of the picture.
//
Function CalculationRegisterPicSequenceIndex() Export
    
    Return 8;
    
EndFunction // CalculationRegisterPicSequenceIndex()

// Returns the sequence number of the business process picture in the FL_MetadataObjects collection.
//
// Returns:
//  Number - the sequence number of the picture.
//
Function BusinessProcessPicSequenceIndex() Export
    
    Return 7;
    
EndFunction // BusinessProcessPicSequenceIndex()

// Returns the sequence number of the task picture in the FL_MetadataObjects collection.
//
// Returns:
//  Number - the sequence number of the picture.
//
Function TaskPicSequenceIndex() Export
    
    Return 16;
    
EndFunction // TaskPicSequenceIndex()

#EndRegion // PictureLibrary

#EndRegion // ProgramInterface

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
Function IsValueInFixedMapCollection(Value, Collection) 
    
    Return Collection.Get(Upper(Value)) <> Undefined;  
    
EndFunction // IsValueInFixedMapCollection()

// Only for internal use.
//
Function BuildSynonymCombinations(Synonyms)
    
    SynonymCombinations = New Map;
    For Each Synonym In Synonyms Do
        SynonymCombinations.Insert(Synonym.Key, Synonym.Value);
        SynonymCombinations.Insert(Synonym.Value, Synonym.Key);
    EndDo;
    
    Return SynonymCombinations;
    
EndFunction // BuildSynonymCombinations()

#EndRegion // ServiceProceduresAndFunctions