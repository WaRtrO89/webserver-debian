#!/bin/bash

IP=$1
DOMAIN=$2
PHP=$3
USER=$4

cat << EOF > "/etc/apache2/sites-available/$DOMAIN.conf"
<IfModule mod_ssl.c>
	<VirtualHost $IP:443 >
		ServerName $DOMAIN
		ServerAlias www.$DOMAIN

		UseCanonicalName Off

		ErrorLog "/var/www/vhosts/$USER/var/app/system/logs/$DOMAIN/error_ssl.log"
		CustomLog "/var/www/vhosts/$USER/var/app/system/logs/$DOMAIN/access_ssl.log" combined
		DocumentRoot "/var/www/vhosts/$USER/var/app/www/$DOMAIN/httpdocs"

		Include /etc/letsencrypt/options-ssl-apache.conf
		SSLCertificateFile /etc/letsencrypt/live/$DOMAIN/fullchain.pem
		SSLCertificateKeyFile /etc/letsencrypt/live/$DOMAIN/privkey.pem


		TimeOut 1000

		<Directory /var/www/vhosts/$USER/var/app/www/$DOMAIN/httpdocs>
			<IfModule mod_proxy_fcgi.c>
				<Files ~ (\.php$)>
					SetHandler proxy:unix:/run/php/$PHP-fpm.sock|fcgi://localhost
				</Files>
			</IfModule>
		SSLRequireSSL
		</Directory>

		DirectoryIndex "index.php" "index.html" "index.htm"

		Alias /error /var/www/vhosts/$USER/var/app/errors_docs
		ErrorDocument 400 /error/bad_request.html
		ErrorDocument 401 /error/unauthorized.html
		ErrorDocument 403 /error/forbidden.html
		ErrorDocument 404 /error/not_found.html
		ErrorDocument 500 /error/internal_server_error.html
		ErrorDocument 405 /error/method_not_allowed.html
		ErrorDocument 406 /error/not_acceptable.html
		ErrorDocument 407 /error/proxy_authentication_required.html
		ErrorDocument 412 /error/precondition_failed.html
		ErrorDocument 414 /error/unsupported_media_type.html
		ErrorDocument 501 /error/not_implemented.html
		ErrorDocument 502 /error/bad_gateway.html
		ErrorDocument 503 /error/maintenance.html

		<Directory /var/www/vhosts/$USER/var/app/www/$DOMAIN>
			Options -FollowSymLinks -Indexes
			AllowOverride AuthConfig FileInfo Indexes Limit Options=Indexes,SymLinksIfOwnerMatch,MultiViews,ExecCGI,Includes,IncludesNOEXEC
		</Directory>
	</VirtualHost>
</IfModule>

<VirtualHost $DOMAIN:80 >
	ServerName $DOMAIN
	ServerAlias www.$DOMAIN

	UseCanonicalName Off

	ErrorLog "/var/www/vhosts/$USER/var/app/system/logs/$DOMAIN/error.log"
	CustomLog "/var/www/vhosts/$USER/var/app/system/logs/$DOMAIN/access.log" combined
	DocumentRoot "/var/www/vhosts/$USER/var/app/www/$DOMAIN/httpdocs"

	<IfModule mod_rewrite.c>
		RewriteEngine on
		RewriteCond %{SERVER_NAME} =www.$DOMAIN [OR]
		RewriteCond %{SERVER_NAME} =$DOMAIN
		RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]
	</IfModule>
</VirtualHost>
EOF
