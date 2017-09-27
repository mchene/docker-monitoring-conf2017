FROM debian:jessie

RUN echo "deb http://pkg.ci.collectd.org/deb/ jessie collectd-5.7" >> /etc/apt/sources.list \
	&& apt-get update -y \
	&& apt-get install --force-yes --assume-yes collectd \
		curl ca-certificates netcat \
	&& apt-get install -y vim

ADD collectd.conf /etc/collectd/collectd.conf

ADD entrypoint.sh /etc/collectd/entrypoint.sh
RUN chmod +x /etc/collectd/entrypoint.sh

# install docker plugin, https://github.com/dustinblackman/collectd-docker-plugin
RUN curl -Ls "https://github.com/dustinblackman/collectd-docker-plugin/releases/download/0.3.0/collectd-docker-plugin-linux-amd64-0.3.0.tar.gz" | tar xz -C /usr/local/bin/ \
	&& curl -o /usr/share/collectd/docker.db https://raw.githubusercontent.com/dustinblackman/collectd-docker-plugin/master/collectd/docker.db \
	&& curl -o /etc/collectd/collectd.conf.d/docker.conf https://raw.githubusercontent.com/dustinblackman/collectd-docker-plugin/master/collectd/docker.conf

# https://docs.docker.com/engine/installation/linux/linux-postinstall/#manage-docker-as-a-non-root-user
RUN groupadd docker \
 && usermod -aG docker nobody
# Must add user "nobody" to docker group to have access to unix:///var/run/docker.sock
#sudo usermod -aG docker nobody

ENTRYPOINT ["/etc/collectd/entrypoint.sh"]