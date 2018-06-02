FROM nextcloud:13.0.2-fpm

COPY config.sh /
RUN chmod +x /config.sh
ENTRYPOINT ["/config.sh"]
CMD ["apache2-foreground"]