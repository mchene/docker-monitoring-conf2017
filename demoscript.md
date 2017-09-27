# Testing HTTP Event Collector connection
curl -k https://localhost:8088/services/collector -H 'Authorization: Splunk 00000000-0000-0000-0000-000000000000' -d '{"event":"Hello, World!"}'  

curl -k https://splunkenterprise:8088/services/collector -H 'Authorization: Splunk 00000000-0000-0000-0000-000000000000' -d '{"event":"Hello, World!"}'  

# Documentation
https://docs.docker.com/engine/admin/logging/splunk/


# Common Errors
1. Running docker images doesn't start with configured splunk docker logging driver: 
ERROR: for dockermonitoringconf2017_wordpress_db_1  UnixHTTPConnectionPool(host='localhost', port=None): Read timed out. (read timeout=60)

ERROR: for wordpress_db  UnixHTTPConnectionPool(host='localhost', port=None): Read timed out. (read timeout=60)
ERROR: An HTTP request took too long to complete. Retry with --verbose to obtain debug information.
If you encounter this issue regularly because of slow network conditions, consider setting COMPOSE_HTTP_TIMEOUT to a higher value (current value: 60).

2. Getting logs for a container that uses the Splunk Logging Driver: docker logs 07fd44dedd67
Error response from daemon: configured logging driver does not support reading

3. Connection reset by peer:
ERROR: for dockermonitoringconf2017_wordpress_db_1  Cannot start service wordpress_db: failed to initialize logging driver: Options https://127.0.0.1:8088/services/collector/event/1.0: read tcp 127.0.0.1:46954->127.0.0.1:8088: read: connection reset by peer

ERROR: for wordpress_db  Cannot start service wordpress_db: failed to initialize logging driver: Options https://127.0.0.1:8088/services/collector/event/1.0: read tcp 127.0.0.1:46954->127.0.0.1:8088: read: connection reset by peer
ERROR: Encountered errors while bringing up the project.

3. Docker DNS resolution in a logging driver will not work. Workaround is to use 127.0.0.1.  Docker daemon itself is not part of the docker-network, so cannot resolve / directly connect to a container, unless the container is exposing/publishing a port. See the following thread for more details, https://github.com/moby/moby/issues/20370.


#        splunk-url: "https://172.20.0.2:8088"
#        splunk-url: "https://splunkenterprise:8088"
#        splunk-url: "https://dockermonitoringconf2017_splunkenterprise_1:8088"
#        splunk-url: "https://localhost:8088"
#        splunk-verify-connection: "false"
# version: '1'
#    log_driver: "splunk"
#    log_opt:
#          splunk-url: "https://splunkenterprise:8088"
#          splunk-token: "00000000-0000-0000-0000-000000000000"
#          splunk-insecureskipverify: "true"
#          splunk-source: wordpressdb
#          tag: "{{.Name}}"
#          labels: sdlc
#          env: "MYSQL_ROOT_PASSWORD"