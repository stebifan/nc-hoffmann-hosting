FROM nextcloud:13.0.2

COPY config.sh /
COPY hoffmann /var/www/html/themes/hoffmann
RUN chmod +x /config.sh
ENTRYPOINT [/config.sh]