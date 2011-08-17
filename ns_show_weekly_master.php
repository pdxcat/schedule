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

<div id="page-container">

<div id="top-nav">
<?php
include 'ns_top_navigation.php';
?>
</div>

<div id="content">
<?php

if ($username) {
	printf("Logged in as %s. <br />", $username);
	echo "<br />";
	
	// Determine the date to display based on POST operation and SESSION
	// parameters.
	if ($_POST['operation'] == "Current Week") {
		// If current week button was clicked initialize base date with
		// the current date.
		$base_date = date_create();

	} elseif ($_POST['operation'] == "Next Week") {
		// If the next week button was clicked initialize base date
		// with the last viewed date + 1 week.
		$base_date = date_create($_SESSION['last_viewed_date']);
		date_modify($base_date, '+1 week');

	} elseif ($_POST['operation'] == "Previous Week") {
		// If the previous week button was clicked initialize base date
		// with the last viewed date - 1 week.
		$base_date = date_create($_SESSION['last_viewed_date']);
		date_modify($base_date, '-1 week');
	
	} else {
		// Default to current date.
		$base_date = date_create();
	};

	// Once we've figured out the date to display based on, update the last
	// viewed date in SESSION parameters.
	$_SESSION['last_viewed_date'] = date_format($base_date, 'Y-m-d');
	
	generate_weekly_table($username, $base_date);

} else {
	// login failure
	echo "Fail.<br />";
};

?>

</div>
</div>
</body>
</html>

<?php

// Table generation functions
function generate_weekly_table($username, $base_date) {
	// Determine first and last days of the week.
	$first_of_week = clone($base_date);
	if (date_format($first_of_week, 'w') > 1) {
		// If the base date is after Monday, roll back $first_of_week until we
		// hit Monday.
		while (date_format($first_of_week, 'w') != 1) {
			date_modify($first_of_week, '-1 day');
		};
	} elseif (date_format($first_of_week, 'w') == 0) {
		// If the base date is Sunday, add 1 day to it to get Monday.
		date_modify($first_of_week, '+1 day');
	};

	$last_of_week = clone($first_of_week);
	date_modify($last_of_week, '+5 days');

	// Fetch all active shift assignments and shift info between those dates.

	// Generate schedule table from that info.
	echo "<span class=\"master-schedule-table\">";
	write_table_header();

	// Loop over each hour in the work day
	for ($hour = 8; $hour <= 18; $hour++) {
		// Loop over each day of the week being viewed
		for ($current_date = clone($first_of_week);
		date_diff(date_format($current_date,'Y-m-d'),date_format($last_of_week,'Y-m-d')) >= 0 ;
		date_modify($current_date,'+1 day')) {
			// If day is Monday, begin a new row and write out the hour
			// label.
			if (date_format($current_date,'w') == 1) {
				echo "<tr>";
				echo "<td>";
				echo $hour;
				echo "</td>";
			};
	
			write_table_cell($current_date);

			// If day is Saturday, cap off the row after writing out the
			// cell contents.
			if (date_format($current_date,'w') == 6) {
				echo "</tr>";
			};
			
			// Hackish shit necessary due to the hackishness of the
			// date_diff function I'm using as a stand in for the
			// real thing since we're running ancient ass PHP.
			if (date_diff(date_format($current_date,'Y-m-d'),
			date_format($last_of_week,'Y-m-d')) == 0) {
				break;
			};
		};
	};

	write_table_footer();

	echo "</span>";
};


function write_table_header() {
	echo "<table>";
	echo "<tr>";
	echo "<th></th>";
	echo "<th>Monday</th>";
	echo "<th>Tuesday</th>";
	echo "<th>Wednesday</th>";
	echo "<th>Thursday</th>";
	echo "<th>Friday</th>";
	echo "<th>Saturday</th>";
	echo "</tr>";
};


function write_table_cell($date) {
	echo "<td>";
	echo date_format($date, 'Y-m-d');
	echo "</td>";
};


function write_table_footer() {
	echo "</table>";
	echo "<br />";
	echo "Shift key: <br />";
	echo "<span class=\"shift_dh\">DOGHaus</span><br />";
	echo "<span class=\"shift_kn\">Kennel</span><br />";

};
// End of table generation functions
?>
