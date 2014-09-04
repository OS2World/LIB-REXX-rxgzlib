/* Simple demo of RxGZlib Functions. Requires an hpfs drive (for multi-extension file names) */

/* Load the rxGZlib functions */
if rxfuncquery('rxgzLoadFuncs') then do
   foo=RxFuncAdd( 'rxgzLoadFuncs', 'RXGZLIB', 'rxgzLoadFuncs')
   if foo=0 then do
      call rxgzLoadFuncs
   end
   else do
      say "Sorry, rxGZlib.dll is not available"
      exit
   end /* do */
end /* if */

call charout,'Enter an input file: '
pull input_file
if input_file='' then do
  input_file="tstgzlib.cmd"
  say ' ... using 'input_file
end

say "--- Testing file deflation procedures  --- "
say "Size of  original file: "||stream(input_file,'c','query size')

rc=rxgzDeflateFile(Input_file, Input_file".gz")
newsize=stream(input_file".gz",'c','query size')
say 'rxgzDeflateFile to 'input_file'.gz. Code = 'rc ||'. File size='||newsize

rc=rxgzDeflateFile(Input_file, Input_file"_1.gz", "9")
newsize=stream(input_file"_1.gz",'c','query size')
say 'rxDeflateFile to 'input_file'_1.gz, option=9. Code = 'rc ||'. File size='||newsize

rc=rxgzDeflateFile(Input_file, Input_file"_2.gz", "2")
newsize=stream(input_file"_2.gz",'c','query size')
say 'rxDeflateFile to 'Input_file'_2.gz , option=2. Code = 'rc ||'. File size='||newsize

say
rc=rxgzInflateFile(Input_file".gz", Input_file"_1")
newsize=stream(input_file"_1",'c','query size')
say 'rxInflateFile  'Input_file'.gz to 'input_File'_1.'
say '      Code = 'rc ||'. File size='||newsize
say
say "--- Testing string deflation procedures  --- "


InStr="Mary had a little lamb, it's fleece was white as snow, everywhere that Mary went the lamb was sure to go"

CompStr=rxgzDeflateString(InStr)
say "rxgzDeflatestring. In: "length(instr)"  Out: "length(CompStr)
NewStr=rxgzInflateString(CompStr)
say "rxgzInflateStringIn. "length(Compstr)"  Out: "length(NewStr)
say Instr
say NewStr

/*
astring=charin(input_file,1,chars(input_file))
rc=stream(Input_file,'c','close')

deflated=rxgzDeflateString(astring)
inflated=rxgzInflateString(deflated)

output_file=Input_file'_5'
rc=charout(output_file,inflated,1)
rc=stream(output_file,'c','close')
*/

call rxgzUnloadFuncs

