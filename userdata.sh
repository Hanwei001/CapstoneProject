#!/bin/bash

# ---------------------------------------------------------
# 1. Update System & Install LAMP Stack (Apache, PHP, MariaDB)
# ---------------------------------------------------------
dnf update -y
dnf install -y httpd mariadb105-server php php-mysqlnd php-gd php-xml php-mbstring wget tar unzip git

# Start and enable services
systemctl enable httpd
systemctl start httpd
systemctl enable mariadb
systemctl start mariadb

# ---------------------------------------------------------
# 2. Setup WordPress Database
# ---------------------------------------------------------
mysql -e "CREATE DATABASE wordpress;"
mysql -e "CREATE USER 'wpuser'@'localhost' IDENTIFIED BY 'wppassword';"
mysql -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# ---------------------------------------------------------
# 3. Download and Install WordPress
# ---------------------------------------------------------
cd /var/www/html
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
rm -f latest.tar.gz

# Set permissions
chown -R apache:apache /var/www/html/wordpress
chmod -R 755 /var/www/html/wordpress

# Configure wp-config.php
cp wordpress/wp-config-sample.php wordpress/wp-config.php
sed -i "s/database_name_here/wordpress/" wordpress/wp-config.php
sed -i "s/username_here/wpuser/" wordpress/wp-config.php
sed -i "s/password_here/wppassword/" wordpress/wp-config.php

# ---------------------------------------------------------
# 4. Configure Apache VirtualHost
# ---------------------------------------------------------
cat <<EOF > /etc/httpd/conf.d/wordpress.conf
<VirtualHost *:80>
    DocumentRoot /var/www/html/wordpress
    <Directory /var/www/html/wordpress>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

# ---------------------------------------------------------
# 5. Generate seaside.html (Optimized for Terraform/JS)
# ---------------------------------------------------------
cat <<'EOF' > /var/www/html/wordpress/seaside.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Seaside Vacation Adviser | AWS Serverless</title>
    <style>
        :root { --primary: #0077be; --bg: #f4f7f9; --text: #2c3e50; }
        body { font-family: sans-serif; background: var(--bg); color: var(--text); display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; }
        .card { background: white; padding: 2.5rem; border-radius: 24px; box-shadow: 0 20px 40px rgba(0,0,0,0.08); width: 480px; text-align: center; }
        .search-box { display: flex; gap: 12px; margin: 2rem 0; }
        input { flex: 1; padding: 12px; border: 2px solid #edf2f7; border-radius: 12px; font-size: 1rem; }
        button { padding: 12px 24px; background: var(--primary); color: white; border: none; border-radius: 12px; cursor: pointer; font-weight: 600; }
        #loading { display: none; margin: 20px 0; color: var(--primary); font-weight: 500; }
        #resultArea { display: none; text-align: left; border-top: 1px solid #f1f1f1; padding-top: 1rem; }
        .period-item { background: #f0f9ff; padding: 10px; border-radius: 8px; margin-top: 8px; color: #0369a1; font-weight: 600; border: 1px solid #e0f2fe; }
    </style>
</head>
<body>
<div class="card">
    <h1>🏝️ Seaside Adviser</h1>
    <p style="color: #7f8c8d;">Find the perfect swimming window based on the data from last 365 days.</p>
    <div class="search-box">
        <input type="text" id="cityInput" placeholder="Enter city (e.g. Nice, Phuket)">
        <button onclick="checkWeather()">Search</button>
    </div>
    <div id="loading">🌊 Fetching satellite marine data...</div>
    <div id="resultArea">
        <h2 id="resCity" style="color: var(--primary);"></h2>
        <p>Avg Sea Temp: <span id="resAvgTemp" style="font-weight:700;"></span>°C</p>
        <p style="font-weight: 700; margin-bottom: 5px;">📅 Recommended Periods:</p>
        <div id="resPeriods"></div>
    </div>
</div>

<script>
    async function checkWeather() {
        // This placeholder is replaced by Terraform 'replace' function
        const apiURL = "INSERT_API_URL_HERE"; 
        
        const city = document.getElementById('cityInput').value.trim();
        if (!city) { alert("Please enter a city."); return; }

        document.getElementById('loading').style.display = 'block';
        document.getElementById('resultArea').style.display = 'none';

        try {
            const response = await fetch(apiURL, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ "city": city })
            });
            const data = await response.json();
            let res = (data.body && typeof data.body === 'string') ? JSON.parse(data.body) : data;

            if (response.ok && !res.error) {
                // String concatenation avoids the ${} syntax issues
                document.getElementById('resCity').innerText = "📍 " + res.city;
                document.getElementById('resAvgTemp').innerText = res.avg_temp;
                const periodsDiv = document.getElementById('resPeriods');
                periodsDiv.innerHTML = '';
                
                if (res.ideal_periods && res.ideal_periods.length > 0) {
                    res.ideal_periods.forEach(function(p) {
                        const el = document.createElement('div');
                        el.className = 'period-item';
                        el.innerText = "☀️ " + p;
                        periodsDiv.appendChild(el);
                    });
                } else {
                    periodsDiv.innerHTML = '<p>No periods met the 21°C criteria.</p>';
                }
                document.getElementById('resultArea').style.display = 'block';
            } else {
                alert("API Error: " + (res.error || "Unknown error"));
            }
        } catch (e) {
            alert("Network Error: Check API URL or CORS.");
        } finally {
            document.getElementById('loading').style.display = 'none';
        }
    }
</script>
</body>
</html>
EOF

# Set permissions and restart Apache
chown apache:apache /var/www/html/wordpress/seaside.html
systemctl restart httpd