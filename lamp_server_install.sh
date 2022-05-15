#!/bin/bash
#
#Nom		: Script d'installation d'un serveur lamp 
#Description	: Installe apache2, mariadb et php 
#Auteurs	: Mathis Thouvenin, Lyronn Levy, Simon Vener
#Version	: 1.0
#Date		: 15/05/2022
#
#set -x
#
#set -e


DIR_CERTIFICATE=/etc/apache2/certificate

# Mettre à jour le serveur et installer les mises à jour
apt update && apt upgrade -y 

# Installe apache2
apt install apache2 -y

# Lance automatiquement apache2 au démarrage du serveur
systemctl enable apache2

# Afficher la version de apache2
apache2ctl -v

# Installer php
apt install php -y

# Paquets pour l'interaction avec MariaDB
apt install php-pdo php-mysql php-zip php-gd php-mbstring php-curl php-xml php-pear php-bcmath -y

# Afficher les informations PHP
# Supprimer le fichier s'il n'est pas utilisé
cat > /var/www/html/phpinfo.php << "EOF"
<?php
phpinfo();
?>
EOF

# Afficher la version de mariadb
# mariadb -v

# Apache2 SSL
# Activer le module SSL dans Apache2
a2enmod ssl
a2enmod rewrite

# Créer le dossier pour conserver le certificat et la clé privée
mkdir -vp $DIR_CERTIFICATE 

if [ ! -d "$DIR_CERTIFICATE" ]; then
	echo "Le dossier n'existe pas. Veuillez le créer pour conserver le certificat et la clé privée SSL."
fi

cd $DIR_CERTIFICATE 

# Création du certificat auto-signé et de la clé privée
openssl req -newkey rsa:2048 -nodes -keyform PEM -keyout autorite.key -x509 -days 365 -outform PEM -out autorite.crt

# Copie du fichier de conf par défaut
cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.org

# Création du fichier de configuration web par défaut
cat > /etc/apache2/sites-available/000-default.conf << "EOF"
<VirtualHost *:80>
	# Rediriger vers https
	RewriteEngine On
	RewriteCond %{HTTPS} !=on
	RewriteRule ^/?(.*) https://%{SERVER_NAME}/$1 [R=301,L]
</VirtualHost>
<VirtualHost *:443>
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
        SSLEngine on
        SSLCertificateFile /etc/apache2/certificate/autorite.crt
        SSLCertificateKeyFile /etc/apache2/certificate/autorite.key
</VirtualHost>
EOF

systemctl restart apache2

echo "Veuillez importer le fichier autorite.crt dans votre navigateur web"

# Cacher la version de Apache2
sed -i 's/ServerTokens OS/ServerTokens Prod/' /etc/apache2/conf-available/security.conf
sed -i 's/ServerSignature On/ServerSignature Off/' /etc/apache2/conf-available/security.conf

systemctl restart apache2

