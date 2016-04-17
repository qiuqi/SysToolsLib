@echo off
:##############################################################################
:#                                                                            #
:#  Filename        library.cmd                                               #
:#                                                                            #
:#  Description     A library of useful batch routines for Windows NT cmd.exe #
:#                                                                            #
:#  Notes 	    Used this file as a template for new batch files:         #
:#                  Copy this whole file into the new batch file.             #
:#                  Remove all unused code (possibly everything) from the end #
:#                  of the debugging library to the header of the main routine#
:#                  (Always keep the whole debugging library at the beginning,#
:#                  even if you have no immediate need for it. The first time #
:#		    you'll have a bug, it'll be priceless!)                   # 
:#                  Update the header and the main routine.                   #
:#                                                                            #
:#                  Microsoft reference page on batch files:		      #
:#		    http://www.microsoft.com/resources/documentation/windows/xp/all/proddocs/en-us/batch.mspx
:#                  Excellent sources of tips and examples:                   #
:#		    http://www.dostips.com/				      #
:#                  http://www.robvanderwoude.com/batchfiles.php              #
:#                                                                            #
:#                  Reserved characters that affect batch files:              #
:#                  Command sequencing (escaped by ^ and ""): & | ( ) < > ^   #
:#                  Echo control (escaped by enclosing command in ""): @      #
:#                  Argument delim. (escaped by enclosing in ""): , ; space   #
:#		    Environment variables (escaped by %): %		      #
:#		    Delayed variables (escaped by ^): !			      #
:#                  Wildcards: * ?                                            #
:#                  Some internal commands also use: [ ] { } = ' + ` ~        #
:#                                                                            #
:#                  Filenames cannot contain characters: \ / : * ? " < > |    #
:#                  But they can contain: & ( ) ^ @ , ; % ! [ ] { } = ' + ` ~ #
:#                  Conclusion: Always put "quotes" around file names.        #
:#                  Warning: Even "quotes" do not resolve issues with: ^ % !  #
:#                  Files containing these 3 characters will not be processed #
:#                  correctly, except in a for loop with delayed expansion off.
:#                                                                            #
:#                  When cmd parses a line, it does the following steps:      #
:#                  1) Replace %N arguments.                                  #
:#                  2) Replace %VARIABLES%.                                   #
:#		    3) Tokenization. Remove command sequencing tokens,        #
:#			using "" and ^ as escape characters. (See above)      #
:#		    4) Replace for %%V variables                              #
:#		    5) Replace !VARIABLES!.                                   #
:#			If any ! is present in the command, remove another    #
:#			set of ^ escape characters.                           #
:#		    6) If tokenization finds a pipe, and if one of the        #
:#			commands is an internal command (ex: echo), a         #
:#			subshell is executed and passed the processed tokens. #
:#			This subshell repeats steps 1 to 4 or 5 while parsing #
:#			its own arguments. (Depending on /V:OFF or /V:ON)     #
:#			Note: Most internals command, like cd or set, have no #
:#			effect in this case on the original shell.            #
:#                                                                            #
:#                  Steps 4 & 5 are not done for the call command.            #
:#                  Step 3 is done, but the redirections are ignored.         #
:#                                                                            #
:#                  The following four instructions are equivalent:           #
:#                  echo !%VAR_NAME%!                                         #
:#                  call echo %%%VAR_NAME%%%                                  #
:#                  echo %%%VAR_NAME%%% | more                                #
:#                  cmd /c echo %%%VAR_NAME%%%                                #
:#                                                                            #
:#                  During the tokenization step, the analyser switches       #
:#                  between a normal mode and a string mode after every ".    #
:#                  In normal mode, the command sequencing characters (see    #
:#                  above) may be escaped using the ^ character.              #
:#                  In string mode, they are stored in the string token       #
:#                  without escaping. The ^ itself is stored without escaping.#
:#                  The " character itself can be escaped, to avoid switching #
:#                  mode. Ex:                                                 #
:#                  echo "^^"   outputs "^^"  ;  set "A=^^"   stores ^^ in A  #
:#                  echo ^"^^"  outputs "^"   ;  set ^"A=^^"  stores ^  in A  #
:#                                                                            #
:#                  Good practice:                                            #
:#                  * Use :# for comments instead of rem.                     #
:#                    + This avoids echoing the comment in echo on mode.      #
:#                    + This stands out better than the :: used by many.      #
:#                    + Gotcha: A :# comment cannot be at the last line of    #
:#                       a ( block of code ). Use (rem :# comment) instead.   #
:#                  * Always enquote args sent, and dequote args received.    #
:#                    + Best strategy for preserving reserved chars across.   #
:#                  * Always enclose the set command in quotes: set "VAR=val" #
:#                    + Best strategy for preserving reserved chars in val.   #
:#                  * Always use echo.%STRING% instead of echo %STRING%       #
:#                    + This will work even for empty strings.                #
:#                  * Do not worry about strings with unbalanced quotes.      #
:#                    + File names cannot contain quotes.                     #
:#                    + This is not a general purpose language anyway.        #
:#                  * Do worry about arguments with unbalanced quotes.        #
:#                    + The last argument can contain unbalanced quotes.      #
:#                  * Always surround routines by init call and protection    #
:#                    jump. This allows using it by just cutting and pasting  #
:#                    it. Example:                                            #
:#                      call :MyFunc.Init                                     #
:#                      goto :MyFunc.End                                      #
:#                      :MyFunc.Init                                          #
:#                      ...                                                   #
:#                      goto :eof                                             #
:#                      :MyFunc                                               #
:#                      ...                                                   #
:#                      goto :eof                                             #
:#                      :MyFunc.End                                           #
:#                                                                            #
:#                  Gotcha:                                                   #
:#                  * It's not possible a call a subroutine from inside a ()  #
:#                    block. This is because the block is executed in a sub-  #
:#                    shell.                                                  #
:#                                                                            #
:#  License	    Copyright (c) 2002-2015, Jean-Fran�ois Larvoire	      #
:#		                                                              #
:#		    Permission is hereby granted, free of charge, to any      #
:#		    person obtaining a copy of this software and associated   #
:#		    documentation files (the "Software"), to deal in the      #
:#		    Software without restriction, including without limitation#
:#		    the rights to use, copy, modify, merge, publish,          #
:#		    distribute, sublicense, and/or sell copies of the         #
:#		    Software, and to permit persons to whom the Software is   #
:#		    furnished to do so, subject to the following conditions:  #
:#		                                                              #
:#		    The above copyright notice and this permission notice     #
:#		    shall be included in all copies or substantial portions   #
:#		    of the Software. 				              #
:#		                                                              #
:#		    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY #
:#		    KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO    #
:#		    THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A          #
:#		    PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL #
:#		    THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, #
:#		    DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF       #
:#		    CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN   #
:#		    CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS #
:#		    IN THE SOFTWARE.				              #
:# 	                                                                      #
:#  Author          Jean-Fran�ois Larvoire, jf.larvoire@free.fr               #
:#                                                                            #
:#  History                                                                   #
:#   2012-07-10 JFL Updated the debugging framework.                          #
:#                  Added routine get_IP_address.                             #
:#                  Added a factorial routine, to test the tracing framework  #
:#   2012-07-11 JFL Added options -c and -C to respectively test the command  #
:#                  tail as one, or as N separate, commands.                  #
:#   2012-07-19 JFL Added debug optimizations.				      #
:#   2012-10-02 JFL Added options -a and -b.                                  #
:#                  Added the Echo.Color functions.                           #
:#   2013-12-05 JFL Improved the :Exec routine.                               #
:#                  Added :Firewall.GetRules                                  #
:#   2014-05-13 JFL Added EnableExpansion and EnableExpansion.Test routines.  #
:#                  Fixed the self-test mode.				      #
:#   2014-09-30 JFL Added macro system from dostips.com forum topics 5374,5411.
:#                  Added tee routine from dostips.com forum topic #32615.    #
:#   2014-11-19 JFL Added routine PopArg, and use it in the main routine.     #
:#   2015-03-02 JFL Added routine GetServerAddress.			      #
:#   2015-03-18 JFL Rewrote PopArg, which did not process quotes properly.    #
:#   2015-04-16 JFL Added my own version of macro management macros, working  #
:#                  with DelayedExpansion enabled.                            #
:#   2015-10-18 JFL Bug fix: Function :now output date was incorrect if loop  #
:#                  variables %%a, %%b, or %%c existed already.               #
:#                  Renamed macros SET_ERR_0,SET_ERR_1 as TRUE.EXE,FALSE.EXE. #
:#   2015-10-29 JFL Added macro %RETURN#% to return with a comment.           #
:#   2015-11-19 JFL %FUNCTION% now automatically generates its name & %* args.#
:#                  Removed args for all %FUNCTION% invokations.              #
:#                  Added an %UPVAR% macro allowing to define the list of     #
:#                  variables that need to make it back to the caller.        #
:#                  Updated all functions that return such variables.         #
:#   2015-11-23 JFL Added routines :extensions.* to detect the extension      #
:#                  and expansion modes, and option -qe to display it.        #
:#   2015-11-25 JFL Changed the default for %LOGFILE% from NUL to undefined.  #
:#                  Rewrote the %FUNCTION% and %RETURN% macros to manage      #
:#                  most common cases without calling a subroutine.           #
:#   2015-11-27 JFL Added a macro debugging capability.                       #
:#                  Redesigned the problematic character return mechanism     #
:#                  using a table of predefined generic entities. Includes    #
:#                  support for returning strings with CR & LF. Also use this #
:#                  to expand input entities in -a, -b, and -c commands.      #
:#   2015-11-29 JFL Made the RETURN macro better and simpler.                 #
:#                  Added a backspace entity.                                 #
:#   2015-12-01 JFL Rewrote :extensions.get and :extensions.show.             #
:#                  Fixed a bug in the %FUNCTION% macro.                      #
:#                                                                            #
:##############################################################################

:# Check Windows version: minimum requirement Windows
:# 2000, but useful only for Windows XP SP2 and later
if not "%OS%"=="Windows_NT"     goto Err9X
ver | find "Windows NT" >NUL && goto ErrNT

setlocal EnableExtensions EnableDelayedExpansion
set "VERSION=2015-12-01"
set "SCRIPT=%~nx0"
set "SPATH=%~dp0" & set "SPATH=!SPATH:~0,-1!"
set "ARG0=%~f0"
set "ARGS=%*"

:# FOREACHLINE macro. (Change the delimiter to none to catch the whole lines.)
set FOREACHLINE=for /f "delims="

:# Initialize ERRORLEVEL with known values
set "TRUE.EXE=(call,)"	&:# Macro to silently set ERRORLEVEL to 0
set "FALSE.EXE=(call)"	&:# Macro to silently set ERRORLEVEL to 1

set "POPARG=call :PopArg"
call :Macro.Init
call :Debug.Init
call :Exec.Init
goto Main

:Err9X
echo Error: Does not work on Windows 9x
goto eof

:ErrNT
>&2 echo Error: Works only on Windows 2000 and later
goto :eof

:#----------------------------------------------------------------------------#
:#                                                                            #
:#  Function        PopArg                                                    #
:#                                                                            #
:#  Description     Pop the first arguments from %ARGS% into %ARG%            #
:#                                                                            #
:#  Arguments       %ARGS%	    Command line arguments                    #
:#                                                                            #
:#  Returns         %ARG%           The unquoted argument                     #
:#                  %"ARG"%         The actual argument, possibly quoted      #
:#                                                                            #
:#  Notes 	    Works around the defect of the shift command, which       #
:#                  pops the first argument from the %* list, but does not    #
:#                  remove it from %*.                                        #
:#                                                                            #
:#                  Use an inner call to make sure the argument parsing is    #
:#                  done by the actual cmd.exe parser. This guaranties that   #
:#                  arguments are split exactly as shift would have done.     #
:#                                                                            #
:#                  But call itself has a quirk, which requires a convoluted  #
:#                  workaround to process the /? argument.                    #
:#                                                                            #
:#                  To do: Detect if the last arg has mismatched quotes, and  #
:#                  if it does, append one.                                   #
:#                  Right now such mismatched quotes will cause an error here.#
:#                  It is easily feasible to work around this, but this is    #
:#                  useless as passing back an invalid argument like this     #
:#                  will only cause more errors further down.                 #
:#                                                                            #
:#  History                                                                   #
:#   2015-04-03 JFL Bug fix: Quoted args with an & inside failed to be poped. #
:#   2015-07-06 JFL Bug fix: Call quirk prevented inner call from popping /?. #
:#                                                                            #
:#----------------------------------------------------------------------------#

:PopArg
:# Gotcha: The call parser first scans its command line for an unquoted /?.
:# If it finds one anywhere on the command line, then it ignores the target label and displays call help.
:# To work around that, we initialize %ARG% and %"ARG"% with an impossible combination of values.
set "ARG=Yes"
set ""ARG"=No"
call :PopArg.Helper %ARGS% >NUL 2>NUL &:# Output redirections ensure the call help is not actually output.
:# Finding that impossible combination now is proof that the call was not executed.
:# In this case, try again with the /? quoted, to prevent the call parser from processing it.
:# Note that we can not systematically do this /? enquoting, else it's "/?" that would break the call.
if "%ARG%"=="Yes" if [%"ARG"%]==[No] call :PopArg.Helper %ARGS:/?="/?"% 
goto :eof
:PopArg.Helper
set "ARG=%~1"	&:# Remove quotes from the argument
set ""ARG"=%1"	&:# The same with quotes, if any, should we need them
:# Rebuild the tail of the argument line, as shift does not do it
:# Never quote the set ARGS command, else some complex quoted strings break
set ARGS=%2
:PopArg.GetNext
shift
if [%2]==[] goto :eof
:# Leave quotes in the tail of the argument line
set ARGS=%ARGS% %2
goto :PopArg.GetNext

:#----------------------------------------------------------------------------#
:#                                                                            #
:#  Function        Inline macro functions                                    #
:#                                                                            #
:#  Description     Tools for defining inline functions,                      #
:#                  also known as macros by analogy with Unix shells macros   #
:#                                                                            #
:#  Macros          %MACRO%         Define the prolog code of a macro         #
:#                  %/MACRO%        Define the epilog code of a macro         #
:#                                                                            #
:#  Variables       %LF%            A Line Feed ASCII character '\x0A'        #
:#                  %LF2%           Generates a LF when expanded twice        #
:#                  %LF3%           Generates a LF when expanded 3 times      #
:#                                  Etc...                                    #
:#                  %\n%            Macro command line separator              #
:#                                                                            #
:#  Notes           The principle is to define a variable containing the      #
:#                  complete body of a function, like this:                   #
:#                  set $macro=for %%$ in (1 2) do if %%$==2 ( %\n%           #
:#                    :# Define the body of your macro here %\n%              #
:#                    :# Then return the result to the caller %\n%            #
:#                    for /f "delims=" %%r in ('echo.%!%RETVAL%!%') do ( %\n% #
:#                      endlocal %&% set "RETVAL=%%~r" %\n%                   #
:#                    ) %\n%                                                  #
:#                  ) else setlocal enableDelayedExpansion %&% set ARGS=      #
:#                                                                            #
:#                  It is then invoked just like an external command:         #
:#                  %$macro% ARG1 ARG2 ...                                    #
:#                                                                            #
:#                  The ideas that make all this possible were published on   #
:#                  the dostips.com web site, in multiple messages exchanged  #
:#                  by community experts.                                     #
:#                  By convention on the dostips.com web site, macro names    #
:#                  begin by a $ character; And the %\n% variable ends lines. #
:#                  The other variables are mine.                             #
:#                                                                            #
:#                  The use of a for loop executed twice, is critical for     #
:#                  allowing to place arguments behind the macro.             #
:#                  The first loop executes only the tail line, which defines #
:#                  the arguments; The second loop executes the main body of  #
:#                  the macro, which processes the arguments, and returns the #
:#                  result(s).                                                #
:#                  To improve the readability of macros, replace the code in #
:#                  the first line by %MACRO%, and the code in the last line  #
:#                  by %/MACRO%                                               #
:#                                                                            #
:#                  The use of the Line Feed character as command separator   #
:#                  within macros is a clever trick, that helps debugging,    #
:#                  but it is not necessary for macros to work.               #
:#                  This helps debugging, because this allows to output the   #
:#                  macro definition as a structured string spanning several  #
:#                  lines, looking exactly like a normal function with one    #
:#                  instruction per line.                                     #
:#                  But it would be equally possible to define macros using   #
:#                  the documented & character as command separator.          #
:#                                                                            #
:#                  Limitations:                                              #
:#                  - A macro cannot call another macro.                      #
:#                    (This would require escaping all control characters in  #
:#                     the sub-macro, so that they survive an additional      #
:#                     level of expansion.)                                   #
:#                                                                            #
:#  History                                                                   #
:#   2015-04-15 JFL Initial version, based on dostips.com samples, with       #
:#                  changes so that they work with DelayedExpansion on.       #
:#   2015-11-27 JFL Added a primitive macro debugging capability.             #
:#                                                                            #
:#----------------------------------------------------------------------------#

call :Macro.Init
goto :Macro.End

:Macro.Init
:# Define a LF variable containing a Line Feed ('\x0A')
:# The two blank lines below are necessary.
set LF=^


:# End of define Line Feed. The two blank lines above are necessary.

:# LF generator variables, that become an LF after N expansions
:# %LF1% == %LF% ; %LF2% == To expand twice ; %LF3% == To expand 3 times ; Etc
:# Starting with LF2, the right # of ^ doubles on every line,
:# and the left # of ^ is 3 times the right # of ^.
set ^"LF1=^%LF%%LF%"
set ^"LF2=^^^%LF1%%LF1%^%LF1%%LF1%"
set ^"LF3=^^^^^^%LF2%%LF2%^^%LF2%%LF2%"
set ^"LF4=^^^^^^^^^^^^%LF3%%LF3%^^^^%LF3%%LF3%"
set ^"LF5=^^^^^^^^^^^^^^^^^^^^^^^^%LF4%%LF4%^^^^^^^^%LF4%%LF4%"

