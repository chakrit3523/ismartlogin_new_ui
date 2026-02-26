<?php
require_once "userConfig.php";
$db = getDBO();
$db->setQuery("
SELECT 'ATTEND' as _type, id, create_date, start_status, end_status, start_time, end_time, total_time as extra_info 
FROM attend_1_information 
WHERE create_by = 13 
AND DATE(create_date) IN ('2026-01-26', '2026-02-16', '2026-02-23')
UNION ALL
SELECT 'LEAVE' as _type, id, create_date, cid as start_status, status_leave as end_status, firstTime as start_time, lastTime as end_time, numDate as extra_info 
FROM leave_1_information 
WHERE create_by = 13 
AND status_leave IN ('1', '2')
AND (
    '2026-01-26' BETWEEN DATE(FirstDate) AND DATE(LastDate) OR
    '2026-02-16' BETWEEN DATE(FirstDate) AND DATE(LastDate) OR
    '2026-02-23' BETWEEN DATE(FirstDate) AND DATE(LastDate)
)
");
$res = $db->loadAssocList();
print_r($res);
