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
export REDIS_URL":"redis://<redis server IP>:6379/0"

# run the webserver application
rails s -b 0.0.0.0
```
Connect to the webserver at http://<hostname>:3000


## Dependencies

### Sidekiq 

Sidekiq uses a worker process that communicates via Redis. At least one of these worker  processes must be running (see below). The default configuration is
to look for redis on localhost:6379 but it can be overidden by setting the "REDIS_URL" environment variable - https://github.com/mperham/sidekiq/wiki/Using-Redis



```
# make sure redis is running then:
cd <root of project>

# if Redis is running on a different machine
export REDIS_URL":"redis://<redis server IP>:6379/0"

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

* The results are currently stored in /tmp, this will need changing to a shared filesystem or an object store (S3 etc)

### Debugging
To facilitate debugging from vscode (using WSL2 on Windows 10), add the ruby-debug-ide and debase gems - e.g.

```
rails new <appname>
cd <appname>
gem install ruby-debug-ide debase
bundle install
code .
```

## To Do

* Work on presentation 
  - html & css (use bootstrap?)
  - add facility to submit a file directly from the main page
* Add validation (check file exists)
* Add other file file storage types (S3 etc)
* Add a file picker for local file system
* Document running in production mode
* Test running with distributed workers
* Use a "proper" database
* Work out minimum component versions and update Gemfile / docs
* Add authentication - maybe https://github.com/thoughtbot/clearance ?
* Move processing progress update to Redis from the database
* Add pause and cancel using Redis - https://github.com/mperham/sidekiq/wiki/FAQ#how-do-i-cancel-a-sidekiq-job
* Fix scaffold tests broken by schema change and add more tests 
* Rip out unwanted scaffold code
* Dockerise and build Kubernetes deployment

