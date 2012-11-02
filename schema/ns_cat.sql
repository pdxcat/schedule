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
  UNIQUE KEY "ns_cat_alt_email" ("ns_cat_alt_email"),
  KEY "ns_cat_type_id" ("ns_cat_type_id")
);
