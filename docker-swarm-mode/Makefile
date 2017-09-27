export SPLUNK_VERSION ?= 6.6.3
export SPLUNK_TAG ?= 6.6.3-monitor
export DOCKER_CLUSTER_IMAGE_PATH ?= ${USER}

export DOCKER_SPLUNK_ENTERPRISE_IMG ?= mchene/splunk:7.0.1-monitor
#export DOCKER_SPLUNK_ENTERPRISE_IMG ?= mchene/splunk:6.6.3-monitor
export DOCKER_COLLECTD_IMAGE ?= mchene/collectd:docker
export DOCKER_SPLUNK_UF_IMG ?= mchene/universalforwarder:6.6.3-monitor

export SPLUNK_ENTERPRISE_HOST ?= splunkenterprise
#export SPLUNK_ENTERPRISE_HOST ?= dockercon17-elb-1409304900.us-west-2.elb.amazonaws.com

export CLUSTER_NAME ?= swarmcluster
# do not use dashes in the node name... will make the some of the commands fail.

# If you don't want (cannot) delete old volumes, just use SALT to use new one
SALT ?=

setup-clean:
	seq 0 2 | xargs -I @ docker-machine rm -f $(CLUSTER_NAME)@
	unset ${!DOCKER*}

# setting up a docker swarm cluster using virtualbox
createnodes:
	seq 0 2 | xargs -P 6 -I @ bash -c "docker-machine create \
		--driver=virtualbox \
		--virtualbox-disk-size=200000 \
		--virtualbox-memory=1536 \
		--virtualbox-cpu-count=2 \
		$(CLUSTER_NAME)@"

addworkernodes:
	seq 1 2 | xargs -I @ bash -c 'eval $$(docker-machine env $(CLUSTER_NAME)@) && docker swarm join --listen-addr $$(docker-machine ip $(CLUSTER_NAME)@) $$(docker-machine ip $(CLUSTER_NAME)0):2377 --token $$(eval $$(docker-machine env $(CLUSTER_NAME)0) && docker swarm  join-token -q worker )' 
	(eval $$(docker-machine env $(CLUSTER_NAME)0) && docker network create --driver=overlay monitoring)

initswarm:
	seq 0 2 | xargs -P 6 -I @ docker-machine regenerate-certs --force $(CLUSTER_NAME)@
	(eval $$(docker-machine env $(CLUSTER_NAME)0) && docker swarm init --advertise-addr $$(docker-machine ip $(CLUSTER_NAME)0))

startswarmcluster:
	seq 0 2 | xargs -I @ docker-machine start $(CLUSTER_NAME)@

login:
	(eval $$(docker-machine env $(CLUSTER_NAME)0) && docker login -u splunksupport -p demo123!)
#	seq 0 2 | xargs -I @ docker-machine ssh $(CLUSTER_NAME)@ && docker login -u <myuserid> -p <mypwd>

removeworkernodes:
	seq 1 2 | xargs -I @ bash -c 'eval $$(docker-machine env $(CLUSTER_NAME)@) && docker swarm leave --force' 

addmanager:
#	bash -c 'eval docker swarm join --listen-addr $$(docker-machine ip $(CLUSTER_NAME)0) $$(docker-machine ip $(CLUSTER_NAME)0):2377 --token $$(eval $$(docker-machine env $(CLUSTER_NAME)0) && docker swarm  join-token -q manager )'
# adds current node as the manager
	bash -c 'eval docker swarm join --token $$(eval $$(docker-machine env $(CLUSTER_NAME)0) && docker swarm  join-token -q manager ) $$(docker-machine ip $(CLUSTER_NAME)0):2377'

create_swarmmodecluster: createnodes initswarm addworkernodes 
fix_nodecerts: leave_swarm, initswarm

leave_swarm:
	docker swarm leave --force

removeswarm: setup-clean

createmonitoringnetwork-aws:
	docker network create --driver=overlay monitoring

download-image-spunkuf:
	docker service create \
		--mode global \
		--name download-image \
		--with-registry-auth \
		$(DOCKER_SPLUNK_UF_IMG) entrypoint.sh sleep infinity
	sleep 5
	while docker service ps download-image | grep Preparing 1>/dev/null 2>&1; do sleep 1; done
	docker service rm download-image

download-image-splunkenterprise:
	docker service create \
		--mode global \
		--name download-image \
		--with-registry-auth \
		$(DOCKER_SPLUNK_ENTERPRISE_IMG) entrypoint.sh sleep infinity
	sleep 5
	while docker service ps download-image | grep Preparing 1>/dev/null 2>&1; do sleep 1; done
	docker service rm download-image

download-images-splunk: download-image-splunkenterprise download-image-spunkuf

