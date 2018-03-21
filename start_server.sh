#!/usr/bin/env bash
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
docker rmi $(docker images -q)

rm -rf PathwayGenie
git clone https://github.com/synbiochem/PathwayGenie.git
cd PathwayGenie
docker build -t pathwaygenie .
cd ..

rm -rf CodonGenie
git clone https://github.com/synbiochem/CodonGenie.git
cd CodonGenie
docker build -t codongenie .
cd ..

rm -rf CombiGenie
git clone https://github.com/synbiochem/CombiGenie.git
cd CombiGenie
docker build -t combigenie .
cd ..

rm -rf DEbrief
git clone https://github.com/genegeniebio/DEbrief.git
cd DEbrief
docker build -t debrief .
cd ..

rm -rf selenzyme
mkdir selenzyme
wget http://130.88.113.226/selenzy/selenzy.tar.gz
tar -xzvf selenzy.tar.gz -C selenzyme
docker build -t selenzyme .
cd ..

cd
mkdir certs

docker run --name nginx-proxy -d -p 80:80 -p 443:443 -v /var/run/docker.sock:/tmp/docker.sock:ro \
    -v $HOME/certs:/etc/nginx/certs:ro \
    -v /etc/nginx/vhost.d \
    -v /usr/share/nginx/html \
    --label com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy=true \
    jwilder/nginx-proxy

docker run -d \
    --name nginx-letsencrypt \
    --volumes-from nginx-proxy \
    -v $HOME/certs:/etc/nginx/certs:rw \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    jrcs/letsencrypt-nginx-proxy-companion

docker run --name pathwaygenie -d -p :5000 -e VIRTUAL_HOST=parts.synbiochem.co.uk \
	-e LETSENCRYPT_EMAIL=neil.swainston@manchester.ac.uk -e LETSENCRYPT_HOST=parts.synbiochem.co.uk pathwaygenie

docker run --name codongenie -d -p :5000 -e VIRTUAL_HOST=codon.synbiochem.co.uk codongenie

docker run --name combigenie -d -p :5000 -e VIRTUAL_HOST=combi.synbiochem.co.uk combigenie
	
docker run --name debrief -d -p :5000 -e VIRTUAL_HOST=debrief.synbiochem.co.uk \
	-e LETSENCRYPT_EMAIL=neil.swainston@manchester.ac.uk -e LETSENCRYPT_HOST=debrief.synbiochem.co.uk debrief
	
docker run --name selenzyme -d -p :5000 -e VIRTUAL_HOST=selenzyme.synbiochem.co.uk \
	-e LD_LIBRARY_PATH='/opt/conda/bin/../lib' -v $DIR/selenzyme:/selenzyme \
	-e LETSENCRYPT_EMAIL=neil.swainston@manchester.ac.uk -e LETSENCRYPT_HOST=selenzyme.synbiochem.co.uk selenzyme

