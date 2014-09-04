/* Simple demo of rxgzlib Functions. Requires an hpfs drive (for multi-extension file names) */

/* Load the rxgzlib functions */
if rxfuncquery('rxgzLoadFuncs') then do
   foo=RxFuncAdd( 'rxgzLoadFuncs', 'rxgzLIB', 'rxgzLoadFuncs')
   if foo=0 then do
      call rxgzLoadFuncs
   end
   else do
      say "Sorry, rxgzlib.dll is not available"
      exit
   end /* do */
end /* if */

parse source . . thisfile

say "This program will test the compatability of rxgzInflateString (and "
say " rxgzDeflateString) with GZIP.EXE -- the goal is interoperability, and "
say " not bytewise exactness"

say " 1) choose your test file (this file is used by default)."
say " 2) use GZIP.EXE to deflate this, saving the result to EXE_VER.GZ"
say "   [For example, use GZIP -c input_file > EXE_VER.GZ] "
say " 3) run this program, and see what it reports."
say "    Note that this program creates def_string.GZ and def_file.GZ "
say "   (the result of rxgzDeflateString and rxgzDeflateFile, respectively)"
say " or "
say " 4) Run GZIP.EXE against EXE_VER.GZ and PROC_VER.GZ, and compare these"
say '    against your input_file'
say
call charout,'Enter an input file: '
pull input_file
if input_file='' then do
    input_file=thisfile
    say ' ... using 'input_file
end
say 

foo=stream(input_file,'c','query size')
orig_string=charin(input_file,1,foo)
foo=stream(input_File,'c','close')

orig_gz=rxgzdeflatestring(orig_string)

out1='def_String.gz'
foo=charout(out1,orig_gz,1)
foo=stream(out1,'c','close')

say out1 " is the rxgzdeflatestring of " input_file
say " enter to continue "
pull goo

out2='def_file.gz'
out2a='undef_file.out'
stat=rxgzdeflatefile(input_file,out2)
say "Status from rxgzdeflatefile: "stat
stat=rxgzinflatefile(out2,out2a)
say "Status from rxgzinflatefile: "stat

say out2 " is rxgzdeflatefile of " input_file
say " enter to continue "
pull goo

/* read and decompress the rxgzdeflatestring version */

sz=stream(out1,'c','query size')
proc_ver=charin(out1,1,sz)
foo=stream(out1,'c','close')

say " length of proc_ver (gz'ed) string= "length(proc_ver)
proc_ver_deflated=rxgzinflatestring(proc_ver)
say " proc_Ver_deflated string is "length(proc_ver_deflated)
say " enter to continue "
pull goo

/* read and decompress the "gzip.exe" version */

gzexe_file='exe_ver.gz'
sz=stream(gzexe_file,'c','query size')
if sz=0 | sz='' then do
   say gzexe_file " does not exist "
end /* do */
else do
  exe_ver=charin(gzexe_file,1,sz)
  foo=stream(gzexe_file,'c','close')
  say " Reading GZIP.EXE'd version of input_file = "gzexe_file
  say " length of exe_ver (gz'ed) string= "length(exe_ver)
  exe_ver_deflated=rxgzinflatestring(exe_ver)
  say " exe_Ver_deflated string is "length(exe_ver_deflated)
  say " enter to continue "
  pull goo

/* compare the two */

  if exe_ver_deflated=proc_ver_deflated then
     say "SUCCESS. exe_ver and proc_ver are the same "
  else
     say "ERROR!! exe_ver and proc_Ver are different "
end

say " more tests ... "

test='this is a test'
say "  Trying to inflate 'this is a test' "
xx=rxgzinflatestring(test)
say "       yields: " xx

oo=rxgzinflatefile(thisfile,thisfile'.tmp')
say " Trying to inflate non-gzip file, status=" oo

