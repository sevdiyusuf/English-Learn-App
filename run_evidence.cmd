@echo off
set "OUT=C:\ders\flutter\tamamm\sprint6c-owner-command-evidence.txt"
del "%OUT%" 2>nul

echo ===== functions - npm ci ===== >> "%OUT%"
echo CWD: C:\ders\flutter\tamamm\functions >> "%OUT%"
echo ^> npm ci >> "%OUT%"
cd C:\ders\flutter\tamamm\functions
call npm ci >> "%OUT%" 2>&1
echo. >> "%OUT%"

echo ===== functions - npm run build ===== >> "%OUT%"
echo CWD: C:\ders\flutter\tamamm\functions >> "%OUT%"
echo ^> npm run build >> "%OUT%"
cd C:\ders\flutter\tamamm\functions
call npm run build >> "%OUT%" 2>&1
echo. >> "%OUT%"

echo ===== functions - jest ===== >> "%OUT%"
echo CWD: C:\ders\flutter\tamamm\functions >> "%OUT%"
echo ^> npx jest --preset ts-jest --runInBand --forceExit >> "%OUT%"
cd C:\ders\flutter\tamamm\functions
call npx jest --preset ts-jest --runInBand --forceExit >> "%OUT%" 2>&1
echo. >> "%OUT%"

echo ===== test_rules - npm ci ===== >> "%OUT%"
echo CWD: C:\ders\flutter\tamamm\test_rules >> "%OUT%"
echo ^> npm ci >> "%OUT%"
cd C:\ders\flutter\tamamm\test_rules
call npm ci >> "%OUT%" 2>&1
echo. >> "%OUT%"

echo ===== test_rules - java version ===== >> "%OUT%"
echo CWD: C:\ders\flutter\tamamm\test_rules >> "%OUT%"
echo ^> java -version >> "%OUT%"
cd C:\ders\flutter\tamamm\test_rules
java -version >> "%OUT%" 2>&1
echo. >> "%OUT%"

echo ===== test_rules - jest ===== >> "%OUT%"
echo CWD: C:\ders\flutter\tamamm\test_rules >> "%OUT%"
echo ^> firebase emulators:exec --only firestore --project demo-sprint6c "npx jest --runInBand --forceExit" >> "%OUT%"
cd C:\ders\flutter\tamamm\test_rules
call firebase emulators:exec --only firestore --project demo-sprint6c "npx jest --runInBand --forceExit" >> "%OUT%" 2>&1
echo. >> "%OUT%"

echo ===== flutter - flutter test ===== >> "%OUT%"
echo CWD: C:\ders\flutter\tamamm >> "%OUT%"
echo ^> flutter test >> "%OUT%"
cd C:\ders\flutter\tamamm
call flutter test >> "%OUT%" 2>&1
echo. >> "%OUT%"

echo ===== flutter - flutter analyze ===== >> "%OUT%"
echo CWD: C:\ders\flutter\tamamm >> "%OUT%"
echo ^> flutter analyze >> "%OUT%"
cd C:\ders\flutter\tamamm
call flutter analyze >> "%OUT%" 2>&1
echo. >> "%OUT%"

echo ===== Genel - git diff --check HEAD ===== >> "%OUT%"
echo CWD: C:\ders\flutter\tamamm >> "%OUT%"
echo ^> git diff --check HEAD >> "%OUT%"
cd C:\ders\flutter\tamamm
git diff --check HEAD >> "%OUT%" 2>&1
echo. >> "%OUT%"

echo ===== Genel - git status --short ===== >> "%OUT%"
echo CWD: C:\ders\flutter\tamamm >> "%OUT%"
echo ^> git status --short >> "%OUT%"
cd C:\ders\flutter\tamamm
git status --short >> "%OUT%" 2>&1
echo. >> "%OUT%"

echo ===== Genel - functions/lib/*.test.js ===== >> "%OUT%"
echo CWD: C:\ders\flutter\tamamm >> "%OUT%"
echo ^> dir /s /b functions\lib\*.test.js >> "%OUT%"
cd C:\ders\flutter\tamamm
dir /s /b functions\lib\*.test.js >> "%OUT%" 2>&1
echo. >> "%OUT%"

echo ===== Genel - functions/package-lock sync ===== >> "%OUT%"
echo CWD: C:\ders\flutter\tamamm\functions >> "%OUT%"
echo ^> npm ls >> "%OUT%"
cd C:\ders\flutter\tamamm\functions
call npm ls >nul 2>&1
if %errorlevel% equ 0 (echo Sync OK >> "%OUT%") else (echo Sync Failed >> "%OUT%")
echo. >> "%OUT%"

echo ===== Genel - test_rules/package-lock sync ===== >> "%OUT%"
echo CWD: C:\ders\flutter\tamamm\test_rules >> "%OUT%"
echo ^> npm ls >> "%OUT%"
cd C:\ders\flutter\tamamm\test_rules
call npm ls >nul 2>&1
if %errorlevel% equ 0 (echo Sync OK >> "%OUT%") else (echo Sync Failed >> "%OUT%")
echo. >> "%OUT%"
