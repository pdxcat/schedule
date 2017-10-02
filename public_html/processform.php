<?php
# processform.php

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
<head><title>TheSchedule</title></head>
<body>
<?php

if (isset($_SERVER['HTTP_CAS_USER']))
    {
    $username = $_SERVER['HTTP_CAS_USER'];
    }
else
    {
    $username = $_SERVER[PHP_AUTH_USER];
    }

require('db.inc');

$connection = mysqli_connect($db_host, $db_user, $db_password, $db_database)
    or die("Couldn't connect to server.");

foreach (array( 'Mon', 'Tues', 'Wed', 'Thurs', 'Fri', 'Sat') as $day)
    {
    for ($i = 8; $i <= 17; $i++)
        {
        if (!($day == 'Sat' && ($i < 12 || $i > 16)))
            {
            $j      = sprintf('%02d', $i);
            $avail  = $_POST["{$day}-{$j}"];
            $query  = "SELECT * FROM schedAvail$day WHERE username='$username'";
            $result = $connection->query($query);

            if (mysqli_num_rows($result) > 0)
                {
                $query = "UPDATE schedAvail$day SET `{$j}` ='$avail' where username='$username'";
                }
            else
                {
                $query = "INSERT INTO schedAvail$day (username,`{$j}`) VALUES (\"{$username}\",\"{$avail}\")";
                }

            $result = $connection->query($query) or die("Failure: " . mysqli_error());
            }
        }
    }

$spoon = $_POST['sched_pref'];

if (!$spoon)
    {
    $spoon = 1;
    }
$date = date('Y-m-d');

$query  = "SELECT schedpref FROM humanInfo WHERE uname='$username'";
$result = $connection->query($query);

if (mysqli_num_rows($result) > 0)
    {
    $query = "UPDATE humanInfo SET schedpref='$spoon', `update`=CURDATE() where uname='$username'";
    }
else
    {
    $query = "INSERT INTO humanInfo (uname, schedpref, `update`) VALUES ('" . $username . "','" . $spoon . "', CURDATE())";
    }

$result = $connection->query($query)
    or die("Failure: " . mysqli_error());

?>
Updated <?= $date ?>!
<p>Click <a href ='availability.php'>here</a> to view your availability.
