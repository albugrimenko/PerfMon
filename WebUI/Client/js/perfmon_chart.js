var chart_fmt = {
	margin: 20,
	color_bkg: '#f4f4f4',
	color_primeline: '#007e7e',
	color_danger: '#d43f3a',
	color_helperline: '#d27c00',
	is_showZeroLine: false,
	is_statAsArea: true,	// shows stat line as area, otherwise as dashed line
	precision: 4,
	formatFullTime: d3.timeFormat("%a %b %d, %Y @ %H:%M"),
	formatDate: d3.timeFormat("%a %b %d, %Y"),
	formatTime: d3.timeFormat("%H:%M")
};

function getChart(dest_id, chart_title) {
	if (viewModel) {
		var server_id = viewModel.selectedServer().id,
			set_id = viewModel.selectedMetricSet().id,
			metric_id = viewModel.selectedMetric().id,
			sd = $('#dateStart').val(),
			ed = $('#dateEnd').val();
		drawchart(server_id, set_id, metric_id, sd, ed, dest_id, chart_title);
	}
	else {
		alert('ERROR: Cannot get selected values from a page - viewModel is required (KnockOut observable).');
	}
	return true;
}

function drawchart(server_id, set_id, metric_id, start_date, end_date, dest_id, chart_title=''){
	$('#' + dest_id).html('<p class="m-t text-center">...working...<br><img src="./img/ajax-loader.gif" alt="...working..." /></p>');
	var url = "";
	var is_raw = (start_date == end_date);
	if (server_id == 0 && set_id == 0 && metric_id == 0) {
		url = "/data/metricvalues" + (is_raw ? ".raw" : "det") + ".json";
		chart_title += ' (test mode)';
	}
	else {
		url = baseURL + "/metricvalues";
		url += (is_raw) ? "/raw/" : "/det/";
		url += server_id + "/" + set_id + "/" + metric_id;
		url += "?sd=" + start_date + "&ed=" + end_date;
	}

	var chartdata = null;
	$.getJSON(url, function(data){
			chartdata = data.results;
			if (chartdata.length == 0) {
				alert("There is no data available for the selected set of filters.");
				$('#' + dest_id).html('<p class="m-t text-danger"><b>WARNING:</b> There is no Metric Values available.</p>');
			}
		})
		.done(function() {
			if (chartdata.length > 0) {
				$('#' + dest_id).html('');
				if (is_raw) {
					drawchart_mv(dest_id, chartdata, chart_title);
				}
				else {
					drawchart_mvdet(dest_id, chartdata, chart_title);
				}
			}
		})
		.fail(function(error){
			$('#' + dest_id).html('<p class="m-t text-danger"><b>ERROR:</b> Metric Values cannot be loaded at this time.</p>');
		});
	return true;
}

function get_datastats_mv(data){
	// return basic stats
	if (!data) {
		return {
			'min' : 0,
			'max' : 0,
			'minDate' : NaN,
			'maxDate' : NaN,
			'count': 0
		};
	}
	else {
		var minValue = d3.min(data, function(el){return +el.value;}),
			maxValue = d3.max(data, function(el){return +el.value;});
		var minSValue = d3.min(data, function(el){return +el.statvalue_lo;}),
			maxSValue = d3.max(data, function(el){return +el.statvalue_hi;});
		var minDate = d3.min(data, function(el){return new Date(el.date + ' ' + el.time);}),
			maxDate = d3.max(data, function(el){return new Date(el.date + ' ' + el.time);});
		return {
			'min' : Math.min(minValue, minSValue),
			'max' : Math.max(maxValue, maxSValue),
			'minDate' : minDate,
			'maxDate' : maxDate,
			'count': data.length
		};
	}
}

function get_datastats_mvdet(data){
	// return basic stats
	if (!data) {
		return {
			'min' : 0,
			'max' : 0,
			'minDate' : NaN,
			'maxDate' : NaN,
			'count': 0,
			'timeInterval': 0
		};
	}
	else {
		var minValue = d3.min(data, function(el){return +el.value_lo;}),
			maxValue = d3.max(data, function(el){return +el.value_hi;});
		var minSValue = d3.min(data, function(el){return +el.statvalue_lo;}),
			maxSValue = d3.max(data, function(el){return +el.statvalue_hi;});
		var minDate = d3.min(data, function(el){return new Date(el.date + ' ' + el.time_start);}),
			maxDate = d3.max(data, function(el){return new Date(el.date + ' ' + el.time_start);});
		var timeInterval = d3.max(data, function(el){
			return (new Date(el.date + ' ' + el.time_end)) - (new Date(el.date + ' ' + el.time_start));
		});
		timeInterval = Math.floor(timeInterval / 3600000);	// in hours
		return {
			'min' : Math.min(minValue, minSValue),
			'max' : Math.max(maxValue, maxSValue),
			'minDate' : minDate,
			'maxDate' : maxDate,
			'count': data.length,
			'timeInterval': timeInterval
		};
	}
}

