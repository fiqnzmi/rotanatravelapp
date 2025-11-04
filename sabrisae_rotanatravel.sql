-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Nov 03, 2025 at 11:57 AM
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
  `status` enum('CONFIRMED','CANCELLED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'CONFIRMED',
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
(2, 1, 1, 1, 0, 'CONFIRMED', '2025-10-23 14:57:21', NULL, NULL, 0, 0, 0, 1.00),
(3, 1, 1, 1, 0, 'CONFIRMED', '2025-10-23 14:57:43', NULL, NULL, 0, 0, 0, 1.00),
(4, 1, 1, 1, 0, 'CONFIRMED', '2025-10-23 15:58:44', NULL, NULL, 0, 0, 0, 1.00),
(5, 1, 6, 1, 0, 'CONFIRMED', '2025-10-24 13:13:02', NULL, NULL, 0, 0, 0, 2.00),
(6, 1, 6, 2, 0, 'CONFIRMED', '2025-10-24 16:49:39', NULL, NULL, 0, 0, 0, 4.00),
(7, 1, 6, 1, 0, 'CONFIRMED', '2025-10-24 19:28:15', NULL, NULL, 0, 0, 0, 2.00),
(8, 1, 1, 1, 0, 'CONFIRMED', '2025-10-28 23:20:51', NULL, NULL, 0, 0, 0, 1.00),
(9, 1, 6, 1, 0, 'CONFIRMED', '2025-10-28 23:24:21', NULL, NULL, 0, 0, 0, 2.00),
(10, 1, 6, 1, 0, 'CONFIRMED', '2025-10-28 23:25:00', NULL, NULL, 0, 0, 0, 2.00),
(11, 1, 6, 1, 0, 'CONFIRMED', '2025-10-29 10:46:36', NULL, NULL, 0, 0, 0, 2.00),
(12, 1, 6, 1, 0, 'CONFIRMED', '2025-10-29 11:32:39', NULL, NULL, 0, 0, 0, 2.00),
(13, 1, 7, 1, 0, 'CONFIRMED', '2025-11-03 09:19:21', NULL, NULL, 0, 0, 0, 2.00);

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
(1, 2, 'Test User', 'shfj3874', '1995-10-23', 'Male', '2024-10-23', '2030-10-22'),
(2, 3, 'Muhammad Afiq Nazmi', 'shfjj3874', '1995-10-23', 'male', NULL, NULL),
(3, 4, 'Afiq', '244fggdf', '1995-10-17', 'male', NULL, NULL),
(4, 5, 'afiq', '123abc', '1995-10-24', 'male', NULL, NULL),
(5, 6, 'Yamin', 'abc123', '1995-10-24', 'male', NULL, NULL),
(6, 6, 'Wafiy', 'atv231', '1995-10-26', 'male', NULL, NULL),
(7, 7, 'Amier Hamzah', 'yter223', '1995-10-24', 'male', NULL, NULL),
(8, 8, 'Assyabil Yamin', 'A123', '1995-10-28', 'male', NULL, NULL),
(9, 9, 'Amirr', 'a123', '1995-10-28', 'male', NULL, NULL),
(10, 10, 'Amier', 'a1223', '1995-10-28', 'male', NULL, NULL),
(11, 11, 'Amier', 'abc123', '1995-10-29', 'male', NULL, NULL),
(12, 12, 'Amier', '12345679', '1995-10-29', 'male', NULL, NULL),
(13, 13, 'Assyabil', 'abc123456', '1995-11-03', 'male', NULL, NULL);

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
  `file_path` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL,
  `file_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `mime_type` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` enum('ACTIVE','ARCHIVED','REJECTED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'ACTIVE',
  `uploaded_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `label` varchar(120) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `remarks` text COLLATE utf8mb4_unicode_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `documents`
--

INSERT INTO `documents` (`id`, `user_id`, `booking_id`, `traveller_id`, `doc_type`, `file_path`, `file_name`, `mime_type`, `status`, `uploaded_at`, `label`, `remarks`) VALUES
(1, 7, 7, NULL, 'PASSPORT', '', NULL, NULL, 'ACTIVE', '2025-10-28 13:36:09', 'Passport', NULL),
(2, 7, 7, NULL, 'INSURANCE', '', NULL, NULL, 'ACTIVE', '2025-10-28 13:36:09', 'Travel Insurance', NULL),
(3, 7, 7, NULL, 'VISA', '', NULL, NULL, 'ACTIVE', '2025-10-28 13:36:09', 'Visa', NULL),
(4, 7, 7, NULL, 'PAYMENT_PROOF', '', NULL, NULL, 'ACTIVE', '2025-10-28 13:36:09', 'Payment Proof', NULL),
(5, 7, 7, NULL, 'OTHER', '', NULL, NULL, 'ACTIVE', '2025-10-28 13:36:09', 'Additional Document', NULL),
(6, 5, 12, NULL, 'PASSPORT', '', NULL, NULL, 'ACTIVE', '2025-10-29 16:15:34', 'Passport', NULL),
(7, 5, 12, NULL, 'INSURANCE', '', NULL, NULL, 'ACTIVE', '2025-10-29 16:15:34', 'Travel Insurance', NULL),
(8, 5, 12, NULL, 'VISA', '', NULL, NULL, 'ACTIVE', '2025-10-29 16:15:34', 'Visa', NULL),
(9, 5, 12, NULL, 'PAYMENT_PROOF', '', NULL, NULL, 'ACTIVE', '2025-10-29 16:15:34', 'Payment Proof', NULL),
(10, 5, 12, NULL, 'OTHER', '', NULL, NULL, 'ACTIVE', '2025-10-29 16:15:34', 'Additional Document', NULL),
(11, 8, 2, NULL, 'PASSPORT', '', NULL, NULL, 'ACTIVE', '2025-10-31 10:35:39', 'Passport', NULL),
(12, 8, 2, NULL, 'INSURANCE', '', NULL, NULL, 'ACTIVE', '2025-10-31 10:35:39', 'Travel Insurance', NULL),
(13, 8, 2, NULL, 'VISA', '', NULL, NULL, 'ACTIVE', '2025-10-31 10:35:39', 'Visa', NULL),
(14, 8, 2, NULL, 'PAYMENT_PROOF', '', NULL, NULL, 'ACTIVE', '2025-10-31 10:35:39', 'Payment Proof', NULL),
(15, 8, 2, NULL, 'OTHER', '', NULL, NULL, 'ACTIVE', '2025-10-31 10:35:39', 'Additional Document', NULL);

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
(2, 7, 2.00, 'MYR', 'FPX', 'PAID', 'TP2510241059440121', NULL, '2025-10-24 22:10:44', '2025-10-24 22:10:43'),
(3, 6, 4.00, 'MYR', 'FPX', 'PAID', 'TP2510272507006432', NULL, '2025-10-27 21:33:07', '2025-10-27 21:33:07'),
(4, 3, 1.00, 'MYR', 'FPX', 'PAID', 'TP2510284804408329', NULL, '2025-10-28 13:30:28', '2025-10-28 13:30:28'),
(5, 9, 2.00, 'MYR', 'FPX', 'PAID', 'TP2510284224074047', NULL, '2025-10-28 23:54:35', '2025-10-28 23:54:35'),
(6, 10, 2.00, 'MYR', 'FPX', 'PAID', 'TP2510291655455896', NULL, '2025-10-29 07:40:23', '2025-10-29 07:40:22'),
(7, 8, 1.00, 'MYR', 'FPX', 'PAID', 'TP2510292779036563', NULL, '2025-10-29 11:00:59', '2025-10-29 11:00:59'),
(8, 12, 2.00, 'MYR', 'FPX', 'PAID', 'TP2510290565813249', NULL, '2025-10-29 11:34:53', '2025-10-29 11:34:53');

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
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `username`, `name`, `email`, `password_hash`, `created_at`) VALUES
(1, 'afiq', 'afiq', 'afiq@example.com', '$2y$10$rezod81V4ILNsK3Cmf11Feo8FlRqmO6Pb.0JXJY9udBNJ2QwBUXPi', '2025-10-23 09:41:58'),
(4, 'afiq2', 'afiq2', 'afiq2@example.com', '$2y$10$m/seoYYNQXgY0UFjEAz0a.TtB5qiaSp0CtebZ46PlsMWEjnezdYoO', '2025-10-23 09:47:08'),
(5, 'Muhammad Afiq', 'Muhammad Afiq', 'muhammadafiqnazmi2003@gmail.com', '$2y$10$2Q6Q9BGIS8HeUUf4.SF3IOKwgrM8Z4ntBEgI/N.Mmq7KASLx1CfdG', '2025-10-23 09:47:42'),
(6, 'Assyabil', 'Assyabil', 'abilkry@gmail.com', '$2y$10$CscMeP.eMtl/r99i8dvdNOaqIQp3ik3La25glVYXIPJkDKxWuTpQq', '2025-10-24 16:50:11'),
(7, 'Afiq Nazmi', 'Afiq Nazmi', 'afiqnazmi17@icloud.com', '$2y$10$zl4WiRFuafe11zv9HP3vJuG3Kto8jWgjxRC7IsT7Qo4ldxRiw8xya', '2025-10-27 23:17:12'),
(8, 'Muhammad Afiq Nazmi Bin Sulaiman', 'Muhammad Afiq Nazmi Bin Sulaiman', 'afiqnzmi@gmail.com', '$2y$10$ihYrNLR5FYFh.bcv9Upk8.FLsrwibO4p4I0cU6DrUcuDTQIo3iCVS', '2025-10-28 23:05:49'),
(9, 'Amier', 'Amier', 'cuteamier@gmail.com', '$2y$10$HMLA4GaC2uS/Tbe10gIPFuJ.R.DdLH2LYxNeBM3Aq42fIt7SHad.2', '2025-10-29 10:45:52');

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
-- Indexes for table `password_resets`
--
ALTER TABLE `password_resets`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_token` (`token`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `code` (`code`);

--
-- Indexes for table `packages`
--
ALTER TABLE `packages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `title` (`title`);

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
  ADD UNIQUE KEY `username_unique` (`username`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `bookings`
--
ALTER TABLE `bookings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `booking_travellers`
--
ALTER TABLE `booking_travellers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `documents`
--
ALTER TABLE `documents`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `family_members`
--
ALTER TABLE `family_members`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `password_resets`
--
ALTER TABLE `password_resets`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `packages`
--
ALTER TABLE `packages`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `payments`
--
ALTER TABLE `payments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

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
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
