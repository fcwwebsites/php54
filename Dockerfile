FROM php:5.6-cli

WORKDIR "/var/www/html"

ENV LOG_PREFIX /var/log/php-fpm
ENV TEMP_PREFIX /tmp
ENV CACHE_PREFIX /var/cache
ENV PATH $PATH:/root/.composer/vendor/bin
ENV APACHE_DOCUMENT_ROOT /var/www/html
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2/apache2.pid
ENV APACHE_RUN_DIR /var/run/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV TZ America/Bahia

RUN set -x \
    && mkdir -p /var/run \
    && mkdir -p /var/lock/apache2 \
    && mkdir -p /var/run/apache2 \
    && mkdir -p ${LOG_PREFIX} \
    && mkdir -p /var/www/html \
    && touch ${LOG_PREFIX}/access.log \
    && touch ${LOG_PREFIX}/error.log \
    && ln -sf /dev/stdout ${LOG_PREFIX}/access.log \
    && ln -sf /dev/stderr ${LOG_PREFIX}/error.log \
    && curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash - \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
       openssh-client \
       git \
       libgmp3-dev zlib1g \
       libzip-dev \
       libxml2-dev \
       wget \
       nodejs \
       ruby-sass \
       apache2 \
       nano \
       supervisor \
       libmemcached-dev \
       libpng-dev \
       libcurl4-gnutls-dev \
       libonig-dev \
       libgmp-dev \
    && ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h \
    && docker-php-ext-install mbstring \
       mysqli \
       pdo \
       pdo_mysql \
       gmp \
       bcmath \
       opcache \
       zip \
       simplexml \
       xml \
       soap \
       json \
       dom \
       gd \
       fileinfo \
       curl \
       sockets \
    && pecl install redis-4.3.0  \
    && pecl install memcached-2.2.0  \
    && docker-php-ext-enable redis  \
    && docker-php-ext-enable memcached \
    && apt-get -y autoremove \
    && a2dismod mpm_prefork \
    && a2enmod mpm_event \
    && a2enmod proxy_fcgi \
    && a2enmod actions \
    && a2enmod rewrite \
    && a2enmod setenvif \
    && a2enmod expires \
    && npm install -g gulp \
    && mkdir -p /run/php/ \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && rm /var/log/lastlog /var/log/faillog

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
COPY supervisor/supervisord/supervisord.conf /etc/supervisor/supervisord.conf
COPY supervisor/supervisord/conf.d/ /etc/supervisor/conf.d/
COPY script /script
COPY apache2 /apache2-files

RUN chmod +x /script/docker-entrypoint.sh \
    && chmod +x /script/supervisor.sh \
    && cp /apache2-files/conf-enabled/php-fpm.conf /etc/apache2/conf-enabled/php-fpm.conf \
    && cp /apache2-files/apache2.conf /etc/apache2/apache2.conf \
    && cp /apache2-files/sites-enabled/000-default.conf /etc/apache2/sites-enabled/000-default.conf \
    && ln -sf /dev/stdout ${APACHE_LOG_DIR}/access.log \
    && ln -sf /dev/stderr ${APACHE_LOG_DIR}/error.log

EXPOSE 80

ENTRYPOINT ["/script/docker-entrypoint.sh"]
