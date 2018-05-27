FROM nextcloud:13.0.2

COPY config.sh /etc/
COPY hoffmann /var/www/html/themes/hoffmann
RUN chmod +x /etc/config.sh
ENTRYPOINT [/etc/config.sh]