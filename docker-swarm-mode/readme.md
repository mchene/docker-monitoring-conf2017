
# Setup Docker SWARM Mode Cluster on Local Virtualbox
## Minimum Requirements
	- Virtualbox 5.1.18 or higher
	- Docker 17 or higher
	- MAC OS X El Capitan or higher

## Step-by-step
	1. Setup a new cluster:  make create_swarmmodecluster 
		a. Or run the commands manually:
			i.  make createnodes 
			ii.  make initswarm 
			iii.  make addworkernodes 
		b. Default configuration: 1 manager, 2 worker nodes
		c. Default docker-machine names: swarmcluster0, swarmcluster1, swarmcluster2
		d. SWARM Manager: swarmcluster0
	2. Confirm that the 3 nodes are setup:  docker-machine ls 
	3. Before deploying you will need to set your local docker daemon to reference the SWARM Manager:  eval $(docker-machine env swarmcluster0) 
	4. (optional) You may need to manually login to every node  if using a private docker image
		a. docker-machine ip swarmcluster0
		b. docker-machine ssh swarmcluster0
		c. docker login -u <userid> -p <password>
		d. exit
		e. Repeat for each node!
	5. (optional) Download images on each node for a more reliable start up:  make download-images-splunk 
		a. Or manually download each image:  make download-image-splunkenterprise  and  make download-image-spunkuf 
	6. Deploy Splunk Enterprise and Splunk UF (as global Service):  make deploysplunk 
		a. Confirm that the service is deployed, give it some time to download the image on each node and start the services:  docker service ls 
	7. Confirm that you can access Splunk Enterprise
		a. Determine the IP of any node:  docker-machine ip swarmcluster0 
		b. Launch Splunk Web UI, e.g. [Splunk Enterprise Web URL] (http://192.168.99.101:8000/)

## Cleanup
- Remove all swarm nodes:  make removeswarm 

## Troubleshooting
    1. | inputlookup docker_containername.csv

# Splunk Metrics
	1. (optional for metrics build) Deploy cAdvisor to monitor metrics and send metrics as statsd  to Splunk Enterprise: 
	2. Deploy the Buttercup GO App and a few other Apps (collectd, nginx): make deployapps
		a. Determine the IP of any node: docker-machine ip swarmcluster0
		b. Launch Web UI, http://192.168.99.108:3040
	2. Cleanup / teardown cluster: make setup-clean

# Setup a Docker SWARM Mode Cluster on AWS
https://docs.docker.com/docker-for-aws/#quickstart

	1. Setup a docker SWARM mode cluster in AWS
		a.  aws cloudformation create-stack --stack-name conf2017 --template-url https://editions-us-east-1.s3.amazonaws.com/aws/stable/Docker.tmpl --parameters ParameterKey=KeyName,ParameterValue=splunk2015 ParameterKey=InstanceType,ParameterValue=c4.4xlarge ParameterKey=ClusterSize,ParameterValue=3 ParameterKey=ManagerInstanceType,ParameterValue=m4.2xlarge ParameterKey=ManagerSize,ParameterValue=1 --capabilities CAPABILITY_IAM 
			i. Result:
			rSize,ParameterValue=3 ParameterKey=ManagerInstanceType,ParameterValue=m4.2xlarge ParameterKey=ManagerSize,ParameterValue=3 --capabilities CAPABILITY_IAM
			{
			    "StackId": "arn:aws:cloudformation:us-west-2:269555371468:stack/dockercon17/607d14b0-23f1-11e7-b4db-503ac9841afd"
			}
			
		b. Redirecting docker commands to a Manager Node
			i. export AWS_DOCKER_MANAGER_IP=<dockerswarmmode_managernode_externalip>
				1) E.g., 34.209.163.226, 
				2) export AWS_DOCKER_MANAGER_IP=34.209.163.226
			ii. ssh -i /Users/mchene/Documents/Personal/AWS/splunk2015.pem docker@$AWS_DOCKER_MANAGER_IP
			iii. exit
			iv. ssh -i /Users/mchene/Documents/Personal/AWS/splunk2015.pem -NL localhost:2374:/var/run/docker.sock docker@$AWS_DOCKER_MANAGER_IP &
			v. export DOCKER_HOST=localhost:2374
	2. Deploy UF as global service and Splunk Enterprise as a replicated service 1/1
		a. Create monitoring network:  make createmonitoringnetwork-aws 
		b. Deploy Splunk Enterprise and UF:  make deploysplunk 	
	3. Update ELB with required external ports (e.g., 8000, 8088)
		a. From EC2 dashboard, click on EC2 host that has the "-Manager" postfix
		b. Click on the "***-Manager***" Security Group
		c. Open the required ports
	4. (optional) Update limits.conf
		a. ssh -i /Users/mchene/Documents/Personal/AWS/splunk2015.pem docker@54.69.223.147
		b. vi /opt/splunk/etc/system/local/limits.conf
		c. [search] max_searches_per_cpu=99999
		d. /opt/splunk/bin/splunk restart
		Concurrent Search quotas, http://docs.splunk.com/Documentation/Splunk/6.5.3/DistSearch/SHCarchitecture
			- User and Role search quotas: srchJobsQuota (authorize.conf)
			- Overall search quotas: max_searches_per_cpu (limits.conf)
			- https://jira.splunk.com/browse/SPL-124810
		
	5. Deploy application nodes: make deployapps


# FAQ
0. Running as a Priviledged container.