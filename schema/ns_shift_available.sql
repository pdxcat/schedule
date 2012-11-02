DROP TABLE IF EXISTS "ns_shift_available";
CREATE TABLE "ns_shift_available" (
  "ns_sv_id" int(11) NOT NULL AUTO_INCREMENT,
  "ns_sv_pref" int(11) NOT NULL,
  "ns_cat_id" int(11) NOT NULL,
  "ns_shift_id" int(11) NOT NULL,
  "ns_sv_timestamp" datetime NOT NULL,
  PRIMARY KEY ("ns_sv_id")
);
