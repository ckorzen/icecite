package de.freiburg.iif;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.InputStream;
import java.util.Properties;

import org.apache.log4j.Logger;
import org.ektorp.CouchDbConnector;
import org.ektorp.CouchDbInstance;
import org.ektorp.DbPath;
import org.ektorp.changes.ChangesCommand;
import org.ektorp.changes.ChangesFeed;
import org.ektorp.changes.DocumentChange;
import org.ektorp.http.HttpClient;
import org.ektorp.http.StdHttpClient;
import org.ektorp.impl.StdCouchDbInstance;
import org.jasypt.encryption.pbe.StandardPBEStringEncryptor;
import org.jasypt.properties.EncryptableProperties;


public class CouchDbWatcher {
  // The name of properties file.
  private static final String PROP_FILE = "app.properties";
  
  // The log.
  Logger LOG = Logger.getLogger(CouchDbWatcher.class);
  // The properties object.
  Properties props;
  
  HttpClient httpClient;
  CouchDbInstance dbInstance;
  CouchDbConnector db;
        
  public CouchDbWatcher() {
    StdHttpClient.Builder builder = new StdHttpClient.Builder();
    
    StandardPBEStringEncryptor encryptor = new StandardPBEStringEncryptor();
    encryptor.setPassword("secret"); // TODO: Dont hardcode this password here.
        
    this.props = new EncryptableProperties(encryptor);
    
    try {
      props.load(getClass().getClassLoader().getResourceAsStream(PROP_FILE));
      String externalProperties = System.getProperty(PROP_FILE);
      if (externalProperties != null) {
        InputStream is = null;
        try {
          is = new FileInputStream(externalProperties);
        } catch (FileNotFoundException e) {
          // continue.
        }
        if (is != null) {
          props.load(is); 
        }
      }
            
      builder.url(props.getProperty("couchdb.url"));
      builder.username(props.getProperty("couchdb.username"));
      builder.password(props.getProperty("couchdb.password"));
    } catch (Exception e) {
      e.printStackTrace();
    }
        
    this.httpClient = builder.build();
    this.dbInstance = new StdCouchDbInstance(httpClient);
  }
      
  public void watchEntriesDatabase(String dbName) throws InterruptedException {
    CouchDbConnector db = dbInstance.createConnector(dbName, true);
    ChangesCommand cmd = new ChangesCommand.Builder().build();
    ChangesFeed feed = db.changesFeed(cmd);
    
    while (feed.isAlive()) {
      try {
        DocumentChange change = feed.next();
        
        String docId = change.getId();
        String supplementsDbName = "supplements-" + docId;
        
        System.out.println("Change");
        
        if (change.isDeleted()) {
          deleteDb(supplementsDbName);
        } else {
          ensureDbExistence(supplementsDbName); 
        }
      } catch (Exception e) {
        e.printStackTrace();
      }
    }
  }
  
  public void ensureDbExistence(String name) {    
    boolean exists = dbInstance.checkIfDbExists(new DbPath(name));
    if (!exists) {
      dbInstance.createDatabase(name);
    }
  }
  
  public void deleteDb(String name) {
    boolean exists = dbInstance.checkIfDbExists(new DbPath(name));
    if (exists) {
      dbInstance.deleteDatabase(name);
    }
  }
}