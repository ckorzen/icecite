library cache;

import 'dart:collection';

/// The feed entry cache.
abstract class Cache<K, V> implements Map<K, V> {
  final Map<K, V> _map;
  
  /// Creates a cache.
  Cache() : _map = new HashMap<K, V>();
  
  // ___________________________________________________________________________
  
  // Abstract method.
  void fill();
  
  Iterable<K> get keys => _map.keys;

  Iterable<V> get values => _map.values;

  int get length => _map.length;

  get isEmpty => length == 0;

  get isNotEmpty => !isEmpty;

  bool containsValue(Object value) => _map.containsValue(value);

  bool containsKey(Object key) => _map.containsKey(key);

  V operator [](Object key) => _map[key];

  void operator []=(K key, V value) { _map[key] = value; }
    
  void addAll(Map<K, V> other) {
    other.forEach((K key, V value) { this[key] = value; });
  }

  V remove(Object key) => _map.remove(key); 
    
  void clear() => _map.clear();
    
  String toString() => Maps.mapToString(this);

  void forEach(void f(K key, V value)) => _map.forEach(f);
  
  V putIfAbsent(K key, V ifAbsent()) => _map.putIfAbsent(key, ifAbsent);
}