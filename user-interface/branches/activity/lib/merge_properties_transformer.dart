import 'dart:async';
import 'package:barback/barback.dart';

class MergePropertiesTransformer extends Transformer { 
  String mode;
  AssetId mainAssetId;
  AssetId extensionAssetId;
  Map<String, String> properties = {};
  
  /// The constructors.
  MergePropertiesTransformer(this.mode);
  MergePropertiesTransformer.fromList(List a): this(a[0]);
  MergePropertiesTransformer.asPlugin(BarbackSettings settings) : 
    this.fromList(_parseSettings(settings));
      
  @override
  String get allowedExtensions => ".dart";
    
  @override
  Future<bool> isPrimary(AssetId input) {
    bool res = false;
    if (_isMainAsset(input) || _isExtensionAsset(input)) res = true; 
    return new Future.value(res);
  }
  
  @override
  Future apply(Transform transform) {
    // Don't forward the transform.
    transform.consumePrimary();
    return transform.primaryInput.readAsString().then((content) {
      if (_isMainAsset(transform.primaryInput.id)) {
        // Read the main properties asset and put all properties into map.
        _readProperties(content, (key, value) {
          // Don't overwrite existing properties.
          if (!properties.containsKey(key)) properties[key] = value;
        });
        mainAssetId = transform.primaryInput.id;
      } else if (_isExtensionAsset(transform.primaryInput.id)) {
        // Read the extension properties asset and put all properties into map.
        _readProperties(content, (key, value) {
          // Overwrite existing properties.
          properties[key] = value;
        });
        extensionAssetId = transform.primaryInput.id;
      }
        
      // Write output asset if both files were processed.
      if (mainAssetId != null && extensionAssetId != null) {
        StringBuffer sb = new StringBuffer();
        properties.values.forEach((String property) {
          sb.write(property + "\n");
        });
        transform.addOutput(new Asset.fromString(mainAssetId, sb.toString()));
      }
    });
  }
  
  // ___________________________________________________________________________
  // Helper methods.
  
  void _readProperties(String content, var callback) {
    List<String> lines = content.split("\n");
    lines.forEach((String line) {
      int indexOfEqualSign = line.indexOf("=");
      if (indexOfEqualSign > -1) {
        String key = line.substring(0, indexOfEqualSign).trim();
        callback(key, line);
      }
    });
  }
  
  bool _isMainAsset(AssetId a) => a.path.endsWith("properties.dart"); 
  
  bool _isExtensionAsset(AssetId a) => a.path.endsWith("properties.$mode.dart");
  
  static List<String> _parseSettings(BarbackSettings settings) {
    return [ settings.mode.name ];
  }
}