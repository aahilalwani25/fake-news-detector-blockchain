@echo off
setlocal EnableDelayedExpansion

set CHAIN=fakedetectchain
set DATADIR=%APPDATA%\MultiChain\%CHAIN%

echo ==========================================================
echo  1. Initializing MultiChain Instance: %CHAIN%
echo ==========================================================

:: Forcefully stop any running daemon to release files
taskkill /F /IM multichaind.exe >nul 2>&1
timeout /t 2 /nobreak >nul

:: Clean existing directory completely
if exist "%DATADIR%" (
    echo Cleaning existing chain directory...
    rmdir /s /q "%DATADIR%"
    timeout /t 1 /nobreak >nul
)

:: Create parameter set
multichain-util create %CHAIN%
if errorlevel 1 (
    echo Failed to create chain.
    exit /b %errorlevel%
)

echo ==========================================================
echo  2. Configuring PoA and Permission Parameters (params.dat)
echo ==========================================================

:: Directly append overrides to params.dat without PowerShell
echo. >> "%DATADIR%\params.dat"
echo target-block-time = 15 >> "%DATADIR%\params.dat"
echo mining-diversity = 0.5 >> "%DATADIR%\params.dat"
echo anyone-can-connect = false >> "%DATADIR%\params.dat"
echo anyone-can-send = false >> "%DATADIR%\params.dat"
echo anyone-can-receive = false >> "%DATADIR%\params.dat"
echo anyone-can-issue = false >> "%DATADIR%\params.dat"
echo anyone-can-create = false >> "%DATADIR%\params.dat"
echo anyone-can-mine = false >> "%DATADIR%\params.dat"
echo anyone-can-activate = false >> "%DATADIR%\params.dat"

echo PoA and security parameters configured successfully.

echo ==========================================================
echo  3. Launching Daemon
echo ==========================================================

start /b multichaind %CHAIN% -daemon
timeout /t 6 /nobreak >nul

echo ==========================================================
echo  4. Creating Identities and Assigning Roles
echo ==========================================================

:: Extract Admin address safely from listpermissions admin
for /f "tokens=2 delims=:, " %%i in ('multichain-cli %CHAIN% listpermissions admin ^| findstr /i "address"') do (
    set "ADMIN_ADDR=%%~i"
)

:: Generate new role addresses
for /f "tokens=*" %%a in ('multichain-cli %CHAIN% getnewaddress') do set "PUB_ADDR=%%a"
for /f "tokens=*" %%a in ('multichain-cli %CHAIN% getnewaddress') do set "VAL_ADDR=%%a"
for /f "tokens=*" %%a in ('multichain-cli %CHAIN% getnewaddress') do set "USER_ADDR=%%a"
for /f "tokens=*" %%a in ('multichain-cli %CHAIN% getnewaddress') do set "UNAUTH_ADDR=%%a"

echo Admin Address:           !ADMIN_ADDR!
echo Publisher Address:       !PUB_ADDR!
echo Validator Address:       !VAL_ADDR!
echo Reader/User Address:     !USER_ADDR!
echo Unauthenticated Address: !UNAUTH_ADDR!

:: Grant Role-Based Permissions
multichain-cli %CHAIN% grant !PUB_ADDR! connect,send,receive >nul
multichain-cli %CHAIN% grant !VAL_ADDR! connect,send,receive,mine >nul
multichain-cli %CHAIN% grant !USER_ADDR! connect,receive >nul

:: Revoke global issue permission from Publisher and Validator
multichain-cli %CHAIN% revoke !PUB_ADDR! issue >nul 2>&1
multichain-cli %CHAIN% revoke !VAL_ADDR! issue >nul 2>&1

echo ==========================================================
echo  5. Setting up Native Asset (CredibilityToken)
echo ==========================================================

multichain-cli %CHAIN% issue !ADMIN_ADDR! CredibilityToken 1000000 1 >nul
timeout /t 2 /nobreak >nul

multichain-cli %CHAIN% sendasset !PUB_ADDR! CredibilityToken 500 >nul
multichain-cli %CHAIN% sendasset !VAL_ADDR! CredibilityToken 1000 >nul
timeout /t 2 /nobreak >nul

