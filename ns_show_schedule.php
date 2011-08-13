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
 viewed. DONE (8/5/11)
*/

if ($username) {
	// do stuff for the currently logged in user
	printf("Logged in as %s. <br /> <br />", $username);

	start_db();	

	if ($_POST['operation'] == "Drop Selected Shifts") {
		/*
		If the user has clicked the drop shifts button, check if there
		were any shifts selected. If so, display the confirmation 
		stuff. If not, note that no shifts were selected to drop and
		redraw the calendar.
		*/
		
		// Update SESSION data to account for any new shift selections
		// or deselections that were POSTed before we do anything else.
		update_session_shifts();
		
		if (is_array($_SESSION['drop_shifts'])) {
			echo "Are you sure you wish to drop the following shifts?<br />";

			foreach ($_SESSION['drop_shifts'] as $key => $val) {
				$drop_shifts_ids[] = $key;
			};

			generate_shifts_table($drop_shifts_ids);

			echo "<form action=\"ns_show_schedule.php\" method=\"post\">";
			echo "<input type=\"submit\" name=\"operation\" value=\"Abort\">";
			echo "</form>";

			echo "<form action=\"ns_drop_shifts.php\" method=\"post\">";
			echo "<input type=\"submit\" name=\"operation\" value=\"Proceed\">";
			echo "</form>";
		} else {
			echo "No shifts were selected to drop.<br />";

			generate_shifts_calendar($username);
		};
	} elseif ($_POST['operation'] == "Abort") {
		// If the user clicked the abort button in the confirmation
		// dialog then clear the SESSION array of shifts to drop and
		// note what's happened.

		echo "Shift drop cancelled, shift selections have been cleared.<br />";
		session_unset($_SESSION['drop_shifts']);

		generate_shifts_calendar($username);
	} else {
		generate_shifts_calendar($username);
	};

} else {
	// login failure
	echo "Fail.<br />";
};

?>
</body>

</html>

<?php
// Functions to generate a calendar of shifts.
function generate_shifts_calendar( $gct_username ) {
	/*
	If the user has been viewing the calendar in the current session, but
	has left the calendar page at some point, we want to take them back to
	their last viewed month. This is set in the last_viewed_date variable
	in the session data. 

	If they've clicked one of the navigation buttons at the bottom the date
	should be set appropriately based on the button. 

	Additionally, whenever one of the navigation buttons is used the
	shift boxes that were checked when the button was clicked should be
	recorded. This is done with the update_session_shifts() function.
	*/
	
	if ($_POST['operation'] == "Current Month") {
		// If current date button was clicked initialize base date with
		// the current date.
		$base_date = date_create();
	
		update_session_shifts();

	} elseif ($_POST['operation'] == "Next Month") {
		// If next month button was clicked initialize base date with
		// the last viewed date and then tack a month onto it.
		$base_date = date_create($_SESSION['last_viewed_date']);
		date_modify($base_date, '+1 month');

		update_session_shifts();

	} elseif ($_POST['operation'] == "Previous Month") {
		// If previous month button was clicked initialize base date
		// with the last viewed date and then hack a month off it.
		$base_date = date_create($_SESSION['last_viewed_date']);
		date_modify($base_date, '-1 month');

		update_session_shifts();
	} else { 
		// If no submit button was clicked to get here or we otherwise
		// have no previous date to go off of then use the last viewed
		// date if it is set or initialize base date as the current 
		// date if there's nothing else to go off of.
		if (!empty($_SESSION['last_viewed_date'])) {	
			$base_date = date_create($_SESSION['last_viewed_date']);		
		} else {
			$base_date = date_create();
		};
	};

	// Once we're done figuring out the date to use to generate the page
	// update the last viewed date in the SESSION parameters.
	$_SESSION['last_viewed_date'] = date_format($base_date, 'Y-m-d');

	// Come up with the first and last dates of the month by using some
	// gross tricks with the built in date manipulation functions.
	$first_of_month = date_create(date_format($base_date,'Y-m-01'));
	$last_of_month = date_create(date_format($base_date,'Y-m-t'));

	// Fire up a connection to the database, then grab the currently
	// logged in user's id in the schedule database, follow it up by 
	// sucking up all of the assigned shifts for this user. 
	start_db();
	$gct_cat_id = get_cat_id($gct_username);
	$gct_shifts = get_shifts($gct_cat_id[0]);
	
	// Start actually assembling the calendar table into which all of this
	// shift data is outputted.
	write_calendar_header($base_date);

	echo "<form action=\"ns_show_schedule.php\" method=\"post\">";
	
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
			
				write_dated_calendar_cell($current_date,$gct_shifts); 
				
				// Start a new row every seven cells.
				if ($cell % 7 == 0 && $cell < 42) {
					echo "</tr>\n<tr valign=\"top\">";
				};

				$cell++;
			};
			
		};			
		
		write_blank_calendar_cell();
		
		// Start a new row every seven cells.
		if ($cell % 7 == 0 && $cell < 42) {
			echo "</tr>\n<tr valign=\"top\">";
		};
	}; 
	echo "</tr>";

	write_calendar_footer($base_date);

};


