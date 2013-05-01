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
  if (empty($_POST['operation'])) {
    // The user really shouldn't get to this page without having
    // clicked a button on the view/drop shifts page.

    echo "No operation to perform. <br />";
    echo "<a href=\"ns_show_schedule.php\">Return to your schedule</a><br />";
  } elseif (is_array($_SESSION['drop_shifts']) && $_POST['operation'] == "Proceed") {
    // If the user has confirmed dropping the shifts then proceed
    // and display a confirmation and link back to the calendar
    // view.

    $dbh = start_db();

    foreach ($_SESSION['drop_shifts'] as $key => $val) {
      $drop_shifts_ids[] = $key;
    };

    drop_shifts_by_sa_ids($drop_shifts_ids, $dbh);

    $dbh = null;

    echo "Shifts dropped. <br />";
    echo "<a href=\"ns_show_schedule.php\">Back to your schedule</a><br />";
    session_unset($_SESSION['drop_shifts']);

  } else {
    // Shouldn't ever really get here.
    echo "Something went wrong. Contact the scheduler. <br />";
  };
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
function discard_dropped_sa_ids($sa_ids, &$dbh) {
  /*
    Fetch any ns_shift_dropped entries which match the provided sa_ids and
    remove the matching sa_ids from the provided array.
  */
  $sa_id_list .= implode(",",$sa_ids);

  /*
    Set up and run query for grabbing the sa_ids from the provided list
    which have an associated shift drop entry.
  */
  $token_str = make_token_string($sa_ids);

  $query = "
    SELECT d.ns_sa_id
    FROM ns_shift_dropped as d
    WHERE d.ns_sa_id IN ($token_str)";

  $sth = $dbh->prepare($query);

  // Binds the items in the array to the tokens in the query.
  bind_id_list($sa_ids, $sth);

  $sth->execute();

  $sth->setFetchMode(PDO::FETCH_ASSOC);

  // If we got no matches break here.
  if ($sth->rowCount() == 0) {
    return $sa_ids;
  };

  // Iterate through the results and remove from the sa_ids list any ids
  // matching the ones retrieved from the database.
  while ($row = $sth->fetch()) {
    foreach ($sa_ids as $key => $val) {
      if ($val == $db_row['ns_sa_id']) {
        unset($sa_ids[$key]);
      };
    };
  };

  // Reset array indexes since they'll be messed up if we removed any
  // elements from the middle.
  $sa_ids = array_values($sa_ids);

  return $sa_ids;
};


function drop_shifts_by_sa_ids (&$drop_shifts, &$dbh) {
  /*
    For each id in the array passed to the function, do the following:
     - Remove sa_ids which already have an ns_shift_dropped entry from the
       list of sa_ids to drop.
     - Add a new entry to ns_shift_dropped for the shift assignment.
     - Use the current date/time as the ns_sd_droptime.
  */

  // Run function to discard from the array shift assignment ids which
  // have already been dropped.
  $drop_shifts = discard_dropped_sa_ids($drop_shifts, $dbh);

  // Insert new ns_shift_dropped entries for each of the remaining sa_ids.
  $query = "
    INSERT INTO `ns_shift_dropped` (ns_sa_id,ns_sd_droptime)
    VALUES (:sa_id, :timestamp)";

  $sth = $dbh->prepare($query);

  foreach ($drop_shifts as $shift) {
    $now = date_create();
    $timestamp = date_format($now,"Y-m-d H:i:s");

    $sth->bindParam(':sa_id',$shift);
    $sth->bindParam(':timestamp',$timestamp);

    $sth->execute();
  };
};
?>
