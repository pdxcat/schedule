<?php
# schedule.php  Schedule Display Page in Progress

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

if(isset($_SERVER['HTTP_CAS_USER'])) {
  $username = $_SERVER['HTTP_CAS_USER'];
} else {
  $username = $_SERVER[PHP_AUTH_USER];
}

echo "<table border=1>
	<tr>\n
	<th></th>\n
	<th>Mon</th>\n
	<th>Tues</th>\n
	<th>Wed</th>\n
	<th>Thurs</th>\n
	<th>Fri</th>\n
	<th>Sat</th>\n
	</tr>";

# Sets host, user, password variables
require("db.inc");
$connection = mysql_connect($db_host,$db_user,$db_password) or die ("Couldn't connect to server.");

$db = mysql_select_db($db_database,$connection) or die ("Unable to connect to the $connection database.");
$days = array("Mon", "Tues", "Wed", "Thurs", "Fri", "Sat");
echo "$username";
for($i=8; $i<=17;$i++){
	$j=sprintf("%02d",$i);
	echo "<tr><td>$j</td>\n";
	foreach ($days as $day){
		if(! ($day=="Sat"&&($i<12||$i>16))){
			$query = "SELECT `{$j}` FROM schedAvail$day WHERE username=\"". $username
				."\"";
			$result = mysql_query($query) or die ("Couldn't execute query.");
			$row = mysql_fetch_array($result);
			if($row[0] == "a"){
				echo "<td bgcolor='#FFFF00'>Available</td>";
			}elseif($row[0] == "p"){
				echo "<td bgcolor='#00FF00'>Preferred</td>";
			}else{
				echo "<td bgcolor='000000'>Unavailable</td>";
			};
		};
	};
	echo "</tr>\n";
};
echo "</table>\n";

echo "<p>Shift Preference: ";
$query = "SELECT schedpref FROM humanInfo WHERE uname=\"". $username ."\"";
$result = mysql_query($query);
$row = mysql_fetch_row($result);
if($row[0] == "f"){
	echo "One 4-Hour Shift";
}elseif($row[0] == "t"){
	echo "Two 2-Hour Shifts";
}else{
	echo "No Shift Length Preference";
};
echo "</p>\n";
?>

<p><a href="ns_show_schedule.php">Return to your schedule</a></p>
</body></html>
