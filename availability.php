<!-- schedule.php  Schedule Display Page in Progress -->

<html>
<head><title>TheSchedule</title></head>
<body>
<?php

$username= $_SERVER[PHP_AUTH_USER];

echo "<table border=1>
	<tr>\n
	<td></td>\n
	<td>Mon</td>\n
	<td>Tues</td>\n
	<td>Wed</td>\n
	<td>Thurs</td>\n
	<td>Fri</td>\n
	<td>Sat</td>\n
	</tr>";

# Sets host, user, password variables                                                                              
require("db.inc");
$connection = mysql_connect($host,$user,$password) or die ("Couldn't connect to server.");

$database = $user;
$db = mysql_select_db($database,$connection) or die ("Unable to connect to the $connection database.");
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
echo "</table><p>Shift Preference: ";

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

echo "<br />";
echo "<a href=\"ns_show_schedule.php\">Return to your schedule</a><br />";

?>
</body></html>