:# Variables for use in inline macro functions
set ^"\n=%LF3%^^^"	&:# Insert a LF and continue macro on next line
set "^!=^^^^^^^!"	&:# Define a %!%DelayedExpansion%!% variable
set "'^!=^^^!"		&:# Idem, but inside a quoted string
set ">=^^^>"		&:# Insert a redirection character
set "&=^^^&"		&:# Insert a command separator in a macro
:# Idem, to be expanded twice, for use in macros within macros
set "^!2=^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^!"
set "'^!2=^^^^^^^!"
set "&2=^^^^^^^^^^^^^^^&"

set "MACRO=for %%$ in (1 2) do if %%$==2"				&:# Prolog code of a macro
set "/MACRO=else setlocal enableDelayedExpansion %&% set MACRO.ARGS="	&:# Epilog code of a macro

set "ON_MACRO_EXIT=for /f "delims=" %%r in ('echo"	&:# Begin the return variables definitions 
set "/ON_MACRO_EXIT=') do endlocal %&% %%r"		&:# End the return variables definitions

:# Primitive macro debugging definitions
:# Macros, usable anywhere, including within other macros, for conditionally displaying debug information
:# Use option -xd to set a > 0 macro debugging level.
:# Usage: %IF_XDLEVEL% N command
:# Runs command if the current macro debugging level is at least N.
:# Ex: %IF_XDLEVEL% 2 set VARIABLE
:# Recommended: Use set, instead of echo, to display variable values. This is sometimes
:# annoying because this displays other unwanted variables. But this is the only way
:# to be sure to display _all_ tricky characters correctly in any expansion mode. 
:# Note: These debugging macros slow down a lot their enclosing macro.
:#       They should be removed from the released code.
set "XDLEVEL=0" &:# 0=No macro debug; 1=medium debug; 2=full debug; 3=Even more debug
set "IF_XDLEVEL=for /f %%' in ('call echo.%%XDLEVEL%%') do if %%' GEQ"

:# While at it, and although this is unrelated to macros, define other useful ASCII control codes
:# Define a CR variable containing a Carriage Return ('\x0D')
for /f %%a in ('copy /Z %COMSPEC% nul') do set "CR=%%a"

:# Define a BS variable containing a BackSpace ('\x08')
:# Use prompt to store a  backspace+space+backspace into a DEL variable.
for /F "tokens=1 delims=#" %%a in ('"prompt #$H# & echo on & for %%b in (1) do rem"') do set "DEL=%%a"
:# Then extract the first backspace
set "BS=%DEL:~0,1%"

goto :eof
:Macro.end

:#----------------------------------------------------------------------------#
:#                                                                            #
:#  Function        Debug routines					      #
:#                                                                            #
:#  Description     A collection of debug routines                            #
:#                                                                            #
:#  Functions       Debug.Init	    Initialize debugging. Call once at first. #
:#                  Debug.Off	    Disable the debugging mode		      #
:#                  Debug.On	    Enable the debugging mode		      #
:#                  Debug.SetLog    Set the log file         		      #
:#                  Debug.Entry	    Log entry into a routine		      #
:#                  Debug.Return    Log exit from a routine		      #
:#                  Verbose.Off	    Disable the verbose mode                  #
:#                  Verbose.On	    Enable the verbose mode		      #
:#                  Echo	    Echo and log strings, indented            #
:#                  EchoVars	    Display the values of a set of variables  #
:#                  EchoArgs	    Display the values of all arguments       #
:#                                                                            #
:#  Macros          %FUNCTION%	    Define and trace the entry in a function. #
:#                  %UPVAR%         Declare a var. to pass back to the caller.#
:#                  %RETURN%        Return from a function and trace it       #
:#                                                                            #
:#                  Always match uses of %FUNCTION% and %RETURN%. That is     #
:#                  never use %RETURN% if there was no %FUNCTION% before it.  #
:#                                                                            #
:#                  :# Example of a factorial routine using this framework    #
:#                  :Fact                                                     #
:#                  %FUNCTION% enableextensions enabledelayedexpansion        #
:#		    %UPVAR% RETVAL					      #
:#                  set N=%1                                                  #
:#                  if .%N%.==.0. (                                           #
:#                    set RETVAL=1                                            #
:#                  ) else (                                                  #
:#                    set /A M=N-1                                            #
:#                    call :Fact !M!                                          #
:#                    set /A RETVAL=N*RETVAL                                  #
:#                  )                                                         #
:#                  %RETURN%					              #
:#                                                                            #
:#                  %ECHO%	    Echo and log a string, indented           #
:#                  %LOG%	    Log a string, indented                    #
:#                  %ECHO.V%	    Idem, but display it in verbose mode only #
:#                  %ECHO.D%	    Idem, but display it in debug mode only   #
:#                                                                            #
:#                  %ECHOVARS%	    Indent, echo and log variables values     #
:#                  %ECHOVARS.V%    Idem, but display them in verb. mode only #
:#                  %ECHOVARS.D%    Idem, but display them in debug mode only #
:#                                                                            #
:#                  %IF_DEBUG%      Execute a command in debug mode only      #
:#                  %IF_VERBOSE%    Execute a command in verbose mode only    #
:#                                                                            #
:#  Variables       %>DEBUGOUT%     Debug output redirect. Either "" or ">&2".#
:#                  %LOGFILE%       Log file name. Inherited. Default=NUL.    #
:#                  %DEBUG%         Debug mode. 0=Off; 1=On. Use functions    #
:#                                  Debug.Off and Debug.On to change it.      #
:#                                  Inherited. Default=0.                     #
:#                  %VERBOSE%       Verbose mode. 0=Off; 1=On. Use functions  #
:#                                  Verbose.Off and Verbose.On to change it.  #
:#                                  Inherited. Default=0.                     #
:#                  %INDENT%        Spaces to put ahead of all debug output.  #
:#                                  Inherited. Default=. (empty string)       #
:#                                                                            #
:#  Notes           All output from these routines is sent to the log file.   #
:#                  In debug mode, the debug output is also sent to stderr.   #
:#                                                                            #
:#                  Traced functions are indented, based on the call depth.   #
:#                  Use %ECHO% to get the same indentation of normal output.  #
:#                                                                            #
:#                  The output format matches the batch language syntax       #
:#                  exactly. This allows copying the debug output directly    #
:#                  into another command window, to check troublesome code.   #
:#                                                                            #
:#  History                                                                   #
:#   2011-11-15 JFL Split Debug.Init from Debug.Off, to improve clarity.      #
:#   2011-12-12 JFL Output debug information to stderr, so that stdout can be #
:#                  used for returning information from the subroutine.       #
:#   2011-12-13 JFL Standardize use of RETVAR/RETVAL, and display it on return.
:#   2012-07-09 JFL Restructured functions to a more "object-like" style.     #
:#                  Added the three flavors of the Echo and EchoVars routines.#
:#   2012-07-19 JFL Added optimizations to improve performance in non-debug   #
:#                  and non-verbose mode. Added routine Debug.SetLog.         #
:#   2012-11-13 JFL Added macro LOG. Fixed setlocal bug in :EchoVars.         #
:#   2013-08-27 JFL Changed %RETURN% to do exit /b. This allows returning     #
:#                  an errorlevel by doing: %RETURN% %ERRORLEVEL%             #
:#   2013-11-12 JFL Added macros %IF_DEBUG% and %IF_VERBOSE%.                 #
:#   2013-12-04 JFL Added variable %>DEBUGOUT% to allow sending debug output  #
:#                  either to stdout or to stderr.                            #
:#   2015-10-29 JFL Added macro %RETURN#% to return with a comment.           #
:#   2015-11-19 JFL %FUNCTION% now automatically generates its name & %* args.#
:#                  (Simplifies usage, but comes at a cost of about a 5% slow #
:#                   down when running in debug mode.)                        #
:#                  Added an %UPVAR% macro allowing to define the list of     #
:#                  variables that need to make it back to the caller.        #
:#                  %RETURN% (Actually the Debug.return routine) now handles  #
:#                  this variable back propagation using the (goto) trick.    #
:#                  This works well, but the performance is poor.             #
:#   2015-11-25 JFL Rewrote the %FUNCTION% and %RETURN% macros to manage      #
:#                  most common cases without calling a subroutine. This      #
:#                  resolves the performance issues of the previous version.  #
:#   2015-11-27 JFL Redesigned the problematic character return mechanism     #
:#                  using a table of predefined generic entities. Includes    #
:#                  support for returning strings with CR & LF.		      #
:#   2015-11-29 JFL Streamlined the macros and added lots of comments.        #
:#                  The FUNCTION macro now runs with expansion enabled, then  #
:#                  does a second setlocal in the end as requested.           #
:#                  The RETURN macro now displays strings in debug mode with  #
:#                  delayed expansion enabled. This fixes issues with CR & LF.#
:#                  Added a backspace entity.                                 #
:#   2015-12-01 JFL Bug fix: %FUNCTION% with no arg did change the exp. mode. #
:#                                                                            #
:#----------------------------------------------------------------------------#

call :Debug.Init
goto :Debug.End

