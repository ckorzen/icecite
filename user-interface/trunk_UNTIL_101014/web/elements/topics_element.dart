library topics_element;

import 'package:polymer/polymer.dart' hide ObservableMap;
import 'icecite_element.dart';
import '../models/models.dart';

/// The uploader of Icecite.
@CustomTag('topics-element')
class TopicsElement extends IceciteElement {  
  @observable List<LibraryEntry> topics = toObservable([]);
  @observable List<String> selectedTopicIds = toObservable([]);
  
  /// The default constructor.
  TopicsElement.created() : super.created();
     
  /// Override.
  void enteredView() {
    super.enteredView();
//    shadowRoot.append(createStyleElement("elements/topics_element.css"));
    
    // Wait until the library entries are cached.
    if (actions.areLibraryEntriesFilled()) fill();
    actions.onLibraryEntriesFilled.listen((_) => fill());
    actions.onTopicChanged.listen((top) => topicChangedHandler(top));
    actions.onTopicDeleted.listen((top) => topicDeletedHandler(top));
  }
  
  // Override
  void resetOnLogout() {
    super.resetOnLogout();
    if (this.topics != null) this.topics.clear();
    if (this.selectedTopicIds != null) selectedTopicIds.clear();
  }
  
  // ___________________________________________________________________________
  // Handlers.
        
  /// Define the behavior when an entry in storage was added or updated.
  void topicChangedHandler(LibraryEntry topic) {
    if (topic == null) return;
    if (topic.formerUserIds != null && topic.formerUserIds.contains(user.id)) {
      // The user is member of formerUsers. So he should be rejected.
      rejectFormerUser(topic);
    } else if (topic.userIds != null && topic.userIds.contains(user.id)) {
      // The entry is shared with user.
      revealTopic(topic); 
    } else {
      // The entry doesn't belong to user. Delete it.
      topicDeletedHandler(topic);
    }
  } 
  
  /// Define the behavior when an entry in storage was added or updated.
  void topicDeletedHandler(LibraryEntry topic) => unrevealTopic(topic);  
         
  // ___________________________________________________________________________
  // On-purpose methods.
    
  /// Will create a new topic.
  void onCreatePurpose(event, details, target) => create();
  
  /// Will edit a topic.
  void onUpdatePurpose(event, topic, target) => update(topic);
    
  /// Will delete a topic.
  void onDeletePurpose(event, topic, t) => delete(int.parse(t.dataset['idx']));
  
  /// Will select a topic.
  void onSelectPurpose(event, topic, target) => select(topic);
  
  /// Will unselect a topic.
  void onUnselectPurpose(event, topic, target) => unselect(topic);
      
  /// Will assign topic to entry.
  void onAssignEntryPurpose(e, d, t) => assign(d['entryId'], d['topicId']);
  
  /// Will unshare the given topic from given user.
  void onRejectUserPurpose(e, d, t) => rejectUser(d['topic'], d['user']);
  
  // ___________________________________________________________________________
  // Actions.
   
  /// Fills the topics list.
  void fill() => actions.getTopics().forEach((topic) => revealTopic(topic));
        
  /// Creates a new topic.
  void create() => topics.add(new LibraryEntry("topic", "", user));
  
  /// Creates a new topic.
  void update(LibraryEntry topic) {
    actions.setTopic(topic); 
  }
  
  /// Deletes the given topic.
  void delete(int index) {    
    LibraryEntry topic = topics[index];
    if (topic == null) return;
    if (topic.id != null) {
      actions.deleteTopicAndRejectEntries(topic);
    } else {
      // Topics, which wasn't added to db yet, doesn't have an id.  
      topics.removeAt(index);
      if (topic['selected'] == true) unselect(topic);
    }
  }
      
  /// Selects the given topic.
  void select(LibraryEntry topic) {
    fire("topic-selection", detail: selectedTopicIds..add(topic.id));
    topic['selected'] = true;
  }
  
  /// Unselects the given topic.
  void unselect(LibraryEntry topic) {
    fire("topic-selection", detail: selectedTopicIds..remove(topic.id));
    topic['selected'] = false;
  }
  
  /// Assigns the given topic to given entry.
  void assign(String entryId, String topicId) { 
    actions.assignLibraryEntryToTopic(entryId, topicId);
  }
  
  /// Rejects the given topic from given entry.
  void rejectLibraryEntry(LibraryEntry topic, LibraryEntry entry) {
    actions.rejectLibraryEntryFromTopic(entry, topic);
  }
  
  /// Unshares the given entry from given user.
  void rejectUser(LibraryEntry topic, User user) {
    actions.rejectEntryFromUser(topic, user);
  }
  
  /// Rejects former user.
  void rejectFormerUser(LibraryEntry topic) {
    actions.rejectFormerUserFromEntry(user, topic);
  }
  
  // ___________________________________________________________________________
  // Display methods.
  
  /// Reveals a topic, i.e. adds the topic, if it isn't present in
  /// library and updates it otherwise.
  void revealTopic(LibraryEntry topic) {
    if (topic == null) return;
    if (topic.userIds == null) return;
    if (!topic.userIds.contains(user.id)) return;     
    int index = topics.indexOf(topic);
    if (index < 0) topics.add(topic); 
    else topics[index] = topic;
  }
    
  /// Reveals a topic, i.e. adds the topic, if it isn't present in
  /// library and updates it otherwise.
  void unrevealTopic(LibraryEntry topic) {
    topics.remove(topic);
  }
}