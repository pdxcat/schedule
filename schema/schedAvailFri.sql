DROP TABLE IF EXISTS "schedAvailFri";
CREATE TABLE "schedAvailFri" (
  "day" char(3) NOT NULL DEFAULT 'fri',
  "username" char(8) NOT NULL,
  "08" enum('a','p','u') NOT NULL DEFAULT 'u',
  "09" enum('a','p','u') NOT NULL DEFAULT 'u',
  "10" enum('a','p','u') NOT NULL DEFAULT 'u',
  "11" enum('a','p','u') NOT NULL DEFAULT 'u',
  "12" enum('a','p','u') NOT NULL DEFAULT 'u',
  "13" enum('a','p','u') NOT NULL DEFAULT 'u',
  "14" enum('a','p','u') NOT NULL DEFAULT 'u',
  "15" enum('a','p','u') NOT NULL DEFAULT 'u',
  "16" enum('a','p','u') NOT NULL DEFAULT 'u',
  "17" enum('a','p','u') NOT NULL DEFAULT 'u',
  PRIMARY KEY ("username")
);
