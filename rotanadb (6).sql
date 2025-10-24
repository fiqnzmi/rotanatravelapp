-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Oct 24, 2025 at 05:15 AM
-- Server version: 8.0.30
-- PHP Version: 8.1.10

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `rotanadb`
--

-- --------------------------------------------------------

--
-- Table structure for table `bookings`
--

CREATE TABLE `bookings` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `package_id` int NOT NULL,
  `adults` int NOT NULL DEFAULT '1',
  `children` int NOT NULL DEFAULT '0',
  `status` enum('CONFIRMED','CANCELLED') NOT NULL DEFAULT 'CONFIRMED',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `departure_date` date DEFAULT NULL,
  `room_tier` varchar(30) DEFAULT NULL,
  `deposit_paid` tinyint(1) NOT NULL DEFAULT '0',
  `briefing_done` tinyint(1) NOT NULL DEFAULT '0',
  `final_paid` tinyint(1) NOT NULL DEFAULT '0',
  `total_amount` decimal(10,2) NOT NULL DEFAULT '0.00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `bookings`
--

INSERT INTO `bookings` (`id`, `user_id`, `package_id`, `adults`, `children`, `status`, `created_at`, `departure_date`, `room_tier`, `deposit_paid`, `briefing_done`, `final_paid`, `total_amount`) VALUES
(2, 1, 1, 1, 0, 'CONFIRMED', '2025-10-23 14:57:21', NULL, NULL, 0, 0, 0, '1.00'),
(3, 1, 1, 1, 0, 'CONFIRMED', '2025-10-23 14:57:43', NULL, NULL, 0, 0, 0, '1.00'),
(4, 1, 1, 1, 0, 'CONFIRMED', '2025-10-23 15:58:44', NULL, NULL, 0, 0, 0, '1.00'),
(5, 1, 6, 1, 0, 'CONFIRMED', '2025-10-24 13:13:02', NULL, NULL, 0, 0, 0, '2.00');

-- --------------------------------------------------------

--
-- Table structure for table `booking_travellers`
--

