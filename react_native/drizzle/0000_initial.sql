CREATE TABLE `accounts` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`username` text NOT NULL,
	`display_name` text NOT NULL,
	`farm_name` text,
	`email` text,
	`password_hash` text NOT NULL,
	`password_salt` text NOT NULL,
	`hash_iterations` integer NOT NULL,
	`created_at` integer NOT NULL,
	`last_login_at` integer
);
--> statement-breakpoint
CREATE UNIQUE INDEX `accounts_username_unique` ON `accounts` (`username`);--> statement-breakpoint
CREATE TABLE `alerts` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`kind` text NOT NULL,
	`severity` text NOT NULL,
	`title` text NOT NULL,
	`body` text NOT NULL,
	`raised_at` integer NOT NULL,
	`batch_code` text,
	`acknowledged` integer DEFAULT false NOT NULL
);
--> statement-breakpoint
CREATE INDEX `alerts_raised_at_idx` ON `alerts` (`raised_at`);--> statement-breakpoint
CREATE TABLE `batches` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`code` text NOT NULL,
	`started_at` integer NOT NULL,
	`ended_at` integer,
	`account_id` integer,
	`device_id` text,
	`device_name` text,
	`stage` text DEFAULT 'idle' NOT NULL,
	`machine_status` text DEFAULT 'connected' NOT NULL,
	`reading_count` integer DEFAULT 0 NOT NULL,
	`ph` real,
	`moisture` real,
	`temperature_c` real,
	`electrical_conductivity` real,
	`turbidity` real,
	`weight_kg` real,
	`flow_lpm` real,
	`color_r` integer,
	`color_g` integer,
	`color_b` integer,
	`color_pfund` real,
	`color_label` text,
	`assessment` text DEFAULT 'incomplete' NOT NULL,
	`recommendation` text DEFAULT 'awaitingData' NOT NULL,
	`summary` text,
	`results_json` text,
	`notes` text
);
--> statement-breakpoint
CREATE UNIQUE INDEX `batches_code_unique` ON `batches` (`code`);--> statement-breakpoint
CREATE INDEX `batches_started_at_idx` ON `batches` (`started_at`);--> statement-breakpoint
CREATE TABLE `readings` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`batch_code` text,
	`recorded_at` integer NOT NULL,
	`ph` real,
	`moisture` real,
	`temperature_c` real,
	`electrical_conductivity` real,
	`turbidity` real,
	`weight_kg` real,
	`flow_lpm` real,
	`color_r` integer,
	`color_g` integer,
	`color_b` integer,
	`color_pfund` real,
	`color_label` text,
	`stage` text DEFAULT 'idle' NOT NULL,
	`machine_status` text DEFAULT 'connected' NOT NULL,
	`device_id` text,
	`device_name` text
);
--> statement-breakpoint
CREATE INDEX `readings_batch_code_idx` ON `readings` (`batch_code`);--> statement-breakpoint
CREATE INDEX `readings_recorded_at_idx` ON `readings` (`recorded_at`);--> statement-breakpoint
CREATE TABLE `thresholds` (
	`parameter` text PRIMARY KEY NOT NULL,
	`min_value` real,
	`max_value` real,
	`warn_min` real,
	`warn_max` real,
	`rated` integer DEFAULT true NOT NULL,
	`source` text DEFAULT 'operatorEdited' NOT NULL,
	`updated_at` integer NOT NULL
);
