<?php
require_once "userConfig.php";
$db = getDBO();
$db->setQuery("SELECT id, title, default_type FROM leave_1_category WHERE status = '1'");
$categories = $db->loadAssocList();
echo json_encode($categories, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
