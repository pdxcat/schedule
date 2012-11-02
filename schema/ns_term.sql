DROP TABLE IF EXISTS "ns_term";
CREATE TABLE "ns_term" (
  "ns_term_id" int(11) NOT NULL AUTO_INCREMENT,
  "ns_term_name" varchar(80) NOT NULL,
  "ns_term_startdate" date NOT NULL,
  "ns_term_enddate" date NOT NULL,
  PRIMARY KEY ("ns_term_id")
);