function drawchart_init(dest_id, title) {
	// initializes chart with some basic functionality 
	// returns svg object if success, otherwise null
	var dest = d3.select('#' + dest_id);
	if (dest.empty())
		return null;

	dest.html(''); // clean it first for resize (re-draw) events
	title = dest.append('center').append('h4').html(title);
	
	var svg = dest.append('center').append('svg');
	
	var width = dest.attr('width') ? dest.attr('width') : window.innerWidth - 2*chart_fmt.margin;
	var height = window.innerHeight - 2*chart_fmt.margin;
	if (width < height) {
		height = width * 1.618033;;
	}
	else {
		height *= .75;
		width = height * 1.618033;
	}
	//alert(width + ' x ' + height);

	svg.style('background-color', chart_fmt.color_bkg)
		.attr('height', height)
		.attr('width', width)
		.append('g')
		.attr('transform', `translate(${chart_fmt.margin},${chart_fmt.margin})`);

	// horizontal line helper
	svg.on('click', function() {
		d3.selectAll('line.helperline').remove();
		var xy = d3.mouse(this);
		svg.append('line')
			.attr('class', 'helperline')
			.attr('x1', chart_fmt.margin)
			.attr('y1', xy[1])
			.attr('x2', width-chart_fmt.margin)
			.attr('y2', xy[1])
			.attr('stroke', chart_fmt.color_helperline)
			.attr('stroke-width', 1);
	});

	return svg;
}

