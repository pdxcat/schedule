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
	$dbh = start_db();
	$cat_id = get_cat_id($username, $dbh);
	if (!$cat_id) {
		echo "You don't seem to be active in the schedule database. If you believe this is an error please contact the scheduler.<br />\n";
		exit;
	};

	if ($_POST['operation'] == "Pick Up Selected Shifts") {
		/*
		If the user has clicked the pickup shifts button, check if there
		were any shifts selected. If so, display the confirmation
		stuff. If not, note that no shifts were selected to drop and
		redraw the calendar.
		*/

		// Update SESSION data to account for any new shift selections
		// or deselections that were POSTed before we do anything else.
		update_session_shifts();

		if (is_array($_SESSION['pickup_shifts'])) {
			echo "Are you sure you wish to pick up the following shifts?<br />";

			foreach ($_SESSION['pickup_shifts'] as $key => $val) {
				$pickup_shifts_ids[] = $key;
			};

			generate_shifts_table($pickup_shifts_ids, $dbh);

			echo "<form action=\"ns_show_pickup.php\" method=\"post\">";
			echo "<input type=\"submit\" name=\"operation\" value=\"Abort\">";
			echo "</form>";

			echo "<form action=\"ns_pickup_shifts.php\" method=\"post\">";
			echo "<input type=\"submit\" name=\"operation\" value=\"Proceed\">";
			echo "</form>";
		} else {
			echo "No shifts were selected to pick up.<br />";

			generate_shifts_calendar($username, $cat_id, $dbh);
		};
	} elseif ($_POST['operation'] == "Abort") {
		// If the user clicked the abort button in the confirmation
		// dialog then clear the SESSION array of shifts to drop and
		// note what's happened.

		echo "Shift pick up cancelled, shift selections have been cleared.<br />";
		session_unset($_SESSION['pickup_shifts']);

		generate_shifts_calendar($username, $cat_id, $dbh);

	} elseif (empty($_POST['operation'])) {
		// Clear selections if we got here without having clicked one
		// of the form buttons.
		session_unset($_SESSION['pickup_shifts']);

		generate_shifts_calendar($username, $cat_id, $dbh);

	} else {
		// Update SESSION data to account for any new shift selections
		// or deselections that were POSTed before we do anything else.
		update_session_shifts();

		// Any other POST operation will be processed in the calendar
		// generation function.
		generate_shifts_calendar($username, $cat_id, $dbh);
	};

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
// Functions to generate a calendar of shifts.
function generate_shifts_calendar( $gct_username, $cat_id, &$dbh ) {
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

	} elseif ($_POST['operation'] == "Next Month") {
		// If next month button was clicked initialize base date with
		// the last viewed date and then tack a month onto it.
		$base_date = date_create($_SESSION['last_viewed_date']);
		date_modify($base_date, '+1 month');

	} elseif ($_POST['operation'] == "Previous Month") {
		// If previous month button was clicked initialize base date
		// with the last viewed date and then hack a month off it.
		$base_date = date_create($_SESSION['last_viewed_date']);
		date_modify($base_date, '-1 month');

	} else {
		/*
		// If no submit button was clicked to get here or we otherwise
		// have no previous date to go off of then use the last viewed
		// date if it is set or initialize base date as the current
		// date if there's nothing else to go off of.
		if (!empty($_SESSION['last_viewed_date'])) {
			$base_date = date_create($_SESSION['last_viewed_date']);
		} else {
			$base_date = date_create();
		};
		*/

		// Default to current date.
		$base_date = date_create();
	};

	// Once we're done figuring out the date to use to generate the page
	// update the last viewed date in the SESSION parameters.
	$_SESSION['last_viewed_date'] = date_format($base_date, 'Y-m-d');

	// Come up with the first and last dates of the month by using some
	// gross tricks with the built in date manipulation functions.
	$first_of_month = date_create(date_format($base_date,'Y-m-01'));
	$last_of_month = date_create(date_format($base_date,'Y-m-t'));

	/*
	Fire up a connection to the database, then grab the currently
	logged in user's id in the schedule database, follow it up by
	retrieving all of the shifts available for pickup which do not
	overlap with other shifts of the user's.
	*/
	$gct_shifts = get_shifts_to_pickup($cat_id, $dbh);


	// Start actually assembling the calendar table into which all of this
	// shift data is outputted.
	write_calendar_header($base_date);

	// Format start and end times in hhmm format
 	foreach ($gct_shifts as &$shift) {
 		foreach ($shift as $key => &$value) {
 			if ($key == 'ns_shift_start_time' || $key == 'ns_shift_end_time') {
 				preg_match('/^(\d{2}):(\d{2}):(\d{2})/',$value,$chunks);
 				$value = $chunks[1] . $chunks[2];
			};
 		};
	};

	echo "<form action=\"ns_show_pickup.php\" method=\"post\">";

	echo "<tr>";
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
			our_date_diff(date_format($current_date,'Y-m-d'),date_format($last_of_month,'Y-m-d')) >= 0;
			date_modify($current_date,'+1 day')) {

				write_dated_calendar_cell($current_date,$gct_shifts);

				// Start a new row every seven cells.
				if ($cell % 7 == 0 && $cell < 42) {
					echo "</tr>\n<tr>";
				};

				$cell++;

				// Hackish shit necessary due to the hackishness of the
				// date_diff function I'm using as a stand in for the
				// real thing since we're running ancient ass PHP.
				if (our_date_diff(date_format($current_date,'Y-m-d'),
				date_format($last_of_month,'Y-m-d')) == 0) {
					break;
				};
			};

		};

		write_blank_calendar_cell();

		// Start a new row every seven cells.
		if ($cell % 7 == 0 && $cell < 42) {
			echo "</tr>\n<tr>";
		};
	};
	echo "</tr>";

	write_calendar_footer($dbh, $base_date);

};


