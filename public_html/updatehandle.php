<?php
  require('ns_common.php');
  check_session();
  $username = $_SESSION['username'];

if ($username) {
  $dbh = start_db();
  if (array_key_exists('id', $_GET)) {
    $id = $_GET['id'];
  } else {
    $id = get_cat_id($username, $dbh);
  }

  $cat = get_cat_by_id($id, $dbh);

  if ($cat['username'] == $username) {
    if (array_key_exists('handle', $_POST)) { // update handle
      $handle = stripslashes($_POST['handle']); // magicquotes-- php--
      if (set_cat_handle($id, $handle, $dbh)) {
        redirect();
      } else {
        include('header.php');
        echo "<p>Failed to update handle.</p>\n";
      }
    } else {
      redirect();
    }
  } else {
    redirect();
  }
} else {
  // login failure
  include('header.php');
  echo "<p>Fail.</p>";
  echo "</div></div></body></html>\n";
};

function redirect() {
  header( "HTTP/1.1 303 See Other" );
  header( "Location: cat.php" );
}
?>