echo ==========================================================
echo  6. Creating and Restricting Streams
echo ==========================================================

multichain-cli %CHAIN% create stream news_registry false >nul
multichain-cli %CHAIN% create stream validation_stream false >nul
timeout /t 2 /nobreak >nul

multichain-cli %CHAIN% subscribe news_registry >nul
multichain-cli %CHAIN% subscribe validation_stream >nul

multichain-cli %CHAIN% grant !PUB_ADDR! news_registry.write >nul
multichain-cli %CHAIN% grant !VAL_ADDR! validation_stream.write >nul
timeout /t 2 /nobreak >nul

echo ==========================================================
echo  7. Running Access Control and Security Tests
echo ==========================================================

set DUMMY_HEX=7b2274657374223a22756e61757468227d

:: Test 1: Unauthenticated node write attempt
multichain-cli %CHAIN% publishfrom !UNAUTH_ADDR! news_registry "PROBE-001" "%DUMMY_HEX%" >nul 2>&1
if errorlevel 1 (
    echo Test 1 [Unauthenticated Write Attempt]: PASSED
) else (
    echo Test 1 [Unauthenticated Write Attempt]: FAILED
)

:: Test 2: Cross-stream write by publisher
multichain-cli %CHAIN% publishfrom !PUB_ADDR! validation_stream "PROBE-002" "%DUMMY_HEX%" >nul 2>&1
if errorlevel 1 (
    echo Test 2 [Publisher writing to validation_stream]: PASSED
) else (
    echo Test 2 [Publisher writing to validation_stream]: FAILED
)

:: Test 3: Cross-stream write by validator
multichain-cli %CHAIN% publishfrom !VAL_ADDR! news_registry "PROBE-003" "%DUMMY_HEX%" >nul 2>&1
if errorlevel 1 (
    echo Test 3 [Validator writing to news_registry]: PASSED
) else (
    echo Test 3 [Validator writing to news_registry]: FAILED
)

:: Test 4: Unauthorized asset issuance by publisher
multichain-cli %CHAIN% issuefrom !PUB_ADDR! !PUB_ADDR! ForgedToken 1000 1 >nul 2>&1
if errorlevel 1 (
    echo Test 4 [Publisher issuing assets]: PASSED
) else (
    echo Test 4 [Publisher issuing assets]: FAILED
)

echo ==========================================================
echo  8. Simulating Production Flow (Publish -^> Validate -^> Reward)
echo ==========================================================

set NEWS_ID=NEWS-2026-X88
set HEX_NEWS=7b227469746c65223a22414920427265616b7468726f756768222c22617574686f72223a22526575746572734f7267227d

echo Publishing news metadata to news_registry...
multichain-cli %CHAIN% publishfrom !PUB_ADDR! news_registry "%NEWS_ID%" "%HEX_NEWS%" >nul
timeout /t 2 /nobreak >nul

set HEX_VAL=7b226e6577735f6964223a224e4557532d323032362d583838222c2264726c5f76657264696374223a225265616c222c22637265646962696c6974795f64656c7461223a31307d

echo Certifying article in validation_stream...
multichain-cli %CHAIN% publishfrom !VAL_ADDR! validation_stream "%NEWS_ID%" "%HEX_VAL%" >nul
timeout /t 2 /nobreak >nul

echo Awarding CredibilityTokens to publisher...
multichain-cli %CHAIN% sendasset !PUB_ADDR! CredibilityToken 10 >nul
timeout /t 2 /nobreak >nul

echo ==========================================================
echo  9. Final Ledger Verification
echo ==========================================================

echo [Items in news_registry for %NEWS_ID%]:
multichain-cli %CHAIN% liststreamkeyitems news_registry "%NEWS_ID%"

echo.
echo [Items in validation_stream for %NEWS_ID%]:
multichain-cli %CHAIN% liststreamkeyitems validation_stream "%NEWS_ID%"

echo.
echo [Publisher Token Balance]:
multichain-cli %CHAIN% getaddressbalances !PUB_ADDR!

echo ==========================================================
echo  Setup and verification completed successfully.
echo ==========================================================
pause