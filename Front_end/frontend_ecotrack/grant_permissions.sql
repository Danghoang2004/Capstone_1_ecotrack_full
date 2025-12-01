-- Cấp quyền cho user spring truy cập database ecotrack_demo1
GRANT ALL PRIVILEGES ON ecotrack_demo1.* TO 'spring'@'localhost';
FLUSH PRIVILEGES;
