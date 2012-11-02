DROP TABLE IF EXISTS `humanInfo`;
CREATE TABLE `humanInfo` (
  `uname` char(8) NOT NULL,
  `SID` char(9) NOT NULL,
  `fname` varchar(30) NOT NULL,
  `lname` varchar(30) NOT NULL,
  `IRC` varchar(30) DEFAULT NULL,
  `email` varchar(60) NOT NULL,
  `DOG` tinyint(1) NOT NULL DEFAULT '1',
  `DROID` tinyint(1) NOT NULL DEFAULT '0',
  `schedpref` enum('o','t','f') NOT NULL DEFAULT 'o',
  `update` date NOT NULL,
  `makeup` char(5) NOT NULL DEFAULT '00:00',
  `banked` tinyint(1) NOT NULL,
  `warning` int(1) NOT NULL DEFAULT '0',
  UNIQUE KEY `uname` (`uname`,`SID`,`email`)
);
