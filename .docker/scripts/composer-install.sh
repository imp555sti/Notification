#!/usr/bin/env sh
set -eu

cd /opt/app-root

if [ ! -f composer.phar ]; then
  curl -sS https://getcomposer.org/installer -o composer-setup.php
  php composer-setup.php --quiet --filename=composer.phar
fi

COMPOSER_VENDOR_DIR=/opt/app-root/src/vendor php composer.phar install --no-interaction --no-security-blocking

if [ -f composer-setup.php ]; then
  rm composer-setup.php
fi

if [ -f composer.phar ]; then
  rm composer.phar
fi

exit 0
