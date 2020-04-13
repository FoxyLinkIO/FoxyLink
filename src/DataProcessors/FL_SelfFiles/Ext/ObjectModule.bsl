////////////////////////////////////////////////////////////////////////////////
// This file is part of FoxyLink.
// Copyright © 2016-2020 Petro Bazeliuk.
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

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region ChannelDescription

// The name of the standard API used in this channel.
//
// Returns:
//  String - name of the standard API.
//
Function ChannelStandard() Export
    
    Return "FoxyLink";
    
EndFunction // ChannelStandard()

// Returns the link to the description of the standard API that is used 
// in this channel.
//
// Returns:
//  String - the link to the description of the standard API.
//
Function ChannelStandardLink() Export
    
    Return "https://github.com/FoxyLinkIO/FoxyLink";
    
EndFunction // ChannelStandardLink()

// Returns short channel name.
//
// Returns:
//  String - channel short name.
// 
Function ChannelShortName() Export
    
    Return "FoxyLink";    
    
EndFunction // ChannelShortName()

// Returns full channel name.
//
// Returns:
//  String - channel full name.
//
Function ChannelFullName() Export
    
    Return "FoxyLink file-messaging";    
    
EndFunction // ChannelFullName()

#EndRegion // ChannelDescription 

#Region ProgramInterface

// Delivers a data object to the file export application endpoint.
//
// Parameters:
//  Invocation - Structure - see function Catalogs.FL_Messages.NewInvocation.
//  JobResult  - Structure - see function Catalogs.FL_Jobs.NewJobResult.
//
Procedure DeliverMessage(Invocation, JobResult) Export
    
    Try 
                    
        FullName = WriteOutputToDestination(Invocation);
        
        FileProperties = FL_InteriorUseClientServer.NewFileProperties(FullName);   
        ProcessAdditionalOutputProperties(FileProperties);     
 
        // Out payload
        MemoryStream = New MemoryStream;
        JSONWriter = New JSONWriter;
        JSONWriter.OpenStream(MemoryStream);
        WriteJSON(JSONWriter, FileProperties);
        JSONWriter.Close();
        
        // Out invocation
        OutInvocation = Catalogs.FL_Messages.NewInvocation();
        FillPropertyValues(OutInvocation, Invocation);
        OutInvocation.ContentEncoding = "UTF-8";
        OutInvocation.ContentType = "application/json";
        OutInvocation.FileExtension = ".json";
        OutInvocation.Payload = MemoryStream.CloseAndGetBinaryData();
        OutInvocation.Timestamp = CurrentUniversalDateInMilliseconds();
        
        Catalogs.FL_Jobs.AddToJobResult(JobResult, "Invocation", OutInvocation);
        
        JobResult.StatusCode = FL_InteriorUseReUse.OkStatusCode(); 
        If TypeOf(JobResult.LogAttribute) = Type("String") Then
            JobResult.LogAttribute = "200 Success";
        EndIf;
        
    Except
        
        JobResult.StatusCode = FL_InteriorUseReUse
            .InternalServerErrorStatusCode();
        JobResult.LogAttribute = ErrorDescription();
        
    EndTry;
          
    JobResult.Success = FL_InteriorUseReUse.IsSuccessHTTPStatusCode(
        JobResult.StatusCode);
        
EndProcedure // DeliverMessage() 

// Invalidates the channel data. 
//
// Returns:
//  Boolean - if True channel was disconnected successfully.
//
Function Disconnect() Export
    
    Return True;
    
EndFunction // Disconnect() 

// Returns the boolean value whether preauthorization is required.
//
// Returns:
//  Boolean - if True preauthorization is required.
//
Function PreauthorizationRequired() Export
    
    Return False;
    
EndFunction // PreauthorizationRequired()

// Returns the boolean value whether resources are required.
//
// Returns:
//  Boolean - if True resources are required.
//
Function ResourcesRequired() Export
    
    Return True;
    
EndFunction // ResourcesRequired()

