FROM ubuntu:xenial

########################################################################
############## RSTUDIO STUFF HACKED TOGETHER FROM ROCKER ###############
########################################################################
#
#              https://github.com/rocker-org/rocker
#

########### from r-base #############
# https://github.com/rocker-org/rocker/tree/master/r-base

RUN useradd docker \
    && mkdir /home/docker \
    && chown docker:docker /home/docker \
    && addgroup docker staff

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       	       ed \
	       less \
	       locales \
	       vim-tiny \
	       wget \
	       ca-certificates \
	       build-essential \
	       awscli \
	       python-setuptools \
	       python-magic \
	       s3cmd \
	       tmux \
	       emacs \
	       ess \
	       git \
	       postgresql-client \
	       libssh2-1-dev \
    && rm -rf /var/lib/apt/lists/*

## Configure default locale, see https://github.com/rocker-org/rocker/issues/19
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_US.utf8 \
    && /usr/sbin/update-locale LANG=en_US.UTF-8

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

## Use Debian unstable via pinning -- new style via APT::Default-Release
#RUN echo "deb http://http.debian.net/debian sid main" > /etc/apt/sources.list.d/debian-unstable.list \
#    && echo 'APT::Default-Release "testing";' > /etc/apt/apt.conf.d/default

ENV R_BASE_VERSION 3.2.3

## Now install R and littler, and create a link for littler in /usr/local/bin
## Also set a default CRAN repo, and make sure littler knows about it too
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       	       littler \
	       r-cran-littler \
	       r-base=${R_BASE_VERSION}* \
	       r-base-dev=${R_BASE_VERSION}* \
	       r-recommended=${R_BASE_VERSION}* \
    && echo 'options(repos = c(CRAN = "https://cran.rstudio.com/"), download.file.method = "libcurl")' >> /etc/R/Rprofile.site \
    && echo 'source("/etc/R/Rprofile.site")' >> /etc/littler.r \
    && ln -s /usr/share/doc/littler/examples/install.r /usr/local/bin/install.r \
    && ln -s /usr/share/doc/littler/examples/install2.r /usr/local/bin/install2.r \
    && ln -s /usr/share/doc/littler/examples/installGithub.r /usr/local/bin/installGithub.r \
    && ln -s /usr/share/doc/littler/examples/testInstalled.r /usr/local/bin/testInstalled.r \
    && install.r docopt \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
    && rm -rf /var/lib/apt/lists/*

###################### from R devel ################################
# https://github.com/rocker-org/rocker/tree/master/r-devel

## Remain current
RUN apt-get update -qq \
    && apt-get dist-upgrade -y

## From the Build-Depends of the Debian R package, plus subversion
RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends \
	       bash-completion \
	       bison \
	       debhelper \
	       default-jdk \
	       g++ \
	       gcc \
	       gdb \
	       gfortran \
	       groff-base \
	       libblas-dev \
	       libbz2-dev \
	       libcairo2-dev \
	       libcurl4-openssl-dev \
	       libjpeg-dev \
	       liblapack-dev \
	       liblzma-dev \
	       libncurses5-dev \
	       libpango1.0-dev \
	       libpcre3-dev \
	       libpng-dev \
	       libreadline-dev \
	       libtiff5-dev \
	       libx11-dev \
	       libxt-dev \
	       mpack \
	       subversion \
	       tcl8.6-dev \
	       texinfo \
	       texlive-base \
	       texlive-extra-utils \
	       texlive-fonts-extra \
	       texlive-fonts-recommended \
	       texlive-generic-recommended \
	       texlive-latex-base \
	       texlive-latex-extra \
	       texlive-latex-recommended \
	       tk8.6-dev \
	       x11proto-core-dev \
	       xauth \
	       xdg-utils \
	       xfonts-base \
	       xvfb \
	       zlib1g-dev


################## from rstudio ############################
# https://github.com/rocker-org/rocker/blob/master/rstudio

## Add RStudio binaries to PATH
ENV PATH /usr/lib/rstudio-server/bin/:$PATH

## Download and install RStudio server & dependencies
## Attempts to get detect latest version, otherwise falls back to version given in $VER
## Symlink pandoc, pandoc-citeproc so they are available system-wide
RUN rm -rf /var/lib/apt/lists/ \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
	       ca-certificates \
	       file \
	       git \
	       libapparmor1 \
	       libedit2 \
	       libcurl4-openssl-dev \
	       libssl1.0.0 \
	       libssl-dev \
	       psmisc \
	       python-setuptools \
	       supervisor \
	       sudo \
#   MODIFIED	       
#    && VER=$(wget --no-check-certificate -qO- https://s3.amazonaws.com/rstudio-server/current.ver) \
#    && wget -q http://download2.rstudio.org/rstudio-server-${VER}-amd64.deb \
#    && dpkg -i rstudio-server-${VER}-amd64.deb \
    && wget -q https://s3.amazonaws.com/rstudio-dailybuilds/rstudio-server-0.99.875-amd64.deb \
    && dpkg -i rstudio-server-0.99.875-amd64.deb \ 
    && rm rstudio-server-*-amd64.deb \
    && ln -s /usr/lib/rstudio-server/bin/pandoc/pandoc /usr/local/bin \
    && ln -s /usr/lib/rstudio-server/bin/pandoc/pandoc-citeproc /usr/local/bin \
    && wget https://github.com/jgm/pandoc-templates/archive/1.15.0.6.tar.gz \
    && mkdir -p /opt/pandoc/templates && tar zxf 1.15.0.6.tar.gz \
    && cp -r pandoc-templates*/* /opt/pandoc/templates && rm -rf pandoc-templates* \
    && mkdir /root/.pandoc && ln -s /opt/pandoc/templates /root/.pandoc/templates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/

## Ensure that if both httr and httpuv are installed downstream, oauth 2.0 flows still work correctly.
RUN echo '\n\
\n# Configure httr to perform out-of-band authentication if HTTR_LOCALHOST \
\n# is not set since a redirect to localhost may not work depending upon \
\n# where this Docker container is running. \
\nif(is.na(Sys.getenv("HTTR_LOCALHOST", unset=NA))) { \
\n  options(httr_oob_default = TRUE) \
\n}' >> /etc/R/Rprofile.site

## A default user system configuration. For historical reasons,
## we want user to be 'rstudio', but it is 'docker' in r-base
RUN usermod -l rstudio docker \
    && usermod -m -d /home/rstudio rstudio \
    && groupmod -n rstudio docker \
    && echo '"\e[5~": history-search-backward' >> /etc/inputrc \
    && echo '"\e[6~": history-search-backward' >> /etc/inputrc \
    && echo "rstudio:rstudio" | chpasswd

## User config and supervisord for persistant RStudio session
COPY userconf.sh /usr/bin/userconf.sh
COPY add-students.sh /usr/local/bin/add-students
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN mkdir -p /var/log/supervisor \
    && chgrp staff /var/log/supervisor \
    && chmod g+w /var/log/supervisor \
    && chgrp staff /etc/supervisor/conf.d/supervisord.conf

EXPOSE 8787

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]




