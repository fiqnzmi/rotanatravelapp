<?php
// === ENV ===
$APP_ENV = 'production';  // 'production' to hide debug_code in reset flow

// === DB CREDS ===
$DB_HOST = 'localhost';
$DB_NAME = 'sabrisae_rotanatravel';
$DB_USER = 'sabrisae_rotanatravel';
$DB_PASS = 'Rotanatravel_2025';

// === UPLOADS ===
$UPLOAD_DIR = realpath(__DIR__ . '/../uploads');
$BASE_URL   = (isset($_SERVER['HTTPS']) ? 'https://' : 'http://') . $_SERVER['HTTP_HOST'];
$UPLOAD_URL = $BASE_URL . dirname($_SERVER['SCRIPT_NAME'], 1) . '/../uploads';

// === PAYMENTS / TOYYIBPAY ===
$TOYYIBPAY_BASE_URL      = getenv('TOYYIBPAY_BASE_URL') ?: 'https://toyyibpay.com';
$TOYYIBPAY_SECRET_KEY    = getenv('TOYYIBPAY_SECRET_KEY') ?: '6snobie9-a2hm-vdpp-9xa3-wv69aioimh6d';
$TOYYIBPAY_CATEGORY_CODE = getenv('TOYYIBPAY_CATEGORY_CODE') ?: '1pqcbh5e';
$TOYYIBPAY_RETURN_URL    = getenv('TOYYIBPAY_RETURN_URL') ?: 'https://ruangprojek.com/rotanatravel/rotanatravelapi/toyyibpay_return.php';
$TOYYIBPAY_CALLBACK_URL  = getenv('TOYYIBPAY_CALLBACK_URL') ?: 'https://ruangprojek.com/rotanatravel/rotanatravelapi/api/toyyibpay_callback.php';
$TOYYIBPAY_DEFAULT_PHONE = getenv('TOYYIBPAY_DEFAULT_PHONE') ?: '01135363010';
$TOYYIBPAY_DEFAULT_EMAIL = getenv('TOYYIBPAY_DEFAULT_EMAIL') ?: 'muhammadafiqnazmi2003@gmail.com';

// === MAIL (SMTP) ===
$MAIL_HOST = getenv('MAIL_HOST') ?: 'mail.ruangprojek.com';
$MAIL_PORT = (int)(getenv('MAIL_PORT') ?: 587);
$MAIL_USERNAME = getenv('MAIL_USERNAME') ?: 'rotanatravel@ruangprojek.com';
$MAIL_PASSWORD = getenv('MAIL_PASSWORD') ?: 'Rotanatravel_2025';
$MAIL_SECURE = strtolower(getenv('MAIL_SECURE') ?: 'tls'); // tls, ssl, none
$MAIL_FROM = getenv('MAIL_FROM') ?: 'rotanatravel@ruangprojek.com';
$MAIL_FROM_NAME = getenv('MAIL_FROM_NAME') ?: 'Rotana Travel';
$MAIL_REPLY_TO = getenv('MAIL_REPLY_TO') ?: $MAIL_FROM;

// === MAIL (used by password reset) ===
$MAIL_FROM = getenv('MAIL_FROM') ?: 'no-reply@rotanatravel.com';
$MAIL_FROM_NAME = getenv('MAIL_FROM_NAME') ?: 'Rotana Travel';
$MAIL_REPLY_TO = getenv('MAIL_REPLY_TO') ?: $MAIL_FROM;
