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


function check_session() {
	if (!isset($_SESSION['id'])) {
		session_start();
		$_SESSION['username'] = $_SERVER[PHP_AUTH_USER];
	} else {
		
	};
};


function make_token_string (&$id_list) {
	// Generates a token string for using lists of id numbers in parameter
	// bound SQL queries. Output format is:
	//	[id0,id1,..,idn]
	// Input should be an array of id numbers.
	
	$token_str = "";
	$max = (count($id_list) - 1);
	for ($i = 0; $i <= $max; $i++) {
		$token_str .= sprintf(":id%d",$i);
		if ($i != $max) {
			$token_str .= ", ";
		}; 	
	};

	return $token_str;
};


function bind_id_list (&$id_list, &$sth) {
	$max = (count($id_list) - 1);
	for ($i = 0; $i <= $max; $i++) {
		$token = sprintf(":id%d",$i);
		$sth->bindValue($token,$id_list[$i]);
	};
};


function get_shifts( $gs_id, &$dbh ) {
        /* 
	Returns an array of shifts for the cat in question with the format:
        	$return_array[
		[ns_sa_id => x, 
		ns_shift_date => x, 
		ns_desk_shortname => x,
        	ns_shift_start_time => x, 
		ns_shift_end_time => x], 
		...]

        We only want to fetch shifts scheduled on or after today's date, so
        we need to know what today is.
	*/
        $today = date("Y-m-d");

        /* 
	Set up and run query for getting shift entries.

	Constraints are the date of the shift being after today's date, and
	the ID being assigned to matching the ID passed to this function.

	Additional constraint to make sure we are not getting shifts that have
	been dropped has been added (2011-7-29).

	Resolves the desk id in the shift assignment to the short name for the
	desk from the desks table.
	*/
        $query = "
		SELECT a.ns_sa_id, s.ns_shift_date, d.ns_desk_shortname, s.ns_shift_start_time, s.ns_shift_end_time
		FROM ns_shift_assigned as a, ns_shift as s, ns_desk as d
		WHERE s.ns_shift_date >= ?
		AND a.ns_cat_id = ?
		AND a.ns_shift_id = s.ns_shift_id
		AND a.ns_desk_id = d.ns_desk_id
		AND a.ns_sa_id NOT IN (
			SELECT ns_sa_id
			FROM ns_shift_dropped)
		ORDER BY ns_shift_date, ns_shift_start_time";

	$sth = $dbh->prepare($query);

	$sth->bindParam(1, $today);
	$sth->bindParam(2, $gs_id);

	$sth->execute();

	$sth->setFetchMode(PDO::FETCH_ASSOC);
	
	// Dump all the fetched data into a 2 dimensional array and return it.
        $shifts = array();
        while ($row = $sth->fetch()) {
                $shifts[] = array('ns_sa_id' => $row['ns_sa_id'],
			'ns_shift_date' => $row['ns_shift_date'],
                        'ns_desk_shortname' => $row['ns_desk_shortname'], 
			'ns_shift_start_time' => $row['ns_shift_start_time'],
                        'ns_shift_end_time' => $row['ns_shift_end_time']);
        };

        return $shifts;
};

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


