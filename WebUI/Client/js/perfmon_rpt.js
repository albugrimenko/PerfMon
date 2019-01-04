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
			if (xhr && xhr.responseText) {
				var err = JSON.parse(xhr.responseText);
				alert("ERROR: " + err.Message);
			}
			else {
				alert("ERROR: Unable to connect.");
			}
			if (viewModel != undefined) {
				viewModel.status("Loading " + rptName + ": ERROR. (exec time: " + getExecTime(start) + " s)");
			}
			$('#' + dest).html('');
		}
	})
	return false;
}