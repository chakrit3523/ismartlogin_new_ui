<?php if (!defined('BASEPATH')) exit('No direct script access allowed');

class summary extends CI_Controller
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
        '_CMD'              => 'organization',
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
        $this->getMember();
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
    public function attendSummaryList()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;

        $language = $var['language'] ? $var['language'] : request('language', $this->language);
        $platform = $var['platform'] ? $var['platform'] : request('platform', 'android');

        $org_id = $var['org_id'] ? $var['org_id'] : request('org_id');
        $branch_id = $var['branch_id'] ? $var['branch_id'] : request('branch_id');
        $department_id = $var['department_id'] ? $var['department_id'] : request('department_id');
        $uid = $var['uid'] ? $var['uid'] : request('uid');
        $mode = $var['mode'] ? $var['mode'] : request('mode', 'summary');
        $create_date = $var['create_date'] ? $var['create_date'] : request('create_date');


        $start_limit = $var['start'] ? $var['start'] : request('start', 0);
        $rows = $var['rows'] ? $var['rows'] : request('rows', $this->maxRows);

        $user = getMyOrgId($uid);
        $limit_start = 0;
        if ($start_limit) {
            $limit_start = $start_limit * $rows;
        }

        $db = getDBO();
        $sql_search = '';
        if ($create_date) {
            $sql_search .= " AND i.create_date='{$create_date}' ";
        }
        if ($branch_id) {
            $sql_search .= " AND i.branch_id='{$branch_id}' ";
        } else {
            $branch_id = $department_id;
        }
        if ($department_id) {
            $sql_search .= " AND i.branch_id='{$department_id}' ";
        }
        if (!$branch_id && !$department_id) {
            $sql_search .= " AND i.branch_id IS NULL ";
        }


        $item = array();
        if ($mode == 'list') {
            $sql = "
				SELECT			i.cid, DATE(i.create_date) AS create_date
				FROM			attend_" .  $org_id .  "_information AS i
				WHERE			i.local_id='" . Site::$local_id . "'
								{$sql_search}
				GROUP BY		DATE(i.create_date)
				ORDER BY		i.create_date DESC
				LIMIT			{$limit_start}, {$rows}
			";
            $db->setQuery($sql);
            // exit($db->getQuery());
            if ($_GET['debug']) {
                exit($db->getQuery());
            }
            $rs = $db->loadAssocList();
            $len = count($rs);
            for ($i = 0; $i < $len; $i++) {
                $item[$i]['cid'] = $rs[$i]['cid'];
                $item[$i]['create_date'] = $rs[$i]['create_date'];
                $item[$i]['create_date_th'] = $rs[$i]['create_date'];
                fullThaiDate($item[$i]['create_date_th']);

                $list = $this->attendDailyList_org($org_id);
                $item[$i]['ontime'] = $list['ontime'];
                $item[$i]['late'] = $list['late'];
                $item[$i]['outside'] = $list['outside'];
                $item[$i]['absence'] = $list['absence'];
                $item[$i]['leave'] = array();
            }
        } else {
            updateAttendSummary($org_id, $branch_id);
            $sql = "
				SELECT			i.*
				FROM			attend_" . $org_id . "_summary AS i
				WHERE			i.local_id='" . Site::$local_id . "'
								{$sql_search}
				ORDER BY		i.create_date DESC
				LIMIT			{$limit_start}, {$rows}
			";
            $db->setQuery($sql);
            if ($_GET['debug']) {
                exit($db->getQuery());
            }
            // exit($db->getQuery());
            $rs = $db->loadAssocList();
            $len = count($rs);
            for ($i = 0; $i < $len; $i++) {
                $item[$i]['cid'] = $rs[$i]['cid'];
                $item[$i]['create_date'] = $rs[$i]['create_date'];
                $item[$i]['create_date_th'] = $rs[$i]['create_date'];
                fullThaiDate($item[$i]['create_date_th']);
                $item[$i]['ontime'] = (int) $rs[$i]['num_ontime'];
                $item[$i]['late'] = (int) $rs[$i]['num_late'];
                $item[$i]['outside'] = (int) $rs[$i]['num_outside'];
                $item[$i]['absence'] = (int) $rs[$i]['num_absence'];
                $item[$i]['leave'] = 0;
            }
        }

        echo json_encode($item);
        exit();
    }

    public function attendDailyList_org($org_id)
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;

        $language = $var['language'] ? $var['language'] : request('language', $this->language);
        $platform = $var['platform'] ? $var['platform'] : request('platform', 'android');

        $org_id = $var['org_id'] ? $var['org_id'] : request('org_id');
        $uid = $var['uid'] ? $var['uid'] : request('uid');
        $cid = $var['cid'] ? $var['cid'] : request('cid');
        $create_date = $var['create_date'] ? $var['create_date'] : request('create_date');
        $mode = $var['mode'] ? $var['mode'] : request('mode');
        $user = getMyOrgId($uid);

        $daily = orgAttendDaily($org_id, $create_date, $cid);
        $result = array();

        $rs = $daily['rs_ontime'];
        $len = count($rs);
        $item_ontime = array();
        for ($i = 0; $i < $len; $i++) {
            $item_ontime[$i] = orgAttendItem($org_id, $rs[$i]);
        }
        // $result['ontime'] = $item;

        $rs = $daily['rs_late'];
        $len = count($rs);
        $item_late = array();
        for ($i = 0; $i < $len; $i++) {
            $item_late[$i] = orgAttendItem($org_id, $rs[$i]);
        }
        // $result['late'] = $item;

        $rs = $daily['rs_outside'];
        $len = count($rs);
        $item_outside = array();
        for ($i = 0; $i < $len; $i++) {
            $item_outside[$i] = orgAttendItem($org_id, $rs[$i]);
        }

        $rs = $daily['rs_absence'];
        $len = count($rs);
        $item_absence = array();
        for ($i = 0; $i < $len; $i++) {
            $item_absence[$i] = orgAttendItem($org_id, $rs[$i]);
        }
        // $result['absence'] = $item;

        // if ($mode == 'ontime') {
        //     $result[0] = $result['ontime'];
        // } else if ($mode == 'late') {
        //     $result[0] = $result['late'];
        // } else if ($mode == 'absence') {
        //     $result[0] = $result['absence'];
        // } else if ($mode == 'list') {
        //     return $result[0];
        // }
        $sum[0] = array(
            "ontime" => $item_ontime,
            "late" => $item_late,
            "outside" => $item_outside,
            "absence" => $item_absence,
        );

        echo json_encode($sum);
        exit();
    }
    public function attendDailyList()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;

        $language = $var['language'] ? $var['language'] : request('language', $this->language);
        $platform = $var['platform'] ? $var['platform'] : request('platform', 'android');

        $org_id = $var['org_id'] ? $var['org_id'] : request('org_id');
        $branch_id = $var['branch_id'] ? $var['branch_id'] : request('branch_id', 0);
        $uid = $var['uid'] ? $var['uid'] : request('uid');
        $cid = $var['cid'] ? $var['cid'] : request('cid');
        $create_date = $var['create_date'] ? $var['create_date'] : request('create_date');
        $mode = $var['mode'] ? $var['mode'] : request('mode');
        $department_id = $var['department_id'] ? $var['department_id'] : request('department_id');
        if ($org_id == '') {
            $user = getMyOrgId($uid);
            $org_id = $user['org_id'];
        }

        if ($department_id != '') {
            $daily = orgAttendDailyDepartment($org_id, $create_date, $cid, $department_id);
        } else {
            $daily = orgAttendDaily($org_id, $create_date, $cid, $branch_id);
        }

        $result = array();

        $rs = $daily['rs_ontime'];
        $len = count($rs);
        $item_ontime = array();
        for ($i = 0; $i < $len; $i++) {
            $item_ontime[$i] = orgAttendItem($org_id, $rs[$i]);
        }
        // $result['ontime'] = $item;

        $rs = $daily['rs_late'];
        $len = count($rs);
        $item_late = array();
        for ($i = 0; $i < $len; $i++) {
            $item_late[$i] = orgAttendItem($org_id, $rs[$i]);
        }
        // $result['late'] = $item;
        $rs = $daily['rs_outside'];
        $len = count($rs);
        $item_outside = array();
        for ($i = 0; $i < $len; $i++) {
            $item_outside[$i] = orgAttendItem($org_id, $rs[$i]);
            
            // Parse start_note JSON and set topic to start_location_sub_status for outside work (cid=3)
            if (!empty($item_outside[$i]['start_note'])) {
                $start_note_data = json_decode($item_outside[$i]['start_note'], true);
                if (is_array($start_note_data) && isset($start_note_data[0]['topic']) && $start_note_data[0]['topic'] != '') {
                    $item_outside[$i]['start_location_sub_status'] = $start_note_data[0]['topic'];
                    if (isset($start_note_data[0]['description']) && $start_note_data[0]['description'] != '') {
                        $item_outside[$i]['description'] = $start_note_data[0]['description'];
                    }
                }
            }
        }

        $rs = $daily['rs_absence'];
        $len = count($rs);
        $item_absence = array();
        for ($i = 0; $i < $len; $i++) {
            $item_absence[$i] = orgAttendItem($org_id, $rs[$i]);
        }

        $rs = $daily['rs_ot'];
        $len = count($rs);
        $item_ot = array();
        for ($i = 0; $i < $len; $i++) {
            $item_ot[$i] = orgAttendItem($org_id, $rs[$i]);
        }
        // $result['absence'] = $item;


        // $result['absence'] = $item;

        // if ($mode == 'ontime') {
        //     $result[0] = $result['ontime'];
        // } else if ($mode == 'late') {
        //     $result[0] = $result['late'];
        // } else if ($mode == 'absence') {
        //     $result[0] = $result['absence'];
        // } else if ($mode == 'list') {
        //     return $result[0];
        // }
        $sum[0] = array(
            "ontime" => $item_ontime,
            "late" => $item_late,
            "outside" => $item_outside,
            "absence" => $item_absence,
            "ot" => $item_ot
        );

        echo json_encode($sum);
        exit();
    }


    public function attendList()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;

        //$language = $var['language'] ? $var['language'] : request('language', $this->language);
        //$platform = $var['platform'] ? $var['platform'] : request('platform', 'android');

        $budgetYear = $var['budgetYear'] ? $var['budgetYear'] : request('budgetYear');
        $month = $var['month'] ? $var['month'] : request('month');

        $org_id = $var['org_id'] ? $var['org_id'] : request('org_id');
        $uid = $var['uid'] ? $var['uid'] : request('uid');

        $start_limit = $var['start'] ?: request('start', 0);
        $rows = $var['rows'] ?: request('rows', $this->maxRows);
        //$user = getMyOrgId($uid);
        $db = getDBO();

        $limit_start = 0;
        if ($start_limit) {
            $limit_start = $start_limit * $rows;
        }
        $query_add = "";
        if ($budgetYear) {
            $year_prev = $budgetYear - 1;
            $start_date = $year_prev . '-10-01';
            $end_date = $budgetYear . '-09-30';
            $query_add .= " AND (DATE(i.create_date) >= '$start_date' AND DATE(i.create_date) <= '$end_date') ";
        }
        if ($month) {
            $query_add .= " AND MONTH(i.create_date) = '$month' ";
        }

        if ($_GET['check']) {
            $query_add .= " AND i.start_status = '4' ";
        }

        $sql = "
			SELECT				    i.*,a.id AS uid,a.fullname AS fullname
			FROM					attend_" . $org_id . "_information AS i
            INNER JOIN              users AS a
			ON  					i.status='1'
			AND						i.local_id='" . Site::$local_id . "'
			AND						i.create_by='{$uid}'
            AND                     a.id = '{$uid}'
            {$query_add}
            -- GROUP BY				DATE(i.create_date)
			ORDER BY				DATE(i.create_date) DESC, i.id ASC
			LIMIT					{$limit_start} , {$rows}
			";

        $db->setQuery($sql);
        $rs = $db->loadAssocList();
        $len = count($rs);

        if ($_GET['debug']) {
            exit($db->getQuery());
        }

        $item = array();
        for ($i = 0; $i < $len; $i++) {
            $item[$i] = orgAttendItem($org_id, $rs[$i]);
        }

        echo json_encode($item);
        exit();
    }

    public function attendListYala()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;

        //$language = $var['language'] ? $var['language'] : request('language', $this->language);
        //$platform = $var['platform'] ? $var['platform'] : request('platform', 'android');

        $budgetYear = $var['budgetYear'] ? $var['budgetYear'] : request('budgetYear');
        $month = $var['month'] ? $var['month'] : request('month');

        $org_id = $var['org_id'] ? $var['org_id'] : request('org_id');
        $uid = $var['uid'] ? $var['uid'] : request('uid');

        $start_limit = $var['start'] ?: request('start', 0);
        $rows = $var['rows'] ?: request('rows', $this->maxRows);
        //$user = getMyOrgId($uid);
        $db = getDBO();

        $limit_start = 0;
        if ($start_limit) {
            $limit_start = $start_limit * $rows;
        }
        $query_add = "";
        if ($budgetYear) {
            $year_prev = $budgetYear - 1;
            $start_date = $year_prev . '-10-01';
            $end_date = $budgetYear . '-09-30';
            $query_add .= " AND (DATE(i.create_date) >= '$start_date' AND DATE(i.create_date) <= '$end_date') ";
        }
        if ($month) {
            $query_add .= " AND MONTH(i.create_date) = '$month' ";
        }

        if ($_GET['check']) {
            $query_add .= " AND i.start_status = '4' ";
        }

        $sql = "
			SELECT				    i.*,a.id AS uid,a.fullname AS fullname
			FROM					attend_" . $org_id . "_information AS i
            INNER JOIN              users AS a
			ON  					i.status='1'
			AND						i.local_id='" . Site::$local_id . "'
			AND						i.create_by='{$uid}'
            AND                     a.id = '{$uid}'
            {$query_add}
            -- GROUP BY				DATE(i.create_date)
			ORDER BY				DATE(i.create_date) DESC, i.id ASC
			LIMIT					{$limit_start} , {$rows}
			";

        $db->setQuery($sql);
        $rs = $db->loadAssocList();
        $len = count($rs);

        if ($_GET['debug']) {
            exit($db->getQuery());
        }

        $item = array();
        for ($i = 0; $i < $len; $i++) {
            $item[$i] = orgAttendItem($org_id, $rs[$i]);
        }

        echo json_encode($item);
        exit();
    }


    public function lineNotifyDaily()
    {
        $org_id = getParam(3);
        if (!$org_id) {
            return;
        }
        updateAttendDailyStatus($org_id);
        $create_date = date('Y-m-d', strtotime('yesterday'));
        $date_th = $create_date;
        shortThaiDate($date_th);
        $data = orgAttendDailyNum($org_id, $create_date);
        $data_outside = orgAttendDailyNum($org_id, $create_date, '3');
        $data['num_ontime_outside'] = $data_outside['num_ontime'];
        $data['num_late_outside'] = $data_outside['num_late'];

        $msg = 'App iSmartLogin' . PHP_EOL . 'สรุปการเข้าทำงาน วันที่ ' . $date_th . PHP_EOL;
        //------------------
        $num = $data['num_ontime'];
        $num_outside = $data['num_ontime_outside'];
        if ($num_outside) {
            $num_outside = '';
        } else {
            $num_outside = '';
        }
        if ($num) {
            $msg .= PHP_EOL . 'ทันเวลา ' . number_format($num) . ' คน ' . $num_outside;
        }
        //------------------
        $num = $data['num_late'];
        $num_outside = $data['num_late_outside'];
        if ($num_outside) {
            $num_outside = '';
        } else {
            $num_outside = '';
        }
        if ($num) {
            $msg .= PHP_EOL . 'สาย ' . number_format($num) . ' คน ' . $num_outside;
        }
        //------------------
        $num = $data['num_outside'];
        if ($num) {
            $msg .= PHP_EOL . 'ทำงานนอกสถานที่ ' . number_format($num) . ' งาน';
        }
        //------------------
        $num = $data['num_absence'];
        if ($num) {
            if ($org_id == "1") {
                $sql = "SELECT id FROM `users` WHERE `status` = 1 AND `org_id` = 1 AND priv = 'ismart1' AND userclass = 'member' AND id != 59";
                $db = getDBO();
                $db->setQuery($sql);
                $city = $db->loadAssocList();
                $len_city = count($city);
                if ($num == $len_city) {
                    $msg .= PHP_EOL . 'วันหยุด';
                }
            } else {
                $msg .= PHP_EOL . 'ไม่ลงชื่อเข้างาน ' . number_format($num) . ' คน';
            }
        }

        $db = getDBO();
        $db->setQuery(" SELECT * FROM org_information WHERE id={$org_id} ");
        $uploadKey = $db->loadAssocList();
        $uploadKey = @$uploadKey[0]['uploadKey'];

        $msg .= PHP_EOL . PHP_EOL . 'ดูรายละเอียดเพิ่มเติม : ' . base_url() . 'attend_result/daily/?org=' . $uploadKey . '&create_date=' . $create_date;


        if ($org_id == '2') {
            $access_token = "tQbjuGTfTk1bgEP8neAOZs64iFo1z47ywxgTMEsqjWm"; // token iSmart
        } else {
            $access_token = "y4r15jSETW794qYVijThKQbvtTt5qaNXJCoBk0yRkA2"; // token iSmart
        }
        $message_data = array(
            'message' => $msg, //ข้อความที่ต้องการส่ง สูงสุด 1000 ตัวอักษร
            'imageThumbnail' => '', // ขนาดสูงสุด 240×240px JPEG
            'imageFullsize' => '', // ขนาดสูงสุด 1024×1024px JPEG
        );
        // $result = $this->send_notify_line($access_token, $message_data);
        $result = array();
        if ($msg) {
            $token = Site::$cityToken;
            $this->sendTextToLineGroup($token, $msg);
            //telegram
            $botToken = TelegramConfig::$botToken;
            $chatId = TelegramConfig::$chatId;
            // $this->sendTelegramMessage($botToken, $chatId, $msg);
        }
        echo json_encode($result, JSON_UNESCAPED_UNICODE);
        exit();
    }

    public function lineNotifyDailyPublic()
    {
        $org_id = getParam(3);
        if (!$org_id) {
            return;
        }
        updateAttendDailyStatus($org_id);
        $create_date = date('Y-m-d', strtotime('yesterday'));
        $date_th = $create_date;
        shortThaiDate($date_th);
        $data = orgAttendDailyNum($org_id, $create_date);
        $data_outside = orgAttendDailyNum($org_id, $create_date, '3');
        // per($data_outside);
        // exit();
        $data['num_ontime_outside'] = $data_outside['num_ontime'];
        $data['num_late_outside'] = $data_outside['num_late'];

        $msg = 'App iSmartLogin' . PHP_EOL . 'สรุปการเข้าทำงาน วันที่ ' . $date_th . PHP_EOL;
        //------------------
        $num = $data['num_ontime'];
        $num_outside = $data['num_ontime_outside'];
        if ($num_outside) {
            $num_outside = '';
            //$num_outside = '(นอกสถานที่ ' . number_format($num_outside) . ' คน)';
        } else {
            $num_outside = '';
        }
        if ($num) {
            $msg .= PHP_EOL . 'ทันเวลา ' . number_format($num) . ' คน ' . $num_outside;
        }
        //------------------
        $num = $data['num_late'];
        $num_outside = $data['num_late_outside'];
        if ($num_outside) {
            $num_outside = '';
            //$num_outside = '(นอกสถานที่ ' . number_format($num_outside) . ' คน)';
        } else {
            $num_outside = '';
        }
        if ($num) {
            $msg .= PHP_EOL . 'สาย ' . number_format($num) . ' คน ' . $num_outside;
        }
        //------------------
        $num = $data['num_outside'];
        if ($num) {
            $msg .= PHP_EOL . 'ทำงานนอกสถานที่ ' . number_format($num) . ' งาน';
        }
        //------------------
        $num = $data['num_absence'];
        if ($num) {
            $msg .= PHP_EOL . 'ไม่ลงชื่อเข้างาน ' . number_format($num) . ' คน';
        }
        echo $msg;
        //------------------
        /* $num = $data['num_not_end'];
		if ($num) {
			$msg .= PHP_EOL . 'ไม่ลงชื่อเลิกงาน ' . number_format($num) . ' คน';
		} */

        $db = getDBO();
        $db->setQuery("SELECT uploadKey,token_key_line FROM org_information WHERE id={$org_id} ");
        $uploadKey = $db->loadAssocList();

        // exit($db->getQuery());
        $access_token = $uploadKey[0]['token_key_line'];
        $uploadKey = $uploadKey[0]['uploadKey'];

        if ($org_id == "2170" || $org_id == "2180") {
            $msg .= PHP_EOL . PHP_EOL . 'ดูรายละเอียดเพิ่มเติม : ' . base_url() . 'attend_result/daily_parent/?org=' . $uploadKey . '&create_date=' . $create_date;
        } else {
            $msg .= PHP_EOL . PHP_EOL . 'ดูรายละเอียดเพิ่มเติม : ' . base_url() . 'attend_result/daily/?org=' . $uploadKey . '&create_date=' . $create_date;
        }

        if ($org_id == "2170") {
            //เด่นล่าเพชรเกษม
            $access_token = "Ccd57f6394fad85a0d4f7961a710ca23b";
        } else if ($org_id == "2180") {
            //เด่นล่าพระราม 5
            $access_token = "C6eb61fd95f44d52cf0558a6c0f44915f";
        }

        //send notify to line oa group 
        $result = $this->sendTextToLineGroup($access_token, $msg);
        // $result = $this->send_notify_line($access_token, $message_data);

        if ($org_id == "2183") {
            $botToken = TelegramConfig::$botToken;
            $chatId = '-4676888499';
            $this->sendTelegramMessage($botToken, $chatId, $msg);
        }

        if ($org_id == "227") {
            $botToken = TelegramConfig::$botToken;
            $chatId = '-4682000244';
            $this->sendTelegramMessage($botToken, $chatId, $msg);
        }

        echo json_encode($result, JSON_UNESCAPED_UNICODE);
        exit();
    }

    function sendTextToLineGroup($token, $text)
    {
        $url = "https://line.cityvariety.com/api_v1/sendTextToGroup";
        $param = array(
            "token" => $token,
            "text" => $text,
        );

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, 0);
        curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($param));
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
        $result = curl_exec($ch);
        $error = curl_error($ch);
        curl_close($ch);

        if (@$error) {
            return $error;
        } else {
            return $result;
        }
    }


    public function lineNotifyLate()
    {
        $org_id = request('org_id');
        $date_pre = request('start_date');
        $create_date = request('end_date');


        if (!$create_date) {
            $create_date = date('Y-m-d', strtotime('yesterday'));
        } else {
            $date_1 = strtotime($create_date);
            $create_date = date('Y-m-d', $date_1);
        }
        if (!$date_pre) {
            $date_pre = date("Y-m-d", strtotime("-1 month"));
        }

        ///
        if (!$org_id) {
            $org_id = getParam(3);
            if (!$org_id) {
                return;
            }
        }

        // if ($org_id == '2') {
        //     $access_token = "tQbjuGTfTk1bgEP8neAOZs64iFo1z47ywxgTMEsqjWm"; // token iSmart
        // } else {
        //     $access_token = "y4r15jSETW794qYVijThKQbvtTt5qaNXJCoBk0yRkA2"; // token iSmart
        // }
        // Test
        $access_token = "8CwfpQRgQ9in43I6k54WVJAPXCghCKVYmurdvPCfws9"; // token iSmart
        //---
        $text = "";
        $text_m = "";
        $db = getDBO();
        $db->setQuery("
            SELECT      u.id AS id , u.fullname AS fullname , u.nickname AS nickname,u.create_date AS create_date,u.delete_date AS delete_date
            FROM        user_relationship AS a
            INNER JOIN  users AS u
            ON          u.org_id = '" . $org_id . "'
            AND			(
                (
                    u.status='1' AND
                    u.org_id = '{$org_id}' AND
                    u.stat = '1'
                AND DATE(u.create_date) <= '{$create_date}'
                )
            OR	
                ( 
                    u.status='0' AND
                    u.stat = '1' AND
                    u.org_id = '{$org_id}'
                    AND		u.delete_date <= DATE('" . $create_date . "')
                    AND		u.delete_date BETWEEN DATE('" . $date_pre . "') AND DATE('" . $create_date . "')
                )
            )
            AND         u.stat = '1'
            AND         a.uid = u.id
            GROUP BY u.id
            ORDER BY u.id ASC
        ");
        echo  $db->getQuery();
        $rs = $db->loadAssocList();
        $len = count($rs);
        //---

        if ($len) {
            for ($i = 0; $i < $len; $i++) {
                $no_work = "";
                $late = "";
                $logout = "";
                $leave = "";
                $no_work_num = 0;
                $late_num = 0;
                $logout_num = 0;
                $leave_num = 0;
                $txt_le = "";
                $txt_lem = "";
                $sql = "
                        SELECT     create_date
                        FROM       attend_" . $org_id . "_summary
                        WHERE      create_date BETWEEN '{$date_pre}' AND '{$create_date}'
                        AND        num_ontime > 0
                        GROUP BY   create_date
                        ";
                $db->setQuery($sql);
                $rs_date = $db->loadAssocList();
                if (count($rs_date)) {
                    for ($d = 0; $d < count($rs_date); $d++) {
                        //--
                        $date_now = $rs_date[$d]['create_date'];
                        $date_now = strtotime($date_now);
                        $user_create = $rs[$i]['create_date'];
                        $user_create =  strtotime($user_create);
                        $user_delete = $rs[$i]['delete_date'];
                        $user_delete = strtotime($user_delete);
                        //---
                        if ($date_now >= $user_create) {
                            $input_d = $rs_date[$d]['create_date'];
                            $date_d = strtotime($input_d);
                            $DayOfWeek = date("w", strtotime(date('Y-m-d', $date_d)));
                            if ($DayOfWeek != 0 && $DayOfWeek != 6) {
                                // Holiday check (Match edit.php behavior)
                                $date_text = date('Y-m-d', $date_d);
                                $branch_id = getBranchOrg($rs[$i]['id']);
                                $subBranch = checkSubBranch($rs[$i]['id']);
                                if ($branch_id != 1) {
                                    if (!$subBranch) {
                                        $holiday = checkThisHoliday($date_text, 1);
                                    } else {
                                        $holiday = checkThisHoliday($date_text);
                                    }
                                    if ($holiday == 1) {
                                        continue;
                                    }
                                }

                                // Check for approved leave (DB Check)
                                $check_date_leave = date('Y-m-d', $date_d);
                                $db_check = getDBO();
                                $sql_check = "SELECT cid FROM leave_{$org_id}_information 
                                            WHERE create_by='" . $rs[$i]['id'] . "' 
                                            AND '{$check_date_leave}' BETWEEN DATE(FirstDate) AND DATE(LastDate) 
                                            AND status_leave = '2' LIMIT 1";
                                $db_check->setQuery($sql_check);
                                $rs_check = $db_check->loadAssocList();
                                $has_leave_db = false;
                                if ($rs_check && count($rs_check) > 0) {
                                    if ($rs_check[0]['cid'] != '2') { // Match edit.php: Not Sick Leave
                                        $has_leave_db = true;
                                    }
                                }

                                $sql = "
                                SELECT     *
                                FROM       attend_" . $org_id . "_information
                                WHERE      create_by = '" . $rs[$i]['id'] . "'
                                AND        create_date LIKE '" . $rs_date[$d]['create_date'] . "%' 
                                AND        status = '1'
                                AND        cid != '3'
                                ";
                                $db->setQuery($sql);
                                $rs_sum = $db->loadAssocList();
                                $day_leave_recorded = false; // Fix: Flag to prevent duplicate dates
                                if (count($rs_sum) > 0) {
                                    for ($k = 0; $k < count($rs_sum); $k++) {
                                        // Check if attendance record itself indicates leave (start_status 2)
                                        $is_leave_status = ($rs_sum[$k]['start_status'] == '2');
                                        
                                        // Combined leave check: DB Record OR Attendance Status for exemption
                                        $is_exempt = $has_leave_db || $is_leave_status;

                                        // Restore: Show "Leave" in summary if scan is status 2 OR they have an approved DB record
                                        // (This aligns with edit.php for half-day leaves)
                                        if ($is_exempt && !$day_leave_recorded) {
                                            $leave .= date('d', $date_d) . ",";
                                            $leave_num = $leave_num + 1;
                                            $day_leave_recorded = true; 
                                        }

                                        if (($rs_sum[$k]['start_status'] == '1' || $rs_sum[$k]['start_status'] == '3') && !$is_exempt) {
                                            $late .= date('d', $date_d) . ",";
                                            $late_num = $late_num + 1;
                                        }
                                        if (($rs_sum[$k]['end_status'] == '1' || $rs_sum[$k]['end_time'] == '') && !$is_exempt) {
                                            // Fix: If end_time exists, do not show as penalty (Match edit.php)
                                            if ($rs_sum[$k]['end_time'] != '') {
                                                continue;
                                            }
                                            $logout .= date('d', $date_d) . ",";
                                            $logout_num = $logout_num + 1;
                                        }
                                    }
                                } else {
                                    // If NO scan, summarize based on DB leave
                                    if ($has_leave_db) {
                                        $leave .= date('d', $date_d) . ",";
                                        $leave_num = $leave_num + 1;
                                    } else {
                                        $no_work .= date('d', $date_d) . ",";
                                        $no_work_num = $no_work_num + 1;
                                    }
                                }
                            }
                        }
                    }
                }
                //---
                $name = explode(",", $rs[$i]['fullname']);
                $name = $rs[$i]['nickname'] != "" ? $rs[$i]['nickname'] : $name[0];
                $txt_l = "";
                $txt_g = "";
                $txt_w = "";
                $txt_lm = "";
                $txt_gm = "";
                $txt_wm = "";
                if ($leave_num > 0) {
                    $txt_le = "ลา : " . $leave . "<br>";
                    $txt_lem = "- ลา : " . $leave . PHP_EOL;
                }
                if ($late_num > 0) {
                    $txt_l = "สาย : " . $late . "<br>";
                    $txt_lm = "- สาย : " . $late . PHP_EOL;
                }
                if ($logout_num > 0) {
                    $txt_g = "ไม่ลงชื่อออกงาน/ออกก่อนเวลา : " . $logout . "<br>";
                    $txt_gm = "- ไม่ลงชื่อออกงาน/ออกก่อนเวลา : " . $logout . PHP_EOL;
                }
                if ($no_work_num > 0) {
                    $txt_w = "ไม่ลงชื่อเข้างาน : " . $no_work . "<br>";
                    $txt_wm = "- ไม่ลงชื่อเข้างาน : " . $no_work . PHP_EOL;
                }
                if ($late_num != 0 || $logout_num != 0 || $no_work_num != 0 || $leave_num > 0) {
                    $text .= "
                    " . $name . " => " . $txt_le . $txt_l . "" . $txt_g . "" . $txt_w .
                        "<br>----------<br>
                    ";
                    $text_m .= $name . PHP_EOL . $txt_lem . $txt_lm . "" . $txt_wm  . "" . $txt_gm .
                        "----------" . PHP_EOL . "";
                }
            }
        }
        //---
        $date_th_end = $create_date;
        shortThaiDate($date_th_end);
        $date_pre_th = $date_pre;
        shortThaiDate($date_pre_th);
        //---
        if ($org_id == '2') {
            $access_token = "tQbjuGTfTk1bgEP8neAOZs64iFo1z47ywxgTMEsqjWm"; // token iSmart
        } else {
            $access_token = "y4r15jSETW794qYVijThKQbvtTt5qaNXJCoBk0yRkA2"; // token iSmart
        }
        // Test
        // $access_token = "8CwfpQRgQ9in43I6k54WVJAPXCghCKVYmurdvPCfws9"; // token iSmart
        $msg = 'App iSmartLogin' . PHP_EOL . 'สรุปการเข้าทำงาน ตั้งแต่วันที่ ' . $date_pre_th . ' ถึง ' . $date_th_end . PHP_EOL . PHP_EOL;
        $msg .= $text_m;
        $message_data = array(
            'message' => $msg, //ข้อความที่ต้องการส่ง สูงสุด 1000 ตัวอักษร
            'imageThumbnail' => '', // ขนาดสูงสุด 240×240px JPEG
            'imageFullsize' => '', // ขนาดสูงสุด 1024×1024px JPEG
            /* 'stickerPackageId' => 1, // Package ID ของสติกเกอร์
		'stickerId' => 410, // ID ของสติกเกอร์ */
        );
        // $result = $this->send_notify_line($access_token, $message_data);
        if ($msg) {
            $token = Site::$cityToken;
            // $this->sendTextToLineGroup($token, $msg);
            //telegram
            $botToken = TelegramConfig::$botToken;
            $chatId = TelegramConfig::$chatId;
            // $this->sendTelegramMessage($botToken, $chatId, $msg);
        }
        ///----
        echo "App iSmartLogin สรุปการเข้าทำงาน ตั้งแต่วันที่ " . $date_pre_th . " ถึง " . $date_th_end . "<br><br>
        " . $text . "
        ";
        //---


        echo json_encode($rs, JSON_UNESCAPED_UNICODE);
        exit();
    }

    public function lineNotifyLateTest()
    {
        $org_id = request('org_id');
        $date_pre = request('start_date');
        $create_date = request('end_date');


        if (!$create_date) {
            $create_date = date('Y-m-d', strtotime('yesterday'));
        } else {
            $date_1 = strtotime($create_date);
            $create_date = date('Y-m-d', $date_1);
        }
        if (!$date_pre) {
            $date_pre = date("Y-m-d", strtotime("-1 month"));
        }

        if (!$org_id) {
            $org_id = getParam(3);
            if (!$org_id) {
                return;
            }
        }
        //---
        $text = "";
        $text_m = "";
        $db = getDBO();
        $db->setQuery("
            SELECT      u.id AS id , u.fullname AS fullname , u.nickname AS nickname,u.create_date AS create_date,u.delete_date AS delete_date
            FROM        user_relationship AS a
            INNER JOIN  users AS u
            ON          u.org_id = '" . $org_id . "'
            AND			(
                (
                    u.status='1' AND
                    u.org_id = '{$org_id}' AND
                    u.stat = '1'
                AND DATE(u.create_date) <= '{$create_date}'
                )
            OR	
                ( 
                    u.status='0' AND
                    u.stat = '1' AND
                    u.org_id = '{$org_id}'
                    AND		u.delete_date <= DATE('" . $create_date . "')
                    AND		u.delete_date BETWEEN DATE('" . $date_pre . "') AND DATE('" . $create_date . "')
                )
            )
            AND         u.stat = '1'
            AND         a.uid = u.id
            GROUP BY u.id
            ORDER BY u.id ASC
        ");
        echo  $db->getQuery();
        $rs = $db->loadAssocList();
        $len = count($rs);
        //---

        if ($len) {
            for ($i = 0; $i < $len; $i++) {
                $no_work = "";
                $late = "";
                $logout = "";
                $leave = "";
                $no_work_num = 0;
                $late_num = 0;
                $logout_num = 0;
                $leave_num = 0;
                $txt_le = "";
                $txt_lem = "";
                $sql = "
                        SELECT     create_date
                        FROM       attend_" . $org_id . "_summary
                        WHERE      create_date BETWEEN '{$date_pre}' AND '{$create_date}'
                        AND        num_ontime > 0
                        GROUP BY   create_date
                        ";
                $db->setQuery($sql);
                $rs_date = $db->loadAssocList();
                if (count($rs_date)) {
                    for ($d = 0; $d < count($rs_date); $d++) {
                        //--
                        $date_now = $rs_date[$d]['create_date'];
                        $date_now = strtotime($date_now);
                        $user_create = $rs[$i]['create_date'];
                        $user_create =  strtotime($user_create);
                        $user_delete = $rs[$i]['delete_date'];
                        $user_delete = strtotime($user_delete);
                        //---
                        if ($date_now >= $user_create) {
                            $input_d = $rs_date[$d]['create_date'];
                            $date_d = strtotime($input_d);
                            $DayOfWeek = date("w", strtotime(date('Y-m-d', $date_d)));
                            if ($DayOfWeek != 0 && $DayOfWeek != 6) {
                                // Holiday check (Match edit.php behavior)
                                $date_text = date('Y-m-d', $date_d);
                                $branch_id = getBranchOrg($rs[$i]['id']);
                                $subBranch = checkSubBranch($rs[$i]['id']);
                                if ($branch_id != 1) {
                                    if (!$subBranch) {
                                        $holiday = checkThisHoliday($date_text, 1);
                                    } else {
                                        $holiday = checkThisHoliday($date_text);
                                    }
                                    if ($holiday == 1) {
                                        continue;
                                    }
                                }

                                // Check for approved leave (DB Check)
                                $check_date_leave = date('Y-m-d', $date_d);
                                $db_check = getDBO();
                                $sql_check = "SELECT cid FROM leave_{$org_id}_information 
                                            WHERE create_by='" . $rs[$i]['id'] . "' 
                                            AND '{$check_date_leave}' BETWEEN DATE(FirstDate) AND DATE(LastDate) 
                                            AND status_leave = '2' LIMIT 1";
                                $db_check->setQuery($sql_check);
                                $rs_check = $db_check->loadAssocList();
                                $has_leave_db = false;
                                if ($rs_check && count($rs_check) > 0) {
                                    if ($rs_check[0]['cid'] != '2') { // Match edit.php: Not Sick Leave
                                        $has_leave_db = true;
                                    }
                                }

                                $sql = "
                                SELECT     *
                                FROM       attend_" . $org_id . "_information
                                WHERE      create_by = '" . $rs[$i]['id'] . "'
                                AND        create_date LIKE '" . $rs_date[$d]['create_date'] . "%' 
                                AND        status = '1'
                                AND        cid != '3'
                                ";
                                $db->setQuery($sql);
                                $rs_sum = $db->loadAssocList();
                                $day_leave_recorded = false; // Fix: Flag to prevent duplicate dates
                                if (count($rs_sum) > 0) {
                                    for ($k = 0; $k < count($rs_sum); $k++) {
                                        // Check if attendance record itself indicates leave (start_status 2)
                                        $is_leave_status = ($rs_sum[$k]['start_status'] == '2');
                                        
                                        // Combined leave check: DB Record OR Attendance Status for exemption
                                        $is_exempt = $has_leave_db || $is_leave_status;

                                        // Restore: Show "Leave" in summary if scan is status 2 OR they have an approved DB record
                                        // (This aligns with edit.php for half-day leaves)
                                        if ($is_exempt && !$day_leave_recorded) {
                                            $leave .= date('d', $date_d) . ",";
                                            $leave_num = $leave_num + 1;
                                            $day_leave_recorded = true; 
                                        }

                                        if (($rs_sum[$k]['start_status'] == '1' || $rs_sum[$k]['start_status'] == '3') && !$is_exempt) {
                                            $late .= date('d', $date_d) . ",";
                                            $late_num = $late_num + 1;
                                        }
                                        if (($rs_sum[$k]['end_status'] == '1' || $rs_sum[$k]['end_time'] == '') && !$is_exempt) {
                                            // Fix: If end_time exists, do not show as penalty (report3d technique)
                                            if ($rs_sum[$k]['end_time'] != '') {
                                                continue;
                                            }
                                            $logout .= date('d', $date_d) . ",";
                                            $logout_num = $logout_num + 1;
                                        }
                                    }
                                } else {
                                    // If NO scan, summarize based on DB leave
                                    if ($has_leave_db) {
                                        $leave .= date('d', $date_d) . ",";
                                        $leave_num = $leave_num + 1;
                                    } else {
                                        $no_work .= date('d', $date_d) . ",";
                                        $no_work_num = $no_work_num + 1;
                                    }
                                }
                            }
                        }
                    }
                }
                //---
                $name = explode(",", $rs[$i]['fullname']);
                $name = $rs[$i]['nickname'] != "" ? $rs[$i]['nickname'] : $name[0];
                $txt_l = "";
                $txt_g = "";
                $txt_w = "";
                $txt_lm = "";
                $txt_gm = "";
                $txt_wm = "";
                if ($leave_num > 0) {
                    $txt_le = "ลา : " . $leave . "<br>";
                    $txt_lem = "- ลา : " . $leave . PHP_EOL;
                }
                if ($late_num > 0) {
                    $txt_l = "สาย : " . $late . "<br>";
                    $txt_lm = "- สาย : " . $late . PHP_EOL;
                }
                if ($logout_num > 0) {
                    $txt_g = "ไม่ลงชื่อออกงาน/ออกก่อนเวลา : " . $logout . "<br>";
                    $txt_gm = "- ไม่ลงชื่อออกงาน/ออกก่อนเวลา : " . $logout . PHP_EOL;
                }
                if ($no_work_num > 0) {
                    $txt_w = "ไม่ลงชื่อเข้างาน : " . $no_work . "<br>";
                    $txt_wm = "- ไม่ลงชื่อเข้างาน : " . $no_work . PHP_EOL;
                }
                if ($late_num != 0 || $logout_num != 0 || $no_work_num != 0 || $leave_num > 0) {
                    $text .= "
                    " . $name . " => " . $txt_le . $txt_l . "" . $txt_g . "" . $txt_w .
                        "<br>----------<br>
                    ";
                    $text_m .= $name . PHP_EOL . $txt_lem . $txt_lm . "" . $txt_wm  . "" . $txt_gm .
                        "----------" . PHP_EOL . "";
                }
            }
        }
        //---
        $date_th_end = $create_date;
        shortThaiDate($date_th_end);
        $date_pre_th = $date_pre;
        shortThaiDate($date_pre_th);

        $msg = 'App iSmartLogin' . PHP_EOL . 'สรุปการเข้าทำงาน ตั้งแต่วันที่ ' . $date_pre_th . ' ถึง ' . $date_th_end . PHP_EOL . PHP_EOL;
        $msg .= $text_m;
        ///----
        echo "App iSmartLogin สรุปการเข้าทำงาน ตั้งแต่วันที่ " . $date_pre_th . " ถึง " . $date_th_end . "<br><br>
        " . $text . "
        ";
        ///----
        // echo json_encode($rs, JSON_UNESCAPED_UNICODE);
        exit();
    }

    public function lineNotifyLateDenla()
    {
        $org_id = request('org_id');
        $date_pre = request('start_date');
        $create_date = request('end_date');


        if (!$create_date) {
            $create_date = date('Y-m-d', strtotime('yesterday'));
        } else {
            $date_1 = strtotime($create_date);
            $create_date = date('Y-m-d', $date_1);
        }
        if (!$date_pre) {
            $date_pre = date("Y-m-d", strtotime("-1 month"));
        }


        if ($_GET['debug']) {
            $create_date = "2025-05-19";
            $date_pre = "2025-04-20";
            // $create_date = "2025-04-19";
            // $date_pre = "2025-03-20";
        }

        // pre($create_date);
        ///
        if (!$org_id) {
            $org_id = getParam(3);
            $parent_id = getParam(4);
            if (!$org_id) {
                return;
            }
        }

        // if ($org_id == '2') {
        //     $access_token = "tQbjuGTfTk1bgEP8neAOZs64iFo1z47ywxgTMEsqjWm"; // token iSmart
        // } else {
        //     $access_token = "y4r15jSETW794qYVijThKQbvtTt5qaNXJCoBk0yRkA2"; // token iSmart
        // }
        // Test
        $access_token = ""; // token iSmart //8CwfpQRgQ9in43I6k54WVJAPXCghCKVYmurdvPCfws9

        //---
        $text = "";
        $text_m = "";
        $db = getDBO();
        $db->setQuery("
            SELECT      u.id AS id , u.fullname AS fullname , u.nickname AS nickname,u.create_date AS create_date,u.delete_date AS delete_date
            FROM        user_relationship AS a
            INNER JOIN  users AS u
            ON          u.org_id = '" . $org_id . "'
            AND			(
                (
                    u.status='1' AND
                    u.org_id = '{$org_id}' AND
                    u.stat = '1'
                AND DATE(u.create_date) <= '{$create_date}'
                )
            OR	
                ( 
                    u.status='0' AND
                    u.stat = '1' AND
                    u.org_id = '{$org_id}'
                    AND		u.delete_date <= DATE('" . $create_date . "')
                    AND		u.delete_date BETWEEN DATE('" . $date_pre . "') AND DATE('" . $create_date . "')
                )
            )
            AND         u.stat = '1'
            AND         a.uid = u.id
            GROUP BY u.id
            ORDER BY u.id ASC
        ");
        echo  $db->getQuery();
        $rs = $db->loadAssocList();
        $len = count($rs);
        //---

        if ($len) {
            $len = 10;
            for ($i = 0; $i < $len; $i++) {
                $no_work = "";
                $late = "";
                $logout = "";
                $leave = "";
                $no_work_num = 0;
                $late_num = 0;
                $logout_num = 0;
                $leave_num = 0;
                $txt_le = "";
                $txt_lem = "";
                $sql = "
                        SELECT     create_date
                        FROM       attend_" . $org_id . "_summary
                        WHERE      DATE(create_date) BETWEEN '{$date_pre}' AND '{$create_date}'
                        AND        num_ontime > 0
                        GROUP BY   create_date
                        ";
                $db->setQuery($sql);
                $rs_date = $db->loadAssocList();
                if (count($rs_date)) {
                    for ($d = 0; $d < count($rs_date); $d++) {
                        //--
                        $date_now = $rs_date[$d]['create_date'];
                        $date_now = strtotime($date_now);
                        $user_create = $rs[$i]['create_date'];
                        $user_create =  strtotime($user_create);
                        $user_delete = $rs[$i]['delete_date'];
                        $user_delete = strtotime($user_delete);
                        //---
                        if ($date_now >= $user_create) {
                            $input_d = $rs_date[$d]['create_date'];
                            $date_d = strtotime($input_d);
                            $DayOfWeek = date("w", strtotime(date('Y-m-d', $date_d)));
                            if ($DayOfWeek != 0 && $DayOfWeek != 6) {
                                // Holiday check (Match edit.php behavior)
                                $date_text = date('Y-m-d', $date_d);
                                $branch_id = getBranchOrg($rs[$i]['id']);
                                $subBranch = checkSubBranch($rs[$i]['id']);
                                if ($branch_id != 1) {
                                    if (!$subBranch) {
                                        $holiday = checkThisHoliday($date_text, 1);
                                    } else {
                                        $holiday = checkThisHoliday($date_text);
                                    }
                                    if ($holiday == 1) {
                                        continue;
                                    }
                                }

                                // Check for approved leave (DB Check)
                                $check_date_leave = date('Y-m-d', $date_d);
                                $db_check = getDBO();
                                $sql_check = "SELECT cid FROM leave_{$org_id}_information 
                                            WHERE create_by='" . $rs[$i]['id'] . "' 
                                            AND '{$check_date_leave}' BETWEEN DATE(FirstDate) AND DATE(LastDate) 
                                            AND status_leave = '2' LIMIT 1";
                                $db_check->setQuery($sql_check);
                                $rs_check = $db_check->loadAssocList();
                                $has_leave_db = false;
                                if ($rs_check && count($rs_check) > 0) {
                                    if ($rs_check[0]['cid'] != '2') { // Match edit.php: Not Sick Leave
                                        $has_leave_db = true;
                                    }
                                }

                                $sql = "
                                SELECT     *
                                FROM       attend_" . $org_id . "_information
                                WHERE      create_by = '" . $rs[$i]['id'] . "'
                                AND        create_date LIKE '" . $rs_date[$d]['create_date'] . "%' 
                                AND        status = '1'
                                AND        cid != '3'
                                AND        org_id = '" . $parent_id . "'";
                                $db->setQuery($sql);
                                $rs_sum = $db->loadAssocList();
                                $day_leave_recorded = false; // Fix: Flag to prevent duplicate dates
                                if (count($rs_sum) > 0) {
                                    for ($k = 0; $k < count($rs_sum); $k++) {
                                        // Check if attendance record itself indicates leave (start_status 2)
                                        $is_leave_status = ($rs_sum[$k]['start_status'] == '2');
                                        
                                        // Combined leave check: DB Record OR Attendance Status for exemption
                                        $is_exempt = $has_leave_db || $is_leave_status;

                                        // Restore: Show "Leave" in summary if scan is status 2 OR they have an approved DB record
                                        // (This aligns with edit.php for half-day leaves)
                                        if ($is_exempt && !$day_leave_recorded) {
                                            $leave .= date('d', $date_d) . ",";
                                            $leave_num = $leave_num + 1;
                                            $day_leave_recorded = true; 
                                        }

                                        if (($rs_sum[$k]['start_status'] == '1' || $rs_sum[$k]['start_status'] == '3') && !$is_exempt) {
                                            $late .= date('d', $date_d) . ",";
                                            $late_num = $late_num + 1;
                                        }
                                        if (($rs_sum[$k]['end_status'] == '1' || $rs_sum[$k]['end_time'] == '') && !$is_exempt) {
                                            // Fix: If end_time exists, do not show as penalty (report3d technique)
                                            if ($rs_sum[$k]['end_time'] != '') {
                                                continue;
                                            }
                                            $logout .= date('d', $date_d) . ",";
                                            $logout_num = $logout_num + 1;
                                        }
                                    }
                                } else {
                                    // If NO scan, summarize based on DB leave
                                    if ($has_leave_db) {
                                        $leave .= date('d', $date_d) . ",";
                                        $leave_num = $leave_num + 1;
                                    } else {
                                        $no_work .= date('d', $date_d) . ",";
                                        $no_work_num = $no_work_num + 1;
                                    }
                                }
                            }
                        }
                    }
                }
                //---
                $sql = "SELECT * FROM `user_relationship` WHERE `uid` = '{$rs[$i]['id']}' AND `org_id` = '{$org_id}' AND `org_sub_id` = '{$parent_id}' AND type = 'member'";
                $db->setQuery($sql);
                $rs_sub = $db->loadAssocList();
                if ($rs_sub) {
                    $name = explode(",", $rs[$i]['fullname']);
                    $name = $rs[$i]['nickname'] != "" ? $rs[$i]['nickname'] : $name[0];
                    $txt_l = "";
                    $txt_le = "";
                    $txt_g = "";
                    $txt_w = "";
                    $txt_lm = "";
                    $txt_lem = "";
                    $txt_gm = "";
                    $txt_wm = "";
                    if ($leave_num > 0) {
                        $txt_le = "- ลา (" . $leave_num . ") : <br>" . $leave;
                        $txt_lem = "- ลา (" . $leave_num . ") : " . $leave . PHP_EOL;
                    }
                    if ($late_num > 0) {
                        $txt_l = "- สาย/ลืมลงชื่อเข้างาน (" . $late_num . ") : <br>" . $late;
                        $txt_lm = "- สาย (" . $late_num . ") : " . $late . PHP_EOL;
                    }
                    if ($logout_num > 0) {
                        $txt_g = "- ไม่ลงชื่อออกงาน/ออกก่อนเวลา (" . $logout_num . ") : "  . $logout . "<br>";
                        $txt_gm = "- ไม่ลงชื่อออกงาน/ออกก่อนเวลา (" . $logout_num . ") : " . $logout . PHP_EOL;
                    }
                    if ($no_work_num > 0) {
                        $txt_w = "- ไม่ลงชื่อเข้างาน (" . $no_work_num . ") : " . $no_work . "<br>";
                        $txt_wm = "- ไม่ลงชื่อเข้างาน (" . $no_work_num . ") : " . $no_work . PHP_EOL;
                    }
                    if ($late_num != 0 || $logout_num != 0 || $no_work_num != 0 || $leave_num > 0) {
                        $text .= "
                        " . $name . "<br>" . $txt_le . "" . $txt_l . "" . $txt_g . "" . $txt_w .
                            "<br>----------<br>
                        ";
                        $text_m .= $name . PHP_EOL . $txt_lem . $txt_lm . "" . $txt_wm  . "" . $txt_gm .
                            "----------" . PHP_EOL . "";
                    }
                }
            }
        }
        //---
        $date_th_end = $create_date;
        shortThaiDate($date_th_end);
        $date_pre_th = $date_pre;
        shortThaiDate($date_pre_th);
        //---
        //KYZjHL1VFStCVWcnljOqwtoY8R5tcw7Z6eyylxNVIZf test
        if ($parent_id == '2170') {
            $access_token = "Ccd57f6394fad85a0d4f7961a710ca23b"; // token iSmart เด่นหล้าเพชรเกษม //G2ctJIXoGdlU04aQPpP1vn9OKwdbgwLQ4sWn4aEv9Pi
        } else {
            $access_token = "C6eb61fd95f44d52cf0558a6c0f44915f"; // token iSmart เด่นหล้าพระราม5 //WmjAN2KduYuni4Z3BGkNaFYshyw0kka2lBvR5z2pzQ1
        }
        $msg = 'App iSmartLogin เด่นหล้า' . PHP_EOL . 'สรุปการเข้าทำงาน ตั้งแต่วันที่ ' . $date_pre_th . ' ถึง ' . $date_th_end . PHP_EOL . PHP_EOL;
        // $msg .= $text_m;
        $msg .= $text_m . PHP_EOL . PHP_EOL . '- ดูรายละเอียดเพิ่มเติม : ' . "https://ismartlogin.cityvariety.com/summary/lineNotifyLateDenlaDetail/" . $org_id . "/" . $parent_id;

        $this->sendTextToLineGroup($access_token, $msg);
        // $result = $this->send_notify_line($access_token, $message_data);
        ///----
        // echo "App iSmartLogin สรุปการเข้าทำงาน ตั้งแต่วันที่ " . $date_pre_th . " ถึง " . $date_th_end . "<br><br>
        // " . $text . "
        // ";
        //---
        // echo json_encode($rs, JSON_UNESCAPED_UNICODE);
        exit();
    }


    public function lineNotifyLateDenlaDetail()
    {
        $org_id = request('org_id');
        $date_pre = request('start_date');
        $create_date = request('end_date');


        if (!$create_date) {
            $create_date = date('Y-m-d', strtotime('yesterday'));
        } else {
            $date_1 = strtotime($create_date);
            $create_date = date('Y-m-d', $date_1);
        }
        if (!$date_pre) {
            $date_pre = date("Y-m-d", strtotime("-1 month"));
        }


        if ($_GET['debug']) {
            $create_date = "2024-05-19";
            $date_pre = "2024-04-20";
        }

        // pre($create_date);
        ///
        if (!$org_id) {
            $org_id = getParam(3);
            $parent_id = getParam(4);
            if (!$org_id) {
                return;
            }
        }

        // if ($org_id == '2') {
        //     $access_token = "tQbjuGTfTk1bgEP8neAOZs64iFo1z47ywxgTMEsqjWm"; // token iSmart
        // } else {
        //     $access_token = "y4r15jSETW794qYVijThKQbvtTt5qaNXJCoBk0yRkA2"; // token iSmart
        // }
        // Test
        $access_token = ""; // token iSmart //8CwfpQRgQ9in43I6k54WVJAPXCghCKVYmurdvPCfws9

        //---
        $text = "";
        $text_m = "";
        $db = getDBO();
        $db->setQuery("
            SELECT      u.id AS id , u.fullname AS fullname , u.nickname AS nickname,u.create_date AS create_date,u.delete_date AS delete_date
            FROM        user_relationship AS a
            INNER JOIN  users AS u
            ON          u.org_id = '" . $org_id . "'
            AND			(
                (
                    u.status='1' AND
                    u.org_id = '{$org_id}' AND
                    u.stat = '1'
                AND DATE(u.create_date) <= '{$create_date}'
                )
            OR	
                ( 
                    u.status='0' AND
                    u.stat = '1' AND
                    u.org_id = '{$org_id}'
                    AND		u.delete_date <= DATE('" . $create_date . "')
                    AND		u.delete_date BETWEEN DATE('" . $date_pre . "') AND DATE('" . $create_date . "')
                )
            )
            AND         u.stat = '1'
            AND         a.uid = u.id
            GROUP BY u.id
            ORDER BY u.id ASC
        ");


        // echo  $db->getQuery();
        $rs = $db->loadAssocList();
        if ($_GET['debug']) {
            // pre($rs);
            // exit();
        }
        $len = count($rs);
        //---

        if ($len) {
            for ($i = 0; $i < $len; $i++) {
                $no_work = "";
                $late = "";
                $logout = "";
                $no_work_num = 0;
                $late_num = 0;
                $logout_num = 0;
                $sql = "
                        SELECT     create_date
                        FROM       attend_" . $org_id . "_summary
                        WHERE      DATE(create_date) BETWEEN '{$date_pre}' AND '{$create_date}'
                        GROUP BY    DATE(create_date)
                        ";
                $db->setQuery($sql);
                // if($_GET['debug']){
                //     echo $db->getQuery();
                //     exit();
                // }
                $rs_date = $db->loadAssocList();
                if (count($rs_date)) {
                    for ($d = 0; $d < count($rs_date); $d++) {
                        //--
                        $date_now = $rs_date[$d]['create_date'];
                        $date_now = strtotime($date_now);
                        $user_create = $rs[$i]['create_date'];
                        $user_create =  strtotime($user_create);
                        $user_delete = $rs[$i]['delete_date'];
                        $user_delete = strtotime($user_delete);
                        //---
                        if ($date_now >= $user_create) {
                            $input_d = $rs_date[$d]['create_date'];
                            $date_d = strtotime($input_d);
                            $DayOfWeek = date("w", strtotime(date('Y-m-d', $date_d)));
                            if ($DayOfWeek != 0 && $DayOfWeek != 6) {
                                // Holiday check (Match edit.php behavior)
                                $date_text = date('Y-m-d', $date_d);
                                $branch_id = getBranchOrg($rs[$i]['id']);
                                $subBranch = checkSubBranch($rs[$i]['id']);
                                if ($branch_id != 1) {
                                    if (!$subBranch) {
                                        $holiday = checkThisHoliday($date_text, 1);
                                    } else {
                                        $holiday = checkThisHoliday($date_text);
                                    }
                                    if ($holiday == 1) {
                                        continue;
                                    }
                                }

                                $sql = "
                                SELECT     *
                                FROM       attend_" . $org_id . "_information
                                WHERE      create_by = '" . $rs[$i]['id'] . "'
                                AND        create_date LIKE '" . $rs_date[$d]['create_date'] . "%' 
                                AND        org_id = '" . $parent_id . "'";
                                $db->setQuery($sql);
                                $rs_sum = $db->loadAssocList();
                                if ($_GET['debug']) {
                                    if ($rs[$i]['id'] == "2284") {
                                        pre($db->getQuery());
                                    }
                                }
                                // echo $db->getQuery();
                                if (count($rs_sum) > 0) {
                                    for ($k = 0; $k < count($rs_sum); $k++) {
                                        if ($rs_sum[$k]['start_status'] == '1' || $rs_sum[$k]['start_status'] == '3') {
                                            $date_d = date('Y-m-d', $date_d);
                                            shortThaiDate($date_d);
                                            $late .= $date_d . " เหตุผล : " . ($rs_sum[$k]['start_note'] ? $rs_sum[$k]['start_note'] : 'ลืมลงชื่อเข้างาน') . "<br>"; //date('d', $date_d)
                                            $late_num = $late_num + 1;
                                        }
                                        if ($rs_sum[$k]['end_status'] == '1' || $rs_sum[$k]['end_time'] == '') {
                                            $logout .= date('d', $date_d) . ",";
                                            $logout_num = $logout_num + 1;
                                        }
                                    }
                                } else {
                                    $no_work .= date('d', $date_d) . ",";
                                    $no_work_num = $no_work_num + 1;
                                }
                            }
                        }
                    }
                }
                //---
                $sql = "SELECT * FROM `user_relationship` WHERE `uid` = '{$rs[$i]['id']}' AND `org_id` = '{$org_id}' AND `org_sub_id` = '{$parent_id}' AND type = 'member'";
                $db->setQuery($sql);
                $rs_sub = $db->loadAssocList();
                if ($rs_sub) {
                    $name = explode(",", $rs[$i]['fullname']);
                    $name = $rs[$i]['nickname'] != "" ? $rs[$i]['nickname'] : $name[0];
                    $txt_l = "";
                    $txt_g = "";
                    $txt_w = "";
                    $txt_lm = "";
                    $txt_gm = "";
                    $txt_wm = "";
                    if ($late_num > 0) {
                        $txt_l = "- สาย/ลืมลงชื่อเข้างาน (" . $late_num . ") : <br>" . $late;
                        $txt_lm = "- สาย (" . $late_num . ") : " . $late . PHP_EOL;
                    }
                    if ($logout_num > 0) {
                        $txt_g = "- ไม่ลงชื่อออกงาน/ออกก่อนเวลา (" . $logout_num . ") : "  . $logout . "<br>";
                        $txt_gm = "- ไม่ลงชื่อออกงาน/ออกก่อนเวลา (" . $logout_num . ") : " . $logout . PHP_EOL;
                    }
                    if ($no_work_num > 0) {
                        $txt_w = "- ไม่ลงชื่อเข้างาน (" . $no_work_num . ") : " . $no_work . "<br>";
                        $txt_wm = "- ไม่ลงชื่อเข้างาน (" . $no_work_num . ") : " . $no_work . PHP_EOL;
                    }
                    if ($late_num != 0 || $logout_num != 0 || $no_work_num != 0) {
                        $text .= "
                        " . $name . "<br>" . $txt_l . "" . $txt_g . "" . $txt_w .
                            "<br>----------<br>
                        ";
                        $text_m .= $name . PHP_EOL . $txt_lm . "" . $txt_wm  . "" . $txt_gm .
                            "----------" . PHP_EOL . "";
                    }
                }
            }
        }
        //---
        $date_th_end = $create_date;
        shortThaiDate($date_th_end);
        $date_pre_th = $date_pre;
        shortThaiDate($date_pre_th);
        //---
        //KYZjHL1VFStCVWcnljOqwtoY8R5tcw7Z6eyylxNVIZf test
        if ($parent_id == '2170') {
            $access_token = "G2ctJIXoGdlU04aQPpP1vn9OKwdbgwLQ4sWn4aEv9Pi"; // token iSmart เด่นหล้าเพชรเกษม //G2ctJIXoGdlU04aQPpP1vn9OKwdbgwLQ4sWn4aEv9Pi
        } else {
            $access_token = "WmjAN2KduYuni4Z3BGkNaFYshyw0kka2lBvR5z2pzQ1"; // token iSmart เด่นหล้าพระราม5 //WmjAN2KduYuni4Z3BGkNaFYshyw0kka2lBvR5z2pzQ1
        }
        // Test
        // $access_token = "8CwfpQRgQ9in43I6k54WVJAPXCghCKVYmurdvPCfws9"; // token iSmart
        $msg = 'App iSmartLogin' . PHP_EOL . 'สรุปการเข้าทำงาน ตั้งแต่วันที่ ' . $date_pre_th . ' ถึง ' . $date_th_end . PHP_EOL . PHP_EOL;
        $msg .= $text_m . PHP_EOL . PHP_EOL . '- ดูรายละเอียดเพิ่มเติม : ' . "https://ismartlogin.cityvariety.com/summary/lineNotifyLateDenlaDetail/" . $org_id . "/" . $parent_id;
        $message_data = array(
            'message' => $msg, //ข้อความที่ต้องการส่ง สูงสุด 1000 ตัวอักษร
            'imageThumbnail' => '', // ขนาดสูงสุด 240×240px JPEG
            'imageFullsize' => '', // ขนาดสูงสุด 1024×1024px JPEG
            /* 'stickerPackageId' => 1, // Package ID ของสติกเกอร์
		'stickerId' => 410, // ID ของสติกเกอร์ */
        );
        // $result = $this->send_notify_line($access_token, $message_data);
        ///----
        echo "App iSmartLogin เด่นหล้า สรุปการเข้าทำงาน ตั้งแต่วันที่ " . $date_pre_th . " ถึง " . $date_th_end . "<br><br>
        " . $text . "
        ";
        //---


        // echo json_encode($rs, JSON_UNESCAPED_UNICODE);
        exit();
    }


    public function lineNotifyLateJson()
    {
        $org_id = request('org_id');
        $date_pre = request('start_date');
        $create_date = request('end_date');

        if (!$create_date) {
            $create_date = date('Y-m-d', strtotime('yesterday'));
        } else {
            $date_1 = strtotime($create_date);
            $create_date = date('Y-m-d', $date_1);
        }
        if (!$date_pre) {
            $date_pre = date("Y-m-d", strtotime("-1 month"));
        }

        ///
        if (!$org_id) {
            $org_id = getParam(3);
            if (!$org_id) {
                return;
            }
        }

        // if ($org_id == '2') {
        //     $access_token = "tQbjuGTfTk1bgEP8neAOZs64iFo1z47ywxgTMEsqjWm"; // token iSmart
        // } else {
        //     $access_token = "y4r15jSETW794qYVijThKQbvtTt5qaNXJCoBk0yRkA2"; // token iSmart
        // }
        // Test
        $access_token = "8CwfpQRgQ9in43I6k54WVJAPXCghCKVYmurdvPCfws9"; // token iSmart
        //---
        $text = "";
        $text_m = "";
        $db = getDBO();
        $db->setQuery("
            SELECT      u.id AS id , u.fullname AS fullname , u.nickname AS nickname,u.create_date AS create_date,u.delete_date AS delete_date
            FROM        user_relationship AS a
            INNER JOIN  users AS u
            ON          u.org_id = '" . $org_id . "'
            AND			(
                (
                    u.status='1' AND
                    u.org_id = '{$org_id}' AND
                    u.stat = '1'
                AND DATE(u.create_date) <= '{$create_date}'
                )
            OR	
                ( 
                    u.status='0' AND
                    u.stat = '1' AND
                    u.org_id = '{$org_id}'
                    AND		u.delete_date <= DATE('" . $create_date . "')
                    AND		u.delete_date BETWEEN DATE('" . $date_pre . "') AND DATE('" . $create_date . "')
                )
            )
            AND         u.stat = '1'
            AND         a.uid = u.id
            GROUP BY u.id
            ORDER BY u.id ASC
        ");
        echo  $db->getQuery();
        $rs = $db->loadAssocList();
        $len = count($rs);
        //---

        if ($len) {
            for ($i = 0; $i < $len; $i++) {
                $no_work = "";
                $late = "";
                $logout = "";
                $leave = "";
                $no_work_num = 0;
                $late_num = 0;
                $logout_num = 0;
                $leave_num = 0;
                $txt_le = "";
                $txt_lem = "";
                $sql = "
                        SELECT     create_date
                        FROM       attend_" . $org_id . "_summary
                        WHERE      DATE(create_date) BETWEEN '{$date_pre}' AND '{$create_date}'
                        AND        num_ontime > 0
                        GROUP BY   create_date
                        ";
                $db->setQuery($sql);
                $rs_date = $db->loadAssocList();
                if (count($rs_date)) {
                    for ($d = 0; $d < count($rs_date); $d++) {
                        //--
                        $date_now = $rs_date[$d]['create_date'];
                        $date_now = strtotime($date_now);
                        $user_create = $rs[$i]['create_date'];
                        $user_create =  strtotime($user_create);
                        $user_delete = $rs[$i]['delete_date'];
                        $user_delete = strtotime($user_delete);
                        //---
                        if ($date_now >= $user_create) {
                            $input_d = $rs_date[$d]['create_date'];
                            $date_d = strtotime($input_d);
                            $DayOfWeek = date("w", strtotime(date('Y-m-d', $date_d)));
                            if ($DayOfWeek != 0 && $DayOfWeek != 6) {
                                // Holiday check (Match edit.php behavior)
                                $date_text = date('Y-m-d', $date_d);
                                $branch_id = getBranchOrg($rs[$i]['id']);
                                $subBranch = checkSubBranch($rs[$i]['id']);
                                if ($branch_id != 1) {
                                    if (!$subBranch) {
                                        $holiday = checkThisHoliday($date_text, 1);
                                    } else {
                                        $holiday = checkThisHoliday($date_text);
                                    }
                                    if ($holiday == 1) {
                                        continue;
                                    }
                                }

                                // Check for approved leave (DB Check)
                                $check_date_leave = date('Y-m-d', $date_d);
                                $db_check = getDBO();
                                $sql_check = "SELECT cid FROM leave_{$org_id}_information 
                                            WHERE create_by='" . $rs[$i]['id'] . "' 
                                            AND '{$check_date_leave}' BETWEEN DATE(FirstDate) AND DATE(LastDate) 
                                            AND status_leave = '2' LIMIT 1";
                                $db_check->setQuery($sql_check);
                                $rs_check = $db_check->loadAssocList();
                                $has_leave_db = false;
                                if ($rs_check && count($rs_check) > 0) {
                                    if ($rs_check[0]['cid'] != '2') { // Match edit.php: Not Sick Leave
                                        $has_leave_db = true;
                                    }
                                }

                                $sql = "
                                SELECT     *
                                FROM       attend_" . $org_id . "_information
                                WHERE      create_by = '" . $rs[$i]['id'] . "'
                                AND        create_date LIKE '" . $rs_date[$d]['create_date'] . "%' 
                                AND        status = '1'
                                AND        cid != '3'
                                ";
                                $db->setQuery($sql);
                                $rs_sum = $db->loadAssocList();
                                $day_leave_recorded = false; // Fix: Flag to prevent duplicate dates
                                if (count($rs_sum) > 0) {
                                    for ($k = 0; $k < count($rs_sum); $k++) {
                                        // Check if attendance record itself indicates leave (start_status 2)
                                        $is_leave_status = ($rs_sum[$k]['start_status'] == '2');
                                        
                                        // Combined leave check: DB Record OR Attendance Status for exemption
                                        $is_exempt = $has_leave_db || $is_leave_status;

                                        // Restore: Show "Leave" in summary if scan is status 2 OR they have an approved DB record
                                        // (This aligns with edit.php for half-day leaves)
                                        if ($is_exempt && !$day_leave_recorded) {
                                            $leave .= date('d', $date_d) . ",";
                                            $leave_num = $leave_num + 1;
                                            $day_leave_recorded = true; 
                                        }

                                        if (($rs_sum[$k]['start_status'] == '1' || $rs_sum[$k]['start_status'] == '3') && !$is_exempt) {
                                            $late .= date('d', $date_d) . ",";
                                            $late_num = $late_num + 1;
                                        }
                                        if (($rs_sum[$k]['end_status'] == '1' || $rs_sum[$k]['end_time'] == '') && !$is_exempt) {
                                            // Fix: If end_time exists, do not show as penalty (report3d technique)
                                            if ($rs_sum[$k]['end_time'] != '') {
                                                continue;
                                            }
                                            $logout .= date('d', $date_d) . ",";
                                            $logout_num = $logout_num + 1;
                                        }
                                    }
                                } else {
                                    // If NO scan, summarize based on DB leave
                                    if ($has_leave_db) {
                                        $leave .= date('d', $date_d) . ",";
                                        $leave_num = $leave_num + 1;
                                    } else {
                                        $no_work .= date('d', $date_d) . ",";
                                        $no_work_num = $no_work_num + 1;
                                    }
                                }
                            }
                        }
                    }
                }
                //---
                $name = explode(",", $rs[$i]['fullname']);
                $name = $rs[$i]['nickname'] != "" ? $rs[$i]['nickname'] : $name[0];
                $txt_l = "";
                $txt_le = "";
                $txt_g = "";
                $txt_w = "";
                $txt_lm = "";
                $txt_lem = "";
                $txt_gm = "";
                $txt_wm = "";
                if ($leave_num > 0) {
                    $txt_le = "ลา : " . $leave . "<br>";
                    $txt_lem = "- ลา : " . $leave . PHP_EOL;
                }
                    if ($late_num > 0) {
                        $txt_l = "สาย : " . $late . "<br>";
                        $txt_lm = "- สาย : " . $late . PHP_EOL;
                    }
                    if ($logout_num > 0) {
                        $txt_g = "ไม่ลงชื่อออกงาน/ออกก่อนเวลา : " . $logout . "<br>";
                        $txt_gm = "- ไม่ลงชื่อออกงาน/ออกก่อนเวลา : " . $logout . PHP_EOL;
                    }
                    if ($no_work_num > 0) {
                        $txt_w = "ไม่ลงชื่อเข้างาน : " . $no_work . "<br>";
                        $txt_wm = "- ไม่ลงชื่อเข้างาน : " . $no_work . PHP_EOL;
                    }
                    if ($late_num != 0 || $logout_num != 0 || $no_work_num != 0 || $leave_num > 0) {
                        $text .= "
                        " . $name . " => " . $txt_le . $txt_l . "" . $txt_g . "" . $txt_w .
                            "<br>----------<br>
                        ";
                        $text_m .= $name . PHP_EOL . $txt_lem . $txt_lm . "" . $txt_wm  . "" . $txt_gm .
                            "----------" . PHP_EOL . "";
                    }
            }
        }
        //---
        $date_th_end = $create_date;
        shortThaiDate($date_th_end);
        $date_pre_th = $date_pre;
        shortThaiDate($date_pre_th);
        //---
        // if ($org_id == '2') {
        //     $access_token = "tQbjuGTfTk1bgEP8neAOZs64iFo1z47ywxgTMEsqjWm"; // token iSmart
        // } else {
        //     $access_token = "y4r15jSETW794qYVijThKQbvtTt5qaNXJCoBk0yRkA2"; // token iSmart
        // }
        // Test
        // $access_token = "8CwfpQRgQ9in43I6k54WVJAPXCghCKVYmurdvPCfws9"; // token iSmart
        $msg = 'App iSmartLogin' . PHP_EOL . 'สรุปการเข้าทำงาน ตั้งแต่วันที่ ' . $date_pre_th . ' ถึง ' . $date_th_end . PHP_EOL . PHP_EOL;
        $msg .= $text_m;
        $message_data = array(
            'message' => $msg, //ข้อความที่ต้องการส่ง สูงสุด 1000 ตัวอักษร
            'imageThumbnail' => '', // ขนาดสูงสุด 240×240px JPEG
            'imageFullsize' => '', // ขนาดสูงสุด 1024×1024px JPEG
            /* 'stickerPackageId' => 1, // Package ID ของสติกเกอร์
		'stickerId' => 410, // ID ของสติกเกอร์ */
        );
        // $result = $this->send_notify_line($access_token, $message_data);
        ///----
        echo "App iSmartLogin สรุปการเข้าทำงาน ตั้งแต่วันที่ " . $date_pre_th . " ถึง " . $date_th_end . "<br><br>
        " . $text . "
        ";
        //---


        echo json_encode($rs, JSON_UNESCAPED_UNICODE);
        exit();
    }


    public function lineNotifyLate_old()
    {
        $org_id = request('org_id');
        $date_pre = request('start_date');
        $create_date = request('end_date');

        ///
        if (!$org_id) {
            $org_id = getParam(3);
            if (!$org_id) {

                return;
            }
        }

        if ($org_id == '2') {
            $access_token = "tQbjuGTfTk1bgEP8neAOZs64iFo1z47ywxgTMEsqjWm"; // token iSmart
        } else {
            $access_token = "y4r15jSETW794qYVijThKQbvtTt5qaNXJCoBk0yRkA2"; // token iSmart
        }
        // Test
        // $access_token = "KYZjHL1VFStCVWcnljOqwtoY8R5tcw7Z6eyylxNVIZf"; // token iSmart

        updateAttendDailyStatus($org_id);
        if (!$create_date) {
            $create_date = date('Y-m-d', strtotime('yesterday'));
        } else {
            $date_1 = strtotime($create_date);
            $create_date = date('Y-m-d', $date_1);
        }

        $date_th_end = $create_date;
        shortThaiDate($date_th_end);
        //---
        if (!$date_pre) {
            $date_pre = date("Y-m-d", strtotime("-1 month"));
        }

        $date_pre_th = $date_pre;
        shortThaiDate($date_pre_th);
        //---
        $data = orgAttendDailyNum($org_id, $create_date);
        $data_outside = orgAttendDailyNum($org_id, $create_date, '3');
        // per($data_outside);
        // exit();
        $data['num_ontime_outside'] = $data_outside['num_ontime'];
        $data['num_late_outside'] = $data_outside['num_late'];

        $msg = 'App iSmartLogin' . PHP_EOL . 'สรุปการเข้าทำงาน ตั้งแต่วันที่ ' . $date_pre_th . ' ถึง ' . $date_th_end . PHP_EOL;

        echo $msg;
        //-------สาย-----------
        $msg .= PHP_EOL . '⏰ ผู้มาสาย';
        $db = getDBO();
        $db->setQuery("
            SELECT      create_date
            FROM        attend_" . $org_id . "_summary AS s
            WHERE       local_id='" . Site::$local_id . "'
            AND         create_date BETWEEN '{$date_pre}' AND '{$create_date}'
            AND         num_late > 0
        ");
        $rs = $db->loadAssocList();
        $len = count($rs);
        $item = array();
        for ($i = 0; $i < $len; $i++) {
            $date = $rs[$i]['create_date'];
            $daily = orgAttendDaily($org_id, $date);
            $item[$date] = $daily['rs_late'];
        }
        if (count($item)) {
            foreach ($item as $date => $rs) {
                $date_th = $date;
                shortThaiDate($date_th);
                $len = count($rs);
                $name = array();
                for ($i = 0; $i < $len; $i++) {
                    $fullname = $rs[$i]['fullname'];
                    $fullname_ar = explode(",", $fullname);
                    $name[] = $rs[$i]['nickname'] == "" ? $fullname_ar[0] . ' ' . $fullname_ar[1] . ', ' : $rs[$i]['nickname'] . ', ';
                    $uid = $rs[$i]['uid'];
                    if (@$user[$uid]) {
                        $user[$uid]['date_th'][] = $date_th;
                    } else {
                        $fullname = $rs[$i]['fullname'];
                        $fullname_ar = explode(",", $fullname);
                        $user[$uid] = array(
                            'fullname' => $rs[$i]['nickname'] == "" ? $fullname_ar[0] . ' ' . $fullname_ar[1] : $rs[$i]['nickname'],
                            'date_th' => array($date_th)
                        );
                    }
                }
                $msg .= PHP_EOL  . $date_th . ' ' . implode(' ', $name);
            }
        } else {
            $msg .= PHP_EOL . 'ไม่มีผู้มาสาย';
        }
        //-------ไม่ลงชื่อเข้างาน-----------
        $msg .= PHP_EOL . PHP_EOL . '🖊 ผู้ไม่ลงชื่อเข้างาน';
        $db = getDBO();
        $db->setQuery("
            SELECT      create_date
            FROM        attend_" . $org_id . "_summary AS s
            WHERE       local_id='" . Site::$local_id . "'
            AND         create_date BETWEEN '{$date_pre}' AND '{$create_date}'
            AND         num_absence > 0
        ");
        $rs = $db->loadAssocList();
        $len = count($rs);
        $item = array();
        for ($i = 0; $i < $len; $i++) {
            $date = $rs[$i]['create_date'];
            $daily = orgAttendDaily($org_id, $date);
            $item[$date] = $daily['rs_absence'];
        }
        if (count($item)) {
            foreach ($item as $date => $rs) {
                $date_th = $date;
                shortThaiDate($date_th);
                $len = count($rs);
                $name = array();
                for ($i = 0; $i < $len; $i++) {
                    $fullname = $rs[$i]['fullname'];
                    $fullname_ar = explode(",", $fullname);
                    $name[] = $rs[$i]['nickname'] == "" ? $fullname_ar[0] . ' ' . $fullname_ar[1] . ', ' : $rs[$i]['nickname'] . ', ';
                    $uid = $rs[$i]['uid'];
                    if (@$user[$uid]) {
                        $user[$uid]['date_th'][] = $date_th;
                    } else {
                        $fullname = $rs[$i]['fullname'];
                        $fullname_ar = explode(",", $fullname);
                        $user[$uid] = array(
                            'fullname' => $rs[$i]['nickname'] == "" ? $fullname_ar[0] . ' ' . $fullname_ar[1] : $rs[$i]['nickname'],
                            'date_th' => array($date_th)
                        );
                    }
                }
                $msg .= PHP_EOL  . $date_th . ' ' . implode(' ', $name);
            }
        } else {
            $msg .= PHP_EOL . 'ไม่มีผู้ไม่ลงชื่อเข้างาน';
        }

        // $access_token = "8CwfpQRgQ9in43I6k54WVJAPXCghCKVYmurdvPCfws9"; // token iSmart

        $message_data = array(
            'message' => $msg, //ข้อความที่ต้องการส่ง สูงสุด 1000 ตัวอักษร
            'imageThumbnail' => '', // ขนาดสูงสุด 240×240px JPEG
            'imageFullsize' => '', // ขนาดสูงสุด 1024×1024px JPEG
            /* 'stickerPackageId' => 1, // Package ID ของสติกเกอร์
		'stickerId' => 410, // ID ของสติกเกอร์ */
        );
        $result = $this->send_notify_line($access_token, $message_data);
        //-------ทำงานนอกสถานที่-----------
        $msg = "";
        $msg = 'App iSmartLogin' . PHP_EOL . 'สรุปการเข้าทำงาน ตั้งแต่วันที่ ' . $date_pre_th . ' ถึง ' . $date_th_end . PHP_EOL;
        $msg .=  PHP_EOL . '🚙 ผู้ทำงานนอกสถานที่';
        $db = getDBO();
        $db->setQuery("
            SELECT      create_date
            FROM        attend_" . $org_id . "_summary AS s
            WHERE       local_id='" . Site::$local_id . "'
            AND         create_date BETWEEN '{$date_pre}' AND '{$create_date}'
            AND         num_outside > 0
        ");
        $rs = $db->loadAssocList();
        $len = count($rs);
        $item = array();
        for ($i = 0; $i < $len; $i++) {
            $date = $rs[$i]['create_date'];
            $daily = orgAttendDaily($org_id, $date);
            $item[$date] = $daily['rs_outside'];
        }
        if (count($item)) {
            foreach ($item as $date => $rs) {
                $date_th = $date;
                shortThaiDate($date_th);
                $len = count($rs);
                $name = array();
                for ($i = 0; $i < $len; $i++) {
                    $fullname = $rs[$i]['fullname'];
                    $fullname_ar = explode(",", $fullname);
                    $name[] = $rs[$i]['nickname'] == "" ? $fullname_ar[0] . ' ' . $fullname_ar[1] . ', ' : $rs[$i]['nickname'] . ', ';
                    $uid = $rs[$i]['uid'];
                    if (@$user[$uid]) {
                        $user[$uid]['date_th'][] = $date_th;
                    } else {
                        $fullname = $rs[$i]['fullname'];
                        $fullname_ar = explode(",", $fullname);
                        $user[$uid] = array(
                            'fullname' => $rs[$i]['nickname'] == "" ? $fullname_ar[0] . ' ' . $fullname_ar[1] : $rs[$i]['nickname'],
                            'date_th' => array($date_th)
                        );
                    }
                }
                $msg .= PHP_EOL  . $date_th . ' ' . implode(' ', $name);
            }
        } else {
            $msg .= PHP_EOL . 'ไม่มีผู้ทำงานนอกสถานที่';
        }


        $db = getDBO();
        $db->setQuery(" SELECT * FROM org_information WHERE id={$org_id} ");
        $uploadKey = $db->loadAssocList();
        $uploadKey = @$uploadKey[0]['uploadKey'];

        $msg .= PHP_EOL . PHP_EOL . '- ดูรายละเอียดเพิ่มเติม - ';
        $msg .= PHP_EOL . 'ไม่ลงชื่อเข้างาน : ' . base_url() . 'attend_result/summary_absence/?org=' . $uploadKey . '&start_date=' . $date_pre . '&end_date=' . $create_date;
        $msg .= PHP_EOL . 'มาสาย : ' . base_url() . 'attend_result/summary_late/?org=' . $uploadKey . '&start_date=' . $date_pre . '&end_date=' . $create_date;

        // exit($msg);
        // next version will keep in database (tbl: org_info)

        // $access_token = "8CwfpQRgQ9in43I6k54WVJAPXCghCKVYmurdvPCfws9"; // token iSmart

        $message_data = array(
            'message' => $msg, //ข้อความที่ต้องการส่ง สูงสุด 1000 ตัวอักษร
            'imageThumbnail' => '', // ขนาดสูงสุด 240×240px JPEG
            'imageFullsize' => '', // ขนาดสูงสุด 1024×1024px JPEG
            /* 'stickerPackageId' => 1, // Package ID ของสติกเกอร์
		'stickerId' => 410, // ID ของสติกเกอร์ */
        );
        $result = $this->send_notify_line($access_token, $message_data);
        echo json_encode($result, JSON_UNESCAPED_UNICODE);
        exit();
    }

    private function send_notify_line($access_token, $message_data)
    {
        $headers = array('Method: POST', 'Content-type: multipart/form-data', 'Authorization: Bearer ' . $access_token);
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, 'https://notify-api.line.me/api/notify');
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, 0);
        curl_setopt($ch, CURLOPT_POSTFIELDS, $message_data);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
        $result = curl_exec($ch);
        // Check Error
        if (curl_error($ch)) {
            $return_array = array('status' => '000: send fail', 'message' => curl_error($ch));
        } else {
            $return_array = json_decode($result, true);
        }
        curl_close($ch);
        return $return_array;
    }

    public function imageResizeAll()
    {
        ini_set('memory_limit', '4096M');
        $org_id = 1;
        $db = getDBO();

        $sql = "
			SELECT				*
			FROM				attend_1_attachments
			";

        $db->setQuery($sql);
        $rs = $db->loadAssocList();
        for ($i = 0; $i < count($rs); $i++) {
            $filePath = $rs[$i]['filepath'];
            $file_size = uploadResize($filePath, $filePath, Site::$maxImageWidth, Site::$maxImageHeight, Site::$maxImageSize, Site::$imageQuality);

            // echo $filePath . " ===> " . $file_size . " <br> ";

        }
        echo "finish";
    }

    public function lineNotifyOt()
    {
        $org_id = getParam(3);
        if (!$org_id) {
            return;
        }

        $late_month = date("Y-m", strtotime("-1 month"));
        $late_month = $late_month . "-26";
        $current_month = date("Y-m");
        $current_month = $current_month . "-25";

        $db = getDBO();
        $sql = "SELECT      create_by
                FROM        attend_" . $org_id . "_information
                WHERE       cid = '3'
                AND         DATE(create_date) BETWEEN '{$late_month}' AND '{$current_month}'
                GROUP BY create_by";
        $db->setQuery($sql);
        $rs = $db->loadAssocList();
        $len = count($rs);
        $tmp_current_month = $current_month;
        $tmp_late_month = $late_month;
        shortThaiDate($tmp_current_month);
        shortThaiDate($tmp_late_month);
        $title = "App iSmartLogin สรุปการบันทึก OT ตั้งแต่วันที่ " . $tmp_late_month . " ถึง " . $tmp_current_month . PHP_EOL;
        $msg = '';
        for ($i = 0; $i < $len; $i++) {
            $sql = "SELECT      *
                    FROM        attend_" . $org_id . "_information
                    WHERE       cid = '3'
                    AND         create_by = '{$rs[$i]['create_by']}'
                    AND         DATE(create_date) BETWEEN '{$late_month}' AND '{$current_month}'";
            $db->setQuery($sql);
            $rs2 = $db->loadAssocList();
            $len2 = count($rs2);
            $sql = "SELECT      *
                    FROM        users
                    WHERE       id = '{$rs[$i]['create_by']}'";
            $db->setQuery($sql);
            $name = $db->loadAssocList();
            $name = str_replace(",", " ", $name[0]['fullname']);
            $msg .= $name . PHP_EOL;
            $sum = array();
            for ($j = 0; $j < $len2; $j++) {
                $date = $rs2[$j]['create_date'];
                shortThaiDate($date);
                $data = json_decode($rs2[$j]['start_note'], true);
                if ($data[0]['times']) {
                    $sum[] = $data[0]['times'];
                    $msg .= $date . " " . $data[0]['topic'] . " " . $data[0]['description'] . " " . $data[0]['times'] . " ชั่วโมง" . PHP_EOL;
                    if ($j == $len2 - 1) {
                        $msg .= "รวม OT ทั้งหมด " . array_sum($sum) . " ชั่วโมง" . PHP_EOL;
                    }
                }
            }
            $msg .= "----------" . PHP_EOL;
        }
        $url = "https://ismartlogin.cityvariety.com/summary/lineNotifyOtLink/1";
        $msg .= 'ดูรายละเอียดเพิ่มเติม : <a href="' . $url . '" target="_blank">คลิกที่นี่</a>';
        //pre($title . $msg);
        //exit();
        $access_token = "EMqAXuM80LEtB2XarzkXRrovJDeQikbzUBN2ReOuUn3";
        if ($msg && $access_token) {
            $message_data = array(
                'message' => $msg,
                'imageThumbnail' => '',
                'imageFullsize' => '',
            );
            $result = $this->send_notify_line($access_token, $message_data);
        }
    }

    public function lineNotifyOtWeek()
    {
        $org_id = getParam(3);
        if (!$org_id) {
            return;
        }


        $mondayLastWeek = strtotime("last week");
        $sundayLastWeek = strtotime("+6 days", $mondayLastWeek);
        $mondayLastWeek = date("Y-m-d", $mondayLastWeek);
        $sundayLastWeek = date("Y-m-d", $sundayLastWeek);

        $db = getDBO();
        $sql = "SELECT      create_by
                FROM        attend_" . $org_id . "_information
                WHERE       cid = '3'
                AND         DATE(create_date) BETWEEN '{$mondayLastWeek}' AND '{$sundayLastWeek}'
                GROUP BY create_by";
        $db->setQuery($sql);
        $rs = $db->loadAssocList();

        // pre($sql);
        // exit();

        $len = count($rs);
        $tmp_current_month = $mondayLastWeek;
        $tmp_late_month = $sundayLastWeek;
        shortThaiDate($tmp_current_month);
        shortThaiDate($tmp_late_month);
        $title = "App iSmartLogin สรุปการบันทึก OT สัปดาห์ที่ผ่านมา ตั้งแต่วันที่ " . $tmp_current_month . " ถึง " . $tmp_late_month . PHP_EOL;
        $msg = '';
        for ($i = 0; $i < $len; $i++) {
            $sql = "SELECT      *
                    FROM        attend_" . $org_id . "_information
                    WHERE       cid = '3'
                    AND         create_by = '{$rs[$i]['create_by']}'
                    AND         DATE(create_date) BETWEEN '{$mondayLastWeek}' AND '{$sundayLastWeek}'";
            $db->setQuery($sql);
            $rs2 = $db->loadAssocList();
            $len2 = count($rs2);
            $sql = "SELECT      *
                    FROM        users
                    WHERE       id = '{$rs[$i]['create_by']}'";
            $db->setQuery($sql);
            $name = $db->loadAssocList();
            $name = str_replace(",", " ", $name[0]['fullname']);
            $msg .= $name . PHP_EOL;
            $sum = array();
            for ($j = 0; $j < $len2; $j++) {
                $date = $rs2[$j]['create_date'];
                shortThaiDate($date);
                $data = json_decode($rs2[$j]['start_note'], true);
                if ($data[0]['times']) {
                    $sum[] = $data[0]['times'];
                    $msg .= $date . " " . $data[0]['topic'] . " " . $data[0]['description'] . " " . $data[0]['times'] . " ชั่วโมง" . PHP_EOL;
                    if ($j == $len2 - 1) {
                        $msg .= "รวม OT ทั้งหมด " . array_sum($sum) . " ชั่วโมง" . PHP_EOL;
                    }
                }
            }
            $msg .= "----------" . PHP_EOL;
        }
        // pre($title . $msg);
        // exit();
        $access_token = "EMqAXuM80LEtB2XarzkXRrovJDeQikbzUBN2ReOuUn3";
        if ($msg && $access_token) {
            $message_data = array(
                'message' => $msg,
                'imageThumbnail' => '',
                'imageFullsize' => '',
            );
            $result = $this->send_notify_line($access_token, $message_data);
        }
    }

    public function lineNotifyOtLink()
    {
        $org_id = getParam(3);
        if (!$org_id) {
            return;
        }

        $late_month = date("Y-m", strtotime("-1 month"));
        $late_month = $late_month . "-26";
        $current_month = date("Y-m");
        $current_month = $current_month . "-25";

        $db = getDBO();
        $sql = "SELECT      create_by
                FROM        attend_" . $org_id . "_information
                WHERE       cid = '3'
                AND         DATE(create_date) BETWEEN '{$late_month}' AND '{$current_month}'
                GROUP BY create_by";
        $db->setQuery($sql);
        $rs = $db->loadAssocList();
        $len = count($rs);
        $tmp_current_month = $current_month;
        $tmp_late_month = $late_month;
        shortThaiDate($tmp_current_month);
        shortThaiDate($tmp_late_month);
        $title = "App iSmartLogin สรุปการบันทึก OT ตั้งแต่วันที่ " . $tmp_late_month . " ถึง " . $tmp_current_month . PHP_EOL;
        $msg = '';
        for ($i = 0; $i < $len; $i++) {
            $sql = "SELECT      *
                    FROM        attend_" . $org_id . "_information
                    WHERE       cid = '3'
                    AND         create_by = '{$rs[$i]['create_by']}'
                    AND         DATE(create_date) BETWEEN '{$late_month}' AND '{$current_month}'";
            $db->setQuery($sql);
            $rs2 = $db->loadAssocList();
            $len2 = count($rs2);
            $sql = "SELECT      *
                    FROM        users
                    WHERE       id = '{$rs[$i]['create_by']}'";
            $db->setQuery($sql);
            $name = $db->loadAssocList();
            $name = str_replace(",", " ", $name[0]['fullname']);
            $msg .= $name . PHP_EOL;
            $sum = array();
            for ($j = 0; $j < $len2; $j++) {
                $date = $rs2[$j]['create_date'];
                shortThaiDate($date);
                $data = json_decode($rs2[$j]['start_note'], true);
                if ($data[0]['times']) {
                    $sum[] = $data[0]['times'];
                    $msg .= $date . " " . $data[0]['topic'] . " " . $data[0]['description'] . " " . $data[0]['times'] . " ชั่วโมง" . PHP_EOL;
                    if ($j == $len2 - 1) {
                        $msg .= "รวม OT ทั้งหมด " . array_sum($sum) . " ชั่วโมง" . PHP_EOL;
                    }
                }
            }
            $msg .= "----------" . PHP_EOL;
        }
        // $url = "https://ismartlogin.cityvariety.com/summary/lineNotifyOtLink/1";
        // $msg .= 'ดูรายละเอียดเพิ่มเติม : <a href="' . $url.'" target="_blank">คลิกที่นี่</a>';
        pre($title . $msg);
        exit();
        // $access_token = "EMqAXuM80LEtB2XarzkXRrovJDeQikbzUBN2ReOuUn3";
        // if ($msg && $access_token) {
        //     $message_data = array(
        //         'message' => $msg,
        //         'imageThumbnail' => '',
        //         'imageFullsize' => '',
        //     );
        //     $result = $this->send_notify_line($access_token, $message_data);
        // }
    }

    public function testTelegramBot()
    {
        $msg = 'Test Telegram Bot จาก web site';
        $botToken = TelegramConfig::$botToken;
        $chatId = '-4682000244';
        $this->sendTelegramMessage($botToken, $chatId, $msg);
    }

    private function sendTelegramMessage($botToken, $chatId, $message)
    {
        $url = "https://api.telegram.org/bot$botToken/sendMessage";

        // ข้อมูลที่ต้องส่งไปยัง API
        $data = [
            'chat_id' => $chatId,
            'text' => $message
        ];

        // ใช้ cURL ส่งข้อมูล
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_POST, 1);
        curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($data));
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

        $response = curl_exec($ch);
        curl_close($ch);
    }
}
