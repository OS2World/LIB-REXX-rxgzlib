/* Small REXX program to demonstrate functions
   defined in the "alternate" version of RXGZLIB DLL 

  Note that this "alternate" version requires the Z.DLL
  os/2 (C) library.

*/

call RxFuncAdd 'RxGzLoadFuncs', 'RXGZLIB', 'RxGzLoadFuncs'
call RxGzLoadFuncs

input_file = 'z.dll'
out_file = 'z2.gz'
out_file2 = 'z2b.gz'

test_file = 'z2.dll'
test_file2 = 'z2b.dll'

gsize = stream(input_file, 'c', 'query size')
rc = stream(input_file, 'c', 'open read')
thestr = charin(input_file, 1, gsize)
rc = stream(input_file, 'c', 'close')

say "1) Reading "input_file" into memory, and then gzipping "
gzstr = RxGzString(gsize, thestr)

rc = stream(out_file, 'c', 'open write')
rc = charout(out_file, gzstr, 1)
rc = stream(out_file, 'c', 'close')

say "1a) gzipped string saved to " out_file


rc=rxgzfile(input_file,out_file2)
say "2) gzfile of "input_file " to " out_file2

/* =========================== */

gsize = stream(out_file, 'c', 'query size')
rc = stream(out_file, 'c', 'open read')
gzstr = charin(out_file, 1, gsize)
rc = stream(out_file, 'c', 'close')

say "3) Reading gz file "out_file" to a string, and ungzing the string"
thestr = RxUngzString(gsize, gzstr)

rc = stream(test_file, 'c', 'open write')
rc = charout(test_file, thestr, 1)
rc = stream(test_file, 'c', 'close')
say "3a) wrote ungz'ed string to " test_file

say "4) ungzfile of "out_file2" to "test_file2
rc=rxungzfile(out_file2,test_file2)
say
Say "Now compare "input_file" and "test_file
say "and also compare "input_file" and "test_file2

call RxGzUnloadFuncs


Exit
