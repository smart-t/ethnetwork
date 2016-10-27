AUTHOR=banking
NAME=ethnetwork
NETWORKID=42
SUBNET=10.0.42
VERSION=latest
PWD=/dockerbackup

build:
	docker build --build-arg NETWORKID=${NETWORKID} -t $(AUTHOR)/$(NAME):$(VERSION) .

start: network miner node1 node2 ethstats ethstatsclient

stop:
	docker stop miner
	docker stop node1
	docker stop node2
	docker stop ethstats
	docker stop ethstatsclient

clean:
	docker rm -f miner
	docker rm -f node1
	docker rm -f node2
	docker rm -f ethstats
	docker rm -f ethstatsclient
	docker network rm icec

cleanrestart: clean start

network:
	docker network create --subnet $(SUBNET).0/24 --gateway $(SUBNET).254 icec

datavolume:
	docker run -d -v ethereumvol:/root --name data-eth_miner --entrypoint /bin/echo $(AUTHOR)/$(NAME):$(VERSION)

backup:
	docker run --rm --volumes-from data-eth_miner -v $(PWD):/backup debian:wheezy bash -c "tar zcvf /backup/ethereumbackup.tgz root"

restore:
	docker run --rm --volumes-from data-eth_miner -v $(PWD):/backup debian:wheezy bash -c "tar zxvf /backup/ethereumbackup.tgz"

rmnetwork:
	docker network rm icec

help:
	docker run -i $(AUTHOR)/$(NAME):$(VERSION) help

miner:
	docker run -d --name=miner --net icec --ip $(SUBNET).1 -p 8545:8545 --volumes-from data-eth_miner -e SUBNET=$(SUBNET) $(AUTHOR)/$(NAME):$(VERSION) miner

node1:
	docker run -d --name=node1 --net icec --ip $(SUBNET).2 -e SUBNET=$(SUBNET) $(AUTHOR)/$(NAME):$(VERSION) node1

node2:
	docker run -d --name=node2 --net icec --ip $(SUBNET).3 -e SUBNET=$(SUBNET) $(AUTHOR)/$(NAME):$(VERSION) node2

ethstatsclient:
	docker run -d --name=ethstatsclient --net icec --ip $(SUBNET).243 -e SUBNET=$(SUBNET) $(AUTHOR)/$(NAME):$(VERSION) ethstatsclient

ethstats:
	docker run -d --name=ethstats --net icec --ip $(SUBNET).242 -e SUBNET=$(SUBNET) -p 3000:3000 $(AUTHOR)/$(NAME):$(VERSION) ethstats

console: ciminer

ciminer:
	docker exec -ti miner /geth attach

cinode1:
	docker exec -ti node1 /geth attach

cinode2:
	docker exec -ti node2 /geth attach

