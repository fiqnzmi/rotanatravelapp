-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Nov 06, 2025 at 02:25 PM
-- Server version: 5.7.44-cll-lve
-- PHP Version: 8.2.29

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `sabrisae_rotanatravel`
--

-- --------------------------------------------------------

--
-- Table structure for table `bookings`
--

CREATE TABLE `bookings` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `package_id` int(11) NOT NULL,
  `adults` int(11) NOT NULL DEFAULT '1',
  `children` int(11) NOT NULL DEFAULT '0',
  `status` enum('PENDING','CONFIRMED','CANCELLED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDING',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `departure_date` date DEFAULT NULL,
  `room_tier` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `deposit_paid` tinyint(1) NOT NULL DEFAULT '0',
  `briefing_done` tinyint(1) NOT NULL DEFAULT '0',
  `final_paid` tinyint(1) NOT NULL DEFAULT '0',
  `total_amount` decimal(10,2) NOT NULL DEFAULT '0.00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `bookings`
--

INSERT INTO `bookings` (`id`, `user_id`, `package_id`, `adults`, `children`, `status`, `created_at`, `departure_date`, `room_tier`, `deposit_paid`, `briefing_done`, `final_paid`, `total_amount`) VALUES
(16, 6, 7, 1, 0, 'CONFIRMED', '2025-11-04 19:24:50', NULL, NULL, 0, 0, 0, 2.00),
(17, 9, 1, 1, 0, 'CONFIRMED', '2025-11-05 00:43:22', NULL, NULL, 0, 0, 0, 0.00),
(18, 5, 7, 1, 0, 'CONFIRMED', '2025-11-05 03:41:53', NULL, NULL, 0, 0, 0, 2.00),
(22, 5, 6, 1, 0, 'CONFIRMED', '2025-11-05 13:01:56', NULL, NULL, 0, 0, 0, 2.00),
(23, 5, 3, 1, 0, 'CONFIRMED', '2025-11-05 14:40:40', NULL, NULL, 0, 0, 0, 2.00),
(24, 6, 6, 1, 0, 'CONFIRMED', '2025-11-05 21:05:11', NULL, NULL, 0, 0, 0, 2.00),
(25, 5, 3, 1, 0, 'CONFIRMED', '2025-11-05 21:07:02', NULL, NULL, 0, 0, 0, 2.00),
(26, 6, 6, 2, 0, 'CONFIRMED', '2025-11-05 21:07:08', NULL, NULL, 0, 0, 0, 4.00);

-- --------------------------------------------------------

--
-- Table structure for table `booking_travellers`
--

CREATE TABLE `booking_travellers` (
  `id` int(11) NOT NULL,
  `booking_id` int(11) NOT NULL,
  `full_name` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `passport_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `dob` date DEFAULT NULL,
  `gender` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `passport_issue_date` date DEFAULT NULL,
  `passport_expiry_date` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `booking_travellers`
--

INSERT INTO `booking_travellers` (`id`, `booking_id`, `full_name`, `passport_no`, `dob`, `gender`, `passport_issue_date`, `passport_expiry_date`) VALUES
(16, 16, 'Eryschia', 'abc123', '1995-11-04', 'female', NULL, NULL),
(17, 18, 'Muhammad Afiq Nazmi Bin Sulaiman', 'a123', '1995-11-05', 'male', NULL, NULL),
(21, 22, 'Muhammad Farhan Bin Mohd Fahimy', 'a123', '2003-06-11', 'male', NULL, NULL),
(22, 23, 'Muhammad Farhan Bin Mohd Fahimy', 'a123', '2003-06-11', 'male', NULL, NULL),
(23, 24, 'Asperl', '123', '1995-11-05', 'male', '2024-11-06', '2030-11-05'),
(24, 25, 'Muhammad Ammar Syahmi Bin Sulaiman', 'a345', '2025-11-05', 'male', '2024-11-05', '2030-11-05'),
(25, 26, 'Eryschia', 'abc123', '2025-11-05', 'female', '2025-11-04', '2025-11-29'),
(26, 26, 'Asperl', 'avb123', '1995-11-05', 'male', '2024-11-05', '2030-11-04');

-- --------------------------------------------------------

--
-- Table structure for table `documents`
--

CREATE TABLE `documents` (
  `id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `booking_id` int(11) DEFAULT NULL,
  `traveller_id` int(11) DEFAULT NULL,
  `doc_type` enum('PASSPORT','IC','VISA','TICKET','HOTEL_VOUCHER','INSURANCE','PAYMENT_PROOF','ITINERARY','OTHER') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'OTHER',
  `file_path` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `file_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `mime_type` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` enum('REQUIRED','PENDING','UNDER_REVIEW','APPROVED','ACTIVE','REJECTED','ARCHIVED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'REQUIRED',
  `uploaded_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `label` varchar(120) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `remarks` text COLLATE utf8mb4_unicode_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `documents`
--

INSERT INTO `documents` (`id`, `user_id`, `booking_id`, `traveller_id`, `doc_type`, `file_path`, `file_name`, `mime_type`, `status`, `uploaded_at`, `label`, `remarks`) VALUES
(1, 5, 18, NULL, 'PASSPORT', 'doc_18_5_1762417677.pdf', 'e-order_receipt_3324187589069677564_en_my.pdf', NULL, 'PENDING', '2025-11-06 08:27:57', 'PASSPORT', NULL),
(2, 5, 18, NULL, 'INSURANCE', 'doc_18_5_1762417886.pdf', 'e-order_receipt_3324187589069677564_en_my.pdf', 'application/pdf', 'PENDING', '2025-11-06 08:31:26', 'INSURANCE', NULL),
(3, 5, 18, NULL, 'VISA', 'doc_18_5_1762418741.pdf', 'e-order_receipt_3324187589069677564_en_my.pdf', 'application/pdf', 'PENDING', '2025-11-06 08:45:41', 'VISA', NULL),
(4, 5, 18, NULL, 'PAYMENT_PROOF', 'doc_18_5_1762418755.pdf', 'e-order_receipt_3324187589069677564_en_my.pdf', 'application/pdf', 'PENDING', '2025-11-06 08:45:55', 'PAYMENT_PROOF', NULL),
(5, 5, 18, NULL, 'OTHER', 'doc_18_5_1762418760.pdf', 'e-order_receipt_3324187589069677564_en_my.pdf', 'application/pdf', 'PENDING', '2025-11-06 08:46:00', 'OTHER', NULL),
(6, 5, 22, NULL, 'PASSPORT', NULL, NULL, NULL, 'REQUIRED', '2025-11-05 22:54:31', 'Passport', NULL),
(7, 5, 22, NULL, 'INSURANCE', NULL, NULL, NULL, 'REQUIRED', '2025-11-05 22:54:31', 'Travel Insurance', NULL),
(8, 5, 22, NULL, 'VISA', NULL, NULL, NULL, 'REQUIRED', '2025-11-05 22:54:31', 'Visa', NULL),
(9, 5, 22, NULL, 'PAYMENT_PROOF', NULL, NULL, NULL, 'REQUIRED', '2025-11-05 22:54:31', 'Payment Proof', NULL),
(10, 5, 22, NULL, 'OTHER', NULL, NULL, NULL, 'REQUIRED', '2025-11-05 22:54:31', 'Additional Document', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `family_members`
--

CREATE TABLE `family_members` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `full_name` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `relationship` enum('SPOUSE','CHILD','PARENT','SIBLING','FRIEND','OTHER') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'OTHER',
  `gender` enum('male','female') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `passport_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `dob` date DEFAULT NULL,
  `passport_issue_date` date DEFAULT NULL,
  `passport_expiry_date` date DEFAULT NULL,
  `nationality` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `phone` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `family_members`
--

INSERT INTO `family_members` (`id`, `user_id`, `full_name`, `relationship`, `gender`, `passport_no`, `dob`, `passport_issue_date`, `passport_expiry_date`, `nationality`, `phone`, `created_at`) VALUES
(1, 5, 'Muhammad Farhan Bin Mohd Fahimy', 'FRIEND', 'male', 'a123', '2003-06-11', '2025-11-04', '2030-11-04', 'Malaysia', '01110742871', '2025-11-04 20:16:47'),
(2, 5, 'Muhammad Ammar Syahmi Bin Sulaiman', 'SIBLING', 'male', 'a345', '2025-11-05', '2024-11-05', '2030-11-05', 'Malaysia', '01137136259', '2025-11-05 10:20:20'),
(3, 6, 'Eryschia', 'SPOUSE', 'female', 'abc123', '2025-11-05', '2025-11-04', '2025-11-29', 'MALAYSIA', '', '2025-11-05 21:06:08');

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `type` enum('PAYMENT','DOCS','BRIEFING','BOOKING','PROMO','GENERAL') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'GENERAL',
  `title` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `body` text COLLATE utf8mb4_unicode_ci,
  `is_important` tinyint(1) NOT NULL DEFAULT '0',
  `is_read` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `packages`
--

CREATE TABLE `packages` (
  `id` int(11) NOT NULL,
  `title` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `price` decimal(10,2) NOT NULL DEFAULT '0.00',
  `images_json` json DEFAULT NULL,
  `bill_url` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `duration_days` int(11) DEFAULT NULL,
  `cities` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `hotel_stars` tinyint(4) DEFAULT NULL,
  `rating_avg` decimal(2,1) DEFAULT NULL,
  `rating_count` int(11) DEFAULT NULL,
  `departures_json` json DEFAULT NULL,
  `inclusions_json` json DEFAULT NULL,
  `itinerary_json` json DEFAULT NULL,
  `faqs_json` json DEFAULT NULL,
  `required_docs_json` text COLLATE utf8mb4_unicode_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `packages`
--

INSERT INTO `packages` (`id`, `title`, `description`, `price`, `images_json`, `bill_url`, `created_at`, `duration_days`, `cities`, `hotel_stars`, `rating_avg`, `rating_count`, `departures_json`, `inclusions_json`, `itinerary_json`, `faqs_json`, `required_docs_json`) VALUES
(1, 'test', 'package', 1.00, '[\"uploads/packages/pkg_dfd83dd14145.jpg\"]', 'https://toyyibpay.com/7qr6lhrg', '2025-10-23 10:12:25', 7, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(3, 'holiday', 'testpackage', 2.00, '[\"uploads/packages/pkg_bbfe170f1803.jpg\"]', 'https://toyyibpay.com/7qr6lhrg', '2025-10-23 19:57:03', 14, 'Madinah', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(6, 'Test 4', 'test 4', 2.00, '[\"uploads/packages/pkg_5df3d4265444.jpg\"]', 'https://toyyibpay.com/khxeyzqb', '2025-10-24 05:05:41', 2, 'tak tahu', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(7, 'london', 'hjh', 2.00, NULL, 'https://toyyibpay.com/dhgnvogj', '2025-10-29 03:39:24', 7, 'london', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `password_resets`
--

CREATE TABLE `password_resets` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `token` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `code` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `used_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `password_resets`
--

INSERT INTO `password_resets` (`id`, `user_id`, `token`, `code`, `created_at`, `used_at`) VALUES
(1, 6, '1bfa83f5b3b8fede0707be646177a8b0', '927163', '2025-11-03 16:00:07', NULL),
(2, 6, '7543b9a5e29ab87a6fe516671c4b986f', '362020', '2025-11-03 16:13:03', NULL),
(3, 6, '56c1df979bfdc46afa6c79a1cd462a18', '927960', '2025-11-03 16:23:09', NULL),
(4, 6, 'be4b7cbd03b8e31059e421757d1e4b3c', '918360', '2025-11-03 16:23:34', NULL),
(5, 6, '8a7ce760005be243eeb469f9021565c4', '554459', '2025-11-03 17:05:18', NULL),
(6, 6, '8b0a58b7db6dff097e1a7912ecae8483', '749458', '2025-11-03 17:09:56', NULL),
(7, 6, '35e44f2c8dc72b245f8cb0e263999e52', '227858', '2025-11-04 01:20:37', '2025-11-04 01:22:08'),
(8, 7, '3759ffd430258a9f732bf957eceba5b1', '569695', '2025-11-04 12:09:22', '2025-11-04 12:10:17');

-- --------------------------------------------------------

--
-- Table structure for table `payments`
--

CREATE TABLE `payments` (
  `id` int(11) NOT NULL,
  `booking_id` int(11) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `currency` char(3) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'MYR',
  `method` enum('FPX','CARD','TRANSFER','CASH','EWALLET') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'TRANSFER',
  `status` enum('PENDING','PAID','FAILED','REFUNDED','CANCELLED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDING',
  `transaction_ref` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `gateway_payload` json DEFAULT NULL,
  `paid_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `payments`
--

INSERT INTO `payments` (`id`, `booking_id`, `amount`, `currency`, `method`, `status`, `transaction_ref`, `gateway_payload`, `paid_at`, `created_at`) VALUES
(1, 18, 2.00, 'MYR', 'FPX', 'PENDING', 'ml4kztik', '{\"bill\": {\"BillCode\": \"ml4kztik\"}, \"request\": {\"amount\": 2, \"external_ref\": \"BOOK-18-1762285319\", \"customer_name\": \"Muhammad Afiq\", \"customer_email\": \"muhammadafiqnazmi2003@gmail.com\", \"customer_phone\": \"01135363010\"}}', NULL, '2025-11-05 03:42:00'),
(2, 18, 2.00, 'MYR', 'FPX', 'PENDING', 'fnlemn05', '{\"bill\": {\"BillCode\": \"fnlemn05\"}, \"request\": {\"amount\": 2, \"external_ref\": \"BOOK-18-1762285350\", \"customer_name\": \"Muhammad Afiq\", \"customer_email\": \"muhammadafiqnazmi2003@gmail.com\", \"customer_phone\": \"01135363010\"}}', NULL, '2025-11-05 03:42:31'),
(3, 25, 2.00, 'MYR', 'FPX', 'PENDING', 't8iful6o', '{\"bill\": {\"BillCode\": \"t8iful6o\"}, \"request\": {\"amount\": 2, \"external_ref\": \"BOOK-25-1762416586\", \"customer_name\": \"Muhammad Afiq Nazmi Bin Sulaiman\", \"customer_email\": \"muhammadafiqnazmi2003@gmail.com\", \"customer_phone\": \"01135363010\"}}', NULL, '2025-11-06 16:09:47'),
(4, 23, 2.00, 'MYR', 'FPX', 'PENDING', 'qnfcmet7', '{\"bill\": {\"BillCode\": \"qnfcmet7\"}, \"request\": {\"amount\": 2, \"external_ref\": \"BOOK-23-1762416711\", \"customer_name\": \"Muhammad Afiq Nazmi Bin Sulaiman\", \"customer_email\": \"muhammadafiqnazmi2003@gmail.com\", \"customer_phone\": \"01135363010\"}}', NULL, '2025-11-06 16:11:52'),
(5, 23, 2.00, 'MYR', 'FPX', 'PENDING', 'sceflzvc', '{\"bill\": {\"BillCode\": \"sceflzvc\"}, \"request\": {\"amount\": 2, \"external_ref\": \"BOOK-23-1762416732\", \"customer_name\": \"Muhammad Afiq Nazmi Bin Sulaiman\", \"customer_email\": \"muhammadafiqnazmi2003@gmail.com\", \"customer_phone\": \"01135363010\"}}', NULL, '2025-11-06 16:12:13'),
(6, 25, 2.00, 'MYR', 'FPX', 'PENDING', 'owv7dcbd', '{\"bill\": {\"BillCode\": \"owv7dcbd\"}, \"request\": {\"amount\": 2, \"external_ref\": \"BOOK-25-1762429258\", \"customer_name\": \"Muhammad Afiq Nazmi Bin Sulaiman\", \"customer_email\": \"muhammadafiqnazmi2003@gmail.com\", \"customer_phone\": \"01135363010\"}}', NULL, '2025-11-06 19:40:59');

-- --------------------------------------------------------

--
-- Table structure for table `role`
--

CREATE TABLE `role` (
  `RoleID` int(11) NOT NULL,
  `RoleName` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `role`
--

INSERT INTO `role` (`RoleID`, `RoleName`) VALUES
(1, 'Admin'),
(2, 'Staff');

-- --------------------------------------------------------

--
-- Table structure for table `staff`
--

CREATE TABLE `staff` (
  `StaffID` int(11) NOT NULL,
  `Name` varchar(100) NOT NULL,
  `Email` varchar(100) NOT NULL,
  `Password` varchar(255) NOT NULL,
  `RoleID` int(11) DEFAULT NULL,
  `CreatedAt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `staff`
--

INSERT INTO `staff` (`StaffID`, `Name`, `Email`, `Password`, `RoleID`, `CreatedAt`) VALUES
(3, 'Rotana Admin', 'admin@rotana.test', '$2y$10$LkzBwLxhHJnAIvzyFXcZxuhY/C5xUh0HzSO.VxQpVXJmJQppI8ekq', 1, '2025-10-23 19:15:17'),
(4, 'Rotana Staff', 'staff@rotana.test', '$2y$10$SQjrmwSoxME3ZCsigJUOM.AD5RCAW1ojXWLiZ2r59yG85hDDzwip6', 2, '2025-10-23 19:15:17');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `username` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `gender` enum('male','female','other') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `dob` date DEFAULT NULL,
  `passport_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address` text COLLATE utf8mb4_unicode_ci,
  `notify_email` tinyint(1) NOT NULL DEFAULT '1',
  `notify_sms` tinyint(1) NOT NULL DEFAULT '0',
  `preferred_language` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `emergency_contact_id` int(11) DEFAULT NULL,
  `profile_photo` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `profile_photo_url` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `username`, `name`, `email`, `password_hash`, `phone`, `gender`, `dob`, `passport_no`, `address`, `notify_email`, `notify_sms`, `preferred_language`, `emergency_contact_id`, `profile_photo`, `profile_photo_url`, `created_at`) VALUES
(1, 'afiq', 'afiq', 'afiq@example.com', '$2y$10$rezod81V4ILNsK3Cmf11Feo8FlRqmO6Pb.0JXJY9udBNJ2QwBUXPi', NULL, NULL, NULL, NULL, NULL, 1, 0, 'en', NULL, NULL, NULL, '2025-10-23 09:41:58'),
(4, 'afiq2', 'afiq2', 'afiq2@example.com', '$2y$10$m/seoYYNQXgY0UFjEAz0a.TtB5qiaSp0CtebZ46PlsMWEjnezdYoO', NULL, NULL, NULL, NULL, NULL, 1, 0, 'en', NULL, NULL, NULL, '2025-10-23 09:47:08'),
(5, 'Muhammad Afiq', 'Muhammad Afiq Nazmi Bin Sulaiman', 'muhammadafiqnazmi2003@gmail.com', '$2y$10$2Q6Q9BGIS8HeUUf4.SF3IOKwgrM8Z4ntBEgI/N.Mmq7KASLx1CfdG', '01135363010', 'male', '2003-12-17', 'A12345', NULL, 1, 1, 'en', 2, 'uploads/profile_5_1762316253_9260e968.jpg', 'https://ruangprojek.com/rotanatravel/rotanatravelapi/api/../uploads/profile_5_1762316253_9260e968.jpg', '2025-10-23 09:47:42'),
(6, 'Assyabil', 'Assyabil', 'abilkry@gmail.com', '$2y$10$NIFNXbGErITAFUcPai68se7PQHsLa/7AlrFoqmLagnAfSkb2ka8Uu', NULL, NULL, NULL, NULL, NULL, 1, 0, 'en', NULL, NULL, NULL, '2025-10-24 16:50:11'),
(7, 'Afiq Nazmi', 'Afiq Nazmi', 'afiqnazmi17@icloud.com', '$2y$10$ymq6UL58EOS74ZLCgBlwx.Z3/2Cw3mnEaKqkEe6vo2KM/WEOHJFG2', NULL, NULL, NULL, NULL, NULL, 1, 0, 'en', NULL, NULL, NULL, '2025-10-27 23:17:12'),
(8, 'Muhammad Afiq Nazmi Bin Sulaiman', 'Muhammad Afiq Nazmi Bin Sulaiman', 'afiqnzmi@gmail.com', '$2y$10$ihYrNLR5FYFh.bcv9Upk8.FLsrwibO4p4I0cU6DrUcuDTQIo3iCVS', NULL, NULL, NULL, NULL, NULL, 1, 0, 'en', NULL, NULL, NULL, '2025-10-28 23:05:49'),
(9, 'Amier', 'Amier', 'cuteamier@gmail.com', '$2y$10$HMLA4GaC2uS/Tbe10gIPFuJ.R.DdLH2LYxNeBM3Aq42fIt7SHad.2', NULL, NULL, NULL, NULL, NULL, 1, 0, 'en', NULL, NULL, NULL, '2025-10-29 10:45:52');

-- --------------------------------------------------------

--
-- Table structure for table `user_settings`
--

CREATE TABLE `user_settings` (
  `user_id` int(11) NOT NULL,
  `settings_json` json NOT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_settings`
--

INSERT INTO `user_settings` (`user_id`, `settings_json`, `created_at`, `updated_at`) VALUES
(5, '{\"two_factor\": true, \"biometric_login\": true, \"trusted_devices\": true, \"personalized_recommendations\": true}', '2025-11-06 00:43:52', '2025-11-06 00:44:06');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `bookings`
--
ALTER TABLE `bookings`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `package_id` (`package_id`),
  ADD KEY `status` (`status`),
  ADD KEY `created_at` (`created_at`);

--
-- Indexes for table `booking_travellers`
--
ALTER TABLE `booking_travellers`
  ADD PRIMARY KEY (`id`),
  ADD KEY `booking_id` (`booking_id`);

--
-- Indexes for table `documents`
--
ALTER TABLE `documents`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `booking_id` (`booking_id`),
  ADD KEY `traveller_id` (`traveller_id`),
  ADD KEY `doc_type` (`doc_type`),
  ADD KEY `status` (`status`),
  ADD KEY `uploaded_at` (`uploaded_at`);

--
-- Indexes for table `family_members`
--
ALTER TABLE `family_members`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `relationship` (`relationship`),
  ADD KEY `full_name` (`full_name`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `type` (`type`),
  ADD KEY `is_read` (`is_read`),
  ADD KEY `created_at` (`created_at`);

--
-- Indexes for table `packages`
--
ALTER TABLE `packages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `title` (`title`);

--
-- Indexes for table `password_resets`
--
ALTER TABLE `password_resets`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_token` (`token`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `code` (`code`);

--
-- Indexes for table `payments`
--
ALTER TABLE `payments`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_transaction_ref` (`transaction_ref`),
  ADD KEY `booking_id` (`booking_id`),
  ADD KEY `status` (`status`),
  ADD KEY `created_at` (`created_at`);

--
-- Indexes for table `role`
--
ALTER TABLE `role`
  ADD PRIMARY KEY (`RoleID`);

--
-- Indexes for table `staff`
--
ALTER TABLE `staff`
  ADD PRIMARY KEY (`StaffID`),
  ADD UNIQUE KEY `Email` (`Email`),
  ADD KEY `RoleID` (`RoleID`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD UNIQUE KEY `username_unique` (`username`),
  ADD KEY `emergency_contact_id` (`emergency_contact_id`);

--
-- Indexes for table `user_settings`
--
ALTER TABLE `user_settings`
  ADD PRIMARY KEY (`user_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `bookings`
--
ALTER TABLE `bookings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=27;

--
-- AUTO_INCREMENT for table `booking_travellers`
--
ALTER TABLE `booking_travellers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=27;

--
-- AUTO_INCREMENT for table `documents`
--
ALTER TABLE `documents`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `family_members`
--
ALTER TABLE `family_members`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `packages`
--
ALTER TABLE `packages`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `password_resets`
--
ALTER TABLE `password_resets`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `payments`
--
ALTER TABLE `payments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `role`
--
ALTER TABLE `role`
  MODIFY `RoleID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `staff`
--
ALTER TABLE `staff`
  MODIFY `StaffID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `bookings`
--
ALTER TABLE `bookings`
  ADD CONSTRAINT `fk_bookings_package` FOREIGN KEY (`package_id`) REFERENCES `packages` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_bookings_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `booking_travellers`
--
ALTER TABLE `booking_travellers`
  ADD CONSTRAINT `fk_travellers_booking` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `documents`
--
ALTER TABLE `documents`
  ADD CONSTRAINT `fk_documents_booking` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_documents_traveller` FOREIGN KEY (`traveller_id`) REFERENCES `booking_travellers` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_documents_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `family_members`
--
ALTER TABLE `family_members`
  ADD CONSTRAINT `fk_family_members_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `fk_notifications_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `password_resets`
--
ALTER TABLE `password_resets`
  ADD CONSTRAINT `fk_password_resets_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `payments`
--
ALTER TABLE `payments`
  ADD CONSTRAINT `fk_payments_booking` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `staff`
--
ALTER TABLE `staff`
  ADD CONSTRAINT `staff_ibfk_1` FOREIGN KEY (`RoleID`) REFERENCES `role` (`RoleID`);

--
-- Constraints for table `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `fk_users_emergency_contact` FOREIGN KEY (`emergency_contact_id`) REFERENCES `family_members` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `user_settings`
--
ALTER TABLE `user_settings`
  ADD CONSTRAINT `fk_user_settings_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
