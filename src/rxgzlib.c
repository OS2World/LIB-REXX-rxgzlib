/*
#define  DEBUG
*/

#define  INCL_VIO
#define  INCL_DOS
#define  INCL_ERRORS
#define  INCL_REXXSAA
#define  _DLL

#include <os2.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <ctype.h>
#include <io.h>
#include <fcntl.h>
#include "zlib.h"

#ifndef GZ_SUFFIX
#  define GZ_SUFFIX ".gz"
#endif
#define SUFFIX_LEN (sizeof(GZ_SUFFIX)-1)

#define BUFLEN      32768
#define MAX_NAME_LEN 1024

static int gz_magic[2] = {0x1f, 0x8b}; /* gzip magic header */

/* gzip flag byte */
#define ASCII_FLAG   0x01 /* bit 0 set: file probably ascii text */
#define HEAD_CRC     0x02 /* bit 1 set: header CRC present */
#define EXTRA_FIELD  0x04 /* bit 2 set: extra field present */
#define ORIG_NAME    0x08 /* bit 3 set: original file name present */
#define ZCOMMENT     0x10 /* bit 4 set: file comment present */
#define RESERVED     0xE0 /* bits 5..7: reserved */

#define BUILDRXSTRING(t, s) { \
  strcpy((t)->strptr,(s));\
  (t)->strlength = strlen((s)); \
  }

#define BUILDRXULONG(t, s) { \
  sprintf((t)->strptr, "%u", (s));\
  (t)->strlength = strlen((t)->strptr); \
  }

#define BUILDRXLONG(t, s) { \
  sprintf((t)->strptr, "%d", (s));\
  (t)->strlength = strlen((t)->strptr); \
  }

#define OK_CALL         0
#define BAD_CALL        40
#define MAX_DIGITS      10

void  sputLong      OF((Bytef *dest, uLong x));
int   uncompress2   OF((Bytef *dest, uLongf *destLen, const Bytef *source, uLong sourceLen));


static PSZ RxFuncTable[] =
  {
  "rxgzUnloadFuncs",      "rxgzUnloadFuncs",
  "rxgzLoadFuncs",        "rxgzLoadFuncs",
  "rxgzDeflateFile",      "rxgzDeflateFile",
  "rxgzInflateFile",      "rxgzInflateFile",
  "rxgzDeflateString",    "rxgzDeflateString",
  "rxgzInflateString",    "rxgzInflateString"
  };

/* --- RXGZLOADFUNCS --- */

ULONG rxgzLoadFuncs(
  PSZ           _Name,                  /* name of the function         */
  ULONG         _Argc,                  /* number of args               */
  RXSTRING      _Argv[],                /* list of argument strings     */
  PSZ           _Queuename,             /* current queue name           */
  PRXSTRING     _Retstr)                /* returned result string       */
{

int     entries;
int     index;

  _Retstr->strlength = 0;

  if (_Argc > 0)                        /* Bad call to function         */
    return(BAD_CALL);                   /* Let REXX bomb                */

  entries = sizeof(RxFuncTable) / sizeof(PSZ);

  for (index = 0; index < entries; index+=2)
    RexxRegisterFunctionDll(RxFuncTable[index],
                            "RXGZLIB",
                            RxFuncTable[index+1]);

return(OK_CALL);
}

/* ---- RXGZUNLOADFUNCS ---- */

ULONG rxgzUnloadFuncs(
  PSZ           _Name,                  /* name of the function         */
  ULONG         _Argc,                  /* number of args               */
  RXSTRING      _Argv[],                /* list of argument strings     */
  PSZ           _Queuename,             /* current queue name           */
  PRXSTRING     _Retstr)                /* returned result string       */
{

int     entries;
int     index;

  _Retstr->strlength = 0;

  if (_Argc > 0)
    return(BAD_CALL);

  entries = sizeof(RxFuncTable) / sizeof(PSZ);

  for (index = 0; index < entries; index+=2)
    RexxDeregisterFunction(RxFuncTable[index]);

return(OK_CALL);
}

