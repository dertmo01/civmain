-- ============================================================================
-- CIVILWATCH — Canonical Database Dump
-- ============================================================================
-- Source      : live development database (Termux / MariaDB 11)
-- Schema      : 15 tables — modern schema only (citizens, citizen_reports,
--               report_activities, citizen_notifications, government_offices,
--               announcements, otp_codes, ...). No legacy reports/notifications.
-- status enum : includes 'Rejected'  (required for the reject-with-notes flow)
--
-- HOW TO IMPORT — XAMPP on Windows
--   1. Start "MySQL" from the XAMPP Control Panel
--   2. Open http://localhost/phpmyadmin
--   3. Click the "Import" tab
--   4. Choose this file:  civilwatch_FINAL.sql
--   5. Click "Go"
--   6. Done. The file creates the database for you.
--
-- DEFAULT ACCOUNTS — CHANGE THEIR PASSWORDS IMMEDIATELY AFTER IMPORT
--   Super Admin :  admin@civilwatch.ph
--   CEO         :  ceo@civilwatch.ph
--   Citizen     :  +639171234567
--   The seeded passwords/PIN were published in earlier versions of this
--   file, so treat them as public. Never import this dump on a server that
--   is reachable by others without rotating them first.
--
-- ALTERNATIVE (no SQL import)
--   composer setup       -> copies .env, key:generate, migrate --seed,
--                           storage:link
--
-- See docs/SETUP_PC.md for the full walkthrough.
-- ============================================================================

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

CREATE DATABASE IF NOT EXISTS `civilwatch`
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE `civilwatch`;

/*M!999999\- enable the sandbox mode */ 
-- MariaDB dump 10.20-13.0.2-MariaDB, for Android (aarch64)
--
-- Host: localhost    Database: civilwatch
-- ------------------------------------------------------
-- Server version	13.0.2-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*M!100616 SET @OLD_NOTE_VERBOSITY=@@NOTE_VERBOSITY, NOTE_VERBOSITY=0 */;

--
-- Table structure for table `announcements`
--

DROP TABLE IF EXISTS `announcements`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `announcements` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL,
  `body` text NOT NULL,
  `is_published` tinyint(1) NOT NULL DEFAULT 1,
  `published_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `announcements`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `announcements` WRITE;
/*!40000 ALTER TABLE `announcements` DISABLE KEYS */;
INSERT INTO `announcements` VALUES
(1,'Keep Digos City Clean and Safe!','Let\'s work together for a better community. Report any infrastructure or environmental concerns through the CivilWatch app.',1,'2026-10-04 06:10:27','2026-10-06 06:10:27','2026-10-06 06:10:27'),
(2,'Road Repair Schedule — Barangay San Miguel','Road repairs will be conducted from July 18–20, 2026. Expect partial road closures. Please use alternate routes.',1,'2026-10-02 06:10:27','2026-10-06 06:10:27','2026-10-06 06:10:27');
/*!40000 ALTER TABLE `announcements` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `cache`
--

DROP TABLE IF EXISTS `cache`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `cache` (
  `key` varchar(255) NOT NULL,
  `value` mediumtext NOT NULL,
  `expiration` int(11) NOT NULL,
  PRIMARY KEY (`key`),
  KEY `cache_expiration_index` (`expiration`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cache`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `cache` WRITE;
