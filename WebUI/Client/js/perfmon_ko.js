Date.prototype.addDays = function(d) {
	return new Date(this.valueOf() + 864E5 * d);
}
function getExecTime(startTime) {
	var delta = Date.now() - startTime; // milliseconds
	return eval(delta)/1000;
}
function getDateString(date) {
	var d = (date == undefined) ? new Date() : new Date(date);
	var dd = d.getDate();
	var mm = d.getMonth()+1;
	var yyyy = d.getFullYear();
	if (dd < 10) { dd = '0' + dd; }
	if (mm < 10) { mm = '0' + mm; }
	return yyyy + '-' + mm + '-' + dd;
}

var lkpItem = function(id, name) {
	this.id = id;
	this.name = name;
};

function getLookup(objName, params, destProp, status) {
	var start = Date.now();
	var url = baseURL + "/lookup/" + objName;
	if (params && params.length > 0) {
		params.forEach(item => {
			url += "/" + item;
		});
	}
	$.getJSON(url, function(data) {
		var res = [];
		$.each(data.results, function(index, item) {
			res.push(new lkpItem(item.id, item.name));
		});
		destProp(res);
		status("Loading " + objName + " list: OK. (loaded " + res.length + " items in " + getExecTime(start) + " s)");
	})
	.fail(function() {
		status("Loading " + objName + " list: ERROR. (exec time: " + getExecTime(start) + " s)");
	});
	return true;
}

var viewModel = {
	status: ko.observable(),
	lkpServers: ko.observableArray(),
	selectedServer: ko.observable(),
	lkpMetricSets: ko.observableArray(),
	selectedMetricSet: ko.observable(),
	lkpMetrics: ko.observableArray(),
	selectedMetric: ko.observable(),
	dateRangeDays: ko.observable()
};
viewModel.status.subscribe(function(newStatus) {
	var t = new Date().toLocaleTimeString().toLowerCase();
	var m = $('#txtStatus').val();
	$('#txtStatus').val(t  + " > " + newStatus + "\n" + ((m === undefined || m == "") ? "" : m.substring(0,1024)));
});
viewModel.selectedServer.subscribe(function(newServer) {
	if (newServer === undefined)
		return;
	var params = [];
	params.push(newServer.id);
	getLookup("metricset", params, viewModel.lkpMetricSets, viewModel.status);
});
viewModel.selectedMetricSet.subscribe(function(newMetricSet) {
	if (newMetricSet === undefined)
		return;
	var params = [];
	params.push(viewModel.selectedServer().id);
	params.push(newMetricSet.id);
	getLookup("metric", params, viewModel.lkpMetrics, viewModel.status);
});
viewModel.dateRangeDays.subscribe(function(newValue) {
	var today = new Date();
	$('#dateEnd').val(getDateString(today));
	$('#dateStart').val(getDateString(today.addDays(-eval(newValue))));
});

function resetDates(startDate, endDate) {
	viewModel.dateRangeDays("0");
	var d = document.getElementById('dateEnd');
	d.value = startDate;
	d = document.getElementById('dateStart');
	d.value = endDate;
}
function resetServer(server_id) {
	// does not work...
	//viewModel.selectedServer().id = server_id;
}


