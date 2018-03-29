library history_element;
 
import 'dart:html' hide Location;
import 'package:polymer/polymer.dart' hide ObservableMap;
import '../models/models.dart';
import '../utils/html/location_util.dart';
import 'icecite_element.dart';

/// The history element of Icecite.
@CustomTag('history-element')
class HistoryElement extends IceciteElement {
  /// The list of history entries.
  @observable List<HistoryEntry> history = toObservable([]);
  /// The number of history entries to show.
  @observable int sizeOfHistory = 5; // TODO: Move to properties.
  
  /// The name of selected event.
  static const String EVENT_HISTORY_ELEMENT_SELECTED = "entry-selected";
  
  // ___________________________________________________________________________
  
  /// The default constructor.
  HistoryElement.created() : super.created();
    
  @override
  void attached() {
    super.attached();    
    actions.onLibraryEntryChanged.listen(onLibraryEntryChangedInDb);
    actions.onLibraryEntryDeleted.listen(onLibraryEntryDeletedInDb);
  }
  
  @override
  void resetOnLogout() {
    super.resetOnLogout();
    if (this.history != null) this.history.clear();
  }
  
  // ___________________________________________________________________________
  // Handlers.
  
  /// This method is called, whenever a library entry was selected.
  void onLibraryEntrySelected(entry) => handleLibraryEntrySelected(entry); 
         
  /// This method is called, whenever a library entry was changed in db.
  void onLibraryEntryChangedInDb(entry) => handleLibraryEntryChangedInDb(entry);
  
  /// This method is called, whenever a library entry was deleted in db.
  void onLibraryEntryDeletedInDb(entry) => handleLibraryEntryDeletedInDb(entry);
      
  /// This method is called, whenever a history entry was clicked.
  void onHistoryEntryClicked(event, entry, target) => 
      handleHistoryEntryClicked(event, target.dataset['idx']);
      
  // ___________________________________________________________________________
  // Actions.
  
  /// Handles a library entry selection.
  void handleLibraryEntrySelected(LibraryEntry entry) {
    // Don't add the entry, if it is not an library entry.
    if (entry == null) return;
    if (entry.brand != 'entry') return;
    if (history.isNotEmpty && entry == history.last.libraryEntry) return;
    // Add the selected entry, if it differs from the previous entry.
    addHistoryEntry(entry);
  }
    
  /// Handles a library entry change in db.
  void handleLibraryEntryChangedInDb(LibraryEntry entry) {
    // Update history entry, if history contains the entry.
    HistoryEntry historyEntry = new HistoryEntry(entry);
    int index = history.indexOf(historyEntry);
    if (index > -1) setHistoryEntry(index, historyEntry);
  }
  
  /// Handles a library entry change in db.
  void handleLibraryEntryDeletedInDb(LibraryEntry entry) {
    // Disable all related history entries. 
    disableHistoryEntry(entry);
  }
    
  /// Handles a click on a history entry.
  void handleHistoryEntryClicked(Event event, String index) {
    retardEvent(event);
    int idx = int.parse(index);
    if (idx < 0) return;
    if (idx > history.length - 1) return;
    fireHistoryElementSelectedEvent(history[idx].libraryEntry);
  }
  
  // ___________________________________________________________________________
  
  /// Creates a history entry for given library entry.
  void addHistoryEntry(LibraryEntry entry) { 
    if (entry == null) return;
    if (entry.title == null || entry.title.trim().isEmpty) return;
    // Remove the first history entries, as long as the history holds at most 
    // sizeOfHistory-many elements. 
    while (history.length > sizeOfHistory - 1) history.removeAt(0);
    history.add(new HistoryEntry(entry));
  }
 
  /// Sets the history entry at position index to given entry.
  void setHistoryEntry(int index, HistoryEntry entry) {
    if (entry == null) return; 
    if (index < 0 || index > history.length - 1) return;
    history[index] = entry;
  }
  
  /// Disables all history entries, related to the given library entry.
  void disableHistoryEntry(LibraryEntry entry) {
    if (entry == null) return;
    // Search the history for related history entries.
    history.forEach((historyEntry) {
      if (historyEntry.libraryEntry == entry) {
        // Disable the history entry.
        historyEntry.isDisabled = true;
      }
    });
  }
  
  /// Fires an 'entry-selected' event.
  void fireHistoryElementSelectedEvent(LibraryEntry entry) {
    Map detail = {'entry': entry, 'location': Location.REFERENCES};
    fire(EVENT_HISTORY_ELEMENT_SELECTED, detail: detail);
  }
}

/// The class representing a history entry.
class HistoryEntry extends Observable {
  /// The related library entry.
  @observable LibraryEntry libraryEntry;
  /// The text of this history entry.
  @observable String text;
  /// Boolean flag indicating, whether this history element is disabled.
  @observable bool isDisabled; 
  /// The number of chars to show of each history element.
  @observable int numOfHistoryChars = 15; // TODO: Move to properties.
  
  /// The default constructor.
  HistoryEntry(LibraryEntry entry) {
    if (entry == null) return;
    if (entry.title == null) return;
    this.libraryEntry = entry;
    this.text = entry.title.substring(0, numOfHistoryChars);
    this.isDisabled = false;
  }
  
  /// Returns the hashCode of this history entry.
  get hashCode => super.hashCode;

  /// Compares this history entry to given other object.
  bool operator==(other) {
    if (identical(other, this)) return true;
    if (other is String) return other == text;
    if (other is LibraryEntry) return other == libraryEntry;
    return (other.libraryEntry.id == libraryEntry.id);
  }
}