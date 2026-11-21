FROM php:8.4.27-apache

RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

RUN { \
      echo 'session.save_handler=files'; \
      echo 'session.save_path=/var/lib/php/sessions'; \
      echo 'session.serialize_handler=php'; \
      echo 'session.upload_progress.enabled=1'; \
      echo 'session.upload_progress.cleanup=Off'; \
      echo 'session.use_strict_mode=0'; \
      echo 'display_errors=On'; \
      echo 'error_reporting=E_ALL'; \
    } > /usr/local/etc/php/conf.d/zz-lab.ini

RUN mkdir -p /var/lib/php/sessions && chown www-data:www-data /var/lib/php/sessions

COPY src/ /var/www/html/