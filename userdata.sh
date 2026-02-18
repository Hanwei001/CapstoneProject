#!/bin/bash

# -----------------------------
# 1️⃣ 更新系统 & 安装 Apache, PHP, MariaDB
# -----------------------------
dnf update -y
dnf install -y httpd mariadb105-server php php-mysqlnd php-gd php-xml php-mbstring wget tar unzip git

# 启动并设置开机自启
systemctl enable httpd
systemctl start httpd

systemctl enable mariadb
systemctl start mariadb

# -----------------------------
# 2️⃣ 创建 WordPress 数据库和用户
# -----------------------------
mysql -e "CREATE DATABASE wordpress;"
mysql -e "CREATE USER 'wpuser'@'localhost' IDENTIFIED BY 'wppassword';"
mysql -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# -----------------------------
# 3️⃣ 下载并解压 WordPress
# -----------------------------
cd /var/www/html
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
rm -f latest.tar.gz

# -----------------------------
# 4️⃣ 设置文件权限
# -----------------------------
chown -R apache:apache /var/www/html/wordpress
chmod -R 755 /var/www/html/wordpress

# -----------------------------
# 5️⃣ 配置 WordPress wp-config.php
# -----------------------------
cp wordpress/wp-config-sample.php wordpress/wp-config.php
sed -i "s/database_name_here/wordpress/" wordpress/wp-config.php
sed -i "s/username_here/wpuser/" wordpress/wp-config.php
sed -i "s/password_here/wppassword/" wordpress/wp-config.php

# -----------------------------
# 6️⃣ 配置 Apache 指向 WordPress
# -----------------------------
cat <<EOF > /etc/httpd/conf.d/wordpress.conf
<VirtualHost *:80>
    DocumentRoot /var/www/html/wordpress
    <Directory /var/www/html/wordpress>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

systemctl restart httpd