DROP TABLE IF EXISTS "schedAvailThurs";
CREATE TABLE "schedAvailThurs" (
  "day" char(5) NOT NULL DEFAULT 'thurs',
  "username" char(8) NOT NULL,
  "08" enum('a','p','x') DEFAULT 'x',
  "09" enum('a','p','x') DEFAULT 'x',
  "10" enum('a','p','x') DEFAULT 'x',
  "11" enum('a','p','x') DEFAULT 'x',
  "12" enum('a','p','x') DEFAULT 'x',
  "13" enum('a','p','x') DEFAULT 'x',
  "14" enum('a','p','x') DEFAULT 'x',
  "15" enum('a','p','x') DEFAULT 'x',
  "16" enum('a','p','x') DEFAULT 'x',
  "17" enum('a','p','x') DEFAULT 'x',
  PRIMARY KEY ("username")
);