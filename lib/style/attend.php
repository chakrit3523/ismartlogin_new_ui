<?php if (!defined('BASEPATH')) exit('No direct script access allowed');

class attend extends CI_Controller
{

    /**
     *
     * @var Array All Available tables 
     */
    public $_TABLE              = array(
        'info'              => 'attend_test_information',
        'file'              => 'attend_test_attachments',
        'sum'              => 'attend_test_summary',
        'category'          => 'attend_test_category'
    );
    public $data                = array(
        '_CMD'              => 'attend',
        'body'              => '',
        'menuName'          => ''
    );
    public $maxRows             = 8;
    public $avialableTag        = '<p><a><img><span><div><table><tbody><tr><td><th><ul><li><qoute><font><ol><style><strong><em><u><i><h4><h5><h6>';
    public $mobile = '';
    /*
     * Predined methods
     */
    public function __construct()
    {
        parent::__construct();
        $this->load->helper('url');
        setPicContent('แบบมาตรฐานบ้าน/อาคาร');

        $this->load->library('user_agent');
        if (!$this->agent->is_mobile()) {
            $this->mobile = '';
        } else {
            $this->mobile = Site::$mobile; //
        }
    }
    private function loadView($view = null, $viewData = array())
    {
        if ($view != null) {
            if (!@$viewData['data']) {
                $viewData['data'] = $this->data;
            }
            ob_start();
            $this->load->view($view, $viewData);
            $subView            = ob_get_clean();
            $this->data['body'] = $subView;
        }
        $this->load->view($view, $this->data);
    }
    private function getView($view = null, $viewData = array())
    {
        ob_start();
        $this->load->view($view, $viewData);
        return ob_get_clean();
    }
    public function index()
    {
        $this->attandCheck();
    }
    public function download()
    {
        $this->updateFileHit(request('id'));
        if (!$this->agent->is_mobile()) {
            download(request('file'), request('name'));
        }
        exit();
    }
    public function updateFileHit($id)
    {
        $db             = getDBO();
        $db->setQuery("UPDATE ebook_attachments SET hits=hits+1 WHERE id='{$id}' ");
        $db->query();
    }
    public function updateHit($id)
    {
        $db             = getDBO();
        $db->setQuery("UPDATE {$this->_TABLE['info']} SET hits=hits+1 WHERE id='{$id}' ");
        $db->query();
    }
    //-----


    public function attandCheck()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        $uid = $var['uid'] ? $var['uid'] : request('uid');
        $time_id = $var['time_id'] ? $var['time_id'] : request('time_id');
        $user = getMyOrgId($uid);
        $search = "";
        $next_day = "";
        if ($time_id) {
            $search = "AND `log` = 'timeid_{$time_id}'";
        }
        $search_date = "";
        if ($user['org_id'] == "1564") {
            if ($time_id == "547") {
                $search_date = "AND create_date >= CURDATE() + INTERVAL 6 HOUR
                            AND create_date < CURDATE() + INTERVAL 1 DAY + INTERVAL 9 HOUR";
            } else {
                $search_date = "AND			DATE(create_date) = CURDATE()";
            }
        } else {
            $search_date = "AND			DATE(create_date) = CURDATE()";
        }

