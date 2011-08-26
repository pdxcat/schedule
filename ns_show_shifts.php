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
	
	$dbh = start_db();

	generate_shifts_table($username, $dbh);

	$dbh = null;

} else {
	// login failure
	echo "Fail.<br />";
};

?>

</body>
</html>

<?php 
function generate_shifts_table( $gst_username, &$dbh ) {
	
	// Fetch the cat_id for the logged in user. If we get more than one ID
	// back something is terribly wrong in the DB.
	$cat_id = get_cat_id($gst_username, $dbh);
	if (count($cat_id) > 1) {
		die ("Username is associated with more than one ID. Please ping the scheduler.");
	} elseif (!$cat_id) {
		die ("Username has no ID associated with it in the schedule database.");
	} else {
	};

	// Get shifts
	$shifts = get_shifts($cat_id[0], $dbh);

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

