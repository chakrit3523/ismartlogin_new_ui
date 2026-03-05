<?php
$_SERVER['DOCUMENT_ROOT'] = __DIR__;
include("config/db.php");
$db = getDBO();

// Find Sopon
$db->setQuery("SELECT id FROM users WHERE nickname LIKE '%เอก%'");
$users = $db->loadAssocList();
$uid = $users[0]['id'];

// Check dates
$date_pre = '2026-01-26';
$create_date = '2026-02-25';
$db->setQuery("SELECT create_date FROM attend_1_summary WHERE create_date BETWEEN '{$date_pre}' AND '{$create_date}'");
$sum_dates = $db->loadAssocList();

$db->setQuery("SELECT * FROM attend_1_information WHERE create_by = '{$uid}' AND create_date LIKE '2026-01-26%'");
$att_26 = $db->loadAssocList();

echo json_encode([
    'uid' => $uid,
    'has_sum_26' => in_array('2026-01-26', array_column($sum_dates, 'create_date')),
    'att_26_01' => $att_26,
], JSON_PRETTY_PRINT);
