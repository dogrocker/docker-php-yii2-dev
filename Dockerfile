FROM debian:jessie
MAINTAINER Kanin Peanviriyakulkit <kanin.pean@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
    && apt-get upgrade -y \
	&& apt-get install -y wget \
    && wget -O- http://nginx.org/keys/nginx_signing.key | apt-key add - \
    && echo "deb http://nginx.org/packages/mainline/debian/ jessie nginx" >> /etc/apt/sources.list \
    && echo "deb-src http://nginx.org/packages/mainline/debian/ jessie nginx" >> /etc/apt/sources.list \
    && apt-get -y install supervisor \
                          git \
                          nginx \
                          php5-fpm \
                          php5-cli \
                          php5-mysql \
                          php5-curl \
                          php5-gd \
                          php5-intl \
                          php5-mcrypt \
                          php5-tidy \
                          php5-xmlrpc \
                          php5-xsl \
                          php5-dev \
    && php -r "readfile('https://getcomposer.org/installer');" | php -- --install-dir=/usr/local/bin --filename=composer \
    && apt-get remove -y `dpkg -l | grep -e \-dev | sed 's/ii//g' \
    	| sed 's/rc//g' | sed 's/^ *//;s/ *$//' \
		| sed 's/ \+ /\t/g' | cut -f 1` \
    && apt-get autoremove -y \
    && apt-get clean \
    && apt-get autoclean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /usr/share/doc/* \
    && rm -rf /usr/share/groff/* \
    && rm -rf /usr/share/man/* \
    && rm -rf /usr/share/info/* \
    && rm -rf /usr/share/lintian/* \
    && rm -rf /usr/share/linda/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/*

# tweak nginx config
RUN sed -i -e"s/worker_processes  1/worker_processes 1/" /etc/nginx/nginx.conf \
    && sed -i -e"s/keepalive_timeout\s*65/keepalive_timeout 2/" /etc/nginx/nginx.conf \
    && sed -i -e"s/keepalive_timeout 2/keepalive_timeout 2;\n\tclient_max_body_size 100m/" /etc/nginx/nginx.conf \
    && echo "daemon off;" >> /etc/nginx/nginx.conf

# tweak php-fpm config
RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php5/fpm/php.ini \
    && sed -i -e "s/listen = \/var\/run\/php5-fpm.sock/listen = 127.0.0.1:9000/g" /etc/php5/fpm/pool.d/www.conf \
    && sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php5/fpm/php.ini \
    && sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php5/fpm/php.ini \
    && sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf \
    && sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php5/fpm/pool.d/www.conf \
    && sed -i -e "s/pm.max_children = 5/pm.max_children = 4/g" /etc/php5/fpm/pool.d/www.conf \
    && sed -i -e "s/pm.start_servers = 2/pm.start_servers = 1/g" /etc/php5/fpm/pool.d/www.conf \
    && sed -i -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 1/g" /etc/php5/fpm/pool.d/www.conf \
    && sed -i -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 2/g" /etc/php5/fpm/pool.d/www.conf \
    && sed -i -e "s/pm.max_requests = 500/pm.max_requests = 200/g" /etc/php5/fpm/pool.d/www.conf

# workaround cannot change files permission
RUN usermod -u 1000 www-data

# nginx site conf
RUN rm -Rf /etc/nginx/conf.d/*
ADD ./nginx-site.conf /etc/nginx/conf.d/nginx-site.conf

# Supervisor Config
ADD ./supervisord.conf /etc/supervisord.conf

# Start Supervisord
ADD ./entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# change owner
RUN chown -Rf www-data.www-data /var/www/html/

# Expose Ports
EXPOSE 80

WORKDIR /var/www/html

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]
