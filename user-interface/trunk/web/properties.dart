library properties;

// _____________________________________________________________________________
// COMMON Properties.
const bool VERBOSE_MODE = false;

// _____________________________________________________________________________
// AUTH properties

/// The clientId for oAuth2 authentication.
//const AUTH_OAUTH2_CLIENTID = "651417891511.apps.googleusercontent.com";
const AUTH_OAUTH2_CLIENTID = "851169450966.apps.googleusercontent.com";
/// The userinfo scope.
const AUTH_OAUTH2_USERINFO_SCOPE = "https://www.googleapis.com/auth/userinfo.profile";
/// The url to get the userinfo.
const AUTH_OAUTH2_USERINFO_URL = "https://www.googleapis.com/oauth2/v1/userinfo?alt=json&access_token=";

/// The url to get the userinfo.
String OAUTH2_USERINFO_URL(token) => AUTH_OAUTH2_USERINFO_URL + token;

// _____________________________________________________________________________
// REPLICATION properties

/// The base replication url.
//const String DB_REMOTE = 'http://stromboli.informatik.uni-freiburg.de:6501/';
const String DB_REMOTE = 'http://localhost:5984/';
/// The prefix of entries db.
const String DB_ENTRIES_PREFIX = "entries";
/// The prefix of supplements db.
const String DB_SUPPLEMENTS_PREFIX = "supplements";

/// The name of users db.
String DB_USERS_NAME() => "users";
/// The replication url of users database.
String DB_USERS_URL() => DB_REMOTE + DB_USERS_NAME();
/// The name of supplements database.
String DB_SUPPLEMENTS_NAME(String entryId) => "$DB_SUPPLEMENTS_PREFIX-${entryId.toLowerCase()}";
/// The name of supplements database.
String DB_SUPPLEMENTS_URL(String entryId) => DB_REMOTE + DB_SUPPLEMENTS_NAME(entryId);
/// The name of feeds db for given user.
String DB_ENTRIES_NAME(user) => "$DB_ENTRIES_PREFIX-${user.id}"; 
/// The replication url of feeds db for given user.
String DB_ENTRIES_URL(user) => DB_REMOTE + DB_ENTRIES_PREFIX;

// _____________________________________________________________________________
// PDF2META / META2PDF properties.

const String URL_PDF2META = "http://stromboli.informatik.uni-freiburg.de:6222/pdf-machine/pdf2Meta";
const String URL_META2PDF = "http://stromboli.informatik.uni-freiburg.de:6222/pdf-machine/meta2Pdf";

const int TIMEOUT_PDF2META = 30000; // 30 sec.
const int TIMEOUT_META2PDF = 30000; // 30 sec.

// _____________________________________________________________________________
// SEARCH properties.

/// The url of search engine.
String SEARCH_URL(String q) => "http://stromboli.informatik.uni-freiburg.de:6201/?q=${q}&format=json";  

// _____________________________________________________________________________
// LOCATION properties

const String LOCATION_NAME_LIBRARY = "library";
const String LOCATION_NAME_REFERENCES = "references";
const String LOCATION_NAME_FEEDS = "feed";