// Returns array of supplied integrations for this configuration.
//
// Returns:
//  Array - array filled by supplied integrations.
//      * ArrayItem - Structure - see function FL_InteriorUse.NewPluggableSettings.
//
Function SuppliedIntegrations() Export
    
    SuppliedIntegrations = New Array;
    
    BasicPhrases = New Array;
    BasicPhrases.Add(NStr("en='Exchange description service helps to transfer ';
        |ru='Сервис описания обменов помогает переносить обмены из одной ';
        |uk='Сервіс опису обмінів допомагає переносити обміни з однієї ';
        |en_CA='Exchange description service helps to transfer '"));
    BasicPhrases.Add(NStr("en='exchanges from one accounting system to another.';
        |ru='учетной системы в другие.';
        |uk='облікової системи в інші.';
        |en_CA='exchanges from one accounting system to another.'"));
    
    PluggableSettings = FL_InteriorUse.NewPluggableSettings();   
    PluggableSettings.Name = NStr("en='Exchange description service';
        |ru='Сервис описания обменов';
        |uk='Сервіс опису обмінів';
        |en_CA='Exchange description service'");
    PluggableSettings.Template = "Self";
    PluggableSettings.ToolTip = StrConcat(BasicPhrases);
    PluggableSettings.Version = "1.0.10";
    SuppliedIntegrations.Add(PluggableSettings);
    
    Return SuppliedIntegrations;
        
EndFunction // SuppliedIntegration()

#EndRegion // ProgramInterface

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
Procedure ProcessAdditionalOutputProperties(FileProperties)
    
    AdditionalProperties = FL_EncryptionClientServer.FieldValueNoException(
        ChannelResources, "AdditionalOutputProperties");
    If ValueIsFilled(AdditionalProperties) Then
        
        AdditionalProperties = FL_CommonUse.ValueFromJSONString(
            AdditionalProperties);
        If TypeOf(AdditionalProperties) = Type("Structure") Then
            FL_CommonUseClientServer.ExtendStructure(FileProperties, 
                AdditionalProperties, True); 
        EndIf;
        
    EndIf;
    
EndProcedure // ProcessAdditionalOutputProperties()

// Only for internal use.
//
Function WriteOutputToDestination(Invocation)
    
    Path = FL_CommonUseClientServer.AddPathSeparatorToPath(
        FL_EncryptionClientServer.FieldValue(ChannelResources, "Path"));
    
    BaseName = FL_EncryptionClientServer.FieldValueNoException(
        ChannelResources, "BaseName", StrReplace(New UUID, "-", ""));     
    BaseName = StrTemplate("%1%2", BaseName, NewTimestamp());    
    
    Extension = FL_EncryptionClientServer.FieldValueNoException(
        ChannelResources, "Extension", Invocation.FileExtension);    
    If NOT ValueIsFilled(Extension) Then
        Extension = Invocation.FileExtension;
    EndIf;
    
    BinaryData = Invocation.Payload;
    If TypeOf(BinaryData) = Type("SpreadsheetDocument") Then
        BinaryData = ProcessSpreadsheetDocument(Invocation.Payload, Extension);    
    EndIf;
    
    CompressOutput = Boolean(FL_EncryptionClientServer.FieldValueNoException(
        ChannelResources, "CompressOutput", False));
    If CompressOutput Then
        BinaryData = CompressToZipDocument(BinaryData, BaseName, Extension);
        Extension = ".zip";
    EndIf;
    
    FullName = StrTemplate("%1%2%3", Path, BaseName, Extension);
    BinaryData.Write(FullName);
    
    Return FullName;
    
EndFunction // WriteOutputToDestination()

// Only for internal use.
//
Function ProcessSpreadsheetDocument(SpreadsheetDocument, Extension)
    
    MemoryStream = New MemoryStream;
    
    FileTypes = New Map;
    FileTypes.Insert(".DOCX", SpreadsheetDocumentFileType.DOCX);
    FileTypes.Insert(".HTML", SpreadsheetDocumentFileType.HTML);
    FileTypes.Insert(".MXL", SpreadsheetDocumentFileType.MXL);
    FileTypes.Insert(".ODS", SpreadsheetDocumentFileType.ODS);
    FileTypes.Insert(".PDF", SpreadsheetDocumentFileType.PDF);
    FileTypes.Insert(".TXT", SpreadsheetDocumentFileType.TXT);
    FileTypes.Insert(".XLS", SpreadsheetDocumentFileType.XLS);
    FileTypes.Insert(".XLSX", SpreadsheetDocumentFileType.XLSX);
    
    FileType = FileTypes.Get(Upper(Extension));
    If FileType = Undefined Then
        Raise NStr("en='Unsupported file type for spreadsheet document.';
            |ru='Неподдерживаемый тип файла для табличного документа.';
            |uk='Непідтримуваний тип файлу для табличного документу.';
            |en_CA='Unsupported file type for spreadsheet document.'");  
    EndIf;
    
    MemoryStream = New MemoryStream;
    SpreadsheetDocument.Write(MemoryStream, FileType);
    Return MemoryStream.CloseAndGetBinaryData();
        
EndFunction // ProcessSpreadsheetDocument()

// Only for internal use.
//
Function CompressToZipDocument(BinaryData, BaseName, Extension)
    
    Path = TempFilesDir();
    FullName = StrTemplate("%1%2%3", Path, BaseName, Extension);
    BinaryData.Write(FullName);
    
    ZipPassword = FL_EncryptionClientServer.FieldValueNoException(
        ChannelResources, "ZipPassword");
    ZipCommentaries = FL_EncryptionClientServer.FieldValueNoException(
        ChannelResources, "ZipCommentaries");
        
    MemoryStream = New MemoryStream;
    ZipFileWriter = New ZipFileWriter(MemoryStream,
        ZipPassword, 
        ZipCommentaries, 
        NewCompressionMethod(), 
        NewCompressionLevel(), 
        NewEncryptionMethod()); 
    ZipFileWriter.Add(FullName);
    ZipFileWriter.Write();
    
    DeleteFiles(FullName);
    
    Return MemoryStream.CloseAndGetBinaryData();
    
EndFunction // CompressToZipDocument()

// Only for internal use.
//
Function NewCompressionMethod()
    
    CompressionMethod = FL_EncryptionClientServer.FieldValueNoException(
        ChannelResources, "ZipCompressionMethod");
    If CompressionMethod = "BZIP2" Then
        Return ZIPCompressionMethod.BZIP2;    
    ElsIf CompressionMethod = "Copy" Then
        Return ZIPCompressionMethod.Copy;    
    Else
        Return ZIPCompressionMethod.Deflate;    
    EndIf;   
    
EndFunction // NewCompressionMethod()

// Only for internal use.
//
Function NewCompressionLevel()
    
    CompressionLevel = FL_EncryptionClientServer.FieldValueNoException(
        ChannelResources, "ZipCompressionLevel");
    If CompressionLevel = "Maximum" Then
        Return ZIPCompressionLevel.Maximum;    
    ElsIf CompressionLevel = "Minimum" Then
        Return ZIPCompressionLevel.Minimum;    
    Else
        Return ZIPCompressionLevel.Optimal;    
    EndIf;
    
EndFunction // NewCompressionLevel()

// Only for internal use.
//
Function NewEncryptionMethod()
    
    EncryptionMethod = FL_EncryptionClientServer.FieldValueNoException(
        ChannelResources, "ZipEncryptionMethod");
    If EncryptionMethod = "AES128" Then
        Return ZipEncryptionMethod.AES128;    
    ElsIf EncryptionMethod = "AES192" Then
        Return ZipEncryptionMethod.AES192;    
    ElsIf EncryptionMethod = "AES256" Then
        Return ZipEncryptionMethod.AES256;
    Else
        Return ZipEncryptionMethod.Zip20;    
    EndIf;
    
EndFunction // NewEncryptionMethod()

// Only for internal use.
//
Function NewTimestamp()
    
    AddTimestamp = Boolean(FL_EncryptionClientServer.FieldValueNoException(
        ChannelResources, "AddTimestamp", False));
    If AddTimestamp Then
            
        FormatString = FL_EncryptionClientServer.FieldValueNoException(
            ChannelResources, "FormatString");
            
        DateInMilliseconds = CurrentUniversalDateInMilliseconds();
        UniversalDate = Date(1, 1, 1) + DateInMilliseconds / 1000;
        Milliseconds = DateInMilliseconds % 1000;
            
        If ValueIsFilled(FormatString) Then
            Return "_" + Format(ToLocalTime(UniversalDate), FormatString);     
        Else
            Return "_" + Format(ToLocalTime(UniversalDate), 
                "df=yyyy-MM-ddTHH-mm-ss") + Format(Milliseconds, "NF=.N");
        EndIf;
            
    EndIf;
    
    Return "";

EndFunction // NewTimestamp()

#EndRegion // ServiceProceduresAndFunctions

#Region ExternalDataProcessorInfo

// Returns object version.
//
// Returns:
//  String - object version.
//
Function Version() Export
    
    Return "1.1.3";
    
EndFunction // Version()

// Returns base object description.
//
// Returns:
//  String - base object description.
//
Function BaseDescription() Export
    
    BaseDescription = NStr(
        "en='Export data to file (%1) application endpoint processor, ver. %2'; 
        |ru='Обработчик конечной точки приложения экспорта данных в файл (%1), вер. %2';
        |uk='Обробник кінцевої точки додатку експорту данних в файл (%1), вер. %2';
        |en_CA='Export data to file (%1) application endpoint processor, ver. %2'");
    Return StrTemplate(BaseDescription, ChannelStandard(), Version());        
    
EndFunction // BaseDescription()

// Returns library guid which is used to identify different implementations 
// of specific channel.
//
// Returns:
//  String - library guid. 
//  
Function LibraryGuid() Export
    
    Return "595e752d-57f4-4398-a1cb-e6c5a6aaa65c";
    
EndFunction // LibraryGuid()

#EndRegion // ExternalDataProcessorInfo

#EndIf