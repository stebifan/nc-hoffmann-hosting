#!/bin/bash
/usr/bin/supervisord
sudo -u www-data php /var/www/html/occ config:system:set theme --value="hoffmann"