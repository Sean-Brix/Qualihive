ALTER TABLE `batches` DROP COLUMN `moisture`;--> statement-breakpoint
ALTER TABLE `readings` DROP COLUMN `moisture`;--> statement-breakpoint
DELETE FROM `thresholds` WHERE `parameter` = 'moisture';
