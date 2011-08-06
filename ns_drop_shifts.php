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
if ($username) {
	// do stuff for the currently logged in user
	printf("Logged in as %s. <br />", $username);
	
	if ($_POST['operation'] == "Abort") {
		// If the user clicked the abort button on the page after landing here
		// don't do anything except clear the SESSION parameter of ids to drop
		// and display a link to take them back to the schedule view.
		echo "OHSHI... Cancelling that.<br />";
		echo "<a href=\"ns_show_schedule.php\">Back to your schedule</a><br />";
		session_unset($_SESSION['drop_shifts']);
	} elseif (is_array($_SESSION['drop_shifts']) && empty($_POST['operation'])) {
		// If the user just landed here for the first time give them
		// the choice of proceeding with or aborting dropping of the
		// shifts they selected on the schedule monthly view.

		echo "Are you sure you wish to drop the following shifts?<br />";

		start_db();

		foreach ($_SESSION['drop_shifts'] as $key => $val) {
			$drop_shifts_ids[] = $key;
		};

		generate_shifts_table($drop_shifts_ids);

		echo "<form action=\"ns_drop_shifts.php\" method=\"post\">";
		echo "<input type=\"submit\" name=\"operation\" value=\"Abort\">";
		echo "<input type=\"submit\" name=\"operation\" value=\"Proceed\">";
		echo "</form>";
	} elseif (is_array($_SESSION['drop_shifts']) && $_POST['operation'] == "Proceed") {
		// If the user has confirmed dropping the shifts then proceed
		// and display a confirmation and link back to the calendar
		// view.

		start_db();

		foreach ($_SESSION['drop_shifts'] as $key => $val) {
			$drop_shifts_ids[] = $key;
		};

		generate_shifts_table($drop_shifts_ids);

		echo "Shifts dropped. <br />";
		echo "<a href=\"ns_show_schedule.php\">Back to your schedule</a><br />";
		session_unset($_SESSION['drop_shifts']);
	} elseif (!$_SESSION['drop_shifts']) {
		// If no shift assignment ids were passed along don't do
		// anything.
	
		echo "No shifts selected to drop.<br />";
		echo "<a href=\"ns_show_schedule.php\">Back to your schedule</a><br />";
	} else {
		// Shouldn't ever really get here.
	
		echo "Something went wrong. Contact the scheduler. <br />";
	};
	
} else {
	// login failure
	echo "Fail.<br />";
};
?>

</body>
</html>

<?php
function drop_shifts_by_sa_ids ( &$drop_shifts ) {
	/*
	For each id in the array passed to the function, do the following:
	-Remove sa_ids which already have an ns_shift_dropped entry from the
	 list of sa_ids to drop. 
	-Add a new entry to ns_shift_dropped for the shift assignment.
	-Use the current date/time as the ns_sd_droptime.
	*/ 	

	// Run function to discard from the array shift assignment ids which
	// have already been dropped. 
	$drop_shifts = discard_dropped_sa_ids($drop_shifts);

	// Insert new ns_shift_dropped entries for each of the remaining sa_ids.
	foreach ($drop_shifts as $shift) {
		echo $shift . "<br />";
	};

};


function discard_dropped_sa_ids($sa_ids) {
	/*
	Fetch any ns_shift_dropped entries which match the provided sa_ids and
	remove the matching sa_ids from the provided array.
	*/

	$sa_id_list .= implode(",",$sa_ids);

	/*
	Set up and run query for grabbing the sa_ids from the provided list
	which have an associated shift drop entry.
	*/ 

	$db_query = "
		SELECT d.ns_sa_id
		FROM ns_shift_dropped as d
		WHERE d.ns_sa_id IN ($sa_id_list)";
	
	$db_result = mysql_query($db_query);

	// If we got no matches break here.
	if (empty($db_result)) {
		echo "Empty result set. <br />";
		return $sa_ids;
	}; 

	// Iterate through the results and remove from the sa_ids list any ids
	// matching the ones retrieved from the database.
	while ($db_row = mysql_fetch_array($db_result)) {
		foreach ($sa_ids as $key => $value) {
			if ($value = $db_row[0]) {
				unset($sa_ids[$key]);
			};
		};
	};

	// Reset array indexes since they'll be messed up if we removed any
	// elements from the middle.
	$sa_ids = array_values($sa_ids);

	echo "Got some results. <br />";
	return $sa_ids;
};


function generate_shifts_table( $drop_shifts ) {
	
	// Get shifts
	$shifts = get_shifts_from_sa_ids($drop_shifts);

	// See if we even have any records to display, if so write them out.
	if ($shifts) {
		write_table_header();
		foreach ($shifts as $shift) {
			write_shift_cell(array_slice($shift,1,4));
		};
		write_table_footer();
	} else {
		// No records
		echo "No shifts to display. <br />";
	};
};


function write_shift_cell( $ws_shift ) {
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
?>

