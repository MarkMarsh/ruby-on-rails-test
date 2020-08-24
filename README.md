# README
Installation and execution instructions for this Ruby on Rails Technical Test

This project was written as a test of how far I could get with writing a Ruby on Rails project in a week. It processes files, extracting most and least frequent words and palindromic words.

The files are processed in the background using Sidekiq. More processing power can be added by running more Sidekiq workers.

## Installation

* Check / install the packages in the Packages section below
* Clone the repo
* Run the setup

```
git clone https://github.com/MarkMarsh/ruby-on-rails-test.git
cd ruby-on-rails-test 
./bin/setup
```

## Execution

* Make sure Redis is running
* Make sure a Sidekiq worker is running (see below)
* Run the following commands (the -b option to rails is only required if you want to connect from another machine)

*Todo: work out how to run in production mode (setup secret key etc)*
```
cd <root of project>

# if Redis is running on a different machine
export REDIS_URL="redis://<redis server IP>:6379/0"

# run the webserver application
rails s -b 0.0.0.0
```
Connect to the webserver at http://<hostname>:3000


## Dependencies

### MongoDB

MongoDB is used for the database and it's location is configured in
`config/mongoid.yml`. It defaults to localhost:27017

A basic MongoDB server running on localhost can be created using docker:

`docker run --name file-stats-mongo -p 27017:27017 -d mongo`

For multi instance deployments, the MongoDB database must be shared between all the Sidekiq workers.

### Sidekiq 

Sidekiq uses a worker process that communicates via Redis. At least one of these worker processes must be running (see below). 

Sidekiq uses Redis to communicate between the client (your web app) and the worker processes. The default configuration is
to look for redis on localhost:6379 but it can be overidden by setting the "REDIS_URL" environment variable - https://github.com/mperham/sidekiq/wiki/Using-Redis

Sidekiq will use up to 100% of one core so you can increase processing by running multiple worker
processes on a single instance (EC2 instance, physical machine or VM) and / or running workers on multiple instances.

```
# make sure redis is running then:
cd <root of project>

# if Redis is running on a different machine
export REDIS_URL="redis://<redis server IP>:6379/0"

# run the worker process
nohup bundle exec sidekiq -q file_stats >log/sidekiq.log 2>&1 &

# to monitor
tail -f log/sidekiq.log
```
This starts a worker and tells it to process the queue "file_stats".

### Redis

Redis is used by Sidekiq for storage and communication. For multi Sidekiq worker configurations
(multiple hosts) Redis needs to be running on one host and acessible by 
all the hosts that the Sidekiq workers are running on.

To run a basic Redis instance using Docker:
```
docker run --name redis-file-stats -p 6379:6379 -d redis
```
For production you should use something more robust with both replication and persistence:
https://redis.io/topics/replication  
https://redis.io/topics/persistence

### Packages

The following packages are required

* Ruby 2.7.1 
* Rails 6.0.3.2 
* yarn 
* node
* sqlite3
* Redis Server
* bundler 2.1.4 + (```gem install bundler:2.1.4```)

### Adding more processing nodes

Sidekiq can run processing workers on multiple nodes (physical machines or EC2 instances for example), the following changes need to be made for this to work.

* The results are currently stored in /tmp, this will need changing to a shared filesystem, an object store (S3 etc) or in the database.

* The input files need to be on a shared filesystem so they can be picked up by any worker

* ~~The database needs to be shared so that Sidekiq workers can make status updates (move to MongoDB)~~

### Debugging
To facilitate debugging from vscode (using WSL2 on Windows 10), add the ruby-debug-ide and debase gems - e.g.

```
rails new <appname>
cd <appname>
gem install ruby-debug-ide debase
bundle install
code .
```

## Running Distributed on AWS

This section details the steps required to build and run on AWS instances with the web server, Redis and MongoDB on one instance and the Sidekiq worker on another.

It takes some liberties with security between the components, relying on AWS security instead.

