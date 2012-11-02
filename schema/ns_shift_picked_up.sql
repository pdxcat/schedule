DROP TABLE IF EXISTS "ns_shift_picked_up";
CREATE TABLE "ns_shift_picked_up" (
  "ns_spu_id" int(11) NOT NULL AUTO_INCREMENT,
  "ns_spu_timestamp" datetime NOT NULL,
  "ns_sd_id" int(11) NOT NULL,
  "ns_cat_id" int(11) NOT NULL,
  "ns_sa_id" int(11) NOT NULL,
  PRIMARY KEY ("ns_spu_id"),
  UNIQUE KEY "ns_sd_id" ("ns_sd_id","ns_sa_id")
);
