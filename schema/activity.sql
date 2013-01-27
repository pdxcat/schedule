DROP TABLE IF EXISTS 'activity';
CREATE TABLE 'activity' (
  'id' INTEGER NOT NULL AUTO_INCREMENT,
  'event_time' TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  'cat_id' INTEGER NOT NULL,
  'type_id' INTEGER NOT NULL,
  PRIMARY KEY ('id'),
  FOREIGN KEY ('cat_id') REFERENCES ns_cat ('ns_cat_id'),
  FOREIGN KEY ('type_id') REFERENCES activity_types ('id')
);
