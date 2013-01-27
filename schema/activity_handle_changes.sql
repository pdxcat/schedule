DROP TABLE IF EXISTS 'activity_handle_changes';
CREATE TABLE 'activity_handle_changes' (
  'activity_id' INTEGER NOT NULL,
  'old_handle' VARCHAR(20) NOT NULL,
  'new_handle' VARCHAR(20) NOT NULL,
  PRIMARY KEY ('activity_id'),
  FOREIGN KEY ('activity_id') REFERENCES activity ('id')
);
