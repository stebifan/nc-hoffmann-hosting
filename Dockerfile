FROM nextcloud:13.0.2-fpm

COPY config.sh /
COPY hoffmann /var/www/html/themes/hoffmann
COPY config.json /
RUN chmod -R /var/www/html/themes
RUN chmod +x /config.sh
ENTRYPOINT ["/config.sh"]
CMD ["apache2-foreground"]