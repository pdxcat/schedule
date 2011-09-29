<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">

<html>

<head>

<link rel="stylesheet" type="text/css" href="ns_cal_public.css" media="screen" />

</head>

<body>

<div id="shift_public">

<?php
$base_date = date_create();

$dbh = start_db();

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
$shifts = get_shifts_for_all($first_of_week,$last_of_week,$dbh);

echo "An @ indicates there will be a member of the CAT present at the given day and time. The color of the symbol indicates which location they will be at.<br /><br />\n";
echo "<span class=\"cal_labels\">";
echo "Schedule for " . date_format($first_of_week,'Y-m-d') . " to " . date_format($last_of_week,'Y-m-d');
echo "<br />";
echo "</span>";
?>

<br />
<table>
<tr>
<th class="hour_label"></th>
<th class="day_label">M</th>
<th class="day_label">T</th>
<th class="day_label">W</th>
<th class="day_label">R</th>
<th class="day_label">F</th>
<th class="day_label">S</th>
</tr>

<?php
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

		$flags = array('dh' => 0, 'kn' => 0);
		write_table_cell($current_date, $hour, $shifts, $flags);

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
?>

</table>

<br />
<span class="cal_labels">
Schedule key: <br />
<span class="shift_dh">DOGHaus	FAB 82-01</span><br />
<span class="shift_kn">Kennel	EB 325A</span><br />
</span>

</div>
</body>
</html>

<?php
function start_db() {
        // Establishes the database connection.
        // Uses an include file with some special permissions on it.
        require('db.inc');
        $db_database = "schedule";
        try {
                $dbh = new PDO("mysql:host=$db_host;dbname=$db_database",$db_user,$db_password);
        } catch (PDOException $e) {
                echo $e->getMessage();
        };

        return $dbh;
};


function write_table_cell(&$date, &$hour, &$gwt_shifts, &$flags) {
	$db_date = date_format($date, 'Y-m-d');
	$start_time = sprintf('%02d',$hour) . ":00:00";
	echo "<td>";
	foreach ($gwt_shifts as $date_key => $date_val) {
		if ($date_key == $db_date) {
			foreach ($date_val as $time_key => $time_val) {
				if ($time_key == $start_time) {
					foreach ($time_val as $assignment) {
						if ($assignment['ns_desk_shortname'] == "Kennel"
							&& $flags['kn'] == 0) {
							echo "<span class=\"shift_kn\">";
							echo " @ ";
							echo "</span>";
							$flags['kn'] = 1;
						} elseif ($assignment['ns_desk_shortname'] == "DOGHaus"
							&& $flags['dh'] == 0) {
							echo "<span class=\"shift_dh\">";
							echo " @ ";
							echo "</span>";
							$flags['dh'] = 1;
						};
					};
				};
			};
		};
	};

	echo "</td>";
};


/*
Using this since we're currently runing PHP 5.2.mumble. It's taken from an
example posted at http://www.php.net/manual/en/datetime.diff.php by Dennis C.
*/

function date_diff($date1, $date2) {
    $current = $date1;
    $datetime2 = date_create($date2);
    $count = 0;
    while(date_create($current) < $datetime2){
        $current = gmdate("Y-m-d", strtotime("+1 day", strtotime($current)));
        $count++;
    }
    return $count;
}


function get_shifts_for_all( &$start_date, &$end_date, &$dbh ) {
        /*
        Function to fetch all active assignments in a specified date range.
        This is used to populate the weekly schedule displays which show when
        people are on shift.

        Format for return array looks like:
        $return_array
        ['ns_shift_date']
                ['ns_shift_start_time']
                        ['ns_cat_uname']
                        ['ns_desk_shortname']
        */

        $gsfa_start_date = date_format($start_date, 'Y-m-d');
        $gsfa_end_date = date_format($end_date, 'Y-m-d');

        $query = "
                SELECT s.ns_shift_date, s.ns_shift_start_time, c.ns_cat_uname, d.ns_desk_shortname
                FROM ns_shift as s, ns_shift_assigned as a, ns_desk as d, ns_cat as c
                WHERE s.ns_shift_date >= ?
                AND s.ns_shift_date <= ?
                AND a.ns_cat_id = c.ns_cat_id
                AND a.ns_desk_id = d.ns_desk_id
                AND a.ns_shift_id = s.ns_shift_id
                AND a.ns_sa_id NOT IN (
                        SELECT ns_sa_id
                        FROM ns_shift_dropped)
                ORDER BY d.ns_desk_shortname,s.ns_shift_date,s.ns_shift_start_time,c.ns_cat_uname
                ";

        $sth = $dbh->prepare($query);

        $sth->bindParam(1, $gsfa_start_date);
        $sth->bindParam(2, $gsfa_end_date);

        $sth->execute();

        $sth->setFetchMode(PDO::FETCH_ASSOC);

        // Dump all the fetched data into a 2 dimensional array and return it.
        $shifts = array();
        while ($row = $sth->fetch()) {
                $shifts[$row['ns_shift_date']][$row['ns_shift_start_time']][] = array(
                        'ns_cat_uname' => $row['ns_cat_uname'],
                        'ns_desk_shortname' => $row['ns_desk_shortname']);
        };

        return $shifts;
};
?>
