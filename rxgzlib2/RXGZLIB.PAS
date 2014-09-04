{$AlignCode+,AlignData+,AlignRec-,Asm-,B-,Cdecl+,D+,Delphi+,Frame-,G3+,I-}
{$L+,Optimise+,OrgName+,P-,Q-,R-,SmartLink+,Speed+,T-,V-,W-,X+,Z-,ZD+}
{$M 16384}
{$D REXX interface to the ZLIB library}
LIBRARY RxGzLib;
USES Os2Def, Os2Rexx, Strings, DOS;
TYPE
  gzFile = Pointer;
{--------------------}
CONST
  FunctionTable: Array [0..6] of pChar = (
    'RxGzUnloadFuncs', 
    'RxGzFile', 
    'RxUngzFile', 
    'RxGzString', 
    'RxUngzString', 
    'RxGzCrc32',
    'RxGzAdler32'
  );
  BUFLEN = 4096;
  GZH: Array [1..10] of Char = #31#139#8#0#0#0#0#0#0#255;
{--------------------}
Function adler32 (crc: ULong; var buf; len: Integer): ULong; external 'Z' index 1;
Function compress (var dest; var destlen: ULong; const source; sourcelen: ULong): Integer; external 'Z' index 3;
Function compress2 (var dest; var destlen: ULong; source: PChar; sourcelen: ULong; method: Integer): Integer; external 'Z' index 2;
Function uncompress (var dest; var destlen: ULong; const source; sourcelen: ULong): Integer; external 'Z' index 63;
Function crc32 (crc: ULong; var buf; len: Integer): ULong; external 'Z' index 5;
Function gzdopen (fd: Integer; mode: PChar): gzFile; external 'Z' index 16;
Function gzwrite (gzf: gzFile; var buf; len: Integer): Integer; external 'Z' index 21;
Function gzread (gzf: gzFile; var buf; len: Integer): Integer; external 'Z' index 18;
Function gzclose (gzf: gzFile): Integer; external 'Z' index 30;
{--------------------}
{ Converts Longint to String (hexadecimal) }
{--------------------}
function Hex2Str(Value: Longint): String;
var
  I: Longint;
  S: String;
const
  HexDigits: array[0..15] of Char = '0123456789ABCDEF';
begin
  S[0] := Chr(8);
  for I := 0 to 7 do
  begin
    S[8-I] := HexDigits[Value and $0F];
    Value := Value shr 4;
  end;
  Hex2Str := S;
end;
{--------------------}
Procedure gz_compress (fin: PChar; fout: gzFile);
Var
  f: File;
  buf: Array [1..BUFLEN] of Char;
  len, err: LongInt;
Begin
  Assign (f, fin);
  Reset (f, 1);
  While (true) Do
    Begin
      BlockRead (f, buf, SizeOf (buf), len);
      If (len = 0) Then break;
      gzwrite (fout, buf, len);
    End;
  Close (f);
  gzclose (fout);
End;
{--------------------}
Procedure gz_uncompress (fin: gzFile; fout: PChar);
Var
  f: File;
  buf: Array [1..BUFLEN] of Char;
  len, err: Integer;
Begin
  Assign (f, fout);
  Rewrite (f, 1);
  While (true) Do
    Begin
      len := gzread (fin, buf, SizeOf (buf));
      If (len = 0) Then break;
      BlockWrite (f, buf, len);
    End;
  Close (f);
  gzclose (fin);
End;
{--------------------}
Procedure FileToGz (InFile, OutFile: PChar);
Var
  f: File;
  gzf: gzFile;
Begin
  Assign (f, OutFile);
  Rewrite (f, 1);
  gzf := gzdopen (FileRec(f).Handle, 'wb');
  gz_compress (InFile, gzf);
  Close (f);
End;
{--------------------}
Procedure GzToFile (InFile, OutFile: PChar);
Var
  f: File;
  gzf: gzFile;
Begin
  Assign (f, InFile);
  Reset (f, 1);
  gzf := gzdopen (FileRec(f).Handle, 'rb');
  gz_uncompress (gzf, OutFile);
  Close (f);
End;
{--------------------}

Function RxGzLoadFuncs(FuncName  : PChar;
                       ArgC      : ULong;
                       Args      : pRxString;
                       QueueName : pChar;
                       Var Ret   : RxString): ULong; export;
Var
  j: LongInt;
Begin
  Ret.strLength := 0;
  If (ArgC > 0)
    Then                { Do not allow parameters }
      RxGzLoadFuncs := 40
    Else
      Begin
        For j := Low (FunctionTable) To High (FunctionTable) Do
          RexxRegisterFunctionDLL (FunctionTable [j], 'RXGZLIB', FunctionTable [j]);
        RxGzLoadFuncs := 0;
      End;
End;

Function RxGzUnloadFuncs(FuncName  : PChar;
                         ArgC      : ULong;
                         Args      : pRxString;
                         QueueName : pChar;
                         Var Ret   : RxString): ULong; export;
