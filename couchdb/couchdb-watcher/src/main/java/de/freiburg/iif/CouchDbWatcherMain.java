package de.freiburg.iif;

import java.io.IOException;

public class CouchDbWatcherMain {
	public static void main(String[] args) throws InterruptedException, IOException {	  	  	  
	  CouchDbWatcher couchDbWatcher = new CouchDbWatcher();
				  
	  // Ensure the existence of the database "users"
	  couchDbWatcher.ensureDbExistence("users");
		
		// Watch the entries database for changes.
		couchDbWatcher.watchEntriesDatabase("entries");	  
	}
}
