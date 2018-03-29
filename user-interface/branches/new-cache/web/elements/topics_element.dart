//library topics_element;
//
//import 'dart:html';
//import 'package:polymer/polymer.dart' hide ObservableMap;
//import 'icecite_element.dart';
//import '../models/models.dart';
//import '../utils/observable_map.dart';
//
////// The uploader of Icecite.
//@CustomTag('topics-element')
//class TopicsElement extends IceciteElement {
//  /// The topics to show.
//  @observable Map<String, LibraryEntry> topics = new ObservableMap();
//  /// The ids of selected topics.
//  @observable List<String> selectedTopicIds = toObservable([]);
//  
//  /// The name of "topics-selected" event.
//  static const String EVENT_TOPICS_SELECTED = "topics-selected";
//  
//  // ___________________________________________________________________________
//  
//  /// The default constructor.
//  TopicsElement.created() : super.created();
//     
//  @override
//  void attached() {
//    super.attached();
//    
//    // Wait until the library entries are cached.
//    if (actions.areLibraryEntriesFilled()) fillTopics();
//    actions.onLibraryEntriesFilled.listen((_) => fillTopics());
//    actions.onTopicChanged.listen(onTopicChangedInDb);
//    actions.onTopicDeleted.listen(onTopicDeletedInDb);
//  }
//  
//  @override
//  void resetOnLogout() {
//    super.resetOnLogout();
//    if (this.topics != null) this.topics.clear();
//    if (this.selectedTopicIds != null) this.selectedTopicIds.clear();
//  }
//  
//  // ___________________________________________________________________________
//  // Handlers.
//        
//  /// This method is called, whenever a topic was changed in db.
//  void onTopicChangedInDb(topic) => handleTopicChangedInDb(topic);
//    
//  /// This method is called, whenever a topic was deleted in db.
//  void onTopicDeletedInDb(topic) => handleTopicDeletedInDb(topic);  
//             
//  /// This method is called, whenever the new topic button was clicked.
//  void onNewTopicButtonClicked(event) => handleNewTopicButtonClicked(event);
//  
//  /// This method is called, whenever a topic was updated IN VIEW.
//  void onTopicUpdated(event, topic) => handleTopicUpdated(event, topic);
//    
//  /// This method is called, whenever a topic was deleted IN VIEW.
//  void onTopicDeleted(event, topic) => handleTopicDeleted(event, topic);
//  
//  /// This method is called, whenever a topic was selected.
//  void onTopicSelected(event, topic) => handleTopicSelected(event, topic);
//  
//  /// This method is called, whenever a topic was unselected.
//  void onTopicUnselected(event, topic) => handleTopicUnselected(event, topic);
//      
//  /// This method is called, whenever an entry was assigned to a topic IN VIEW.
//  void onLibraryEntryAssigned(event, detail) => 
//      handleLibraryEntryAssigned(event, detail);
//  
//  /// This method is called, whenever a participant was disinvited from a topic.
//  void onParticipantDisinvited(event, detail) => 
//      handleParticipantDisinvited(event, detail);
//
//  /// This method is called, whenever an invitee was disinvited from a topic.
//  void onInviteeDisinvited(event, detail) => 
//      handleInviteeDisinvited(event, detail);
//  
//  /// This method is called, whenever the logged-in user was invited to a topic.
//  void onUserInvited(topic) => handleUserInvited(topic);
//  
//  /// This method is called, whenever the logged-in user was disinvited from a 
//  /// topic.
//  void onUserDisinvited(topic) => handleUserDisinvited(topic);
//  
//  // ___________________________________________________________________________
//  // Actions.
//   
//  /// Handles a change of topic in db.
//  void handleTopicChangedInDb(LibraryEntry topic) {
//    if (user.isInvited(topic)) onUserInvited(topic);
//    else if (user.isDisinvited(topic)) onUserDisinvited(topic);
//    else if (user.isOwnerOrParticipant(topic)) revealTopic(topic);
//    else unrevealTopic(topic);
//  }
//  
//  /// Handles a deletion of topic in db.
//  void handleTopicDeletedInDb(LibraryEntry topic) {
//    // Unreveal the topic.
//    unrevealTopic(topic);
//  }
//  
//  /// Handles a click on new-topic-button.
//  void handleNewTopicButtonClicked(Event event) {
//    retardEvent(event);
//    // Create an new topic.
//    createNewTopic();
//  }
//  
//  /// Handles an update of topic element.
//  void handleTopicUpdated(Event event, LibraryEntry topic) {
//    retardEvent(event);
//    // Update the topic.
//    if (user.isOwner(topic)) updateTopic(topic);
//  }
//  
//  /// Handles a deletion of topic element.
//  void handleTopicDeleted(Event event, LibraryEntry topic) {
//    retardEvent(event);
//    
//    if (topic == null) return;
//    // Unreveal the topic if it isn't persisted yet.
//    if (topic.rev == null) unrevealTopic(topic);
//    // Unselect the topic if it was checked.
//    if (topic.selected) onTopicUnselected(null, topic);
//    // Check, if the logged-in user is the owner of the topic.
//    if (user.isOwner(topic)) { 
//      // The logged-in user is the owner. Delete the topic.
//      deleteTopicAndRejectEntries(topic);
//    } else {
//      // The logged in user isn't the owner. Unsubscribe from topic.
//      unsubscribeUserFromTopic(topic);
//    }
//  }
//  
//  /// Handles a selection of topic element.
//  void handleTopicSelected(Event event, LibraryEntry topic) {
//    retardEvent(event);
//    if (topic == null) return;
//    
//    // Fire "topics-selected" event.
//    fireTopicsSelectedEvent(topic);
//    topic.selected = true;
//  }
//  
//  /// Handles an unselection of topic element.
//  void handleTopicUnselected(Event event, LibraryEntry topic) {
//    retardEvent(event);
//    if (topic == null) return;
//       
//    // Fire "topics-selected" event.
//    fireTopicsUnselectedEvent(topic);
//    topic.selected = false;
//  }
//  
//  /// Handles an assignment of a library entry to topic.
//  void handleLibraryEntryAssigned(Event event, Map detail) {
//    retardEvent(event);
//    // Assigns the library entry to topic.
//    assignLibraryEntryToTopic(detail['entryId'], detail['topicId']);
//  }
//  
//  /// Handles a disinvitation of a user from topic.
//  void handleParticipantDisinvited(Event event, Map detail) {
//    retardEvent(event);
//    // Assigns the entry to topic.
//    unsubscribeParticipantFromTopic(detail['topic'], detail['user']);
//  }
//  
//  /// Handles a disinvitation of an invitee from topic.
//  void handleInviteeDisinvited(Event event, Map detail) {
//    retardEvent(event);
//    // Assigns the entry to topic.
//    unsubscribeInviteeFromTopic(detail['topic'], detail['user']);
//  }
//  
//  /// Handles a invitation of the logged-in user to given topic.
//  void handleUserInvited(LibraryEntry topic) {
//    // Acknowledge the invite request.
//    acknowledgeInviteRequest(topic); 
//  }
//  
//  /// Handles a disinvitation of the logged-in user from given topic.
//  void handleUserDisinvited(LibraryEntry topic) {
//    // Acknowledge the disinvite request.
//    acknowledgeDisinviteRequest(topic); 
//  }
//  
//  // ___________________________________________________________________________
//  
//  /// Fills the topics list.
//  void fillTopics() { 
//    actions.getTopics().forEach((k, topic) => revealTopic(topic));
//  }
//    
//  /// Creates a new topic.
//  void createNewTopic() {
//    // Reveal a dummy topic with a generated id.
//    revealTopic(new LibraryEntry.withGeneratedId("topic", "", user));
//  }
//  
//  /// Updates the topic in database.
//  void updateTopic(LibraryEntry topic) {
//    actions.setTopic(topic); 
//  }
//  
//  /// Deletes the topic and reject the associated entries from topic.
//  void deleteTopicAndRejectEntries(LibraryEntry topic) {    
//    actions.deleteTopicAndRejectEntries(user, topic);
//  }
//  
//  /// Unsubscribes the logged-in user from given topic.
//  void unsubscribeUserFromTopic(LibraryEntry topic) {    
//    actions.unsubscribeUserFromEntry(user, topic, false);
//  }
//  
//  /// Unsubscribes the given participant from topic.
//  void unsubscribeParticipantFromTopic(LibraryEntry topic, User user) {
//    actions.unsubscribeUserFromEntry(user, topic, true);
//  }
//  
//  /// Unsubscribes the given invitee from topic.
//  void unsubscribeInviteeFromTopic(LibraryEntry topic, User user) {
//    actions.unsubscribeUserFromEntry(user, topic, true);
//  }
//  
//  /// Assigns the given library entry to topic.
//  void assignLibraryEntryToTopic(String entryId, String topicId) { 
//    actions.assignLibraryEntryToTopic(entryId, topicId);
//  }
//  
//  /// Acknowledges an invite request.
//  void acknowledgeInviteRequest(LibraryEntry topic) {
//    actions.acknowledgeInviteRequest(user, topic);
//  }
//  
//  /// Acknowleges a disinvite request.
//  void acknowledgeDisinviteRequest(LibraryEntry topic) {
//    actions.acknowledgeDisinviteRequest(user, topic);
//  }
//  
//  // ___________________________________________________________________________
//  
//  /// Reveals the given topic.
//  void revealTopic(LibraryEntry topic) {
//    if (topic == null) return;  
//    if (!user.isOwnerOrParticipant(topic)) return; // TODO: Move to higher level?
//    topics[topic.id] = topic; 
//  }
//    
//  /// Unreveals the given topic.
//  void unrevealTopic(LibraryEntry topic) {
//    if (topic == null) return;
//    topics.remove(topic.id);
//  }
//  
//  // ___________________________________________________________________________
//  
//  /// Add the topic to selectedTopicIds and fires a "topics-selected" event.
//  void fireTopicsSelectedEvent(LibraryEntry topic) {
//    fire(EVENT_TOPICS_SELECTED, detail: selectedTopicIds..add(topic.id));
//  }
//  
//  /// Removes topic from selectedTopicIds and fires a "topics-selected" event.
//  void fireTopicsUnselectedEvent(LibraryEntry topic) {
//    fire(EVENT_TOPICS_SELECTED, detail: selectedTopicIds..remove(topic.id));
//  }
//    
//  // ___________________________________________________________________________
//  
//  /// Filters the user by given filter.  
//  Function sortByTitle() { 
//    return (Iterable<LibraryEntry> topics) { 
//      return topics.toList()..sort(IceciteElement.getComparator("title"));  
//    };
//  }
//}