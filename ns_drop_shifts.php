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
	
	// If a list of shift assignment ids to drop was submitted to the form
	// dump them into a SESSION parameter for use later
	if (!empty($_POST['drop_shifts'])) {
		$_SESSION['drop_shifts'] = $_POST['drop_shifts'];
	};
	
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

		generate_shifts_table($_SESSION['drop_shifts']);

		echo "<form action=\"ns_drop_shifts.php\" method=\"post\">";
		echo "<input type=\"submit\" name=\"operation\" value=\"Abort\">";
		echo "<input type=\"submit\" name=\"operation\" value=\"Proceed\">";
		echo "</form>";
	} elseif (is_array($_SESSION['drop_shifts']) && $_POST['operation'] == "Proceed") {
		// If the user has confirmed dropping the shifts then proceed
		// and display a confirmation and link back to the calendar
		// view.

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

echo "</body>";
echo "</html>";

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

