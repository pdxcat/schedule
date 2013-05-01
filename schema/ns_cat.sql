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

DROP TABLE IF EXISTS "ns_cat";
CREATE TABLE "ns_cat" (
  "ns_cat_id" int(11) NOT NULL AUTO_INCREMENT,
  "ns_cat_uname" varchar(40) NOT NULL,
  "ns_cat_fname" varchar(40) DEFAULT NULL,
  "ns_cat_lname" varchar(40) DEFAULT NULL,
  "ns_cat_type_id" int(11) DEFAULT NULL,
  "ns_cat_group_id" int(11) DEFAULT NULL,
  "ns_cat_alt_email" varchar(80) DEFAULT NULL,
  "ns_cat_handle" varchar(20) DEFAULT NULL,
  PRIMARY KEY ("ns_cat_id"),
  UNIQUE KEY "ns_cat_uname" ("ns_cat_uname"),
  UNIQUE KEY "ns_cat_alt_email" ("ns_cat_alt_email"),
  KEY "ns_cat_type_id" ("ns_cat_type_id")
);
