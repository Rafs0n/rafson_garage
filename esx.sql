ALTER TABLE `owned_vehicles`
ADD COLUMN `favorite` TINYINT(1) NOT NULL DEFAULT 0 AFTER `stored`;

ALTER TABLE owned_vehicles ADD COLUMN `vin` varchar(50) DEFAULT NULL;