ALTER TABLE `player_vehicles`
ADD COLUMN `favorite` TINYINT(1) NOT NULL DEFAULT 0 AFTER `state`;

ALTER TABLE player_vehicles ADD COLUMN `vin` varchar(50) DEFAULT NULL;