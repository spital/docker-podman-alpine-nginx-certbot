# Docker-podman-alpine-nginx-certbot

Create and automatically renew website SSL certificates using the free [letsencrypt](https://letsencrypt.org/) certificate authority, and its client [*certbot*](https://certbot.eff.org/), built on top of the [nginx](https://www.nginx.com/) webserver running in container managed by [Docker-ce](https://www.docker.com/docker-community) or daemonless container engine [Podman](https://podman.io).

This repository was originally inspired by [docker-nginx-certbot](https://github.com/staticfloat/docker-nginx-certbot), many thanks for the good ideas.  It has since been completely rewritten, and bears almost no resemblance to the original.  This repository is _much_ more opinionated about the structure of your webservers/containers, however it is easier to use as long as all of your webservers follow the given pattern.

The example below was specifically prepared to get A+ score from [Qualys SSL Lab test](https://www.ssllabs.com/ssltest), tested 2020/05/21.

# Prerequisities / install

You need to install make and docker-ce (tested on Fedora 31, see https://linuxconfig.org/how-to-install-docker-on-fedora-31) or podman (tested on Fedora 32, see the note below; while Fedora was running in virtual machine, `ssh -L*:8080:VM_IP:8080 -L*:8443:VM_IP:8443 user@VM_IP` came handy):
```bash
sudo dnf install -y make podman podman-compose podman-docker
docker run hello-world
docker run -it alpine cat /etc/os-release
```
**Important note:** although podman can run rootless, mapping `--volume` to the host's local directory did not work for me even under root. You need to use only named volumes (stored under $HOME/.local/share/containers/storage/volumes/.... or /var/lib/containers/storage/volumes/... for root) and copy config files into container using `docker cp HOST_DIR/FILE nginx-certbot:/DIR/FILE` (or `cp` to mentioned host's filesystem directory). Please bear that in mind and amend commands below accordingly. Also podman's image repository is not shared between root and user (neither with Docker) and the user does not see containers started by the other user. Published ports are accessible by everybody of course.
# Usage

Check example in a config directory for your custom configs and build spital/nginx-certbot:
```bash
ls nginx_conf.d
make
docker images | head
```

Prepare Nginx `.conf` with http only and certbot redirect:
```bash
cp nginx_conf.d/my.domain.org._no_ssl_conf nginx_conf.d/my.domain.org.conf
```

Start nginx http server (with ports 8080 and 8443):
```bash
docker run --detach --name nginx-certbot --publish 8080:80 --publish 8443:443 \
  --volume $(pwd)/letsencrypt:/etc/letsencrypt --volume $(pwd)/nginx_conf.d:/etc/nginx/conf.d \
  --volume $(pwd)/var_lib_le:/var/lib/letsencrypt spital/nginx-certbot
```

Check that you receive `502 Bad Gateway` reply from http://localhost:8080/.well-known/acme-challenge and from http://my.domain.org too.

Issue a certificate for your DOMAIN and EMAIL from SERVER
```bash
SERVER='https://acme-v02.api.letsencrypt.org/directory'
DOMAINS=my.domain.org,mywww.domain.org
EMAIL=my@email.com
docker exec -it nginx-certbot certbot certonly --non-interactive --domains $DOMAINS \
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

Now you have it running on ports 8080 and 8443, change the config or map the ports on router and test `my.domain.org` at https://www.ssllabs.com/ssltest

# TODO
Check cron daily cert check is working and add Nginx reload post-hook, test in container first with `--dry-run`:
```bash
cat /etc/periodic/daily/certbot
```