ULONG rxgzDeflateFile(
  PSZ           _Name,                  /* name of the function         */
  ULONG         _Argc,                  /* number of args               */
  RXSTRING      _Argv[],                /* list of argument strings     */
  PSZ           _Queuename,             /* current queue name           */
  PRXSTRING     _Retstr)                /* returned result string       */
{

  char outmode[10];
  FILE  *in;
  gzFile out;
  char buf[BUFLEN];
  int len;

  _Retstr->strlength = 0;
  strcpy(outmode, "wb6 ");

  if (_Argc > 3)                        /* Bad call to function         */
    return(BAD_CALL);                   /* Let REXX bomb                */

  if (_Argc > 2 && !isdigit(_Argv[2].strptr[0]))
    return BAD_CALL;                    /* raise an error             */

  if (_Argc > 2) {
     if (_Argv[2].strptr[0] >= '0' &&  _Argv[2].strptr[0] <= '9')
        outmode[2] = _Argv[2].strptr[0];
     else
        return(BAD_CALL);                   /* Let REXX bomb                */
  }

  in = fopen(_Argv[0].strptr, "rb");
  if (in == NULL) {
      BUILDRXULONG(_Retstr, 1)     /* Return ErrorCode */
      return(OK_CALL);             /* Return  */
  }
  out = gzopen(_Argv[1].strptr, outmode);
  if (out == NULL) {
      BUILDRXULONG(_Retstr, 2)     /* Return ErrorCode */
      return(OK_CALL);             /* Return  */
  }

  for (;;) {
      len = fread(buf, 1, sizeof(buf), in);
      if (ferror(in)) {
           BUILDRXULONG(_Retstr, 1)     /* Return ErrorCode */
           return(OK_CALL);             /* Return  */
      }
      if (len == 0) break;

      if (gzwrite(out, buf, (unsigned)len) != len) {
           BUILDRXULONG(_Retstr, 2)     /* Return ErrorCode */
           return(OK_CALL);             /* Return  */
       }
  }
  fclose(in);
  if (gzclose(out) != Z_OK) {
      BUILDRXULONG(_Retstr, 4)     /* Return ErrorCode */
      return(OK_CALL);             /* Return  */
  }

  BUILDRXULONG(_Retstr, 0)     /* Return ErrorCode */
  return(OK_CALL);
}

ULONG rxgzInflateFile(
  PSZ           _Name,                  /* name of the function         */
  ULONG         _Argc,                  /* number of args               */
  RXSTRING      _Argv[],                /* list of argument strings     */
  PSZ           _Queuename,             /* current queue name           */
  PRXSTRING     _Retstr)                /* returned result string       */
{

  FILE  *out;
  gzFile in;
  char buf[BUFLEN];
  int len;

  _Retstr->strlength = 0;

  if (_Argc != 2)                       /* Bad call to function         */
    return(BAD_CALL);                   /* Let REXX bomb                */


  in = gzopen(_Argv[0].strptr, "rb");
  if (in == NULL) {
      BUILDRXULONG(_Retstr, 1);     /* Return ErrorCode */
      return(OK_CALL);             /* Return  */
  }

  out = fopen(_Argv[1].strptr, "wb");
  if (out == NULL) {
      BUILDRXULONG(_Retstr, 2);     /* Return ErrorCode */
      return(OK_CALL);             /* Return  */
  }

  for (;;) {
      len = gzread(in, buf, sizeof(buf));
      if (len < 0) {
        BUILDRXULONG(_Retstr, 1);     /* Return ErrorCode */
        return(OK_CALL);             /* Return  */
      }
      if (len == 0) break;

      if ((int)fwrite(buf, 1, (unsigned)len, out) != len) {
          BUILDRXULONG(_Retstr, 2);     /* Return ErrorCode */
          return(OK_CALL);             /* Return  */
      }
  }
  if (fclose(out)) {
      BUILDRXULONG(_Retstr, 2)     /* Return ErrorCode */
      return(OK_CALL);             /* Return  */
  }

  if (gzclose(in) != Z_OK) {
      BUILDRXULONG(_Retstr, 1);     /* Return ErrorCode */
      return(OK_CALL);             /* Return  */
  }

  BUILDRXULONG(_Retstr, 0);
  return(OK_CALL);
}

