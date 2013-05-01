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

DROP TABLE IF EXISTS "ns_shift_available";
CREATE TABLE "ns_shift_available" (
  "ns_sv_id" int(11) NOT NULL AUTO_INCREMENT,
  "ns_sv_pref" int(11) NOT NULL,
  "ns_cat_id" int(11) NOT NULL,
  "ns_shift_id" int(11) NOT NULL,
  "ns_sv_timestamp" datetime NOT NULL,
  PRIMARY KEY ("ns_sv_id")
);
