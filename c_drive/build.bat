@echo off
fasm %1%
if errorlevel 1 goto error
echo Build successful!
goto end
:error
echo Build failed!
:end
