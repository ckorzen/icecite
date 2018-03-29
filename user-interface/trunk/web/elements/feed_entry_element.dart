@MirrorsUsed(targets: 'LibraryEntry')
library feed_entry_element;

import 'dart:html';
import 'dart:mirrors';
import 'package:polymer/polymer.dart';
import 'icecite_element.dart';
import '../models/models.dart';
import '../properties.dart';

/// An entry of the library.
@CustomTag('feed-entry-element')
class FeedEntryElement extends IceciteElement {   
  /// The feed entry.
  @published FeedEntry feed;
  /// The author of feed entry.
  @observable User author;
  /// The boolean, which is true, if the update form is shown - false otherwise.
  @observable bool showTextUpdateForm;
  /// Boolean indicationg whether the verbose mode is turned on or off.
  @observable bool verbose = VERBOSE_MODE;

  /// The cached text of feed entry.
  String prevText;
  /// The name of updated event.
  static const String EVENT_FEED_UPDATED = "feed-updated";
  /// The name of deleted event.
  static const String EVENT_FEED_DELETED = "feed-deleted";
  
  // ___________________________________________________________________________
  
  /// The default constructor.
  FeedEntryElement.created(): super.created();

  @override
  void attached() {
    super.attached();
    this.author = resolveAuthor();
    this.showTextUpdateForm = false;
  }
  
  @override
  void resetOnLogout() {
    super.resetOnLogout();
    this.showTextUpdateForm = false;
    this.prevText = null;
    this.author = null;
  }

  // ___________________________________________________________________________
  // Handlers.

  /// This method is called, whenever new text was committed (via update form).
  void onTextCommitted(event) => handleTextCommitted(event);

  /// This method is called, whenever the commit of a new text was cancelled.
  void onTextCommitCancelled(event) => handleTextCommitCancelled(event);

  /// This method is called, whenever the delete button was clicked.
  void onDeleteButtonClicked(event) => handleDeleteButtonClicked(event);

  /// This method is called, whenever a feed entry was double clicked.
  void onTextDoubleClicked(event) => handleTextDoubleClicked(event);

  // ___________________________________________________________________________
  // Actions

  /// Handles an update of the feed entry.
  void handleTextCommitted(Event event) {
    retardEvent(event);
    // Do nothing, if the text wasn't changed.
    if (feed.data == prevText) return;
    // Hide the update form.
    hideTextUpdateForm(resetToOriginValues: false);
    // Fire update event to inform parent elements.
    fire(EVENT_FEED_UPDATED, detail: feed);
  }

  /// Handles a cancellation of feed update.
  void handleTextCommitCancelled(Event event) {
    retardEvent(event);
    // Hide the update form and reset to origin values.
    hideTextUpdateForm(resetToOriginValues: true);
  }
  
  /// Handles a deletion of this feed entry.
  void handleDeleteButtonClicked(Event event) {
    retardEvent(event);
    // Fire delete event to inform parent elements.
    fire(EVENT_FEED_DELETED, detail: feed);
  }

  /// Handles a double click on feed entry.
  void handleTextDoubleClicked(Event event) {
    retardEvent(event);
    // Don't display the form, if the logged-in user isn't the author of feed. 
    if (user == null) return;
    if (user.id != feed.userId) return;
    // Display the update form and cache the current values.
    displayTextUpdateForm(cacheOriginValues: true);
  }
  
  // ___________________________________________________________________________
  
  /// Displays the form to update the text.
  void displayTextUpdateForm({bool cacheOriginValues}) {
    showTextUpdateForm = true;
    if (cacheOriginValues) {
      prevText = feed.data;
    }
  }

  /// Hides the form to update the text.
  void hideTextUpdateForm({bool resetToOriginValues}) {
    showTextUpdateForm = false;
    if (resetToOriginValues) {
      if (prevText != null) feed.data = prevText;
    }
  }
  
  /// Resolves the author of this feed entry.
  User resolveAuthor() {
    return actions.getUser(feed.userId);
  }
}
