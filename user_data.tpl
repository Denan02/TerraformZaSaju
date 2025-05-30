#!/bin/bash
echo "Configuring ECS agent"
cat <<'EOF' | sudo tee /etc/ecs/ecs.config
ECS_CLUSTER=${cluster_name}
ECS_CONTAINER_INSTANCE_PROPAGATE_TAGS_FROM=ec2_instance
EOF

# RESTART ECS AGENT!
systemctl restart ecs
systemctl enable ecs

# Update system
yum update -y

# Install Apache
yum install -y httpd

# Na Amazon Linux, moduli su već dostupni, samo ih enable-ujte u config
# Dodajte LoadModule direktive u main config
cat <<'APACHE_CONFIG' >> /etc/httpd/conf/httpd.conf

# Enable required modules
LoadModule rewrite_module modules/mod_rewrite.so
LoadModule proxy_module modules/mod_proxy.so
LoadModule proxy_http_module modules/mod_proxy_http.so
APACHE_CONFIG

# Kreiraj virtual host
cat <<'VHOST' > /etc/httpd/conf.d/www.conf
<VirtualHost *:80>
  RewriteEngine On
  RewriteRule ^/$ http://localhost:3000/nekretnine.html [P,L]
  ProxyPass / http://localhost:3000/
  ProxyPassReverse / http://localhost:3000/
  ErrorLog /var/log/httpd/error.log
  CustomLog /var/log/httpd/access.log combined
  ProxyPreserveHost On
</VirtualHost>
VHOST

# Test config
httpd -t

# Enable i start httpd
systemctl enable httpd
systemctl start httpd

# Debug output
echo "Apache status:" >> /var/log/user-data.log
systemctl status httpd >> /var/log/user-data.log