function get_shifts_to_pickup( $gsp_id, &$dbh ) {
        /* 
	Function to get the shift information for display on the calendar view
	page used for selection of shifts to pick up.
	
	Returns an array of shifts available for the CAT in question to pick up
	with the format:

        We only want to fetch shifts on or after today's date, so we need to 
	know what today is.
	*/
        $today = date("Y-m-d");

        /* 
	Set up and run query for getting shift entries.

	A shift is available for pickup if it has an assignment entry with an
	associated drop entry which does not have a pickup entry associated 
	with it.
	
	Constraints:
	-Shift must not overlap with the user's assigned shifts (the user 
	 should have no assignments for the same shift id as the drop shift
	 entry)
	-If there are multiple dropped shifts for a given shift, time, and 
	 location, only one of these should be retrieved. 
	-Shift must have an assignment, with a drop entry which has no pick up
	 entry associated with it

	Data needed:
	-ns_sd_id (shift drop id, needed for insertion into shift pickup table)
	-ns_desk_shortname (for display)
	-ns_shift_date, ns_shift_start_time, ns_shift_end_time (for display)



	Resolves the desk id in the shift assignment to the short name for the
	desk from the desks table.
	*/
        $query = "
		SELECT sd.ns_sd_id, de.ns_desk_shortname, s.ns_shift_date, s.ns_shift_start_time, s.ns_shift_end_time
		FROM ns_shift as s, ns_desk as de, ns_shift_assigned as sa, ns_shift_dropped as sd
		WHERE sd.ns_sa_id = sa.ns_sa_id
		AND sa.ns_shift_id = s.ns_shift_id
		AND sa.ns_desk_id = de.ns_desk_id
		AND s.ns_shift_date >= ?
		AND s.ns_shift_id NOT IN (
			SELECT s.ns_shift_id
			FROM ns_shift as s, ns_shift_assigned as sa
			WHERE sa.ns_shift_id = s.ns_shift_id
			AND sa.ns_cat_id = ?
			AND sa.ns_sa_id NOT IN (
				SELECT ns_sa_id
				FROM ns_shift_dropped))
		AND sd.ns_sd_id NOT IN (
			SELECT ns_sd_id
			FROM ns_shift_picked_up)
		GROUP BY s.ns_shift_id, sa.ns_desk_id";
	
	$sth = $dbh->prepare($query);
	
	$sth->bindParam(1, $today);
	$sth->bindParam(2, $gsp_id);
	
	$sth->execute();

	$sth->setFetchMode(PDO::FETCH_ASSOC);

	// Dump all the fetched data into a 2 dimensional array and return it.
        $shifts = array();
        while ($row = $sth->fetch()) {
                $shifts[] = array(
			'ns_sd_id' => $row['ns_sd_id'], 
			'ns_desk_shortname' => $row['ns_desk_shortname'], 	
			'ns_shift_date' => $row['ns_shift_date'], 
			'ns_shift_start_time' => $row['ns_shift_start_time'], 
			'ns_shift_end_time' => $row['ns_shift_end_time']);
        };

        return $shifts;
};


function get_shifts_from_sa_ids( $sa_ids, &$dbh ) {
	/*
	Returns an array of shifts associated with assignments by id in the
	format:
	
	$return_array[
	[ns_sa_id => x, 
	ns_shift_date => x, 
	ns_desk_shortname => x,
	ns_shift_start_time => x, 
	ns_shift_end_time => x], 
	...]

        We only want to fetch shifts scheduled on or after today's date, so
        we need to know what today is.
	*/
        $today = date("Y-m-d");

	/*
	Set up and run query for getting shift entries.

	Get only shifts which have been assigned with an assignment matching 
	one of the IDs passed to the function.

	Additional constraint to make sure we are not getting shifts that have
	been dropped has been added (2011-7-29).

	Resolves the desk id in the shift assignment to the short name for the
	desk from the desks table.
	*/

	// Build the token string for our query. PDO doesn't support using a 
	// comma separated list as a bound parameter so the query must be
	// built dynamically based on how many IDs need to be matched against.

	$token_str = make_token_string($sa_ids);

        $query = "
		SELECT a.ns_sa_id, s.ns_shift_date, d.ns_desk_shortname, s.ns_shift_start_time, s.ns_shift_end_time
		FROM ns_shift_assigned as a, ns_shift as s, ns_desk as d
		WHERE s.ns_shift_date >= :today
		AND a.ns_sa_id IN ($token_str)
		AND a.ns_shift_id = s.ns_shift_id
		AND a.ns_desk_id = d.ns_desk_id
		AND a.ns_sa_id NOT IN (
			SELECT ns_sa_id
			FROM ns_shift_dropped)
		ORDER BY ns_shift_date, ns_shift_start_time";

	$sth = $dbh->prepare($query);

	$sth->bindParam(':today',$today);
	
	// Binds the items in the array to the tokens in the query.
	bind_id_list($sa_ids, $sth);
	
	$sth->execute();

	$sth->setFetchMode(PDO::FETCH_ASSOC);
	
	// Dump all the fetched data into a 2 dimensional array and return it.
        $shifts = array();
        while ($row = $sth->fetch()) {
                $shifts[] = array('ns_sa_id' => $row['ns_sa_id'], 
			'ns_shift_date' => $row['ns_shift_date'],
                        'ns_desk_shortname' => $row['ns_desk_shortname'], 
			'ns_shift_start_time' => $row['ns_shift_start_time'],
                        'ns_shift_end_time' => $row['ns_shift_end_time']);
        };

        return $shifts;
};


