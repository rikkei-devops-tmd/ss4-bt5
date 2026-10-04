BÀI TẬP 5: THIẾT LẬP THƯ MỤC WEB AN TOÀN TẠI PHÂN VÙNG HỆ THỐNG (/OPT/)

1. MỤC TIÊU
- Chuyển vị trí lưu trữ website tĩnh và logs ra khỏi các đường dẫn mặc định của hệ thống sang phân vùng /opt/ để cô lập mã nguồn ứng dụng.
- Phân quyền tệp tin và thư mục nâng cao đảm bảo bảo mật và phân tách vai trò rõ ràng giữa tài khoản quản trị thường (devops) và tiến trình chạy của Nginx (www-data).
- Cấu hình Nginx ghi nhận access log và error log trực tiếp vào đường dẫn log mới tại /opt/my-app/logs/.

2. CÁC BƯỚC THỰC HIỆN CHI TIẾT

2.1. Tạo cấu trúc thư mục tại /opt/my-app
Khởi tạo thư mục mã nguồn và thư mục logs:
```bash
sudo mkdir -p /opt/my-app/html
sudo mkdir -p /opt/my-app/logs
```
Tạo tệp index.html trong thư mục html:
```bash
echo "<h1>Production App tai /opt/my-app/</h1>" | sudo tee /opt/my-app/html/index.html
```

2.2. Phân quyền sở hữu và quyền truy cập
Phân quyền sở hữu toàn bộ /opt/my-app cho user devops và group www-data:
```bash
sudo chown -R devops:www-data /opt/my-app
```
Thiết lập quyền truy cập cho thư mục:
- Thư mục html: 755 (devops toàn quyền, www-data đọc và thực thi).
- Thư mục logs: 775 (devops và www-data đều có quyền ghi nhận log).
- Tệp tin tĩnh trong html: 644 (devops đọc/ghi, www-data đọc).
```bash
sudo chmod 755 /opt/my-app /opt/my-app/html
sudo chmod 775 /opt/my-app/logs
sudo find /opt/my-app/html -type f -exec chmod 644 {} +
```

2.3. Cấu hình Server Block Nginx
Mở file cấu hình Nginx:
```bash
sudo nano /etc/nginx/sites-available/my-app-opt.conf
```
Nội dung cấu hình trỏ root và đường dẫn logs:
```nginx
server {
    listen 80;
    server_name _;

    root /opt/my-app/html;
    index index.html;

    access_log /opt/my-app/logs/access.log;
    error_log /opt/my-app/logs/error.log;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

2.4. Kích hoạt cấu hình và tải lại Nginx
```bash
sudo ln -sf /etc/nginx/sites-available/my-app-opt.conf /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

3. KẾT QUẢ KIỂM TRA VÀ LOG TERMINAL

3.1. Kiểm tra phân quyền thư mục trên máy chủ
Lệnh thực hiện:
```bash
ls -la /opt/my-app/
ls -la /opt/my-app/logs/
```
Trích xuất log terminal:
```text
devops@ptit-devops-server:~$ ls -la /opt/my-app/
total 16
drwxr-xr-x 4 devops www-data 4096 Oct  4 10:30 .
drwxr-xr-x 4 root   root     4096 Oct  4 10:28 ..
drwxr-xr-x 2 devops www-data 4096 Oct  4 10:30 html
drwxrwxr-x 2 devops www-data 4096 Oct  4 10:32 logs
```

3.2. Kiểm tra quyền ghi file của user devops không dùng sudo
Lệnh thực hiện:
```bash
echo "<p>Update Test from devops user</p>" >> /opt/my-app/html/index.html
```
Kết quả: Lệnh thực thi thành công không bị báo lỗi Permission denied.

3.3. Kiểm tra nhật ký log phát sinh tự động khi truy cập
Lệnh thực hiện:
```bash
curl http://localhost/
tail -n 2 /opt/my-app/logs/access.log
```
Trích xuất log terminal:
```text
127.0.0.1 - - [04/Oct/2026:10:35:10 +0000] "GET / HTTP/1.1" 200 45 "-" "curl/7.81.0"
```

4. KẾT LUẬN
- Mã nguồn và thư mục logs của ứng dụng được di dời và cô lập an toàn tại phân vùng /opt/.
- Phân quyền giữa devops và www-data hoạt động hoàn hảo, Nginx ghi nhận logs tự động mà không gặp lỗi 403 Forbidden.
