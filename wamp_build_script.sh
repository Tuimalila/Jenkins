#!/bin/sh
MY_PATH=/var/jenkins_home/workspace/Wamp_MASTER
export GOPATH=$MY_PATH
echo "--------------------------------------------------------------------------------------"
echo "Check if rsync is installed"
export LD_LIBRARY_PATH=/usr/local/lib:/usr/lib:/usr/local/lib64:/usr/lib64
apt-get update
apt-get install rsync -y
echo "--------------------------------------------------------------------------------------"
echo "Installing GO libraries"
go get -t github.com/jcelliott/lumber # Logging
go get -t gopkg.in/jcelliott/turnpike.v2 # Wamp
go get -t github.com/satori/go.uuid # Authentication
go get -t github.com/fsnotify/fsnotify #Notify for watcher
go get -t github.com/RackSec/srslog # Syslog
go get -t github.com/lib/pq # For Postgres database connection
go get -t github.com/mitchellh/go-ps # For Middleware process checker
go get -t github.com/rakyll/gom/http # For extra advanced debugging
go get -t github.com/vova616/screenshot #  library za naredit screenshote 
name=wamp
echo "GOPATH is set to: $MY_PATH"
echo "--------------------------------------------------------------------------------------"
echo "Building $name"
DATE=`date +%Y-%m-%d`
HASH=$(cat /var/jenkins_home/workspace/Wamp_MASTER/.git/HEAD)
VERSION=$(grep -Po 'SHORT_VERSION = "\K.*?(?=")' /var/jenkins_home/workspace/Wamp_MASTER/src/main/main.go)
echo "Date is: $DATE"
echo "Commit hash: $HASH"
echo "Wamp version is: $VERSION"
echo "--------------------------------------------------------------------------------------"
GOOS="linux" GOARCH="amd64" go build -ldflags "-X main.WAMP_VERSION=Wamp.Master-$DATE-$HASH" -o ${name}-linux main
GOOS="windows" GOARCH="amd64" go build -ldflags "-X main.WAMP_VERSION=Wamp.Master-$DATE-$HASH" -o ${name}-windows.exe main
echo "Wamp was built"
echo "--------------------------------------------------------------------------------------"
echo "1st copy binary to deploy server:"
echo "--------------------------------------------------------------------------------------"
export RSYNC_PASSWORD=change_password
rsync -cLhavzP --stats --progress /var/jenkins_home/workspace/Wamp_MASTER/scripts/listener.json rsync://admin@0.0.0.0/tools/wamp/listener.json
rsync -cLhavzP --stats --progress /var/jenkins_home/workspace/Wamp_MASTER/scripts/watcher.json rsync://admin@0.0.0.0/tools/wamp/watcher.json
rsync -cLhavzP --stats --progress wamp-windows.exe rsync://admin@10.100.0.10/2nd/tools/wamp/wamp.exe
echo "--------------------------------------------------------------------------------------"
echo "Then copy binaries to container build server:"
echo "--------------------------------------------------------------------------------------"
mkdir $(date +%Y-%m-%d)_MASTER_$HASH
mv wamp-linux $(date +%Y-%m-%d)_MASTER_$HASH
mv wamp-windows.exe $(date +%Y-%m-%d)_MASTER_$HASH
cp /var/jenkins_home/workspace/Wamp_MASTER/scripts/listener.json $(date +%Y-%m-%d)_MASTER_$HASH
cp /var/jenkins_home/workspace/Wamp_MASTER/scripts/api.json $(date +%Y-%m-%d)_MASTER_$HASH
grep -Po 'SHORT_VERSION = "\K.*?(?=")' /var/jenkins_home/workspace/Wamp_MASTER/src/main/main.go > version.txt
rsync -cLhavzP --stats --progress version.txt rsync://admin@0.0.0.0/tools/wamp/version.txt
cp version.txt $(date +%Y-%m-%d)_MASTER_$HASH
mkdir latest_master
cd latest_master
ln -s ../$(date +%Y-%m-%d)_MASTER_$HASH/wamp-linux
ln -s ../$(date +%Y-%m-%d)_MASTER_$HASH/wamp-windows.exe
ln -s ../$(date +%Y-%m-%d)_MASTER_$HASH/listener.json
ln -s ../$(date +%Y-%m-%d)_MASTER_$HASH/api.json
ln -s ../$(date +%Y-%m-%d)_MASTER_$HASH/version.txt
cd ..
rsync -av $(date +%Y-%m-%d)_MASTER_$HASH rsync://0.0.0.0/container_build/docker.wamp/
rsync -avk latest_master rsync://0.0.0.0/container_build/docker.wamp/
rm -rf $(date +%Y-%m-%d)_MASTER_$HASH
rm -rf latest_master
echo "--------------------------------------------------------------------------------------"
echo "Script Finished!"
echo "--------------------------------------------------------------------------------------"