Var
  j: LongInt;
Begin
  Ret.strLength := 0;
  If (ArgC > 0)
    Then
      RxGzUnloadFuncs := 40
    Else
      Begin
        For j := Low (FunctionTable) To High (FunctionTable) Do
          RexxDeregisterFunction (FunctionTable [j]);
        RxGzUnloadFuncs := 0;
      End;
End;

{ Gzips file1 into file2. Returns 0 if Ok }

Function RxGzFile (FuncName  : PChar;
                   ArgC      : ULong;
                   Args      : pRxString;
                   QueueName : pChar;
                   Var Ret   : RxString): ULong; export;
Var
  i: ULong;
  fin, fout: PChar;
Begin
  If (ArgC = 0) Then
    Begin
      RxGzFile := 40;  { At least one parameter required }
      Exit;
    End;
  For i := 1 To ArgC Do
    Begin
      Case i of
        1: fin := StrNew (Args^.strptr);
        2: fout := StrNew (Args^.strptr);
      End;
      Inc (Args);
    End;
  FileToGz (fin, fout);
  Ret.StrLength := 0;
  StrCopy (Ret.strptr, '');
  RxGzFile := DosError;
End;

{ UnGzips file1 into file2. Returns 0 if Ok }

Function RxUngzFile (FuncName  : PChar;
                     ArgC      : ULong;
                     Args      : pRxString;
                     QueueName : pChar;
                     Var Ret   : RxString): ULong; export;
Var
  i: ULong;
  fin, fout: PChar;
Begin
  If (ArgC = 0) Then
    Begin
      RxUngzFile := 40;  { At least one parameter required }
      Exit;
    End;
  For i := 1 To ArgC Do
    Begin
      Case i of
        1: fin := StrNew (Args^.strptr);
        2: fout := StrNew (Args^.strptr);
      End;
      Inc (Args);
    End;
  GzToFile (fin, fout);
  Ret.StrLength := 0;
  StrCopy (Ret.strptr, '');
  RxUngzFile := DosError;
End;

{Returns gzipped string with all needed GZIP or ZLIB headers and checksum }

Function RxGzString (FuncName  : PChar;
                     ArgC      : ULong;
                     Args      : pRxString;
                     QueueName : pChar;
                     Var Ret   : RxString): ULong; export;
Var
  i, ilen, olen, theCRC: ULong;
  astr: String;
  err: LongInt;
  fin, fout: PChar;
Begin
  If (ArgC = 0) Then
    Begin
      RxGzString := 40;  { At least one parameter required }
      Exit;
    End;
  For i := 1 To ArgC Do
    Begin
      Case i of
        1: Begin
             astr := StrPas (Args^.strptr);
             Val (astr, ilen, Err);
             GetMem (fin, ilen+1);
           End;
        2: Move (Args^.strptr^, fin^, ilen);
        3: astr := StrPas (Args^.strptr);
      End;
      Inc (Args);
    End;

  GetMem (fout, ilen+1);
  If (UpCase (astr[1]) = 'Z') Then
    Begin
      theCRC := adler32 (LongInt(0), fin^, ilen);
      olen := ilen + Round (0.001 * ilen) + 8;
      compress (fout^, olen, fin^, ilen);
      GetMem (Ret.strptr, olen+1);
      Ret.StrLength := olen;
      Move (fout^, Ret.strptr^, olen);
      RxGzString := 0;
      FreeMem(fin, ilen+1);
      FreeMem(fout, ilen+1);
      Exit;
    End;

  theCRC := crc32 (LongInt(0), fin^, ilen);
  olen := ilen + Round (0.001 * ilen) + 8;
  compress (fout^, olen, fin^, ilen);
  Dec (olen, 6);
  Move ((fout+2)^, fout^, olen);
  Move (fout^, (fout+10)^, olen);
  Move (GZH, fout^, 10);
  Inc (olen, 10);
  Move (theCRC, fout[olen], 4);
  Inc (olen, 4);
  Move (ilen, fout [olen], 4);
  Inc (olen, 4);

  GetMem (Ret.strptr, olen+1);
  Ret.StrLength := olen;
  Move (fout^, Ret.strptr^, olen);
  RxGzString := 0;
  FreeMem(fin, ilen+1);
  FreeMem(fout, ilen+1);
End;

{Returns ungzipped (or unzlibbed :-)) string}

Function RxUngzString (FuncName  : PChar;
                       ArgC      : ULong;
                       Args      : pRxString;
                       QueueName : pChar;
                       Var Ret   : RxString): ULong; export;
Var
  atmp, i, j, k, ilen, olen, theCRC: ULong;
  err: LongInt;
  fin, fout, ftmp: PChar;
  astr: String;
  flg: Byte;
  extra: SmallWord;
