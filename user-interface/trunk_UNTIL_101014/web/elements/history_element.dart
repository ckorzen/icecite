library history_element;

import 'package:polymer/polymer.dart' hide ObservableMap;
import '../models/models.dart';
import 'icecite_element.dart';

/// The history element of Icecite.
@CustomTag('history-element')
class HistoryElement extends IceciteElement {
  
  @observable List<LibraryEntry> history = toObservable([]);
  @observable int numOfHistoryChars = 15;
  @observable int sizeOfHistory = 5;
  
  /// The default constructor.
  HistoryElement.created() : super.created();
    
  // Overrides.
  void enteredView() {
    super.enteredView();
//    shadowRoot.append(createStyleElement("elements/history_element.css"));
    
    actions.onLibraryEntryChanged.listen(libraryEntryChangedHandler);
    actions.onLibraryEntryDeleted.listen(libraryEntryDeletedHandler);
  }
  
  // Override
  void resetOnLogout() {
    super.resetOnLogout();
    if (this.history != null) this.history.clear();
  }
  
  // ___________________________________________________________________________
  // Handlers.
  
  /// This method is automatically called, whenever the selected entry was
  /// changed.
  void selectedEntryChanged(LibraryEntry prevSelectedEntry) {
    if (prevSelectedEntry != selectedEntry) add(selectedEntry); 
  }
  
  /// Define the behavior when an entry in storage was added or updated.
  void libraryEntryChangedHandler(LibraryEntry entry) => update(entry);
  
  /// Define the behavior when an entry in storage was deleted.
  void libraryEntryDeletedHandler(LibraryEntry entry) => disable(entry);
  
  // ___________________________________________________________________________
  // On-purpose methods.
  
  /// This method is called, whenever an entry was selected.
  void onSelectLibraryEntryPurpose(event, entry, target) { 
    selectedEntry = entry; // Will trigger the call of selectedEntryChanged.
  }
  
  /// This method is called, whenever a history-element was selected.
  void onSelectHistoryElementPurpose(event, entry, target) {
    int index = int.parse(target.dataset['idx']);
    fire("select-entry", detail: history[index]);
  }
  
  // ___________________________________________________________________________
  // Display methods.
  
  /// Adds the given entry to history.
  void add(LibraryEntry entry) { 
    history.add(entry);
    while (history.length > sizeOfHistory) history.removeAt(0);
  }
 
  /// Reveals the given entry.
  void update(LibraryEntry entry) {
    if (entry == null) return; 
    for (int i = 0; i < history.length; i++) {
      if (history[i] == entry) history[i] = entry;
    }
  }
  
  /// Unreveals all occurennces of the given entry in history.
  void disable(LibraryEntry toDisable) {
    for (int i = 0; i < history.length; i++) {
      LibraryEntry entry = history[i];
      if (entry == toDisable) {
        entry['history-disabled'] = true;
        history[i] = entry;
      }
    }
  }
}