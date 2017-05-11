library main_view;

import 'dart:html' hide Entry;
import 'package:polymer/polymer.dart';
import 'package:animation/animation.dart';
import 'stage_view.dart';
import 'display_view.dart';
import '../models/models.dart';
import '../elements/icecite_element.dart';
import '../elements/history_element.dart';
import '../cache/library_entry_cache.dart';
import '../utils/html/logging_util.dart' as logging;
import 'package:logging/logging.dart';

/// The main view of Icecite.
@CustomTag('main-view')
class MainView extends IceciteElement {  
  Logger LOG = logging.get("main-view");
  
  /// Boolean, indicating, whether the stageView is displayed.
  @observable bool fullScreenMode = false;

  /// The stage view.
  StageView stageView;
  /// The display view.
  DisplayView displayView;
  /// The library entry cache.
  LibraryEntryCache cache;
  
  /// The history window.
  HistoryElement historyWindow;
        
  // ___________________________________________________________________________
  
  /// The default constructor.
  MainView.created() : super.created() { 
    listenForKeyDownEvents();
    listenForKeyUpEvents();
  }
     
  @override
  void reset() { 
    super.reset();
    this.fullScreenMode = false;
    this.cache.reset();
    this.historyWindow.reset();
  }
  
  /// Listens for keyDown events.
  void listenForKeyDownEvents() {
    window.onKeyDown.listen((evt) {      
      var cmd = (evt.ctrlKey ? 1 : 0) |
        (evt.altKey ? 2 : 0) |
        (evt.shiftKey ? 4 : 0) |
        (evt.metaKey ? 8 : 0);
                        
      if (cmd == 4) { // shift
        switch (evt.keyCode) {
          case 9: // tab
            onStartHistoryRequest(evt);
            break;
          case 37: // left arrow.
            onJumpToPreviousPdfViewRequest(evt);
            break;
          case 38: // up arrow
            onSelectPreviousEntryRequest(evt);
            break;
          case 39: // right arrow.
            onJumpToNextPdfViewRequest(evt);
            break;
          case 40: // down arrow
            onSelectNextEntryRequest(evt);
            break;
          case 122: // F11.
            onToggleFullscreenRequest(evt);
            break;
          default:
            break;
          }
       }
    });
  }
  
  /// Listens for keyUp events.
  void listenForKeyUpEvents() {
    // Listen for key-up events.
    window.onKeyUp.listen((evt) {      
      switch (evt.keyCode) {
        case 16: // shift
          onEndHistoryRequest(evt);
          break;
        default:
          break;
      }
    });
  }
    
  // ___________________________________________________________________________
  // Listeners.
  
  @override
  void onRevealed() => handleRevealed();
      
  @override
  void onLogin(User user) => handleLogin(user);
  
  /// This method is called, whenever a library entry was selected.
  void onSelectEntryRequest(evt, data) => handleSelectEntryRequest(entry: data);
    
  /// This method is called, whenever a previous-entry-request occurs.
  void onSelectPreviousEntryRequest(evt) => handleSelectPreviousEntryRequest();
  
  /// This method is called, whenever a next-entry-request occurs.
  void onSelectNextEntryRequest(evt) => handleSelectNextEntryRequest();

  /// This method is called, whenever a start-history request occurs.
  void onStartHistoryRequest(evt) => handleStartHistoryRequest();
  
  /// This method is called, whenever a end-history request occurs.
  void onEndHistoryRequest(evt) => handleEndHistoryRequest();
  
  /// This method is called, whenever a jump-to-prev-pdf-view request occurs.
  void onJumpToPreviousPdfViewRequest(evt) => handleJumpToPreviousPdfViewRequest();
  
  /// This method is called, whenever a jump-to-next-pdf-view request occurs.
  void onJumpToNextPdfViewRequest(evt) => handleJumpToNextPdfViewRequest();
  
  /// This method is called, whenever an entry was imported from search.
  void onImportFromStageViewRequest(evt, data) => 
      handleImportFromStageViewRequest(evt, data);
  
  /// This method is called, whenever an entry was imported from pdf.
  void onImportFromDisplayViewRequest(evt, data) => 
      handleImportFromDisplayViewRequest(evt, data);
  
  /// This method is called, whenever a library entry was deleted.
  void onDeleteEntryRequest(evt, data) => handleDeleteEntryRequest(evt, data);
  
  /// This method is called, whenever the fullscreen was toggled.
  void onToggleFullscreenRequest(evt) => handleToggleFullscreenRequest();
      
