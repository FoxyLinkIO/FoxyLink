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

// Calculates OAuth signature. 
//
// Parameters:
//  HTTPMethod           - String - HTTP method name. 
//  URL                  - String - reference to the resource.
//  OAuthSignatureMethod - String - type of signature method. 
//  PreparedSignature    - String - prepared signature parameters as string.
//  EncryptedData        - FormDataCollection - collection with encrypted data.
//
// Returns:
//  String - base64-encoded (HMAC) signature. 
//
Function OAuthSignature(Val HTTPMethod, Val URL, Val OAuthSignatureMethod, 
    Val PreparedSignature, EncryptedData) Export
    
    UrlSignature = HTTPMethod + "&" 
        + EncodeString(URL, StringEncodingMethod.URLEncoding) + "&" 
        + EncodeString(PreparedSignature, StringEncodingMethod.URLEncoding);
   
    KeySignature = EncryptedFiledValue("oauth_consumer_secret", EncryptedData) 
        + "&" + EncryptedFiledValue("oauth_token_secret", EncryptedData);
    
    If Upper(TrimAll(OAuthSignatureMethod)) = "HMAC-SHA1" Then
 
        Signature = HMAC(UrlSignature, KeySignature, 
            HashFunction.SHA1);
        
    Else
        
        ErrorMessage = NStr("en = 'Signature method is not supported.';
            |ru = 'Сигнатурный метод не поддерживаеться.'");
            
        Raise ErrorMessage;
        
    EndIf;
    
    Return Signature;           
    
EndFunction // OAuthSignature()

// Implements the keyed-hash message authentication code (HMAC). 
// HMAC is a specific type of message authentication code (MAC) involving 
// a cryptographic hash function and a secret cryptographic key.
//
// Parameters:
//  Message   - String       - message to be authenticated. 
//            - BinaryData   - message bytes to be authenticated.
//  SecretKey - String       - secret key in string presentation.
//            - BinaryData   - secret key in byte presentation.
//  HashFunc  - HashFunction - contains type of hash-function. Defines 
//                                the method for calculating the hash-sum and 
//                                type of value, being calculated.
//
// Returns:
//  String - HMAC as base64-encoded string. 
//
Function HMAC(Val Message, Val SecretKey, HashFunc) Export
    
    If HashFunc = HashFunction.MD5
        OR HashFunc = HashFunction.SHA1
        OR HashFunc = HashFunction.SHA256 Then
        BlockSize = 64;
    Else
        Raise NStr("en = 'Unsupported HMAC hash function.';
            |ru = 'Неподдерживаемая хеш-функция HMAC.'");
    EndIf;
    
    If TypeOf(Message) = Type("String") Then
        Message = GetBinaryDataFromString(Message);        
    EndIf;
    
    If TypeOf(SecretKey) = Type("String") Then
        SecretKey = GetBinaryDataFromString(SecretKey);        
    EndIf;
    
    If SecretKey.Size() > BlockSize Then
        SecretKey = Hash(SecretKey, HashFunc);        
    EndIf;
    
    EmptyBin = GetBinaryDataFromString("");
    SecretKey = BinaryLeft(SecretKey, BlockSize);
    К0 = BinaryRightPad(SecretKey, BlockSize, "0x00");

    IPad = BinaryRightPad(EmptyBin, BlockSize, "0x36");
    KIPad = BinaryBitwiseXOR(К0, IPad);

    OPad = BinaryRightPad(EmptyBin, BlockSize, "0x5C");
    KOPad = BinaryBitwiseXOR(К0, OPad);

    Message = BinaryConcat(KIPad, Message);
    Hash = BinaryConcat(KOPad, Hash(Message, HashFunc));
    Return Base64String(Hash(Hash, HashFunc));
    
EndFunction // HMAC()

// Implements the incremental calculation of hash-sum by added data. 
// The calculation method and type of value, being calculated, are defined by 
// the type of hash-function.
//
// Parameters:
//  Value        - BinaryData   - added binary data. 
//               - String       - added text data. 
//               - Stream       - stream which gives data for updating a hash-sum.
//  HashFunction - HashFunction - contains type of hash-function. Defines the method 
//                                  for calculating the hash-sum and type of value, 
//                                  being calculated.
//
// Returns:
//  BinaryData - for functions MD5, SHA1 and SHA256 – current value of the hash-sum. 
//  Number     - for function CRC32 – current value of the hash-sum.
//
Function Hash(Value, HashFunction) Export
    
    DataHashing = New DataHashing(HashFunction);
    DataHashing.Append(Value);
    Return DataHashing.HashSum;
    
EndFunction // Hash()

#EndRegion // ProgramInterface

#Region ServiceInterface

// Updates encrypted data table from string body.
//
// Parameters:
//  Body                - String - body with values for update.
//  StringFields        - String - list of fields to find in the body.
//  StringEncryptFields - String - list of fields to be encrypted.
//  EncryptedData       - FormDataCollection - collection to be filled from body.
//
Procedure UpdateEncryptedData(Body, StringFields, StringEncryptFields, 
    EncryptedData) Export
    
    Fields = StrSplit(StringFields, ",");
    EncryptFields = StrSplit(StringEncryptFields, ","); 
    
    BodyParts = StrSplit(Body, "&");
    For Each BodyPart In BodyParts Do
        
        Position = StrFind(BodyPart, "=");
        If Position > 0 Then
            
            FieldName  = Left(BodyPart, Position - 1);
            FieldValue = Mid(BodyPart, Position + 1);
            If Fields.Find(FieldName) <> Undefined Then
                
                FilterResult = EncryptedData.FindRows(New Structure("FieldName", FieldName));
                If FilterResult.Count() = 0 Then
                    RowResult = EncryptedData.Add();
                Else
                    RowResult = FilterResult[0];    
                EndIf;
                
                RowResult.FieldName  = FieldName;
                RowResult.FieldValue = FieldValue;
                If EncryptFields.Find(RowResult.FieldName) <> Undefined Then
                    FL_EncryptionKeys.EncryptString(RowResult.FieldValue, 
                        RowResult.EncryptNumber);       
                EndIf; 
                
            EndIf;
            
        EndIf;
        
    EndDo;
                
EndProcedure // UpdateEncryptedData()

// Returns field value by the passed field name.
//
// Parameters:
//  FieldName     - String - field name.
//  EncryptedData - FormDataCollection - collection with encrypted data.
//
// Returns:
//  String - field value.
//
Function FieldValue(FieldName, EncryptedData) Export
    
    SearchResult = EncryptedData.Find(FieldName, "FieldName");
    If SearchResult <> Undefined 
        AND IsBlankString(SearchResult.EncryptNumber) Then
        
        Return SearchResult.FieldValue;
        
    EndIf;
    
    Raise NStr("en = 'Value not found or encrypted.';
        |ru = 'Значение не найдено или зашифровано.'");
    
EndFunction // FieldValue()
    
#EndRegion // ServiceInterface

#Region ServiceProceduresAndFunctions

// Only for internal use.
//
Function EncryptedFiledValue(FieldName, EncryptedData)
    
    FieldValue = "";
    SearchResult = EncryptedData.Find(FieldName, "FieldName");
    If SearchResult <> Undefined Then
        
        FieldValue = SearchResult.FieldValue;
        EncryptNumber = SearchResult.EncryptNumber;
        If NOT IsBlankString(EncryptNumber) Then
            FL_EncryptionKeys.DecryptString(FieldValue, EncryptNumber);
        EndIf;
          
    EndIf;
    
    Return FieldValue;
  
EndFunction // EncryptedFiledValue()

// Only for internal use.
//
Function BinaryLeft(Val BinaryData, Val BlockSize)

    MemoryStream = New MemoryStream();
    
    DataReader = New DataReader(BinaryData);
    DataWriter = New DataWriter(MemoryStream);
    
    Buffer = DataReader.ReadIntoBinaryDataBuffer(BlockSize);
    If Buffer.Size > 0 Then
        DataWriter.WriteBinaryDataBuffer(Buffer);
    EndIf;

    Return MemoryStream.CloseAndGetBinaryData();

EndFunction // BinaryLeft()

// Only for internal use.
//
Function BinaryRightPad(Val BinaryData, Val BlockSize, Val HexString)
    
    MemoryStream = New MemoryStream();

    DataReader = New DataReader(BinaryData);
    DataWriter = New DataWriter(MemoryStream);

    Buffer = DataReader.ReadIntoBinaryDataBuffer();
    If Buffer.Size > 0 Then
        DataWriter.WriteBinaryDataBuffer(Buffer);
    EndIf;

    PadByte = NumberFromHexString(HexString);
    For n = Buffer.Size + 1 To BlockSize Do
        DataWriter.WriteByte(PadByte);
    EndDo;

    Return MemoryStream.CloseAndGetBinaryData();

EndFunction // BinaryRightPad()

// Only for internal use.
//
Function BinaryBitwiseXOR(Val BinaryData1, Val BinaryData2)

    MemoryStream = New MemoryStream();

    DataReader1 = New DataReader(BinaryData1);
    DataReader2 = New DataReader(BinaryData2);
    DataWriter = New DataWriter(MemoryStream);

    Buffer1 = DataReader1.ReadIntoBinaryDataBuffer();
    Buffer2 = DataReader2.ReadIntoBinaryDataBuffer();
    If Buffer1.Size > Buffer2.Size Then
        Buffer1.WriteBitwiseXor(0, Buffer2, Buffer2.Size);
        DataWriter.WriteBinaryDataBuffer(Buffer1);
    Else 
        Buffer2.WriteBitwiseXor(0, Buffer1, Buffer1.Size);
        DataWriter.WriteBinaryDataBuffer(Buffer2);
    EndIf;

    Return MemoryStream.CloseAndGetBinaryData();

EndFunction // BinaryBitwiseXOR()

// Only for internal use.
//
Function BinaryConcat(Val BinaryData1, Val BinaryData2)

    MemoryStream = New MemoryStream();
    
    DataWriter = New DataWriter(MemoryStream);

    DataReader = New DataReader(BinaryData1);
    Buffer = DataReader.ReadIntoBinaryDataBuffer();
    If Buffer.Size > 0 Then
        DataWriter.WriteBinaryDataBuffer(Buffer);
    EndIf;

    DataReader = New DataReader(BinaryData2);
    Buffer = DataReader.ReadIntoBinaryDataBuffer();
    If Buffer.Size > 0 Then
        DataWriter.WriteBinaryDataBuffer(Buffer);
    EndIf;

    Return MemoryStream.CloseAndGetBinaryData();

EndFunction // BinaryConcat()

#EndRegion // ServiceProceduresAndFunctions