function write_dated_calendar_cell(&$current_date,&$gct_shifts) {

	// Writes out the date in the top left of the cell
	echo "<td width=\"120\" height=\"100\">";
	echo "<span align=\"left\" class=\"cell_label\">";
	echo date_format($current_date, 'j');
	echo "</span>";

	// Writes out shift start and end times
	echo "<div class=\"shifts\">";
	foreach ($gct_shifts as $shift) {
		if ($shift['ns_shift_date'] == date_format($current_date,'Y-m-d')) {
			// Use the state of the shift from the SESSION params,
			// if it's been set.
			if ($_SESSION['drop_shifts'][$shift['ns_sa_id']] == 1) {
				// If the parameter for the shift is set and
				// has a value of 1, display a checked box and
				// put in a hidden field to set the value to 
				// 0 so if the box is unchecked that change is
				// registered.
				echo "<input type=\"hidden\" name=\"drop_shifts[" . $shift['ns_sa_id']. "]\"
					value=\"0\">";
				echo "<input type=\"checkbox\" name=\"drop_shifts[" . $shift['ns_sa_id'] . "]\" 
					value=\"1\" checked>";	
			} else {
				echo "<input type=\"checkbox\" name=\"drop_shifts[" . $shift['ns_sa_id'] . "]\" 
					value=\"1\">";
			};
	
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


function write_blank_calendar_cell() {
	echo "
	<td width=\"120\" height=\"100\">
	</td>";
};


function write_calendar_header( &$base_date ) {
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


function write_calendar_footer( &$base_date ) {
	echo "</table>";
	

	echo "<input type=\"submit\" name=\"operation\" value=\"Previous Month\">";
	echo "<input type=\"submit\" name=\"operation\" value=\"Current Month\">";
	echo "<input type=\"submit\" name=\"operation\" value=\"Next Month\">";
	echo "<br />";
	echo "<input type=\"submit\" name=\"operation\" value=\"Drop Selected Shifts\">";
	echo "</form>";
	echo "<br />";
	
	echo "<br />";
	echo "Shift key: <br />";
	echo "<span class=\"shift_dh\">DOGHaus</span><br />";
	echo "<span class=\"shift_kn\">Kennel</span><br />";
};
// End of shift calendar functions.


// Functions used in the generation of a table of shifts.
function generate_shifts_table( $drop_shifts ) {
	
	// Get shifts
	$shifts = get_shifts_from_sa_ids($drop_shifts);

	// See if we even have any records to display, if so write them out.
	if ($shifts) {
		write_table_header();
		foreach ($shifts as $shift) {
			write_table_cell(array_slice($shift,1,4));
		};
		write_table_footer();
	} else {
	
		echo "No shifts to display. <br />";
	};
};


function write_table_cell( $ws_shift ) {
	echo "<tr>\n";
	foreach ($ws_shift as $cell) {
		echo "<td>$cell</td>\n";
	};
	echo "</tr>\n";
};


function write_table_header() {
	echo "
		<table border=\"1\" cellpadding=\"1\" cellspacing=\"1\">\n
		<tr>\n
			<th>Date</th>\n
			<th>Desk</th>\n
			<th>Shift Start</th>\n
			<th>Shift End</th>\n
		</tr>\n";
};


function write_table_footer() {
	echo "</table>";
};
// End of shift table functions.


function update_session_shifts() {
	// If no changes were made then return early.
	if (!isset($_POST['drop_shifts'])) {
		return 1;
	};
	
	foreach ($_POST['drop_shifts'] as $key => $val) {
		if ($val == 1) {
			$_SESSION['drop_shifts'][$key] = $val;
		} else {
			unset($_SESSION['drop_shifts'][$key]);
		};
	}; 
}; 

?>

