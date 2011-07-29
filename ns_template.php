
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" 
"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">

<html>

<head>

<?php

// User login and session info stuff

// If the user is logged in we should display their username in the title bar

$username = $_SERVER[PHP_AUTH_USER];

if ($username) {
	echo "<title>The Schedule ($username)</title>";
} else {
	echo "<title>The Schedule</title>";
};

?>

<link rel="stylesheet" type="text/css" href="ns_general.css" media="screen" />

</head>


<body>

<?php

if ($username) {
	// do stuff for the currently logged in user
	printf("Logged in as %s. <br />", $username);

	require('ns_common.php');
	
	// Put additional stuff here

} else {
	// login failure
	echo "Fail.<br />";
};

?>

</body>
</html>
