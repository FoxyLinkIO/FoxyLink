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

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region ProgramInterface
    
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
                ValueList.Add(DataProcessor.LibraryGuid(),
                    StrTemplate("%1 (ver. %2)", 
                        DataProcessor.ChannelFullName(),
                        DataProcessor.Version()));
            
            Except
                
                FL_CommonUseClientServer.NotifyUser(ErrorDescription());
                Continue;
                
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
            
            ChannelProcessor = NewChannelProcessor(Channel.Value);
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
// Returns:
//  ValueList - with values:
//      * Value - CatalogRef.FL_Channels - reference to the channel.
//
Function ExchangeChannels() Export
    
    ValueList = New ValueList;

    Query = New Query;
    Query.Text = QueryTextConnectedChannels();
    QueryResult = Query.Execute();
    If NOT QueryResult.IsEmpty() Then
        
        ValueTable = QueryResult.Unload();
        For Each Item In ValueTable Do
            If Item.Connected Then 
                ValueList.Add(Item.Ref, , True, PictureLib.FL_Connected);
            Else
                ValueList.Add(Item.Ref, , False, PictureLib.FL_Disconnected);   
            EndIf;
        EndDo;
        
    EndIf;
        
    Return ValueList;
    
EndFunction // ExchangeChannels()

// Returns new channel data processor for every server call.
//
// Parameters:
//  LibraryGuid - String - library guid which is used to identify 
//                         different implementations of specific channel.
//
// Returns:
//  DataProcessorObject.<Data processor name> - channel data processor.
//
Function NewChannelProcessor(Val LibraryGuid) Export
    
    DataProcessorName = FL_InteriorUseReUse.IdentifyPluginProcessorName(
        LibraryGuid, "Channels");
           
    Return DataProcessors[DataProcessorName].Create();
    
EndFunction // NewChannelProcessor()

// Returns new delivery result structure.
//
// Returns:
//  Structure - message delivery result with values:
//      * Success          - Boolean   - shows whether delivery was successful.
//      * StatusCode       - Number    - state (reply) code returned by the HTTP service.
//      * OriginalResponse - Arbitrary - original response object.
//      * StringResponse   - String    - string response presentation.
//
Function NewChannelDeliverResult() Export

    ChannelDeliveryResult = New Structure;
    ChannelDeliveryResult.Insert("Success", False);
    ChannelDeliveryResult.Insert("StatusCode");
    ChannelDeliveryResult.Insert("StringResponse");
    ChannelDeliveryResult.Insert("OriginalResponse");
    
    Return ChannelDeliveryResult;
    
EndFunction // ChannelDeliveryResult()

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
    
    ChannelProcessor = NewChannelProcessor(LibraryGuid);      
    ChannelProcessorMetadata = ChannelProcessor.Metadata();
    
    ChannelParameters = NewChannelParametersStructure();
    ChannelParameters.FormName = StrTemplate("%1.Form.%2",
        ChannelProcessorMetadata.FullName(), FormName);        
    ChannelParameters.FullName = ChannelProcessor.ChannelFullName();
    ChannelParameters.ShortName = ChannelProcessor.ChannelShortName();
    ChannelParameters.BasicChannelGuid = LibraryGuid;
    
    Return ChannelParameters;     
    
EndFunction // NewChannelParameters()

// Transfers the stream to the specified exchange channel.
//
// Parameters:
//  Channel    - CatalogRef.FL_Channels - exchange channel.
//  Stream     - Stream                 - a data stream that can be read successively 
//                                          or/and where you can record successively. 
//             - MemoryStream           - specialized version of Stream object for 
//                                          operation with the data located in the RAM.
//             - FileStream             - specialized version of Stream object for 
//                                          operation with the data located in a file on disk.
//  Properties - Structure              - channel properties.
//      * Key   - String - property name.
//      * Value - String - property value.
//
// Returns:
//  Structure - the deliver result, see function Catalogs.FL_Channels.NewChannelDeliverResult.
//
Function TransferStreamToChannel(Channel, Stream, Properties) Export
    
    Query = New Query;
    Query.Text = QueryTextChannelSettings();
    Query.SetParameter("ExchangeChannel", Channel);
    QueryResult = Query.Execute();
    If QueryResult.IsEmpty() Then
        // Error    
    EndIf;
    
    ChannelSettings = QueryResult.Select();
    ChannelSettings.Next();
    If NOT ChannelSettings.Connected Then
        // Error    
    EndIf;
    
    ChannelProcessor = NewChannelProcessor(ChannelSettings.BasicChannelGuid);
    ChannelProcessor.ChannelData.Load(ChannelSettings.ChannelData.Unload());
    ChannelProcessor.EncryptedData.Load(
        ChannelSettings.EncryptedData.Unload());    
    Return ChannelProcessor.DeliverMessage(Stream, Properties);    
    
EndFunction // TransferStreamToChannel()

#EndRegion // ProgramInterface

#Region ServiceProceduresAndFunctions

// Only for internal use.
// 
Function QueryTextConnectedChannels()
    
    QueryText = "
        |SELECT
        |   Channels.Ref         AS Ref,
        |   Channels.Connected   AS Connected
        |FROM
        |   Catalog.FL_Channels AS Channels
        |WHERE
        |   Channels.DeletionMark = False   
        |";
    Return QueryText;
    
EndFunction // QueryTextConnectedChannels()

// Only for internal use.
// 
Function QueryTextChannelSettings()
    
    QueryText = "
        |SELECT
        |   Channels.Ref                AS Ref,
        |   Channels.Description        AS Description,
        |   Channels.BasicChannelGuid   AS BasicChannelGuid,
        |   Channels.Connected          AS Connected,
        |
        |   Channels.ChannelData.(
        |       FieldName   AS FieldName,
        |       FieldValue  AS FieldValue
        |       ) AS ChannelData,
        |   
        |   Channels.EncryptedData.(
        |       EncryptNumber AS EncryptNumber,
        |       FieldName     AS FieldName,
        |       FieldValue    AS FieldValue
        |       ) AS EncryptedData
        |   
        |FROM
        |   Catalog.FL_Channels AS Channels
        |   
        |WHERE
        |    Channels.Ref = &ExchangeChannel
        |AND Channels.DeletionMark = FALSE
        |";  
    Return QueryText;
    
EndFunction // QueryTextChannelSettings()

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
    
#EndRegion // ServiceProceduresAndFunctions

#EndIf