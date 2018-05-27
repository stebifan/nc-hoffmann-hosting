#!/bin/sh
runuser -l www-data -c 'php /var/www/html/occ config:system:set theme --value="hoffmann"'