/*!40000 ALTER TABLE `cache` DISABLE KEYS */;
/*!40000 ALTER TABLE `cache` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `cache_locks`
--

DROP TABLE IF EXISTS `cache_locks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `cache_locks` (
  `key` varchar(255) NOT NULL,
  `owner` varchar(255) NOT NULL,
  `expiration` int(11) NOT NULL,
  PRIMARY KEY (`key`),
  KEY `cache_locks_expiration_index` (`expiration`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cache_locks`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `cache_locks` WRITE;
/*!40000 ALTER TABLE `cache_locks` DISABLE KEYS */;
/*!40000 ALTER TABLE `cache_locks` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `citizen_notifications`
--

DROP TABLE IF EXISTS `citizen_notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `citizen_notifications` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `citizen_id` bigint(20) unsigned NOT NULL,
  `title` varchar(100) NOT NULL,
  `message` text NOT NULL,
  `type` varchar(50) NOT NULL DEFAULT 'status_update',
  `citizen_report_id` bigint(20) unsigned DEFAULT NULL,
  `reference_number` varchar(20) DEFAULT NULL,
  `status` varchar(50) DEFAULT NULL,
  `is_read` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `citizen_notifications_citizen_id_foreign` (`citizen_id`),
  KEY `citizen_notifications_citizen_report_id_foreign` (`citizen_report_id`),
  CONSTRAINT `citizen_notifications_citizen_id_foreign` FOREIGN KEY (`citizen_id`) REFERENCES `citizens` (`id`) ON DELETE CASCADE,
  CONSTRAINT `citizen_notifications_citizen_report_id_foreign` FOREIGN KEY (`citizen_report_id`) REFERENCES `citizen_reports` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `citizen_notifications`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `citizen_notifications` WRITE;
/*!40000 ALTER TABLE `citizen_notifications` DISABLE KEYS */;
INSERT INTO `citizen_notifications` VALUES
(1,1,'Pending Validation','CW-2026-00001 is now under review by the administrator.','status_update',1,'CW-2026-00001','Pending Validation',0,'2026-10-06 06:15:02'),
(2,1,'Pending Validation','CW-2026-00002 is now under review by the administrator.','status_update',2,'CW-2026-00002','Pending Validation',0,'2026-10-06 06:15:10'),
(3,1,'Pending Validation','CW-2026-00003 is now under review by the administrator.','status_update',3,'CW-2026-00003','Pending Validation',0,'2026-10-06 06:15:22'),
(4,1,'Assigned to Office','CW-2026-00002 has been assigned to City Engineering Office.','status_update',2,'CW-2026-00002','Assigned to Office',0,'2026-10-06 07:43:04'),
(5,1,'Rejected','CW-2026-00003 — Rejected. No reason was given by the administrator.','status_update',3,'CW-2026-00003','Rejected',0,'2026-10-06 10:30:52'),
(6,1,'Rejected','CW-2026-00001 — Rejected. Duplicate report - same issue already tracked under CW-2026-00003.','status_update',1,'CW-2026-00001','Rejected',0,'2026-10-06 10:31:39');
/*!40000 ALTER TABLE `citizen_notifications` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `citizen_reports`
--

DROP TABLE IF EXISTS `citizen_reports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `citizen_reports` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `reference_number` varchar(20) NOT NULL,
  `citizen_id` bigint(20) unsigned NOT NULL,
  `category` enum('Infrastructure','Environment','Others') NOT NULL,
  `concern` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `street` varchar(255) DEFAULT NULL,
  `purok` varchar(100) DEFAULT NULL,
  `barangay` varchar(100) NOT NULL,
  `city` varchar(100) NOT NULL DEFAULT 'Digos City',
  `province` varchar(100) NOT NULL DEFAULT 'Davao del Sur',
  `landmark` varchar(255) DEFAULT NULL,
  `lat` decimal(10,7) DEFAULT NULL,
  `lng` decimal(10,7) DEFAULT NULL,
  `severity` enum('Minor','Moderate','Severe') NOT NULL DEFAULT 'Moderate',
  `photo_url` varchar(500) DEFAULT NULL,
  `status` enum('Submitted','Pending Validation','Approved','Assigned to Office','In Progress','Resolved','Rejected') NOT NULL DEFAULT 'Submitted',
  `assigned_office_id` bigint(20) unsigned DEFAULT NULL,
  `resolved_at` timestamp NULL DEFAULT NULL,
  `is_public` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `citizen_reports_reference_number_unique` (`reference_number`),
  KEY `citizen_reports_citizen_id_foreign` (`citizen_id`),
  KEY `citizen_reports_assigned_office_id_foreign` (`assigned_office_id`),
  CONSTRAINT `citizen_reports_assigned_office_id_foreign` FOREIGN KEY (`assigned_office_id`) REFERENCES `government_offices` (`id`) ON DELETE SET NULL,
  CONSTRAINT `citizen_reports_citizen_id_foreign` FOREIGN KEY (`citizen_id`) REFERENCES `citizens` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `citizen_reports`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `citizen_reports` WRITE;
/*!40000 ALTER TABLE `citizen_reports` DISABLE KEYS */;
INSERT INTO `citizen_reports` VALUES
(1,'CW-2026-00001',1,'Infrastructure','Fallen power line','Low-hanging live wire over the market road.',NULL,NULL,'San Jose','Digos City','Davao del Sur',NULL,6.7567000,125.3545000,'Moderate',NULL,'Rejected',NULL,NULL,0,'2026-10-06 06:15:02','2026-10-06 10:31:39'),
(2,'CW-2026-00002',1,'Infrastructure','Fallen power line','Low-hanging live wire over the market road.',NULL,NULL,'San Jose','Digos City','Davao del Sur',NULL,6.7567000,125.3545000,'Moderate',NULL,'Assigned to Office',1,NULL,1,'2026-10-06 06:15:10','2026-10-06 07:43:04'),
(3,'CW-2026-00003',1,'Infrastructure','Street flooding','Drainage clogged causing knee-deep water.',NULL,NULL,'San Jose','Digos City','Davao del Sur',NULL,6.7567000,125.3545000,'Severe',NULL,'Rejected',NULL,NULL,0,'2026-10-06 06:15:22','2026-10-06 10:30:52');
/*!40000 ALTER TABLE `citizen_reports` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `citizens`
--

DROP TABLE IF EXISTS `citizens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `citizens` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `full_name` varchar(150) NOT NULL,
  `email` varchar(191) DEFAULT NULL,
  `phone` varchar(20) NOT NULL,
  `barangay` varchar(100) NOT NULL,
  `city` varchar(100) NOT NULL DEFAULT 'Digos City',
  `pin_hash` varchar(255) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `citizens_phone_unique` (`phone`),
  UNIQUE KEY `citizens_email_unique` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `citizens`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `citizens` WRITE;
/*!40000 ALTER TABLE `citizens` DISABLE KEYS */;
INSERT INTO `citizens` VALUES
(1,'Juan Dela Cruz','juan@example.com','639171234567','San Jose','Digos City','$2y$12$Fgls1cN1kMzjcer2sMM65OsCfh9VmVBHrRZxrMGUWQIArFxYsTGOa',1,'2026-10-06 06:15:01','2026-10-06 06:15:01');
/*!40000 ALTER TABLE `citizens` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `failed_jobs`
--

DROP TABLE IF EXISTS `failed_jobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `failed_jobs` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varchar(255) NOT NULL,
  `connection` text NOT NULL,
  `queue` text NOT NULL,
  `payload` longtext NOT NULL,
  `exception` longtext NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `failed_jobs`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `failed_jobs` WRITE;
/*!40000 ALTER TABLE `failed_jobs` DISABLE KEYS */;
/*!40000 ALTER TABLE `failed_jobs` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `government_offices`
--

DROP TABLE IF EXISTS `government_offices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `government_offices` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `abbreviation` varchar(20) NOT NULL,
  `phone` varchar(30) DEFAULT NULL,
  `email` varchar(191) DEFAULT NULL,
  `address` varchar(500) DEFAULT NULL,
  `handles` enum('Infrastructure','Environment','Both') NOT NULL DEFAULT 'Both',
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `government_offices`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `government_offices` WRITE;
/*!40000 ALTER TABLE `government_offices` DISABLE KEYS */;
INSERT INTO `government_offices` VALUES
(1,'City Engineering Office','CEO','+63 82 553 0001','ceo@digos.gov.ph','City Hall Complex, Digos City, Davao del Sur','Infrastructure',1,'2026-10-06 06:10:26','2026-10-06 06:10:26'),
(2,'City Environment and Natural Resources Office','CENRO','+63 82 553 0002','cenro@digos.gov.ph','City Hall Complex, Digos City, Davao del Sur','Environment',1,'2026-10-06 06:10:26','2026-10-06 06:10:26'),
(3,'City Public Works Department','CPWD','+63 82 553 0003','cpwd@digos.gov.ph','City Hall Complex, Digos City, Davao del Sur','Both',1,'2026-10-06 06:10:26','2026-10-06 06:10:26'),
(4,'Digos City Disaster Risk Reduction and Management Office','CDRRMO','+63 82 553 0004','cdrrmo@digos.gov.ph','City Hall Complex, Digos City, Davao del Sur','Both',1,'2026-10-06 06:10:26','2026-10-06 06:10:26'),
(5,'City Veterinary Office','CVO','+63 82 553 0005','cvo@digos.gov.ph','City Hall Complex, Digos City, Davao del Sur','Both',1,'2026-10-06 06:10:26','2026-10-06 06:10:26');
/*!40000 ALTER TABLE `government_offices` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `job_batches`
--

DROP TABLE IF EXISTS `job_batches`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `job_batches` (
  `id` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `total_jobs` int(11) NOT NULL,
  `pending_jobs` int(11) NOT NULL,
  `failed_jobs` int(11) NOT NULL,
  `failed_job_ids` longtext NOT NULL,
  `options` mediumtext DEFAULT NULL,
  `cancelled_at` int(11) DEFAULT NULL,
  `created_at` int(11) NOT NULL,
  `finished_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `job_batches`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `job_batches` WRITE;
/*!40000 ALTER TABLE `job_batches` DISABLE KEYS */;
/*!40000 ALTER TABLE `job_batches` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `jobs`
--

DROP TABLE IF EXISTS `jobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `jobs` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `queue` varchar(255) NOT NULL,
  `payload` longtext NOT NULL,
  `attempts` tinyint(3) unsigned NOT NULL,
  `reserved_at` int(10) unsigned DEFAULT NULL,
  `available_at` int(10) unsigned NOT NULL,
  `created_at` int(10) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `jobs_queue_index` (`queue`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jobs`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `jobs` WRITE;
/*!40000 ALTER TABLE `jobs` DISABLE KEYS */;
/*!40000 ALTER TABLE `jobs` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `migrations`
--

DROP TABLE IF EXISTS `migrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `migrations` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `migration` varchar(255) NOT NULL,
  `batch` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `migrations`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `migrations` WRITE;
/*!40000 ALTER TABLE `migrations` DISABLE KEYS */;
INSERT INTO `migrations` VALUES
(1,'0001_01_01_000000_create_users_table',1),
(2,'0001_01_01_000001_create_cache_table',1),
(3,'0001_01_01_000002_create_jobs_table',1),
(4,'2025_01_01_000010_create_personal_access_tokens_table',1),
(5,'2026_01_01_000001_create_citizens_table',1),
(6,'2026_01_01_000002_create_otp_codes_table',1),
(7,'2026_01_01_000003_create_government_offices_table',1),
(8,'2026_01_01_000004_create_citizen_reports_table',1),
(9,'2026_01_01_000005_create_report_activities_table',1),
(10,'2026_01_01_000006_create_citizen_notifications_table',1),
(11,'2026_01_01_000007_create_announcements_table',1),
(12,'2026_10_06_000001_add_rejected_status_to_citizen_reports',2);
/*!40000 ALTER TABLE `migrations` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `otp_codes`
--

DROP TABLE IF EXISTS `otp_codes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `otp_codes` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `phone` varchar(20) NOT NULL,
  `code` varchar(10) NOT NULL,
  `is_used` tinyint(1) NOT NULL DEFAULT 0,
  `expires_at` timestamp NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `otp_codes_phone_index` (`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `otp_codes`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `otp_codes` WRITE;
/*!40000 ALTER TABLE `otp_codes` DISABLE KEYS */;
/*!40000 ALTER TABLE `otp_codes` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `personal_access_tokens`
--

DROP TABLE IF EXISTS `personal_access_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `personal_access_tokens` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `tokenable_type` varchar(255) NOT NULL,
  `tokenable_id` bigint(20) unsigned NOT NULL,
  `name` varchar(255) NOT NULL,
  `token` varchar(64) NOT NULL,
  `abilities` text DEFAULT NULL,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `personal_access_tokens_token_unique` (`token`),
  KEY `personal_access_tokens_tokenable_type_tokenable_id_index` (`tokenable_type`,`tokenable_id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `personal_access_tokens`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `personal_access_tokens` WRITE;
/*!40000 ALTER TABLE `personal_access_tokens` DISABLE KEYS */;
-- personal_access_tokens is intentionally empty: a fresh install should
-- have nobody logged in. Tokens are issued when you log in.
/*!40000 ALTER TABLE `personal_access_tokens` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `report_activities`
--

DROP TABLE IF EXISTS `report_activities`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `report_activities` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `citizen_report_id` bigint(20) unsigned NOT NULL,
  `title` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `status` varchar(50) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `report_activities_citizen_report_id_foreign` (`citizen_report_id`),
  CONSTRAINT `report_activities_citizen_report_id_foreign` FOREIGN KEY (`citizen_report_id`) REFERENCES `citizen_reports` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `report_activities`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `report_activities` WRITE;
/*!40000 ALTER TABLE `report_activities` DISABLE KEYS */;
INSERT INTO `report_activities` VALUES
(1,1,'Report Submitted','Your report has been successfully submitted.','Submitted','2026-10-06 06:15:02'),
(2,1,'Pending Validation','Your report is now waiting for validation by the administrator.','Pending Validation','2026-10-06 06:15:02'),
(3,2,'Report Submitted','Your report has been successfully submitted.','Submitted','2026-10-06 06:15:10'),
(4,2,'Pending Validation','Your report is now waiting for validation by the administrator.','Pending Validation','2026-10-06 06:15:10'),
(5,3,'Report Submitted','Your report has been successfully submitted.','Submitted','2026-10-06 06:15:22'),
(6,3,'Pending Validation','Your report is now waiting for validation by the administrator.','Pending Validation','2026-10-06 06:15:22'),
(7,2,'Assigned to Office','Your report has been assigned to City Engineering Office.','Assigned to Office','2026-10-06 07:43:04'),
(8,3,'Rejected','Your report was rejected by the administrator.','Rejected','2026-10-06 10:30:52'),
(9,1,'Rejected','Duplicate report - same issue already tracked under CW-2026-00003.','Rejected','2026-10-06 10:31:39');
/*!40000 ALTER TABLE `report_activities` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(120) NOT NULL,
  `email` varchar(191) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` enum('super_admin','ceo','cenro') NOT NULL DEFAULT 'ceo',
  `office` varchar(100) DEFAULT NULL,
  `avatar_url` varchar(500) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `last_login_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_users_email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES
(1,'Super Administrator','admin@civilwatch.ph','$2y$12$YQpN2zV2Al1.P.k0cLtUdukIvVaV40g9quBiOZK6r0ZQ4pdsNIiqm','super_admin',NULL,NULL,1,NULL,'2026-10-06 06:10:26','2026-10-06 06:10:26'),
(2,'CEO Test Account','ceo@civilwatch.ph','$2y$12$uM7JeKwE1T.CIVCFwdHR4e6UuRBrQ2A5ItblJBhk2TqdlUR/XWiqq','ceo',NULL,NULL,1,NULL,'2026-10-06 10:54:39','2026-10-06 10:54:39');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Dumping routines for database 'civilwatch'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*M!100616 SET NOTE_VERBOSITY=@OLD_NOTE_VERBOSITY */;

-- Dump completed on 2026-10-07 18:06:39
-- ============================================================================
-- END OF DUMP
-- ============================================================================
-- RESET AUTO_INCREMENT on tables that got no explicit ids is not needed —
-- all auto_increment counters were dumped with their current values.
--
-- VERIFY AFTER IMPORT (in phpMyAdmin -> SQL tab):
--   SELECT COUNT(*) FROM information_schema.TABLES
--    WHERE TABLE_SCHEMA = 'civilwatch';          -- expect 15
--   SELECT COLUMN_TYPE FROM information_schema.COLUMNS
--    WHERE TABLE_SCHEMA = 'civilwatch'
--      AND TABLE_NAME  = 'citizen_reports'
--      AND COLUMN_NAME = 'status';               -- must contain 'Approved','Rejected'
--
-- NEXT STEP
--   .env:  DB_CONNECTION=mysql, DB_DATABASE=civilwatch, DB_USERNAME=root
--   run:   php artisan serve --host=127.0.0.1 --port=8000
--   admin: http://127.0.0.1:8000/admin/login
-- ============================================================================

SET FOREIGN_KEY_CHECKS = 1;
COMMIT;
