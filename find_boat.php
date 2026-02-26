<?php
require_once "userConfig.php";
$db = getDBO();

// Find Boat
$db->setQuery("SELECT id, fullname, username FROM users WHERE fullname LIKE '%โบ๊ต%' OR username LIKE '%โบ๊ต%'");
$users = $db->loadAssocList();
echo "<h3>Users matching 'โบ๊ต'</h3>";
echo "<pre>" . print_r($users, true) . "</pre>";

if ($users) {
    $uid = $users[0]['id'];
    $org_id = 1;
    $dates = ["'2026-01-27'", "'2026-02-05'", "'2026-02-12'", "'2026-02-13'"];
    $dates_str = implode(",", $dates);

    echo "<h3>Leave Records for UID: $uid</h3>";
    $db->setQuery("SELECT * FROM leave_{$org_id}_information 
                   WHERE create_by = $uid 
                   AND status = '1'
                   AND (
                       '2026-01-27' BETWEEN DATE(FirstDate) AND DATE(LastDate) OR
                       '2026-02-05' BETWEEN DATE(FirstDate) AND DATE(LastDate) OR
                       '2026-02-12' BETWEEN DATE(FirstDate) AND DATE(LastDate) OR
                       '2026-02-13' BETWEEN DATE(FirstDate) AND DATE(LastDate)
                   )");
    $leaves = $db->loadAssocList();
    echo "<pre>" . print_r($leaves, true) . "</pre>";

    echo "<h3>Attendance Records for UID: $uid</h3>";
    $db->setQuery("SELECT * FROM attend_{$org_id}_information 
                   WHERE create_by = $uid 
                   AND DATE(create_date) IN ($dates_str)");
    $attends = $db->loadAssocList();
    echo "<pre>" . print_r($attends, true) . "</pre>";
}
