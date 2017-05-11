var base64toArrayBuffer = function base64toArrayBuffer(base64) {
  var binary_string = window.atob(base64);
  var length = binary_string.length;
  var uint8Array = new Uint8Array(length);
  for (var i = 0; i < length; i++) {
    uint8Array[i] = binary_string.charCodeAt(i);
  }
  return uint8Array.buffer;
}

var convertDate = function convertDate(date) {
  var dateBuffer = ['01', '.', '01', '.', '1970', ' ', '00', ':', '00', ':', '00'];
  
  if (date) {
    // The date is a string of the form (D:YYYYMMDDHHmmSSOHH'mm')
    var index = date.search(/\d/); // Find first digit.
    date = date.substring(index);
    index = date.search(/\D/); // Find first non-digit.
    date = date.substring(0, index);

    var length = date.length;
    if (length >= 4) {
      dateBuffer[4] = date.substring(0, 4); // year
    }
    if (length >= 6) {
      dateBuffer[2] = date.substring(4, 6); // month
    }
    if (length >= 8) {
      dateBuffer[0] = date.substring(6, 8); // day
    }
    if (length >= 10) {
      dateBuffer[6] = date.substring(8, 10); // hours
    }
    if (length >= 12) {
      dateBuffer[8] = date.substring(10, 12); // minutes
    }
    if (length >= 14) {
      dateBuffer[10] = date.substring(12, 14); // seconds
    }
  }
  return dateBuffer.join('');
}

// Converts the 
var convert = function convert(annot, pageIndex) {
  if (!annot) return;
  if (!annot.subtype) return;
  // Process only highlight and text annotations.
  if (annot.subtype !== 'Highlight' && annot.subtype !== 'Text') return;
  
  var converted = {
    'annotationType': annot.annotationType,
    // TODO: Use AnnotationSubtype, but it isn't available in the current setup.
    'subtype': (annot.subtype === 'Highlight') ? 2 : 1, 
    'rect': annot.rect,
    'color': annot.color,
    'creationDate': convertDate(annot.creationDate),
    'modificationDate': convertDate(annot.modificationDate),
    'pageIndex': pageIndex || 0,
    'author': annot.author || annot.title
  };
  
  if (!converted.annotationType) {
    // TODO: Use AnnotationSubtype, but it isn't available in the current setup.
    converted.annotationType = (annot.subtype === 'Highlight') ? 4 : 2; 
  }
    
  if (annot.quadPoints) {
    converted.quadPoints = annot.quadPoints;
  }
  
  if (annot.content) {
    converted.text = annot.content;
  }
    
  return converted;
}

var extractNativeAnnotations = function extractAnnotations(pdf, callback) {
  var buffer = base64toArrayBuffer(pdf);
   
  var promises = [];
  PDFJS.getDocument({'data': buffer}).then(function(pdfDocument) {
    for (var i = 1; i <= pdfDocument.numPages; i++) {
      var promise = pdfDocument.getPage(i).then(function(page) {
        return page.getAnnotations();
      });
      promises.push(promise);
    }
      
    Promise.all(promises).then(function(annots) {
      var annotations = [];
      for (var i = 0; i < annots.length; i++) {
        for (var j = 0; j < annots[i].length; j++) {
          var annot = convert(annots[i][j], i);
          if (annot) annotations.push(annot);
        }
      }
      callback(null, annotations);
    }, function(err) {
      callback(err);
    });
  }, function(err) {
    callback(err);
  });
}