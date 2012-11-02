DROP VIEW IF EXISTS `AVAILABILITY`;
CREATE VIEW `AVAILABILITY` AS (
 SELECT `schedAvailMon`.`day` AS `day`,
        `schedAvailMon`.`username` AS `username`,
        `schedAvailMon`.`08` AS `08`,
        `schedAvailMon`.`09` AS `09`,
        `schedAvailMon`.`10` AS `10`,
        `schedAvailMon`.`11` AS `11`,
        `schedAvailMon`.`12` AS `12`,
        `schedAvailMon`.`13` AS `13`,
        `schedAvailMon`.`14` AS `14`,
        `schedAvailMon`.`15` AS `15`,
        `schedAvailMon`.`16` AS `16`,
        `schedAvailMon`.`17` AS `17`
   FROM `schedAvailMon`
) UNION (
 SELECT `schedAvailTues`.`day` AS `day`,
        `schedAvailTues`.`username` AS `username`,
        `schedAvailTues`.`08` AS `08`,
        `schedAvailTues`.`09` AS `09`,
        `schedAvailTues`.`10` AS `10`,
        `schedAvailTues`.`11` AS `11`,
        `schedAvailTues`.`12` AS `12`,
        `schedAvailTues`.`13` AS `13`,
        `schedAvailTues`.`14` AS `14`,
        `schedAvailTues`.`15` AS `15`,
        `schedAvailTues`.`16` AS `16`,
        `schedAvailTues`.`17` AS `17`
   FROM `schedAvailTues`
) UNION (
 SELECT `schedAvailWed`.`day` AS `day`,
        `schedAvailWed`.`username` AS `username`,
        `schedAvailWed`.`08` AS `08`,
        `schedAvailWed`.`09` AS `09`,
        `schedAvailWed`.`10` AS `10`,
        `schedAvailWed`.`11` AS `11`,
        `schedAvailWed`.`12` AS `12`,
        `schedAvailWed`.`13` AS `13`,
        `schedAvailWed`.`14` AS `14`,
        `schedAvailWed`.`15` AS `15`,
        `schedAvailWed`.`16` AS `16`,
        `schedAvailWed`.`17` AS `17`
   FROM `schedAvailWed`
) UNION (
 SELECT `schedAvailThurs`.`day` AS `day`,
        `schedAvailThurs`.`username` AS `username`,
        `schedAvailThurs`.`08` AS `08`,
        `schedAvailThurs`.`09` AS `09`,
        `schedAvailThurs`.`10` AS `10`,
        `schedAvailThurs`.`11` AS `11`,
        `schedAvailThurs`.`12` AS `12`,
        `schedAvailThurs`.`13` AS `13`,
        `schedAvailThurs`.`14` AS `14`,
        `schedAvailThurs`.`15` AS `15`,
        `schedAvailThurs`.`16` AS `16`,
        `schedAvailThurs`.`17` AS `17`
   FROM `schedAvailThurs`
) UNION (
 SELECT `schedAvailFri`.`day` AS `day`,
        `schedAvailFri`.`username` AS `username`,
        `schedAvailFri`.`08` AS `08`,
        `schedAvailFri`.`09` AS `09`,
        `schedAvailFri`.`10` AS `10`,
        `schedAvailFri`.`11` AS `11`,
        `schedAvailFri`.`12` AS `12`,
        `schedAvailFri`.`13` AS `13`,
        `schedAvailFri`.`14` AS `14`,
        `schedAvailFri`.`15` AS `15`,
        `schedAvailFri`.`16` AS `16`,
        `schedAvailFri`.`17` AS `17`
   FROM `schedAvailFri`
) UNION (
 SELECT `schedAvailSat`.`day` AS `day`,
        `schedAvailSat`.`username` AS `username`,
        `schedAvailSat`.`08` AS `08`,
        `schedAvailSat`.`09` AS `09`,
        `schedAvailSat`.`10` AS `10`,
        `schedAvailSat`.`11` AS `11`,
        `schedAvailSat`.`12` AS `12`,
        `schedAvailSat`.`13` AS `13`,
        `schedAvailSat`.`14` AS `14`,
        `schedAvailSat`.`15` AS `15`,
        `schedAvailSat`.`16` AS `16`,
        `schedAvailSat`.`17` AS `17`
   FROM `schedAvailSat`
);
