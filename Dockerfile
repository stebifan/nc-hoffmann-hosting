FROM nextcloud:13.0.2

RUN apt-get update && apt-get install -y \
    supervisor \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir /var/log/supervisord /var/run/supervisord

COPY supervisord.conf /etc/supervisor/supervisord.conf

COPY hoffmann /var/www/html/themes/hoffmann

CMD ["/usr/bin/supervisord"]