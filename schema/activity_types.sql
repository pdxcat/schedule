DROP TABLE IF EXISTS 'activity_types';
CREATE TABLE 'activity_types' (
  'id' INTEGER NOT NULL AUTO_INCREMENT,
  'name' varchar(40) NOT NULL,
  PRIMARY KEY ('id'),
  UNIQUE KEY ('name')
);
INSERT INTO activity_types (name) VALUES ('Handle Change');
