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
CMD ["/usr/bin/supervisord"]
CMD /config.sh
#RUN sudo -u www-data php /var/www/html/occ config:system:set theme --value="hoffmann"
