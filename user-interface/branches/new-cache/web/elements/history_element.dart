library history_window_element;

import 'dart:html';
import 'dart:async';
import 'dart:collection';
import '../models/models.dart';
import '../utils/request.dart';
import '../utils/html/logging_util.dart' as logging;
import 'package:polymer/polymer.dart';
import 'package:logging/logging.dart';

/// The history window element of Icecite.
@CustomTag('history-element')
class HistoryElement extends PolymerElement {  
  Logger LOG = logging.get("history-element");
  DivElement historyElement;
  Queue<LibraryEntry> history;
  Timer displayTimer;
  int currentIndex = 0;
  int maxSize = 5; 
    
  // ___________________________________________________________________________
  
  /// The default constructor.
  HistoryElement.created() : super.created() {
    this.history = new Queue<LibraryEntry>();
  }
  
  void reset() {
    history.clear();
    currentIndex = 0;
  }
  
  @override
  void attached() {
    super.attached();
    this.historyElement = shadowRoot.querySelector(".history-window");
  }
  
  /// Pushes the given library entry into history.
  void push(LibraryEntry entry) {
    LOG.finest("Pushing entry $entry to history.");
    // Delete the entry from history, if it contains the entry (so that the 
    // entry isn't contained twice).
    if (history.contains(entry)) {
      history.remove(entry);
    }
       
    history.addFirst(entry);
       
    // Ensure, that the size of history doesn't exceed the max size.
    while (history.length > maxSize) {
      history.removeLast();
    }
  }
  
  /// Pops the given library entry from history.
  void pop(LibraryEntry entry) {
    LOG.finest("Popping entry $entry from history.");
    if (entry == null) return;
    history.remove(entry);
  }
    
  /// Scrolls the history.
  void scroll() {
    LOG.finest("Scrolling.");
    // Display the history window, if it is hidden.
    if (isHistoryWindowHidden()) {
      displayHistoryWindow();
    }
  
    // The history window can still be hidden, (e.g. if the history is empty).
    if (!isHistoryWindowHidden()) {
      // Scroll.
      blurHistoryElement(currentIndex);
      currentIndex = (currentIndex + 1) % history.length;
      focusHistoryElement(currentIndex);
    }
  }
  
  /// Selects the history element at given index.
  void selectCurrentEntry() {
    if (!isHistoryWindowHidden()) {
      if (currentIndex < history.length) {
        LOG.finest("Selecting entry ${history.elementAt(currentIndex)}");
        fireSelectEntryRequest(history.elementAt(currentIndex));
      }
      hideHistoryWindow();
    }
  }
  
  /// Displays and fills the history window.
   void displayHistoryWindow() {
     LOG.finest("Displaying history window");
     historyElement.children.clear();
     if (history.length > 1) {
       for (int i = 0; i < history.length; i++) {
         var libraryEntry = history.elementAt(i);
         var historyEntry = document.createElement('div');
         historyEntry.className = "history-entry";
        
         var entryTitle = document.createElement('div');
         entryTitle.className = "title";
         entryTitle.text = libraryEntry.title;
         historyEntry.append(entryTitle);
        
         var entryAuthors = document.createElement('div');
         entryAuthors.className = "authors";
         entryAuthors.text = libraryEntry.authors.join(", ");
         historyEntry.append(entryAuthors);
        
         var entryVenue = document.createElement('div');
         entryVenue.className = "venue";
         entryVenue.text = "${libraryEntry.journal} ${libraryEntry.year}";
         historyEntry.append(entryVenue);
        
         this.historyElement.append(historyEntry);
       }
        
       historyElement.style.display = "block";
      
       /// Adjust the margin-top, such that the window is centered vertically. 
       var computedStyle = historyElement.getComputedStyle();
       String computedHeight = computedStyle.height.replaceAll('px', '');
       String top = "${-1 * int.parse(computedHeight) / 2}px";
       historyElement.style.marginTop = top;
     }
   }
  
   /// Hides the history window.
   void hideHistoryWindow() {      
     LOG.finest("Hiding history window");
     if (historyElement != null) {
       historyElement.style.display = "none";
       currentIndex = 0;
     }
   }
  
   /// Returns true, if the history window is hidden. False otherwise.
   bool isHistoryWindowHidden() {
     return historyElement.style.display == "none";
   }
      
   /// Blurs the history entry at given index.
   void blurHistoryElement(int index) {
     Element historyElement = getHistoryElement(index);
     if (historyElement != null) {
       historyElement.classes.remove("focused");
     }
   }
  
   /// Blurs the history entry at given index.
   void focusHistoryElement(int index) {
     Element historyElement = getHistoryElement(index);
     if (historyElement != null) {
       historyElement.classes.add("focused");
     }
   }
  
   /// Returns the history element at given index.
   Element getHistoryElement(int index) {
     if (index > -1) {
       var historyEntries = historyElement.children;
       if (index < historyEntries.length) {
         return historyEntries[index];
       }
     }
     return null;
   }
   
  /// Fires an entry-selected event.
  void fireSelectEntryRequest(LibraryEntry entry) {  
    fire(IceciteRequest.SELECT_ENTRY, detail: entry);
  }
}