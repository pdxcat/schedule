<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
  "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html>
  <head>
    <title>The Schedule (<?php
      $username = $_SESSION['username'];
      echo "$username";
  ?>)</title>
    <link rel="stylesheet" type="text/css" href="ns_general.css" media="screen" />
  </head>
  <body>
    <div id="page-container">
    <div id="user">
      <?php
        if ($username) {
          $dbh = start_db();
          printf("Logged in as <a href=\"cat.php\">%s</a>.",
            get_cat_handle_by_username($username, $dbh));
        };
      ?>
    </div>
    <div id="top-nav">
        <a href="ns_show_schedule.php">View/Drop Your Shifts</a>
        <a href="ns_show_pickup.php">Pick Up Dropped Shifts</a>
        <a href="index.php">View Weekly Schedule</a>
        <a href="buildavailability.php">Update Availability</a>
    </div>
    <div id="content">
