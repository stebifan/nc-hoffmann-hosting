FROM nextcloud:13.0.2

RUN apt-get update && apt-get install -y \
    sudo \
  && rm -rf /var/lib/apt/lists/* \
COPY config.sh /
COPY hoffmann /var/www/html/themes/hoffmann
RUN chmod +x /config.sh
CMD /config.sh &