ULONG rxgzDeflateString(
  PSZ           _Name,                  /* name of the function         */
  ULONG         _Argc,                  /* number of args               */
  RXSTRING      _Argv[],                /* list of argument strings     */
  PSZ           _Queuename,             /* current queue name           */
  PRXSTRING     _Retstr)                /* returned result string       */
{
  Byte *gzstrptr;
  Byte *compr;
  Byte *temp_ptr;
  int   level;
  int   err;
  uLong len;
  uLong comprLen;
  z_stream stream;
  uLong  crc = crc32(0L, Z_NULL, 0);


  _Retstr->strlength = 0;

  level=6;

  if (_Argc < 1 || _Argc > 2)                        /* Bad call to function         */
    return(BAD_CALL);                   /* Let REXX bomb                */

  if (_Argc > 1 && !isdigit(_Argv[1].strptr[0]))
    return BAD_CALL;                    /* raise an error             */

  if (_Argc > 1) {
     if (_Argv[1].strptr[0] >= '0' &&  _Argv[1].strptr[0] <= '9')
        level = atoi(_Argv[1].strptr);
     else
        return(BAD_CALL);                   /* Let REXX bomb                */
  }

  len=_Argv[0].strlength;
  comprLen=len+(0.001*len)+15;
  gzstrptr=(Byte*)calloc((uInt)comprLen, 1);
  compr=gzstrptr+10L;



  stream.next_in = (Bytef*)_Argv[0].strptr;
  stream.avail_in = (uInt)len;
  stream.next_out = compr;
  stream.avail_out = (uInt)comprLen;
  stream.zalloc = (alloc_func)0;
  stream.zfree = (free_func)0;
  stream.opaque = (voidpf)0;

  /* windowBits is passed < 0 to suppress zlib header */
  err = deflateInit2(&stream, level, Z_DEFLATED, -MAX_WBITS, 8, Z_DEFAULT_STRATEGY);

  if (err != Z_OK){
      _Retstr->strlength = 0;
      return(OK_CALL);             /* Return  */
   }

  sprintf(gzstrptr, "%c%c%c%c%c%c%c%c%c%c", gz_magic[0], gz_magic[1],
          Z_DEFLATED, 0 /*flags*/, 0,0,0,0 /*time*/, 0 /*xflags*/, 0x03);

  err = deflate(&stream, Z_FINISH);

  if (err != Z_STREAM_END) {
        err = deflateEnd(&stream);
        _Retstr->strlength = 0;
        return(OK_CALL);             /* Return  */
   }

  comprLen = stream.total_out;

  crc = crc32(crc, (const Bytef *)_Argv[0].strptr, len);
  temp_ptr=gzstrptr+10+comprLen;

  sputLong (temp_ptr, crc);
  temp_ptr=temp_ptr+4;
  sputLong (temp_ptr, stream.total_in);

  err = deflateEnd(&stream);

  _Retstr->strlength = comprLen+18;
  _Retstr->strptr=gzstrptr;


  return(OK_CALL);
}

