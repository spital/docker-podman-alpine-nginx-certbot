# Docker-podman-alpine-nginx-certbot

Create and automatically renew website SSL certificates using the free [letsencrypt](https://letsencrypt.org/) certificate authority, and its client [*certbot*](https://certbot.eff.org/), built on top of the [nginx](https://www.nginx.com/) webserver.

This repository was originally inspired by [docker-nginx-certbot](https://github.com/staticfloat/docker-nginx-certbot), many thanks for the good ideas.  It has since been completely rewritten, and bears almost no resemblance to the original.  This repository is _much_ more opinionated about the structure of your webservers/containers, however it is easier to use as long as all of your webservers follow the given pattern.

The example below was specifically prepared to get A+ score from [Qualys SSL Lab test](https://www.ssllabs.com/ssltest).

# Prerequisities

You need to install docker (tested on Fedora 31) or podman (tested on Fedora 32) and make.

# Usage

Check example in a config directory for your custom configs and build spital/nginx-certbot:
```bash
$ ls nginx_conf.d
$ make
```

Prepare Nginx `.conf` with http only and certbot redirect:
```bash
$ cp nginx_conf.d/my.domain.org._no_ssl_conf nginx_conf.d/my.domain.org.conf
```

Start nginx http server (with ports 8080 and 8443):
```bash
$ docker run --detach --name nginx-certbot --publish 8080:80 --publish 8443:443 \
  --volume $(pwd)/letsencrypt:/etc/letsencrypt --volume $(pwd)/nginx_conf.d:/etc/nginx/conf.d \
  --volume $(pwd)/var_lib_le:/var/lib/letsencrypt spital/nginx-certbot
```

Check that you receive `502 Bad Gateway` reply from http://localhost:8080/.well-known/acme-challenge and from http://my.domain.org too.

Issue a certificate for your DOMAIN and EMAIL from SERVER
```bash
SERVER='https://acme-v02.api.letsencrypt.org/directory'
DOMAIN=k2.spital.cz
EMAIL=my@email.com
docker exec -it nginx-certbot certbot certonly --non-interactive --domains $DOMAIN \
  --standalone --expand --email $EMAIL --agree-tos --keep --text \
  --server $SERVER --http-01-port 1337 \
  --preferred-challenges http-01 --debug
```

Prepare nginx config for http(s) with HSTS and OCSP stapling to get Qualys SSL Labs A+
```bash
cp nginx_conf.d/my.domain.org._ssl_conf nginx_conf.d/my.domain.org.conf
vi nginx_conf.d/my.domain.org.conf  # and rename my.domain.org to yours
```

Test Nginx configuration
```bash
docker exec -it nginx-certbot nginx -t
```

Reload Nginx configuration
```bash
docker exec -it nginx-certbot nginx -s reload
```

Now you have it running on ports 8080 and 8443, change the config or map the ports on router and test my.domain.org at https://www.ssllabs.com/ssltest


