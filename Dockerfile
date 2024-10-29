FROM jkaninda/nginx-php-fpm:8.3 AS base

USER root
WORKDIR /var/www/html
VOLUME /var/www/html/storage

RUN chown -R root:root /var/www/html

# timezone environment
ENV TZ=UTC \
  # locale
  LANG=en_US.UTF-8 \
  LANGUAGE=en_US:en \
  LC_ALL=en_US.UTF-8 \
  # composer environment
  COMPOSER_ALLOW_SUPERUSER=1 \
  COMPOSER_HOME=/composer

COPY --from=composer:2.6 /usr/bin/composer /usr/bin/composer

RUN <<EOF
  apt-get update
  apt-get -y install --no-install-recommends \
    locales \
    git \
    unzip \
    libzip-dev \
    libicu-dev \
    libonig-dev
  locale-gen en_US.UTF-8
  localedef -f UTF-8 -i en_US en_US.UTF-8

  composer config -g process-timeout 3600
  composer config -g repos.packagist composer https://packagist.org
EOF

FROM base AS deploy

COPY docker/php.deploy.ini /usr/local/etc/php/php.ini
COPY ./src /var/www/html

RUN <<EOF
  composer install
  chmod -R 777 /var/www/html
EOF

RUN docker-php-ext-install mysqli pdo pdo_mysql
