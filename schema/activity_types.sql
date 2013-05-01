-- Licensed to the Computer Action Team (CAT) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The CAT licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--   http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing,
-- software distributed under the License is distributed on an
-- "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
-- KIND, either express or implied.  See the License for the
-- specific language governing permissions and limitations
-- under the License.

DROP TABLE IF EXISTS 'activity_types';
CREATE TABLE 'activity_types' (
  'id' INTEGER NOT NULL AUTO_INCREMENT,
  'name' varchar(40) NOT NULL,
  PRIMARY KEY ('id'),
  UNIQUE KEY ('name')
);
INSERT INTO activity_types (name) VALUES ('Handle Change');
