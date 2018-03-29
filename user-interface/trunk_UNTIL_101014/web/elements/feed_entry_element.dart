@MirrorsUsed(targets: 'LibraryEntry')
library feed_entry_element;

import 'dart:html';
import "dart:mirrors";
import 'package:polymer/polymer.dart';
import 'icecite_element.dart';
import '../models/models.dart';

/// An entry of the library.
@CustomTag('feed-entry-element')
class FeedEntryElement extends IceciteElement {   
  // Observable properties.
  @published FeedEntry entry;
  @observable bool showUpdateDataView = false;
  // Internal properties.
  String prevData;

  /// The default constructor.
  FeedEntryElement.created(): super.created();

  void enteredView() {
    super.enteredView();
//    shadowRoot.append(createStyleElement("elements/feed_entry_element.css"));
  }
  
  // Override
  void resetOnLogout() {
    super.resetOnLogout();
    this.showUpdateDataView = false;
    this.prevData = null;
  }

  // ___________________________________________________________________________
  // On-purpose methods.

  /// This method is called, whenever an entry was updated.
  void onUpdatePurpose(event, detail, target) => update();

  /// This method is called, whenever an update process was cancelled.
  void onCancelUpdatePurpose(event, detail, target) => cancelUpdate(event);

  /// This method is called, whenever a feed entry was deleted.
  void onDeletePurpose(event, detail, target) => delete();

  /// Define the behavior on double clicking the entry.
  void onDblClickPurpose(event, detail, target) => displayUpdateView(target);

  // ___________________________________________________________________________
  // Actions

  /// Deletes the feed entry.
  void delete() {
    fire('delete-feed-entry', detail: entry);
  }

  /// Updates the feed entry.
  void update() {
    // Fire update event, if data was changed.
    if (entry.data != prevData) fire('edit-feed-entry', detail: entry);
    hideEditView(false);
  }

  /// Cancels the update process of feed entry.
  void cancelUpdate(Event event) {
    // Stop the event propagation, such that no other handlers are affected.
    event.stopPropagation();
    event.preventDefault();
    hideEditView(true);
  }

  // ___________________________________________________________________________
  // Display methods.

  /// Hides the edit view.
  void displayUpdateView(Element target) {
    if (user != entry.user) return;
    switch (target.id) {
      case ("data"):
        showUpdateDataView = true;
        prevData = entry.data;
        break;
    }
  }

  /// Hides the edit view.
  void hideEditView(bool resetToOriginValues) {
    showUpdateDataView = false;
    if (resetToOriginValues) {
      if (prevData != null) entry.data = prevData;
    }
  }
}
