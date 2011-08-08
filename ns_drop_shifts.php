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
	

	if (empty($_POST['operation'])) {
		// The user really shouldn't get to this page without having
		// clicked a button on the view/drop shifts page.

		echo "No operation to perform. <br />";
		echo "<a href=\"ns_show_schedule.php\">Return to your schedule</a><br />";
		
	} elseif (is_array($_SESSION['drop_shifts']) && $_POST['operation'] == "Proceed") {
		// If the user has confirmed dropping the shifts then proceed
		// and display a confirmation and link back to the calendar
		// view.

		start_db();

		foreach ($_SESSION['drop_shifts'] as $key => $val) {
			$drop_shifts_ids[] = $key;
		};

		drop_shifts_by_sa_ids($drop_shifts_ids);

		echo "Shifts dropped. <br />";
		echo "<a href=\"ns_show_schedule.php\">Back to your schedule</a><br />";
		session_unset($_SESSION['drop_shifts']);

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
		return $sa_ids;
	}; 

	// Iterate through the results and remove from the sa_ids list any ids
	// matching the ones retrieved from the database.
	while ($db_row = mysql_fetch_array($db_result)) {
		foreach ($sa_ids as $key => $val) {
			if ($val == $db_row[0]) {
				unset($sa_ids[$key]);
			};
		};
	};

	// Reset array indexes since they'll be messed up if we removed any
	// elements from the middle.
	$sa_ids = array_values($sa_ids);

	return $sa_ids;
};


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
		$now = date_create();
		$timestamp = date_format($now,"Y-m-d H:i:s");
		
		$db_query = "
			INSERT INTO `ns_shift_dropped` (ns_sa_id,ns_sd_droptime)
			VALUES ($shift,'$timestamp')";

		mysql_query($db_query);
	};
};
?>

