FROM nextcloud:13.0.2-fpm

COPY config.sh /
COPY hoffmann /var/www/html/themes/hoffmann
COPY demo /var/www/html/themes/demo
COPY tst /var/www/html/themes/tst
RUN chmod +x /config.sh
ENTRYPOINT ["/config.sh"]
CMD ["php-fpm"]