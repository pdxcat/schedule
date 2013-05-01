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
