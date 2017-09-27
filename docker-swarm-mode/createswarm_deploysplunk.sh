date
make create_swarmmodecluster
date
docker-machine ls
eval $(docker-machine env swarmcluster0)
date
make deploysplunk
date
docker-machine ip swarmcluster0