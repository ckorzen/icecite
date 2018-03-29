library main_view;

import 'dart:async';
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
  @observable bool showStageView = true;
  
  // The stage view.
  StageView stageView;
  DisplayView displayView;
    
  /// The default constructor.
  MainView.created() : super.created() {
    Timer.run(() {
      StyleElement style = new StyleElement();
      style.text = "@import 'views/main_view.css';";
      shadowRoot.append(style);
    });
  }
      
  // Override
  void resetOnLogout() { 
    super.resetOnLogout();
    this.showStageView = true;
  }
  
  // ___________________________________________________________________________
  // Handlers.
  
  /// The revealed handler.
  void revealedHandler() { // Revealed on login.
    super.revealedHandler();
    this.stageView = get("stage-view");
    this.displayView = get("display-view");
    this.stageView.reveal(); // Show stage view per default.
    this.displayView.reveal(); // Show display view per default.
    get('stage-toggle').classes.add("active");
  }
  
  /// The logout handler.
  void logoutHandler() {
    // Hide the stage toggle.
    get('stage-toggle').classes.remove("active");
  }
  
  /// This method is called, whenever the selection of topics has changed.
  void topicsSelectedHandler(event, detail, target) {
    stageView.topicsSelectedHandler(event, detail, target);
  }
      
  // ___________________________________________________________________________
  // On-purpose methods.
    
  /// Will upload the given files.
  void onUploadFilesPurpose(Event event, List<File> files, Node target) {
    stageView.onUploadFilesPurpose(event, files, target);
  }
  
  /// This method is called, whenever file(s) were uploaded.
  void onUrlUploadPurpose(Event event, String url, Node target) {
    stageView.onUrlUploadPurpose(event, url, target);
  }
    
  /// Will select the given entry.
  void onSelectLibraryEntryPurpose(event, entry, target) {
    stageView.onSelectLibraryEntryPurpose(event, entry, target);
    displayView.onSelectLibraryEntryPurpose(event, entry, target);
  }
    
  /// Will import the given entry.
  void onImportFromPdfPurpose(Event event, LibraryEntry entry, Node target) {
    stageView.onImportFromPdfPurpose(event, entry, target);
  }
  
  /// Will hide the stage.
  void onHideStageViewPurpose(event, entry, target) => hideStageView();
  
  /// Will unhide the stage.
  void onDisplayStageViewPurpose(event, entry, target) => displayStageView();
      
  // ___________________________________________________________________________
  // Actions.
  
  /// Hides the stage.
  void hideStageView() {
    animate(stageView, properties: {'left':'-400px'}, duration: 600);
    animate(displayView, properties: {'left':'20px'}, duration: 600)
      ..onComplete.listen((_) => showStageView = false);
  }
  
  /// Hides the stage.
  void displayStageView() {
    animate(stageView, properties: {'left':'20px'}, duration: 600);
    animate(displayView, properties: {'left':'425px'}, duration: 600)
      ..onComplete.listen((_) => showStageView = true);
  }
}