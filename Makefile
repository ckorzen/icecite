SHELL = /usr/local/bin/bash

CURRENT_DIR = $(shell pwd)

COUCHDB_LOG_DIR = /usr/local/var/log/couchdb
COUCHDB_LOG_OUTPUT = $(CURRENT_DIR)/log/couchdb/couchdb.log

start: start-database start-completesearch

restart: restart-database restart-completesearch

stop: stop-database stop-completesearch

start-database: start-couchdb start-couchdb-watcher

restart-database: restart-couchdb restart-couchdb-watcher

stop-database: stop-couchdb stop-couchdb-watcher

start-couchdb:
	@echo "*** Starting couchdb ***"
	@sudo /etc/init.d/couchdb start

restart-couchdb:
	@echo "*** Restarting couchdb ***"
	@sudo /etc/init.d/couchdb restart

stop-couchdb:
	@echo "*** Stopping couchdb ***"
	@sudo /etc/init.d/couchdb stop

start-couchdb-watcher:
	@echo "*** Start watching couchdb  ***"
	@sudo /etc/init.d/couchdb-watcher start

restart-couchdb-watcher:
	@echo "*** Restart watching couchdb ***"
	@sudo /etc/init.d/couchdb-watcher restart

stop-couchdb-watcher:
	@echo "*** Stop watching couchdb ***"
	@sudo /etc/init.d/couchdb-watcher stop

start-completesearch:

restart-completesearch:

stop-completesearch:

log:
	@cd ./couchdb/couchdb-log-parser && $(MAKE) all;
	@cd ./couchdb/couchdb-log-parser && $(MAKE) INPUT=$(COUCHDB_LOG_DIR) \
	  OUTPUT=$(COUCHDB_LOG_OUTPUT) run;