Begin
  If (ArgC = 0) Then
    Begin
      RxUngzString := 40;  { At least one parameter required }
      Exit;
    End;
  For i := 1 To ArgC Do
    Begin
      Case i of
        1: Begin
             astr := StrPas (Args^.strptr);
             Val (astr, ilen, err);
             j := ilen + 1;
             GetMem (fin, j);
           End;
        2: Move (Args^.strptr^, fin^, ilen);
        3: astr := StrPas (Args^.strptr);
      End;
      Inc (Args);
    End;

  If (UpCase (astr[1]) = 'Z') Then
    Begin
      atmp := 5 * j;
      GetMem (fout, atmp+1);
      olen := atmp;
      uncompress (fout^, olen, fin^, ilen);
      GetMem (Ret.strptr, olen+1);
      Ret.StrLength := olen;
      Move (fout^, Ret.strptr^, olen+1);
      FreeMem(fout, atmp+1);
      FreeMem(fin, j);
      RxUngzString := 0;
      Exit;
    End;

  Move (PChar(fin)[ilen-4], atmp, 4);
  Dec (ilen, 4);
  Move (PChar(fin)[ilen-4], theCRC, 4);
  Dec (ilen, 4);
  Move (PChar(fin)[3], flg, 1);
  Move (PChar(fin)[10], fin^, ilen-10);
  Dec (ilen, 10);
  If ((flg and $4 {FEXTRA}) = $4) Then
    Begin
      Move (fin^, extra, 2);
      Dec (ilen, 2);
      Move (PChar(fin)[extra+1], fin^, ilen);
      Dec (ilen, extra);
    End;
  If ((flg and $8 {FNAME}) = $8) Then
    Begin
      While (fin [0] <> #0) Do 
        Begin
          Dec (ilen);
          Move ((fin+1)^, fin^, ilen);
        End;
      Dec (ilen);
      Move ((fin+1)^, fin^, ilen);
    End;
  If ((flg and $10 {FCOMMENT}) = $10) Then
    Begin
      While (fin [0] <> #0) Do 
        Begin
          Dec (ilen);
          Move ((fin+1)^, fin^, ilen);
        End;
      Dec (ilen);
      Move ((fin+1)^, fin^, ilen);
    End;
  If ((flg and $2 {FHCRC}) = $2) Then
    Begin
      Dec (ilen, 2);
      Move (PChar(fin)[2], fin^, ilen);
    End;

  Move (fin^, PChar(fin)[2], ilen);
  fin[0] := Char($78); fin[1] := Char($9C);
  Inc (ilen, 2);

  GetMem (fout, atmp+1);
  olen := atmp;
  uncompress (fout^, olen, fin^, ilen);
  GetMem (Ret.strptr, olen+1);
  Ret.StrLength := olen;
  Move (fout^, Ret.strptr^, olen+1);
  FreeMem(fout, atmp+1);
  FreeMem(fin, j);
  RxUngzString := 0;

End;

{RxGzCrc32 returns CRC-32 of a buffer with given lenght}

Function RxGzCrc32 (FuncName  : PChar;
                     ArgC      : ULong;
                     Args      : pRxString;
                     QueueName : pChar;
                     Var Ret   : RxString): ULong; export;
Var
  i, ilen, theCRC, err: ULong;
  fin: PChar;
  astr: String;
Begin
  If (ArgC = 0) Then
    Begin
      RxGzCrc32 := 40;  { At least one parameter required }
      Exit;
    End;
  For i := 1 To ArgC Do
    Begin
      Case i of
        1: Begin
             astr := StrPas (Args^.strptr);
             Val (astr, ilen, err);
             GetMem (fin, ilen);
           End;
        2: Move (Args^.strptr^, fin^, ilen);
      End;
      Inc (Args);
    End;
  theCRC := crc32 (LongInt(0), fin^, ilen);
  astr := Hex2Str (theCRC);
  Ret.StrLength := Length (astr);
  Ret.strptr := StrPCopy (Ret.strptr, astr);
  RxGzCrc32 := 0;
  FreeMem (fin, ilen);
End;

{RxGzAdler32 returns Adler-32 of a buffer with given lenght}

Function RxGzAdler32 (FuncName  : PChar;
                      ArgC      : ULong;
                      Args      : pRxString;
                      QueueName : pChar;
                      Var Ret   : RxString): ULong; export;
Var
  i, ilen, theCRC, err: ULong;
  fin: PChar;
  astr: String;
Begin
  If (ArgC = 0) Then
    Begin
      RxGzAdler32 := 40;  { At least one parameter required }
      Exit;
    End;
  For i := 1 To ArgC Do
    Begin
      Case i of
        1: Begin
             astr := StrPas (Args^.strptr);
             Val (astr, ilen, err);
             GetMem (fin, ilen);
           End;
        2: Move (Args^.strptr^, fin^, ilen);
      End;
      Inc (Args);
    End;
  theCRC := adler32 (LongInt(0), fin^, ilen);
  astr := Hex2Str (theCRC);
  Ret.StrLength := Length (astr);
  Ret.strptr := StrPCopy (Ret.strptr, astr);
  RxGzAdler32 := 0;
  FreeMem (fin, ilen);
End;

INITIALIZATION
END.