function drawchart_mv(dest_id, data, title) {
	// draws a simple chart for metric values
	var svg = drawchart_init(dest_id, title);
	if (!svg)
		return false;	// could not init chart.
	var width = svg.attr('width');
	var height = svg.attr('height');

	var stat = get_datastats_mv(data);
	if (stat.min == 0 && stat.max == 0) {
		stat.min = -.05;
		stat.max = .05;
	}
	var pad = (stat.max - stat.min)*.1;
	pad = stat.max != 0 ? Math.abs(pad/stat.max) : (stat.min != 0 ? Math.abs(pad/stat.min) : .05);
	
	var xScale = d3.scaleTime()
		.domain([stat.minDate, stat.maxDate])
		.range([chart_fmt.margin, width - chart_fmt.margin]);
	var yScale = d3.scaleLinear()
		.domain([stat.min == 0 ? -stat.max*pad : stat.min*(1-pad), stat.max*(1+pad)])
		.range([height - chart_fmt.margin, chart_fmt.margin]);

	// gridlines
	function make_x_gridlines() {		
		return d3.axisBottom(xScale).ticks();
	}
	function make_y_gridlines() {		
		return d3.axisLeft(yScale).ticks();
	}
	svg.append("g")
		.attr("class", "grid")
		.style('shape-rendering', 'crispEdges')
		.style('stroke-opacity', 0.2)
		.style('stroke-dasharray', ('2, 2'))
		.attr('transform', `translate(0,${height-chart_fmt.margin})`)
		.call(make_x_gridlines().tickFormat('').tickSize(-height+2*chart_fmt.margin));
	svg.append("g")			
		.style('shape-rendering', 'crispEdges')
		.style('stroke-opacity', 0.2)
		.style('stroke-dasharray', ('2, 2'))
		.attr("transform", `translate(${chart_fmt.margin},0)`)
		.call(make_y_gridlines().tickFormat('').tickSize(-width+2*chart_fmt.margin));

	// axises
	svg.append("g")
		.attr("class", "x axis")
		.attr('transform', `translate(0,${height-chart_fmt.margin})`)
		.call(d3.axisBottom(xScale)
			.tickFormat(d3.timeFormat("%H:%M"))	// "%Y-%m-%d"
			)
	;
	svg.append("g")
		.attr("class", "y axis")
		.attr("transform", `translate(${chart_fmt.margin},0)`)
		.call(d3.axisRight(yScale))
	;

	// stat data - must be behind main line
	if (chart_fmt.is_statAsArea) {
		var area = d3.area()
			.curve(d3.curveMonotoneX)
			.x(function(el) { return xScale(new Date(el.date + ' ' + el.time)); })
			.y0(function(el) { return yScale(el.statvalue_lo); })
			.y1(function(el) { return yScale(el.statvalue_hi); });

		svg.append('path')
			.datum(data)
			.attr('d', area)
			.style('stroke', chart_fmt.color_danger)
			.style('stroke-width', 1)
			.style('stroke-opacity', 0.4)
			.style('fill', chart_fmt.color_danger)
			.style('fill-opacity', 0.1)
		;
	}
	else {
		var statline_min = d3.line()
			.x(function(el) { return xScale(new Date(el.date + ' ' + el.time)); })
			.y(function(el) { 
				return yScale(el.statvalue_lo);
			})
			.curve(d3.curveMonotoneX);	// smoothing line
		var statline_max = d3.line()
			.x(function(el) { return xScale(new Date(el.date + ' ' + el.time)); })
			.y(function(el) { 
				return yScale(el.statvalue_hi);
			})
			.curve(d3.curveMonotoneX);	// smoothing line
		svg.append('path')
			.datum(data)
			.attr("d", statline_min)
			.style('stroke', chart_fmt.color_danger)
			.style('stroke-width', 1)
			.style('stroke-dasharray', ('3, 3'))
			.style('fill', 'none')
		;
		svg.append('path')
			.datum(data)
			.attr("d", statline_max)
			.style('stroke', chart_fmt.color_danger)
			.style('stroke-width', 1)
			.style('stroke-dasharray', ('3, 3'))
			.style('fill', 'none')
		;
	}

	// data
	var line = d3.line()
		.x(function(el) { return xScale(new Date(el.date + ' ' + el.time)); })
		.y(function(el) { return yScale(el.value); })
		.curve(d3.curveMonotoneX);	// smoothing line

	svg.append('path')
		.datum(data)
		.attr("d", line)
		.style('stroke', chart_fmt.color_primeline)
		.style('stroke-width', 1)
		.style('fill', 'none')
	;
	
	// zero line
	if (chart_fmt.is_showZeroLine && (stat.min == 0 || (stat.min < 0 && stat.max > 0))) {
		svg.append('line')
			.attr('class', 'zeroline')
			.attr('x1', chart_fmt.margin)
			.attr('y1', yScale(0))
			.attr('x2', width-chart_fmt.margin)
			.attr('y2', yScale(0))
			.attr('stroke', '#000')
			.attr('stroke-width', 1)
			.attr('stroke-opacity', .8)
			;
	};

	// values helper
	svg.on('mousemove', function() {
		d3.select('text.ttip').remove();
		var xy = d3.mouse(this);
		if (xy[0] < chart_fmt.margin || xy[0] > width - chart_fmt.margin)
			return;
		if (xy[1] < chart_fmt.margin || xy[1] > height - chart_fmt.margin)
			return;
		svg.append('text')
			.attr('x', 2*chart_fmt.margin)
			.attr('y', chart_fmt.margin-4)
			.attr('class', 'ttip muted')
			.html( chart_fmt.formatFullTime(xScale.invert(xy[0])) + ": " + yScale.invert(xy[1]).toFixed(chart_fmt.precision) );
	});
	
	// legend
	var legend = d3.select('#' + dest_id).append('div').attr('class', 'text-small text-info');
	legend.html('<br /><h5>Legend:</h5>' +
		'<ul>' + 
			'<li><b>Solid Line</b> - exact metric values.</li>' +
			'<li><b>Dashed Line</b> - historical min/max values for the same one hour period.</li>' + 
		'</ul>' +
		'<p>' +
			'* - click on a chart to draw horizontal line for easy comparison of values.<br />' +
		'</p>'
	);

	return true;
}

