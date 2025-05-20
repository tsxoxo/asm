@ECHO OFF
:LOOP
  ECHO Watching %1%...
  fasm %1%
  %1%
  CHOICE /T:y,02 /N >NUL
  GOTO LOOP
