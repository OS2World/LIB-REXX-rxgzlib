/* Load the rxgZlib functions */
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

input_file=''
output_file=''

parse arg input_file output_file .

if input_file='' | output_file='' then do
   say "UnGZIP a file, using rxGZlib procedures."
   say 'Syntax: rxgunzip <input_file.gz> <output_file>'
   exit (1)
end /* if */

rc = stream(input_file, 'c', 'open read')
agzstr = charin(input_file, 1, chars(input_file))
rc = stream(input_file, 'c', 'close')

thestr2 = rxgzInflateString(agzstr)

rc = stream(output_file, 'c', 'open write')
rc = charout(output_file, thestr2, 1)
rc = stream(output_file, 'c', 'close')


