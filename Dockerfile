FROM nextcloud:13.0.2

RUN apt-get update && apt-get install -y \
    supervisor \
    sudo \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir /var/log/supervisord /var/run/supervisord

COPY supervisord.conf /etc/supervisor/supervisord.conf

COPY hoffmann /var/www/html/themes/hoffmann
COPY config.sh /
RUN chmod +x /config.sh
RUN ["/config.sh"]
CMD ["/usr/bin/supervisord"]
<<<<<<< HEAD
CMD ["sudo -u www-data php /var/www/html/occ config:system:set theme --value="hoffmann""]
=======
>>>>>>> a2ea170c514f6ee06c15d87edde0ab12f2c3fde5
