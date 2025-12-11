---

## 📑 Mục lục

1. [Giới thiệu](#giới-thiệu)  
2. [Hạ tầng khóa công khai (PKI)](#hạ-tầng-khóa-công-khai-pki)  
3. [Công cụ OpenSSL](#công-cụ-openssl)  
4. [Tạo chữ ký số cá nhân bằng OpenSSL 1.1.1w](#tạo-chữ-ký-số-cá-nhân-bằng-openssl-111w)  
5. [Ký số PDF bằng Adobe Acrobat Pro](#ký-số-pdf-bằng-adobe-acrobat-pro)  
6. [Một số lỗi thường gặp và cách khắc phục](#một-số-lỗi-thường-gặp-và-cách-khắc-phục)  
7. [Thực nghiệm và kết quả](#thực-nghiệm-và-kết-quả)  
8. [Kết luận](#kết-luận)  

---

## 1. Giới thiệu

Chữ ký số (digital signature) là thành phần quan trọng trong các hệ thống giao dịch điện tử, cho phép:

- Xác thực người gửi (authentication)  
- Đảm bảo toàn vẹn dữ liệu (integrity)  
- Chống chối bỏ (non-repudiation)  

Mục tiêu của báo cáo:

- Tự xây dựng **chữ ký số cá nhân self-signed** bằng OpenSSL trên Windows  
- Đóng gói chữ ký ở dạng **PKCS#12 (.p12)**  
- Import vào **Adobe Acrobat Pro** và sử dụng để ký số tài liệu PDF  
- Ghi nhận các lỗi thực tế gặp phải (OpenSSL 3.x, cấu hình `openssl.cnf`, lỗi import .p12, …) và cách khắc phục.

---

## 2. Hạ tầng khóa công khai (PKI)

Tóm tắt các khái niệm chính:

- **Khóa công khai / khóa bí mật (Public/Private key)**  
- **Chứng thư số (Digital Certificate)** – chứa public key + thông tin chủ thể + chữ ký của CA  
- **CA (Certificate Authority)** – tổ chức phát hành và xác thực chứng thư  
- **PKCS#12** – định dạng file đóng gói *private key + certificate* (đuôi `.p12` / `.pfx`)  
- **Self-signed certificate** – chứng thư tự ký, không do CA bên ngoài cấp, dùng chủ yếu cho nội bộ / thử nghiệm.

Sơ đồ luồng cơ bản khi ký số PDF:

1. Người dùng tạo cặp khóa (RSA 2048 bit)  
2. Sinh chứng thư tự ký (X.509) từ cặp khóa này  
3. Gói private key + certificate vào file `.p12`  
4. Import `.p12` vào phần mềm đọc PDF (Adobe Acrobat)  
5. Dùng Digital ID để ký tài liệu PDF.

---

## 3. Công cụ OpenSSL

### 3.1. Lý do chọn OpenSSL

- Mã nguồn mở, miễn phí  
- Hỗ trợ đầy đủ các thuật toán bất đối xứng (RSA, ECC, …)  
- Có sẵn trên nhiều hệ điều hành, trong đó có Windows  
- Tạo được các loại chứng thư, CSR, và file PKCS#12 cần thiết cho Acrobat.

### 3.2. Phiên bản sử dụng

Trong quá trình làm, có hai nhánh phiên bản:

- **OpenSSL 3.5.x:**  
  - Ưu điểm: mới, hỗ trợ nhiều thuật toán, provider mới  
  - Nhược điểm: tạo file `.p12` dùng chuẩn PBES2 + AES ⇒ **Adobe Acrobat Pro 2022 không đọc được**, báo lỗi *“Could not open digital ID file with the password provided”*.

- ✅ **OpenSSL 1.1.1w:**  
  - Dùng chuẩn PKCS#12 “legacy” với 3DES + SHA1  
  - **Tương thích 100% với Adobe Acrobat Pro 2022 (64-bit)**  
  - Đây là phiên bản được sử dụng cho toàn bộ thực nghiệm cuối cùng.

---

## 4. Tạo chữ ký số cá nhân bằng OpenSSL 1.1.1w

### 4.1. Cấu hình môi trường

Giả sử OpenSSL 1.1.1w được cài tại:

```text
D:\BÀI HỌC Ổ D\1 Thạc sĩ ATTT\0 HK3\Hạ tầng khóa công khai _ PKI\Apps\openssl-1.1.1w\openssl-1.1\x64\bin

Mở Command Prompt:

cd /d "D:\BÀI HỌC Ổ D\1 Thạc sĩ ATTT\0 HK3\Hạ tầng khóa công khai _ PKI\Apps\openssl-1.1.1w\openssl-1.1\x64\bin"
openssl version

Kết quả:

OpenSSL 1.1.1w  11 Sep 2023

4.2. Tạo thư mục lưu khóa & chứng thư

mkdir D:\PKI

4.3. Tạo private key & self-signed certificate

Mở OpenSSL shell:

cd /d "D:\BÀI HỌC Ổ D\1 Thạc sĩ ATTT\0 HK3\Hạ tầng khóa công khai _ PKI\Apps\openssl-1.1.1w\openssl-1.1\x64\bin"
openssl

Tại dấu nhắc OpenSSL> chạy:

req -x509 -newkey rsa:2048 ^
  -keyout "D:\PKI\private.key" ^
  -out "D:\PKI\certificate.crt" ^
  -days 365 -nodes ^
  -subj "/C=VN/ST=Ho Chi Minh/L=Tan Phu/O=Seedcom/OU=IT/CN=Minh Hung/emailAddress=minhhung8712@gmail.com"

Sau khi chạy xong, trong thư mục D:\PKI có:

    private.key – khóa bí mật (RSA 2048 bit)

    certificate.crt – chứng thư X.509 tự ký (self-signed), hạn 1 năm

4.4. Đóng gói thành PKCS#12 (.p12)

Vẫn trong OpenSSL shell:

pkcs12 -export -out "D:\PKI\signature_legacy.p12" ^
  -inkey "D:\PKI\private.key" ^
  -in "D:\PKI\certificate.crt" ^
  -passout pass:123456

Kết quả:

    D:\PKI\signature_legacy.p12 – Digital ID chứa cả private key + certificate.
    Đây là file sẽ import vào Adobe Acrobat.

    🔐 Mật khẩu “123456” chỉ là ví dụ, khi dùng thực tế nên đặt mật khẩu mạnh hơn.

5. Ký số PDF bằng Adobe Acrobat Pro
5.1. Import Digital ID (.p12) vào Acrobat

    Mở Adobe Acrobat Pro (64-bit)

    Vào Edit → Preferences → Signatures

    Mục Identities & Trusted Certificates → bấm More…

    Chọn Add ID → A file → Next

    Chọn file D:\PKI\signature_legacy.p12

    Nhập mật khẩu: 123456

    Acrobat hiển thị Digital ID:

        Minh Hung (Digital ID file)

        Issued by: Minh Hung

        Expires: (ví dụ) 2026-11-17

Từ thời điểm này, chữ ký số đã sẵn sàng để sử dụng.
5.2. Thực hiện ký số trên PDF

    Mở file PDF cần ký

    Vào tab Tools → Certificates

    Chọn Digitally Sign

    Dùng chuột kéo một vùng chữ nhật trên trang PDF – nơi sẽ hiển thị chữ ký

    Hộp thoại Sign with a Digital ID xuất hiện → chọn Digital ID Minh Hung (Digital ID file) → Continue

    Nhập mật khẩu 123456 → Sign

    Chọn nơi lưu file mới (ví dụ document_signed.pdf)

Sau khi lưu, Acrobat hiển thị chữ ký tại vị trí đã chọn, trạng thái:

    “Signed and all signatures are valid” (đối với self-signed sẽ thêm cảnh báo về độ tin cậy của CA, điều này là bình thường trong môi trường thử nghiệm).

6. Một số lỗi thường gặp và cách khắc phục
6.1. “Could not open digital ID file with the password provided”

Triệu chứng:
Khi import .p12 vào Acrobat, dù nhập đúng mật khẩu vẫn báo lỗi.

Nguyên nhân:

    File .p12 được tạo bằng OpenSSL 3.x, dùng chuẩn PBES2 + AES-256 mà Acrobat 2022 chưa hỗ trợ.

    Acrobat hiểu nhầm là sai mật khẩu.

Cách khắc phục:

    Chuyển sang dùng OpenSSL 1.1.1w để tạo lại file .p12 theo chuẩn PKCS#12 cũ (3DES + SHA1).

6.2. Lỗi “Can't open ...\openssl.cnf for reading”

Triệu chứng:

    Khi chạy lệnh req bị lỗi:

    Can't open C:\Program Files\Common Files\FireDaemon SSL\openssl.cnf for reading
    error in req

Nguyên nhân:

    Bản OpenSSL được build với đường dẫn OPENSSL_CONF trỏ tới file cấu hình cũ không tồn tại.

Cách khắc phục (2 hướng):

    Không dùng interactive mode, mà truyền trực tiếp thông tin Distinguished Name bằng tham số -subj như ở mục 4.3
    → Không cần file openssl.cnf.

    Hoặc tự tạo file openssl.cnf mới và dùng tham số -config, ví dụ:

    req -new -key private.key -out request.csr -config "D:\PKI\openssl.cnf"

6.3. Lỗi 'req' is not recognized as an internal or external command

Triệu chứng:

    Gõ req ... trong Command Prompt và bị báo lỗi không nhận lệnh.

Nguyên nhân:

    req là sub-command của OpenSSL, chỉ chạy được khi đã vào shell OpenSSL (OpenSSL>).

Cách khắc phục:

    Chạy:

cd /d "...\openssl-1.1.1w\...\bin"
openssl

Sau đó mới gõ:

    OpenSSL> req ...
    OpenSSL> pkcs12 ...

7. Thực nghiệm và kết quả

    Đã tạo thành công cặp khóa RSA 2048 bit và chứng thư X.509 tự ký bằng OpenSSL 1.1.1w.

    Đã đóng gói private key + certificate thành file .p12 tương thích Acrobat.

    Import thành công Digital ID vào Adobe Acrobat Pro 2022 (64-bit).

    Ký số nhiều file PDF, Acrobat xác nhận:

        Chữ ký hợp lệ

        Nội dung tài liệu không bị sửa đổi sau khi ký

        Thông tin Subject trong certificate hiển thị đúng (CN, email, tổ chức, …).

Có thể chèn thêm hình minh họa:

![OpenSSL 1.1.1w trên Windows](images/openssl-111w.png)
![Digital ID trong Acrobat](images/adobe-digital-id.png)
![Chữ ký số trên PDF](images/pdf-signed.png)

8. Kết luận

    Việc tạo chữ ký số cá nhân bằng OpenSSL trên Windows hoàn toàn khả thi và miễn phí.

    Phiên bản OpenSSL ảnh hưởng trực tiếp đến khả năng tương thích với phần mềm ký số:

        OpenSSL 3.x mạnh hơn nhưng gây lỗi với Acrobat khi tạo .p12.

        OpenSSL 1.1.1w cho kết quả ổn định và tương thích tốt.

    Chữ ký số tự ký (self-signed) phù hợp cho mục đích học tập, thử nghiệm, nội bộ, nhưng không thay thế được chứng thư số thương mại do các CA uy tín (VNPT-CA, FPT-CA, CA2, …) cấp trong thực tế.

Hướng phát triển:

    Thử nghiệm tạo CA nội bộ bằng OpenSSL để cấp nhiều chứng thư con.

    Tích hợp quy trình ký số vào ứng dụng tự viết (ví dụ: ký PDF bằng thư viện iText, pdfbox, …).

    So sánh thao tác ký giữa Adobe Acrobat, Foxit Reader và các công cụ khác.
