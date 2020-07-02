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
        Return CreateApdex(Exchange, Message);
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
	EventHandlerInfo.Version = "0.8";    
    EventHandlerInfo.Description = StrTemplate(NStr("
            |en='ELK bulk event handler, ver. %1.';
            |ru='Обработчик события при операции bulk в ELK, вер. %1.'"), 
        EventHandlerInfo.Version);
    EventHandlerInfo.EventHandler = "омСобытияFoxyLink_BulkELK.ProcessMessage";
       
    EventSources = New Array;
    EventSources.Add(Upper("HTTPService.FL_AppEndpoint"));
    EventSources.Add(Upper("HTTPСервис.FL_AppEndpoint"));
    EventSources.Add(Upper("Catalog.*"));
    EventSources.Add(Upper("Справочник.*"));
    EventSources.Add(Upper("Document.*"));
    EventSources.Add(Upper("Документ.*"));
    EventSources.Add(Upper("ChartOfCharacteristicTypes.*"));
    EventSources.Add(Upper("ПланВидовХарактеристик.*"));
    EventSources.Add(Upper("InformationRegister.*"));
    EventSources.Add(Upper("РегистрСведений.*"));
    EventSources.Add(Upper("AccumulationRegister.*"));
    EventSources.Add(Upper("РегистрНакопления.*"));
		
    EventHandlerInfo.Publishers.Insert(Catalogs.FL_Operations.Create, 
        EventSources); 
               
    Return FL_CommonUse.FixedData(EventHandlerInfo);
    
EndFunction // EventHandlerInfo()

#EndRegion // ServiceInterface

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
Function CreateApdex(Exchange, Message)
    
    JobResult = Catalogs.FL_Jobs.NewJobResult();
    
	Try
		
        Settings = Catalogs.FL_Exchanges.ExchangeSettingsByRefs(Exchange, Message.Operation);
        StreamObject = FL_InteriorUse.NewFormatProcessor(
            Settings.BasicFormatGuid);
        
        // Open new memory stream and initialize format processor.
        Stream = New MemoryStream;
        StreamObject.Initialize(Stream, Settings.APISchema);
        
        OutputParameters = Catalogs.FL_Exchanges.NewOutputParameters(Settings, 
            Catalogs.FL_Messages.DeserializeContext(Message));
                    
        FL_DataComposition.Output(StreamObject, OutputParameters);
        
        // Fill MIME-type information.
        Properties = Catalogs.FL_Exchanges.NewProperties();
        FillPropertyValues(Properties, Message);
        Properties.ContentType = FormatMediaType();
        Properties.ContentEncoding = StreamObject.ContentEncoding;
        Properties.FileExtension = StreamObject.FormatFileExtension();
        Properties.MessageId = Message.Code;
        
        // Close format stream and memory stream.
        StreamObject.Close();
        Payload = Stream.CloseAndGetBinaryData();
				
		StreamReader = Payload.OpenStreamForRead();
		StreamReaderToJson = New JSONReader;		
		StreamReaderToJson.OpenStream(StreamReader, Properties.ContentEncoding);		
		ReadResult = ReadJSON(StreamReaderToJson);
		StreamReader.Close();
		
		If TypeOf(ReadResult) <> Type("Массив") Then
			Raise "JSON для отправки в ELK с помощью операции bulk должен быть массивом";
		EndIf;
		
		If ReadResult.Count() = 0 Then
			Raise "JSON для отправки в ELK с помощью операции bulk пустой";
		EndIf;
		
		CRLF = Chars.CR + Chars.LF;
	    StreamForBulk = New MemoryStream;
	    StreamWriterForBulk = New JSONWriter;		
	    StreamWriterForBulk.ValidateStructure = False;
		JSONWriterSettings = Новый JSONWriterSettings(JSONLineBreak.None);
	    StreamWriterForBulk.OpenStream(StreamForBulk, Properties.ContentEncoding,, JSONWriterSettings);
		
		For Each Element In ReadResult Do
						
			StreamWriterForBulk.WriteRaw("{""index"":{}}");	
			StreamWriterForBulk.WriteRaw(CRLF);			
			WriteJSON(StreamWriterForBulk, Element);		  
			StreamWriterForBulk.WriteRaw(CRLF);
					    			
		EndDo; 
		
	    StreamWriterForBulk.Close();
	    Payload = StreamForBulk.CloseAndGetBinaryData();						
        
        JobResult.StatusCode = FL_InteriorUseReUse.OkStatusCode();
        
        Catalogs.FL_Jobs.AddToJobResult(JobResult, "Payload", Payload);     
        Catalogs.FL_Jobs.AddToJobResult(JobResult, "Properties", Properties); 

    Except
        
        FL_InteriorUse.WriteLog("омСобытияFoxyLink_BulkELK.ProcessMessage", 
            EventLogLevel.Error,
            Metadata.Catalogs.FL_Exchanges,
            ErrorDescription(),
            JobResult);
            
    EndTry;
    
    JobResult.Success = FL_InteriorUseReUse.IsSuccessHTTPStatusCode(
        JobResult.StatusCode);
    Return JobResult;

    
EndFunction 

// Returns format media type.
//
// Returns:
//  String - format media type.
//
Function FormatMediaType() Export
    
    Return "application/x-ndjson";
    
EndFunction // FormatMediaType()


#EndRegion // ServiceProceduresAndFunctions