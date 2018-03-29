library main_view;

import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:animation/animation.dart';
import 'stage_view.dart';
import 'display_view.dart';
import '../models/models.dart';
import '../elements/icecite_element.dart';

/// The main view of Icecite.
@CustomTag('main-view')
class MainView extends IceciteElement {  
  /// Boolean, indicating, whether the stageView is displayed.
  @observable bool isStageViewHidden = false;

  /// The stage view.
  StageView stageView;
  /// The display view.
  DisplayView displayView;
  
  /// The name of stage-toogle event.
  static const String EVENT_STAGE_TOOGLE = "stage-toggle";
  
  // ___________________________________________________________________________
  
  /// The default constructor.
  MainView.created() : super.created() {
  }
      
  @override
  void resetOnLogout() { 
    super.resetOnLogout();
    this.isStageViewHidden = false;
  }
  
  // ___________________________________________________________________________
  // Handlers.
  
  @override
  void onRevealed() => handleRevealed();
  
  @override
  void onLogout() => handleLogout();
    
  /// This method is called, whenever the selection of topics has changed.
  void onTopicsSelected(topicIds) => handleTopicsSelected(topicIds);
     
  /// This method is called, whenever there are files to upload.
  void onFilesUpload(files) => handleFilesUpload(files);
  
  /// This method is called, whenever there is an url for upload.
  void onUrlUpload(url) => handleUrlUpload(url);
    
  /// This method is called, whenever a library entry was selected.
  void onLibraryEntrySelected(entry) => handleLibraryEntrySelected(entry);
    
  /// This method is called, whenever an entry was imported from pdf.
  void onImportedFromPdf(event, entry) => handleImportedFromPdf(event, entry);
  
  /// This method is called, whenever a previous-entry-request occurs.
  void onPreviousEntryRequest() => handlePreviousEntryRequest();
  
  /// This method is called, whenever a next-entry-request occurs.
  void onNextEntryRequest() => handleNextEntryRequest();
  
  void onPreviousViewRequest() => handlePreviousViewRequest();
    
  void onNextViewRequest() => handleNextViewRequest();
  
  void onFullscreenToggleRequest() => handleFullscreenToggleRequest();
  
  // ___________________________________________________________________________
  // Actions.
  
  /// Handles the revealed event.
  void handleRevealed() {
    this.stageView = get("stage-view");
    this.displayView = get("display-view");
    this.stageView.reveal(); // Show stage view per default.
    this.displayView.reveal(); // Show display view per default.
//    get('stage-toggle').classes.add("active");
  }
  
  /// Handles a logout.
  void handleLogout() {
    this.user = null;
    // Hide the stage toggle.
//    get('stage-toggle').classes.remove("active");
    resetOnLogout();
  }
   
  /// Handles a selection of topics.
  void handleTopicsSelected(Iterable topicIds) {
    // Propagate the event to stageView.
    stageView.onTopicsSelected(topicIds);
  }
  
  /// Handles a files upload.
  void handleFilesUpload(Iterable files) {
    // Propagate the event to stageView.
    stageView.onFilesUpload(null, files);
  }
  
  /// Handles an upload via url.
  void handleUrlUpload(String url) {
    // Propagate the event to stageView.
    stageView.onUrlUpload(null, url);
  }
  
  /// Handles a selection of a library entry.
  void handleLibraryEntrySelected(LibraryEntry entry) {
    // Propagate the event to stageView and displayView.
    stageView.onLibraryEntrySelected(entry);
    if (entry.rev != null) 
      displayView.onLibraryEntrySelected(entry);
  }
  
  /// Handles an import from pdf.
  void handleImportedFromPdf(Event event, LibraryEntry entry) {
    retardEvent(event);
    // Propagate the event to stageView.
    stageView.onImportedFromPdf(entry);
  }
    
  /// Handles a previous-entry request.
  void handlePreviousEntryRequest() {
    stageView.onPreviousEntryRequest();
  }
   
  /// Handles a next-entry request.
  void handleNextEntryRequest() {
    stageView.onNextEntryRequest();
  }
  
  void handlePreviousViewRequest() { 
    displayView.onPreviousViewRequest();
  }
    
  void handleNextViewRequest() {
    displayView.onNextViewRequest();
  }
  
  void handleFullscreenToggleRequest() {   
    if (isStageViewHidden) {
      displayStageView();
    } else {
      hideStageView();
    }
  }
  
  // ___________________________________________________________________________
  
  /// Hides the stage.
  void hideStageView() {
    animate(stageView, properties: {'left':'-425px'}, duration: 600);
    animate(displayView, properties: {'left':'0px'}, duration: 600)
      ..onComplete.listen((_) => isStageViewHidden = true);
  }
  
  /// Hides the stage.
  void displayStageView() {
    animate(stageView, properties: {'left':'0px'}, duration: 600);
    animate(displayView, properties: {'left':'415px'}, duration: 600)
      ..onComplete.listen((_) => isStageViewHidden = false);
  }
}