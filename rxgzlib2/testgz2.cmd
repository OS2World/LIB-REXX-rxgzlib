/* Small REXX program to demonstrate using functions
   defined in the RXGZLIB DLL 
*/

call RxFuncAdd 'RxGzLoadFuncs', 'RXGZLIB', 'RxGzLoadFuncs'
call RxGzLoadFuncs

input_file = 'z.dll'
out_file = 'z2.gz'
test_file = 'z2.dll'

gsize = stream(input_file, 'c', 'query size')
rc = stream(input_file, 'c', 'open read')
thestr = charin(input_file, 1, gsize)
rc = stream(input_file, 'c', 'close')

/* Note that 3-rd parameter is added - method of compressing
   the only two values is allowed (the only first letter is important):

   ZLIB - use ZLIB format for compressed string;
   GZIP - use GZIP format (stored string can be unpacked by GZIP program)
*/

gzstr = RxGzString(gsize, thestr, 'zlib')

rc = stream(out_file, 'c', 'open write')
rc = charout(out_file, gzstr, 1)
rc = stream(out_file, 'c', 'close')

/* =========================== */

gsize = stream(out_file, 'c', 'query size')
rc = stream(out_file, 'c', 'open read')
gzstr = charin(out_file, 1, gsize)
rc = stream(out_file, 'c', 'close')

/* Note that 3-rd parameter is added - method of decompressing
   the only two values is allowed (the only first letter is important):

   ZLIB - the compressed string is in ZLIB format;
   GZIP - the compressed string is in GZIP format (loaded from file packed by
          GZIP program)
*/
thestr = RxUngzString(gsize, gzstr, 'zlib')

/* Two supplemental functions */

say "CRC-32 of ungzipped string is" RxGzCrc32(Length(thestr), thestr)
say "ADLER-32 of ungzipped string is" RxGzAdler32(Length(thestr), thestr)

rc = stream(test_file, 'c', 'open write')
rc = charout(test_file, thestr, 1)
rc = stream(test_file, 'c', 'close')

Say "Now compare "input_file" and "test_file


call RxGzUnloadFuncs


Exit
