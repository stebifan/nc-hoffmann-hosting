FROM nextcloud:13.0.2
RUN apt-get upgrade && apt-get install sudo -y
COPY config.sh /
COPY hoffmann /var/www/html/themes/hoffmann
RUN chmod +x /config.sh
ENTRYPOINT ["/config.sh"]
CMD ["apache2-foreground"]