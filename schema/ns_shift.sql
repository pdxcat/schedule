DROP TABLE IF EXISTS "ns_shift";
CREATE TABLE "ns_shift" (
  "ns_shift_id" int(11) NOT NULL AUTO_INCREMENT,
  "ns_shift_date" date NOT NULL,
  "ns_shift_start_time" time NOT NULL,
  "ns_shift_end_time" time NOT NULL,
  PRIMARY KEY ("ns_shift_id")
);
