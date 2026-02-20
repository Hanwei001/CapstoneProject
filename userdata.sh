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
# 5. Generate seaside.html (With Chart.js Integration)
# ---------------------------------------------------------
cat <<'EOF' > /var/www/html/wordpress/seaside.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Seaside Vacation Adviser | AWS Serverless</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        :root { --primary: #0077be; --bg: #f4f7f9; --text: #2c3e50; }
        body { font-family: 'Segoe UI', sans-serif; background: var(--bg); color: var(--text); display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; }
        .card { background: white; padding: 2.5rem; border-radius: 24px; box-shadow: 0 20px 40px rgba(0,0,0,0.08); width: 100%; max-width: 550px; text-align: center; }
        .search-box { display: flex; gap: 12px; margin: 2rem 0; }
        input { flex: 1; padding: 12px; border: 2px solid #edf2f7; border-radius: 12px; font-size: 1rem; }
        button { padding: 12px 24px; background: var(--primary); color: white; border: none; border-radius: 12px; cursor: pointer; font-weight: 600; }
        #loading { display: none; margin: 20px 0; color: var(--primary); font-weight: 500; }
        #resultArea { display: none; text-align: left; border-top: 1px solid #f1f1f1; padding-top: 1rem; }
        .stat-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 15px; margin-bottom: 1rem; }
        .stat-item { background: #f8fafc; padding: 10px; border-radius: 12px; border: 1px solid #f1f5f9; }
        .stat-label { font-size: 0.7rem; color: #94a3b8; font-weight: 700; text-transform: uppercase; }
        .period-item { background: #f0f9ff; padding: 10px; border-radius: 8px; margin-top: 8px; color: #0369a1; font-weight: 600; font-size: 0.9rem; }
        .chart-container { position: relative; height: 250px; width: 100%; margin-top: 1.5rem; }
    </style>
</head>
<body>
<div class="card">
    <h1>🏝️ Seaside Adviser</h1>
    <p style="color: #7f8c8d;">Historical analysis of sea temperatures (365 days).</p>
    <div class="search-box">
        <input type="text" id="cityInput" placeholder="Enter city (e.g. Nice, Phuket)">
        <button onclick="checkWeather()">Search</button>
    </div>
    <div id="loading">🌊 Fetching satellite marine data...</div>
    <div id="resultArea">
        <div class="stat-grid">
            <div class="stat-item">
                <div class="stat-label">Location</div>
                <div id="resCity" style="font-weight: 700; color: var(--primary);"></div>
            </div>
            <div class="stat-item">
                <div class="stat-label">Avg Temp</div>
                <div style="font-weight: 700; color: var(--primary);"><span id="resAvgTemp"></span>°C</div>
            </div>
        </div>
        
        <p style="font-weight: 700; margin-bottom: 5px;">📅 Recommended Swimming Windows:</p>
        <div id="resPeriods"></div>

        <div class="chart-container">
            <canvas id="tempChart"></canvas>
        </div>
    </div>
</div>

<script>
    let myChart = null;

    async function checkWeather() {
        // Placeholder replaced by Terraform replace()
        const apiURL = "INSERT_API_URL_HERE"; 
        
        const city = document.getElementById('cityInput').value.trim();
        if (!city) return;

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
                document.getElementById('resCity').innerText = "📍 " + res.city + ", " + res.country;
                document.getElementById('resAvgTemp').innerText = res.avg_temp;
                
                // Render periods
                const periodsDiv = document.getElementById('resPeriods');
                periodsDiv.innerHTML = '';
                if (res.ideal_periods.length > 0) {
                    res.ideal_periods.forEach(p => {
                        const el = document.createElement('div');
                        el.className = 'period-item';
                        el.innerText = "☀️ " + p;
                        periodsDiv.appendChild(el);
                    });
                } else {
                    periodsDiv.innerHTML = '<p style="font-style:italic; color:#94a3b8;">No periods met the 21°C criteria.</p>';
                }

                // Render Chart
                renderTempChart(res.chart_data);
                document.getElementById('resultArea').style.display = 'block';
            } else {
                alert("API Error: " + (res.error || "Unknown error"));
            }
        } catch (e) {
            alert("Network Error: Could not connect to AWS.");
        } finally {
            document.getElementById('loading').style.display = 'none';
        }
    }

    function renderTempChart(chartData) {
        const ctx = document.getElementById('tempChart').getContext('2d');
        if (myChart) myChart.destroy();

        myChart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: chartData.labels,
                datasets: [{
                    label: 'Sea Temp (°C)',
                    data: chartData.values,
                    borderColor: '#0077be',
                    backgroundColor: 'rgba(0, 119, 190, 0.1)',
                    fill: true,
                    tension: 0.4,
                    pointRadius: 0
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    x: { display: false },
                    y: { suggestedMin: 10, ticks: { callback: v => v + '°' } }
                },
                plugins: {
                    legend: { display: false },
                    tooltip: { mode: 'index', intersect: false }
                }
            }
        });
    }
</script>
</body>
</html>
EOF

# Set permissions and restart Apache
chown apache:apache /var/www/html/wordpress/seaside.html
systemctl restart httpd