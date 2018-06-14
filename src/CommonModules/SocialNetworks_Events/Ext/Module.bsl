////////////////////////////////////////////////////////////////////////////////
// This file is part of FoxyLink.
// Copyright © 2018 Petro Bazeliuk.
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

// Returns a processing result.
//
// Parameters:
//  Exchange - CatalogRef.FL_Exchanges - reference of the FL_Exchanges catalog.
//  Message  - CatalogRef.FL_Messages  - reference of the FL_Messages catalog.
//
// Returns:
//  Structure - see fucntion Catalogs.FL_Jobs.NewJobResult. 
//
Function ProcessMessage(Exchange, Message) Export
    
    Operation = FL_CommonUse.ObjectAttributeValue(Message, "Operation");
    If Operation = Catalogs.FL_Operations.Create Then
        Return CreateSocial(Exchange, Message);
    ElsIf Operation = Catalogs.FL_Operations.Merge Then
        Return MergeSocial(Exchange, Message);
    EndIf;
  
EndFunction // ProcessMessage()

#EndRegion // ProgramInterface

#Region ServiceInterface

// Returns the external event handler info structure for this module.
//
// Returns:
//  Structure - see function FL_InteriorUse.NewExternalEventHandlerInfo.
//
Function EventHandlerInfo() Export
    
    EventHandlerInfo = FL_InteriorUse.NewExternalEventHandlerInfo();
    EventHandlerInfo.Description = StrTemplate(NStr("
            |en='Social networks event handler, ver. %1.';
            |ru='Обработчик событий социальных сетей, вер. %1.';
            |uk='Обробник подій соціальних мереж, вер. %1.';
            |en_CA='Social networks handler, ver. %1.'"), 
        EventHandlerInfo.Version);
    EventHandlerInfo.EventHandler = "SocialNetworks_Events.ProcessMessage";
    EventHandlerInfo.Version = "1.0.4";
    EventHandlerInfo.Transactional = True;
       
    EventSources = New Array;
    EventSources.Add(Upper("HTTPService.FL_AppEndpoint"));
    EventSources.Add(Upper("HTTPСервис.FL_AppEndpoint"));
    
    EventHandlerInfo.Publishers.Insert(Catalogs.FL_Operations.Create, 
        EventSources); 
        
    EventHandlerInfo.Publishers.Insert(Catalogs.FL_Operations.Merge, 
        EventSources);
       
    Return FL_CommonUse.FixedData(EventHandlerInfo);
    
EndFunction // EventHandlerInfo()

#EndRegion // ServiceInterface

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
Procedure CreateSocialMessage(SocialUser, SocialConversation, Context)
    
    SocialMessage = InformationRegisters.SocialNetworks_Messages
        .NewSocialMessage();
        
    SocialMessage.SocialConversation = SocialConversation;
    SocialMessage.SocialUser = SocialUser;
    SocialMessage.ChatId = TrimAll(Context.ChatId);
    SocialMessage.MessageID = TrimAll(Context.MessageId);
    SocialMessage.Text = TrimAll(Context.Text);
    If Context.Property("CollaborationMessageId", SocialMessage.CollaborationMessageId) Then
        SocialMessage.Incoming = False;
        SocialMessage.Outgoing = True;
    Else
        SocialMessage.Incoming = True;
        SocialMessage.Outgoing = False;    
    EndIf;
    
    If Context.Property("User") Then
        SocialMessage.User = DataProcessors.FL_CollaborationSystem
            .UserByCollaborationSystemUserID(Context.User);
    Else
        SocialMessage.User = Constants.SocialNetworks_DefaultUser.Get();
    EndIf;
    
    SupportedTypes = New Array;
    SupportedTypes.Add(Type("Date"));
    ConversionResult = FL_CommonUse.ConvertValueIntoPlatformObject(
        Context.Date, SupportedTypes);
    If ConversionResult.TypeConverted Then
        SocialMessage.Date = ConversionResult.ConvertedValue;
    Else
        SocialMessage.Date = CurrentSessionDate();   
    EndIf;
    
    InformationRegisters.SocialNetworks_Messages.CreateSocialMessage(
        SocialMessage);        
    
EndProcedure // CreateSocialMessage()

// Only for internal use.
//
Function CreateSocial(Exchange, Message)
    
    JobResult = Catalogs.FL_Jobs.NewJobResult();

    Try
        
        Context = Catalogs.FL_Messages.DeserializeContext(Message);
        
        SocialNetwork = Enums.SocialNetworks[Context.ChannelName];
        SocialUser = Catalogs.SocialNetworks_Users.SocialNetworkUser(
            TrimAll(Context.UserId), SocialNetwork, Context.Description);   
        SocialConversation = Catalogs.SocialNetworks_Conversations
            .SocialNetworkConversation(SocialUser, TrimAll(Context.ChatId));  
        CreateSocialMessage(SocialUser, SocialConversation, Context);
        
        JobResult.StatusCode = FL_InteriorUseReUse.OkStatusCode();
            
    Except

        FL_InteriorUse.WriteLog("SocialNetworks_Events.ProcessMessage", 
            EventLogLevel.Error, 
            Metadata.CommonModules.SocialNetworks_Events,
            ErrorDescription(), 
            JobResult);
        
    EndTry;
    
    JobResult.Success = FL_InteriorUseReUse.IsSuccessHTTPStatusCode(
        JobResult.StatusCode);
    Return JobResult;
    
EndFunction // CreateSocial()

// Only for internal use.
//
Function MergeSocial(Exchange, Message)
    
    JobResult = Catalogs.FL_Jobs.NewJobResult();

    Try
        
        RequestBody = Catalogs.FL_Messages.DeserializeContext(Message);
        Context = RequestBody.Object;   
        
        SupportedTypes = New Array;
        SupportedTypes.Add(Type("CatalogRef.Партнеры"));
        ConversionResult = FL_CommonUse.ConvertValueIntoPlatformObject(
            Context.Partner, SupportedTypes);
            
        Success = False;
        If ConversionResult.TypeConverted Then    
            
            UserRef = ConversionResult.ConvertedValue;
            
            SocialNetwork = Enums.SocialNetworks[Context.ChannelName];
            SocialUser = Catalogs.SocialNetworks_Users.SocialNetworkUser(
                TrimAll(Context.UserId), SocialNetwork, , UserRef);
            Catalogs.SocialNetworks_Conversations
                .SocialNetworkConversation(SocialUser, TrimAll(Context.ChatId));    
            Success = True;    
                
        EndIf;        
        
        Settings = Catalogs.FL_Exchanges.ExchangeSettingsByRefs(Exchange, 
            Message.Operation);
        StreamObject = FL_InteriorUse.NewFormatProcessor(
            Settings.BasicFormatGuid);
        
        // Open new memory stream and initialize format processor.
        Stream = New MemoryStream;
        StreamObject.Initialize(Stream, Settings.APISchema);
        
        NewContext = New Structure;
        NewContext.Insert("Settings", New Structure);
        NewContext.Settings.Insert("TaskId", Context.TaskId);
        NewContext.Settings.Insert("Success", Success);
        OutputParameters = Catalogs.FL_Exchanges.NewOutputParameters(Settings, 
            NewContext);
                    
        FL_DataComposition.Output(StreamObject, OutputParameters);
        
        // Fill MIME-type information.
        Properties = Catalogs.FL_Exchanges.NewProperties();
        FillPropertyValues(Properties, Message);
        Properties.ContentType = StreamObject.FormatMediaType();
        Properties.ContentEncoding = StreamObject.ContentEncoding;
        Properties.FileExtension = StreamObject.FormatFileExtension();
        Properties.MessageId = Message.Code;
        
        // Close format stream and memory stream.
        StreamObject.Close();
        Payload = Stream.CloseAndGetBinaryData();
        
        JobResult.StatusCode = FL_InteriorUseReUse.OkStatusCode();
        
        Catalogs.FL_Jobs.AddToJobResult(JobResult, "Payload", Payload);     
        Catalogs.FL_Jobs.AddToJobResult(JobResult, "Properties", Properties); 
            
    Except
        
        FL_InteriorUse.WriteLog("SocialNetworks_Events.ProcessMessage", 
            EventLogLevel.Error,
            Metadata.Catalogs.FL_Exchanges,
            ErrorDescription(),
            JobResult);
        
    EndTry;
    
    JobResult.Success = FL_InteriorUseReUse.IsSuccessHTTPStatusCode(
        JobResult.StatusCode);
    Return JobResult;
    
EndFunction // MergeSocial()

#EndRegion // ServiceProceduresAndFunctions