FROM nextcloud:13.0.2

COPY config.sh /
COPY hoffmann /var/www/html/themes/hoffmann
RUN chmod +x /config.sh
RUN chown -cR www-data:www-data /var/www/html/themes/hoffmann
ENTRYPOINT ["/config.sh"]
CMD ["apache2-foreground"]