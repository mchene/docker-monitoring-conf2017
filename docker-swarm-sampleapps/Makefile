deploy-nginx:
	docker service create \
		--log-driver=json-file \
		--name my-web \
		--replicas 3 \
		--publish 7000:8080 \
		nginx
removenginx: 
	-docker service rm my-web

deploy-buttercupgo:
	docker service create \
		--log-driver=json-file \
		--name my-buttercup \
		--replicas 3 \
		--publish 3040:3040 \
		mchene/buttercupgo
removebuttercupgo: 
	-docker service rm my-buttercup

deployapps: deploy-buttercupgo deploy-nginx
removeapps: removebuttercupgo removenginx

clean:
	-docker service rm my-buttercup cadvisor my-web
