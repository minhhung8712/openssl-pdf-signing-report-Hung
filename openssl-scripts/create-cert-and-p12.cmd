@echo off
echo ==========================================
echo  Tao khoa bi mat + certificate + file P12
echo  (Su dung OpenSSL 1.1.1w tren Windows)
echo ==========================================

REM --- Cau hinh duong dan PKI ---
set "PKI_DIR=D:\PKI"

REM Tao thu muc neu chua co
if not exist "%PKI_DIR%" mkdir "%PKI_DIR%"

REM --- Mo OpenSSL o che do non-interactive ---
echo.
echo [1/2] Tao private.key va certificate.crt ...
openssl req -x509 -newkey rsa:2048 ^
  -keyout "%PKI_DIR%\private.key" ^
  -out "%PKI_DIR%\certificate.crt" ^
  -days 365 -nodes ^
  -subj "/C=VN/ST=Ho Chi Minh/L=Tan Phu/O=Seedcom/OU=IT/CN=Minh Hung/emailAddress=minhhung8712@gmail.com"

if errorlevel 1 (
  echo Loi khi tao certificate. Thoat...
  pause
  exit /b 1
)

echo.
echo [2/2] Tao file PKCS#12 (signature_legacy.p12) ...
openssl pkcs12 -export ^
  -out "%PKI_DIR%\signature_legacy.p12" ^
  -inkey "%PKI_DIR%\private.key" ^
  -in "%PKI_DIR%\certificate.crt" ^
  -passout pass:123456

if errorlevel 1 (
  echo Loi khi tao file P12. Thoat...
  pause
  exit /b 1
)

echo.
echo Hoan tat!
echo  - Private key:      %PKI_DIR%\private.key
echo  - Certificate CRT:  %PKI_DIR%\certificate.crt
echo  - P12 for Acrobat:  %PKI_DIR%\signature_legacy.p12
echo  - Password P12:     123456
echo.
pause
