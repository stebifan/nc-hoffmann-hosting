#!/bin/bash
set -eu

# version_greater A B returns whether A > B
version_greater() {
    [ "$(printf '%s\n' "$@" | sort -t '.' -n -k1,1 -k2,2 -k3,3 -k4,4 | head -n 1)" != "$1" ]
}

# return true if specified directory is empty
directory_empty() {
    [ -z "$(ls -A "$1/")" ]
}

run_as() {
  if [ "$(id -u)" = 0 ]; then
    su - www-data -s /bin/sh -c "$1"
  else
    sh -c "$1"
  fi
}

installed_version="0.0.0.0"
if [ -f /var/www/html/version.php ]; then
    # shellcheck disable=SC2016
    installed_version="$(php -r 'require "/var/www/html/version.php"; echo implode(".", $OC_Version);')"
fi
# shellcheck disable=SC2016
image_version="$(php -r 'require "/usr/src/nextcloud/version.php"; echo implode(".", $OC_Version);')"

if version_greater "$installed_version" "$image_version"; then
    echo "Can't start Nextcloud because the version of the data ($installed_version) is higher than the docker image version ($image_version) and downgrading is not supported. Are you sure you have pulled the newest image version?"
    exit 1
fi

if version_greater "$image_version" "$installed_version"; then
    if [ "$installed_version" != "0.0.0.0" ]; then
        run_as 'php /var/www/html/occ app:list' | sed -n "/Enabled:/,/Disabled:/p" > /tmp/list_before
    fi
    if [ "$(id -u)" = 0 ]; then
      rsync_options="-rlDog --chown www-data:root"
    else
      rsync_options="-rlD"
    fi
    rsync $rsync_options --delete --exclude /config/ --exclude /data/ --exclude /custom_apps/ --exclude /themes/ /usr/src/nextcloud/ /var/www/html/

    for dir in config data custom_apps themes; do
        if [ ! -d "/var/www/html/$dir" ] || directory_empty "/var/www/html/$dir"; then
            rsync $rsync_options --include "/$dir/" --exclude '/*' /usr/src/nextcloud/ /var/www/html/
        fi
    done

    if [ "$installed_version" != "0.0.0.0" ]; then
        run_as 'php /var/www/html/occ upgrade --no-app-disable'

        run_as 'php /var/www/html/occ app:list' | sed -n "/Enabled:/,/Disabled:/p" > /tmp/list_after
        echo "The following apps have beed disabled:"
        diff /tmp/list_before /tmp/list_after | grep '<' | cut -d- -f2 | cut -d: -f1
        rm -f /tmp/list_before /tmp/list_after
    fi
fi
# Check if Nextcloud is already installed (Old Check)
#grep -iq installed /var/www/html/config/config.php && exec "$@" && exit 0

# Repair permissions on Themes Folder
chown -cR www-data:root /var/www/html/themes
check_install=$(grep -Fxqv installed /var/www/html/config/config.php)

# Install Nextcloud if not installed
if [ $check_install ]; then
su -m - www-data -s /bin/sh -c "php /var/www/html/occ maintenance:install -q -n --database-host "db" --database "$DB_DRIVER" --database-name "nextcloud"  --database-user "nextcloud" --database-pass "$NC_DB_PASSWORD" --admin-user "$NEXTCLOUD_ADMIN_USER" --admin-pass "$NEXTCLOUD_ADMIN_PASSWORD" --data-dir "/var/www/html/data""
su -m - www-data -s /bin/sh -c "php /var/www/html/occ config:system:set trusted_domains 2 --value="$DOMAIN""
echo "Nextcloud is installed"
fi

# If Theme Variable is set, use the Theme
if [ -v THEME ]; then
su -m - www-data -s /bin/sh -c "php /var/www/html/occ config:system:set theme --value="$THEME""
echo "Theme $THEME is Activated"
fi

#Enable Encryption
check_encryption_on=$(su -m - www-data -s /bin/sh -c "php /var/www/html/occ encryption:status" | grep -q "enabled: true")
check_encryption_off=$(su -m - www-data -s /bin/sh -c "php /var/www/html/occ encryption:status" | grep -q "enabled: false")
if [ "$ENCRYPTION" = true ]; then
    if [ $check_encryption_off ]; then
        su -m - www-data -s /bin/sh -c "php /var/www/html/occ app:enable encryption"
        su -m - www-data -s /bin/sh -c "php /var/www/html/occ encryption:enable"
        su -m - www-data -s /bin/sh -c "php /var/www/html/occ encryption:status"
        echo "Encryption Enabled"
    fi
else
    if [ $check_encryption_on ]; then
        su -m - www-data -s /bin/sh -c "php /var/www/html/occ app:enable encryption"
        su -m - www-data -s /bin/sh -c "php /var/www/html/occ encryption:enable"
        su -m - www-data -s /bin/sh -c "php /var/www/html/occ encryption:status"
        echo "Encryption Disabled"
    fi
fi

# If SINGLE_USER variable is set, setup user and quota

if [ "$SINGLE_USER" = true ]; then
    user_is=$(su -m - www-data -s /bin/sh -c "php /var/www/html/occ user:list | grep -q "$SINGLE_USER_NAME"")
    user_should="  - $SINGLE_USER_NAME: $SINGLE_USER_FULL_NAME"
    if [ $user_is != $user_should ]; then
        su -m - www-data -s /bin/sh -c 'php /var/www/html/occ user:add --password-from-env --display-name="$SINGLE_USER_FULL_NAME" --group="users" '$SINGLE_USER_NAME''
    fi
    #Check Quota
    quota_is=$(su -m - www-data -s /bin/sh -c "php /var/www/html/occ user:setting $SINGLE_USER_NAME files quota")
    if [ $quota_is != $SINGLE_USER_QUOTA ]; then
        su -m - www-data -s /bin/sh -c "php /var/www/html/occ user:setting $SINGLE_USER_NAME files quota "$SINGLE_USER_QUOTA""
    fi
echo "User $SINGLE_USER_NAME is activated with Quota of $SINGLE_USER_QUOTA"
fi
exec "$@"