:Debug.Init
:# Preliminary checks to catch common problems
if exist echo >&2 echo WARNING: The file "echo" in the current directory will cause problems. Please delete it and retry.
:# Inherited variables from the caller: DEBUG, VERBOSE, INDENT, >DEBUGOUT
:# Initialize other debug variables
set "ECHO=call :Echo"
set "ECHOVARS=call :EchoVars"
:# Define variables for problematic characters, that cause parsing issues
:# Use the ASCII control character name, or the html entity name.
:# Warning: The excl and hat characters need different quoting depending on context.
set "DEBUG.percnt=%%"	&:# One percent sign
set "DEBUG.excl=^!"	&:# One exclamation mark
set "DEBUG.hat=^"	&:# One caret, aka. circumflex accent, or hat sign
set ^"DEBUG.quot=""	&:# One double quote
set "DEBUG.apos='"	&:# One apostrophe
set "DEBUG.amp=&"	&:# One ampersand
set "DEBUG.vert=|"	&:# One vertical bar
set "DEBUG.gt=>"	&:# One greater than sign
set "DEBUG.lt=<"	&:# One less than sign
set "DEBUG.lpar=("	&:# One left parenthesis
set "DEBUG.rpar=)"	&:# One right parenthesis
set "DEBUG.lbrack=["	&:# One left bracket
set "DEBUG.rbrack=]"	&:# One right bracket
set "DEBUG.sp= "	&:# One space
set "DEBUG.tab=	"	&:# One tabulation
set "DEBUG.cr=!CR!"	&:# One carrier return
set "DEBUG.lf=!LF!"	&:# One line feed
set "DEBUG.bs=!BS!"	&:# One backspace
:# The FUNCTION, UPVAR, and RETURN macros should work with delayed expansion on or off
set MACRO.GETEXP=(if "%'!2%%'!2%"=="" (set MACRO.EXP=EnableDelayedExpansion) else set MACRO.EXP=DisableDelayedExpansion)
set UPVAR=call set DEBUG.RETVARS=%%DEBUG.RETVARS%%
set RETURN=call set "DEBUG.ERRORLEVEL=%%ERRORLEVEL%%" %&% %MACRO% ( %\n%
  set DEBUG.EXITCODE=%!%MACRO.ARGS%!%%\n%
  if defined DEBUG.EXITCODE set DEBUG.EXITCODE=%!%DEBUG.EXITCODE: =%!%%\n%
  if not defined DEBUG.EXITCODE set DEBUG.EXITCODE=%!%DEBUG.ERRORLEVEL%!%%\n%
  set "DEBUG.SETARGS=" %\n%
  for %%v in (%!%DEBUG.RETVARS%!%) do ( %\n%
    set "DEBUG.VALUE=%'!%%%v%'!%" %# We must remove problematic characters in that value #% %\n%
    set "DEBUG.VALUE=%'!%DEBUG.VALUE:%%=%%DEBUG.percnt%%%'!%"	%# Remove percent #% %\n%
    for %%e in (sp tab cr lf quot) do for %%c in ("%'!%DEBUG.%%e%'!%") do ( %# Remove named character entities #% %\n%
      set "DEBUG.VALUE=%'!%DEBUG.VALUE:%%~c=%%DEBUG.%%e%%%'!%" %\n%
    ) %\n%
    set "DEBUG.VALUE=%'!%DEBUG.VALUE:^^=%%DEBUG.hat%%%'!%"	%# Remove carets #% %\n%
    call set "DEBUG.VALUE=%%DEBUG.VALUE:%!%=^^^^%%" 		%# Remove exclamation points #% %\n%
    set "DEBUG.VALUE=%'!%DEBUG.VALUE:^^^^=%%DEBUG.excl%%%'!%"	%# Remove exclamation points #% %\n%
    set DEBUG.SETARGS=%!%DEBUG.SETARGS%!% "%%v=%'!%DEBUG.VALUE%'!%" %\n%
  ) %\n%
  if %!%DEBUG%!%==1 ( %# Build the debug message and display it #% %\n%
    set "DEBUG.MSG=return %'!%DEBUG.EXITCODE%'!%" %\n%
    for %%v in (%!%DEBUG.SETARGS%!%) do ( %\n%
      set "DEBUG.MSG=%'!%DEBUG.MSG%'!% %%DEBUG.amp%% set %%v" %!% %\n%
    ) %\n%
    call set "DEBUG.MSG=%'!%DEBUG.MSG:%%=%%DEBUG.excl%%%'!%" %# Change all percent to ! #%  %\n%
    if defined ^^%>%DEBUGOUT ( %# If we use a debugging stream distinct from stdout #% %\n%
      call :Echo.Eval2DebugOut %!%DEBUG.MSG%!%%# Use a helper routine, as delayed redirection does not work #%%\n%
    ) else ( %# Output directly here, which is faster #% %\n%
      for /f "delims=" %%c in ("%'!%INDENT%'!%%'!%DEBUG.MSG%'!%") do echo %%c%# Use a for loop to do a double !variable! expansion #% %\n%
    ) %\n%
    if defined LOGFILE ( %# If we have to send a copy to a log file #% %\n%
      call :Echo.Eval2LogFile %!%DEBUG.MSG%!%%# Use a helper routine, as delayed redirection does not work #%%\n%
    ) %\n%
  ) %\n%
  for %%r in (%!%DEBUG.EXITCODE%!%) do ( %# Carry the return values through the endlocal barriers #% %\n%
    for /f "delims=" %%a in (""" %'!%DEBUG.SETARGS%'!%") do ( %# The initial "" makes sure the body runs even if the arg list is empty #% %\n%
      endlocal %&% endlocal %&% endlocal %# Exit the RETURN and FUNCTION local scopes #% %\n%
      if "%'!%%'!%"=="" ( %# Delayed expansion is ON #% %\n%
	set "DEBUG.SETARGS=%%a" %\n%
	call set "DEBUG.SETARGS=%'!%DEBUG.SETARGS:%%=%%DEBUG.excl%%%'!%" %# Change all percent to ! #%  %\n%
	for %%v in (%!%DEBUG.SETARGS:~3%!%) do ( %\n%
	  set %%v %# Set each upvar variable in the caller's scope #% %\n%
	) %\n%
	set "DEBUG.SETARGS=" %\n%
      ) else ( %# Delayed expansion is OFF #% %\n%
	set "DEBUG.hat=^^^^" %# Carets need to be doubled to be set right below #% %\n%
	for %%v in (%%a) do if not %%v=="" ( %\n%
	  call set %%v %# Set each upvar variable in the caller's scope #% %\n%
	) %\n%
	set "DEBUG.hat=^^" %# Restore the normal value with a single caret #% %\n%
      ) %\n%
      exit /b %%r %# Return to the caller #% %\n%
    ) %\n%
  ) %\n%
) %/MACRO%
:Debug.Init.2
set "LOG=call :Echo.Log"
set ">>LOGFILE=>>%LOGFILE%"
if not defined LOGFILE set "LOG=rem" & set ">>LOGFILE=rem"
if .%LOGFILE%.==.NUL. set "LOG=rem" & set ">>LOGFILE=rem"
set "ECHO.V=call :Echo.Verbose"
set "ECHO.D=call :Echo.Debug"
set "ECHOVARS.V=call :EchoVars.Verbose"
set "ECHOVARS.D=call :EchoVars.Debug"
:# Variables inherited from the caller...
:# Preserve INDENT if it contains just spaces, else clear it.
for /f %%s in ('echo.%INDENT%') do set "INDENT="
:# Preserve the log file name, else by default use NUL.
:# if not defined LOGFILE set "LOGFILE=NUL"
:# VERBOSE mode can only be 0 or 1. Default is 0.
if not .%VERBOSE%.==.1. set "VERBOSE=0"
call :Verbose.%VERBOSE%
:# DEBUG mode can only be 0 or 1. Default is 0.
if not .%DEBUG%.==.1. set "DEBUG=0"
goto :Debug.%DEBUG%

:Debug.SetLog
set "LOGFILE=%~1"
goto :Debug.Init.2

:Debug.Off
:Debug.0
set "DEBUG=0"
set "DEBUG.ENTRY=rem"
set "IF_DEBUG=if .%DEBUG%.==.1."
set "FUNCTION0=rem"
set FUNCTION=%MACRO.GETEXP% %&% %MACRO% ( %\n%
  call set "FUNCTION.NAME=%%0" %\n%
  call set "ARGS=%%*"%\n%
  set "DEBUG.RETVARS=" %\n%
  if not defined MACRO.ARGS set "MACRO.ARGS=%'!%MACRO.EXP%'!%" %\n%
  setlocal %!%MACRO.ARGS%!% %\n%
) %/MACRO%
set "RETURN0=exit /b"
set "RETURN#=exit /b & rem"
set "EXEC.ARGS= %EXEC.ARGS%"
set "EXEC.ARGS=%EXEC.ARGS: -d=%"
set "EXEC.ARGS=%EXEC.ARGS:~1%"
:# Optimization to speed things up in non-debug mode
if not defined LOGFILE set "ECHO.D=rem"
if .%LOGFILE%.==.NUL. set "ECHO.D=rem"
if not defined LOGFILE set "ECHOVARS.D=rem"
if .%LOGFILE%.==.NUL. set "ECHOVARS.D=rem"
goto :eof

:Debug.On
:Debug.1
set "DEBUG=1"
set "DEBUG.ENTRY=:Debug.Entry"
set "IF_DEBUG=if .%DEBUG%.==.1."
set "FUNCTION0=call call :Debug.Entry0 %%0 %%*"
set FUNCTION=%MACRO.GETEXP% %&% %MACRO% ( %\n%
  call set "FUNCTION.NAME=%%0" %\n%
  call set "ARGS=%%*"%\n%
  if %!%DEBUG%!%==1 ( %# Build the debug message and display it #% %\n%
    if defined ^^%>%DEBUGOUT ( %# If we use a debugging stream distinct from stdout #% %\n%
      call :Echo.2DebugOut call %!%FUNCTION.NAME%!% %!%ARGS%!%%# Use a helper routine, as delayed redirection does not work #%%\n%
    ) else ( %# Output directly here, which is faster #% %\n%
      echo%!%INDENT%!% call %!%FUNCTION.NAME%!% %!%ARGS%!%%\n%
    ) %\n%
    if defined LOGFILE ( %# If we have to send a copy to a log file #% %\n%
      call :Echo.2LogFile call %!%FUNCTION.NAME%!% %!%ARGS%!%%# Use a helper routine, as delayed redirection does not work #%%\n%
    ) %\n%
    call set "INDENT=%'!%INDENT%'!%  " %\n%
  ) %\n%
  set "DEBUG.RETVARS=" %\n%
  if not defined MACRO.ARGS set "MACRO.ARGS=%'!%MACRO.EXP%'!%" %\n%
  setlocal %!%MACRO.ARGS%!% %\n%
) %/MACRO%
set "RETURN0=call :Debug.Return0 & exit /b"
:# Macro for displaying comments on the return log line
set RETURN#=set "RETURN#ERR=%'!%ERRORLEVEL%'!%" %&% %MACRO% ( %\n%
  set RETVAL=%!%MACRO.ARGS:~1%!%%\n%
  call :Debug.Return %!%RETURN#ERR%!% %\n%
  %ON_MACRO_EXIT% set "INDENT=%'!%INDENT%'!%" %/ON_MACRO_EXIT% %&% set "RETURN#ERR=" %&% exit /b %\n%
) %/MACRO%
set "EXEC.ARGS= %EXEC.ARGS%"
set "EXEC.ARGS=%EXEC.ARGS: -d=% -d"
set "EXEC.ARGS=%EXEC.ARGS:~1%"
:# Reverse the above optimization
set "ECHO.D=call :Echo.Debug"
set "ECHOVARS.D=call :EchoVars.Debug"
goto :eof

:Debug.Entry0
setlocal DisableDelayedExpansion
%>DEBUGOUT% echo %INDENT%call %*
if defined LOGFILE %>>LOGFILE% echo %INDENT%call %*
endlocal
set "INDENT=%INDENT%  "
goto :eof

:Debug.Entry
setlocal DisableDelayedExpansion
%>DEBUGOUT% echo %INDENT%call %FUNCTION.NAME% %ARGS%
if defined LOGFILE %>>LOGFILE% echo %INDENT%call %FUNCTION.NAME% %ARGS%
endlocal
set "INDENT=%INDENT%  "
goto :eof

:Debug.Return0 %1=Optional exit code
%>DEBUGOUT% echo %INDENT%return !RETVAL!
if defined LOGFILE %>>LOGFILE% echo %INDENT%return !RETVAL!
set "INDENT=%INDENT:~0,-2%"
exit /b %1

:# Routine to set the VERBOSE mode, in response to the -v argument.
:Verbose.Off
:Verbose.0
set "VERBOSE=0"
set "IF_VERBOSE=if .%VERBOSE%.==.1."
set "EXEC.ARGS= %EXEC.ARGS%"
set "EXEC.ARGS=%EXEC.ARGS: -v=%"
set "EXEC.ARGS=%EXEC.ARGS:~1%"
:# Optimization to speed things up in non-verbose mode
if not defined LOGFILE set "ECHO.V=rem"
if .%LOGFILE%.==.NUL. set "ECHO.V=rem"
if not defined LOGFILE set "ECHOVARS.V=rem"
if .%LOGFILE%.==.NUL. set "ECHOVARS.V=rem"
goto :eof

:Verbose.On
:Verbose.1
set "VERBOSE=1"
set "IF_VERBOSE=if .%VERBOSE%.==.1."
set "EXEC.ARGS= %EXEC.ARGS%"
set "EXEC.ARGS=%EXEC.ARGS: -v=% -v"
set "EXEC.ARGS=%EXEC.ARGS:~1%"
:# Reverse the above optimization
set "ECHO.V=call :Echo.Verbose"
set "ECHOVARS.V=call :EchoVars.Verbose"
goto :eof

:# Echo and log a string, indented at the same level as the debug output.
:Echo
echo.%INDENT%%*
:Echo.Log
if defined LOGFILE %>>LOGFILE% echo.%INDENT%%*
goto :eof

:Echo.Verbose
%IF_VERBOSE% goto :Echo
goto :Echo.Log

:Echo.Debug
%IF_DEBUG% goto :Echo
goto :Echo.Log

:Echo.Eval2DebugOut %*=String with variables that need to be evaluated first
:# Must be called with delayed expansion on, so that !variables! within %* get expanded
:Echo.2DebugOut	%*=String to output to the DEBUGOUT stream
%>DEBUGOUT% echo.%INDENT%%*
goto :eof

:Echo.Eval2LogFile %*=String with variables that need to be evaluated first
:# Must be called with delayed expansion on, so that !variables! within %* get expanded
:Echo.2LogFile %*=String to output to the LOGFILE
%>>LOGFILE% echo.%INDENT%%*
goto :eof

:# Echo and log variable values, indented at the same level as the debug output.
:EchoVars
setlocal EnableExtensions EnableDelayedExpansion
:EchoVars.loop
if "%~1"=="" endlocal & goto :eof
%>DEBUGOUT% echo %INDENT%set "%~1=!%~1!"
if defined LOGFILE %>>LOGFILE% echo %INDENT%set "%~1=!%~1!"
shift
goto EchoVars.loop

:EchoVars.Verbose
%IF_VERBOSE% (
  call :EchoVars %*
) else ( :# Make sure the variables are logged
  call :EchoVars %* >NUL 2>NUL
)
goto :eof

:EchoVars.Debug
%IF_DEBUG% (
  call :EchoVars %*
) else ( :# Make sure the variables are logged
  call :EchoVars %* >NUL 2>NUL
)
goto :eof

:# Echo a list of arguments.
:EchoArgs
setlocal EnableExtensions DisableDelayedExpansion
set N=0
:EchoArgs.loop
if .%1.==.. endlocal & goto :eof
set /a N=N+1
%>DEBUGOUT% echo %INDENT%set "ARG%N%=%1"
shift
goto EchoArgs.loop

:Debug.End

:#----------------------------------------------------------------------------#
:#                                                                            #
:#  Function        Exec                                                      #
:#                                                                            #
:#  Description     Run a command, logging its output to the log file.        #
:#                                                                            #
:#                  In VERBOSE mode, display the command line first.          #
:#                  In DEBUG mode, display the command line and the exit code.#
:#                  In NOEXEC mode, display the command line, but don't run it.
:#                                                                            #
:#  Arguments       -t          Tee all output to the log file if there's a   #
:#                              usable tee.exe. Default: Redirect all >> log. #
:#                              Known limitation: The exit code is always 0.  #
:#                  %*          The command and its arguments                 #
:#                              Quote redirection operators. Ex:              #
:#                              %EXEC% find /I "error" "<"logfile.txt ">"NUL  #
:#                                                                            #
:#  Functions       Exec.Init	Initialize Exec routines. Call once at 1st    #
:#                  Exec.Off	Disable execution of commands		      #
:#                  Exec.On	Enable execution of commands		      #
:#                  Do          Always execute a command, logging its output  #
:#                  Exec	Conditionally execute a command, logging it.  #
:#                                                                            #
:#  Macros          %DO%        Always execute a command, logging its output  #
:#                  %EXEC%      Conditionally execute a command, logging it.  #
:#                  %ECHO.X%    Echo and log a string, indented, in -X mode.  #
:#                  %ECHO.XVD%  Echo a string, indented, in -X or -V or -D    #
:#                              modes; Log it always.                         #
:#                              Useful to display commands in cases where     #
:#                              %EXEC% can't be used, like in for ('cmd') ... #
:#                  %IF_EXEC%   Execute a command if _not_ in NOEXEC mode     #
:#                  %IF_NOEXEC% Execute a command in NOEXEC mode only         #
:#                                                                            #
:#  Variables       %LOGFILE%	Log file name.                                #
:#                  %NOEXEC%	Exec mode. 0=Execute commands; 1=Don't. Use   #
:#                              functions Exec.Off and Exec.On to change it.  #
:#                              Inherited from the caller. Default=On.	      #
:#                  %NOREDIR%   0=Log command output to the log file; 1=Don't #
:#                              Default: 0                                    #
:#                              Useful in cases where the output must be      #
:#                              shown to the user, and no tee.exe is available.
:#                  %EXEC.ARGS%	Arguments to recursively pass to subcommands  #
:#                              with the same execution options conventions.  #
:#                                                                            #
:#  Notes           This framework can't be used from inside () blocks.       #
:#                  This is because these blocks are executed separately      #
:#                  in a child shell.                                         #
:#                                                                            #
:#  History                                                                   #
:#   2010-05-19 JFL Created this routine.                                     #
:#   2012-05-04 JFL Support logging ">" redirections.                         #
:#   2012-07-09 JFL Restructured functions to a more "object-like" style.     #
:#   2012-07-11 JFL Support logging both "<" and ">" redirections.            #
:#   2012-09-18 JFL Added macro %ECHO.X% for cases where %EXEC% can't be used.#
:#   2012-11-13 JFL Support for "|" pipes too.                                #
:#   2013-11-12 JFL Added macro %IF_NOEXEC%.                                  #
:#   2013-12-04 JFL Added option -t to tee the output if possible.            #
:#                  Split %ECHO.X% and %ECHO.XVD%.                            #
:#   2014-05-13 JFL Call tee.exe explicitely, to avoid problems if there's    #
:#                  also a tee.bat script in the path.                        #
:#   2015-03-12 JFL If there are output redirections, then cancel any attempt #
:#		    at redirecting output to the log file.		      #
:#                                                                            #
:#----------------------------------------------------------------------------#

call :Exec.Init
goto :Exec.End

:# Global variables initialization, to be called first in the main routine
:Exec.Init
set "DO=call :Do"
set "EXEC=call :Exec"
set "ECHO.X=call :Echo.NoExec"
set "ECHO.XVD=call :Echo.XVD"
if not .%NOEXEC%.==.1. set "NOEXEC=0"
if not .%NOREDIR%.==.1. set "NOREDIR=0"
:# Check if there's a tee.exe program available
set "Exec.HaveTee=0"
tee.exe --help >NUL 2>NUL
if not errorlevel 1 set "Exec.HaveTee=1"
goto :NoExec.%NOEXEC%

:Exec.On
:NoExec.0
set "NOEXEC=0"
set "IF_NOEXEC=if .%NOEXEC%.==.1."
set "IF_EXEC=if .%NOEXEC%.==.0."
set "EXEC.ARGS= %EXEC.ARGS%"
set "EXEC.ARGS=%EXEC.ARGS: -X=%"
set "EXEC.ARGS=%EXEC.ARGS:~1%"
goto :eof

:# Routine to set the NOEXEC mode, in response to the -X argument.
:Exec.Off
:NoExec.1
set "NOEXEC=1"
set "IF_NOEXEC=if .%NOEXEC%.==.1."
set "IF_EXEC=if .%NOEXEC%.==.0."
set "EXEC.ARGS= %EXEC.ARGS%"
set "EXEC.ARGS=%EXEC.ARGS: -X=% -X"
set "EXEC.ARGS=%EXEC.ARGS:~1%"
goto :eof

:Echo.NoExec
%IF_NOEXEC% goto :Echo
goto :eof

:Echo.XVD
%IF_NOEXEC% goto :Echo
%IF_VERBOSE% goto :Echo
%IF_DEBUG% goto :Echo
goto :Echo.Log

:# Execute a command, logging its output.
:# Use for informative commands that should always be run, even in NOEXEC mode. 
:Do
setlocal EnableExtensions DisableDelayedExpansion
set NOEXEC=0
set "IF_NOEXEC=if .%NOEXEC%.==.1."
goto :Exec.Start

:# Execute critical operations that should not be run in NOEXEC mode.
:# Version supporting input and output redirections, and pipes.
:# Redirection operators MUST be surrounded by quotes. Ex: "<" or ">" or "2>>"
:Exec
setlocal EnableExtensions DisableDelayedExpansion
:Exec.Start
set "Exec.Redir=>>%LOGFILE%,2>&1"
if .%NOREDIR%.==.1. set "Exec.Redir="
if not defined LOGFILE set "Exec.Redir="
if /i .%LOGFILE%.==.NUL. set "Exec.Redir="
:# Process optional arguments
set "Exec.GotCmd=Exec.GotCmd"   &:# By default, the command line is %* for :Exec
goto :Exec.GetArgs
:Exec.NextArg
set "Exec.GotCmd=Exec.BuildCmd" &:# An :Exec argument was found, we'll have to rebuild the command line
shift
:Exec.GetArgs
if "%~1"=="-L" set "Exec.Redir=" & goto :Exec.NextArg :# Do not send the output to the log file
if "%~1"=="-t" if defined LOGFILE ( :# Tee the output to the log file
  :# Warning: This prevents from getting the command exit code!
  if .%Exec.HaveTee%.==.1. set "Exec.Redir= 2>&1 | tee.exe -a %LOGFILE%"
  goto :Exec.NextArg
)
set Exec.Cmd=%*
goto :%Exec.GotCmd%
:Exec.BuildCmd
:# Build the command list. Cannot use %*, which still contains the :Exec switches processed above.
set Exec.Cmd=%1
:Exec.GetCmdLoop
shift
if not .%1.==.. set Exec.Cmd=%Exec.Cmd% %1& goto :Exec.GetCmdLoop
:Exec.GotCmd
:# First stage: Split multi-char ops ">>" "2>" "2>>". Make sure to keep ">" signs quoted every time.
:# Do NOT use surrounding quotes for these set commands, else quoted arguments will break.
set Exec.Cmd=%Exec.Cmd:">>"=">"">"%
set Exec.Cmd=%Exec.Cmd:">>&"=">"">""&"%
set Exec.Cmd=%Exec.Cmd:">&"=">""&"%
:# If there are output redirections, then cancel any attempt at redirecting output to the log file.
set "Exec.Cmd1=%Exec.Cmd:"=%" &:# Remove quotes in the command string, to allow quoting the whole string.
if not "%Exec.Cmd1:>=%"=="%Exec.Cmd1%" set "Exec.Redir="
:# Second stage: Convert quoted redirection operators (Ex: ">") to a usable (Ex: >) and a displayable (Ex: ^>) value.
:# Must be once for each of the four < > | & operators.
:# Since each operation removes half of ^ escape characters, then insert
:# enough ^ to still protect the previous characters during the subsequent operations.
set Exec.toEcho=%Exec.Cmd:"|"=^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^|%
set Exec.toEcho=%Exec.toEcho:"&"=^^^^^^^^^^^^^^^&%
set Exec.toEcho=%Exec.toEcho:">"=^^^^^^^>%
set Exec.toEcho=%Exec.toEcho:"<"=^^^<%
:# Finally create the usable command, by removing the last level of ^ escapes.
set Exec.Cmd=%Exec.toEcho%
set "Exec.Echo=rem"
%IF_NOEXEC% set "Exec.Echo=echo"
%IF_DEBUG% set "Exec.Echo=echo"
%IF_VERBOSE% set "Exec.Echo=echo"
%>DEBUGOUT% %Exec.Echo%.%INDENT%%Exec.toEcho%
if defined LOGFILE %>>LOGFILE% echo.%INDENT%%Exec.toEcho%
:# Constraints at this stage:
:# The command exit code must make it through, back to the caller.
:# The local variables must disappear before return.
:# But the new variables created by the command must make it through.
:# This should work whether :Exec is called with delayed expansion on or off.
endlocal & if not .%NOEXEC%.==.1. (
  %Exec.Cmd%%Exec.Redir%
  call :Exec.ShowExitCode
)
goto :eof

:Exec.ShowExitCode
%IF_DEBUG% %>DEBUGOUT% echo.%INDENT%  exit %ERRORLEVEL%
if defined LOGFILE %>>LOGFILE% echo.%INDENT%  exit %ERRORLEVEL%
exit /b %ERRORLEVEL%

:Exec.End

:#----------------------------------------------------------------------------#
:#                        End of the debugging library                        #
:#----------------------------------------------------------------------------#

:#----------------------------------------------------------------------------#
:#  Variables containing control characters
:#----------------------------------------------------------------------------#

:# Define a CR variable containing a Carriage Return ('\x0D')
for /f %%a in ('copy /Z "%~dpf0" nul') do set "CR=%%a"

:# Define a LF variable containing a Line Feed ('\x0A')
:# The two blank lines below are necessary.
set LF=^


:# End of define Line Feed. The two blank lines above are necessary.

:# Define a BS variable containing a BackSpace ('\x08')
:# Use prompt to store a  backspace+space+backspace into a DEL variable.
for /F "tokens=1 delims=#" %%a in ('"prompt #$H# & echo on & for %%b in (1) do rem"') do set "DEL=%%a"
:# Then extract the first backspace
set "BS=%DEL:~0,1%"

:#----------------------------------------------------------------------------#
:#  Useful tricks
:#----------------------------------------------------------------------------#

:# The following commands end up with a loop that works identically both
:# inside a batch file, and at the cmd.exe prompt.
set "@=%"	&:# Ends up as % at cmd prompt, or undefined in a batch
if not defined @ set "@=%%"	&:# If undefined (in a batch) redefine as %
for /l %@%N in (1,1,3) do @echo Loop %@%N   &:# Display the loop number

:#----------------------------------------------------------------------------#
:#  Test macros
:#----------------------------------------------------------------------------#

:Macro.test
:# Sample macro showing macro features, and how to use them
set $reflect=%MACRO% ( %\n%
  echo $reflect %!%MACRO.ARGS%!% %\n%
  :# Make sure ARG is undefined if there's no argument %\n%
  set "ARG=" %\n%
  :# Scan all arguments, and show what they are %\n%
  for %%v in (%!%MACRO.ARGS%!%) do ( %\n%
    set "ARG=%%~v" %\n%
    echo Hello %!%ARG%!% %\n%
  ) %\n%
  :# Change another variable, to show the change is local only %\n%
  set "LOCALVAR=CHANGED" %\n%
  :# Return the last argument %\n%
  set RETVAL=%!%ARG%!%%\n%
  :# Work around the inability to use either %RETVAL% or !RETVAL! in macros after endlocal %\n%
  echo return "RETVAL=%'!%RETVAL%'!%"%\n%
  %ON_MACRO_EXIT% set "RETVAL=%'!%RETVAL%'!%" %/ON_MACRO_EXIT% %\n%
) %/MACRO%

set $reflect

echo.
set LOCALVAR=BEFORE
echo set "RETVAL=%RETVAL%"
echo set "LOCALVAR=%LOCALVAR%"
%$reflect% inline functions
echo set "RETVAL=%RETVAL%"
echo set "LOCALVAR=%LOCALVAR%"

echo.
%$reflect%
echo set "RETVAL=%RETVAL%"
echo set "LOCALVAR=%LOCALVAR%"

echo.
%$reflect% more "inline functions"
echo set "RETVAL=%RETVAL%"
echo set "LOCALVAR=%LOCALVAR%"
goto :eof

:Return#.Test1
%FUNCTION%
if %1==0 %TRUE.EXE% & %RETURN#% 0
%FALSE.EXE% & %RETURN#% 1

:Return#.Test
call :Return#.Test1 0
echo ERRORLEVEL=%ERRORLEVEL% Expected 0
call :Return#.Test1 1
echo ERRORLEVEL=%ERRORLEVEL% Expected 1
call :Return#.Test1 0
echo ERRORLEVEL=%ERRORLEVEL% Expected 0
goto :eof

:#----------------------------------------------------------------------------#
:# From: http://www.dostips.com/forum/viewtopic.php?f=3&t=5411
:# This is posted mostly for (my) reference, since I don't always remember,
:# and never seem to be able to find everything in one place.
:# Below is a set of LF-related macros, with !LF! and %\n% following common
:# usage around here, %/n% being proposed for a linefeed without continuation,
:# and multi-slashed %\\n% %//n% indicating the target depth of expansion.
:# Code:
@echo off & setlocal disableDelayedExpansion

@rem single linefeed char 0x0A (two blank lines required below)
set LF=^


@rem linefeed macros
set ^"/n=^^^%LF%%LF%^%LF%%LF%"
set ^"//n=^^^^^^%/n%%/n%^^%/n%%/n%"
set ^"///n=^^^^^^^^^^^^%//n%%//n%^^^^%//n%%//n%"
set ^"////n=^^^^^^^^^^^^^^^^^^^^^^^^%///n%%///n%^^^^^^^^%///n%%///n%"
:: set ^"//n=^^^^^^^%LF%%LF%^%LF%%LF%^^^%LF%%LF%^%LF%%LF%"

@rem newline macros (linefeed + line continuation)
set ^"\n=%//n%^^"
set ^"\\n=%///n%^^"
set ^"\\\n=%////n%^^"

setlocal enableDelayedExpansion

@rem check inline expansion
echo(
set ^"NL=^%LF%%LF%"
if '!LF!'=='!NL!' echo '^^!LF^^!'    == '^^^^%%LF%%%%LF%%'

@rem check linefeed macros
echo(
set "ddx=!/n!" & set "edx=!LF!"
call :check && (echo '%%/n%%'    == '^^!LF^^!') || (echo ???)
set "ddx=!//n!" & set "edx=!/n!"
call :check && (echo '%%//n%%'   == '^^!/n^^!') || (echo ???)
set "ddx=!///n!" & set "edx=!//n!"
call :check && (echo '%%///n%%'  == '^^!//n^^!') || (echo ???)
set "ddx=!////n!" & set "edx=!///n!"
call :check && (echo '%%////n%%' == '^^!///n^^!') || (echo ???)

@rem check newline macros
echo(
set "ddx=!\n!" & set "edx=!LF!^"
call :check && (echo '%%\n%%'    == '^^!LF^^!^^^^') || (echo ???)
set "ddx=!\\n!" & set "edx=!/n!^"
call :check && (echo '%%\\n%%'   == '^^!/n^^!^^^^') || (echo ???)
set "ddx=!\\\n!" & set "edx=!//n!^"
call :check && (echo '%%\\\n%%'  == '^^!//n^^!^^^^') || (echo ???)

endlocal & endlocal & goto :eof

:check
set ^"dvar='%ddx%'"
set ^"evar='!edx!'"
if "!dvar!" equ "!evar!" (call;) else (call) & goto :eof

:#----------------------------------------------------------------------------#
:#batchTee.bat  OutputFile  [+]
:#
:#  Write each line of stdin to both stdout and outputFile.
:#  The default behavior is to overwrite any existing outputFile.
:#  If the 2nd argument is + then the content is appended to any existing
:#  outputFile.
:#
:#  Limitations:
:#
:#  1) Lines are limited to ~1000 bytes. The exact maximum line length varies
:#     depending on the line number. The SET /P command is limited to reading
:#     1021 bytes per line, and each line is prefixed with the line number when
:#     it is read.
:#
:#  2) Trailing control characters are stripped from each line.
:#
:#  3) Lines will not appear on the console until a newline is issued, or
:#     when the input is exhaused. This can be a problem if the left side of
:#     the pipe issues a prompt and then waits for user input on the same line.
:#     The prompt will not appear until after the input is provided.
:#
:# From http://www.dostips.com/forum/viewtopic.php?p=32615#p32615
:#----------------------------------------------------------------------------#

@echo off
setlocal enableDelayedExpansion
if "%~1" equ ":tee" goto :tee

:lock
set "teeTemp=%temp%\tee%time::=_%"
2>nul (
  9>"%teeTemp%.lock" (
    for %%F in ("%teeTemp%.test") do (
      set "yes="
      pushd "%temp%"
      copy /y nul "%%~nxF" >nul
      for /f "tokens=2 delims=(/" %%A in (
        '^<nul copy /-y nul "%%~nxF"'
      ) do if not defined yes set "yes=%%A"
      popd
    )
    for /f %%A in ("!yes!") do (
        find /n /v ""
         echo :END
         echo %%A
      ) >"%teeTemp%.tmp" | <"%teeTemp%.tmp" "%~f0" :tee %* 7>&1 >nul
    (call )
  ) || goto :lock
)
del "%teeTemp%.lock" "%teeTemp%.tmp" "%teeTemp%.test"
exit /b

:tee
set "redirect=>"
if "%~3" equ "+" set "redirect=>>"
8%redirect% %2 (call :tee2)
set "redirect="
(echo ERROR: %~nx0 unable to open %2)>&7

:tee2
for /l %%. in () do (
  set "ln="
  set /p "ln="
  if defined ln (
    if "!ln:~0,4!" equ ":END" exit
    set "ln=!ln:*]=!"
    (echo(!ln!)>&7
    if defined redirect (echo(!ln!)>&8
  )
)

:#----------------------------------------------------------------------------#
:#                                                                            #
:#  Function        EnableExpansion                                           #
:#                                                                            #
:#  Description     Test if cmd.exe delayed variable expansion can be enabled #
:#                                                                            #
:#  Returns         %ERRORLEVEL% == 0 if success, else error.                 #
:#                                                                            #
:#  Note            Allows testing if enabling delayed expansion works.       #
:#                  But, contrary to what I thought when I created the        #
:#		    routine, the effect does not survive the return.          #
:#                  So this routine CANNOT be used to enable variable         #
:#                  expansion.                                                #
:#                                                                            #
:#  History                                                                   #
:#   2010-05-31 JFL Created this routine.                                     #
:#   2014-05-13 JFL Only do a single setlocal.                                #
:#                  Tested various return methods, but none of them preserves #
:#                  the expansion state changed inside.                       #
:#                                                                            #
:#----------------------------------------------------------------------------#

:EnableExpansion
:# Enable command extensions
verify other 2>nul
setlocal EnableExtensions
if errorlevel 1 (
  >&2 echo Error: Unable to enable cmd.exe command extensions.
  >&2 echo Please restart your cmd.exe shell with the /E:ON option,
  >&2 echo or set HKLM\Software\Microsoft\Command Processor\EnableExtensions=1
  >&2 echo or set HKCU\Software\Microsoft\Command Processor\EnableExtensions=1
  exit /b 1
)
endlocal &:# Disable that first setting, as we do another setlocal just below.
:# Enable delayed variable expansion
verify other 2>nul
setlocal EnableExtensions EnableDelayedExpansion
if errorlevel 1 (
  :EnableExpansionFailed
  >&2 echo Error: Unable to enable cmd.exe delayed variable expansion.
  >&2 echo Please restart your cmd.exe shell with the /V option,
  >&2 echo or set HKLM\Software\Microsoft\Command Processor\DelayedExpansion=1
  >&2 echo or set HKCU\Software\Microsoft\Command Processor\DelayedExpansion=1
  exit /b 1
)
:# Check if delayed variable expansion works now 
set VAR=before
if "%VAR%" == "before" (
  set VAR=after
  if not "!VAR!" == "after" goto :EnableExpansionFailed
)
:# Success
exit /b 0

:# Test proving that the :EnableExpansion routine does not have lasting effects.
:EnableExpansion.Test
setlocal EnableExtensions DisableDelayedExpansion
echo :# First attempt with variable expansion disabled
set "X=Initial value"
set "X=Modified value" & echo X=!X!
call :EnableExpansion
echo :# Second attempt after call :EnableExpansion
set "X=Initial value"
set "X=Modified value" & echo X=!X!
endlocal
setlocal EnableExtensions EnableDelayedExpansion
echo :# Third attempt after setlocal EnableDelayedExpansion
set "X=Initial value"
set "X=Modified value" & echo X=!X!
endlocal
goto :eof

:#----------------------------------------------------------------------------#
:#                                                                            #
:#  Function        Echo-n                                                    #
:#                                                                            #
:#  Description     Output a string with no newline                           #
:#                                                                            #
:#  Macros          %ECHO-N%    Output a string with no newline.              #
:#                                                                            #
:#  Arguments       %1          String to output.                             #
:#                                                                            #
:#  Notes           Quotes around the string, if any, will be removed.        #
:#                  Leading spaces will NOT be output. (Limitation of set /P) #
:#                                                                            #
:#  History                                                                   #
:#   2010-05-19 JFL Created this routine.                                     #
:#   2012-07-09 JFL Send the output to the log file too.                      #
:#                                                                            #
:#----------------------------------------------------------------------------#

set "ECHO-N=call :Echo-n"
goto :Echo-n.End

:Echo-n
setlocal
if defined LOGFILE %>>LOGFILE% <NUL set /P =%~1
                               <NUL set /P =%~1
endlocal
goto :eof

:Echo-n.End

:#----------------------------------------------------------------------------#
:#                                                                            #
:#  Function        Echo.Color						      #
:#                                                                            #
:#  Description     Echo colored strings                                      #
:#                                                                            #
:#  Arguments                                                                 #
:#                                                                            #
:#  Notes 	    Based on the colorPrint sample code in                    #
:#                  http://stackoverflow.com/questions/4339649/how-to-have-multiple-colors-in-a-batch-file
:#                                                                            #
:#                  Requires ending the script with a last line containing    #
:#                  a single dash "-" and no CRLF in the end.                 #
:#                                                                            #
:#                  Known limitations:                                        #
:#                  Backspaces do not work across a line break, so the        #
:#                  technique can have problems if the line wraps.            #
:#                  For example, printing a string with length between 74-79  #
:#                  will not work properly in a 80-columns console.           #
:#                                                                            #
:#  History                                                                   #
:#   2011-03-17 JEB Published the first sample on stackoverflow.com           #
:#   2012-04-30 JEB Added support for strings containing invalid file name    #
:#                  characters, by using the \..\x suffix.                    #
:#   2012-05-02 DB  Added support for strings that contain additional path    #
:#                  levels, like: "a\b\" "a/b/" "\" "/" "." ".." "c:"         #
:#                  Store the temp file on %TEMP%, which is always writable.  #
:#                  Created 2 variants, one takes a string literal, the other #
:#                  the name of a variable containing the string. The variable#
:#                  version is generally less convenient, but it eliminates   #
:#                  some special character escape issues.                     #
:#                  Added the /n option as an optional 3rd parameter to       #
:#                  append a newline at the end of the output.                #
:#   2012-09-26 JFL Renamed routines as object-oriented Echo.Methods.         #
:#                  Added routines Echo.Success, Echo.Warning, Echo.Failure.  #
:#   2012-10-02 JFL Renamed variable DEL as ECHO.DEL to avoid name collisions.#
:#                  Removed the . in the temp file. findstr can search a BS.  #
:#                  Removed a call level to improve performance a bit.        #
:#                  Added comments.                                           #
:#                  New implementation not using a temporary file.            #
:#   2012-10-06 JFL Fixed the problem with displaying "!".                    #
:#   2012-11-13 JFL Copy the string into the log file, if defined.            #
:#                                                                            #
:#----------------------------------------------------------------------------#

call :Echo.Color.Init
goto Echo.Color.End

:Echo.Color %1=Color %2=Str [%3=/n]
:# Temporarily disable expansion to preserve ! in the input string
setlocal disableDelayedExpansion
set "str=%~2"
:Echo.Color.2
setlocal enableDelayedExpansion
if defined LOGFILE %>>LOGFILE% <NUL set /P =!str!
:# Replace path separators in the string, so that the final path still refers to the current path.
set "str=a%ECHO.DEL%!str:\=a%ECHO.DEL%\..\%ECHO.DEL%%ECHO.DEL%%ECHO.DEL%!"
set "str=!str:/=a%ECHO.DEL%/..\%ECHO.DEL%%ECHO.DEL%%ECHO.DEL%!"
set "str=!str:"=\"!"
:# Go to the script directory and search for the trailing -
pushd "%ECHO.DIR%"
findstr /p /r /a:%~1 "^^-" "!str!\..\!ECHO.FILE!" nul
popd
:# Remove the name of this script from the output. (Dependant on its length.)
for /l %%n in (1,1,24) do if not "!ECHO.FILE:~%%n!"=="" <nul set /p "=%ECHO.DEL%"
:# Remove the other unwanted characters "\..\: -"
<nul set /p "=%ECHO.DEL%%ECHO.DEL%%ECHO.DEL%%ECHO.DEL%%ECHO.DEL%%ECHO.DEL%%ECHO.DEL%"
:# Append the optional CRLF
if not "%~3"=="" echo.&if defined LOGFILE %>>LOGFILE% echo.
endlocal & endlocal & goto :eof

:Echo.Color.Var %1=Color %2=StrVar [%3=/n]
if not defined %~2 goto :eof
setlocal enableDelayedExpansion
set "str=!%~2!"
goto :Echo.Color.2

:Echo.Color.Init
set "ECHO.COLOR=call :Echo.Color"
set "ECHO.DIR=%~dp0"
set "ECHO.FILE=%~nx0"
:# Use prompt to store a backspace into a variable. (Actually backspace+space+backspace)
for /F "tokens=1 delims=#" %%a in ('"prompt #$H# & echo on & for %%b in (1) do rem"') do set "ECHO.DEL=%%a"
goto :eof

:Echo.Color.End

:#----------------------------------------------------------------------------#

:Echo.Color.Test
setlocal disableDelayedExpansion
%ECHO.COLOR% 0a "a"
%ECHO.COLOR% 0b "b"
set "txt=^" & %ECHO.COLOR%.Var 0c txt
%ECHO.COLOR% 0d "<"
%ECHO.COLOR% 0e ">"
%ECHO.COLOR% 0f "&"
%ECHO.COLOR% 1a "|"
%ECHO.COLOR% 1b " "
%ECHO.COLOR% 1c "%%%%" & rem # Escape the '%' character
%ECHO.COLOR% 1d ^""" & rem # Escape the '"' character
%ECHO.COLOR% 1e "*"
%ECHO.COLOR% 1f "?"
%ECHO.COLOR% 2a "!" & rem # This one does not need escaping in disableDelayedExpansion mode
%ECHO.COLOR% 2b "."
%ECHO.COLOR% 2c ".."
%ECHO.COLOR% 2d "/"
%ECHO.COLOR% 2e "\"
%ECHO.COLOR% 2f "q:" /n
echo.
set complex="c:\hello world!/.\..\\a//^<%%>&|!" /^^^<%%^>^&^|!\
%ECHO.COLOR%.Var 74 complex /n
goto :eof

:# Experimental code that does not work...
:# Check if this script contains a trailing :eof. If not, add one.
set "ECHO.FULL=%ECHO.DIR%%ECHO.FILE%"
findstr /r "^^-" "%ECHO.FULL%" >NUL 2>&1
if errorlevel 1 (
  >&2 echo Notice: Adding the missing - at the end of this script
  >>"%ECHO.FULL%" echo goto :eof
  >>"%ECHO.FULL%" <nul set /p "=-"
) else (
echo three
  for /f "delims=" %%s in ('findstr /r "^-" "%ECHO.FULL%"') do set "ECHO.TMP=%%s"
  %ECHOVARS% ECHO.TMP
)
  if not "%ECHO.TMP:~1%"=="" >&2 echo Error: Please remove all CRLF after the trailing -

:#----------------------------------------------------------------------------#

:# Initial implementation with a temporary file %TEMP%\x containing backspaces

:Echo.Color1 %1=Color %2=Str [%3=/n]
setlocal enableDelayedExpansion
set "str=%~2"
set "strvar=str"
goto :Echo.Color1.2

:Echo.Color1.Var %1=Color %2=StrVar [%3=/n]
if not defined %~2 goto :eof
setlocal enableDelayedExpansion
set "strvar=%~2"
:Echo.Color1.2
:# Replace path separators in the string, so that they still refer to the current path.
set "str=a%ECHO.DEL%!%strvar%:\=a%ECHO.DEL%\..\%ECHO.DEL%%ECHO.DEL%%ECHO.DEL%!"
set "str=!str:/=a%ECHO.DEL%/..\%ECHO.DEL%%ECHO.DEL%%ECHO.DEL%!"
set "str=!str:"=\"!"
pushd "%TEMP%"
findstr /P /L /A:%~1 "%ECHO.BS%" "!str!\..\x" nul
popd
if not "%~3"=="" echo.
endlocal & goto :eof

:Echo.Color1.Init
set "ECHO.COLOR=call :Echo.Color"
:# Use prompt to store a backspace into a variable. (Actually backspace+space+backspace)
for /F "tokens=1 delims=#" %%a in ('"prompt #$H# & echo on & for %%b in (1) do rem"') do set "ECHO.DEL=%%a"
set "ECHO.BS=%ECHO.DEL:~0,1%"
:# Generate a temp file containing backspaces. This content will be used later to post-process the findstr output.
<nul >"%TEMP%\x" set /p "=%ECHO.DEL%%ECHO.DEL%%ECHO.DEL%%ECHO.DEL%%ECHO.DEL%%ECHO.DEL%"
goto :eof

:Echo.Color1.Cleanup
del "%TEMP%\x"
goto :eof

:#----------------------------------------------------------------------------#

:Echo.Success
%ECHO.COLOR% 02 [Success] /n
goto :eof

:Echo.Warning
%ECHO.COLOR% 06 [Warning] /n
goto :eof

:Echo.Failure
%ECHO.COLOR% 04 [Failure] /n
goto :eof

:#----------------------------------------------------------------------------#
:#                                                                            #
:#  Function        EchoF						      #
:#                                                                            #
:#  Description     Echo a string with several formatted fields               #
:#                                                                            #
:#  Arguments       %1	    Format string with columns width and alignment    #
:#                          Ex: "[-10][10][10]"				      #
:#                  %*	    Optional substrings to format                     #
:#                                                                            #
:#  Notes 	    Inspired from C printf routine.                           #
:#                                                                            #
:#                  Prefix all local variable names with a character that     #
:#                  cannot be used in %%N loop variables. The ";" here.       #
:#                  This avoids a bug when this routine is invoked from       #
:#                  within a loop, where that loop variable uses the first    #
:#                  letter of one of our variables.                           #
:#                                                                            #
:#                  Limitations                                               #
:#                  - Can format at most 8 strings.                           #
:#                  - The format string cannot contain | < > &                #
:#                  - Each formatted field can be at most 53 characters long. #
:#                                                                            #
:#  History                                                                   #
:#   2006-01-01     Created Format on http://www.dostips.com                  #
:#   2009-11-30     Changed                                                   #
:#   2012-10-25 JFL Adapted to my usual style and renamed as EchoF.           #
:#                  Fixed bug when invoked in a loop on %%c or %%l, etc...    #
:#                  Added the option to have an unspecified width: []         #
:#                                                                            #
:#----------------------------------------------------------------------------#

:EchoF.Init
set "ECHOF=call :EchoF"
goto :eof

:EchoF fmt str1 str2 ... -- outputs columns of strings right or left aligned
::                       -- fmt [in] - format string specifying column width and alignment. Ex: "[-10] / [10] / []"
:$created 20060101 :$changed 20091130 :$categories Echo
:# Updated 20121026 JFL: Added tons of comments.
:#                       Fixed a bug if invoked in a loop on %%c or %%f or %%l or %%s or %%i.
:#                       Added an unspecified width format []. Useful for the last string.
:$source http://www.dostips.com
setlocal EnableExtensions DisableDelayedExpansion
set ";fmt=%~1" &:# Format string
set ";line="   &:# Output string. Initially empty.
set ";spac=                                                     "
set ";i=1"     &:# Argument index. 1=fmt; 2=str1; ...
:# %ECHOVARS.D% ";fmt" ";line" ";spac" ";i"
:# For each substring in fmt split at each "]"... (So looking like "Fixed text[SIZE]".) 
for /f "tokens=1,2 delims=[" %%a in ('"echo..%;fmt:]=&echo..%"') do ( :# %%a=Fixed text before "["; %%b=size after "["
  call set /a ";i=%%;i%%+1"                            &:# Compute the next str argument index.
  call call set ";subst=%%%%~%%;i%%%;spac%%%%%~%%;i%%" &:# Append that str at both ends of the spacer
:# %ECHOVARS.D% ";i" ";subst"
  if "%%b"=="" (         :# Unspecified width. Use the string as it is.
    call call set ";subst=%%%%~%%;i%%" 
  ) else if %%b0 GEQ 0 ( :# Cut a left-aligned field at the requested size.
    call set ";subst=%%;subst:~0,%%b%%"
  ) else (               :# Cut a right-aligned field at the requested size.
    call set ";subst=%%;subst:~%%b%%"
  )
  call set ";const=%%a" &:# %%a=Fixed text before "[". Includes an extra dot at index 0.
  call set ";line=%%;line%%%%;const:~1%%%%;subst%%" &:# Append the fixed text, and the formated string, to the output line.
:# %ECHOVARS.D% ";subst" ";const" ";line"
)
echo.%;line%
endlocal & exit /b

:# Original Format function from dostips.com

:Format fmt str1 str2 ... -- outputs columns of strings right or left aligned
::                        -- fmt [in] - format string specifying column width and alignment, i.e. "[-10][10][10]"
:$created 20060101 :$changed 20091130 :$categories Echo
:$source http://www.dostips.com
SETLOCAL
set "fmt=%~1"
set "line="
set "spac=                                                     "
set "i=1"
for /f "tokens=1,2 delims=[" %%a in ('"echo..%fmt:]=&echo..%"') do (
    set /a i+=1
    call call set "subst=%%%%~%%i%%%spac%%%%%~%%i%%"
    if %%b0 GEQ 0 (call set "subst=%%subst:~0,%%b%%"
    ) ELSE        (call set "subst=%%subst:~%%b%%")
    call set "const=%%a"
    call set "line=%%line%%%%const:~1%%%%subst%%"
)
echo.%line%
EXIT /b

:#----------------------------------------------------------------------------#
:#                                                                            #
:#  Function        strlen						      #
:#                                                                            #
:#  Description     Measure the length of a string                            #
:#                                                                            #
:#  Arguments       %1	    String variable name                              #
:#                  %2	    Ouput variable name                               #
:#                                                                            #
:#  Notes 	    Inspired from C string management routines                #
:#                                                                            #
:#                  Many thanks to 'sowgtsoi', but also 'jeb' and 'amel27'    #
:#		    dostips forum users helped making this short and efficient#
:#  History                                                                   #
:#   2008-11-22     Created on dostips.com.                                   #
:#   2010-11-16     Changed.                                                  #
:#   2012-10-08 JFL Adapted to my %FUNCTION% library.                         #
:#   2015-11-19 JFL Adapted to new %UPVAR% mechanism.                         #
:#                                                                            #
:#----------------------------------------------------------------------------#

:strlen stringVar lenVar                -- returns the length of a string
%FUNCTION% enabledelayedexpansion
set "RETVAR=%~2"
if "%RETVAR%"=="" set "RETVAR=RETVAL"
set "str=A!%~1!" &:# keep the A up front to ensure we get the length and not the upper bound
		  :# it also avoids trouble in case of empty string
set "len=0"
for /L %%A in (12,-1,0) do (
  set /a "len|=1<<%%A"
  for %%B in (!len!) do if "!str:~%%B,1!"=="" set /a "len&=~1<<%%A"
)
set "%RETVAR%=%len%" & %UPVAR% %RETVAR% & %RETURN%

:#----------------------------------------------------------------------------#
:#                                                                            #
:#  Function        strcpy						      #
:#                                                                            #
:#  Description     Copy the content of a variable into another one           #
:#                                                                            #
:#  Arguments       %1	    Destination variable name                         #
:#                  %2	    Source variable name                              #
:#                                                                            #
:#  Notes 	    Inspired from C string management routines                #
:#                                                                            #
:#                  Features:						      #
:#                  - Supports empty strings (if %2 is undefined, %1 will too)#
:#                  - Supports strings including balanced quotes	      #
:#                  - Supports strings including special characters & and |   #
:#                                                                            #
:#  History                                                                   #
:#                                                                            #
:#----------------------------------------------------------------------------#

:# Copy the content of a variable into another one
:# %1 = Destination variable name
:# %2 = Source variable name
:strcpy
%FUNCTION%
if not "%~1"=="%~2" call set "%~1=%%%~2%%"
%ECHOVARS.D% "%~1"
%RETURN%

:# Append the content of a variable to another one
:# %1 = Destination variable name
:# %2 = Source variable name
:strcat
%FUNCTION%
call set "%~1=%%%~1%%%%%~2%%"
%ECHOVARS.D% "%~1"
%RETURN%

:#----------------------------------------------------------------------------#
:#                                                                            #
:#  Function        strlwr						      #
:#                                                                            #
:#  Description     Convert a variable content to lower case		      #
:#                                                                            #
:#  Arguments       %1	    Variable name                                     #
:#                                                                            #
:#  Notes 	    Inspired from C string management routines                #
:#                                                                            #
:#  History                                                                   #
:#                                                                            #
:#----------------------------------------------------------------------------#

:# Convert a variable content to lower case
:# %1 = Variable name
:strlwr
%FUNCTION%
if not defined %~1 %RETURN%
for %%a in ("A=a" "B=b" "C=c" "D=d" "E=e" "F=f" "G=g" "H=h" "I=i"
            "J=j" "K=k" "L=l" "M=m" "N=n" "O=o" "P=p" "Q=q" "R=r"
            "S=s" "T=t" "U=u" "V=v" "W=w" "X=x" "Y=y" "Z=z" "�=�"
            "�=�" "�=�" "�=�" "�=�" "�=�" "�=�" "�=�" "�=�" "�=�"
            "�=�" "�=�" "�=�" "�=�" "�=�" "�=�" "�=�" "�=�") do (
  call set "%~1=%%%~1:%%~a%%"
)
%ECHOVARS.D% "%~1"
%RETURN%

:# Convert a variable content to upper case
:# %1 = Variable name
:strupr
%FUNCTION%
if not defined %~1 %RETURN%
for %%a in ("a=A" "b=B" "c=C" "d=D" "e=E" "f=F" "g=G" "h=H" "i=I"
            "j=J" "k=K" "l=L" "m=M" "n=N" "o=O" "p=P" "q=Q" "r=R"
            "s=S" "t=T" "u=U" "v=V" "w=W" "x=X" "y=Y" "z=Z" "�=�"
            "�=�" "�=�" "�=�" "�=�" "�=�" "�=�" "�=�" "�=�" "�=�"
            "�=�" "�=�" "�=�" "�=�" "�=�" "�=�" "�=�" "�=�") do (
  call set "%~1=%%%~1:%%~a%%"
)
%ECHOVARS.D% "%~1"
%RETURN%

:#----------------------------------------------------------------------------#
:#                                                                            #
:#  Function        trim						      #
:#                                                                            #
:#  Description     Trim spaces (or other chars.) from the ends of a string   #
:#                                                                            #
:#  Arguments       %1	    Variable name                                     #
:#                  %2	    Characters to be trimmed. Default: space and tab  #
:#                                                                            #
:#  Notes 	    Inspired from Tcl string timming routines                 #
:#                                                                            #
:#  History                                                                   #
:#   2012-11-09 JFL  Disable delayed expansion to support strings with !s.    #
:#                   Fixed the debug output for the returned value.           #
:#   2015-11-19 JFL Adapted to new %UPVAR% mechanism.                         #
:#                                                                            #
:#----------------------------------------------------------------------------#

:# Trim spaces (or other characters) from the beginning of a string
:# %1 = String variable to be trimmed
:# %2 = Characters to be trimmed. Default: space and tab
:trimleft
%FUNCTION% EnableExtensions DisableDelayedExpansion
if not defined %~1 %RETURN%
call set "string=%%%~1%%"
set "chars=%~2"
if not defined chars set "chars=	 "
:# %ECHOVARS.D% %~1 chars
for /f "tokens=* delims=%chars%" %%a in ("%string%") do set "string=%%a"
%UPVAR% %~1
set "%~1=%string%"
%RETURN%

:# Trim spaces (or other characters) from the end of a string
:# %1 = String variable to be trimmed
:# %2 = Characters to be trimmed. Default: space and tab
:trimright
%FUNCTION% EnableExtensions DisableDelayedExpansion
if not defined %~1 %RETURN%
call set "string=%%%~1%%"
set "chars=%~2"
if not defined chars set "chars=	 "
:# %ECHOVARS.D% RETVAR %~1 string chars DEBUG.RETVARS
:trimright_loop
if not defined string goto trimright_exit
for /f "delims=%chars%" %%a in ("%string:~-1%") do goto trimright_exit
set "string=%string:~0,-1%"
goto trimright_loop
:trimright_exit
%UPVAR% %~1
set "%~1=%string%"
%RETURN%

:# Trim spaces (or other characters) from both ends of a string
:# %1 = String variable to be trimmed
:# %2 = Characters to be trimmed. Default: space and tab
:trim
%FUNCTION%
if not defined %~1 %RETURN%
call :trimleft "%~1" "%~2"
call :trimright "%~1" "%~2"
%UPVAR% %~1
%RETURN%

:#----------------------------------------------------------------------------#
:#                                                                            #
:#  Function        list						      #
:#                                                                            #
:#  Description     List management routines                                  #
:#                                                                            #
:#  Arguments                                                                 #
:#                                                                            #
:#  Notes 	    Inspired from Tcl list management routines                #
:#                                                                            #
:#  History                                                                   #
:#                                                                            #
:#----------------------------------------------------------------------------#

:# Append an element to a list
:# %1 = Input/Output variable name
:# %2 = element value
:lappend
%FUNCTION%
%UPVAR% %~1
if defined %~1 call set "%~1=%%%~1%% "
call set "%~1=%%%~1%%"%~2""
%RETURN%

:# Split a string into a list of quoted substrings
:# %1 = Output variable name
:# %2 = Intput variable name
:# %3 = Characters separating substrings. Default: space and tab
:split
%FUNCTION%
if "%~2"=="" %RETURN%
setlocal
call set "string=%%%~2%%"
set "chars=%~3"
if not defined chars set "chars=	 "
set "list="
if not defined string goto split_exit
:# If the string begins with separator characters, begin the list with an empty substring.
set head_chars=true
for /f "delims=%chars%" %%a in ("%string:~0,1%") do set head_chars=false
if %head_chars%==true (
  call :lappend list ""
  :# Remove the head separators. Necessary to correctly detect the tail separators.
  for /f "tokens=* delims=%chars%" %%a in ("%string%") do set "string=%%a"
)
if not defined string goto split_exit
:# If the string ends with separator characters, prepare to append an empty substring to the list.
set tail_chars=true
for /f "delims=%chars%" %%a in ("%string:~-1%") do set tail_chars=false
:# Main loop splitting substrings and appending them to the list.
:split_loop
for /f "tokens=1* delims=%chars%" %%a in ("%string%") do (
  call :lappend list "%%a"
  set "string=%%b"
  goto split_loop
)
if %tail_chars%==true call :lappend list ""
:split_exit
%UPVAR% %~1
set "%~1=%list%"
%RETURN%

:foreach
%FUNCTION% %1=Loop_var_name %2=Values_list %3=Block of code
call set "foreach_list=%%%2%%"
for %%i in (%foreach_list%) do (set "%1=%%i" & %~3)
%RETURN%

:#----------------------------------------------------------------------------#
:#                                                                            #
:#  Function        condquote                                                 #
:#                                                                            #
:#  Description     Add quotes around the content of a pathname if needed     #
:#                                                                            #
:#  Arguments       %1	    Source variable name                              #
:#                  %2	    Destination variable name (optional)              #
:#                                                                            #
:#  Notes 	    Quotes are necessary if the pathname contains special     #
:#                  characters, like spaces, &, |, etc.                       #
:#                                                                            #
:#                  See "cmd /?" for information about characters needing to  #
:#                  be quoted.                                                #
:#                  I've added "@" that needs quoting if first char in cmd.   #
:#                  I've removed "!" as quoting does NOT prevent expansions.  #
:#                                                                            #
:#  History                                                                   #
:#   2010-12-19 JFL Created this routine                                      #
:#   2011-12-12 JFL Rewrote using findstr. (Executes much faster.)	      #
:#		    Added support for empty pathnames.                        #
:#                                                                            #
:#----------------------------------------------------------------------------#

:# Quote file pathnames that require it. %1=Input variable. %2=Opt. output variable.
:condquote
%FUNCTION% enableextensions enabledelayedexpansion
set RETVAR=%~2
if "%RETVAR%"=="" set RETVAR=%~1
set "P=!%~1!"
:# If the value is empty, don't go any further.
if not defined P set "P=""" & goto :condquote_ret
:# Remove double quotes inside P. (Fails if P is empty)
set "P=%P:"=%"
:# If the value is empty, don't go any further.
if not defined P set "P=""" & goto :condquote_ret
:# Look for any special character that needs quoting
echo."%P%"|findstr /C:" " /C:"&" /C:"(" /C:")" /C:"@" /C:"," /C:";" /C:"[" /C:"]" /C:"{" /C:"}" /C:"=" /C:"'" /C:"+" /C:"`" /C:"~" >NUL
if not errorlevel 1 set P="%P%"
:condquote_ret
%UPVAR% %RETVAR%
%RETURN%

:condquote2
%FUNCTION%
setlocal enableextensions enabledelayedexpansion
set RETVAR=%~2
if "%RETVAR%"=="" set RETVAR=%~1
set "P=!%~1!"
:# If the value is empty, don't go any further.
if not defined P set "P=""" & goto :condquote_ret
:# Remove double quotes inside P. (Fails if P is empty)
set "P=%P:"=%"
:# If the value is empty, don't go any further.
if not defined P set "P=""" & goto :condquote_ret
:# Look for any special character that needs quoting
echo."%P%"|findstr /C:" " /C:"&" /C:"(" /C:")" /C:"@" /C:"," /C:";" /C:"[" /C:"]" /C:"{" /C:"}" /C:"=" /C:"'" /C:"+" /C:"`" /C:"~" >NUL
if not errorlevel 1 set P="%P%"
:condquote_ret
:# Contrary to the general rule, do NOT enclose the set commands below in "quotes",
:# because this interferes with the quoting already added above. This would
:# fail if the quoted string contained an & character.
:# But because of this, do not leave any space around & separators.
endlocal&set RETVAL=%P%&set %RETVAR%=%P%&%RETURN%

:#----------------------------------------------------------------------------#
:# Older implementation (More complex, but actually just as fast)

:# Quote file pathnames that require it. %1=Input variable. %2=Opt. output variable.
:condquote1
%FUNCTION%
setlocal enableextensions
call set "P=%%%~1%%"
:# If the value is empty, don't go any further.
if not defined P set "P=""" & goto :condquote_ret
:# Remove double quotes inside P. (Fails if P is empty)
set "P=%P:"=%"
:# If the value is empty, don't go any further.
if not defined P set "P=""" & goto :condquote_ret
set RETVAR=%~2
if "%RETVAR%"=="" set RETVAR=%~1
for %%c in (" " "&" "(" ")" "@" "," ";" "[" "]" "{" "}" "=" "'" "+" "`" "~") do (
  :# Note: Cannot directly nest for loops, due to incorrect handling of /f in the inner loop.
  cmd /c "for /f "tokens=1,* delims=%%~c" %%a in (".%%P%%.") do @if not "%%b"=="" exit 1"
  if errorlevel 1 (
    set P="%P%"
    goto :condquote_ret
  )
)
:condquote_ret
:# Contrary to the general rule, do NOT enclose the set command below in "quotes",
:# because this interferes with the quoting already added above. This would
:# fail if the quoted string contained an & character.
:# But because of this, do not leave any space around & separators.
endlocal&set RETVAL=%P%&set %RETVAR%=%P%&%RETURN%

:#----------------------------------------------------------------------------#
:#                                                                            #
:#  Function        time                                                      #
:#                                                                            #
:#  Description     Functions for manipulating date and time.                 #
:#                                                                            #
:#  Arguments       echotime        Display the current time                  #
:#                                                                            #
:#  Notes 	                                                              #
:#                                                                            #
:#  History                                                                   #
:#                                                                            #
:#----------------------------------------------------------------------------#

:# Display the current time. Useless, except for a comparison with the next function.
:echotime
%FUNCTION%
echo %TIME%
%RETURN%

:echotime
%FUNCTION%
:# Get the time; Keep only the line with numbers; Display only what follows ": ".
@for /f "tokens=1,* delims=:" %%a in ('echo.^|time^|findstr [0-9]') do @echo%%b
%RETURN%

:#----------------------------------------------------------------------------#
:#                                                                            #
:#  Function        sleep                                                     #
:#                                                                            #
:#  Description     Sleep N seconds				              #
:#                                                                            #
:#  Arguments       %1        Number of seconds to wait                       #
:#                                                                            #
:#  Notes 	                                                              #
:#                                                                            #
:#  History                                                                   #
:#   2012-07-10 JFL Add 1 to the argument, because the 1st ping delays 0 sec. #
:#   2015-11-19 JFL Adapted to new %UPVAR% mechanism.                         #
:#                                                                            #
:#----------------------------------------------------------------------------#

:goto :Sleep.End

:# Sleep N seconds. %1 = Number of seconds to wait.
:Sleep
%FUNCTION%
set /A N=%1+1
ping -n %N% 127.0.0.1 >NUL 2>&1
%RETURN%

:Sleep.End

:#----------------------------------------------------------------------------#
:#                                                                            #
:#  Function        GetPid                                                    #
:#                                                                            #
:#  Description     Get the PID and title of the current console              #
:#                                                                            #
:#  Arguments                                                                 #
:#                                                                            #
:#  Notes 	                                                              #
:#                                                                            #
:#  History                                                                   #
:#   2015-11-19 JFL Adapted to new %UPVAR% mechanism.                         #
:#                                                                            #
:#----------------------------------------------------------------------------#

:# Function GetProcess: Set PID and TITLE with the current console PID and title string.
:GetProcess
%FUNCTION% enableextensions
if not defined ARG0 >&2 echo Function GetProcess error: Please set "ARG0=%%~0" in script initialization. & %RETURN% 1
:# Get the list of command prompts titles
for /f "tokens=2,9*" %%a in ('tasklist /v /nh /fi "IMAGENAME eq cmd.exe"') do set TITLE.%%a=%%c
:# Change the current title to a statistically unique value
for /f "tokens=2 delims=.," %%A IN ("%TIME%") DO set RDMTITLE=%%A %RANDOM% %RANDOM% %RANDOM% %RANDOM%
%ECHOVARS.D% RDMTITLE
title %RDMTITLE%
:# Find our PID
set N=3
:GetProcessAgain
:# Note: Do not filter by title, because when running as administrator, there's a prefix: Administrator:
:#       And at any time, there's a temporary suffix: The name of the running script (This very script!) and its arguments.
:# for /f "tokens=2" %%a in ('tasklist /v /nh /fi "WINDOWTITLE eq %RDMTITLE%"') do set PID=%%a
for /f "tokens=2,9*" %%a in ('tasklist /v /nh /fi "IMAGENAME eq cmd.exe" ^| findstr "%RDMTITLE%"') do set "PID=%%a" & set "TITLENOW=%%c"
:# Gotcha: Sometimes the above command returns a wrong TITLENOW, containing "N/A". (What would it be in localized versions of Windows?)
:# Maybe there's a small (variable?) delay before and entry with the new title appears in Windows task list?
:# Maybe it's another instance with the findstr command itself that disrupts the test?
:# Anyway, double check the result, and try again up to 3 times if it's bad. 
echo "%TITLENOW%" | findstr "%RDMTITLE%" >nul
if errorlevel 1 (
  if .%DEBUG%.==.1. (
    >&2 echo Warning: Wrong title: %TITLENOW%
    :# Note: This tasklist has never returned an entry with N/A, but tests with teeing the initial tasklist above have.
    tasklist /v /nh /fi "IMAGENAME eq cmd.exe"
  )
  if not %N%==0 (
    if .%DEBUG%.==.1. >&2 echo Scan cmd.exe windows titles again.
    set /a N=N-1
    goto GetProcessAgain
  )
  >&2 echo Function GetProcess error: Failed to identify the current process title.
  title ""
  %RETURN% 1
)
%ECHOVARS.D% PID TITLENOW
:# Parse the actual title now. (May differ from the one we set, due to an additional Administrator: prefix.)
:# If we find such a prefix, then assume the initial title had that same prefix.
call :trimright TITLENOW
:# Find our initial title
call set TITLE=%%TITLE.%PID%%%
set TITLE=%TITLE:"=''% &:# Remove quotes, which may be unmatched, and confuse the %RETURN% macro
%ECHOVARS.D% TITLE
call :trimright TITLE
:# Find the possible title prefix and suffix
%ECHO.D% call set "PREFIX=%%TITLENOW:%RDMTITLE%=";rem %%
call set "PREFIX=%%TITLENOW:%RDMTITLE%=";rem %%
%ECHOVARS.D% PREFIX
:# Now trim the possible prefix and suffix from the title
:# In the absence of a special char (like ^) to anchor the match string at the beginning,
:# prefix the prefix with our random string, to avoid problems if the prefix string is repeated elsewhere in the string
:# Additional gotcha: Initially there's 1 space between the prefix and title; 
:# but the title command always ends up putting 2 spaces there. So erase all spaces there.
call :trimright PREFIX
set "TITLE=%RDMTITLE% %TITLE%"
call set "TITLE=%%TITLE:%RDMTITLE% %PREFIX%=%%"
%ECHOVARS.D% TITLE
call :trimleft TITLE
:# Remove the suffix from the title. Else if we leave it and restore the title with
:# that suffix, then the suffix will remain after the script exits.
set "SUFFIX=%RDMTITLE% %TITLE%"
call set "TITLE=%%TITLE: - %ARG0%=";rem %%
%ECHOVARS.D% TITLE
call set "SUFFIX=%%SUFFIX:%RDMTITLE% %TITLE%=%%"
%ECHOVARS.D% SUFFIX
call :trimleft SUFFIX
:# Restore the title
title %TITLE%
%UPVAR% PID TITLE PREFIX SUFFIX
%RETURN% 0

:GetPid
%FUNCTION% enableextensions
:# Get the list of command prompts
for /f "tokens=2,9*" %%a in ('tasklist /v /nh /fi "IMAGENAME eq cmd.exe"') do set TITLE.%%a=%%c
:# Change the current title to a random value
set TITLE=%RANDOM% %RANDOM% %RANDOM% %RANDOM%
title %TITLE%
:# Find our PID
set PID=0
:GetPidAgain
for /f "tokens=2" %%a in ('tasklist /v ^| findstr "%TITLE%"') do set PID=%%a
if %PID%==0 goto GetPidAgain
:# Find our initial title
call set TITLE=%%TITLE.%PID%%%
:# Restore the title
title %TITLE%
%UPVAR% PID TITLE
%RETURN%

:#----------------------------------------------------------------------------#
:#                                                                            #
:#  Function        IsAdmin                                                   #
:#                                                                            #
:#  Description     Test if the user has administration rights                #
:#                                                                            #
:#  Arguments                                                                 #
:#                                                                            #
:#  Notes 	    Returns the result in %ERRORLEVEL%: 0=Yes; 5=No           #
:#                                                                            #
:#  History                                                                   #
:#                                                                            #
:#----------------------------------------------------------------------------#

:IsAdmin
>NUL 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
goto :eof

:IsAdmin
>NUL 2>&1 net session
goto :eof

:RunAsAdmin
:# adaptation of https://sites.google.com/site/eneerge/home/BatchGotAdmin and http://stackoverflow.com/q/4054937
:# Check for ADMIN Privileges
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
  REM Get ADMIN Privileges
  echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
  echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
  "%temp%\getadmin.vbs"
  del "%temp%\getadmin.vbs"
  exit /B
) else (
  REM Got ADMIN Privileges
  pushd "%cd%"
  cd /d "%~dp0"
)
goto :eof

:#----------------------------------------------------------------------------#
:#                                                                            #
:#  Function        chcp / rscp                                               #
:#                                                                            #
:#  Description     Change/restore the code page                              #
:#                                                                            #
:#  Arguments                                                                 #
:#                                                                            #
:#  Notes 	    chcp saves the initial code page into variable OLDCP.     #
:#                  rscp restores it from that variable.                      #
:#                                                                            #
:#  History                                                                   #
:#                                                                            #
:#----------------------------------------------------------------------------#

:# Under NT, save the initial code page, and change it to Windows 1252 code page.
:chcp
if not "%OS%"=="Windows_NT" goto skipchcp
for /f "tokens=2 delims=:" %%n in ('chcp') do set OLDCP=%%n
chcp 1252
:skipchcp

:# Restore the initial code page
:rscp
if not "%OS%"=="Windows_NT" goto skiprscp
chcp %OLDCP%
:skiprscp

:#----------------------------------------------------------------------------#
:#                                                                            #
:#  Function        FOREACHLINE                                               #
:#                                                                            #
:#  Description     Repeat a block of code for each line in a text file       #
:#                                                                            #
:#  Arguments                                                                 #
:#                                                                            #
:#  Notes 	    :# Example d'utilisation                                  #
:#                  %FOREACHLINE% %%l in ('%CMD%') do (                       #
:#                    set "LINE=%%l"                                          #
:#                    echo Notice: !LINE!                                     #
:#                  )                                                         #
:#                                                                            #
:#  History                                                                   #
:#                                                                            #
:#----------------------------------------------------------------------------#

:# FOREACHLINE macro. (Change the delimiter to none to catch the whole lines.)
set FOREACHLINE=for /f "delims="

:#----------------------------------------------------------------------------#
:#                                                                            #
:#  Function        path_depth                                                #
:#                                                                            #
:#  Description     Compute the depth of a pathname                           #
:#                                                                            #
:#  Arguments       %1	    pathname                                          #
:#                                                                            #
:#  Notes 	    Ex: A\B\C -> 3 ; \A -> 1 ; A\ -> 1                        #
:#                                                                            #
:#  History                                                                   #
:#   2011-12-12 JFL Created this routine                                      #
:#   2015-11-19 JFL Adapted to new %UPVAR% mechanism.                         #
:#                                                                            #
:#----------------------------------------------------------------------------#

:# Compute the depth of a pathname. %1=pathname. Ex: A\B\C -> 3 ; \A -> 1 ; A\ -> 1
:path_depth
%FUNCTION%
if not "%~2"=="" set "RETVAR=%~2"
call :path_depth2 %*
%UPVAR% %RETVAR%
set %RETVAR%=%RETVAL%
%RETURN%

:# Worker routine, with call/return trace disabled, to avoid tracing recursion.
:path_depth2
set "ARGS=%~1"
set ARGS="%ARGS:\=" "%"
set ARGS=%ARGS:""=%
set RETVAL=0
for %%i in (%ARGS%) do @set /a RETVAL=RETVAL+1
goto :eof

:#----------------------------------------------------------------------------#
:# First implementation, 50% slower.

:path_depth1
set RETVAL=0
for /f "tokens=1* delims=\" %%i in ("%~1") do (
  if not "%%j"=="" call :path_depth1 "%%j"
  if not "%%i"=="" set /a RETVAL=RETVAL+1
)
goto :eof

:#----------------------------------------------------------------------------#
:#                                                                            #
:#  Function        is_dir						      #
:#                                                                            #
:#  Description     Check if a pathname refers to an existing directory       #
:#                                                                            #
:#  Arguments       %1	    pathname                                          #
:#                                                                            #
:#  Notes 	    Returns errorlevel 0 if it's a valid directory.           #
:#                                                                            #
:#  History                                                                   #
:#   2013-08-27 JFL Created this routine.                                     #
:#   2015-11-19 JFL Adapted to new %UPVAR% mechanism.                         #
:#                                                                            #
:#----------------------------------------------------------------------------#

:is_dir pathname       -- Check if a pathname refers to an existing directory
%FUNCTION%
pushd "%~1" 2>NUL
if errorlevel 1 (
  set "ERROR=1"
) else (
  set "ERROR=0"
  popd
)
%RETURN% %ERROR%

:#----------------------------------------------------------------------------#
:#                                                                            #
:#  Function        basename						      #
:#                                                                            #
:#  Description     Get the file name part of a pathname                      #
:#                                                                            #
:#  Arguments       %1	    Input pathname variable name                      #
:#                  %2	    Ouput file name variable name                     #
:#                                                                            #
:#  Notes 	    Inspired from Unix' basename command                      #
:#                                                                            #
:#                  Works even when the base name contains wild cards,        #
:#                  which prevents using commands such as                     #
:#                  for %%f in (%ARG%) do set NAME=%%~nxf                     #
:#                                                                            #
:#  History                                                                   #
:#   2013-08-27 JFL Created this routine.                                     #
:#                                                                            #
:#----------------------------------------------------------------------------#

:basename pathnameVar filenameVar :# Returns the file name part of the pathname
%FUNCTION% enabledelayedexpansion
set "RETVAR=%~2"
if "%RETVAR%"=="" set "RETVAR=RETVAL"
set "NAME=!%~1!"
:basename.trim_path
set "NAME=%NAME:*\=%"
if not "%NAME%"=="%NAME:\=%" goto :basename.trim_path
%UPVAR% %RETVAR%
set "%RETVAR%=%NAME%"
%RETURN%

:#----------------------------------------------------------------------------#
:#                                                                            #
:#  Function        touch						      #
:#                                                                            #
:#  Description     Pure batch implementation of the Unix touch command       #
:#                                                                            #
:#  Arguments       %1	    file name                                         #
:#                                                                            #
:#  Notes 	    Based on sample in http://superuser.com/a/764725          #
:#                                                                            #
:#                  Creates file if it does not exist.                        #
:#                  Just uses cmd built-ins.                                  #
:#                  Works even on read-only files, like touch does.           #
:#                                                                            #
:#  History                                                                   #
:#   2011-02-16     http://superuser.com/users/201155/bobbogo created this.   #
:#   2015-11-02 JFL Wrapped in a %FUNCTION% with local variables.             #
:#   2015-11-19 JFL Adapted to new %UPVAR% mechanism.                         #
:#                                                                            #
:#----------------------------------------------------------------------------#

:touch
%FUNCTION%
if not exist "%~1" type NUL >>"%~1"& %RETURN%
set _ATTRIBUTES=%~a1
if "%~a1"=="%_ATTRIBUTES:r=%" (copy "%~1"+,,) else attrib -r "%~1" & copy "%~1"+,, & attrib +r "%~1"
%RETURN%

:# Simpler version without read-only file support
:touch
type nul >>"%~1" & copy "%~1",,
goto :eof

:#----------------------------------------------------------------------------#
:#                                                                            #
:#  Function        extensions.test                                           #
:#                                                                            #
:#  Description     Test if cmd extensions work                               #
:#                                                                            #
:#  Arguments                                                                 #
:#                                                                            #
:#  Notes 	    Do not use %FUNCTION% or %RETURN%, as these do require    #
:#                  command extensions to work.                               #
:#                  Only use command.com-compatible syntax!                   #
:#                                                                            #
:#  History                                                                   #
:#   2015-11-23 JFL Renamed, and added :extensions.get and :extensions.show.  #
:#   2015-12-01 JFL Rewrote :extensions.get and :extensions.show as extension #
:#                  and expansion modes are independant of each other. Also   #
:#                  call :extensions.get cannot work if extensions are off.   #
:#                                                                            #
:#----------------------------------------------------------------------------#

:# Get cmd extensions and delayed expansion settings
:extensions.get returns errorlevel=1 if extensions are disabled
ver >NUL &:# Clear the errorlevel
:# Note: Don't use quotes around set commands in the next two lines, as this will not work if extensions are disabled
set EXTENSIONS=DisableExtensions
set DELAYEDEXPANSION=DisableDelayedExpansion
set "EXTENSIONS=EnableExtensions" 2>NUL &:# Fails if extensions are disabled
if "!!"=="" set DELAYEDEXPANSION=EnableDelayedExpansion
goto %EXTENSIONS.RETURN% :eof 2>NUL &:# goto :eof will work, but report an error if extensions are disabled

:# Display cmd extensions and delayed expansion settings
:extensions.show
setlocal &:# Avoid changing the parent environment
set EXTENSIONS.RETURN=:extensions.show.ret
goto :extensions.get &:# call :extensions.get will not work if extensions are disabled
:extensions.show.ret
%ECHO% SetLocal %EXTENSIONS% %DELAYEDEXPANSION%
endlocal &:# Restore the parent environment
goto :eof 2>NUL &:# This goto will work, but report an error if extensions are disabled

:# Test if cmd extensions work (They don't in Windows 2000 and older)
:extensions.test
verify other 2>nul
setlocal enableextensions enabledelayedexpansion
if errorlevel 1 (
  >&2 echo Error: Unable to enable command extensions.
  >&2 echo This script requires Windows XP or later.
  endlocal & set "RETVAL=1" & goto :eof
)
set VAR=before
if "%VAR%" == "before" (
  set VAR=after
  if not "!VAR!" == "after" (
    >&2 echo Error: Failed to enable delayed environment variable expansion.
    >&2 echo This script requires Windows XP or later.
    endlocal & set "RETVAL=1" & goto :eof
  )
)
endlocal & set "RETVAL=0" & goto :eof

:#----------------------------------------------------------------------------#
:#                                                                            #
:#  Function        get_IP_address                                            #
:#                                                                            #
:#  Description     Get the current IP address                                #
:#                                                                            #
:#  Arguments       %1	    Ouput variable name. Default name: MYIP           #
:#                                                                            #
:#  Notes 	                                                              #
:#                                                                            #
:#  History                                                                   #
:#   2010-04-30 JFL Created this routine.                                     #
:#   2015-11-19 JFL Adapted to new %UPVAR% mechanism.                         #
:#                                                                            #
:#----------------------------------------------------------------------------#

:# Find the current IP address
:get_IP_address %1=Ouput variable name; Default name: MYIP   
%FUNCTION%
set "RETVAR=%~1"
if "%RETVAR%"=="" set "RETVAR=MYIP"
set %RETVAR%=
:# Note: The second for in the command below is used to remove the head space left in %%i after the : delimiter.
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| find "IPv4" ^| find /V " 169.254"') do for %%j in (%%i) do set %RETVAR%=%%j
%UPVAR% %RETVAR%
%RETURN%

:# Other versions experimented
:# for /f %%i in ('ipconfig ^| find "IPv4" ^| find " 10." ^| remplace -q "   IPv4 Address[. ]*: " ""') do set MYIP=%%i
:# for /f "tokens=14" %%i in ('ipconfig ^| find "IPv4" ^| findstr /C:" 16." /C:" 10." /C:" 192."') do set MYIP=%%i

:#----------------------------------------------------------------------------#
:#                                                                            #
:#  Function        IsIPv4Supported                                           #
:#                                                                            #
:#  Description     Is IP v4 supported on this computer                       #
:#                                                                            #
:#  Arguments                                                                 #
:#                                                                            #
:#  Notes 	    Result in %ERRORLEVEL%: 0=Supported; 1=NOT supported      #
:#                                                                            #
:#  History                                                                   #
:#                                                                            #
:#----------------------------------------------------------------------------#

:IsIPv4Supported
%FUNCTION%
ping 127.0.0.1 | find "TTL=" >NUL 2>&1
%RETURN%

:# Alternative implementation, faster, but the wmic command is only available on XP Pro or later.
:IsIPv4Supported
%FUNCTION%
wmic Path Win32_PingStatus WHERE "Address='127.0.0.1'" Get StatusCode /Format:Value | findstr /X "StatusCode=0" >NUL 2>&1
%RETURN%

:IsIPv6Supported
%FUNCTION%
ping ::1 | findstr /R /C:"::1:[�$]" >NUL 2>&1
%RETURN%

:# Alternative implementation, faster, but the wmic command is only available on XP Pro or later.
:IsIPv6Supported
%FUNCTION%
wmic Path Win32_PingStatus WHERE "Address='::1'" Get StatusCode >NUL 2>&1
%RETURN%

:#----------------------------------------------------------------------------#
:#                                                                            #
:#  Function        EnumLocalAdmins                                           #
:#                                                                            #
:#  Description     List all local administrators                             #
:#                                                                            #
:#  Arguments                                                                 #
:#                                                                            #
:#  Notes 	    Using only native Windows NT 4+ commands.                 #
:#                                                                            #
:#  History                                                                   #
:#   2015-11-19 JFL Adapted to new %UPVAR% mechanism.                         #
:#                                                                            #
:#----------------------------------------------------------------------------#

:EnumLocalAdmins
%FUNCTION% enableextensions enabledelayedexpansion
for /f "delims=[]" %%a in ('net localgroup Administrators ^| find /n "----"') do set HeaderLines=%%a
for /f "tokens=*"  %%a in ('net localgroup Administrators') do set FooterLine=%%a
net localgroup Administrators | more /E +%HeaderLines% | find /V "%FooterLine%"
%RETURN%

:#----------------------------------------------------------------------------#
:#                                                                            #
:#  Function        num_ips                                                   #
:#                                                                            #
:#  Description     Count IP addresses in a range                             #
:#                                                                            #
:#  Arguments       %1	    First address. Ex: 192.168.0.1                    #
:#                  %2	    Last address, not included in the count.          #
:#                                                                            #
:#  Notes 	    Adapted from a sample published by Walid Toumi:           #
:#                  http://walid-toumi.blogspot.com/                          #
:#                                                                            #
:#  History                                                                   #
:#   2011-08-24 WT  Sample published on http://walid-toumi.blogspot.com/.     #
:#   2011-12-20 JFL Renamed, fixed, and simplified.                           #
:#                                                                            #
:#----------------------------------------------------------------------------#

:num_ips
setlocal enableextensions enabledelayedexpansion
for /f "tokens=1-8 delims=." %%a in ("%1.%2") do (
  set /A a=%%e-%%a,b=%%f-%%b,c=%%g-%%c,d=%%h-%%d
  for %%e in (b c d) do set /A a=256*a + !%%e!
)
endlocal & set "RETVAL=%a%" & goto :eof

:#----------------------------------------------------------------------------#
:#                                                                            #
:#  Function        Now                                                       #
:#                                                                            #
:#  Description     Locale-independant routine to parse the current date/time #
:#                                                                            #
:#  Returns         Environment variables YEAR MONTH DAY HOUR MINUTE SECOND MS#
:#                                                                            #
:#  Notes 	    This routine is a pure-batch attempt at parsing the date  #
:#                  and time in a way compatible with any language and locale.#
:#                  Forces the output variables widths to fixed widths,       #
:#		    suitable for use in ISO 8601 date/time format strings.    #
:#                  Note that it would have been much easier to cheat and     #
:#                  do all this by invoking a PowerShell command!             #
:#                                                                            #
:#                  The major difficulty is that the cmd.exe date and time    #
:#                  are localized, and the year/month/day order and separator #
:#                  vary a lot between countries and languages.               #
:#                  Workaround: Use the short date format from the registry   #
:#                  as a template to analyse the date and time strings.       #
:#                  Tested in English, French, German, Spanish, Simplified    #
:#		    Chinese, Japanese.                                        #
:#                                                                            #
:#                  Uses %TIME% and not "TIME /T" because %TIME% gives more:  #
:#                  %TIME% returns [H]H:MM:SS.hh			      #
:#		    "TIME /T" returns MM:SS only.                             #
:#                                                                            #
:#                  Set DEBUG_NOW=1 before calling this routine, to display   #
:#                  the values of intermediate results.                       #
:#                                                                            #
:#  History                                                                   #
:#   2012-02-14 JFL Created this routine.                                     #
:#   2015-10-18 JFL Bug fix: The output date was incorrect if loop variables  #
:#                  %%a, %%b, or %%c existed already.                         #
:#                                                                            #
:#----------------------------------------------------------------------------#

:now
setlocal enableextensions enabledelayedexpansion
:# First get the short date format from the Control Panel data in the registry
for /f "tokens=3" %%a in ('reg query "HKCU\Control Panel\International" /v sShortDate 2^>NUL ^| findstr "REG_SZ"') do set "SDFTOKS=%%a"
if .%DEBUG_NOW%.==.1. echo set "SDFTOKS=!SDFTOKS!"
:# Now simplify this (ex: "yyyy/MM/dd") to a "YEAR MONTH DAY" format
for %%a in ("yyyy=y" "yy=y" "y=YEAR" "MMM=M" "MM=M" "M=MONTH" "dd=d" "d=DAY" "/=-" ".=-" "-= ") do set "SDFTOKS=!SDFTOKS:%%~a!"
if .%DEBUG_NOW%.==.1. echo set "SDFTOKS=!SDFTOKS!"
:# From the actual order, generate the token parsing instructions
set "%%=%%" &:# Define a % variable that will generate a % _after_ the initial %LoopVariable parsing phase
for /f "tokens=1,2,3" %%t in ("!SDFTOKS!") do set "SDFTOKS=set %%t=!%%!a&set %%u=!%%!b&set %%v=!%%!c"
if .%DEBUG_NOW%.==.1. echo set "SDFTOKS=!SDFTOKS!"
:# Then get the current date and time. (Try minimizing the risk that they get off by 1 day around midnight!)
set "D=%DATE%" & set "T=%TIME%"
if .%DEBUG_NOW%.==.1. echo set "D=%D%" & echo set "T=%T%"
:# Remove the day-of-week that appears in some languages (US English, Chinese...)
for /f %%d in ('for %%a in ^(%D%^) do @^(echo %%a ^| findstr /r [0-9]^)') do set "D=%%d"
if .%DEBUG_NOW%.==.1. echo set "D=%D%"
:# Extract the year/month/day components, using the token indexes set in %SDFTOKS%
for /f "tokens=1,2,3 delims=/-." %%a in ("%D%") do (%SDFTOKS%)
:# Make sure the century is specified, and the month and day have 2 digits.
set "YEAR=20!YEAR!"  & set "YEAR=!YEAR:~-4!"
set "MONTH=0!MONTH!" & set "MONTH=!MONTH:~-2!"
set "DAY=0!DAY!"     & set "DAY=!DAY:~-2!"
:# Remove the leading space that appears for time in some cases. (Spanish...)
set "T=%T: =%"
:# Split seconds and milliseconds
for /f "tokens=1,2 delims=,." %%a in ("%T%") do (set "T=%%a" & set "MS=%%b")
if .%DEBUG_NOW%.==.1. echo set "T=%T%" & echo set "MS=%MS%"
:# Split hours, minutes and seconds. Make sure they all have 2 digits.
for /f "tokens=1,2,3 delims=:" %%a in ("%T%") do (
  set "HOUR=0%%a"   & set "HOUR=!HOUR:~-2!"
  set "MINUTE=0%%b" & set "MINUTE=!MINUTE:~-2!"
  set "SECOND=0%%c" & set "SECOND=!SECOND:~-2!"
  set "MS=!MS!000"  & set "MS=!MS:~0,3!"
)
if .%DEBUG%.==.1. echo set "YEAR=%YEAR%" ^& set "MONTH=%MONTH%" ^& set "DAY=%DAY%" ^& set "HOUR=%HOUR%" ^& set "MINUTE=%MINUTE%" ^& set "SECOND=%SECOND%" ^& set "MS=%MS%"
endlocal & set "YEAR=%YEAR%" & set "MONTH=%MONTH%" & set "DAY=%DAY%" & set "HOUR=%HOUR%" & set "MINUTE=%MINUTE%" & set "SECOND=%SECOND%" & set "MS=%MS%" & goto :eof

:#----------------------------------------------------------------------------#

:# Initial implementation, with a less detailed output, but simple and guarantied to work in all cases.
:now
setlocal enableextensions enabledelayedexpansion
:# Get the time, including seconds. ('TIME /T' returns MM:SS only)
for /f "delims=.," %%t in ("%TIME%") do SET T=%%t
:# Change the optional leading space to a 0. (For countries that use a 12-hours format)
set T=%T: =0%
:# Change HH:MM:SS to HHhMMmSS, as : is invalid in pathnames
for /f "tokens=1-3 delims=:" %%a in ("%T%") do (
  SET HH=%%a
  SET MM=%%b
  SET SS=%%c
)
set T=%HH%h%MM%m%SS%
:# Build the DATE_TIME string
set NOW=%DATE:/=-%_%T%
endlocal & set "RETVAL=%NOW%" & set "NOW=%NOW%" & goto :eof

:#----------------------------------------------------------------------------#

:# Other implementation, independant of the locale, but not of the language, and not relying on the registry.
:# This will work for all languages that output a hint like (mm-dd-yy)
:# This can easily be adapted to other languages: French=(jj-mm-aa) German=(TT-MM-JJ) Spanish=(dd-mm-aa) Japanese ([]-[]-[])
:# But Chinese outputs a string without dashes: ([][][]) so this would be more difficult.
:now
setlocal enableextensions enabledelayedexpansion
set "D="
for /f "tokens=2 delims=:" %%a in ('echo.^|date') do (
  if "!D!"=="" ( set "D=%%a" ) else ( set "O=%%a" )
)
for /f "tokens=1-3 delims=(-) " %%a in ("%O%") DO (
  set "first=%%a" & set "second=%%b" & set "third=%%c"
)
for /f %%d in ('for %%a in ^(%D%^) do @^(echo %%a ^| findstr /r [0-9]^)') do set "D=%%d"
SET %first%=%D:~0,2%
SET %second%=%D:~3,2%
SET %third%=%D:~6,4%
endlocal & SET "YEAR=%yy%" & SET "MONTH=%mm%" & SET "DAY=%dd%" & goto :eof

:#----------------------------------------------------------------------------#
:#                                                                            #
:#  Function        Time.Delta                                                #
:#                                                                            #
:#  Description     Compute the difference between two times                  #
:#                                                                            #
:#  Returns         Environment variables DC DH DM DS DMS                     #
:#                  for carry, hours, minutes, seconds, milliseconds          #
:#                                                                            #
:#  Notes 	    Carry == 0, or -1 if the time flipped over midnight.      #
:#                                                                            #
:#  History                                                                   #
:#   2012-10-08 JFL Created this routine.                                     #
:#   2012-10-12 JFL Renamed variables. Added support for milliseconds.        #
:#                                                                            #
:#----------------------------------------------------------------------------#

:Time.Delta %1=T0 %2=T1 [%3=-f]. Input times in HH:MM:SS[.mmm] format.
setlocal enableextensions enabledelayedexpansion
for /f "tokens=1,2,3,4 delims=:." %%a in ("%~1") do set "H0=%%a" & set "M0=%%b" & set "S0=%%c" & set "MS0=%%d000" & set "MS0=!MS0:~0,3!"
for /f "tokens=1,2,3,4 delims=:." %%a in ("%~2") do set "H1=%%a" & set "M1=%%b" & set "S1=%%c" & set "MS1=%%d000" & set "MS1=!MS1:~0,3!"
:# Remove the initial 0, to avoid having numbers interpreted in octal afterwards. (MS may have 2 leading 0s!)
for %%n in (0 1) do for %%c in (H M S MS MS) do if "!%%c%%n:~0,1!"=="0" set "%%c%%n=!%%c%%n:~1!"
:# Compute differences
for %%c in (H M S MS) do set /a "D%%c=%%c1-%%c0"
set "DC=0" & :# Carry  
:# Report carries if needed
if "%DMS:~0,1%"=="-" set /a "DMS=DMS+1000" & set /a "DS=DS-1"
if "%DS:~0,1%"=="-" set /a "DS=DS+60" & set /a "DM=DM-1"
if "%DM:~0,1%"=="-" set /a "DM=DM+60" & set /a "DH=DH-1"
if "%DH:~0,1%"=="-" set /a "DH=DH+24" & set /a "DC=DC-1"
:# If requested, convert the results back to a 2-digit format.
if "%~3"=="-f" for %%c in (H M S MS) do if "!D%%c:~1!"=="" set "D%%c=0!D%%c!"
if "!DMS:~2!"=="" set "DMS=0!DMS!"
endlocal & set "DC=%DC%" & set "DH=%DH%" & set "DM=%DM%" & set "DS=%DS%" & set "DMS=%DMS%" & goto :eof

:#----------------------------------------------------------------------------#
:#                                                                            #
:#  Function        WinVer                                                    #
:#                                                                            #
:#  Description     Parse Windows version, extracting major, minor & build #. #
:#                                                                            #
:#  Arguments       None                                                      #
:#                                                                            #
:#  Returns         Environment variables WINVER WINMAJOR WINMINOR WINBUILD   #
:#                                                                            #
:#  Notes 	                                                              #
:#                                                                            #
:#  History                                                                   #
:#   2012-02-29 JFL Created this routine.                                     #
:#                                                                            #
:#----------------------------------------------------------------------------#

:WinVer
for /f "tokens=*" %%v in ('ver') do @set WINVER=%%v
for /f "delims=[]" %%v in ('for %%a in ^(%WINVER%^) do @^(echo %%a ^| findstr [0-9]^)') do @set WINVER=%%v
for /f "tokens=1,2,3 delims=." %%v in ("%WINVER%") do @(set "WINMAJOR=%%v" & set "WINMINOR=%%w" & set "WINBUILD=%%x")
goto :eof

:#----------------------------------------------------------------------------#
:#                                                                            #
:#  Function        Firewall.GetRules                                         #
:#                                                                            #
:#  Description     Get a list of firewall rules, and their properties        #
:#                                                                            #
:#  Arguments       %1	    Rule(s) name                                      #
:#                                                                            #
:#  Returns         RULE.N                Number of rules found               #
:#                  RULE.LIST             List of rule indexes                #
:#                  RULE[!N!].PROPERTIES  List of properties                  #
:#                  RULE[!N!].!PROPERTY!  Property value                      #
:#                                                                            #
:#  Notes 	    Requires delayed expansion enabled beforehand.            #
:#                                                                            #
:#  History                                                                   #
:#   2013-11-28 JFL Created this routine.                                     #
:#                                                                            #
:#----------------------------------------------------------------------------#

:Firewall.GetRules
%FUNCTION%
set "RULE.N=0"
set "RULE.LIST="
               %ECHO.XVD% netsh advfirewall firewall show rule name^=%1 verbose
for /f "delims=" %%l in ('netsh advfirewall firewall show rule name^=%1 verbose') do (
  for /f "tokens=1,* delims=:" %%a in ('echo.%%l') do (
    set "RULE.NAME=%%a"  &:# Property name
    set "RULE.VALUE=%%b" &:# Property value
    if not "%%b"=="" (
      if "!RULE.NAME!"=="Rule Name" ( :# It's a new rule
      	set "RULE.I=!RULE.N!"
	set "RULE.LIST=!RULE.LIST! !RULE.I!"
      	set /a "RULE.N=!RULE.N!+1"
      ) else ( :# It's a property of the current rule.
      	set "RULE.NAME=!RULE.NAME: =_!"	& rem :# Make sure it does not contain spaces
	call set "RULE[%%RULE.I%%].PROPERTIES=%%RULE[!RULE.I!].PROPERTIES%% !RULE.NAME!"
      	:# %%b is the value, but we need to skip all spaces after the :
      	for /f "tokens=1,*" %%c in ('echo 1 !RULE.VALUE!') do (
      	  set "RULE.VALUE=%%d"
      	)
      	set "RULE[!RULE.I!].!RULE.NAME!=!RULE.VALUE!"
      )
    )
  )
)
%IF_DEBUG% set RULE
%RETURN%

:#----------------------------------------------------------------------------#
:#                                                                            #
:#  Function        GetServerAddress                                          #
:#                                                                            #
:#  Description     Use nslookup.exe to resolve an IP address		      #
:#                                                                            #
:#  Arguments       %1	    Server name                                       #
:#                  %2      Name of the return variable. Default: ADDRESS     #
:#                                                                            #
:#  Notes 	    Returns an empty string if it cannot resolve the address. #
:#                                                                            #
:#  History                                                                   #
:#   2015-03-02 JFL Created this routine.                                     #
:#                                                                            #
:#----------------------------------------------------------------------------#

:# The nslookup output contains:
:#	0 or more lines with parameters, like:
:#		1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.ip6.arpa
:#		        primary name server = 1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.ip6.arpa
:#		        responsible mail addr = (root)
:#		        serial  = 0
:#		        refresh = 28800 (8 hours)
:#		        retry   = 7200 (2 hours)
:#		        expire  = 604800 (7 days)
:#		        default TTL = 86400 (1 day)
:#	Then 2 lines (+1 blank line) with the DNS name and address:
:#		        Server:  UnKnown
:#		        Address:  ::1
:#	Then, if success, 2 lines with a name and a first address
:#		        Name:    katz1.adm.lab.gre.hp.com
:#		        Address:  10.16.131.1
:#	Then, if there are multiple addresses, N lines with just an address
:#		                  10.18.131.1
:#		                  10.17.131.1

:# Use nslookup.exe to resolve an IP address. Return the last one found, or an empty string.

:GetServerAddress %1=Name %2=RetVar
%FUNCTION% enableextensions enabledelayedexpansion
set "NAME=%~1"
set "RETVAR=%~2"
if "%RETVAR%"=="" set "RETVAR=ADDRESS"
set "ADDRESS="
set "NFIELD=0"
for /f "tokens=1,2" %%a in ('nslookup %NAME% 2^>NUL') do (
  set "A=%%a"
  set "B=%%b"
  %ECHOVARS.D% A B
  set "ADDRESS=%%b"			&REM Normally the address is the second token.
  if "%%b"=="" set "ADDRESS=%%a"	&REM But for final addresses it may be the first.
  if not "!A!"=="!A::=!" set /a "NFIELD=NFIELD+1" &REM Count lines with a NAME: header.
  if "!NFIELD!"=="0" set "ADDRESS="	&REM The first two values are for the DNS server, not for the target server.
  if "!NFIELD!"=="1" set "ADDRESS="
  if "!NFIELD!"=="2" set "ADDRESS="
  %ECHOVARS.D% NFIELD ADDRESS
)
%UPVAR% %RETVAR%
set "%RETVAR%=%ADDRESS%"
%RETURN%

:#----------------------------------------------------------------------------#
:#                                                                            #
:#  Function        Test*                                                     #
:#                                                                            #
:#  Description     Misc test routines for testing the debug library itself   #
:#                                                                            #
:#  Arguments       %*	    Vary                                              #
:#                                                                            #
:#  Notes 	                                                              #
:#                                                                            #
:#  History                                                                   #
:#                                                                            #
:#----------------------------------------------------------------------------#

:TempT
echo set "RETURN=!RETURN!"
echo set "RETURN=%RETURN%"
%ECHOVARS.D% RETURN

for %%f in ("A%%A" "BB" "CC") do @echo f=%%f
  
set A=a
set B=b
set V=A
%ECHOVARS% A B V
echo ^^!%%V%%^^!=!%V%!

set V=B
%ECHOVARS% V
echo ^^!%%V%%^^!=!%V%!

set W=^^!V^^!
setlocal disabledelayedexpansion
echo %%W%%=%W%
endlocal
echo %%W%%=%W%
goto :eof

:ExecHello
%EXEC% echo "Hello world^!"
goto :eof

:TestDelayedExpansion
if .%USERNAME%.==.!USERNAME!. (
  echo Delayed Expansion is ON
) else (
  echo Delayed Expansion is OFF
)
goto :eof

:#----------------------------------------------------------------------------#
:# Factorial routine, to test the tracing framework indentation

:Fact
%FUNCTION% enableextensions enabledelayedexpansion
%UPVAR% RETVAL
set N=%1
if .%1.==.. set N=0
if .%N%.==.0. (
  set RETVAL=1
) else (
  set /A M=N-1
  call :Fact !M!
  set /A RETVAL=N*RETVAL
)
%RETURN%

:Fact.test
%FUNCTION%
call :Fact %*
%ECHO% %RETVAL%
%RETURN%

:#----------------------------------------------------------------------------#
:# Test routines to measure the overhead of call/return

:noop
goto :eof

:noop1
%FUNCTION0%
%RETURN0%

:noop2 %1=retcode
%FUNCTION%
%RETURN% %~1

:noop2d %1=retcode
%FUNCTION% DisableDelayedExpansion
%RETURN% %~1

:noop2e %1=retcode
%FUNCTION% EnableDelayedExpansion
%RETURN% %~1

:noop22 %1=retcode
%FUNCTION%
call :noop2 %~1
%RETURN%

:noop3 %1=retcode %2=string to return in RETVAL
%FUNCTION%
call :extensions.show
%UPVAR% RETVAL
:# Do not use parenthesis, in case there are some in the return value
if "!!"=="" set "RETVAL=!ARGS:* =!"
if not "!!"=="" set "RETVAL=%ARGS:* =%"
%RETURN% %~1

:noop3d %1=retcode %2=string to return in RETVAL
%FUNCTION% DisableDelayedExpansion
call :extensions.show
%UPVAR% RETVAL
set "RETVAL=%~2"
%RETURN% %~1

:noop3e %1=retcode %2=string to return in RETVAL
%FUNCTION% EnableDelayedExpansion
call :extensions.show
%UPVAR% RETVAL
set "RETVAL=%~2"
%RETURN% %~1

:noop33 %1=retcode %2=string to return in RETVAL
%FUNCTION%
call :extensions.show
%UPVAR% RETVAL
if "!!"=="" (
  call :noop3 !ARGS!
) else (
  call :noop3 %ARGS%
)
%RETURN%

:noop4 %1=retcode %2=string to return in RETVAL1 %3=string to return in RETVAL2
%FUNCTION%
%UPVAR% RETVAL1 RETVAL2
set "RETVAL1=%2"
set "RETVAL2=%3"
%RETURN% %~1

:noop4i %1=retcode %2=string to return in RETVAL1 %3=string to return in RETVAL2
%FUNCTION%
if "!!"=="" (echo NOOP4 [EnableExpansion]) else echo NOOP4 [DisableExpansion]
set ARGS
%UPVAR% RETVAL1 RETVAL2
set "RETVAL1=%2"
set "RETVAL2=%3"
set RETVAL1 & set RETVAL2
%RETURN% %~1

:noop4d %1=retcode %2=string to return in RETVAL1 %3=string to return in RETVAL2
%FUNCTION% DisableDelayedExpansion
%IF_XDLEVEL% 1 if "!!"=="" (echo NOOP4D [EnableExpansion]) else echo NOOP4D [DisableExpansion]
%IF_XDLEVEL% 1 set ARGS
%UPVAR% RETVAL1 RETVAL2
set "RETVAL1=%~2"
set "RETVAL2=%~3"
%IF_XDLEVEL% 1 set RETVAL1 & set RETVAL2
%RETURN% %~1

:noop4e %1=retcode %2=string to return in RETVAL1 %3=string to return in RETVAL2
%FUNCTION% EnableDelayedExpansion
%IF_XDLEVEL% 1 if "!!"=="" (echo NOOP4E [EnableExpansion]) else echo NOOP4E [DisableExpansion]
%IF_XDLEVEL% 1 set ARGS
%UPVAR% RETVAL1 RETVAL2
set "RETVAL1=%~2"
set "RETVAL2=%~3"
%IF_XDLEVEL% 1 set RETVAL1 & set RETVAL2
%RETURN% %~1

:noop44 %1=retcode %2=string to return in RETVAL1 %3=string to return in RETVAL2
%FUNCTION%
%IF_XDLEVEL% 1 set ARGS
%UPVAR% RETVAL1 RETVAL2
if "!!"=="" (
  call :noop4 !ARGS!
) else (
  call :noop4 %ARGS%
)
%IF_XDLEVEL% 1 set RETVAL1 & set RETVAL2
%RETURN%

:#----------------------------------------------------------------------------#
:# Test %EXEC% one command line. Display start/end time if looping.

:exec_cmd_line
%CMD_BEFORE%
set CMDLINE=%ARGS%
if not %NLOOPS%==1 echo Start at %TIME% & set "T0=%TIME%"
for /l %%n in (1,1,%NLOOPS%) do %EXEC% %CMDLINE%
if not %NLOOPS%==1 echo End at %TIME% & set "T1=%TIME%"
if not %NLOOPS%==1 call :Time.Delta %T0% %T1% -f & echo Delta = !DH!:!DM!:!DS!.!DMS:~0,2!
%CMD_AFTER%
goto :eof

:#----------------------------------------------------------------------------#
:# Test call one command line. Display start/end time if looping.
:# Do not add anything to the inner do loop, such as echoing the command, as this
:# would prevent from doing accurate measurements of the duration of the command.

:call_cmd_line
%CMD_BEFORE%
set CMDLINE=%ARGS%
%ECHOVARS.V% CMDLINE
if not %NLOOPS%==1 echo Start at %TIME% & set "T0=%TIME%"
for /l %%n in (1,1,%NLOOPS%) do call %CMDLINE%
if not %NLOOPS%==1 echo End at %TIME% & set "T1=%TIME%"
if not %NLOOPS%==1 call :Time.Delta %T0% %T1% -f & echo Delta = !DH!:!DM!:!DS!.!DMS:~0,2!
%CMD_AFTER%
goto :eof

:call_macro_line
%CMD_BEFORE%
echo :call_macro_line %ARGS%
%POPARG%
set CMDLINE=%%%ARG%%% %ARGS%
%ECHOVARS.V% CMDLINE
if not %NLOOPS%==1 echo Start at %TIME% & set "T0=%TIME%"
:# for /l %%n in (1,1,%NLOOPS%) do cmd /c echo off ^& %%%ARG%%% %ARGS%
for /l %%n in (1,1,%NLOOPS%) do (echo off & %CMDLINE%) | more
if not %NLOOPS%==1 echo End at %TIME% & set "T1=%TIME%"
if not %NLOOPS%==1 call :Time.Delta %T0% %T1% -f & echo Delta = !DH!:!DM!:!DS!.!DMS:~0,2!
%CMD_AFTER%
goto :eof

:#----------------------------------------------------------------------------#
:# Test call N command lines. Display start/end time if looping.
:# Do not add anything to the inner do loop, such as echoing the command, as this
:# would prevent from doing accurate measurements of the duration of the commands.

:# Convert the supported html entities to their corresponding character
:convert_entities %1=variable name
setlocal EnableDelayedExpansion
set "ARG=!%1!"
for %%e in (quot lt gt amp vert rpar lpar rbrack lbrack sp bs cr lf) do (
  call set "ARG=%%ARG:[%%e]=!DEBUG.%%e!%%"
)
:# Then convert special characters that need quoting to survive the return
set "ARG=!ARG:[percnt]=%%!"
set "ARG=!ARG:[Hat]=^^^^^^^^^^^^^^^^!"
set "ARG=%ARG:[excl]=^^^^^^^^^^^^^^^!%"
set "ARG=!ARG:[lbrack]=[!" &:# Must be converted last
endlocal & set "%1=%ARG%" !
goto :eof

:call_all_cmds
%IF_XDLEVEL% 3 set FUNCTION & set UPVAR & set RETURN &:# Dump the structured programming macros
:# Record all commands to run, converting entities to special characters
set NCMDS=0
:call_all_cmds.next_arg
%POPARG%
if not defined "ARG" goto :call_all_cmds.done_args
set /a NCMDS+=1
call :convert_entities ARG
%IF_XDLEVEL% 2 set ARG | findstr ARG=
set "CMD[%NCMDS%]=!ARG!"
goto :call_all_cmds.next_arg
:call_all_cmds.done_args
if defined CMD_BEFORE call :convert_entities CMD_BEFORE
if defined CMD_AFTER call :convert_entities CMD_AFTER
%IF_DEBUG% %>DEBUGOUT% (
  if defined CMD_BEFORE set CMD_BEFORE
  set CMD[
  if defined CMD_AFTER set CMD_AFTER
)
:# Run all commands in a loop, measuring the total duration when looping more than once
if defined CMD_BEFORE !CMD_BEFORE!
if not %NLOOPS%==1 echo Start at %TIME% & set "T0=%TIME%"
for /l %%n in (1,1,%NLOOPS%) do for /l %%c in (1,1,%NCMDS%) do call %%CMD[%%c]%% &:# Don't use !CMD[]! in case one command disables expansion
if not %NLOOPS%==1 echo End at %TIME% & set "T1=%TIME%"
if not %NLOOPS%==1 call :Time.Delta %T0% %T1% -f & echo Delta = !DH!:!DM!:!DS!.!DMS:~0,2!
if defined CMD_AFTER !CMD_AFTER!
goto :eof

:# Short aliases for common before & after commands
:EDE
:EDX
setlocal EnableDelayedExpansion
goto :eof

:DDE
:DDX
setlocal DisableDelayedExpansion
goto :eof

:#----------------------------------------------------------------------------#
:#                                                                            #
:#  Function        Main                                                      #
:#                                                                            #
:#  Description     Process command line arguments                            #
:#                                                                            #
:#  Arguments       %*	    Command line arguments                            #
:#                                                                            #
:#  Notes 	                                                              #
:#                                                                            #
:#  History                                                                   #
:#                                                                            #
:#----------------------------------------------------------------------------#

:Help
echo.
echo %SCRIPT% version %VERSION% - JFL cmd.exe Batch Library tests
echo.
echo Usage: %SCRIPT% [OPTIONS]
echo.
echo Options:
echo   -?       Display this help
echo   --       End of wrapper options
echo   -a CMDLINE         Call the command line once after the -c/-C commands (1)
echo   -b CMDLINE         Call the command line once before the -c/-C commands (1)
echo   -c CMDLINE1 ...    Call each following argument as a separate cmd. (1)
echo   -C CMD ARGS        Call the whole command tail as one command line
echo   -d       Debug mode. Trace functions entry and exit
echo   -d2      Send debug output to stderr instead of stdout
echo   -e       Display all arguments and exit
echo   -E CMD ARGS        %%EXEC%% the whole command tail as one command line
echo   -l LOG   Set the log file name
echo   -M MACRO ARGS      Call %%MACRO%% and pass it ARGS
echo   -n N     Run the commands N times and display the start and end times
echo   -qe      Query the current cmd extensions and delayed expansion settings
echo   -r       Test %%EXEC%% with an output redirection to exec.log
echo   -R       Test %%EXEC%% without an output redirection
echo   -v       Verbose mode. Display commands executed
echo   -V       Display the script version and exit
echo   -X       Display commands to execute, but don't execute them
echo.
echo Notes:
echo 1) The following html entity names, within brackets, will be converted to their
echo    corresponding character:
echo    [percnt]=%% [excl]=^^^! [quot]=" [Hat]=^^ [lt]=< [gt]=> [amp]=& [vert]=| [lpar]=( [rpar]=) [lbrack]=[ [rbrack]=]
goto :eof

:#----------------------------------------------------------------------------#
:# Main routine

:Main
set "NLOOPS=1"
set "CMD_AFTER="
set "CMD_BEFORE="

:next_arg
%POPARG%
if "!ARG!"=="" goto :Start
if "!ARG!"=="-?" goto :Help
if "!ARG!"=="/?" goto :Help
if "!ARG!"=="-a" %POPARG% & set "CMD_AFTER=!ARG!" & goto next_arg
if "!ARG!"=="-b" %POPARG% & set "CMD_BEFORE=!ARG!" & goto next_arg
if "!ARG!"=="-c" goto :call_all_cmds
if "!ARG!"=="-C" goto :call_cmd_line
if "!ARG!"=="-d" call :Debug.On & goto next_arg
if "!ARG!"=="-d0" set ">DEBUGOUT=>NUL" & call :Debug.On & goto next_arg	&:# Useful for library performance measurements
if "!ARG!"=="-d1" set ">DEBUGOUT=>&3" & call :Debug.On & goto next_arg	&:# Useful to test debug output routines to 
if "!ARG!"=="-d2" set ">DEBUGOUT=>&2" & call :Debug.On & goto next_arg	&:# Useful to test debug output routines
if "!ARG!"=="-e" goto EchoArgs
if "!ARG!"=="-E" goto :exec_cmd_line
if "!ARG!"=="-l" %POPARG% & call :Debug.SetLog "!ARG!" & goto next_arg
if "!ARG!"=="-M" goto :call_macro_line
if "!ARG!"=="-n" %POPARG% & set "NLOOPS=!ARG!" & goto next_arg
if "!ARG!"=="-qe" endlocal & (set ECHO=echo) & goto :extensions.show
if "!ARG!"=="-r" call :Debug.Setlog test.log & %EXEC% cmd /c %SCRIPT% -? ">"exec.log & goto :eof
if "!ARG!"=="-R" call :Debug.Setlog test.log & %EXEC% cmd /c %SCRIPT% -? & goto :eof
if "!ARG!"=="-tg" %POPARG% & call :GetServerAddress !ARG! & %ECHOVARS% ADDRESS & goto :eof &:# Test routine GetServerAddress
if "!ARG!"=="-v" call :Verbose.On & goto next_arg
if "!ARG!"=="-V" (echo.%VERSION%) & goto :eof
if "!ARG!"=="-X" call :Exec.Off & goto next_arg
if "!ARG!"=="-xd" %POPARG% & set "XDLEVEL=!ARG!" & goto next_arg
if "!ARG:~0,1!"=="-" (
  >&2 %ECHO% Warning: Unexpected option ignored: !ARG!
  goto :next_arg
)
>&2 %ECHO% Warning: Unexpected argument ignored: !"ARG"!
goto :next_arg

:#----------------------------------------------------------------------------#
:# Start the real work

:Start
:# This library does nothing. Display the help screen.
goto :Help

:# The following line must be last and not end by a CRLF.
-