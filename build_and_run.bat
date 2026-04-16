@echo off
set MASM_PATH=C:\masm32
set IRVINE_PATH=C:\Irvine

if not exist %MASM_PATH% (
    echo [ERROR] MASM not found at %MASM_PATH%
    echo Please edit this .bat file and set MASM_PATH to your masm32 folder.
    pause
    exit /b
)

if not exist %IRVINE_PATH% (
    echo [ERROR] Irvine32 library not found at %IRVINE_PATH%
    echo Please edit this .bat file and set IRVINE_PATH to your Irvine folder.
    pause
    exit /b
)

echo [1/2] Assembling cpu_emulator.asm...
%MASM_PATH%\bin\ml.exe /c /coff /I"%IRVINE_PATH%" cpu_emulator.asm

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Assembly failed.
    pause
    exit /b
)

echo [2/2] Linking...
%MASM_PATH%\bin\link.exe /SUBSYSTEM:CONSOLE /LIBPATH:"%IRVINE_PATH%" /LIBPATH:"%MASM_PATH%\lib" cpu_emulator.obj Irvine32.lib kernel32.lib user32.lib

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Linking failed.
    pause
    exit /b
)

echo [SUCCESS] Running Emulator...
cpu_emulator.exe
pause
