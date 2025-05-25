@ECHO OFF

REM Prog to make fasm compile/run cycle a little faster.
REM Assumes you are waiting for keypress to exit in your program.

:LOOP
  REM give us a chance to quit
  REM Remove if you want blazingly fast,
  REM but have to force quite dosbox to exit.
  CHOICE /Cnq /T:n,01 /N Press Q to quit
  if errorlevel 2 goto EXIT

  REM Compile and run
  fasm %1%.asm
  if errorlevel 1 goto EXIT 
  %1%
  GOTO LOOP

:EXIT
