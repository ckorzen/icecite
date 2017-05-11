/// The class Request. 
class IceciteRequest {  
  /// The select entry request.
  static const String SELECT_ENTRY = 'select-request';
  /// The name of update-entry request.
  static const String UPDATE_ENTRY = "update-request";
  /// The name of entry-deleted event.
  static const String DELETE_ENTRY = "delete-request";
  /// The name of user-invited event.
  static const String SHARE_ENTRY = "share-request";
  /// The name of unshare request.
  static const String UNSHARE_ENTRY = "unshare-request";
  /// The name of tag-added event.
  static const String NEW_TAGS = "new-tags-request";
  /// The name of update-tag request.
  static const String UPDATE_TAG = "update-tag-request";
  /// The name of delete-tag request.
  static const String DELETE_TAG = "delete-tag-request";
  /// The name of select-tag request.
  static const String SELECT_TAG = "select-tag-request";
  /// The name of download-request event. 
  static const String IMPORT_ENTRY = "import-request";
  /// The name of "prev-entry-request" event
  static const String SELECT_PREV_ENTRY = "select-prev-request";
  /// The name of "next-entry-request" event
  static const String SELECT_NEXT_ENTRY = "select-next-request";
  /// The name of "scroll-history-start" event
  static const String START_HISTORY = "start-history-request";
  /// The name of "scroll-history-end" event
  static const String END_HISTORY = "end-history-request";
  /// The name of "fullscreen-toggle" event
  static const String TOGGLE_FULLSCREEN = "toggle-fullscreen-request";
  /// The name of "files-upload" event
  static const String UPLOAD_FILES = "upload-files-request";
  /// The name of "url-upload" event
  static const String UPLOAD_URL = "upload-url-request";
  /// The name of "google-login" request.
  static const String GOOGLE_LOGIN = "google-login-request";
  /// The name of "search" request.
  static const String SEARCH = "search-request";
  /// The name of "cancel-search" request.
  static const String CANCEL_SEARCH = "cancel-search-request";
  /// The name of "filter-tags" request.
  static const String FILTER_BY_TAGS = "filter-by-tags-request";
  /// The name of "add-pdf-url" request.
  static const String ADD_PDF_URL = "add-pdf-url-request";
  /// The name of "repeat-stripping" request.
  static const String REPEAT_STRIPPING = "repeat-stripping-request";
}

class IceciteEvent {
  // The name of "annot-deleted" event
  static const String ANNOT_ADDED = "annot-added";
  // The name of "annot-updated" event
  static const String ANNOT_UPDATED = "annot-updated";
  // The name of "annot-deleted" event
  static const String ANNOT_DELETED = "annot-deleted";
}