  // ___________________________________________________________________________
  // Handlers.
    
  /// Handles the revealed event.
  void handleRevealed() {
    this.historyWindow = get("history-window");
    this.stageView = get("stage-view");
    this.displayView = get("display-view");
    this.stageView.reveal(); // Show stage view per default.
    this.displayView.reveal(); // Show display view per default.
  }
   
  /// Handles a login event.
  void handleLogin(User user) {
    super.onLogin(user);
    
    LOG.fine("Handle login");
    
    this.cache = new LibraryEntryCache(user);
    
    this.cache.initialize().then((_) {
      LOG.fine("library entry cache initialized");
      /// If there is a entryId given in url request, select the related entry.
      if (selectedEntryId != null) {
        handleSelectEntryRequest(entryId: selectedEntryId);
      }
    });
  }
  
  /// Handles a selection of library entry.
  void handleSelectEntryRequest({Entry entry, String entryId}) {  
    if (entry == null && entryId == null) return;
    
    _select(Entry entry) {
      // Propagate the event to stageView and displayView.
      stageView.selectEntry(entry); 
      displayView.selectEntry(entry);
      historyWindow.push(entry);
    }
    
    if (entry != null) {
      // Select the entry, if entry is already given.
      _select(entry);
    } else {
      LibraryEntry entry = cache.getLibraryEntry(entryId);
      if (entry != null) _select(entry);
    }
  }
  
  /// Handles a update of deletion of feed entry.
  void handleDeleteEntryRequest(Event event, LibraryEntry entry) {
    retardEvent(event);
    displayView.deleteEntry(entry);
    stageView.deleteEntry(entry);
    historyWindow.pop(entry);
  }
   
  /// Handles a previous-entry request.
  void handleSelectPreviousEntryRequest() {
    handleSelectEntryRequest(entry: stageView.getPreviousEntry());
  }
   
  /// Handles a next-entry request.
  void handleSelectNextEntryRequest() {
    handleSelectEntryRequest(entry: stageView.getNextEntry());
  }

  /// Handles a previous-entry request.
  void handleStartHistoryRequest() {
    historyWindow.scroll();
  }
   
  /// Handles a next-entry request.
  void handleEndHistoryRequest() {
    historyWindow.selectCurrentEntry();
  }
  
  /// Handles a previous-entry request.
  void handleJumpToPreviousPdfViewRequest() {
    displayView.jumpToPreviousPdfView();
  }
   
  /// Handles a next-entry request.
  void handleJumpToNextPdfViewRequest() {
    displayView.jumpToNextPdfView();
    // displayView.onPreviousViewRequest();
  }
  
  /// Handles an import from pdf.
  void handleImportFromStageViewRequest(Event event, Entry entry) {
    retardEvent(event);
    // Propagate the event to stageView.
    stageView.import(entry..['userId'] = user.id, cancelSearch: false);
  }
  
  /// Handles an import from pdf.
  void handleImportFromDisplayViewRequest(Event event, Entry entry) {
    retardEvent(event);
    if (cache.contains(entry)) {
      // Don't import the entry, if it is already cached. Instead, select it.
      // Don't use entry here, because it could be a reference-entry.
      handleSelectEntryRequest(entryId: entry.id); 
    } else {
      // Propagate the event to stageView.
      stageView.import(entry..['userId'] = user.id, cancelSearch: true);
    }
  }
  
  /// Handles a toggle fullscreen request.
  void handleToggleFullscreenRequest() {   
    if (fullScreenMode) {
      displayStageView();
    } else {
      hideStageView();
    }
  }
    
  // ___________________________________________________________________________
  // Actions.
 
  /// Hides the stage.
  void hideStageView() {
    animate(stageView, properties: {'left':'-425px'}, duration: 600);
    animate(displayView, properties: {'left':'0px'}, duration: 600)
      ..onComplete.listen((_) => fullScreenMode = true);
  }
  
  /// Hides the stage.
  void displayStageView() {
    animate(stageView, properties: {'left':'0px'}, duration: 600);
    animate(displayView, properties: {'left':'415px'}, duration: 600)
      ..onComplete.listen((_) => fullScreenMode = false);
  }
  
  /// Jumps to the previous pdf view.
  void jumpToPreviousPdfView() { 
    displayView.jumpToPreviousPdfView();
  }
    
  /// Jumps to the next pdf view.
  void jumpToNextPdfView() {
    displayView.jumpToNextPdfView();
  }
}