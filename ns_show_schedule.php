
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" 
"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">

<html>

<head>

<?php

// User login and session info stuff

// If the user is logged in we should display their username in the title bar

$username = $_SERVER[PHP_AUTH_USER];

if ($username) {
	echo "<title>The Schedule ($username)</title>";
} else {
	echo "<title>The Schedule</title>";
};

?>

<link rel="stylesheet" type="text/css" href="ns_general.css" media="screen" />

</head>


<body>

<?php

if ($username) {

	// do stuff for the currently logged in user
	printf("Logged in as %s. <br /> <br />", $username);

	require('ns_common.php');
	
	generate_calendar_table($username);

} else {

	// login failure
	echo "Fail.<br />";

};

function generate_calendar_table( $gct_username ) {

	$today =  date_create();
	$first_of_month = date_create(date_format($today,'Y-m-') . "1");
	$last_of_month = date_create(date_format($today,'Y-m-t'));

	start_db();
	$gct_cat_id = get_cat_id($gct_username);
	$gct_shifts = get_shifts($gct_cat_id[0]);
	
	write_table_header();
	
	echo "<tr valign=\"top\">";
	for ($cell = 1; $cell <= 42; $cell++) {	

		/* 
		Write blank cells until we reach the cell corresponding to 
		the first of the month. Then write out dated cells and fill
		them up with whatever until we reach the end of the month. Once
		all of the numbered cells corresponding to days of the month
		have been written out write out blank cells to complete the
		calendar.
		*/
		
		if (date_format($first_of_month, 'N') == $cell) {
			
			for($current_date = $first_of_month;
			date_diff(date_format($current_date,'Y-m-d'),date_format($last_of_month,'Y-m-d')) > 0;
			date_modify($current_date,'+1 day')) { 
			
				write_dated_cell($current_date,$gct_shifts); 
				
				if ($cell % 7 == 0 && $cell < 42) {
					echo "</tr>\n<tr valign=\"top\">";
				};

				$cell++;
			};
			
		};			
		
		write_blank_cell();
		
		// Start a new row every seven cells.
		if ($cell % 7 == 0 && $cell < 42) {
			echo "</tr>\n<tr valign=\"top\">";
		};
	}; 
	echo "</tr>";

	write_table_footer();
	echo "Shift key: <br />";
	echo "<span class=\"shift_dh\">DOGHaus</span><br />";
	echo "<span class=\"shift_kn\">Kennel</span><br />";
};


function write_dated_cell(&$current_date,&$gct_shifts) {

	/*
	Writes out the date in the top left of the cell
	*/
	echo "<td width=\"120\" height=\"100\">";
	echo "<div align=\"left\"><span class=\"cell_label\">";
	echo date_format($current_date, 'j');
	echo "</div></span>";

	/*
	Writes out shift start and end times
	*/
	foreach ($gct_shifts as $shift) {
		if ($shift['ns_shift_date'] == date_format($current_date,'Y-m-d')) {
			if ($shift['ns_desk_shortname'] == "Kennel") {
				echo "<div align=\"center\"><span class=\"shift_kn\">";
				echo $shift['ns_shift_start_time'] . " - " . $shift['ns_shift_end_time'];
				echo "</span></div>";
			} elseif ($shift['ns_desk_shortname'] == "DOGHaus") {
				echo "<div align=\"center\"><span class=\"shift_dh\">";
				echo $shift['ns_shift_start_time'] . " - " . $shift['ns_shift_end_time'];
				echo "</span></div>";
			};
		};
	};
		
	echo "</td>";

};


function write_blank_cell() {
	
	echo "
	<td width=\"120\" height=\"100\">
	</td>";

};


function write_table_header() {
	echo "
		<table border=\"1\" cellpadding=\"1\" cellspacing=\"1\">
		<tr>
			<th>Sunday</th>
			<th>Monday</th>
			<th>Tuesday</th>
			<th>Wednesday</th>
			<th>Thursday</th>
			<th>Friday</th>
			<th>Saturday</th>
		</tr>";
};


function write_table_footer() {
	echo "</table>";
};

?>

</body>
</html>
