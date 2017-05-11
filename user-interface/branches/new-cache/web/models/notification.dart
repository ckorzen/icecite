part of models;

/// The class Notification. 
class Notification extends Observable {
  /// The type of notification.
  @observable NotificationType type;
  /// The short description of notification.
  @observable String short;
  /// The onclick handler
  @observable Function onClick;
  /// The onclick handler
  @observable Function onAbort;
  
  /// The default constructor.
  Notification(this.type, this.short, {this.onClick, this.onAbort});
  
  /// The default constructor.
  Notification.fromData(String typeStr, this.short) {    
    switch (typeStr) {
      case "error":
        type = NotificationType.ERROR;
        break;
      case "warn":
        type = NotificationType.WARN;
        break;
      case "info":
        type = NotificationType.INFO;
        break;
      case "success":
        type = NotificationType.SUCCESS;
        break;
      case "loading":
        type = NotificationType.LOADING;
        break;
      default:
        type = null;
        break;
    }
  }
}


/// The class NotificationType. 
class NotificationType {
  /// The type of this notification.
  final String _type;
  /// The internal constructor.
  const NotificationType._internal(this._type);
  
  /// The type error.
  static const ERROR = const NotificationType._internal('error');
  
  /// The type warn.
  static const WARN = const NotificationType._internal('warn');
  
  /// The type info.
  static const INFO = const NotificationType._internal('info');
  
  /// The type success.
  static const SUCCESS = const NotificationType._internal('success');
  
  /// The type loading.
  static const LOADING = const NotificationType._internal('loading');
  
  /// Returns a string representation of this notification.
  String toString() => _type;
}