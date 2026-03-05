<?php
$_SERVER['DOCUMENT_ROOT'] = __DIR__;
require_once 'system/DB.php'; // or whatever the DB path is
// Actually, let's just include config and create connection
include("config/db.php");
// If I don't know the config, I'll search for it.