ULONG rxgzInflateString(
  PSZ           _Name,                  /* name of the function         */
  ULONG         _Argc,                  /* number of args               */
  RXSTRING      _Argv[],                /* list of argument strings     */
  PSZ           _Queuename,             /* current queue name           */
  PRXSTRING     _Retstr)                /* returned result string       */
{

  Byte *uncompr;
  Byte *temp_ptr;
  Bytef *start;
  int err;
  int i;
  uLong inputlen;
  uLong maxlen;
  uLong DataLen;
  uLong uncomprLen;
  int method; /* method byte */
  int flags;  /* flags byte */
  uInt len;
  int c;

  _Retstr->strlength = 0;

  if (_Argc != 1 )                        /* Bad call to function         */
    return(BAD_CALL);                   /* Let REXX bomb                */

  temp_ptr=_Argv[0].strptr;

  /* Check the gzip magic header */
  for (len = 0; len < 2; len++) {
        c = *temp_ptr;
        temp_ptr++;
        if (c != gz_magic[len]) {
              _Retstr->strlength = 0;      /* Return empty value */
              return(OK_CALL);             /* Return  */
         }
   }
   method = *temp_ptr; temp_ptr++;
   flags = *temp_ptr; temp_ptr++;

   if (method != Z_DEFLATED || (flags & RESERVED) != 0) {
        _Retstr->strlength = 0;
        return(OK_CALL);             /* Return  */
   }

   /* Discard time, xflags and OS code: */
   temp_ptr=temp_ptr+6;

   if ((flags & EXTRA_FIELD) != 0) { /* skip the extra field */
        len  =  (uInt)*temp_ptr; temp_ptr++;
        len += (uInt)(*temp_ptr<<8); temp_ptr++;
        /* len is garbage if EOF but the loop below will quit anyway */
        while (len-- != 0 && temp_ptr != _Argv[0].strptr+_Argv[0].strlength) temp_ptr++;
    }
    if ((flags & ORIG_NAME) != 0) { /* skip the original file name */
        while ((c = *temp_ptr) != 0 && temp_ptr != _Argv[0].strptr+_Argv[0].strlength) temp_ptr++;
        temp_ptr++;
    }
    if ((flags & ZCOMMENT) != 0) {   /* skip the .gz file comment */
        while ((c = *temp_ptr) != 0 && temp_ptr != _Argv[0].strptr+_Argv[0].strlength) temp_ptr++;
        temp_ptr++;
    }
    if ((flags & HEAD_CRC) != 0) {  /* skip the header crc */
        for (len = 0; len < 2; len++) temp_ptr++;
    }

  start=temp_ptr;

  inputlen=_Argv[0].strlength;
  DataLen=inputlen-8-(start-_Argv[0].strptr);
  uncomprLen=3*inputlen;
  maxlen=20*inputlen;
  uncompr=(Byte*)calloc((uInt)uncomprLen, 1);

#ifdef DEBUG
  printf("1: Inputlen: %ld  DataLen: %ld  uncomprLen: %ld err: %ld \n",inputlen, DataLen, uncomprLen, err);
#endif

  if (uncompr == NULL) {
     _Retstr->strlength = 0;
     return(OK_CALL);              /* Return  */
  }

  err = uncompress2(uncompr, &uncomprLen, start, DataLen);

#ifdef DEBUG
  printf("2: Inputlen: %ld  DataLen: %ld  uncomprLen: %ld err: %ld \n",inputlen, DataLen, uncomprLen, err);
#endif

  i=1;
  while (err == Z_BUF_ERROR && uncomprLen<=maxlen) {
      i=i+1;
      uncomprLen=3*inputlen*i;
      uncompr=(Byte*)realloc(uncompr, (uInt)uncomprLen);
      if (uncompr == NULL) {
          _Retstr->strlength = 0;
          return(OK_CALL);              /* Return  */
      }

      err = uncompress2(uncompr, &uncomprLen, start, DataLen);
#ifdef DEBUG
  printf("3: Inputlen: %ld  DataLen: %ld  uncomprLen: %ld err: %ld \n",inputlen, DataLen, uncomprLen, err);
#endif

  }
  uncompr=(Byte*)realloc(uncompr, (uInt)uncomprLen);
  if (uncompr == NULL) {
     _Retstr->strlength = 0;
     return(OK_CALL);              /* Return  */
  }

  _Retstr->strlength = uncomprLen;
  _Retstr->strptr = uncompr;

  return(OK_CALL);
}

void sputLong (dest, x)
    Bytef *dest;
    uLong x;
{
    int n;
    for (n = 0; n < 4; n++) {
        sprintf(dest,"%c",(int)(x & 0xff));
        x >>= 8;
        dest++;
    }
}

int uncompress2 (dest, destLen, source, sourceLen)
    Bytef *dest;
    uLongf *destLen;
    const Bytef *source;
    uLong sourceLen;
{
    z_stream stream;
    int err;

    stream.next_in = (Bytef*)source;
    stream.avail_in = (uInt)sourceLen;
    stream.next_out = dest;
    stream.avail_out = (uInt)*destLen;

    stream.zalloc = (alloc_func)0;
    stream.zfree = (free_func)0;

    err = inflateInit2(&stream, -MAX_WBITS);
    if (err != Z_OK) return err;

#ifdef DEBUG
  printf("4: avail_out: %ld  total_out: %ld  err: %ld \n",stream.avail_out, stream.total_out, err);
#endif

    err = inflate(&stream, Z_FINISH);

#ifdef DEBUG
  printf("5: avail_out: %ld  total_out: %ld  err: %ld \n",stream.avail_out, stream.total_out, err);
#endif

    if (stream.avail_out == 0){
       inflateEnd(&stream);
       return Z_BUF_ERROR;
    }

    *destLen = stream.total_out;

    err = inflateEnd(&stream);
    return err;
}
