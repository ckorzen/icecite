include ../../Makefile

DEPLOY_TARGET=/usr/local/bin/couchdb-watcher.jar

all: compile jar deploy

compile:
	@mvn compile;

jar:
	@mvn assembly:single;

clean:
	@mvn clean;

deploy:
	@sudo cp ./target/couchdb-watcher.jar $(DEPLOY_TARGET) && \
	  sudo chown root:root $(DEPLOY_TARGET) && \
	  sudo chmod 755 $(DEPLOY_TARGET) 

