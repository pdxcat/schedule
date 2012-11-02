DROP TABLE IF EXISTS "ns_cat_group";
CREATE TABLE "ns_cat_group" (
  "ns_cat_group_id" int(2) NOT NULL AUTO_INCREMENT,
  "ns_cat_group_name" varchar(40) DEFAULT NULL,
  "ns_cat_group_year" int(4) NOT NULL,
  PRIMARY KEY ("ns_cat_group_id"),
  UNIQUE KEY "ns_cat_group_year" ("ns_cat_group_year"),
  UNIQUE KEY "ns_cat_group_name" ("ns_cat_group_name")
);