function get_shifts_from_sd_ids( $sd_ids, &$dbh ) {
	/*
	Returns an array of shifts associated with drops by id in the
	format:
	
	$return_array[
	[ns_sd_id => x, 
	ns_shift_date => x, 
	ns_desk_shortname => x,
	ns_shift_start_time => x, 
	ns_shift_end_time => x], 
	...]

        We only want to fetch shifts scheduled on or after today's date, so
        we need to know what today is.
	*/
        $today = date("Y-m-d");

	/*
	Set up and run query for getting shift entries.

	Get only shifts which have been assigned with an assignment matching 
	one of the IDs passed to the function.

	Additional constraint to make sure we are not getting shifts that have
	been dropped has been added (2011-7-29).

	Resolves the desk id in the shift assignment to the short name for the
	desk from the desks table.
	*/

	$token_str = make_token_string($sd_ids);

        $query = "
		SELECT sd.ns_sd_id, s.ns_shift_date, de.ns_desk_shortname, s.ns_shift_start_time, s.ns_shift_end_time
		FROM ns_shift_dropped as sd, ns_shift as s, ns_desk as de, ns_shift_assigned as sa
		WHERE s.ns_shift_date >= :today
		AND sd.ns_sd_id IN ($token_str)
		AND sa.ns_shift_id = s.ns_shift_id
		AND sd.ns_sa_id = sa.ns_sa_id
		AND sa.ns_desk_id = de.ns_desk_id
		AND sd.ns_sa_id NOT IN (
			SELECT ns_sd_id
			FROM ns_shift_picked_up)
		ORDER BY ns_shift_date, ns_shift_start_time";

	$sth = $dbh->prepare($query);

	$sth->bindParam(':today',$today);

	bind_id_list($sd_ids, $sth);
	
	$sth->execute();

	$sth->setFetchMode(PDO::FETCH_ASSOC);

	// Dump all the fetched data into a 2 dimensional array and return it.
        $shifts = array();
        while ($row = $sth->fetch()) {
                $shifts[] = array(
			'ns_sd_id' => $row['ns_sd_id'], 
			'ns_shift_date' => $row['ns_shift_date'],
                        'ns_desk_shortname' => $row['ns_desk_shortname'], 
			'ns_shift_start_time' => $row['ns_shift_start_time'],
                        'ns_shift_end_time' => $row['ns_shift_end_time']);
        };

        return $shifts;

};


function get_cat_id( $gci_uname, &$dbh ) {
	// Retrieve schedule DB ID numbers for the given username. Returns an
	// array of all matching IDs.

        // Set up and run the query to grab all ID numbers for the given CAT username
        $query = "
                SELECT ns_cat_id
                FROM ns_cat
                WHERE ns_cat_uname = ?";
	
	$sth = $dbh->prepare($query);

	$sth->bindParam(1, $gci_uname);

	$sth->execute();
	
	$sth->setFetchMode(PDO::FETCH_ASSOC);	

	$ids = array();
        while ($row = $sth->fetch()) {
		$ids[] = $row['ns_cat_id'];
	};

        return $ids;
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

?>
