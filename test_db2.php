<?php
$_SERVER['DOCUMENT_ROOT'] = __DIR__;
require_once 'config/db.php';
require_once 'system/class.database.php';

$db = getDBO();

$db->setQuery("SELECT id, fullname FROM users WHERE nickname LIKE '%เอก%'");
$users = $db->loadAssocList();
print_r($users);
$uid = $users[0]['id'];

$db->setQuery("SELECT id, cid, numDate, half_day_period, FirstDate FROM leave_1_information WHERE create_by = '{$uid}' AND FirstDate LIKE '2026-02-16%'");
$leaves = $db->loadAssocList();
print_r($leaves);
