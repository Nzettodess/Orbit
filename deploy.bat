@echo off
echo Building Flutter Web...
call flutter build web --release
echo Deploying to Vercel...
call vercel --prod --yes
echo Done!
pause
