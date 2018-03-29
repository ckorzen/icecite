library async_queue;

import 'dart:async';
import 'dart:collection';

/// This is a queue of element, for which a async operation has to be executed
/// in sequential order. For each element, the action defined via the process
/// method in the AsyncElement interface is executed in sequential order.
class AsyncQueue<T extends AsyncQueueElement> extends ListQueue<T> {  
  T activeElement;  
  
  /// Queue the given element. To queue the element, its state has to be "idle".
  void queue(T element) {
    if (element == null) return;
    /// Queue the element only, if its state is idle.
    if (element.getState() != AsyncQueueElementState.IDLE) return;
    
    add(element);
    if (length == 1) {
      processFirstElement(); 
    }
  }
    
  /// Processes the first element in the queue.
  void processFirstElement() {
    if (isEmpty) return;
        
    activeElement = first;
    if (activeElement == null) {
      removeFirst();
      processFirstElement();
      return;
    }
    /// Don't process the element, if the state has changed to "aborted" in the 
    /// meanwhile.
    if (activeElement.getState() == AsyncQueueElementState.ABORTED) {
      removeFirst();
      processFirstElement();
      return;
    }
    
    activeElement.process().whenComplete(() {
      removeFirst();
      processFirstElement();
    });
  }
}

abstract class AsyncQueueElement {
  AsyncQueueElementState getState();
  void setState(AsyncQueueElementState state);
  
  Future process();
}

class AsyncQueueElementState {
  final String _state;
  /// The internal constructor.
  const AsyncQueueElementState._internal(this._state);
  
  static const IDLE = const AsyncQueueElementState._internal('idle');
  static const PROCESSING = const AsyncQueueElementState._internal('processing');
  static const COMPLETED = const AsyncQueueElementState._internal('completed');
  static const ABORTED = const AsyncQueueElementState._internal('aborted');
  static const ERROR = const AsyncQueueElementState._internal('error');  
  
  String toString() => _state;
}