# Default Apache2 container
FROM ubuntu:latest
RUN apt update && apt install --no-install-recommends -y \
    apache2 \
    libapache2-mod-wsgi-py3 \
    python3 \
    python3-pip \
    python3-dev \
    build-essential \
    htop \
    curl \
    net-tools \
    tzdata \
    ntp \
    ntpdate \
    nano \
    supervisor

## Setup correct timezone
RUN ln -fs /usr/share/zoneinfo/Europe/Copenhagen /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

# Setup fair configuration and disable the default conf
COPY ./apache2.conf /etc/apache2/sites-available/projects.conf
RUN a2dissite 000-default.conf && a2ensite projects.conf

# Enable auth_openid, wsgi module, headers (Naming Bug in the enabling of openid requires a fix to the load conf)
RUN a2enmod wsgi && a2enmod headers

# Prepare WSGI launcher script
COPY ./projects /var/www/projects
COPY ./nbi_base /var/www/nbi_base
COPY ./app.wsgi /var/www/projects/wsgi/
RUN chown root:www-data -R /var/www && \
    chmod 775 -R /var/www && \
    chmod 2755 -R /var/www/projects/wsgi

# Copy in the source code
COPY . /app
WORKDIR /app

# Install the code and cleanup
RUN pip3 install setuptools && \
    pip3 install Flask wtforms && \
    python3 setup.py install
    #python3 setup.py test && \


EXPOSE 80
## Prepare supervisord
RUN mkdir -p /var/log/supervisor
## insert supervisord config -> handles the startup procedure for the image
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord"]