```

# create a security group in your VPC that allows all traffic from other members of the group
# create access to that security group as required for ports 
# 22 - SSH 
# 3000 - access to web server

# create an EC2 instance from the Amazon Linux 2 AMI - a t3.medium is fine for experimenting.

# SSH into the instance and....

# install the AWS EFS libraries
sudo yum install -y amazon-efs-utils

# install Redis
sudo amazon-linux-extras install redis4.0
# edit the file /etc/redis.conf and comment out the bind to localhost line and set protected mode to no. See MongoDB section for notes on changing the bind address.

# bind 127.0.0.1
protected-mode no

sudo systemctl enable redis
sudo systemctl start redis

# install mongodb - follow instructions
https://docs.mongodb.com/manual/tutorial/install-mongodb-on-amazon/
# edit /etc/mongod.conf and change the bind address to 0.0.0.0 
# NB: it should be bound more tightly but the AWS security configuration doesn’t expose the port so it’s not a big problem here. In production, binding to (for example), the subnet CIDR would be better

# I had to do the following because the ec2-user owned it and it was preventing starts
sudo chown mongodb:mongodb /tmp/mongodb-27017.sock

# install some common prerequisites
sudo yum install -y git curl gpg gcc gcc-c++ make

# Use the commands at rvm.io to get the project keys and run the installation script for rvm to install Ruby - e.g.
gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB

# install Ruby and Rails
\curl -sSL https://get.rvm.io | bash -s stable --rails

# install node v12
curl -sL https://rpm.nodesource.com/setup_12.x | sudo -E bash -
sudo yum install -y nodejs

# install yarn
sudo npm install -g yarn

# get any path changes by logging out and back in again

# get ruby version 2.7.1
rvm install "ruby-2.7.1"
rvm use "ruby-2.7.1"

# get the app from github and install
git clone https://github.com/MarkMarsh/ruby-on-rails-test.git
cd ruby-on-rails-test
gem install bundler
bundle install
yarn install --check-files
rake assets:precompile

# create an AWS EFS file system using the AWS EFS console
# https://docs.aws.amazon.com/efs/index.html
# this gives us a shared drive for input files and results
# create an access point /file_stats in the EFS file system

# create a mount point file_stats on the EC2 instance
sudo mkdir /mnt/file_stats
sudo chmod 777 /mnt/file_stats

# add the following line to the EC2 instances /etc/fstab file
# you can get the <access-point-id> and <file-system-id> by clicking the 
# Attach button on the top right of the access point page
<file-system-id> /mnt/file_stats efs _netdev,tls,accesspoint=<access-point-id> 0 0

# mount the EFS file system with
sudo mount /mnt/file_stats

# put a big(ish) text file in /mnt/file_stats/big.txt

# start the server
export FILE_STATS_RESULTS_BASE_DIR=/mnt/file_stats/results/
cd ~/ruby-on-rails-test
rails server -b 0.0.0.0

# connect a web browser to <ec2 instance public IP>:3000
click “analyse new file” and enter /mnt/file_stats/big.txt

# the file will show as queued but will not process until we add a Sidekiq worker process

```
### Create an instance for the Sidekiq worker
```
# use the AWS console to create an AMI from the EC2 instance 
# create another EC2 instance using that AMI (make sure you use the same security group)

# ssh into the new instance
# stop the redis and mongodb servers (note that the CLI tools can restart them).
sudo systemctl stop redis
sudo systemctl disable redis
sudo systemctl stop mongod
sudo systemctl disable mongod

# setup for remote 
# get the internal IP address of the first EC2 instance
export REDIS_URL="redis://<first instance IP address>:6379/0"
vi config/mongoid.yml
# change the line below hosts - replace “localhost” with the first instances IP address
# e.g.
#       hosts:
#        - 172.31.33.225:27017

# start a worker process with 
export FILE_STATS_RESULTS_BASE_DIR=/mnt/file_stats/results/
bundle exec sidekiq -q file_stats

# you should now see progress messages and the web interface should show progress 

# additional workers can be run on both EC2 instances

```

## To Do

* Work on presentation 
  - html & css (use bootstrap?)
  - add facility to submit a file directly from the main page
* Add validation (check file exists)
* Add other file file storage types (S3 etc)
* Add a file picker for local file system
* Sort out constants like the queue name
* 
* ~~Use MongoDB as the database~~
* Document running in production mode
* ~~Test running with distributed workers~~
* Work out minimum component versions and update Gemfile / docs
* Add authentication - maybe https://github.com/thoughtbot/clearance ?
* Move processing progress update to Redis from the database
* Add pause and cancel using Redis - https://github.com/mperham/sidekiq/wiki/FAQ#how-do-i-cancel-a-sidekiq-job
* Fix scaffold tests broken by schema change and add more tests 
* Rip out unwanted scaffold code
* Dockerise and build Kubernetes deployment

