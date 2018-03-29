#!/bin/bash
# CouchDb Watcher
#
# description: Watcher for CouchDb

case $1 in
    start)
        /bin/bash /usr/local/bin/couchdb-watcher-start.sh
    ;;
    stop)
        /bin/bash /usr/local/bin/couchdb-watcher-stop.sh
    ;;
    restart)
        /bin/bash /usr/local/bin/couchdb-watcher-stop.sh
        /bin/bash /usr/local/bin/couchdb-watcher-start.sh
    ;;
esac
exit 0
