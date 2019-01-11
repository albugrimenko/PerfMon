function getReport(rptName, params, dest) {
	var start = Date.now();
	var url = baseURL + "/report/html/" + rptName;
	if (params && params.length > 0) {
		params.forEach(item => {
			url += "/" + item;
		});
	}
	$.ajax({
		cache: false,
		method: "GET",
		url: url,
		dataType: "html",
		beforeSend: function(xhr) {
			$('#' + dest).html('<p class="m-t text-center">...working...<br><img src="./img/ajax-loader.gif" alt="...working..." /></p>');			
		},
		success: function(data) {
			$('#' + dest).html(data);
			if (viewModel != undefined) 
				viewModel.status("Loading " + rptName + ": OK. (exec time: " + getExecTime(start) + " s)");
		},
		error: function(xhr) {
			var err = JSON.parse(xhr.responseText);
			alert("ERROR: " + err.Message);
			if (viewModel != undefined) 
				viewModel.status("Loading " + rptName + ": ERROR. (exec time: " + getExecTime(start) + " s)");
			dest.html('');
		}
	})
	return false;
}

function getReportWithDates(rptName, params, dest, title='', startDate='', endDate='') {
	var start = Date.now();
	var url = baseURL + "/report/html/" + rptName;
	if (params && params.length > 0) {
		params.forEach(item => {
			url += "/" + item;
		});
		//resetServer(server_id=params[0]);
	}

	if (viewModel) {
		if (startDate == '' || endDate == '') {
			startDate = $('#dateStart').val();
			endDate = $('#dateEnd').val();
		}
		else {
			resetDates(startDate=startDate, endDate=endDate);
		}
	}
	url += '?sd=' + startDate + '&ed=' + endDate
	//alert(url);
	$.ajax({
		cache: false,
		method: "GET",
		url: url,
		dataType: "html",
		beforeSend: function(xhr) {
			$('#' + dest).html('<p class="m-t text-center">...working...<br><img src="./img/ajax-loader.gif" alt="...working..." /></p>');			
		},
		success: function(data) {
			$('#' + dest).html('<center><h4>' + title + '</h4></center>' + data);
			if (viewModel != undefined) 
				viewModel.status("Loading " + rptName + ": OK. (exec time: " + getExecTime(start) + " s)");
		},
		error: function(xhr) {
			var err = JSON.parse(xhr.responseText);
			alert("ERROR: " + err.Message);
			if (viewModel != undefined) 
				viewModel.status("Loading " + rptName + ": ERROR. (exec time: " + getExecTime(start) + " s)");
			dest.html('');
		}
	})
	return false;
}
