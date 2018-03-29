var setLastUpdateStable = function setLastUpdateStable(date) {
	document.getElementById("last-update-stable").innerHTML = date;
};
		
var setLastUpdateDev = function setLastUpdateDev(date) {
	document.getElementById("last-update-dev").innerHTML = date;
};
		
var readLastUpdate = function readLastUpdate(filepath, callback) {
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", filepath, true);
	xmlhttp.onreadystatechange = function() {
		if (xmlhttp.readyState == 4 && xmlhttp.status == 200) {
			callback(xmlhttp.responseText);
		}
	}
	xmlhttp.send();
};
		
readLastUpdate("/stable/build/web/creation", setLastUpdateStable);
readLastUpdate("/dev/build/web/creation", setLastUpdateDev);