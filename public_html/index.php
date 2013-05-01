<?php
# Licensed to the Computer Action Team (CAT) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The CAT licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

  require('ns_common.php');
  check_session();

  include('header.php');

if ($username) {
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

	$dbh = start_db();

	generate_weekly_table($username, $base_date, $dbh);

	$dbh = null;

} else {
	// login failure
	echo "<p>Fail.</p>";
};

?>

</div>
</div>
</body>
</html>

<?php

// Table generation functions
function generate_weekly_table($username, $base_date, &$dbh) {
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
	$gwt_shifts = get_shifts_for_all($first_of_week,$last_of_week,$dbh);

	// Generate schedule table from that info.
	echo "<p>Schedule for " . date_format($first_of_week,'Y-m-d') . " to " . date_format($last_of_week,'Y-m-d') . "</p>\n";
	write_table_header();

	// Loop over each hour in the work day
	for ($hour = 8; $hour <= 17; $hour++) {
		// Loop over each day of the week being viewed
		for ($current_date = clone($first_of_week);
		date_diff(date_format($current_date,'Y-m-d'),date_format($last_of_week,'Y-m-d')) >= 0 ;
		date_modify($current_date,'+1 day')) {
			// If day is Monday, begin a new row and write out the hour
			// label.
			if (date_format($current_date,'w') == 1) {
				echo "<tr>";
				echo "<td>";
				echo sprintf("%02d", $hour) . "00";
				echo "</td>";
			};

			write_table_cell($current_date, $hour, $gwt_shifts);

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

	write_table_footer($dbh);
};


function write_table_header() {
	echo "<table class=\"shift_weekly\">";
	echo "<tr>";
	echo "<th class=\"hour_label\"></th>";
	echo "<th class=\"day_label\">Monday</th>";
	echo "<th class=\"day_label\">Tuesday</th>";
	echo "<th class=\"day_label\">Wednesday</th>";
	echo "<th class=\"day_label\">Thursday</th>";
	echo "<th class=\"day_label\">Friday</th>";
	echo "<th class=\"day_label\">Saturday</th>";
	echo "</tr>";
};


function write_table_cell(&$date, &$hour, &$gwt_shifts) {
	$db_date = date_format($date, 'Y-m-d');
	$start_time = sprintf('%02d',$hour) . ":00:00";
	echo "<td>";
	foreach ($gwt_shifts as $date_key => $date_val) {
		if ($date_key == $db_date) {
			foreach ($date_val as $time_key => $time_val) {
				if ($time_key == $start_time) {
					foreach ($time_val as $assignment) {
						echo "<div class=\"" . $assignment['css_class'] . "\">";
						echo $assignment['name'];
						echo "</div>";
					};
				};
			};
		};
	};

	echo "</td>";
};


function write_table_footer($dbh) {
	echo "</table>";

	echo "<div id=\"cal_buttons\">\n";
	echo "<form action=\"index.php\" method=\"post\">\n";
	echo "<input type=\"submit\" name=\"operation\" value=\"Previous Week\">\n";
	echo "<input type=\"submit\" name=\"operation\" value=\"Current Week\">\n";
	echo "<input type=\"submit\" name=\"operation\" value=\"Next Week\">\n";
	echo "</form>\n";
	echo "</div>\n";

	write_desk_key($dbh);
};
// End of table generation functions
?>
