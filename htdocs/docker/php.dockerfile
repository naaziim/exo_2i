FROM php:8.2-fpm-alpine

# --- Proxy support during build ---


# --- Alpine repositories ---
RUN echo "https://dl-cdn.alpinelinux.org/alpine/v3.20/main" > /etc/apk/repositories && \
    echo "https://dl-cdn.alpinelinux.org/alpine/v3.20/community" >> /etc/apk/repositories

# --- System build dependencies & PHP extensions ---
RUN set -ex \
    && apk update && apk add --no-cache \
        autoconf \
        g++ \
        gcc \
        make \
        musl-dev \
        pkgconfig \
        imagemagick-dev \
        imagemagick \
        libtool \
        bash \
        coreutils \
        file \
        re2c \
        curl \
        icu \
        icu-dev \
        zlib \
        zlib-dev \
        libjpeg-turbo \
        libjpeg-turbo-dev \
        libpng \
        libpng-dev \
        libwebp \
        libwebp-dev \
        libxml2 \
        libxml2-dev \
    # Download Imagick manually (proxy-safe)
    && curl -L -O https://pecl.php.net/get/imagick-3.7.0.tgz \
    && pecl install imagick-3.7.0.tgz \
    && docker-php-ext-enable imagick \
    # Build all required PHP extensions
    && docker-php-ext-install pdo pdo_mysql exif intl gd simplexml \
    # Cleanup build dependencies
    && apk del g++ gcc make musl-dev pkgconfig autoconf libtool re2c icu-dev libjpeg-turbo-dev libpng-dev libwebp-dev zlib-dev libxml2-dev



# --- Optional: install Composer globally ---
RUN set -ex \
    && curl -L https://getcomposer.org/installer -o composer-setup.php \
    && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
    && rm composer-setup.php

WORKDIR /app
