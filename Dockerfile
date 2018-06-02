FROM nextcloud:13.0.2-fpm

COPY config.sh /
COPY hoffmann /var/www/themes/
RUN chmod +x /config.sh
ENTRYPOINT ["/config.sh"]
CMD ["php-fpm"]