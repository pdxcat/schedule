<?php
# buildAvailability.php

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
<head><title>TheSchedule</title>
<script>
function thiscolor(elem) 
    {
    elem.style.backgroundcolor=elem.options[elem.selectedIndex].style.backgroundcolor;
    }
</script>
</head>
<body>

<?php

# Sets host, user, password variables
require(dirname(__FILE__) . '/db.inc');

if(isset($_SERVER['HTTP_CAS_USER'])) 
    {
    $username = $_SERVER['HTTP_CAS_USER'];
    }
else 
    {
    $username = $_SERVER['PHP_AUTH_USER'];
    }

$connection = mysqli_connect($db_host,$db_user, $db_password, $db_database)
    or die ("Couldn't connect to server.");

?>
<form action = 'processform.php' method='POST'>

<table border=1>
    <tr>
	<td>Time</td>
	<td>Monday</td>
	<td>Tuesday</td>
	<td>Wednesday</td>
	<td>Thursday</td>
	<td>Friday</td>
	<td>Saturday</td>
    </tr>

<?php

for($i=8; $i<18; $i++)
    {
    $j=sprintf('%02d',$i);

    echo "<tr><td>$j - " . sprintf('%02d',$i+1) . '</td>';

    foreach(array('Mon', 'Tues', 'Wed', 'Thurs', 'Fri', 'Sat') as $day)
	{
	if($day == 'Sat' && ($i<12||$i>16))
	    {
	    echo "<td bgcolor='000000'>Unavailable</td>\n";
	    }
	else
	    {
	    $query="SELECT `{$j}` FROM schedAvail$day WHERE username=\"$username\"";
	    $result = $connection->query($query);
	    $row = $result->fetch_array();
	    $options=array('u', 'a', 'p');

	    echo "<td><select name='" . $day . "-" . $j . "' onChange=\"thiscolor(this);\">\n";

	    foreach(array('u', 'a', 'p') as $option)
		{
		echo "<option value='" . $option . "'";
		if($row[0]==$option)
		    {
		    echo ' selected';
		    }
		if($option=='a')
		    {
		    echo " style=\"background-color: Yellow;\">Available\n";
		    }
		else if($option=='p')
		    {
		    echo " style=\"background-color: Green;color: #FFFFFF;\">Preferred\n";
		    }
		else
		    {
		    echo " style=\"background-color: Black;color: #FFFFFF;\">Unavailable\n";
		    }
		}
	    echo "</select>\n</td>";
	    }
	}
    echo '</tr>';
    }

$query="SELECT schedpref from humanInfo where uname=\"$username\"";
$result=$connection->query($query);
$row = $result->fetch_array();
$pref = $row[0];

?>

</table>
<p>
<b>Available</b>: I am available and willing to work during this time.
<br><b>Preferred</b>: I am available and would prefer to work during this time.
<br><b>Unavailable</b>: I am unavailable or unwilling to work during this time.
<p>

<?php

if($pref=='f')
    {
    echo "<input type=\"radio\" name=\"sched_pref\" value=\"f\" checked=checked> One 4-Hour Shift<p>";
    }
else
    {
    echo "<input type=\"radio\" name=\"sched_pref\" value=\"f\"> One 4-Hour Shift<p>";
    }

if($pref=='t')
    {
    echo "<input type=\"radio\" name=\"sched_pref\" value=\"t\" checked=checked> Two 2-Hour Shifts<p>";
    }
else
    {
    echo "<input type=\"radio\" name=\"sched_pref\" value=\"t\"> Two 2-Hour Shifts<p>";
    }

if($pref=='o')
    {
    echo "<input type=\"radio\" name=\"sched_pref\" value=\"o\" checked=checked> No Shift Length Preference<p>";
    }
else
    {
    echo "<input type=\"radio\" name=\"sched_pref\" value=\"o\"> No Shift Length Preference<p>";
    }

?>
<p>
<input type ='submit' value='Submit'>
</form>\n";
</body></html>
