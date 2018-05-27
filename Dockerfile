FROM nextcloud:13.0.2

RUN apt-get update && apt-get install -y \
    supervisor \
    sudo \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir /var/log/supervisord /var/run/supervisord
COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY config.sh /
COPY hoffmann /var/www/html/themes/hoffmann
RUN chmod +x /config.sh
CMD /config.sh