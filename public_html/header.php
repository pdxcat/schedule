<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
  "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
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
?>
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
