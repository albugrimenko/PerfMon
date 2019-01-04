// required: python -m SimpleHTTPServer 8000 &
// file:///home/alex/Documents/source/PerfMon/WebUI/Client/chart.html

var chart_fmt = {
	margin: 20,
	clr_bkg: '#e9ecef',
	clr_grid: '#ced4da',
	clr_primeline: '#ffab00',
	clr_helperline: '#ced4da'
};

function get_data_mv_static(dest_id='', is_drawchart=true, chart_title=''){
	var chartdata = null;
	if (dest_id) {
		$('#' + dest_id).html('<p class="m-t text-center">...working...<br><img src="./img/ajax-loader.gif" alt="...working..." /></p>');
	}
	$.getJSON("/data/metricvalues.raw.json", function(data){
			chartdata = data.results;
			//alert(chartdata.length);
		})
		.done(function() {
			if (dest_id) {
				$('#' + dest_id).html('');
			}
			if (is_drawchart && dest_id) {
				//alert(chartdata.length);
				drawchart_mv(dest_id, chartdata, chart_title);
			}
		})
		.fail(function(error){
			if (dest_id) {
				$('#' + dest_id).html('<p class="m-t text-danger"><b>ERROR:</b> Metric Values cannot be loaded at this time.</p>');
			}
			else {
				alert('ERROR: Metric Values cannot be loaded at this time.');
			}
		})
		;
	return chartdata;
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
		var minDate = d3.min(data, function(el){return new Date(el.date + ' ' + el.time);}),
			maxDate = d3.max(data, function(el){return new Date(el.date + ' ' + el.time);});
		return {
			'min' : minValue,
			'max' : maxValue,
			'minDate' : minDate,
			'maxDate' : maxDate,
			'count': data.length
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

	svg.style('background-color', chart_fmt.clr_bkg)
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
			.attr('stroke', chart_fmt.clr_helperline)
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
	
	var xScale = d3.scaleTime()
		.domain([stat.minDate, stat.maxDate])
		.range([chart_fmt.margin, width - chart_fmt.margin]);
	var yScale = d3.scaleLinear()
		.domain([stat.min, stat.max])
		.range([height - chart_fmt.margin, chart_fmt.margin]);

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
		.call(d3.axisLeft(yScale));
	
	// data
	var line = d3.line()
		.x(function(el) { return xScale(new Date(el.date + ' ' + el.time)); })
		.y(function(el) { return yScale(el.value); })
		.curve(d3.curveMonotoneX);	// smoothing line

	svg.append('path')
		.datum(data)
		.attr("d", line)
		.style('stroke', chart_fmt.clr_primeline)
		.style('stroke-width', 1)
		.style('fill', 'none')
	;

	// values helper
	var formatFullTime = d3.timeFormat("%a %b %d, %Y @ %H:%M");
	svg.on('mousemove', function() {
		d3.select('text.ttip').remove();
		var xy = d3.mouse(this);
		if (xy[0] < chart_fmt.margin || xy[0] > width - chart_fmt.margin)
			return;
		if (xy[1] < chart_fmt.margin || xy[1] > height - chart_fmt.margin)
			return;
		svg.append('text')
			.attr('x', 2*chart_fmt.margin)
			.attr('y', chart_fmt.margin)
			.attr('class', 'ttip muted')
			.html( formatFullTime(xScale.invert(xy[0])) + ": " + yScale.invert(xy[1]).toFixed(4) );
	});

	return true;
}
