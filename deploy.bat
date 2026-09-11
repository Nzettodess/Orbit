@echo off
echo Running pre-deploy verification tests...
call flutter test
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Tests failed! Deployment aborted to protect production.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo Building Flutter Web...
call flutter build web --release
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Build failed! Deployment aborted.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo Deploying to Vercel...
call vercel --prod --yes
echo Done!
pause
