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

// Adds basic authorization header.
//
// Parameters:
//  Headers       - Map        - headers that will be sent to server as a correspondence.
//  Login         - String     - connection login or name of the field in encrypted data.
//  Password      - String     - connection password or name of the field in encrypted data.
//  EncryptedData - ValueTable - collection with encrypted data.
//                      Default value: Undefined.
//
Procedure AddBasicAuthorizationHeader(Headers, Val Login, Val Password, 
    EncryptedData = Undefined) Export
    
    If EncryptedData <> Undefined Then
        Login = EncryptedFiledValue(Login, EncryptedData);    
        Password = EncryptedFiledValue(Password, EncryptedData);
    EndIf;
    
    AuthCombination = StrTemplate("%1:%2", Login, Password);
    Authorization = Base64String(GetBinaryDataFromString(AuthCombination));
    Authorization = StrReplace(Authorization, Chars.CR, "");
    Authorization = StrReplace(Authorization, Chars.LF, "");
    Authorization = StrReplace(Authorization, Chars.CR + Chars.LF, "");
    Headers.Insert("Authorization", StrTemplate("Basic %1", Authorization));
    
EndProcedure // AddBasicAuthorizationHeader()

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
        
        ErrorMessage = NStr("en='Signature method is not supported.';
            |ru='Сигнатурный метод не поддерживаеться.';
            |en_CA='Signature method is not supported.'");
            
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
        Raise NStr("en='Unsupported HMAC hash function.';
            |ru='Неподдерживаемая хеш-функция HMAC.';
            |en_CA='Unsupported HMAC hash function.'");
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

// Calculates a simple checksum used to validate a variety of identification 
// numbers.
//
// Parameters:
//  Number - Number - number for which is needed to calculate a simple checksum.
//
// Returns:
//  Number - calculated checksum. 
//
Function LuhnAlgorithm(Val Number) Export
    
    Result = 0;
    Pair = StrLen(Format(Number, "NG=0")) % 2 = 0;
    While Number > 0 Do
        
        Mod = Number % 10;
        Number = Int(Number / 10);
        
        If Pair Then
            
            Mod = Mod * 2;
            Result = Result + ?(Mod < 10, Mod, Mod % 10 + Int(Mod / 10)); 
            
        Else
            Result = Result + Mod;    
        EndIf;
        
        Pair = NOT Pair;
        
    EndDo;
    
    Return (Result * 9) % 10;
    
EndFunction // LuhnAlgorithm() 

// Generates a random string number of a given length.  
//
// Parameters:
//  Length - Number - needed length of string number. 
//
// Returns:
//  String - random string number of a given length. 
//
Function GenerateRandomNumber(Val Length = 6) Export
    
    UUID = String(New UUID);
    UUID = StrReplace(UUID, "-", "");
    Value = "";
    For Index = 1 To StrLen(UUID) Do
        Symbol = Mid(UUID, Index, 1);
        Value = Value + Right(CharCode(Symbol), 1);
    EndDo;
    
    MinValue = 1;
    MaxValue = 9;
    For Index = 2 To Length Do
        MinValue = MinValue * 10;
        MaxValue = MaxValue + MinValue * 9;
    EndDo;

    RNG = New RandomNumberGenerator(Number(Value));
    RandomNumber = Format(RNG.RandomNumber(MinValue, MaxValue), "NG=0");

    Return RandomNumber;      
    
EndFunction // GenerateRandomNumber()

// Returns the result of logical bitwise AND operator for two numeric values.
//
// Parameters:
//  Number1 - Number - the first operand, an integer in range 0 – 2^32-1.
//  Number2 - Number - the second operand, an integer in range 0 – 2^32-1.
//
// Returns:
//  Number - the result of logical bitwise AND operator for two numeric values. 
//
Function _BitwiseAnd(Number1, Number2) Export
    
    SizeOfInt32 = 4;
    
    Buffer1 = New BinaryDataBuffer(SizeOfInt32);
    Buffer1.WriteInt32(0, Number1);
    
    Buffer2 = New BinaryDataBuffer(SizeOfInt32);
    Buffer2.WriteInt32(0, Number2);
    
    Buffer1.WriteBitwiseAnd(0, Buffer2, Buffer2.Size);
    Return Buffer1.ReadInt32(0);
    
EndFunction // _BitwiseAnd()

#EndRegion // ProgramInterface

#Region ServiceInterface

// Adds and encrypts field value to encrypted data.
//
// Parameters:
//  EncryptedData - FormDataCollection - collection with encrypted data.
//                - ValueTable         - value table with encrypted data.
//  FieldName     - String             - field name.
//  FieldValue    - String             - field value.
//
Procedure AddAndEncryptFieldValue(EncryptedData, FieldName, FieldValue) Export
    
    NewEncryptedDataRow = EncryptedData.Add();
    NewEncryptedDataRow.FieldName  = FieldName;
    NewEncryptedDataRow.FieldValue = FieldValue;
    FL_EncryptionKeys.EncryptString(NewEncryptedDataRow.FieldValue, 
        NewEncryptedDataRow.EncryptNumber);
    
EndProcedure // AddAndEncryptFieldValue()

// Updates encrypted data table from string body.
//
// Parameters:
//  Parameters          - Map    - body with values for update.
//  StringFields        - String - list of fields to find in the body.
//  StringEncryptFields - String - list of fields to be encrypted.
//  EncryptedData       - FormDataCollection - collection to be filled from body.
//
Procedure UpdateEncryptedData(Parameters, StringFields, StringEncryptFields, 
    EncryptedData) Export
    
    Fields = StrSplit(StringFields, ",");
    EncryptFields = StrSplit(StringEncryptFields, ","); 
    
    For Each FieldName In Fields Do
        
        FieldValue = Parameters.Get(FieldName);
        If FieldValue = Undefined Then
            Continue;    
        EndIf;
        
        FL_EncryptionClientServer.SetFieldValue(EncryptedData, FieldName, 
            FieldValue);
                        
        If EncryptFields.Find(FieldName) <> Undefined Then
            
            FilterParameters = New Structure("FieldName", FieldName);
            FilterResult = EncryptedData.FindRows(FilterParameters);
            FL_EncryptionKeys.EncryptString(FilterResult[0].FieldValue, 
                FilterResult[0].EncryptNumber);
                
        EndIf;
        
    EndDo;
                    
EndProcedure // UpdateEncryptedData()

// Returns field value by the passed field name.
//
// Parameters:
//  FieldName  - String - field name.
//  Collection - FormDataCollection - collection with encrypted data.
//             - ValueTable         - value table with encrypted data.
//
// Returns:
//  String - field value.
//
Function FieldValue(FieldName, Collection) Export
    
    FilterParameters = New Structure("FieldName", FieldName);
    FilterResult = Collection.FindRows(FilterParameters);
    If FilterResult.Count() = 1 
        AND IsBlankString(FilterResult[0].EncryptNumber) Then
        Return FilterResult[0].FieldValue;
    EndIf;
        
    Raise NStr("en='Value not found or encrypted.';
        |ru='Значение не найдено или зашифровано.';
        |uk='Значення не знайдено або зашифровано.';
        |en_CA='Value not found or encrypted.'");
    
EndFunction // FieldValue()

// Returns encrypted field value by the passed field name.
//
// Parameters:
//  FieldName  - String             - field name.
//  Collection - FormDataCollection - collection with encrypted data.
//             - ValueTable         - value table with encrypted data.
//
// Returns:
//  String - field value.
//
Function EncryptedFiledValue(FieldName, Collection) Export
    
    FilterParameters = New Structure("FieldName", FieldName);
    FilterResult = Collection.FindRows(FilterParameters);
    If FilterResult.Count() = 1 Then
        
        FieldValue = FilterResult[0].FieldValue;
        EncryptNumber = FilterResult[0].EncryptNumber;
        If NOT IsBlankString(EncryptNumber) Then
            FL_EncryptionKeys.DecryptString(FieldValue, EncryptNumber);
        EndIf;
          
    EndIf;
    
    Return FieldValue;
  
EndFunction // EncryptedFiledValue()

#EndRegion // ServiceInterface

#Region ServiceProceduresAndFunctions

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