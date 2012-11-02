DROP TABLE IF EXISTS "ns_holiday";
CREATE TABLE "ns_holiday" (
  "ns_holiday_id" int(11) NOT NULL AUTO_INCREMENT,
  "ns_holiday_name" varchar(80) NOT NULL,
  "ns_holiday_date" date NOT NULL,
  "ns_holiday_excused" int(11) NOT NULL DEFAULT '1',
  PRIMARY KEY ("ns_holiday_id")
);
