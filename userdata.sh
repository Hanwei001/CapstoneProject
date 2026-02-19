#!/bin/bash

# -----------------------------
# 1️⃣ install Apache, PHP, MariaDB
# -----------------------------
dnf update -y
dnf install -y httpd mariadb105-server php php-mysqlnd php-gd php-xml php-mbstring wget tar unzip git


systemctl enable httpd
systemctl start httpd

systemctl enable mariadb
systemctl start mariadb

# -----------------------------
# 2️⃣ create WordPress database and user
# -----------------------------
mysql -e "CREATE DATABASE wordpress;"
mysql -e "CREATE USER 'wpuser'@'localhost' IDENTIFIED BY 'wppassword';"
mysql -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# -----------------------------
# 3️⃣ download and extract WordPress
# -----------------------------
cd /var/www/html
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
rm -f latest.tar.gz

# -----------------------------
# 4️⃣permissions for WordPress files
# -----------------------------
chown -R apache:apache /var/www/html/wordpress
chmod -R 755 /var/www/html/wordpress

# -----------------------------
# 5️⃣ WordPress wp-config.php
# -----------------------------
cp wordpress/wp-config-sample.php wordpress/wp-config.php
sed -i "s/database_name_here/wordpress/" wordpress/wp-config.php
sed -i "s/username_here/wpuser/" wordpress/wp-config.php
sed -i "s/password_here/wppassword/" wordpress/wp-config.php

# -----------------------------
# 6️⃣ configure Apache for WordPress
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