@echo off
echo ========================================
echo   Running Orbit Local Verification
echo ========================================
echo.

echo [1/2] Running Flutter Analyze...
call flutter analyze --no-fatal-infos
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Flutter analyze found critical errors! Please fix them before deploying.
    pause
    exit /b %ERRORLEVEL%
)
echo.
echo [PASS] Flutter analyze passed (no critical errors)!
echo.

echo [2/2] Running Flutter Tests...
call flutter test
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Tests failed! Please resolve broken tests before deploying.
    pause
    exit /b %ERRORLEVEL%
)
echo.
echo [PASS] All tests passed successfully!
echo.

echo ========================================
echo   Orbit Verification Complete: ALL OK!
echo ========================================
pause
