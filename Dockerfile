FROM php:7.2-cli

MAINTAINER Steve Henty steve@gravityflow.io

# Install required system packages
RUN apt-get update && \
    apt-get -y install \
            git \
            zlib1g-dev \
            libssl-dev \
            libfreetype6-dev \
            libjpeg62-turbo-dev \
            libpng-dev \
            mariadb-client \
            sudo less \
            zip unzip \
        --no-install-recommends && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install php extensions
RUN docker-php-ext-install \
    bcmath \
    gd \
    zip

RUN docker-php-ext-install -j$(nproc) iconv \
        && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
        && docker-php-ext-install -j$(nproc) gd

# Add mysql drivers required for wp-browser
RUN docker-php-ext-install mysqli pdo_mysql

# Configure php
RUN echo "date.timezone = UTC" >> /usr/local/etc/php/php.ini

# Install composer
ENV COMPOSER_ALLOW_SUPERUSER=1
RUN curl -sS https://getcomposer.org/installer | php -- \
        --filename=composer \
        --install-dir=/usr/local/bin
RUN composer global require --optimize-autoloader \
        "hirak/prestissimo"

RUN composer global require "lucatume/wp-browser=^2.0" --prefer-dist --optimize-autoloader && \
    composer clear-cache && \
    ln -s ~/.composer/vendor/bin/codecept /usr/local/bin/codecept

# Add WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
RUN chmod +x wp-cli.phar
RUN mv wp-cli.phar /usr/local/bin/wp

# Prepare application
WORKDIR /repo

# Add source-code
COPY . /repo

WORKDIR /project

ADD docker-entrypoint.sh /

RUN ["chmod", "+x", "/docker-entrypoint.sh"]
