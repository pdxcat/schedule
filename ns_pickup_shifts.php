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
  <link rel="stylesheet" type="text/css" href="ns_general.css" media="screen" />
</head>

<body>

<div id="page-container">
<div id="top-nav"><?php include 'ns_top_navigation.php'; ?></div>

<div id="content">
<?php
if ($username) {
  // do stuff for the currently logged in user
  printf("Logged in as %s. <br />", $username);

  if (empty($_POST['operation'])) {
    // The user really shouldn't get to this page without having
    // clicked a button on the view/drop shifts page.

    echo "No operation to perform. <br />";
    echo "<a href=\"ns_show_schedule.php\">Return to your schedule</a><br />";
  } elseif (is_array($_SESSION['pickup_shifts']) && $_POST['operation'] == "Proceed") {
    // If the user has confirmed dropping the shifts then proceed
    // and display a confirmation and link back to the calendar
    // view.

    $dbh = start_db();

    foreach ($_SESSION['pickup_shifts'] as $key => $val) {
      $pickup_shifts_ids[] = $key;
    };

    pickup_shifts_by_sd_ids($pickup_shifts_ids, $username, $dbh);

    echo "Shifts picked up. <br />";
    echo "<a href=\"ns_show_schedule.php\">Back to your schedule</a><br />";
    session_unset($_SESSION['pickup_shifts']);

  } else {
    // Shouldn't ever really get here.
    echo "Something went wrong. Contact the scheduler. <br />";
  };
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
function discard_picked_up_sd_ids($sd_ids, &$dbh) {
  /*
    Fetch any ns_shift_dropped entries which match the provided sa_ids and
    remove the matching sa_ids from the provided array.
  */

  /*
    Set up and run query for grabbing the sa_ids from the provided list
    which have an associated shift drop entry.
  */

  $token_str = make_token_string($sd_ids);

  $query = "
    SELECT p.ns_sa_id
    FROM ns_shift_picked_up as p
    WHERE p.ns_sd_id IN ($token_str)";

  $sth = $dbh->prepare($query);

  bind_id_list($sd_ids, $sth);

  $sth->execute();

  // If we got no matches break here.
  if (!$sth->rowCount()) {
    return $sd_ids;
  };

  // Iterate through the results and remove from the sd_ids list any ids
  // matching the ones retrieved from the database.
  $sth->setFetchMode(PDO::FETCH_ASSOC);

  while ($row = $sth->fetch()) {
    foreach ($sd_ids as $key => $val) {
      if ($val == $row[0]) {
        unset($sd_ids[$key]);
      };
    };
  };

  // Reset array indexes since they'll be messed up if we removed any
  // elements from the middle.
  $sd_ids = array_values($sd_ids);

  return $sd_ids;
};


function pickup_shifts_by_sd_ids ( &$pickup_shifts, $username, &$dbh ) {
  /*
  For each id in the array passed to the function, do the following:
   - Remove sd_ids which already have an ns_shift_picked_up entry from the
     list of sd_ids to pick up.
   - Add a new entry to ns_shift_picked_up, and to ns_shift_assigned.
   - Use the current date/time as the ns_spu_droptime and ns_sa_assignedtime.
   - Add the ns_sa_id from the new assignment to the ns_shift_picked_up
     entry in the appropriate field.
  */

  // Run function to discard sd_ids that have already been picked up.
  $pickup_shifts = discard_picked_up_sd_ids($pickup_shifts, $dbh);

  // Collect shift information to be used in the creation of new entries.
  $token_str = make_token_string($pickup_shifts);

  $query = "
    SELECT sd.ns_sd_id, sa.ns_shift_id, sa.ns_desk_id
    FROM ns_shift_assigned as sa, ns_shift_dropped as sd
    WHERE sd.ns_sd_id IN ($token_str)
    AND sd.ns_sa_id = sa.ns_sa_id";

  $sth = $dbh->prepare($query);

  bind_id_list($pickup_shifts, $sth);

  $sth->execute();

  $sth->setFetchMode(PDO::FETCH_ASSOC);

  $shift_info = array();
  while ($row = $sth->fetch()) {
    $shift_info[] = array(
      'ns_sd_id' => $row['ns_sd_id'],
      'ns_shift_id' => $row['ns_shift_id'],
      'ns_desk_id' => $row['ns_desk_id']);
  };

  $cat_id = get_cat_id($username, $dbh);
  $now = date_create();
  $timestamp = date_format($now,'Y-m-d H:i:s');

  // Insert new assignment entry.
  // Using a reference for the value since it needs to be modified

  $query = "
    INSERT INTO `ns_shift_assigned` (ns_shift_id,ns_cat_id,ns_desk_id,ns_sa_assignedtime)
    VALUES (:ns_shift_id,:ns_cat_id,:ns_desk_id,:timestamp)
  ";

  $sth = $dbh->prepare($query);

  foreach ($shift_info as &$shift) {

    $sth->bindParam(':ns_shift_id',$shift['ns_shift_id']);
    $sth->bindParam(':ns_cat_id',$cat_id[0]);
    $sth->bindParam(':ns_desk_id',$shift[ns_desk_id]);
    $sth->bindParam(':timestamp',$timestamp);

    $sth->execute();

    // Retrieve ns_sa_id for the new assignment entry just added.
    $shift['ns_sa_id'] = $dbh->lastInsertId();
  };

  // Unsetting the reference used.
  unset($shift);

  // Insert new pickup entry.
  $query = "
    INSERT INTO `ns_shift_picked_up` (ns_spu_timestamp,ns_sd_id,ns_cat_id,ns_sa_id)
    VALUES (:timestamp,:ns_sd_id,:ns_cat_id,:ns_sa_id)
  ";

  $sth = $dbh->prepare($query);

  foreach ($shift_info as $shift) {

    $sth->bindParam(':timestamp',$timestamp);
    $sth->bindParam(':ns_sd_id',$shift['ns_sd_id']);
    $sth->bindParam(':ns_cat_id',$cat_id[0]);
    $sth->bindParam(':ns_sa_id',$shift[ns_sa_id]);

    $sth->execute();
  };
};
?>

