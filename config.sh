#!/bin/sh
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
        su -p www-data -s /bin/sh -c "$1"
    else
        sh -c "$1"
    fi
}

if expr "$1" : "apache" 1>/dev/null || [ "$1" = "php-fpm" ] || [ "${NEXTCLOUD_UPDATE:-0}" -eq 1 ]; then
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
        echo "Initializing nextcloud $image_version ..."
        if [ "$installed_version" != "0.0.0.0" ]; then
            echo "Upgrading nextcloud from $installed_version ..."
            run_as 'php /var/www/html/occ app:list' | sed -n "/Enabled:/,/Disabled:/p" > /tmp/list_before
        fi
        if [ "$(id -u)" = 0 ]; then
            rsync_options="-rlDog --chown www-data:root"
        else
            rsync_options="-rlD"
        fi
        rsync $rsync_options --delete --exclude-from=/upgrade.exclude /usr/src/nextcloud/ /var/www/html/

        for dir in config data custom_apps themes; do
            if [ ! -d "/var/www/html/$dir" ] || directory_empty "/var/www/html/$dir"; then
                rsync $rsync_options --include "/$dir/" --exclude '/*' /usr/src/nextcloud/ /var/www/html/
            fi
        done
        echo "Initializing finished"

        #install
        if [ "$installed_version" = "0.0.0.0" ]; then
            echo "New nextcloud instance - sleep 60 sec. for Mysql Start"
	    	sleep 60
        	# Install Nextcloud if not installed
		su -m - www-data -s /bin/sh -c "php /var/www/html/occ maintenance:install -q -n --database-host "db" --database "$DB_DRIVER" --database-name "nextcloud"  --database-user "nextcloud" --database-pass "$NC_DB_PASSWORD" --admin-user "$NEXTCLOUD_ADMIN_USER" --admin-pass "$NEXTCLOUD_ADMIN_PASSWORD" --data-dir "/var/www/html/data""
		su -m - www-data -s /bin/sh -c "php /var/www/html/occ config:system:set trusted_domains 2 --value="$DOMAIN""
		echo "Nextcloud is installed"

		# Enable Encryption
		if [ "$ENCRYPTION" = true ]; then
			su -m - www-data -s /bin/sh -c "php /var/www/html/occ maintenance:mode --on"
    			su -m - www-data -s /bin/sh -c "php /var/www/html/occ app:enable encryption"
    			su -m - www-data -s /bin/sh -c "php /var/www/html/occ encryption:enable"
    			su -m - www-data -s /bin/sh -c "php /var/www/html/occ maintenance:mode --off"
    			echo "Encryption Enabled"
		fi

		# If SINGLE_USER variable is set, setup user and quota
		if [ "$SINGLE_USER" = true ]; then
    			su -m - www-data -s /bin/sh -c 'php /var/www/html/occ user:add --password-from-env --display-name="$SINGLE_USER_FULL_NAME" --group="users" '$SINGLE_USER_NAME''
    			su -m - www-data -s /bin/sh -c "php /var/www/html/occ user:setting $SINGLE_USER_NAME files quota "$SINGLE_USER_QUOTA""
			echo "User $SINGLE_USER_NAME is activated with Quota of $SINGLE_USER_QUOTA"
		fi
        #upgrade
        else
            run_as 'php /var/www/html/occ upgrade'

            run_as 'php /var/www/html/occ app:list' | sed -n "/Enabled:/,/Disabled:/p" > /tmp/list_after
            echo "The following apps have been disabled:"
            diff /tmp/list_before /tmp/list_after | grep '<' | cut -d- -f2 | cut -d: -f1
            rm -f /tmp/list_before /tmp/list_after

        fi
    fi
fi

exec "$@"
