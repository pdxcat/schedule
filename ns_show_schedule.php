<?php
require('ns_common.php');
check_session(); 
?>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" 
"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">

<html>

<head>

<?php
$username = $_SESSION['username'];
echo "<title>The Schedule ($username)</title>";
?>

<link rel="stylesheet" type="text/css" href="master.css" media="screen" />
<link rel="stylesheet" type="text/css" href="ns_general.css" media="screen" />

</head>


<body>

<?php

/* 
To do:
-Add support for saving which boxes were checked between different months being
 viewed. 
*/

if ($username) {
	// do stuff for the currently logged in user
	printf("Logged in as %s. <br /> <br />", $username);

	generate_calendar_table($username);
} else {
	// login failure
	echo "Fail.<br />";
};

echo "</body>";
echo "</html>";


function generate_calendar_table( $gct_username ) {

	/*
	If the user has been viewing the calendar in the current session, but
	has left the calendar page at some point, we want to take them back to
	their last viewed month. This is set in the last_viewed_date variable
	in the session data. 

	However, if they are browsing around the calendar and have a different
	date set in the GET parameters in the URL, we should use that instead.
	Additionally, the last_viewed_date should be updated to match the date
	in the GET parameters in this case, or set if it is not yet. 

	Finally, if we have no GET or SESSION parameter, we should default to
	displaying the current month.
	*/


	if (!empty($_GET['date'])) {
		// If we have a date in the GET parameters, we should use it.
		// Also, create/update the last_viewed_date SESSION parameter
		// as appropriate.
	
		$base_date = date_create($_GET['date']);
		$_SESSION['last_viewed_date'] = date_format($base_date, 'Y-m-d');

	} elseif (!empty($_SESSION['last_viewed_date']) && empty($_GET['date'])) {
		// If there's no date in the GET parameters, but there is a 
		// last_viewed_date in the SESSION data, use that.
		
		$base_date = date_create($_SESSION['last_viewed_date']);

	} else {
		// If neither of the above conditions are true, default to the
		// current date and set up the SESSION and GET parameters.
		$base_date =  date_create();
	};


	$first_of_month = date_create(date_format($base_date,'Y-m-01'));
	$last_of_month = date_create(date_format($base_date,'Y-m-t'));

	start_db();
	$gct_cat_id = get_cat_id($gct_username);
	$gct_shifts = get_shifts($gct_cat_id[0]);
	
	write_table_header($base_date);

	echo "<form action=\"ns_drop_shifts.php\" method=\"post\">";
	
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
		
		if ((date_format($first_of_month, 'w') + 1) == $cell) {
			
			for($current_date = $first_of_month;
			date_diff(date_format($current_date,'Y-m-d'),date_format($last_of_month,'Y-m-d')) > 0;
			date_modify($current_date,'+1 day')) { 
			
				write_dated_cell($current_date,$gct_shifts); 
				
				// Start a new row every seven cells.
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

	write_table_footer($base_date);

	echo "<input type=\"submit\" name=\"submit\" value=\"Drop Selected Shifts\">";
	echo "</form>";
};


function write_dated_cell(&$current_date,&$gct_shifts) {

	/*
	Writes out the date in the top left of the cell
	*/
	echo "<td width=\"120\" height=\"100\">";
	echo "<span align=\"left\" class=\"cell_label\">";
	echo date_format($current_date, 'j');
	echo "</span>";

	/*
	Writes out shift start and end times
	*/
	echo "<div class=\"shifts\">";
	foreach ($gct_shifts as $shift) {
		if ($shift['ns_shift_date'] == date_format($current_date,'Y-m-d')) {
		echo "<input type=\"checkbox\" name=\"drop_shifts[]\" value=\"" . $shift['ns_sa_id'] . "\">";
			if ($shift['ns_desk_shortname'] == "Kennel") {
				echo "<span class=\"shift_kn\">";
				echo $shift['ns_shift_start_time'] . " - " . $shift['ns_shift_end_time'];
				echo "<br />";
				echo "</span>";
			} elseif ($shift['ns_desk_shortname'] == "DOGHaus") {
				echo "<span class=\"shift_dh\">";
				echo $shift['ns_shift_start_time'] . " - " . $shift['ns_shift_end_time'];
				echo "<br />";
				echo "</span>";
			};
		};
	};
	echo "</div>";
	
	echo "</td>";

};


function write_blank_cell() {
	
	echo "
	<td width=\"120\" height=\"100\">
	</td>";

};


function write_table_header( &$base_date ) {

	echo "
	<div class=\"cal_month\">" .
	date_format($base_date,'F Y')
	. "</div><br />";
	
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


function write_table_footer( &$base_date ) {
	echo "</table>";

	$today = date_create();
	$prev_month = clone($base_date);
	date_modify($prev_month, '-1 month');
	$next_month = clone($base_date);
	date_modify($next_month, '+1 month');

	echo "<a href=\"ns_show_schedule.php?date=" . date_format($prev_month, 'Y-m-d') 
		. "\"> Previous Month </a>";
	echo "<a href=\"ns_show_schedule.php?date=" . date_format($today, 'Y-m-d') 
		. "\"> Current Month </a>";
	echo "<a href=\"ns_show_schedule.php?date=" . date_format($next_month, 'Y-m-d') 
		. "\"> Next Month </a>";
	
	echo "<br />";
	echo "Shift key: <br />";
	echo "<span class=\"shift_dh\">DOGHaus</span><br />";
	echo "<span class=\"shift_kn\">Kennel</span><br />";
};

?>

