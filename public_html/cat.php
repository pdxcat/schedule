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
