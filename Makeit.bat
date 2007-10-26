@echo off

\masm32\bin\rc /v rsrc.rc
\masm32\bin\cvtres /machine:ix86 rsrc.res

\masm32\bin\ml /c /coff eircomWEP.asm

\masm32\bin\link /SUBSYSTEM:WINDOWS /OUT:eircomWEP.exe eircomWEP.obj rsrc.obj

if exist *.obj del *.obj
if exist *.res del *.res

pause
