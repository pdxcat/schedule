<?php
require('ns_common.php');
check_session();
?>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" 
"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">

<html>

<head>

<?php
$username = $_SESSION['username'];
echo "<title>The Schedule ($username)</title>";
?>

<link rel="stylesheet" type="text/css" href="master.css" media="screen" />
<link rel="stylesheet" type="text/css" href="ns_general.css" media="screen" />

</head>

<body>

<div id="page-container">

<div id="top-nav">
<?php
include 'ns_top_navigation.php';
?>
</div>

<div id="content">
<?php

if ($username) {
	// do stuff for the currently logged in user
	printf("Logged in as %s. <br />", $username);

	// Put additional stuff here

} else {
	// login failure
	echo "Fail.<br />";
};

?>

</div>
</div>
</body>
</html>
