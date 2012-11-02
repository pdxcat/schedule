DROP TABLE IF EXISTS "ns_shift_assigned";
CREATE TABLE "ns_shift_assigned" (
  "ns_sa_id" int(11) NOT NULL AUTO_INCREMENT,
  "ns_shift_id" int(11) NOT NULL,
  "ns_cat_id" int(11) NOT NULL,
  "ns_desk_id" int(11) NOT NULL,
  "ns_sa_assignedtime" datetime NOT NULL,
  PRIMARY KEY ("ns_sa_id"),
  KEY "ns_cat_id" ("ns_cat_id")
);