CREATE TABLE `booking_travellers` (
  `id` int NOT NULL,
  `booking_id` int NOT NULL,
  `full_name` varchar(200) NOT NULL,
  `passport_no` varchar(100) DEFAULT NULL,
  `dob` date DEFAULT NULL,
  `gender` varchar(20) DEFAULT NULL,
  `passport_issue_date` date DEFAULT NULL,
  `passport_expiry_date` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `booking_travellers`
--

INSERT INTO `booking_travellers` (`id`, `booking_id`, `full_name`, `passport_no`, `dob`, `gender`, `passport_issue_date`, `passport_expiry_date`) VALUES
(1, 2, 'Test User', 'shfj3874', '1995-10-23', 'Male', '2024-10-23', '2030-10-22'),
(2, 3, 'Muhammad Afiq Nazmi', 'shfjj3874', '1995-10-23', 'male', NULL, NULL),
(3, 4, 'Afiq', '244fggdf', '1995-10-17', 'male', NULL, NULL),
(4, 5, 'afiq', '123abc', '1995-10-24', 'male', NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `documents`
--

CREATE TABLE `documents` (
  `id` int NOT NULL,
  `user_id` int DEFAULT NULL,
  `booking_id` int DEFAULT NULL,
  `traveller_id` int DEFAULT NULL,
  `doc_type` enum('PASSPORT','IC','VISA','TICKET','HOTEL_VOUCHER','INSURANCE','PAYMENT_PROOF','ITINERARY','OTHER') NOT NULL DEFAULT 'OTHER',
  `file_path` varchar(500) NOT NULL,
  `file_name` varchar(255) DEFAULT NULL,
  `mime_type` varchar(100) DEFAULT NULL,
  `status` enum('ACTIVE','ARCHIVED','REJECTED') NOT NULL DEFAULT 'ACTIVE',
  `uploaded_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `label` varchar(120) DEFAULT NULL,
  `remarks` text
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `family_members`
--

CREATE TABLE `family_members` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `full_name` varchar(200) NOT NULL,
  `relationship` enum('SPOUSE','CHILD','PARENT','SIBLING','FRIEND','OTHER') NOT NULL DEFAULT 'OTHER',
  `passport_no` varchar(100) DEFAULT NULL,
  `dob` date DEFAULT NULL,
  `nationality` varchar(100) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `type` enum('PAYMENT','DOCS','BRIEFING','BOOKING','PROMO','GENERAL') NOT NULL DEFAULT 'GENERAL',
  `title` varchar(200) NOT NULL,
  `body` text,
  `is_important` tinyint(1) NOT NULL DEFAULT '0',
  `is_read` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `packages`
--

CREATE TABLE `packages` (
  `id` int NOT NULL,
  `title` varchar(200) NOT NULL,
  `description` text,
  `price` decimal(10,2) NOT NULL DEFAULT '0.00',
  `images_json` json DEFAULT NULL,
  `bill_url` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `duration_days` int DEFAULT NULL,
  `cities` varchar(200) DEFAULT NULL,
  `hotel_stars` tinyint DEFAULT NULL,
  `rating_avg` decimal(2,1) DEFAULT NULL,
  `rating_count` int DEFAULT NULL,
  `departures_json` json DEFAULT NULL,
  `inclusions_json` json DEFAULT NULL,
  `itinerary_json` json DEFAULT NULL,
  `faqs_json` json DEFAULT NULL,
  `required_docs_json` text
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `packages`
--

INSERT INTO `packages` (`id`, `title`, `description`, `price`, `images_json`, `bill_url`, `created_at`, `duration_days`, `cities`, `hotel_stars`, `rating_avg`, `rating_count`, `departures_json`, `inclusions_json`, `itinerary_json`, `faqs_json`, `required_docs_json`) VALUES
(1, 'test', 'package', '1.00', NULL, 'https://toyyibpay.com/7qr6lhrg', '2025-10-23 10:12:25', 7, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(3, 'holiday', 'testpackage', '2.00', NULL, 'https://toyyibpay.com/7qr6lhrg', '2025-10-23 19:57:03', 14, 'Madinah', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(6, 'MINECRAFT 3', 'test 4', '2.00', NULL, 'https://toyyibpay.com/khxeyzqb', '2025-10-24 05:05:41', 2, 'tak tahu', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `payments`
--

CREATE TABLE `payments` (
  `id` int NOT NULL,
  `booking_id` int NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `currency` char(3) NOT NULL DEFAULT 'MYR',
  `method` enum('FPX','CARD','TRANSFER','CASH','EWALLET') NOT NULL DEFAULT 'TRANSFER',
  `status` enum('PENDING','PAID','FAILED','REFUNDED','CANCELLED') NOT NULL DEFAULT 'PENDING',
  `transaction_ref` varchar(100) DEFAULT NULL,
  `gateway_payload` json DEFAULT NULL,
  `paid_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `role`
--

CREATE TABLE `role` (
  `RoleID` int NOT NULL,
  `RoleName` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
  `StaffID` int NOT NULL,
  `Name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `Email` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `Password` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `RoleID` int DEFAULT NULL,
  `CreatedAt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
  `id` int NOT NULL,
  `username` varchar(150) NOT NULL,
  `name` varchar(150) NOT NULL,
  `email` varchar(150) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `username`, `name`, `email`, `password_hash`, `created_at`) VALUES
(1, 'afiq', 'afiq', 'afiq@example.com', '$2y$10$rezod81V4ILNsK3Cmf11Feo8FlRqmO6Pb.0JXJY9udBNJ2QwBUXPi', '2025-10-23 09:41:58'),
(4, 'afiq2', 'afiq2', 'afiq2@example.com', '$2y$10$m/seoYYNQXgY0UFjEAz0a.TtB5qiaSp0CtebZ46PlsMWEjnezdYoO', '2025-10-23 09:47:08'),
(5, 'Muhammad Afiq', 'Muhammad Afiq', 'muhammadafiqnazmi2003@gmail.com', '$2y$10$2Q6Q9BGIS8HeUUf4.SF3IOKwgrM8Z4ntBEgI/N.Mmq7KASLx1CfdG', '2025-10-23 09:47:42');

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
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `booking_travellers`
--
ALTER TABLE `booking_travellers`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `documents`
--
ALTER TABLE `documents`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `family_members`
--
ALTER TABLE `family_members`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `packages`
--
ALTER TABLE `packages`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `payments`
--
ALTER TABLE `payments`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `role`
--
ALTER TABLE `role`
  MODIFY `RoleID` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `staff`
--
ALTER TABLE `staff`
  MODIFY `StaffID` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `bookings`
--
ALTER TABLE `bookings`
  ADD CONSTRAINT `fk_bookings_package` FOREIGN KEY (`package_id`) REFERENCES `packages` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_bookings_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

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