deploy-splunk-uf:
	docker service create \
		--log-driver=json-file \
		--name splunk-uf \
		--mode global \
		--mount "type=volume,source=volume_splunkuf_etc,destination=/opt/splunk/etc" \
		--mount "type=volume,source=volume_splunkuf_var,destination=/opt/splunk/var" \
		--mount "type=bind,source=/var/lib/docker/containers,destination=/host/containers,ro=1" \
		--mount "type=bind,source=/var/run/docker.sock,destination=/var/run/docker.sock,ro=1" \
		--with-registry-auth \
		--publish 8001:8000 \
		--env "SPLUNK_START_ARGS=--accept-license --answer-yes --no-prompt" \
		--env "SPLUNK_FORWARD_SERVER=$(SPLUNK_ENTERPRISE_HOST):9997" \
		--env "SPLUNK_USER=root" \
		--network monitoring \
		$(DOCKER_SPLUNK_UF_IMG)
removesplunkuf: 
	-docker service rm splunk-uf

deploy-splunkenterprise:
	date
	docker service create \
		--log-driver=json-file \
		--name splunkenterprise \
		--hostname splunkenterprise \
		--mode replicated \
		--replicas 1 \
		--mount "type=volume,source=volume_splunkenterprise_etc,destination=/opt/splunk/etc" \
		--mount "type=volume,source=volume_splunkenterprise_var,destination=/opt/splunk/var" \
		--with-registry-auth \
		--publish 8000:8000 \
		--publish 8088:8088 \
		--publish 8089:8089 \
		--publish 9997:9997 \
		--publish 8125:8125/udp \
		--publish 9125:9125/tcp \
		--publish 514:514/tcp \
		--env "SPLUNK_START_ARGS=--accept-license --answer-yes --no-prompt" \
		--env SPLUNK_ENABLE_LISTEN=9997 \
		--network monitoring \
		$(DOCKER_SPLUNK_ENTERPRISE_IMG)
#		--env SPLUNK_ADD="tcp 514 -sourcetype syslog -index main" \
#		--env "SPLUNK_USER=root" \
#		--with-registry-auth 
	date

update-image-splunkenterprise:
	docker service update \
		--force \
		splunkenterprise

removesplunkenterprise: 
	-docker service rm splunkenterprise

deploy-cadvisor:
	docker service create \
		--log-driver=json-file \
		--name=cadvisor \
		--mode global \
		--mount type=bind,source=/,destination=/rootfs,ro=1 \
		--mount type=bind,source=/var/run,destination=/var/run \
		--mount type=bind,source=/sys,destination=/sys,ro=1 \
		--mount type=bind,source=/var/lib/docker/,destination=/var/lib/docker,ro=1 \
		--publish mode=host,target=8080,published=8080 \
		--network monitoring \
		google/cadvisor:latest \
		-storage_driver=statsd -storage_driver_host=splunkenterprise:8125
removecadvisor: 
	-docker service rm cadvisor

deploysplunk: deploy-splunkenterprise deploy-splunk-uf 
removesplunk: 
	-docker service rm splunk-uf splunkenterprise

deploy-collectd:
	docker service create \
		--name=collectd \
		--mode global \
		--env SPLUNK_URL=https://ec2-34-212-110-173.us-west-2.compute.amazonaws.com:8088/services/collector/raw?channel=95251204-55d6-4424-bf7a-048240bc323a \
        --env HEC_TOKEN=95251204-55d6-4424-bf7a-048240bc323a \
		--mount "type=bind,source=/var/run/docker.sock,destination=/var/run/docker.sock" \
		mchene/collectd:docker
removecollectd: 
	-docker service rm collectd

clean:
	-docker service rm splunk-uf splunkenterprise my-buttercup cadvisor my-web

clean-images:
	-seq 0 2 | xargs -P 6 -I @ bash -c 'eval $$(docker-machine env $(CLUSTER_NAME)@); docker rmi -f $$(docker images -q);'

clean-runningimages:
	-seq 0 2 | xargs -P 6 -I @ bash -c 'eval $$(docker-machine env $(CLUSTER_NAME)@); docker rm $$(docker ps -aq);'

clean-volumes:
	-seq 0 2 | xargs -P 6 -I @ bash -c 'eval $$(docker-machine env $(CLUSTER_NAME)@); docker kill $$(docker ps -q); docker rm -v $$(docker ps -aq); docker volume rm $$(docker volume ls -q)'

clean-uf:
	-docker service rm splunk-uf
#	-seq 0 2 | xargs -P 6 -I @ bash -c 'eval $$(docker-machine env $(CLUSTER_NAME)@); docker rmi -f $$(docker images -q);'
	-seq 0 2 | xargs -P 6 -I @ bash -c 'eval $$(docker-machine env $(CLUSTER_NAME)@); docker volume rm $$(docker volume ls -q)'

clean-all: clean clean-volumes