function drawchart_mvdet(dest_id, data, title) {
	// draws a detailed chart with stats for metric values
	var svg = drawchart_init(dest_id, title);
	if (!svg)
		return false;	// could not init chart.
	
	var width = svg.attr('width');
	var height = svg.attr('height');

	var stat = get_datastats_mvdet(data);
	if (stat.min == 0 && stat.max == 0) {
		stat.min = -.05;
		stat.max = .05;
	}
	var pad = (stat.max - stat.min)*.1;
	pad = stat.max != 0 ? Math.abs(pad/stat.max) : (stat.min != 0 ? Math.abs(pad/stat.min) : .05);
	//alert(stat.min + ' - ' + stat.max + '; interval: ' + stat.timeInterval + '; pad:' + pad);
	
	var xScale = d3.scaleTime()
		.domain([stat.minDate, new Date(stat.maxDate).setHours(stat.maxDate.getHours() + stat.timeInterval)])	// expand by timeInterval
		.range([chart_fmt.margin, width - chart_fmt.margin]);
	var yScale = d3.scaleLinear()
		.domain([stat.min == 0 ? -stat.max*pad : stat.min*(1-pad), stat.max*(1+pad)])
		.range([height - chart_fmt.margin, chart_fmt.margin]);

	// gridlines
	function make_x_gridlines() {		
		return d3.axisBottom(xScale).ticks();
	}
	function make_y_gridlines() {		
		return d3.axisLeft(yScale).ticks();
	}
	svg.append("g")
		.attr("class", "grid")
		.style('shape-rendering', 'crispEdges')
		.style('stroke-opacity', 0.2)
		.style('stroke-dasharray', ('2, 2'))
		.attr('transform', `translate(0,${height-chart_fmt.margin})`)
		.call(make_x_gridlines().tickFormat('').tickSize(-height+2*chart_fmt.margin));
	svg.append("g")			
		.style('shape-rendering', 'crispEdges')
		.style('stroke-opacity', 0.2)
		.style('stroke-dasharray', ('2, 2'))
		.attr("transform", `translate(${chart_fmt.margin},0)`)
		.call(make_y_gridlines().tickFormat('').tickSize(-width+2*chart_fmt.margin));

	// axises
	svg.append("g")
		.attr("class", "x axis")
		.attr('transform', `translate(0,${height-chart_fmt.margin})`)
		.call(d3.axisBottom(xScale)
			.tickFormat(d3.timeFormat("%m-%d %H:%M"))	// "%Y-%m-%d"
			)
	;
	svg.append("g")
		.attr("class", "y axis")
		.attr("transform", `translate(${chart_fmt.margin},0)`)
		.call(d3.axisRight(yScale));

	// stat data - must be behind main line
	if (chart_fmt.is_statAsArea) {
		var area = d3.area()
			.curve(d3.curveMonotoneX)
			.x(function(el) { 
				return xScale(new Date(el.date + ' ' + el.time_start).setMinutes(new Date(el.date + ' ' + el.time_start).getMinutes() + stat.timeInterval*60/2));
			})
			.y0(function(el) { return yScale(el.statvalue_lo); })
			.y1(function(el) { return yScale(el.statvalue_hi); });

		svg.append('path')
			.datum(data)
			.attr('d', area)
			.style('stroke', chart_fmt.color_danger)
			.style('stroke-width', 1)
			.style('stroke-opacity', 0.4)
			.style('fill', chart_fmt.color_danger)
			.style('fill-opacity', 0.1)
		;
	}
	else {
		var statline_min = d3.line()
			.x(function(el) { 
				return xScale(new Date(el.date + ' ' + el.time_start).setMinutes(new Date(el.date + ' ' + el.time_start).getMinutes() + stat.timeInterval*60/2));
			})
			.y(function(el) { 
				//return yScale(el.statvalue_lo > el.statvalue_avg-2*el.statvalue_std ? el.statvalue_lo : el.statvalue_avg-2*el.statvalue_std); 
				return yScale(el.statvalue_lo);
			})
			.curve(d3.curveMonotoneX);	// smoothing line
		var statline_max = d3.line()
			.x(function(el) { 
				return xScale(new Date(el.date + ' ' + el.time_start).setMinutes(new Date(el.date + ' ' + el.time_start).getMinutes() + stat.timeInterval*60/2));
				//return xScale(new Date(el.date + ' ' + el.time_start)); 
			})
			.y(function(el) { 
				//return yScale(el.statvalue_hi < el.statvalue_avg+3*el.statvalue_std ? el.statvalue_hi : el.statvalue_avg+3*el.statvalue_std); 
				return yScale(el.statvalue_hi);
			})
			.curve(d3.curveMonotoneX);	// smoothing line
		svg.append('path')
			.datum(data)
			.attr("d", statline_min)
			.style('stroke', chart_fmt.color_danger)
			.style('stroke-width', 1)
			.style('stroke-dasharray', ('3, 3'))
			.style('fill', 'none')
		;
		svg.append('path')
			.datum(data)
			.attr("d", statline_max)
			.style('stroke', chart_fmt.color_danger)
			.style('stroke-width', 1)
			.style('stroke-dasharray', ('3, 3'))
			.style('fill', 'none')
		;
	}
	
	// data
	//var barWidth = Math.floor((width-chart_fmt.margin)/stat.count)-4;
	var barWidth = xScale(new Date(stat.minDate).setHours(stat.minDate.getHours() + stat.timeInterval)) - xScale(new Date(stat.minDate));
	if (barWidth % 2 != 0) {
		barWidth -= 1;
	}
	var line = d3.line()
		.x(function(el) { 
			return xScale(new Date(el.date + ' ' + el.time_start).setMinutes(new Date(el.date + ' ' + el.time_start).getMinutes() + stat.timeInterval*60/2));
			//return xScale(new Date(el.date + ' ' + el.time_start)); 
		})
		.y(function(el) { return yScale(el.value_avg); })
		.curve(d3.curveMonotoneX);	// smoothing line

	svg.append('path')
		.datum(data)
		.attr("d", line)
		.style('stroke', chart_fmt.color_primeline)
		.style('stroke-width', 1)
		.style('fill', 'none')
	;
	svg.selectAll('rect')
		.data(data)
		.enter()
		.append('rect')
		.attr('x', function(el) { return xScale(new Date(el.date + ' ' + el.time_start)); })
		.attr('y', function(el) { return yScale(el.value_hi) })
		.attr('height', function(el) { return Math.abs(yScale(el.value_hi)-yScale(el.value_lo)); })
		.attr('width', barWidth)
		.attr('stroke', function(el) { 
			return el.statratio_descr != "OK" ? chart_fmt.color_danger : chart_fmt.color_primeline; }
		)
		.style('stroke-opacity', 0.7)
		.attr('fill', function(el) { 
			return el.statratio_descr != "OK" ? chart_fmt.color_danger : chart_fmt.color_primeline; }
		)
		.style('fill-opacity', 0.6)
		.on('mouseover', function(el) {		
			d3.select(this).style('fill-opacity', 1);
			d3.select('text.ttip').remove();
			svg.append('text')
				.attr('x', 2*chart_fmt.margin)
				.attr('y', chart_fmt.margin-4)
				.attr('class', 'ttip muted')
				.html('Date: ' + chart_fmt.formatDate(new Date(el.date + ' 00:00:00')) + 
					'; time: ' + chart_fmt.formatTime(new Date(el.date + ' ' + el.time_start)) + 
						' - ' + chart_fmt.formatTime(new Date(el.date + ' ' + el.time_end)) +
					'; value: ' + el.value_lo.toFixed(chart_fmt.precision).toString() + 
						' - ' + el.value_hi.toFixed(chart_fmt.precision).toString() +
						', avg: ' + el.value_avg.toFixed(chart_fmt.precision).toString() +
					'; stat ratio: ' + el.statratio + 
					'; status: ' + el.statratio_descr)		
			;
		})					
		.on('mouseout', function(el) {
			d3.select(this).style('fill-opacity', .6);
			d3.select('text.ttip').remove();
		})
	;
	
	// zero line
	if (chart_fmt.is_showZeroLine && (stat.min == 0 || (stat.min < 0 && stat.max > 0))) {
		svg.append('line')
			.attr('class', 'zeroline')
			.attr('x1', chart_fmt.margin)
			.attr('y1', yScale(0))
			.attr('x2', width-chart_fmt.margin)
			.attr('y2', yScale(0))
			.attr('stroke', '#000')
			.attr('stroke-width', 1)
			.attr('stroke-opacity', .8)
			;
	};

	// legend
	var legend = d3.select('#' + dest_id).append('div').attr('class', 'text-small text-info');
	legend.html('<br /><h5>Legend:</h5>' +
		'<ul>' + 
			'<li><b>Box</b> - represents aggregation time period with min and max values as its lower and higher bars.</li>' +
			'<li><b>Solid Line</b> - average values for the period.</li>' +
			'<li><b>Dashed Line</b> - historical min/max values for the same period.</li>' + 
		'</ul>' +
		'<p>' +
			'* - click on a chart to draw horizontal line for easy comparison of values.<br />' +
			'* - hover over box to show period details.' +
		'</p>'
	);
	
	return true;
}