        $db = getDBO();
        $sql = "SELECT		*
				FROM		attend_" . $user['org_id'] . "_information
				WHERE		create_by = '{$uid}'
                AND         cid != '3'
				AND			status = '1'
                {$search_date}
                {$search}
                ORDER BY id DESC    
                LIMIT 1
				";
        // exit($sql);
        if ($_GET['debug']) {
            echo $sql;
            exit();
        }
        $db->setQuery($sql);
        $rs = $db->loadAssocList();
        $len = count($rs);
        $status = '';
        if ($len > 0) {
            if ($_GET['debug']) {
                pre('login แล้ว');
            }
            //login แล้ว
            $status = 'success';
            //เช็ค ot เช็ค logout อัตโนมัติ
            $sql = "SELECT		*
                    FROM        org_information
                    WHERE       id = '{$user['org_id']}'
                    AND         status = '1'";
            $db->setQuery($sql);
            $org = $db->loadAssocList();
            if ($org[0]['ot_status'] == "1" && ($rs[0]['end_time'] != NULL or $rs[0]['end_time'] != "")) {
                $status = 'fail';
                //check ทำ ot แล้ว
                $sql = "SELECT		*
				        FROM		attend_" . $user['org_id'] . "_information
                        WHERE		create_by = '{$uid}'
                        AND         cid != '3'
                        AND			status = '1'
                        {$search}
                        ";
                // -- AND			DATE(create_date) = CURDATE()
                $db->setQuery($sql);
                $rs_ot = $db->loadAssocList();
                $len_ot = count($rs_ot);
                if ($len_ot > 1) {
                    $status = 'success';
                }
                if ($_GET['debug']) {
                    // echo $sql;
                    // echo $status;
                    // exit();
                }
            } else {
                $status = 'success';
                $day = date('N');
                $day_attend = $day - 1;
                $end_time_login = $org[0]['end_time_login'];
                $sql = "SELECT		*
                        FROM        time_information
                        WHERE       id = '{$time_id}'
                        AND         status = '1'";
                $db->setQuery($sql);
                $time = $db->loadAssocList();
                if ($time) {
                    if ($end_time_login) {
                        $time = $time[0];
                        $time_data = $time['description'];
                        $time_data = json_decode($time_data, true);
                        $len_time = count($time_data);
                        if ($len_time) {
                            $time_end = $time_data[$day_attend]['time_end'];
                            $this_time_logout = strtotime($time_end);
                            $final_time_logout = strtotime('+' . $end_time_login . ' hour', $this_time_logout);
                            $target_time = date('H:i:s', $final_time_logout);
                            $current_time = date('H:i:s');
                            $target_timestamp = strtotime($target_time);
                            $current_timestamp = strtotime($current_time);
                            if ($current_timestamp < $target_timestamp) {
                                // กระทำเมื่อเวลาปัจจุบันมากกว่าหรือเท่ากับเวลาเป้าหมาย
                                $status = 'success';
                            }
                        } else {
                            $status = 'success';
                        }
                    }
                }
            }
        } else {
            if ($_GET['debug']) {
                pre('ยังไม่ได้ login');
            }
            //ยังไม่ได้ login
            $status = 'fail';
            //check login ล่วงหน้าได้กี่โมง
            $sql = "SELECT		*
                    FROM        org_information
                    WHERE       id = '{$user['org_id']}'
                    AND         status = '1'";
            $db->setQuery($sql);
            $org = $db->loadAssocList();
            if ($_GET['debug']) {
                // echo $sql;
                // exit();
            }
            if ($org[0]['start_time_login'] != "" && $status == 'fail') {
                if ($_GET['debug']) {
                    // pre($org[0]['start_time_login']);
                }
                $status = 'fail';
                $day = date('N');
                $day_attend = $day - 1;
                $start_time_login = $org[0]['start_time_login'];
                $sql = "SELECT		*
                        FROM        time_information
                        WHERE       id = '{$time_id}'
                        AND         status = '1'";
                $db->setQuery($sql);
                $time = $db->loadAssocList();
                if ($_GET['debug']) {
                    // pre($sql);
                    // exit();
                }
                if ($time) {
                    $time = $time[0];
                    $time_data = $time['description'];
                    $time_data = json_decode($time_data, true);
                    if ($_GET['debug']) {
                        // pre($time_data);
                        // pre($day_attend);
                        // pre($time_data[$day_attend]);
                        // exit();
                    }
                    $len_time = count($time_data);
                    if ($len_time) {
                        for ($i = 0; $i < $len_time; $i++) {
                            if ($time_data[$i]["day"] == $day_attend) {
                                $time_start = $time_data[$i]["time_start"];
                                $time_end = $time_data[$i]["time_end"];
                                $this_time_login = strtotime($time_start);
                                $final_time_login = strtotime('-' . $start_time_login . ' hour', $this_time_login);
                                $target_time = date('H:i:s', $final_time_login);
                                $current_time = date('H:i:s');
                                if ($_GET['debug']) {
                                    // pre($time_data[$i]["time_start"]);
                                    // pre($time_data[$i]["time_end"]);
                                    // pre($target_time);
                                    // pre($current_time);
                                    // exit();
                                }
                                $target_timestamp = strtotime($target_time);
                                $current_timestamp = strtotime($current_time);
                                if ($current_timestamp >= $target_timestamp) {
                                    // กระทำเมื่อเวลาปัจจุบันมากกว่าหรือเท่ากับเวลาเป้าหมาย
                                    $status = 'fail';
                                } else {
                                    // กระทำเมื่อเวลาปัจจุบันน้อยกว่าเวลาเป้าหมาย
                                    $status = 'success';
                                    $rs[0]['end_time'] = $time_end;
                                }
                            }
                        }
                    } else {
                        $status = 'fail';
                    }
                }
            } else {
                if ($_GET['debug']) {
                    pre('check เวลาออก ตามวัน หลังเที่ยงคืน');
                }
                //check เวลาออก ตามวัน หลังเที่ยงคืน
                $yesterday = date('Y-m-d', strtotime("-1 days"));
                $sql = "SELECT		*
                        FROM        attend_" . $user['org_id'] . "_information
                        WHERE		create_by = '{$uid}'
                        AND         cid != '3'
                        AND			status = '1'
                        AND			DATE(create_date) = '{$yesterday}'
                        AND         (end_time = '' OR end_time IS NULL)";
                $db->setQuery($sql);
                $rs = $db->loadAssocList();
                // pre($data_yesterday);

                if ($rs) {
                    //เช็ค ไม่ logout ก่อนหน้า 
                    $day = date('N');
                    $day_attend = $day - 2;
                    // pre($day_attend);
                    $sql = "SELECT		*
                            FROM        time_information
                            WHERE       id = '{$time_id}'
                            AND         status = '1'";
                    $db->setQuery($sql);
                    $time = $db->loadAssocList();
                    if ($time) {
                        $time = $time[0];
                        $time_data = $time['description'];
                        $time_data = json_decode($time_data, true);
                        // pre($time_data);

                        if ($time_data[$day_attend]) {
                            $time_start = $time_data[$day_attend]['time_start'];
                            $time_end = $time_data[$day_attend]['time_end'];
                            $start_timestamp = strtotime($time_start);
                            $end_timestamp = strtotime($time_end);
                            // pre($time_end);
                            if ($start_timestamp > $end_timestamp) {
                                //ข้ามวัน 
                                $next_day = "1";
                            } else {
                                //ไม่ข้ามวัน
                                $next_day = "0";
                            }
                            $time_logout = date('Y-m-d') . ' ' . $time_end;
                            $time_logout = strtotime($time_logout);
                            $time_logout = strtotime("+5 hours", $time_logout);
                            $time_logout = date('Y-m-d H:i:s', $time_logout);
                            $time_logout = strtotime($time_logout);
                            $current_date_time = date('Y-m-d H:i:s');
                            $current_date_time = strtotime($current_date_time);
                            // pre($time_logout);
                            // pre($current_date_time);
                            if ($next_day == "1") {
                                if ($time_logout > $current_date_time) {
                                    $status = 'success';
                                } else {
                                    $status = 'fail';
                                }
                            } else {
                                $status = 'fail';
                            }
                        }
                        // exit();
                    }
                } else {
                    $status = 'fail';
                }
            }
        }
        $result[0] = array(
            'cid' => '1',
            'status' => $status,
            'uploadKey' => $rs[0]['uploadKey'],
            'start_time' => $rs[0]['start_time'],
            'start_note' => $rs[0]['start_note'],
            'start_status' => $rs[0]['start_status'],
            'end_time' => $rs[0]['end_time'],
            'end_note' => $rs[0]['end_note'],
            'end_status' => $rs[0]['end_status']
        );
        echo json_encode($result);
        exit();
    }

    public function attandCheckBackup()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        $uid = $var['uid'] ? $var['uid'] : request('uid');
        $time_id = $var['time_id'] ? $var['time_id'] : request('time_id');
        $user = getMyOrgId($uid);
        $search = "";
        $next_day = "";
        if ($time_id) {
            $search = "AND `log` = 'timeid_{$time_id}'";
        }
        $db = getDBO();
        $sql = "SELECT		*
				FROM		attend_" . $user['org_id'] . "_information
				WHERE		create_by = '{$uid}'
                AND         cid != '3'
				AND			status = '1'
				AND			DATE(create_date) = CURDATE()
                {$search}
                ORDER BY id DESC    
                LIMIT 1
				";
        // exit($sql);
        if ($_GET['debug']) {
            // echo $sql;
            // exit();
        }
        $db->setQuery($sql);
        $rs = $db->loadAssocList();
        $len = count($rs);
        $status = '';
        if ($len > 0) {
            if ($_GET['debug']) {
                pre('login แล้ว');
            }
            //login แล้ว
            $status = 'success';
            //เช็ค ot เช็ค logout อัตโนมัติ
            $sql = "SELECT		*
                    FROM        org_information
                    WHERE       id = '{$user['org_id']}'
                    AND         status = '1'";
            $db->setQuery($sql);
            $org = $db->loadAssocList();
            if ($org[0]['ot_status'] == "1" && ($rs[0]['end_time'] != NULL or $rs[0]['end_time'] != "")) {
                $status = 'fail';
                //check ทำ ot แล้ว
                $sql = "SELECT		*
				        FROM		attend_" . $user['org_id'] . "_information
                        WHERE		create_by = '{$uid}'
                        AND         cid != '3'
                        AND			status = '1'
                        AND			DATE(create_date) = CURDATE()
                        {$search}
                        ";
                $db->setQuery($sql);
                $rs_ot = $db->loadAssocList();
                $len_ot = count($rs_ot);
                if ($len_ot > 1) {
                    $status = 'success';
                }
                if ($_GET['debug']) {
                    // echo $sql;
                    // echo $status;
                    // exit();
                }
            } else {
                $status = 'success';
                $day = date('N');
                $day_attend = $day - 1;
                $end_time_login = $org[0]['end_time_login'];
                $sql = "SELECT		*
                        FROM        time_information
                        WHERE       id = '{$time_id}'
                        AND         status = '1'";
                $db->setQuery($sql);
                $time = $db->loadAssocList();
                if ($time) {
                    if ($end_time_login) {
                        $time = $time[0];
                        $time_data = $time['description'];
                        $time_data = json_decode($time_data, true);
                        $len_time = count($time_data);
                        if ($len_time) {
                            $time_end = $time_data[$day_attend]['time_end'];
                            $this_time_logout = strtotime($time_end);
                            $final_time_logout = strtotime('+' . $end_time_login . ' hour', $this_time_logout);
                            $target_time = date('H:i:s', $final_time_logout);
                            $current_time = date('H:i:s');
                            $target_timestamp = strtotime($target_time);
                            $current_timestamp = strtotime($current_time);
                            if ($current_timestamp < $target_timestamp) {
                                // กระทำเมื่อเวลาปัจจุบันมากกว่าหรือเท่ากับเวลาเป้าหมาย
                                $status = 'success';
                            }
                        } else {
                            $status = 'success';
                        }
                    }
                }
            }
        } else {
            if ($_GET['debug']) {
                pre('ยังไม่ได้ login');
            }
            //ยังไม่ได้ login
            $status = 'fail';
            //check login ล่วงหน้าได้กี่โมง
            $sql = "SELECT		*
                    FROM        org_information
                    WHERE       id = '{$user['org_id']}'
                    AND         status = '1'";
            $db->setQuery($sql);
            $org = $db->loadAssocList();
            if ($_GET['debug']) {
                // echo $sql;
                // exit();
            }
            if ($org[0]['start_time_login'] != "" && $status == 'fail') {
                $status = 'fail';
                $day = date('N');
                $day_attend = $day - 1;
                $start_time_login = $org[0]['start_time_login'];
                $sql = "SELECT		*
                        FROM        time_information
                        WHERE       id = '{$time_id}'
                        AND         status = '1'";
                $db->setQuery($sql);
                $time = $db->loadAssocList();
                if ($_GET['debug']) {
                    // pre($sql);
                    // exit();
                }
                if ($time) {
                    $time = $time[0];
                    $time_data = $time['description'];
                    $time_data = json_decode($time_data, true);
                    if ($_GET['debug']) {
                        // pre($time_data);
                        // pre($day_attend);
                        // pre($time_data[$day_attend]);
                        // exit();
                    }
                    $len_time = count($time_data);
                    if ($len_time) {
                        for ($i = 0; $i < $len_time; $i++) {
                            if ($time_data[$i]["day"] == $day_attend) {
                                $time_start = $time_data[$i]["time_start"];
                                $time_end = $time_data[$i]["time_end"];
                                $this_time_login = strtotime($time_start);
                                $final_time_login = strtotime('-' . $start_time_login . ' hour', $this_time_login);
                                $target_time = date('H:i:s', $final_time_login);
                                $current_time = date('H:i:s');
                                if ($_GET['debug']) {
                                    // pre($time_data[$i]["time_start"]);
                                    // pre($time_data[$i]["time_end"]);
                                    pre($target_time);
                                    pre($current_time);
                                    exit();
                                }
                                $target_timestamp = strtotime($target_time);
                                $current_timestamp = strtotime($current_time);
                                if ($current_timestamp >= $target_timestamp) {
                                    // กระทำเมื่อเวลาปัจจุบันมากกว่าหรือเท่ากับเวลาเป้าหมาย
                                    $status = 'fail';
                                } else {
                                    // กระทำเมื่อเวลาปัจจุบันน้อยกว่าเวลาเป้าหมาย
                                    $status = 'success';
                                    $rs[0]['end_time'] = $time_end;
                                }
                            }
                        }
                    } else {
                        $status = 'fail';
                    }
                }
            } else {
                //check เวลาออก ตามวัน หลังเที่ยงคือ
                $yesterday = date('Y-m-d', strtotime("-1 days"));
                $sql = "SELECT		*
                        FROM        attend_" . $user['org_id'] . "_information
                        WHERE		create_by = '{$uid}'
                        AND         cid != '3'
                        AND			status = '1'
                        AND			DATE(create_date) = '{$yesterday}'
                        AND         (end_time = '' OR end_time IS NULL)";
                $db->setQuery($sql);
                $rs = $db->loadAssocList();
                // pre($data_yesterday);

                if ($rs) {
                    //เช็ค ไม่ logout ก่อนหน้า 
                    $day = date('N');
                    $day_attend = $day - 2;
                    // pre($day_attend);
                    $sql = "SELECT		*
                            FROM        time_information
                            WHERE       id = '{$time_id}'
                            AND         status = '1'";
                    $db->setQuery($sql);
                    $time = $db->loadAssocList();
                    if ($time) {
                        $time = $time[0];
                        $time_data = $time['description'];
                        $time_data = json_decode($time_data, true);
                        // pre($time_data);

                        if ($time_data[$day_attend]) {
                            $time_start = $time_data[$day_attend]['time_start'];
                            $time_end = $time_data[$day_attend]['time_end'];
                            $start_timestamp = strtotime($time_start);
                            $end_timestamp = strtotime($time_end);
                            // pre($time_end);
                            if ($start_timestamp > $end_timestamp) {
                                //ข้ามวัน 
                                $next_day = "1";
                            } else {
                                //ไม่ข้ามวัน
                                $next_day = "0";
                            }
                            $time_logout = date('Y-m-d') . ' ' . $time_end;
                            $time_logout = strtotime($time_logout);
                            $time_logout = strtotime("+5 hours", $time_logout);
                            $time_logout = date('Y-m-d H:i:s', $time_logout);
                            $time_logout = strtotime($time_logout);
                            $current_date_time = date('Y-m-d H:i:s');
                            $current_date_time = strtotime($current_date_time);
                            // pre($time_logout);
                            // pre($current_date_time);
                            if ($next_day == "1") {
                                if ($time_logout > $current_date_time) {
                                    $status = 'success';
                                } else {
                                    $status = 'fail';
                                }
                            } else {
                                $status = 'fail';
                            }
                        }
                        // exit();
                    }
                } else {
                    $status = 'fail';
                }
            }
        }
        $result[0] = array(
            'cid' => '1',
            'status' => $status,
            'uploadKey' => $rs[0]['uploadKey'],
            'start_time' => $rs[0]['start_time'],
            'start_note' => $rs[0]['start_note'],
            'start_status' => $rs[0]['start_status'],
            'end_time' => $rs[0]['end_time'],
            'end_note' => $rs[0]['end_note'],
            'end_status' => $rs[0]['end_status']
        );
        echo json_encode($result);
        exit();
    }


    public function attendStart()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;


        $uid = $var['uid'] ? $var['uid'] : request('uid');
        $cid = $var['cid'] ? $var['cid'] : request('cid', '2');
        $branch_id = $var['branch_id'] ? $var['branch_id'] : request('branch_id', 0);
        $latitude = $var['latitude'] ? $var['latitude'] : request('latitude');
        $longitude = $var['longitude'] ? $var['longitude'] : request('longitude');
        $time = $var['time'] ? $var['time'] : request('time');
        $start_note = $var['start_note'] ? $var['start_note'] : request('start_note');
        $log = $var['log'] ? $var['log'] : request('log');
        $start_status = $var['start_status'];
        $uploadKey = $var['uploadKey'] ? $var['uploadKey'] : request('uploadKey');
        $start_location_status = $var['start_location_status'] ? $var['start_location_status'] : request('start_location_status');
        //แก้เบิ้ลมา หาวิธีทางแอพไม่ได้ เครื่องบางคนเบิ้ล//ตูน
        $search = "";
        if ($log) {
            $search = "AND `log` = '{$log}'";
        }

        //if ($check) {
        ///----
        $user = getMyOrgId($uid);
        $org_sub_id = getMyOrgSubId($uid, $user['org_id']);
        ////
        if ($uid) {
            $db = getDBO();
            $sql = "
				SELECT		*
				FROM		attend_" . $user['org_id'] . "_information
				WHERE		create_by = '{$uid}'
				AND			status = '1'
                AND         cid != '3'
				AND			DATE(create_date) = CURDATE()
                {$search}
				";

            //exit($sql);

            $db->setQuery($sql);
            $rs = $db->loadAssocList();
            $len = count($rs);
            if ($len) {
                // $result[0] = array(
                //     'status' => 'fail',
                //     'uid' => $uid,
                //     'uploadKey' => null,
                //     'status' => null,
                //     'msg' => 'บันทึกไม่สำเร็จ มีข้อมูลอยู่แล้ว',
                // );
                // echo json_encode($result);
                // exit();
            }
        }

        //}

        //แก้เบิ้ลมา หาวิธีทางแอพไม่ได้ เครื่องบางคนเบิ้ล//ตูน
        // Support pre-uploaded images: if uploadKey is provided from app, use it directly
        if ($uploadKey == '' || $uploadKey == null) {
            // Generate new uploadKey if not provided (backward compatibility)
            $uploadKey = md5(time() . rand(0, 100) . $uid);
        } else {
            // Use uploadKey from app as-is (image already uploaded)
            // uploadKey format from app: timestamp_uid
            // No need to re-hash, just use it directly
        }

        $start_time = date('H:i:s');

        if ($start_status == "4") {
            $start_status =  $this->checkAddOtTime($user['org_id'], $uid);
        }

        $obj = new stdClass();
        $obj->cid = $cid;
        $obj->uploadKey = $uploadKey;
        $obj->local_id = Site::$local_id;
        $obj->branch_id = $branch_id;
        $obj->start_latitude = $latitude;
        $obj->start_longitude = $longitude;
        // $obj->start_time = $time;
        $obj->start_time = $start_time;
        $obj->start_status = $start_status;
        $obj->start_note = $start_note;

        //time id เช็ค login คนละเวลา
        if ($log) {
            $obj->log = $log;
        }
        $obj->start_location_status = $start_location_status;
        $obj->attend_status = '0';
        $obj->status = '1';
        if ($org_sub_id) {
            $obj->org_id = $org_sub_id;
        }
        if ($uid != "") {
            $obj->create_by = $uid;
        }
        $obj->create_ip = getIPAddress();
        $obj->create_date = date('Y-m-d') . ' ' . $time;

        $db = getDBO();
        $insert = $db->insertObject('attend_' . $user['org_id'] . '_information', $obj);

        $result[0] = array(
            'uid' => $uid,
            'uploadKey' => $uploadKey,
            'status' => $insert ? 'success' : 'fail',
            'msg' => $insert ? 'บันทึกสำเร็จ' : 'บันทึกไม่สำเร็จ',
        );
        echo json_encode($result);

        // response_json(json_encode($result));

        // $this->appUploadFile($org_id, 'attend', $uploadKey, $_FILES, 'i_start', $uid);
    }

    public function checkAddOtTime($org_id, $uid)
    {
        // $org_id = request('org_id');
        // $uid    = request('uid');
        $db = getDBO();
        $sql = "SELECT		*
                FROM		attend_" . $org_id . "_information
                WHERE		create_by = '{$uid}'
                AND			status = '1'
                AND			DATE(create_date) = CURDATE()
                ORDER BY id ASC
                LIMIT 1";
        $db->setQuery($sql);
        $rs = $db->loadAssocList();
        $len = count($rs);
        if ($len) {
            if ($rs[0]['start_time'] && $rs[0]['end_time']) {
                return "4";
            } else {
                $time_id = $rs[0]['log'];
                $time_id = str_replace("timeid_", "", $time_id);
                $day = date('N');
                $day_attend = $day - 1;
                $sql = "SELECT		*
                        FROM        time_information
                        WHERE       id = '{$time_id}'
                        AND         status = '1'";
                $db->setQuery($sql);
                $time = $db->loadAssocList();
                if ($time) {
                    $time = $time[0];
                    $time_data = $time['description'];
                    $time_data = json_decode($time_data, true);
                    $len_time = count($time_data);
                    if ($len_time) {
                        $time_start = $time_data[$day_attend]['time_start'];
                        $this_time_login = strtotime($time_start);
                        $time_login = $rs[0]['start_time'];
                        $time_login = strtotime($time_login);
                        if ($time_login > $this_time_login) {
                            return "1";
                        } else {
                            return "0";
                        }
                    }
                }
            }
        }
    }


    public function updateAttendStart()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;

        $status = $var['status'] ? $var['status'] : request('status');
        if ($status == '1') {
            $uid = $var['uid'] ? $var['uid'] : request('uid');
            $start_location_note = $var['start_location_note'] ? $var['start_location_note'] : request('start_location_note');
            $start_location_sub_status = $var['start_location_sub_status'] ? $var['start_location_sub_status'] : request('start_location_sub_status');
        } else {
            $uid = $var['uid'] ? $var['uid'] : request('uid');
            $end_location_note = $var['end_location_note'] ? $var['end_location_note'] : request('end_location_note');
            $end_location_sub_status = $var['end_location_sub_status'] ? $var['end_location_sub_status'] : request('end_location_sub_status');
        }

        $user = getMyOrgId($uid);
        $org_sub_id = getMyOrgSubId($uid, $user['org_id']);
        if ($uid != '') {
            $db = getDBO();
            $sql = "
				SELECT		*
				FROM		attend_" . $user['org_id'] . "_information
				WHERE		create_by = '{$uid}'
				AND			status = '1'
                AND         cid != '3'
				AND			DATE(create_date) = CURDATE()
				";

            //exit($sql);

            $db->setQuery($sql);
            $rs = $db->loadAssocList();
            $len = count($rs);

            $obj = new stdClass();
            $obj->id = $rs[0]['id'];
            $obj->local_id = Site::$local_id;
            if ($status == '1') {
                $obj->start_location_note = $start_location_note;
                $obj->start_location_sub_status = $start_location_sub_status;
            } else {
                $obj->end_location_note = $end_location_note;
                $obj->end_location_status = '1';
                $obj->end_location_sub_status = $end_location_sub_status;
            }
            if ($org_sub_id) {
                $obj->org_id = $org_sub_id;
            }


            $db = getDBO();
            $insert = $db->updateObject("attend_" . $user['org_id'] . "_information", $obj, 'id');

            $result[0] = array(
                'id' => $rs[0]['id'],
                'status' => $insert ? 'success' : 'fail',
                'msg' => $insert ? 'บันทึกสำเร็จ' : 'บันทึกไม่สำเร็จ'
            );
        } else {
            $result[0] = array(
                'id' => '',
                'status' => 'fail',
                'msg' =>  'บันทึกไม่สำเร็จ'
            );
        }

        echo json_encode($result);

        // response_json(json_encode($result));

        // $this->appUploadFile($org_id, 'attend', $uploadKey, $_FILES, 'i_start', $uid);
    }


    public function attendEnd()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;


        $uid = $var['uid'] ? $var['uid'] : request('uid');
        $branch_id = $var['branch_id'] ? $var['branch_id'] : request('branch_id', 0);
        $latitude = $var['latitude'] ? $var['latitude'] : request('latitude');
        $longitude = $var['longitude'] ? $var['longitude'] : request('longitude');
        $time = $var['time'] ? $var['time'] : request('time');
        $end_note = $var['end_note'] ? $var['end_note'] : request('end_note');
        $end_status = $var['end_status'];
        $log = $var['log'] ? $var['log'] : request('log');
        $uploadKey = $var['uploadKey'] ? $var['uploadKey'] : request('uploadKey');
        //แก้เบิ้ลมา หาวิธีทางแอพไม่ได้ เครื่องบางคนเบิ้ล//ตูน
        /*if ($uploadKey == '') {
            $uploadKey = md5(time() . rand(0, 100));
        }*/
        $search = "";
        if ($log) {
            $search = "AND `log` = '{$log}'";
        }


        //if ($check) {
        $user = getMyOrgId($uid);
        $org_sub_id = getMyOrgSubId($uid, $user['org_id']);
        if ($uid) {
            $db = getDBO();
            $sql = "
				SELECT		*
				FROM		attend_" . $user['org_id'] . "_information
				WHERE		create_by = '{$uid}'
				AND			status = '1'
                AND         cid = 2
				AND			DATE(create_date) = CURDATE()
                {$search}
                ORDER BY id DESC
                LIMIT 1
				";

            //exit($sql);

            $db->setQuery($sql);
            $rs = $db->loadAssocList();
            $len = count($rs);

            $end_time = date('H:i:s');

            if ($len) {
                $obj = new stdClass();
                $obj->id = $rs[0]['id'];
                $obj->local_id = Site::$local_id;
                $obj->end_latitude = $latitude;
                $obj->end_longitude = $longitude;
                $obj->end_time = $end_time;
                $obj->end_status = $end_status == '' ? '0' : $end_status;
                $obj->end_note = $end_note;
                $obj->attend_status = '1';
                $obj->status = '1';
                if ($org_sub_id) {
                    $obj->org_id = $org_sub_id;
                }
                if ($uid != "") {
                    $obj->update_by = $uid;
                }
                $obj->update_ip = getIPAddress();
                $obj->update_date = date('Y-m-d') . ' ' . $time;

                $db = getDBO();
                $insert = $db->updateObject("attend_" . $user['org_id'] . "_information", $obj, 'id');

                $result[0] = array(
                    'id' => $rs[0]['id'],
                    'uid' => $uid,
                    'uploadKey' => $uploadKey != "" ? $uploadKey : $rs[0]['uploadKey'],
                    'status' => $insert ? 'success' : 'fail',
                    'msg' => $insert ? 'บันทึกสำเร็จ' : 'บันทึกไม่สำเร็จ'
                );
                echo json_encode($result);

                exit();
            } else {
                $result[0] = array(
                    'status' => 'fail',
                    'uid' => $uid,
                    'uploadKey' => null,
                    'status' => null,
                    'msg' => 'บันทึกไม่สำเร็จ มีข้อมูลอยู่แล้ว',
                );
                echo json_encode($result);
                exit();
            }
        }
    }


    function appUploadFile_backup()
    {
        $cmd = $_POST['cmd'];
        $uploadKey = $_POST['uploadKey'];
        $uid = $_POST['uid'];
        $attact_type = $_POST['attact_type'];
        $user = getMyOrgId($uid);
        if (!count($_FILES['file']['name'])) {
            $result[0] = array(
                "result" => 'fail',
                "latest_path" => ''
            );
        } else {
            // if (!count($files)) {
            //     return 0;
            // }
            $db = getDBO();

            $file_path = "files/com_attend_" . $user['org_id'] . "/";
            if (!is_dir($file_path)) {
                mkdir($file_path);
            }

            // $latest_path = "";


            $filename = date("Ymd") . '_' .  substr(md5(date("sa:i:h")), 0, 15) . '.' . pathinfo($_FILES['file']['name'], PATHINFO_EXTENSION);
            $up =  move_uploaded_file($_FILES['file']['tmp_name'], $file_path . $filename);
            if ($up) {
                $obj = new stdClass();
                $obj->uploadKey = $uploadKey;
                $obj->filename = $filename;
                $obj->filepath = $file_path . $filename;
                $obj->filesizes = $_FILES['file']['size'];
                $obj->extension = pathinfo($_FILES['file']['name'], PATHINFO_EXTENSION);
                $obj->attact_type = $attact_type;
                $obj->status = '1';
                if ($uid != "") {
                    $obj->create_by = $uid;
                }
                $obj->create_ip = getIPAddress();
                $obj->create_date = date("Y-m-d H:i:s");
                $db->insertObject("attend_" . $user['org_id'] . "_attachments", $obj);
                $latest_path = $file_path . $filename;
            }
            $result[0] = array(
                "result" => 'success',
                "latest_path" => $latest_path,
            );
        }


        echo json_encode($result, JSON_UNESCAPED_UNICODE);
    }
    function appUploadFile()
    {
        $cmd = $_POST['cmd'];
        $uploadKey = $_POST['uploadKey'];

        $uid = $_POST['uid'];
        $attact_type = $_POST['attact_type'];
        $user = getMyOrgId($uid);

        //---
        if ($uploadKey == '' && $attact_type == 'i_start') {
            $uploadKey = md5(time() . rand(0, 100));
        }
        //---
        if (!count($_FILES['file']['name'])) {
            $result[0] = array(
                "result" => 'fail',
                "latest_path" => ''
            );
        } else {
            $file_path = "files/com_attend_" . $user['org_id'] . "/";
            $table = "attend_" . $user['org_id'] . "_attachments";
            $path = insert_file($file_path, $table, $uploadKey, $_FILES['file'], $attact_type, $uid);
            $result[0] = array(
                "result" => 'success',
                "latest_path" => $path,
            );
        }


        echo json_encode($result, JSON_UNESCAPED_UNICODE);
    }

    public function attendHistory()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;

        $uid = $var['uid'] ? $var['uid'] : request('uid');
        $user = getMyOrgId($uid);

        $db = getDBO();
        $sql = "
            SELECT		*
            FROM		attend_" . $user['org_id'] . "_information
            WHERE		create_by = '{$uid}'
            AND			status = '1'
            AND			DATE(create_date) = CURDATE()
            ORDER BY id ASC
            ";


        $db->setQuery($sql);
        $rs = $db->loadAssocList();
        $len = count($rs);
        //----

        $img1 = '';
        $img2 = '';
        ///---
        $num = 0;
        $data = array();
        $time_status = '0';
        $etime_status = '0';
        if ($len) {
            for ($j = 0; $j < $len; $j++) {
              
                $sql1 = "
                    SELECT		*
                    FROM		attend_" . $user['org_id'] . "_attachments
                    WHERE		status = '1'
                    AND         uploadKey = '{$rs[$j]['uploadKey']}'
                    ";
                $db->setQuery($sql1);
                $rs_img = $db->loadAssocList();
                $len_img = count($rs_img);
                //----
                for ($i = 0; $i < $len_img; $i++) {
                    if ($rs_img[$i]['attact_type'] == 'i_start') {
                        $img1 = $rs_img[$i]['filepath'];
                    } else if ($rs_img[$i]['attact_type'] == 'i_end') {
                        $img2 = $rs_img[$i]['filepath'];
                    }
                }
                if ($rs[$j]['start_time'] != '') {
                    if ($len > 1) {
                        // if ($j == 1) {
                        //     $time_status = '5';
                        // } else {
                        //     $time_status = $rs[$j]['start_status'];
                        // }
                        if ($rs[$j]['cid'] == "3") {
                            $time_status = "4";
                        } else if ($rs[$j]['start_status'] == "4") {
                            $time_status = "5";
                        } else {
                            $time_status = $rs[$j]['start_status'];
                        }
                    }
                    $data[$num] = array(
                        "time" => $rs[$j]['start_time'],
                        "time_status" => $time_status,
                        "time_id_name" => getNameAttendTime($rs[$j]['log']),
                        "image" => $img1,
                        "lat" => $rs[$j]['start_latitude'],
                        "lng" => $rs[$j]['start_longitude'],
                        "note" => $rs[$j]['start_location_note'] ? $rs[$j]['start_location_note'] : '',
                        "detail" => $rs[$j]['start_note'],
                        "cid" => $rs[$j]['cid'],
                        "status" => "1",
                    );
                }
                if ($rs[$j]['end_time'] != '') {
                    if ($len > 1) {
                        // if ($j == 1) {
                        //     $etime_status = '5';
                        // } else {
                        //     $etime_status = $rs[$j]['end_status'];
                        // }
                        if ($rs[$j]['cid'] == "3") {
                            $etime_status = "4";
                        } else if ($rs[$j]['start_status'] == "4") {
                            $etime_status = "5";
                        } else {
                            $etime_status = $rs[$j]['end_status'];
                        }
                    }
                    $num++;
                    $data[$num] = array(
                        "time" => $rs[$j]['end_time'],
                        "time_status" => $etime_status,
                        "time_id_name" => getNameAttendTime($rs[$j]['log']),
                        "image" => $img2,
                        "lat" => $rs[$j]['end_latitude'],
                        "lng" => $rs[$j]['end_longitude'],
                        "note" => $rs[$j]['end_location_note'] ? $rs[$j]['end_location_note'] : '',
                        "detail" => $rs[$j]['end_note'],
                        "cid" => $rs[$j]['cid'],
                        "status" => "2"
                    );
                }
                $num++;
            }
            $result[0] = array(
                "msg" => "success",
                "result" => $data,
            );
        } else {
            $result[0] = array(
                "msg" => "fail",
                "result" => [],
            );
        }
        echo json_encode($result, JSON_UNESCAPED_UNICODE);
        exit();
    }

    ///--- OUTSIDE



    public function attandCheckOutside()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        $uid = $var['uid'] ? $var['uid'] : request('uid');
        $user = getMyOrgId($uid);
        $db = getDBO();
        $sql = "
				SELECT		*
				FROM		attend_" . $user['org_id'] . "_information
				WHERE		create_by = '{$uid}'
				AND			status = '1'
                AND         cid = 3
				AND			DATE(create_date) = CURDATE()
				";
        // exit($sql);
        $db->setQuery($sql);
        $rs = $db->loadAssocList();
        $len = count($rs);
        ///-----
        $db1 = getDBO();
        $sql1 = "
				SELECT		*
				FROM		attend_" . $user['org_id'] . "_attachments
				WHERE		create_by = '{$uid}'
				AND			status = '1'
                AND         uploadKey = '{$rs[0]['uploadKey']}'
				AND			DATE(create_date) = CURDATE()
				";
        // exit($sql);
        $db1->setQuery($sql1);
        $rs_images = $db1->loadAssocList();
        $image_start = '';
        $image_end  = '';
        for ($i = 0; $i < count($rs_images); $i++) {
            if ($rs_images[$i]['attact_type'] == 'i_start') {
                $image_start = $rs_images[$i]['filepath'];
            } else {
                $image_end = $rs_images[$i]['filepath'];
            }
        }
        ///-----
        $result[0] = array(
            'cid' => '3',
            'status' => $len > 0 ? 'success' : 'fail',
            'create_date' => $rs[0]['create_date'],
            'start_time' => $rs[0]['start_time'],
            'start_note' => $rs[0]['start_note'],
            'start_images' => $image_start,
            'start_status' => $rs[0]['start_status'],
            'end_time' => $rs[0]['end_time'],
            'end_note' => $rs[0]['end_note'],
            'end_images' => $image_end,
            'end_status' => $rs[0]['end_status'],
        );
        echo json_encode($result);
        exit();
    }

    public function attendOutsideStart()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;


        $uid = $var['uid'] ? $var['uid'] : request('uid');
        $cid = $var['cid'] ? $var['cid'] : request('cid', '3');
        $branch_id = $var['branch_id'] ? $var['branch_id'] : request('branch_id', 0);
        $latitude = $var['latitude'] ? $var['latitude'] : request('latitude');
        $longitude = $var['longitude'] ? $var['longitude'] : request('longitude');
        $time = $var['time'] ? $var['time'] : request('time');
        $start_note = $var['start_note'] ? $var['start_note'] : request('start_note');
        //แก้เบิ้ลมา หาวิธีทางแอพไม่ได้ เครื่องบางคนเบิ้ล//ตูน

        //if ($check) {
        ///----
        $user = getMyOrgId($uid);
        ////
        // if ($uid) {
        //     $db = getDBO();
        //     $sql = "
        // 		SELECT		*
        // 		FROM		attend_" . $user['org_id'] . "_information
        // 		WHERE		create_by = '{$uid}'
        //         AND         cid = 3
        // 		AND			status = '1'
        // 		AND			DATE(create_date) = CURDATE()
        // 		";

        //     //exit($sql);

        //     $db->setQuery($sql);
        //     $rs = $db->loadAssocList();
        //     $len = count($rs);
        //     if ($len) {
        //         $result[0] = array(
        //             'status' => 'fail',
        //             'uid' => $uid,
        //             'uploadKey' => null,
        //             'status' => null,
        //             'msg' => 'บันทึกไม่สำเร็จ มีข้อมูลอยู่แล้ว',
        //         );
        //         echo json_encode($result);
        //         exit();
        //     }
        // }

        //}

        //แก้เบิ้ลมา หาวิธีทางแอพไม่ได้ เครื่องบางคนเบิ้ล//ตูน


        $uploadKey = md5(time() . rand(0, 100) . $uid);
        $start_time = date('H:i:s');

        $obj = new stdClass();
        $obj->cid = $cid;
        $obj->uploadKey = $uploadKey;
        $obj->local_id = Site::$local_id;
        $obj->branch_id = $branch_id;
        $obj->start_latitude = $latitude;
        $obj->start_longitude = $longitude;
        // $obj->start_time = $time;
        $obj->start_time = $start_time;
        $obj->start_note = $start_note;
        $obj->attend_status = '0';
        $obj->status = '1';
        if ($uid != "") {
            $obj->create_by = $uid;
        }
        $obj->create_ip = getIPAddress();
        $obj->create_date = date('Y-m-d') . ' ' . $time;

        $db = getDBO();
        $insert = $db->insertObject('attend_' . $user['org_id'] . '_information', $obj);

        $result[0] = array(
            'uid' => $uid,
            'uploadKey' => $uploadKey,
            'status' => $insert ? 'success' : 'fail',
            'msg' => $insert ? 'บันทึกสำเร็จ' : 'บันทึกไม่สำเร็จ',
        );
        echo json_encode($result);

        // response_json(json_encode($result));

        // $this->appUploadFile($org_id, 'attend', $uploadKey, $_FILES, 'i_start', $uid);
    }

    public function attendOutsideEnd()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;


        $uid = $var['uid'] ? $var['uid'] : request('uid');
        $branch_id = $var['branch_id'] ? $var['branch_id'] : request('branch_id', 0);
        $latitude = $var['latitude'] ? $var['latitude'] : request('latitude');
        $longitude = $var['longitude'] ? $var['longitude'] : request('longitude');
        $time = $var['time'] ? $var['time'] : request('time');
        $end_note = $var['end_note'] ? $var['end_note'] : request('end_note');
        $end_status = $var['end_status'];

        //แก้เบิ้ลมา หาวิธีทางแอพไม่ได้ เครื่องบางคนเบิ้ล//ตูน

        //if ($check) {
        $user = getMyOrgId($uid);
        if ($uid) {
            $db = getDBO();
            $sql = "
				SELECT		*
				FROM		attend_" . $user['org_id'] . "_information
				WHERE		create_by = '{$uid}'
				AND			status = '1'
                AND         cid = 3
				AND			DATE(create_date) = CURDATE()
				";

            //exit($sql);

            $db->setQuery($sql);
            $rs = $db->loadAssocList();
            $len = count($rs);

            $end_time = date('H:i:s');

            if ($len) {
                $obj = new stdClass();
                $obj->id = $rs[0]['id'];
                $obj->local_id = Site::$local_id;
                $obj->end_latitude = $latitude;
                $obj->end_longitude = $longitude;
                // $obj->end_time = $time;
                $obj->end_time = $end_time;
                $obj->end_status = $end_status == '' ? '0' : $end_status;
                $obj->end_note = $end_note;
                $obj->attend_status = '1';
                $obj->status = '1';
                if ($uid != "") {
                    $obj->update_by = $uid;
                }
                $obj->update_ip = getIPAddress();
                $obj->update_date = date('Y-m-d') . ' ' . $time;

                $db = getDBO();
                $insert = $db->updateObject("attend_" . $user['org_id'] . "_information", $obj, 'id');

                $result[0] = array(
                    'id' => $rs[0]['id'],
                    'uid' => $uid,
                    'uploadKey' => $rs[0]['uploadKey'],
                    'status' => $insert ? 'success' : 'fail',
                    'msg' => $insert ? 'บันทึกสำเร็จ' : 'บันทึกไม่สำเร็จ'
                );
                echo json_encode($result);

                exit();
                $result[0] = array(
                    'status' => 'fail',
                    'uid' => $uid,
                    'uploadKey' => null,
                    'status' => null,
                    'msg' => 'บันทึกไม่สำเร็จ มีข้อมูลอยู่แล้ว',
                );
                echo json_encode($result);
                exit();
            }
        }
    }

    // ============================================================
    // V2 API Functions - 2-Step Synchronous Upload
    // Created: 2024-12-18
    // These functions support the new 2-API flow:
    // Step 1: uploadImageV2 - Upload image first, get uploadKey
    // Step 2: attendStartV2/attendEndV2 - Submit attendance with uploadKey
    // ============================================================

    /**
     * V2: Upload Image First
     * 
     * Receives image file, saves it, returns uploadKey
     * Does NOT create attendance record yet
     * For checkout (i_end), uses existing uploadKey_end from today's record
     */
    public function uploadImageV2()
    {
        $result = array();
        
        try {
            // Get parameters
            $uid = isset($_POST['uid']) ? $_POST['uid'] : '';
            $attact_type = isset($_POST['attact_type']) ? $_POST['attact_type'] : 'i_start';
            
            // Validate UID
            if (empty($uid)) {
                $result[0] = array(
                    'success' => false,
                    'uploadKey' => null,
                    'imagePath' => null,
                    'error' => 'UID is required'
                );
                echo json_encode($result, JSON_UNESCAPED_UNICODE);
                return;
            }
            
            // Check if file was uploaded
            if (!isset($_FILES['file']) || !isset($_FILES['file']['name']) || empty($_FILES['file']['name'])) {
                $result[0] = array(
                    'success' => false,
                    'uploadKey' => null,
                    'imagePath' => null,
                    'error' => 'No file uploaded'
                );
                echo json_encode($result, JSON_UNESCAPED_UNICODE);
                return;
            }
            
            // Get user's org_id
            $user = getMyOrgId($uid);
            if (!$user || !isset($user['org_id'])) {
                $result[0] = array(
                    'success' => false,
                    'uploadKey' => null,
                    'imagePath' => null,
                    'error' => 'User not found'
                );
                echo json_encode($result, JSON_UNESCAPED_UNICODE);
                return;
            }
            
            // Determine uploadKey based on attact_type
            $uploadKey = '';
            $db = getDBO();
            
            if ($attact_type == 'i_end') {
                // For checkout: get existing uploadKey from today's check-in record
                $sql = "SELECT id, uploadKey FROM attend_" . $user['org_id'] . "_information 
                        WHERE create_by = '{$uid}' 
                        AND status = '1' 
                        AND DATE(create_date) = CURDATE() 
                        ORDER BY id DESC 
                        LIMIT 1";
                $db->setQuery($sql);
                $rs = $db->loadAssocList();
                
                if ($rs && count($rs) > 0 && !empty($rs[0]['uploadKey'])) {
                    // Use the same uploadKey as check-in
                    $uploadKey = $rs[0]['uploadKey'];
                } else {
                    // No record found, return error
                    $result[0] = array(
                        'success' => false,
                        'uploadKey' => null,
                        'imagePath' => null,
                        'error' => 'No attend record found for today'
                    );
                    echo json_encode($result, JSON_UNESCAPED_UNICODE);
                    return;
                }
            } else {
                // For check-in: generate new uploadKey
                $uploadKey = md5(time() . rand(0, 10000) . $uid . uniqid());
            }
            
            // Define file path
            $file_path = "files/com_attend_" . $user['org_id'] . "/";
            $table = "attend_" . $user['org_id'] . "_attachments";
            
            // Upload the file
            $path = insert_file($file_path, $table, $uploadKey, $_FILES['file'], $attact_type, $uid);
            
            if ($path) {
                $result[0] = array(
                    'success' => true,
                    'uploadKey' => $uploadKey,
                    'imagePath' => $path,
                    'error' => null
                );
            } else {
                $result[0] = array(
                    'success' => false,
                    'uploadKey' => $uploadKey,
                    'imagePath' => null,
                    'error' => 'Failed to save file'
                );
            }
            
        } catch (Exception $e) {
            $result[0] = array(
                'success' => false,
                'uploadKey' => null,
                'imagePath' => null,
                'error' => $e->getMessage()
            );
        }
        
        echo json_encode($result, JSON_UNESCAPED_UNICODE);
    }

    /**
     * V2: Attend Start (Check-In) with pre-uploaded image
     * 
     * Receives uploadKey from previous upload, creates attendance record
     */
    public function attendStartV2()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        
        // Get parameters
        $uid = isset($var['uid']) ? $var['uid'] : '';
        $uploadKey = isset($var['uploadKey']) ? $var['uploadKey'] : '';
        $cid = isset($var['cid']) ? $var['cid'] : '2';
        $branch_id = isset($var['branch_id']) ? $var['branch_id'] : 0;
        $latitude = isset($var['latitude']) ? $var['latitude'] : '';
        $longitude = isset($var['longitude']) ? $var['longitude'] : '';
        $time = isset($var['time']) ? $var['time'] : date('H:i:s');
        $start_note = isset($var['start_note']) ? $var['start_note'] : '';
        $log = isset($var['log']) ? $var['log'] : '';
        $start_status = isset($var['start_status']) ? $var['start_status'] : '1';
        $start_location_status = isset($var['start_location_status']) ? $var['start_location_status'] : '';
        
        // Validate required fields
        if (empty($uid)) {
            $result[0] = array(
                'status' => 'fail',
                'uid' => $uid,
                'uploadKey' => $uploadKey,
                'msg' => 'UID is required'
            );
            echo json_encode($result, JSON_UNESCAPED_UNICODE);
            return;
        }
        
        if (empty($uploadKey)) {
            $result[0] = array(
                'status' => 'fail',
                'uid' => $uid,
                'uploadKey' => null,
                'msg' => 'uploadKey is required - please upload image first'
            );
            echo json_encode($result, JSON_UNESCAPED_UNICODE);
            return;
        }
        
        // Get user info
        $user = getMyOrgId($uid);
        $org_sub_id = getMyOrgSubId($uid, $user['org_id']);
        
        // Check for OT status
        if ($start_status == "4") {
            $start_status = $this->checkAddOtTime($user['org_id'], $uid);
        }
        
        $start_time = date('H:i:s');
        
        // Create attendance record
        $obj = new stdClass();
        $obj->cid = $cid;
        $obj->uploadKey = $uploadKey; // Use the pre-uploaded key
        $obj->local_id = Site::$local_id;
        $obj->branch_id = $branch_id;
        $obj->start_latitude = $latitude;
        $obj->start_longitude = $longitude;
        $obj->start_time = $start_time;
        $obj->start_status = $start_status;
        $obj->start_note = $start_note;
        
        if ($log) {
            $obj->log = $log;
        }
        
        $obj->start_location_status = $start_location_status;
        $obj->attend_status = '0';
        $obj->status = '1';
        
        if ($org_sub_id) {
            $obj->org_id = $org_sub_id;
        }
        
        if ($uid != "") {
            $obj->create_by = $uid;
        }
        
        $obj->create_ip = getIPAddress();
        $obj->create_date = date('Y-m-d') . ' ' . $time;
        
        $db = getDBO();
        $insert = $db->insertObject('attend_' . $user['org_id'] . '_information', $obj);
        
        $result[0] = array(
            'uid' => $uid,
            'uploadKey' => $uploadKey,
            'status' => $insert ? 'success' : 'fail',
            'msg' => $insert ? 'บันทึกเข้างานสำเร็จ' : 'บันทึกไม่สำเร็จ'
        );
        
        echo json_encode($result, JSON_UNESCAPED_UNICODE);
    }

    /**
     * V2: Attend End (Check-Out) with pre-uploaded image
     * 
     * Receives uploadKey from previous upload, updates attendance record
     */
    public function attendEndV2()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        
        // Get parameters
        $uid = isset($var['uid']) ? $var['uid'] : '';
        $uploadKey = isset($var['uploadKey']) ? $var['uploadKey'] : '';
        $latitude = isset($var['latitude']) ? $var['latitude'] : '';
        $longitude = isset($var['longitude']) ? $var['longitude'] : '';
        $time = isset($var['time']) ? $var['time'] : date('H:i:s');
        $end_note = isset($var['end_note']) ? $var['end_note'] : '';
        $end_status = isset($var['end_status']) ? $var['end_status'] : '1';
        $end_location_status = isset($var['end_location_status']) ? $var['end_location_status'] : '';
        
        // Validate required fields
        if (empty($uid)) {
            $result[0] = array(
                'status' => 'fail',
                'uid' => $uid,
                'uploadKey' => $uploadKey,
                'msg' => 'UID is required'
            );
            echo json_encode($result, JSON_UNESCAPED_UNICODE);
            return;
        }
        
        if (empty($uploadKey)) {
            $result[0] = array(
                'status' => 'fail',
                'uid' => $uid,
                'uploadKey' => null,
                'msg' => 'uploadKey is required - please upload image first'
            );
            echo json_encode($result, JSON_UNESCAPED_UNICODE);
            return;
        }
        
        // Get user info
        $user = getMyOrgId($uid);
        
        $end_time = date('H:i:s');
        
        // Find today's check-in record
        $db = getDBO();
        $sql = "
            SELECT * FROM attend_" . $user['org_id'] . "_information
            WHERE create_by = '{$uid}'
            AND status = '1'
            AND attend_status = '0'
            AND DATE(create_date) = CURDATE()
            ORDER BY id DESC
            LIMIT 1
        ";
        
        $db->setQuery($sql);
        $rs = $db->loadAssoc();
        
        if (!$rs) {
            $result[0] = array(
                'status' => 'fail',
                'uid' => $uid,
                'uploadKey' => $uploadKey,
                'msg' => 'ไม่พบข้อมูลเข้างานวันนี้'
            );
            echo json_encode($result, JSON_UNESCAPED_UNICODE);
            return;
        }
        
        // Update the record with check-out info
        $updateSql = "
            UPDATE attend_" . $user['org_id'] . "_information
            SET 
                end_time = '{$end_time}',
                end_latitude = '{$latitude}',
                end_longitude = '{$longitude}',
                end_status = '{$end_status}',
                end_note = '{$end_note}',
                end_location_status = '{$end_location_status}',
                attend_status = '1',
                uploadKey_end = '{$uploadKey}'
            WHERE id = '{$rs['id']}'
        ";
        
        $db->setQuery($updateSql);
        $update = $db->query();
        
        $result[0] = array(
            'uid' => $uid,
            'uploadKey' => $uploadKey,
            'status' => $update ? 'success' : 'fail',
            'msg' => $update ? 'บันทึกออกงานสำเร็จ' : 'บันทึกไม่สำเร็จ'
        );
        
        echo json_encode($result, JSON_UNESCAPED_UNICODE);
    }
}
