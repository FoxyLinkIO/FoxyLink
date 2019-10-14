////////////////////////////////////////////////////////////////////////////////
// This file is part of FoxyLink.
// Copyright © 2016-2019 Petro Bazeliuk.
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

#Region ProgramInterface

// Returns a processing result.
//
// Parameters:
//  AppProperties - Structure - see function Catalogs.FL_Channels.NewAppEndpointProperties.
//  Payload       - Arbitrary - payload.
//  Properties    - Structure - see function Catalogs.FL_Exchanges.NewProperties.
//
// Returns:
//  Structure - see fucntion Catalogs.FL_Jobs.NewJobResult. 
//
Function ProcessMessage(AppProperties, Payload, Properties) Export
    
    JobResult = Catalogs.FL_Jobs.NewJobResult();
    JobResult.AppEndpoint = AppProperties.AppEndpoint;
                
    Query = New Query;
    Query.Text = QueryTextAppEndpointSettings();
    Query.SetParameter("AppEndpoint", AppProperties.AppEndpoint);
    QueryResult = Query.Execute();
    If QueryResult.IsEmpty() Then
        
        JobResult.LogAttribute = NStr("
            |en='Failed to load application endpoint settings.';
            |ru='Не удалось загрузить настройки конечной точки приложения.';
            |uk='Не вдалось завантажити налаштування кінцевої точки додатку.';
            |en_CA='Failed to load application endpoint settings.'");
        JobResult.StatusCode = FL_InteriorUseReUse
            .InternalServerErrorStatusCode();
        JobResult.Success = FL_InteriorUseReUse.IsSuccessHTTPStatusCode(
            JobResult.StatusCode);
        Return JobResult;
        
    EndIf;
    
    AppEndpointSettings = QueryResult.Select();
    AppEndpointSettings.Next();
    If NOT AppEndpointSettings.Connected Then
       
        JobResult.LogAttribute = NStr("
            |en='The endpoint is not connected to the application.';
            |ru='Конечная точка не подключена к приложению.';
            |uk='Кінцева точка не підключена до додатку.';
            |en_CA='The endpoint is not connected to the application.'");
        JobResult.StatusCode = FL_InteriorUseReUse
            .InternalServerErrorStatusCode();
        JobResult.Success = FL_InteriorUseReUse.IsSuccessHTTPStatusCode(
            JobResult.StatusCode);
        Return JobResult;
        
    EndIf;
    
    Try
    
        AppEndpointProcessor = FL_InteriorUse.NewAppEndpointProcessor(
            AppEndpointSettings.BasicChannelGuid);
                
        // Shows wether log is to be turned on.
        If AppEndpointSettings.Log Then
            JobResult.LogAttribute = "";        
        EndIf;
        
        AppEndpointProcessor.ChannelData.Load(
            AppEndpointSettings.ChannelData.Unload());
        AppEndpointProcessor.ChannelResources.Load(AppProperties.AppResources);
        AppEndpointProcessor.EncryptedData.Load(
            AppEndpointSettings.EncryptedData.Unload());
                    
        AppEndpointProcessor.DeliverMessage(Payload, Properties, JobResult);      
            
    Except
        
        ErrorDescription = ErrorDescription();
        FL_InteriorUse.WriteLog("FoxyLink.Integration.ProcessMessage", 
            EventLogLevel.Error,
            Metadata.Catalogs.FL_Channels,
            ErrorDescription, 
            JobResult);
    
    EndTry;

    JobResult.Success = FL_InteriorUseReUse.IsSuccessHTTPStatusCode(
        JobResult.StatusCode);
    Return JobResult;
   
EndFunction // ProcessMessage()

// Returns available plugable channels.
//
// Returns:
//  ValueList - with values:
//      * Value - String - channel library guid.
//
Function AvailableChannels() Export
    
    ValueList = New ValueList;

    PlugableChannels = FL_InteriorUse.PluggableSubsystem("Channels"); 
    For Each Item In PlugableChannels.Content Do
        
        If Metadata.DataProcessors.Contains(Item) Then
            
            Try
            
                DataProcessor = DataProcessors[Item.Name].Create();
                AddAvailableChannel(DataProcessor, ValueList);
            
            Except
                
                FL_CommonUseClientServer.NotifyUser(ErrorDescription());
                
            EndTry;
            
        EndIf;
        
    EndDo;
    
    Return ValueList;
    
EndFunction // AvailableChannels()

// Returns array of supplied integrations for this configuration.
//
// Returns:
//  Array - array filled by supplied integrations.
//      * ArrayItem - Structure - see function FL_InteriorUse.NewPluggableSettings.
//
Function SuppliedIntegrations() Export
    
    SuppliedIntegrations = New Array;
    
    AvailableChannels = AvailableChannels();
    For Each Channel In AvailableChannels Do
        
        Try
            
            ChannelProcessor = FL_InteriorUse.NewAppEndpointProcessor(
                Channel.Value);
            Integrations = ChannelProcessor.SuppliedIntegrations();
            For Each Integration In Integrations Do
                Integration.Insert("LibraryGuid", Channel.Value); 
                Integration.Insert("ChannelName", Channel.Presentation);
            EndDo;
            
            FL_CommonUseClientServer.ExtendArray(SuppliedIntegrations, 
                Integrations);
            
        Except
            // There is no any exception, integrations not provided.
            Continue;
        EndTry;
               
    EndDo;
    
    Return SuppliedIntegrations;
    
EndFunction // SuppliedIntegrations()

// Returns exchange plugable channels.
//
// Parameters:
//  LibraryGuid - String - guid which is used to identify different implementations 
//                         of specific app endpoint.
//                  Default value: Undefined.
//
// Returns:
//  ValueList - with values:
//      * Value - CatalogRef.FL_Channels - reference to the channel.
//
Function ExchangeChannels(LibraryGuid = Undefined) Export
    
    ValueList = New ValueList;

    Query = New Query;
    Query.Text = QueryTextConnectedAppEndpoints();
    QueryResult = Query.Execute();
    If NOT QueryResult.IsEmpty() Then
        
        ValueTable = QueryResult.Unload();
        
        If LibraryGuid <> Undefined Then
            FilterParameters = New Structure;
            FilterParameters.Insert("LibraryGuid", LibraryGuid);
            ValueTable = ValueTable.FindRows(FilterParameters);
        EndIf;
        
        For Each Item In ValueTable Do
            
            If Item.Connected Then 
                ValueList.Add(Item.Ref, Item.Presentation, True, 
                    PictureLib.FL_Connected);
            Else
                ValueList.Add(Item.Ref, Item.Presentation, False, 
                    PictureLib.FL_Disconnected);   
            EndIf;
            
        EndDo;
        
    EndIf;
        
    Return ValueList;
    
EndFunction // ExchangeChannels()

// Returns a new channel parameters structure.
//
// Parameters:
//  LibraryGuid          - String - library guid which is used to identify 
//                         different implementations of specific channel.
//  FormName             - Stirng - The name of the form.
//
// Returns:
//  Structure - with values:
//      * FormName         - String    - The name of the form. This is generated
//          as a full path to the Form metadata object (for example, "Catalog.Contractors.Form.ObjectForm") 
//          or a full path to an application object qualified by the default form name.
//      * FullName         - String    - Full channel name.
//      * ShortName        - String    - Short channel name.
//      * BasicChannelGuid - String    - Library guid which is used to identify 
//                      different implementations of specific channel.
//      * Parameters       - Structure - Additional parameters.
//  
Function NewChannelParameters(Val LibraryGuid, FormName) Export
    
    ChannelProcessor = FL_InteriorUse.NewAppEndpointProcessor(LibraryGuid);      
    ChannelProcessorMetadata = ChannelProcessor.Metadata();
    
    ChannelParameters = NewChannelParametersStructure();
    ChannelParameters.FormName = StrTemplate("%1.Form.%2",
        ChannelProcessorMetadata.FullName(), FormName);        
    ChannelParameters.FullName = ChannelProcessor.ChannelFullName();
    ChannelParameters.ShortName = ChannelProcessor.ChannelShortName();
    ChannelParameters.BasicChannelGuid = LibraryGuid;
    
    Return ChannelParameters;     
    
EndFunction // NewChannelParameters()

// Returns a new app endpoint properties.
//
// Returns:
//  Structure - app endpoint properties with keys:
//      * AppEndpoint  - CatalogRef.FL_Channels - reference to the app endpoint.
//      * AppResources - ValueTable             - build from the mock app resources table. 
//
Function NewAppEndpointProperties() Export
    
    AppResources = Metadata.Catalogs.FL_Channels.TabularSections.AppResources;
    
    AppEndpointProperties = New Structure;
    AppEndpointProperties.Insert("AppEndpoint");
    AppEndpointProperties.Insert("AppResources", FL_CommonUse
        .NewMockOfMetadataObjectAttributes(AppResources));
    
    Return AppEndpointProperties;
    
EndFunction // NewAppEndpointProperties()

#EndRegion // ProgramInterface

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
Function AddAvailableChannel(DataProcessor, ValueList)
    
    PresentationTemplate = NStr("en='%1 (ver. %2)';
        |ru='%1 (вер. %2)';
        |uk='%1 (вер. %2)';
        |en_CA='%1 (ver. %2)'");
    
    LibraryGuid = DataProcessor.LibraryGuid();
    ChannelName = DataProcessor.ChannelFullName();
    Version = DataProcessor.Version();
    
    Presentation = StrTemplate(PresentationTemplate, ChannelName, Version);  
    ValueList.Add(LibraryGuid, Presentation);
   
EndFunction // AddAvailableChannel()

// Only for internal use.
//
Function NewChannelParametersStructure()
    
    Parameters = New Structure;
    Parameters.Insert("FormName");
    Parameters.Insert("FullName");
    Parameters.Insert("ShortName");
    Parameters.Insert("BasicChannelGuid");
    Parameters.Insert("Parameters", New Structure());
    Return Parameters;
    
EndFunction // NewChannelParametersStructure()

// Only for internal use.
// 
Function QueryTextConnectedAppEndpoints()
    
    Return "
        |SELECT
        |   AppEndpoints.Ref AS Ref,
        |   AppEndpoints.BasicChannelGuid AS LibraryGuid, 
        |   AppEndpoints.Connected AS Connected,
        |   Presentation(AppEndpoints.Ref) AS Presentation
        |FROM
        |   Catalog.FL_Channels AS AppEndpoints
        |WHERE
        |   AppEndpoints.DeletionMark = False   
        |";
    
EndFunction // QueryTextConnectedAppEndpoints()

// Only for internal use.
// 
Function QueryTextAppEndpointSettings()
    
    Return "
        |SELECT
        |   AppEndpoints.Ref              AS Ref,
        |   AppEndpoints.Description      AS Description,
        |
        |   AppEndpoints.BasicChannelGuid AS BasicChannelGuid,
        |   AppEndpoints.Connected        AS Connected,
        |   AppEndpoints.Log              AS Log,
        |   AppEndpoints.Version          AS Version,  
        |
        |   AppEndpoints.ChannelData.(
        |       FieldName   AS FieldName,
        |       FieldValue  AS FieldValue
        |       ) AS ChannelData,
        |   
        |   AppEndpoints.EncryptedData.(
        |       EncryptNumber AS EncryptNumber,
        |       FieldName     AS FieldName,
        |       FieldValue    AS FieldValue
        |       ) AS EncryptedData
        |   
        |FROM
        |   Catalog.FL_Channels AS AppEndpoints
        |   
        |WHERE
        |    AppEndpoints.Ref = &AppEndpoint
        |AND AppEndpoints.DeletionMark = FALSE
        |";
    
EndFunction // QueryTextAppEndpointSettings()

#EndRegion // ServiceProceduresAndFunctions

#EndIf