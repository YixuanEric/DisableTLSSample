SET LOG_FILE="%TEMP%\StartupLog.txt"
SET EXECUTE_PS1=0

IF "%ComputeEmulatorRunning%" == "" (
	SET EXECUTE_PS1=1
)

IF "%ComputeEmulatorRunning%" == "false" (
	SET EXECUTE_PS1=1
) 

IF %EXECUTE_PS1% EQU 1 (
	echo "Invoking TLSConfig.ps1 on Azure service at %TIME% on %DATE%" >> %LOG_FILE% 2>&1	
	PowerShell -ExecutionPolicy Unrestricted .\TLSConfig.ps1 >> %LOG_FILE% 2>&1
	IF %ERRORLEVEL% NEQ 0 (EXIT /B %ERRORLEVEL%)
) ELSE (
	echo "Skipping  TLSConfig.ps1 invocation on emulated environment" >> %LOG_FILE% 2>&1	
)    
echo "why?"
EXIT /B 0 

