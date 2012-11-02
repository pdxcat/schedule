<?php
/*buildAvailability.php*/
?>
<html>
<head><title>TheSchedule</title>
<script>
function thiscolor(elem) {
  elem.style.backgroundcolor=elem.options[elem.selectedIndex].style.backgroundcolor;
}
</script>
</head>
<body>
<?php

#ini_set("include_path", ".:/home/solaris/schedule/bin");

# Sets host, user, password variables
require("db.inc");
$username=$_SERVER[PHP_AUTH_USER];
echo "$username";
$connection = mysql_pconnect($db_host,$db_user,$db_password) or die ("Couldn't connect
 to server.");
$db = mysql_select_db($db_database,$connection) or die ("Unable to connect to the $connection database.");

echo "<form action = 'processform.php' method='POST'>";

echo "<table border=1>
        <tr>\n
        <td>Time</td>\n
        <td>Monday</td>\n
        <td>Tuesday</td>\n
        <td>Wednesday</td>\n
        <td>Thursday</td>\n
        <td>Friday</td>\n
        <td>Saturday</td></tr>\n";

for($i=8; $i<18; $i++){
	$j=sprintf("%02d",$i);
        echo "<tr><td>$j - " . sprintf("%02d",$i+1) . "</td>";
	foreach(array("Mon","Tues","Wed","Thurs","Fri","Sat") as $day){
		if($day=="Sat"&&($i<12||$i>16)){
			echo "<td bgcolor='000000'>Unavailable</td>\n";
		}else{
			$query="SELECT `{$j}` FROM schedAvail$day WHERE username=\"$username\"";
			$result = mysql_query($query);
			$row = mysql_fetch_array($result);
			$options=array("u","a","p");
			echo "<td><select name='" . $day . "-" . $j . "' onChange=\"thiscolor(this);\">\n";
			foreach(array("u","a","p") as $option){
				echo "<option value='" . $option . "'";
				if($row[0]==$option){
					echo " selected";
##				}else{
##					echo ">";
				};
				if($option=="a"){
					echo " style=\"background-color: Yellow;\">Available\n";
				}else if($option=="p"){
					echo " style=\"background-color: Green;color: #FFFFFF;\">Preferred\n";
				}else{
					echo " style=\"background-color: Black;color: #FFFFFF;\">Unavailable\n";
				};
			};
			echo "</select>\n
			</td>";
		};
	};
	echo "</tr>";
};

$query="SELECT schedpref from humanInfo where uname=\"$username\"";
$result=mysql_query($query);
$row = mysql_fetch_row($result);
$pref = $row[0];

echo "</table>\n<p><b>Available</b>: I am available and willing to work during this time.\n<br><b>Preferred</b>: I am available and would prefer to work during this time.\n<br><b>Unavailable</b>: I am unavailable or unwilling to work during this time.\n<p>";

if($pref=="f")
	echo "<input type=\"radio\" name=\"sched_pref\" value=\"f\" checked=checked> One 4-Hour Shift<p>";
else
	echo "<input type=\"radio\" name=\"sched_pref\" value=\"f\"> One 4-Hour Shift<p>";
if($pref=="t")
	echo "<input type=\"radio\" name=\"sched_pref\" value=\"t\" checked=checked> Two 2-Hour Shifts<p>";
else
	echo "<input type=\"radio\" name=\"sched_pref\" value=\"t\"> Two 2-Hour Shifts<p>";
if($pref=="o")
	echo "<input type=\"radio\" name=\"sched_pref\" value=\"o\" checked=checked> No Shift Length Preference<p>";
else
	echo "<input type=\"radio\" name=\"sched_pref\" value=\"o\"> No Shift Length Preference<p>";

echo "<p><input type ='submit' value='Submit'>
	</form>\n";
?>
</body></html>
