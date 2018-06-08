function cmbLoadLookup(objName, destName) {
	$.getJSON(baseURL + "/lookup/" + objName, null, function(data) {
		$(destName + " option").remove();
		$.each(data.results, function(index, item) {
			$(destName).append(
				$("<option></option>")
					.text(item.name)
					.val(item.id)
			);
		});
	});
}

cmbLoadLookup("server", "#sel_Server");
