DROP TABLE IF EXISTS "ns_desk";
CREATE TABLE "ns_desk" (
  "ns_desk_id" int(11) NOT NULL AUTO_INCREMENT,
  "ns_desk_name" varchar(40) NOT NULL,
  "ns_desk_shortname" varchar(8) NOT NULL,
  "ns_desk_suite" varchar(20) NOT NULL,
  PRIMARY KEY ("ns_desk_id")
);