function write_dated_calendar_cell(&$current_date,&$gct_shifts) {

	// Writes out the date in the top left of the cell
	echo "<td>";
	echo "<span class=\"cell_label\">";
	echo date_format($current_date, 'j');
	echo "<br />";
	echo "</span>";

	// Writes out shift start and end times
	foreach ($gct_shifts as $shift) {
		if ($shift['ns_shift_date'] == date_format($current_date,'Y-m-d')) {
			echo "<span class=\"cell_contents\">\n";
			// Use the state of the shift from the SESSION params,
			// if it's been set.
			if ($_SESSION['pickup_shifts'][$shift['ns_sd_id']] == 1) {
				// If the parameter for the shift is set and
				// has a value of 1, display a checked box and
				// put in a hidden field to set the value to
				// 0 so if the box is unchecked that change is
				// registered.
				echo "<input type=\"hidden\" name=\"pickup_shifts[" . $shift['ns_sd_id']. "]\"
					value=\"0\">";
				echo "<input type=\"checkbox\" name=\"pickup_shifts[" . $shift['ns_sd_id'] . "]\"
					value=\"1\" checked>";
			} else {
				echo "<input type=\"checkbox\" name=\"pickup_shifts[" . $shift['ns_sd_id'] . "]\"
					value=\"1\">";
			};

			echo "<div class=\"" . $shift['css_class'] . "\">";
			echo $shift['ns_shift_start_time'] . " - " . $shift['ns_shift_end_time'];
			echo "</div>";
			echo "</span>";
		};
	};

	echo "</td>";

};


function write_blank_calendar_cell() {
	echo "
	<td>
	</td>";
};


function write_calendar_header( &$base_date ) {
	echo "<p class=\"cal_month\">" . date_format($base_date,'F Y') . "</p>";

	echo "<table class=\"shift_calendar\">
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


function write_calendar_footer( &$dbh, &$base_date ) {
	echo "</table>";

	echo "<div id=\"cal_buttons\">";
	echo "<input type=\"submit\" name=\"operation\" value=\"Previous Month\">";
	echo "<input type=\"submit\" name=\"operation\" value=\"Current Month\">";
	echo "<input type=\"submit\" name=\"operation\" value=\"Next Month\">";
	echo "<br />";
	echo "<input type=\"submit\" name=\"operation\" value=\"Pick Up Selected Shifts\">";
	echo "</div>";
	echo "</form>";


	write_desk_key($dbh);
};
// End of shift calendar functions.


// Functions used in the generation of a table of shifts.
function generate_shifts_table( $pickup_shifts, &$dbh ) {

	// Needs to be changed for shifts available to be picked up
	// Get shifts
	$shifts = get_shifts_from_sd_ids($pickup_shifts, $dbh);

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
		<table class=\"shift_list\">\n
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
	if (!isset($_POST['pickup_shifts'])) {
		return 1;
	};

	foreach ($_POST['pickup_shifts'] as $key => $val) {
		if ($val == 1) {
			$_SESSION['pickup_shifts'][$key] = $val;
		} else {
			unset($_SESSION['pickup_shifts'][$key]);
		};
	};
};

?>
