@echo off
echo Building %1%.asm
fasm "%1%.asm"
if errorlevel 1 goto error
echo Build successful: %1%.asm!
%1%
goto end

:error
  echo Build failed!

:end
