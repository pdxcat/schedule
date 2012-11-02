<?php
/*processform.php*/
?>
<html>
<head><title>TheSchedule</title></head>
<body>
<?php

$username=$_SERVER[PHP_AUTH_USER];
require ("db.inc");
$connection = mysql_connect($host,$user,$password) or die ("Couldn't connect to
        server.");

$database = $user;
$db = mysql_select_db($database,$connection) or die ("Unable to connect to the
        $connection database.");
foreach(array("Mon","Tues","Wed","Thurs","Fri","Sat") as $day){
	for($i=8;$i<=17;$i++){
		if(!($day=="Sat"&&($i<12||$i>16))){
		$j = sprintf("%02d",$i);
		$avail = $_POST["{$day}-{$j}"];
		$query = "SELECT * FROM schedAvail$day WHERE username='$username'";
		$result = mysql_query($query);
		if (mysql_num_rows($result) > 0){
			$query = "UPDATE schedAvail$day SET `{$j}` ='$avail' where username='$username'";
		}else{
			$query = "INSERT INTO schedAvail$day (username,`{$j}`) VALUES (\"{$username}\",\"{$avail}\")";
		};
		$result = mysql_query($query) or die("Failure: " . mysql_error());
		};
	};
};

$spoon=$_POST["sched_pref"];
if(!$spoon){
	$spoon = 1;
};
$date = date("Y-m-d");

$query = "SELECT schedpref FROM humanInfo WHERE uname='$username'";
$result = mysql_query($query);
if (mysql_num_rows($result) > 0){
	$query = "UPDATE humanInfo SET schedpref='$spoon', `update`=CURDATE() where uname='$username'";
}else{
        $query = "INSERT INTO humanInfo (uname, schedpref, `update`) VALUES ('" . $username . "','" . $spoon . "', CURDATE())";
};
$result = mysql_query($query) or die("Failure: " . mysql_error());

echo "Updated $date !\n
	<p>Click <a href ='availability.php'>here</a> to view your availability.";
