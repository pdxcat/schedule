DROP TABLE IF EXISTS "schedAvailSat";
CREATE TABLE "schedAvailSat" (
  "day" char(3) NOT NULL DEFAULT 'sat',
  "username" char(8) NOT NULL,
  "08" enum('a','p','x') NOT NULL DEFAULT 'x',
  "09" enum('a','p','x') NOT NULL DEFAULT 'x',
  "10" enum('a','p','x') NOT NULL DEFAULT 'x',
  "11" enum('a','p','x') NOT NULL DEFAULT 'x',
  "12" enum('a','p','x') NOT NULL DEFAULT 'x',
  "13" enum('a','p','x') NOT NULL DEFAULT 'x',
  "14" enum('a','p','x') NOT NULL DEFAULT 'x',
  "15" enum('a','p','x') NOT NULL DEFAULT 'x',
  "16" enum('a','p','x') NOT NULL DEFAULT 'x',
  "17" enum('a','p','x') NOT NULL DEFAULT 'x',
  PRIMARY KEY ("username")
);
