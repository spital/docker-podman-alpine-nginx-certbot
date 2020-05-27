FROM nginx:stable-alpine
LABEL maintainer="Spital <spital@seznam.cz>"

VOLUME /etc/letsencrypt
VOLUME /etc/nginx/conf.d
VOLUME /var/lib/letsencrypt
VOLUME /var/www

EXPOSE 80
EXPOSE 443


# Do this apt/pip stuff all in one RUN command to avoid creating large
# intermediate layers on non-squashable docker installs
RUN apk add --no-cache \
       curl ca-certificates certbot \
  && curl https://ssl-config.mozilla.org/ffdhe4096.txt > /etc/nginx/ffdhe4096.pem \
  && echo '#!/bin/sh' > /etc/periodic/daily/certbot \
  && echo 'sleep $(($(od -An -N3 -l /dev/random)*86300/16777216)) && certbot -q renew -n --no-self-upgrade --post-hook "nginx -s reload"' >> /etc/periodic/daily/certbot \
  && chmod 755 /etc/periodic/daily/certbot

ENTRYPOINT []
CMD ["nginx", "-g", "daemon off;"]
