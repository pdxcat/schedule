-- Licensed to the Computer Action Team (CAT) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The CAT licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--   http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing,
-- software distributed under the License is distributed on an
-- "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
-- KIND, either express or implied.  See the License for the
-- specific language governing permissions and limitations
-- under the License.

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
