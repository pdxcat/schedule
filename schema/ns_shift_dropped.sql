DROP TABLE IF EXISTS "ns_shift_dropped";
CREATE TABLE "ns_shift_dropped" (
  "ns_sd_id" int(11) NOT NULL AUTO_INCREMENT,
  "ns_sa_id" int(11) NOT NULL,
  "ns_sd_droptime" datetime NOT NULL,
  PRIMARY KEY ("ns_sd_id"),
  KEY "ns_sa_id" ("ns_sa_id")
);
