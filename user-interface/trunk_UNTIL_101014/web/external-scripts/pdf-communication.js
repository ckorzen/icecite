var PDF;

function addMessageHandler(id, msgCallback, errCallback) {      	  
  PDF=document.getElementById(id);
  if (PDF) {
  	PDF = PDF.impl;	
  	PDF.messageHandler = {
      onMessage: function(msg) { msgCallback(msg); },
      onError: function(err, msg) { errCallback(err, msg); }
  	}
  }
}
      
function sendToPdf(msg) {
  if (PDF) {
  	PDF.postMessage(msg);
  }
}