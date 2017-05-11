import 'dart:async';
import 'package:barback/barback.dart';

class AppCacheManifestTransformer extends Transformer {   
  /// The constructors.
  AppCacheManifestTransformer();
  AppCacheManifestTransformer.fromList(List a): this();
  AppCacheManifestTransformer.asPlugin(BarbackSettings settings) : 
    this.fromList(_parseSettings(settings));
      
  @override
  String get allowedExtensions => ".html .css .js";
    
//  @override
//  Future<bool> isPrimary(AssetId input) {
//    return new Future.value(true);
//  }
  
  @override
  Future apply(Transform transform) {
    print("* ${transform.primaryInput.id}");
    // Don't forward the transform.
    transform.consumePrimary();
    return transform.primaryInput.readAsString().then((content) {
      
    });
  }
    
  static List<String> _parseSettings(BarbackSettings settings) {
    return [ settings.mode.name ];
  }
}
