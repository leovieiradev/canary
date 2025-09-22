-- Migration: Add strain system field to players table
-- Date: 2024-01-XX
-- Description: Adds strain system persistence field for Uchiha clan system

ALTER TABLE `players` 
ADD COLUMN `strain_value` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Current strain value (0-100)' AFTER `boss_points`;

-- Update server config version if needed
-- UPDATE `server_config` SET `value` = '53' WHERE `config` = 'db_version';