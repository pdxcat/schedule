<?php
  require('ns_common.php');
  check_session();

  include('header.php');

if ($username) {
  $dbh = start_db();
  if (array_key_exists('id', $_GET)) {
    $id = $_GET['id'];
  } else {
    $id = get_cat_id($username, $dbh);
  }

  $cat = get_cat_by_id($id, $dbh);

  if ($cat['username'] == $username) {
    echo "<p>Username: " . $cat['username'] . "</p>\n";
    echo "<p>Handle: <form action=\"updatehandle.php\" method=\"post\">\n";
    echo "<input type=\"text\" name=\"handle\" value=\"" . $cat['handle'] . "\">\n";
    echo "<input type=\"submit\" value=\"Update\"></form></p>\n";
  } else {
    echo "<p>Username: " . $cat['username'] . "</p>\n";
    echo "<p>Handle: " . $cat['handle'] . "</p>\n";
  }
} else {
  // login failure
  echo "<p>Fail.</p>";
};

?>

</div>
</div>
</body>
</html>
