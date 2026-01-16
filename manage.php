<?php if (!defined('BASEPATH'))
    exit('No direct script access allowed');

class manage extends CI_Controller
{

    /**
     *
     * @var Array All Available tables 
     */
    public $_TABLE = array(
        'info' => 'users',
        'file' => '',
        'category' => ''
    );
    public $data = array(
        '_CMD' => 'manage',
        'body' => '',
        'menuName' => ''
    );
    public $maxRows = 8;
    public $avialableTag = '<p><a><img><span><div><table><tbody><tr><td><th><ul><li><qoute><font><ol><style><strong><em><u><i><h4><h5><h6>';
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
            $subView = ob_get_clean();
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
        $db = getDBO();
        $db->setQuery("UPDATE ebook_attachments SET hits=hits+1 WHERE id='{$id}' ");
        $db->query();
    }
    public function updateHit($id)
    {
        $db = getDBO();
        $db->setQuery("UPDATE {$this->_TABLE['info']} SET hits=hits+1 WHERE id='{$id}' ");
        $db->query();
    }
    //-----

    function getTime()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        //-----
        $org_id = $var['org_id'] ? $var['org_id'] : request('org_id');
        $id = $var['id'] ? $var['id'] : request('id');
        $db = getDBO();
        if ($id) {
            $filter = "AND id = {$id}";
        }
        if ($org_id) {
            $sql = "SELECT          * 
					FROM            time_information
					WHERE           org_id = {$org_id}
                    AND             status != '2'
                                    {$filter}
                    ORDER BY id ASC";
            $db->setQuery($sql);
            $data = $db->loadAssocList();
            $items = array();
            for ($i = 0; $i < count($data); $i++) {
                $items[$i] = array(
                    'id' => $data[$i]['id'],
                    'org_id' => $data[$i]['org_id'],
                    'subject' => $data[$i]['subject'],
                    'create_date' => $data[$i]['create_date'],
                    'update_date' => $data[$i]['update_date'],
                    'status' => $data[$i]['status'],
                    'description' => $data[$i]['description'],
                );
            }
            //check ทำ ot หรือไม่
            $sql = "SELECT          ot_status
                    FROM            org_information
                    WHERE           id = {$org_id}
                    AND             status = '1'
                    ORDER BY id ASC";
            $db->setQuery($sql);
            $org = $db->loadAssocList();

            $item[0] = array(
                'msg' => 'success',
                'ot' => $org[0]['ot_status'],
                'status' => true,
                'result' => $items,
            );
        } else {
            $item[0] = array(
                'msg' => 'fails',
                'status' => false,
                'result' => [],
            );
        }
        echo json_encode($item, JSON_UNESCAPED_UNICODE);
        exit();
    }

    function getOrgSEDetail()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        $org_id = $var['org_id'] ? $var['org_id'] : request('org_id');
        $id = $var['id'] ? $var['id'] : request('id');
        $db = getDBO();
        if ($org_id) {
            $sql = "SELECT          * 
                    FROM            org_information
                    WHERE           id = {$org_id}
                    AND             status = '1'
                    ORDER BY id ASC";
            $db->setQuery($sql);
            $data = $db->loadAssocList();
            $items = array();
            $items[0]['start_time_login'] = $data[0]['start_time_login'] ? $data[0]['start_time_login'] : '';
            $items[0]['end_time_login'] = $data[0]['end_time_login'] ? $data[0]['end_time_login'] : '';
            $items[0]['status'] = 'success';
        } else {
            $items[0]['status'] = 'fail';
        }
        echo json_encode($items, JSON_UNESCAPED_UNICODE);
        exit();
    }

    function postTime()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        //-----
        $subject = $var['subject'] ? $var['subject'] : request('subject');
        $org_id = $var['org_id'] ? $var['org_id'] : request('org_id');
        $description = $var['description'] ? $var['description'] : request('description');
        $status = $var['status'] ? $var['status'] : request('status');
        $type = $var['type'] ? $var['type'] : request('type');
        $id = $var['id'] ? $var['id'] : request('id');
        //-----
        $obj = new stdClass();
        $obj->subject = $subject;
        $obj->org_id = $org_id;
        $obj->description = $description;
        $obj->status = $status;

        $db = getDBO();
        if ($type == "insert") {
            $obj->create_date = date('Y-m-d H:i:s');
            $obj->create_ip = getIPAddress();
            $insert = $db->insertObject("time_information", $obj);
        } else {
            $obj->id = $id;
            $obj->update_date = date('Y-m-d H:i:s');
            $obj->update_ip = getIPAddress();
            $insert = $db->updateObject("time_information", $obj, 'id');
        }

        if ($insert) {
            $rs[0] = array(
                "msg" => "success",
                "status" => true,
            );
        } else {
            $rs[0] = array(
                "msg" => "fails",
                "status" => false,
            );
        }
        echo json_encode($rs);
        exit();
    }

    function postTimeSTManage()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        //-----
        $org_id = $var['org_id'] ? $var['org_id'] : request('org_id');
        $uid = $var['uid'] ? $var['uid'] : request('uid');
        $start_time_login = $var['start_time_login'] ? $var['start_time_login'] : request('start_time_login');
        $end_time_login = $var['end_time_login'] ? $var['end_time_login'] : request('end_time_login');

        $db = getDBO();
        $obj = new stdClass();
        $obj->id = $org_id;
        if ($start_time_login) {
            $obj->start_time_login = $start_time_login;
        }
        if ($end_time_login) {
            $obj->end_time_login = $end_time_login;
        }
        $obj->update_date = date('Y-m-d H:i:s');
        $obj->update_ip = getIPAddress();
        $insert = $db->updateObject('org_information', $obj, 'id');
        if ($insert) {
            $rs[0] = array(
                "status" => "success",
            );
        } else {
            $rs[0] = array(
                "status" => "fails",
            );
        }
        echo json_encode($rs);
        exit();
    }


    function postDepartment()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        //-----
        $org_id = $var['org_id'] ? $var['org_id'] : request('org_id');
        $subject = $var['subject'] ? $var['subject'] : request('subject');
        $latitude = $var['latitude'] ? $var['latitude'] : request('latitude');
        $longitude = $var['longitude'] ? $var['longitude'] : request('longitude');
        $radius = $var['radius'] ? $var['radius'] : request('radius');
        $type = $var['type'] ? $var['type'] : request('type');
        $id = $var['id'] ? $var['id'] : request('id');
        $time_id = $var['time_id'] ? $var['time_id'] : request('time_id');


        //-----
        $obj = new stdClass();
        $obj->parent_id = $org_id;
        $obj->subject = $subject;
        $obj->latitude = $latitude;
        $obj->longitude = $longitude;
        $obj->radius = $radius;
        $obj->time_id = $time_id;
        $obj->status = '1';
        if ($type == 'insert') {
            $obj->create_date = date('Y-m-d H:i:s');
            $obj->create_ip = getIPAddress();
            $db = getDBO();
            $insert = $db->insertObject('org_information', $obj);
        } else {
            $obj->id = $id;
            $obj->update_date = date('Y-m-d H:i:s');
            $obj->update_ip = getIPAddress();
            $db = getDBO();
            $insert = $db->updateObject('org_information', $obj, 'id');
        }

        if ($insert) {
            $rs[0] = array(
                "msg" => "success",
                "status" => true,
            );
        } else {
            $rs[0] = array(
                "msg" => "fails",
                "status" => false,
            );
        }
        echo json_encode($rs, JSON_UNESCAPED_UNICODE);
        exit();
    }

    function getDepartment()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        //-----
        $org_id = $var['org_id'] ? $var['org_id'] : request('org_id');
        $id = $var['id'] ? $var['id'] : request('id');
        if ($id) {
            $filter = "AND id = {$id} ";
        }
        //-----
        $db = getDBO();
        $sql = "
                SELECT          * 
                FROM            org_information
                WHERE           parent_id = {$org_id}
                AND             status = '1'
                {$filter}
                ORDER BY seq ASC,id ASC
            ";
        $db->setQuery($sql);
        $data = $db->loadAssocList();
        $data_result = array();
        if ($org_id) {
            for ($i = 0; $i < count($data); $i++) {
                // $sql = "SELECT admin_branch_id FROM users WHERE id = {$data[$i]['id']} AND status = '1'";
                // $db->setQuery($sql);
                // $admin_branch_id = $db->loadAssocList();
                $data_result[$i] = array(
                    "id" => $data[$i]['id'],
                    "seq" => $data[$i]['seq'],
                    "parent_id" => $data[$i]['parent_id'],
                    "invite_code" => $data[$i]['invite_code'],
                    "subject" => $data[$i]['subject'],
                    "latitude" => $data[$i]['latitude'],
                    "longitude" => $data[$i]['longitude'],
                    "radius" => $data[$i]['radius'],
                    "create_date" => $data[$i]['create_date'],
                    "update_date" => $data[$i]['update_date'] == null ? '' : $data[$i]['update_date'],
                    "noti" => $data[$i]['noti_status'],
                    "status" => $data[$i]['status'],
                    "time_id" => $data[$i]['time_id'] == null ? '' : $data[$i]['time_id'],
                    // "admin_branch_id" => $admin_branch_id[0]['admin_branch_id'] ? $admin_branch_id[0]['admin_branch_id'] : '0',
                );
            }
            $rs[0] = array(
                "msg" => "success",
                "status" => true,
                "result" => $data_result
            );
        } else {
            $rs[0] = array(
                "msg" => "fails",
                "status" => false,
                "result" => []
            );
        }
        echo json_encode($rs, JSON_UNESCAPED_UNICODE);
        exit();
    }

    function getDepartment2()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        //-----
        $org_id = $var['org_id'] ? $var['org_id'] : request('org_id');
        $id = $var['id'] ? $var['id'] : request('id');
        if ($id) {
            $filter = "AND id = {$id} ";
        }
        //-----
        $db = getDBO();
        $sql = "
                SELECT          * 
                FROM            org_information
                WHERE           parent_id = {$org_id}
                AND             status = '1'
                {$filter}
                ORDER BY seq ASC,id ASC
            ";
        $db->setQuery($sql);
        $data = $db->loadAssocList();
        $data_result = array();
        if ($org_id) {
            $data_result[0] = array(
                "id" => '0',
                "seq" => '0',
                "parent_id" => '0',
                "invite_code" => '0',
                "subject" => 'ทั้งหมด',
                "latitude" => '0',
                "longitude" => '0',
                "radius" => '0',
                "create_date" => '0',
                "update_date" => '0',
                "noti" => '0',
                "status" => '0',
                "time_id" => '0',
            );
            $num = 1;
            for ($i = 0; $i < count($data); $i++) {
                // $sql = "SELECT admin_branch_id FROM users WHERE id = {$data[$i]['id']} AND status = '1'";
                // $db->setQuery($sql);
                // $admin_branch_id = $db->loadAssocList();

                $data_result[$num] = array(
                    "id" => $data[$i]['id'],
                    "seq" => $data[$i]['seq'],
                    "parent_id" => $data[$i]['parent_id'],
                    "invite_code" => $data[$i]['invite_code'],
                    "subject" => $data[$i]['subject'],
                    "latitude" => $data[$i]['latitude'],
                    "longitude" => $data[$i]['longitude'],
                    "radius" => $data[$i]['radius'],
                    "create_date" => $data[$i]['create_date'],
                    "update_date" => $data[$i]['update_date'] == null ? '' : $data[$i]['update_date'],
                    "noti" => $data[$i]['noti_status'],
                    "status" => $data[$i]['status'],
                    "time_id" => $data[$i]['time_id'] == null ? '' : $data[$i]['time_id'],
                    // "admin_branch_id" => $admin_branch_id[0]['admin_branch_id'] ? $admin_branch_id[0]['admin_branch_id'] : '0',
                );
                $num++;
            }
            $rs[0] = array(
                "msg" => "success",
                "status" => true,
                "result" => $data_result
            );
        } else {
            $rs[0] = array(
                "msg" => "fails",
                "status" => false,
                "result" => []
            );
        }
        echo json_encode($rs, JSON_UNESCAPED_UNICODE);
        exit();
    }
// --- เพิ่มฟังก์ชันนี้สำหรับดูสถิติองค์กร ---
 function getOrgStats()
    {
        $db = getDBO();

        // 1. ดึงข้อมูล
        $sql = "SELECT 
                    a.id AS org_id,
                    a.subject AS org_name,
                    COUNT(b.uid) AS member_count
                FROM org_information a
                LEFT JOIN user_relationship b ON a.id = b.org_id
                WHERE a.status = '1'
                GROUP BY a.id, a.subject
                ORDER BY member_count DESC";

        $db->setQuery($sql);
        $data = $db->loadAssocList();

        // 2. คำนวณยอดรวม
        $total_organizations = count($data);
        $total_users = 0;
        
        $rows_html = "";
        $i = 1;
        
        foreach ($data as $row) {
            $count_val = intval($row['member_count']);
            $total_users += $count_val;
            $member_count_fmt = number_format($count_val);
            
            // Logic การแสดงผลอันดับ
            $rank_display = $i;
            $row_class = "";
            $icon_badge = "";

            if($i == 1) { 
                $rank_display = ""; 
                $icon_badge = "<span class='material-icons-round rank-icon gold'>emoji_events</span>";
                $row_class = "top-1";
            } elseif($i == 2) { 
                $rank_display = ""; 
                $icon_badge = "<span class='material-icons-round rank-icon silver'>emoji_events</span>";
            } elseif($i == 3) { 
                $rank_display = ""; 
                $icon_badge = "<span class='material-icons-round rank-icon bronze'>emoji_events</span>";
            }

            $rows_html .= "
                <tr class='{$row_class}'>
                    <td class='col-rank'>{$icon_badge}{$rank_display}</td>
                    <td class='col-name'>
                        <div class='text-truncate'>{$row['org_name']}</div>
                    </td>
                    <td class='col-count'>
                        <span class='count-badge'>{$member_count_fmt}</span>
                    </td>
                </tr>
            ";
            $i++;
        }

        $total_users_format = number_format($total_users);
        $total_orgs_format = number_format($total_organizations);

        // 3. Render HTML
        echo <<<HTML
<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>สถิติองค์กร</title>
    <link href="https://fonts.googleapis.com/css2?family=Prompt:wght@300;400;500;600&display=swap" rel="stylesheet">
    <link href="https://fonts.googleapis.com/icon?family=Material+Icons+Round" rel="stylesheet">
    
    <style>
        :root {
            --bg-body: #f8f9fa;
            --card-bg: #ffffff;
            --text-main: #333333;
            --text-sub: #6c757d;
            --accent: #4f46e5;
            --gold: #f59e0b;
            --silver: #94a3b8;
            --bronze: #b45309;
        }

        * { box-sizing: border-box; }

        body {
            font-family: 'Prompt', sans-serif;
            background-color: var(--bg-body);
            margin: 0;
            padding: 15px;
            color: var(--text-main);
            -webkit-tap-highlight-color: transparent;
        }

        .container {
            max-width: 600px;
            margin: 0 auto;
            width: 100%;
        }

        /* Header & Button */
        .header {
            margin-bottom: 25px;
            text-align: center;
        }
        .header h2 {
            font-size: 1.4rem;
            margin: 0 0 5px 0;
            font-weight: 600;
        }
        .header p {
            font-size: 0.85rem;
            color: var(--text-sub);
            margin: 0 0 15px 0;
        }

        .btn-nav {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%);
            color: white;
            text-decoration: none;
            padding: 10px 20px;
            border-radius: 50px;
            font-size: 0.9rem;
            font-weight: 500;
            box-shadow: 0 4px 10px rgba(124, 58, 237, 0.3);
            transition: transform 0.2s;
        }
        .btn-nav:active { transform: scale(0.96); }
        .btn-nav .material-icons-round { font-size: 1.1rem; }

        /* Summary Cards Grid */
        .summary-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 12px;
            margin-bottom: 20px;
        }

        .stat-card {
            background: var(--card-bg);
            border-radius: 12px;
            padding: 15px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.05);
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            text-align: center;
            position: relative;
            overflow: hidden;
        }
        
        .stat-card::before {
            content: '';
            position: absolute;
            top: 0; left: 0; right: 0; height: 4px;
        }
        .stat-card.blue::before { background: #3b82f6; }
        .stat-card.purple::before { background: #8b5cf6; }

        .card-icon { font-size: 28px; margin-bottom: 5px; }
        .text-blue { color: #3b82f6; }
        .text-purple { color: #8b5cf6; }

        .stat-value {
            font-size: 1.6rem;
            font-weight: 700;
            line-height: 1.2;
            color: var(--text-main);
        }
        .stat-label {
            font-size: 0.75rem;
            color: var(--text-sub);
            font-weight: 500;
        }

        /* List Styles */
        .list-card {
            background: var(--card-bg);
            border-radius: 12px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.05);
            overflow: hidden;
        }

        .list-header {
            padding: 12px 15px;
            background-color: #ffffff;
            border-bottom: 1px solid #f0f0f0;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .list-header h3 { margin: 0; font-size: 1rem; font-weight: 600; }
        .header-icon { color: var(--accent); font-size: 20px; }

        table {
            width: 100%;
            border-collapse: collapse;
            table-layout: fixed; 
        }

        th {
            background-color: #f8f9fa;
            color: var(--text-sub);
            font-weight: 500;
            font-size: 0.75rem;
            text-transform: uppercase;
            padding: 10px 8px;
            text-align: left;
        }

        td {
            padding: 12px 8px;
            border-bottom: 1px solid #f0f0f0;
            font-size: 0.9rem;
            vertical-align: middle;
        }
        tr:last-child td { border-bottom: none; }

        /* Column Config */
        .col-rank { width: 15%; text-align: center; font-weight: 600; color: var(--text-sub); }
        .col-name { width: 65%; }
        .col-count { width: 20%; text-align: center; }

        .text-truncate {
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            width: 100%;
            display: block;
        }

        .count-badge {
            background-color: #eff6ff;
            color: var(--accent);
            padding: 4px 8px;
            border-radius: 6px;
            font-size: 0.8rem;
            font-weight: 600;
            display: inline-block;
            min-width: 30px;
        }

        .rank-icon { font-size: 20px; vertical-align: middle; }
        .gold { color: var(--gold); }
        .silver { color: var(--silver); }
        .bronze { color: var(--bronze); }
        .top-1 { background-color: #fffbeb; }
        .top-1 .col-name { color: #b45309; font-weight: 500; }

        .footer-info {
            text-align: center;
            margin-top: 20px;
            font-size: 0.75rem;
            color: #adb5bd;
        }

        /* Mobile Rules: Hide Rank */
        @media (max-width: 480px) {
            .col-rank { display: none; }
            .col-name { width: 75%; padding-left: 15px; }
            .col-count { width: 25%; }
        }
    </style>
</head>
<body>

    <div class="container">
        
        <div class="header">
            <h2>ภาพรวมระบบ</h2>
            <a href="getOrgActiveStatus" class="btn-nav">
                <span class="material-icons-round">travel_explore</span>
                ตรวจสอบการใช้งานจริง
            </a>
        </div>

        <div class="summary-grid">
            <div class="stat-card blue">
                <span class="material-icons-round card-icon text-blue">domain</span>
                <span class="stat-value">{$total_orgs_format}</span>
                <span class="stat-label">องค์กร</span>
            </div>
            <div class="stat-card purple">
                <span class="material-icons-round card-icon text-purple">groups</span>
                <span class="stat-value">{$total_users_format}</span>
                <span class="stat-label">ผู้ใช้งาน</span>
            </div>
        </div>

        <div class="list-card">
            <div class="list-header">
                <span class="material-icons-round header-icon">leaderboard</span>
                <h3>อันดับองค์กร</h3>
            </div>
            
            <table>
                <thead>
                    <tr>
                        <th class="col-rank">#</th>
                        <th class="col-name">ชื่อองค์กร</th>
                        <th class="col-count">คน</th>
                    </tr>
                </thead>
                <tbody>
                    {$rows_html}
                </tbody>
            </table>
        </div>

        <div class="footer-info">
            ข้อมูล ณ วันที่ <script>document.write(new Date().toLocaleDateString('th-TH'));</script>
        </div>

    </div>

</body>
</html>
HTML;
        exit();
    }
    function getOrgActiveStatus()
    {
        $db = getDBO();

        // 1. ดึงข้อมูลพื้นฐานองค์กร
        $sql = "SELECT 
                    a.id AS org_id,
                    a.subject AS org_name,
                    a.create_date AS created_at,
                    COUNT(b.uid) AS member_count
                FROM org_information a
                LEFT JOIN user_relationship b ON a.id = b.org_id
                WHERE a.status = '1'
                GROUP BY a.id, a.subject, a.create_date
                ORDER BY member_count DESC, a.create_date DESC";

        $db->setQuery($sql);
        $data = $db->loadAssocList();

        $stat_active = 0;   
        $stat_trial = 0;    
        $stat_inactive = 0; 
        
        $rows_html = "";
        
        // วันที่ปัจจุบันสำหรับคำนวณ
        $today = date('Y-m-d');

        foreach ($data as $row) {
            $org_id = $row['org_id'];
            $count = intval($row['member_count']);
            $created_date = date('d/m/y', strtotime($row['created_at']));
            
            // --- ส่วนที่เพิ่ม: ค้นหาวันที่ใช้งานล่าสุด ---
            $last_use_txt = "-";
            $last_use_style = "color: #9ca3af;"; // สีเทา (ถ้าไม่เคยใช้)
            
            // ชื่อตารางเก็บเวลาขององค์กรนี้
            $table_attend = "attend_{$org_id}_information";
            
            // Query วันที่ล่าสุด (ใช้ @ เพื่อข้าม error กรณีตารางยังไม่ถูกสร้าง)
            $sql_last = "SELECT create_date FROM {$table_attend} ORDER BY id DESC LIMIT 1";
            $db->setQuery($sql_last);
            $last_data = @$db->loadAssocList();
            
            if ($last_data && !empty($last_data[0]['create_date'])) {
                $last_date_raw = date('Y-m-d', strtotime($last_data[0]['create_date']));
                $last_use_txt = date('d/m/y', strtotime($last_date_raw));
                
                // คำนวณระยะห่างวัน
                $diff = (strtotime($today) - strtotime($last_date_raw)) / (60 * 60 * 24);
                
                if($diff <= 3) {
                    // ใช้งานภายใน 3 วัน (สีเขียวเข้ม)
                    $last_use_style = "color: #059669; font-weight: 600;"; 
                    $last_use_txt = "✅ " . $last_use_txt;
                } elseif ($diff <= 30) {
                    // ใช้งานภายใน 1 เดือน (สีส้ม)
                    $last_use_style = "color: #d97706;";
                } else {
                    // นานกว่า 1 เดือน (สีแดงอ่อน)
                    $last_use_style = "color: #ef4444;";
                }
            }
            // ----------------------------------------

            // Logic แบ่งสถานะ (Badge)
            $status_badge = "";
            $row_class = "";

            if ($count > 5) {
                $stat_active++;
                $status_badge = "<span class='badge badge-success'>Active</span>";
            } elseif ($count >= 1) {
                $stat_trial++;
                $status_badge = "<span class='badge badge-warning'>Trial</span>";
            } else {
                $stat_inactive++;
                $status_badge = "<span class='badge badge-danger'>Inactive</span>";
                $row_class = "opacity-50";
            }

            $rows_html .= "
                <tr class='{$row_class}'>
                    <td class='col-name'>
                        <div class='org-name'>{$row['org_name']}</div>
                        <div class='meta-text'>สร้าง: {$created_date}</div>
                    </td>
                    <td class='col-count text-center'>
                        <span class='count-number'>{$count}</span>
                    </td>
                    <td class='col-status text-right'>
                        {$status_badge}
                        <div class='meta-text' style='margin-top:3px; {$last_use_style}'>
                            ล่าสุด: {$last_use_txt}
                        </div>
                    </td>
                </tr>
            ";
        }

        // 3. Render Dashboard UI
        echo <<<HTML
<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>สถานะการใช้งานองค์กร</title>
    <link href="https://fonts.googleapis.com/css2?family=Prompt:wght@300;400;500;600&display=swap" rel="stylesheet">
    <link href="https://fonts.googleapis.com/icon?family=Material+Icons+Round" rel="stylesheet">
    
    <style>
        :root {
            --bg-body: #f3f4f6;
            --card-bg: #ffffff;
            --text-main: #111827;
            --text-sub: #6b7280;
        }

        * { box-sizing: border-box; }

        body {
            font-family: 'Prompt', sans-serif;
            background-color: var(--bg-body);
            margin: 0;
            padding: 15px;
            color: var(--text-main);
            -webkit-tap-highlight-color: transparent;
        }

        .container {
            max-width: 600px;
            margin: 0 auto;
        }

        /* Header */
        .header { margin-bottom: 20px; text-align: center; }
        .header h2 { font-size: 1.3rem; font-weight: 600; margin: 0; color: #374151; }
        .header p { font-size: 0.85rem; color: var(--text-sub); margin-top: 4px; }

        /* Dashboard Grid */
        .dashboard-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 8px;
            margin-bottom: 20px;
        }

        .dash-card {
            background: var(--card-bg);
            padding: 12px 5px;
            border-radius: 10px;
            text-align: center;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }

        .dash-val { font-size: 1.4rem; font-weight: 700; line-height: 1.1; margin-bottom: 4px; }
        .dash-label { font-size: 0.65rem; color: var(--text-sub); font-weight: 500; }
        
        .t-success { color: #10b981; }
        .t-warning { color: #f59e0b; }
        .t-danger { color: #ef4444; }

        /* List Styles */
        .list-card {
            background: var(--card-bg);
            border-radius: 12px;
            box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1);
            overflow: hidden;
        }

        .list-header {
            padding: 12px 15px;
            background: #fff;
            border-bottom: 2px solid #f3f4f6;
            font-weight: 600;
            font-size: 0.95rem;
            color: #374151;
            display: flex; align-items: center; gap: 6px;
        }

        table { width: 100%; border-collapse: collapse; }
        
        th {
            background: #f9fafb;
            text-align: left;
            padding: 10px 12px;
            font-size: 0.7rem;
            color: var(--text-sub);
            text-transform: uppercase;
            font-weight: 600;
        }

        td {
            padding: 10px 12px;
            border-bottom: 1px solid #f3f4f6;
            vertical-align: middle;
        }
        tr:last-child td { border-bottom: none; }

        /* Columns */
        .col-name { width: 55%; }
        .col-count { width: 15%; }
        .col-status { width: 30%; }

        .org-name { font-size: 0.9rem; font-weight: 500; color: #111827; margin-bottom: 2px; }
        .meta-text { font-size: 0.7rem; color: #9ca3af; }
        
        .count-number { 
            font-weight: 700; font-size: 1rem; color: #374151; 
            background: #f3f4f6; padding: 2px 8px; border-radius: 8px;
        }

        /* Badges */
        .badge {
            display: inline-block;
            padding: 3px 8px;
            border-radius: 99px;
            font-size: 0.65rem;
            font-weight: 600;
            text-transform: uppercase;
        }
        .badge-success { background: #d1fae5; color: #047857; }
        .badge-warning { background: #fef3c7; color: #b45309; }
        .badge-danger { background: #fee2e2; color: #b91c1c; }
        
        .opacity-50 { opacity: 0.6; }
        .text-center { text-align: center; }
        .text-right { text-align: right; }
    </style>
</head>
<body>

    <div class="container">
        
        <div class="header">
            <h2>Activity Log</h2>
            <p>ตรวจสอบสถานะการใช้งานล่าสุด</p>
        </div>

        <div class="dashboard-grid">
            <div class="dash-card">
                <div class="dash-val t-success">{$stat_active}</div>
                <div class="dash-label">Active (>5 คน)</div>
            </div>
            <div class="dash-card">
                <div class="dash-val t-warning">{$stat_trial}</div>
                <div class="dash-label">Trial (1-5 คน)</div>
            </div>
            <div class="dash-card">
                <div class="dash-val t-danger">{$stat_inactive}</div>
                <div class="dash-label">Inactive (0 คน)</div>
            </div>
        </div>

        <div class="list-card">
            <div class="list-header">
                <span class="material-icons-round" style="color:#6366f1;">history</span> รายการล่าสุด
            </div>
            <table>
                <thead>
                    <tr>
                        <th class="col-name">ชื่อองค์กร</th>
                        <th class="col-count text-center">คน</th>
                        <th class="col-status text-right">สถานะ/ล่าสุด</th>
                    </tr>
                </thead>
                <tbody>
                    {$rows_html}
                </tbody>
            </table>
        </div>
        
        <div style="text-align: center; margin-top: 20px; font-size: 0.7rem; color: #d1d5db;">
            * วันที่ล่าสุดอ้างอิงจากตารางเวลาเข้างาน
        </div>

    </div>

</body>
</html>
HTML;
        exit();
    }
function postOrg()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        //-----
        $subject = $var['subject'] ? $var['subject'] : request('subject');
        $type = $var['type'] ? $var['type'] : request('type');
        $uid = $var['uid'] ? $var['uid'] : request('uid');
        $id = $var['id'] ? $var['id'] : request('id');

        //-----
        $obj = new stdClass();
        $obj->parent_id = 0;
        $obj->subject = $subject;
        $obj->status = '1';
        
        $insert = false; 

        if ($type == 'insert') {
            $obj->invite_code = rand(100000000, 999999999);
            $obj->sub_id = '0';
            $obj->create_date = date('Y-m-d H:i:s');
            $obj->create_ip = getIPAddress();
            $obj->create_by = $uid;
            $db = getDBO();
            $insert_1 = $db->insertObject('org_information', $obj);
            if ($insert_1) {
                $db = getDBO();
                $sql = "SELECT id FROM org_information WHERE status = '1' ORDER BY id DESC";
                $db->setQuery($sql);
                $data = $db->loadAssocList();
                //---
                $obj_1 = new stdClass();
                $obj_1->uid = $uid;
                $obj_1->type = "admin";
                $obj_1->org_id = $data[0]['id'];
                $insert = $db->insertObject('user_relationship', $obj_1);
                //--------
                $obj_2 = new stdClass();
                $obj_2->id = $uid;
                $obj_2->org_id = $data[0]['id'];
                $insert1 = $db->updateObject('users', $obj_2, 'id');
            }
        } else {
            $obj->id = $id;
            $obj->update_date = date('Y-m-d H:i:s');
            $obj->update_ip = getIPAddress();
            $db = getDBO();
            $insert = $db->updateObject('org_information', $obj, 'id');
        }

        if ($insert) {
            $user = getMyOrgId($uid);
            $fullname = str_replace(',', ' ', $user['fullname']);
            $phone = $user['phone'];
            
            // หา ID ของ Org ที่เพิ่งสร้าง/แก้ไข เพื่อใช้ในการสร้างตาราง
            $data_org_id = 0;
            if ($type == 'insert' && isset($data[0]['id'])) {
                $data_org_id = $data[0]['id'];
            } elseif ($id) {
                $data_org_id = $id;
            }

            // จุดตรวจสอบที่ 1: มีชื่อและเบอร์โทรครบไหม?
            if ($fullname && $phone) {

                if ($type == 'insert') {
                    // --- แก้ไข Syntax ตรงนี้ ---
                    $mes = "มีการสร้างองค์กรใหม่" . PHP_EOL . 
                           "ชื่อ : " . $subject . PHP_EOL . 
                           "โดย : " . $fullname . PHP_EOL . 
                           "เบอร์ติดต่อ : " . $phone; // เพิ่มตัวแปร $phone และปิด semi-colon

                    $line_token = "C7780f4fde1552d4e12b438ea6555552f";
                    
                    // เรียกใช้ฟังก์ชันส่งไลน์
                    $this->sendTextToLineGroup($line_token, $mes);
                    // ------------------------------------------------
                }
                
                if ($data_org_id) {
                    $this->createTableOrg($data_org_id);
                }
            } 
            // else {
            //    ถ้าไม่เข้าเงื่อนไขนี้ ไลน์ก็จะไม่ส่ง (เช่น ไม่มีเบอร์โทร)
            // }

            $rs[0] = array(
                "msg" => "success",
                "status" => true,
            );
        } else {
            $rs[0] = array(
                "msg" => "fails",
                "status" => false,
            );
        }
        echo json_encode($rs, JSON_UNESCAPED_UNICODE);
        exit();
    }
// --- ฟังก์ชันส่งไลน์กลุ่ม ---
  function sendTextToLineGroup($token, $text) {
        $url = "https://line.cityvariety.com/api_v1/sendTextToGroup";
        $param = array(
            "token" => $token,
            "text" => $text,
        );

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        
        // ปิดการตรวจสอบ SSL ทั้ง 2 ตัว เพื่อกัน Error 500 หรือ Connection Fail
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, 0);
        curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0); 
        
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
function testSendLineLatest()
    {
        $db = getDBO();

        // 1. ดึงข้อมูลองค์กรล่าสุด
        $sql = "SELECT * FROM org_information WHERE status = '1' ORDER BY id DESC LIMIT 1";
        $db->setQuery($sql);
        $org_data = $db->loadAssocList();

        if (!$org_data) {
            echo json_encode(["status" => false, "msg" => "ไม่พบข้อมูลองค์กร"]);
            exit();
        }

        // 2. ดึง ID ผู้สร้าง
        $org_id = $org_data[0]['id'];
        $uid = $org_data[0]['create_by']; // <--- จุดสำคัญ: ดูว่าเลขนี้คืออะไร
        $subject = $org_data[0]['subject'];
        
        // 3. ลองดึงข้อมูลผู้ใช้
        $sql_user = "SELECT fullname, phone FROM users WHERE id = '{$uid}'";
        $db->setQuery($sql_user);
        $user_data = $db->loadAssocList();

        $fullname = "-";
        $phone = "-";
        $debug_msg = "";

        if ($user_data) {
            $fullname = str_replace(',', ' ', $user_data[0]['fullname']);
            $phone = $user_data[0]['phone'];
            $debug_msg = "เจอ User ID: {$uid}";
        } else {
            // กรณีหาไม่เจอ ให้แจ้งเตือนใน Debug
            $fullname = "ไม่พบ User (ID: {$uid})";
            $phone = "ไม่พบเบอร์";
            $debug_msg = "หา User ID: {$uid} ไม่เจอในตาราง users";
        }

        // 4. สร้างข้อความส่งไลน์
        $mes = "ทดสอบ Debug" . PHP_EOL . 
               "องค์กร: " . $subject . " (OrgID: {$org_id})" . PHP_EOL . 
               "ผู้สร้าง ID: " . $uid . PHP_EOL . 
               "ชื่อ: " . $fullname . PHP_EOL . 
               "เบอร์: " . $phone;

        // 5. ส่งไลน์
        $line_token = "C7780f4fde1552d4e12b438ea6555552f";
        // $result = $this->sendTextToLineGroup($line_token, $mes);

        // 6. แสดงผล JSON ออกมาดูหน้าเว็บด้วย
        header('Content-Type: application/json');
        echo json_encode([
            "status" => true,
            "debug_info" => $debug_msg,
            "org_id" => $org_id,
            "create_by_uid" => $uid, // เช็คค่านี้ว่าตรงกับในตาราง users ไหม
            "user_query_result" => $user_data,
            "line_response" => $result
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }
    function createTableOrg($id)
    {
        $db0 = getDBO();
        $sql0 = "SELECT          id
                 FROM            org_information
                 WHERE           status = '1'
                 AND             parent_id = '0'
                 AND             id = {$id}
                 ORDER BY id DESC";
        $db0->setQuery($sql0);
        $data0 = $db0->loadAssocList();
        if (count($data0)) {
            $tb = 'attend_1_attachments';
            $tb2 = 'attend_' . $data0[0]['id'] . '_attachments';
            $sql_create = " CREATE TABLE IF NOT EXISTS $tb2 LIKE $tb ";

            $db1 = getDBO();
            $db1->setQuery($sql_create);
            $update = $db1->query();
            ///---
            $tb = 'attend_1_information';
            $tb2 = 'attend_' . $data0[0]['id'] . '_information';
            $sql_create = " CREATE TABLE IF NOT EXISTS $tb2 LIKE $tb ";

            $db1 = getDBO();
            $db1->setQuery($sql_create);
            $update = $db1->query();
            ///---
            $tb = 'attend_1_category';
            $tb2 = 'attend_' . $data0[0]['id'] . '_category';
            $sql_create = " CREATE TABLE IF NOT EXISTS $tb2 LIKE $tb ";

            $db1 = getDBO();
            $db1->setQuery($sql_create);
            $update = $db1->query();
            ///*----
            $tb = 'attend_1_summary';
            $tb2 = 'attend_' . $data0[0]['id'] . '_summary';
            $sql_create = " CREATE TABLE IF NOT EXISTS $tb2 LIKE $tb ";

            $db1 = getDBO();
            $db1->setQuery($sql_create);
            $update = $db1->query();
        }
    }

    function createTableOrgTmp()
    {
        $db0 = getDBO();
        $id = request('id');
        $sql0 = "
                    SELECT          id
                    FROM            org_information
                    WHERE           status = '1'
                    AND             id = {$id}
                    ORDER BY id DESC
                ";
        $db0->setQuery($sql0);
        $data0 = $db0->loadAssocList();
        if (count($data0)) {
            $tb = 'attend_1_attachments';
            $tb2 = 'attend_' . $data0[0]['id'] . '_attachments';
            $sql_create = " CREATE TABLE IF NOT EXISTS $tb2 LIKE $tb ";

            $db1 = getDBO();
            $db1->setQuery($sql_create);
            $update = $db1->query();
            ///---
            $tb = 'attend_1_information';
            $tb2 = 'attend_' . $data0[0]['id'] . '_information';
            $sql_create = " CREATE TABLE IF NOT EXISTS $tb2 LIKE $tb ";

            $db1 = getDBO();
            $db1->setQuery($sql_create);
            $update = $db1->query();
            ///---
            $tb = 'attend_1_category';
            $tb2 = 'attend_' . $data0[0]['id'] . '_category';
            $sql_create = " CREATE TABLE IF NOT EXISTS $tb2 LIKE $tb ";

            $db1 = getDBO();
            $db1->setQuery($sql_create);
            $update = $db1->query();
            ///*----
            $tb = 'attend_1_summary';
            $tb2 = 'attend_' . $data0[0]['id'] . '_summary';
            $sql_create = " CREATE TABLE IF NOT EXISTS $tb2 LIKE $tb ";

            $db1 = getDBO();
            $db1->setQuery($sql_create);
            $update = $db1->query();
        }
    }

    function getOrg()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        //-----
        $uid = $var['uid'] ? $var['uid'] : request('uid');
        $id = $var['id'] ? $var['id'] : request('id');


        //-----

        if ($uid) {
            $filter_uid = "AND a.uid = {$uid}";
        }
        if ($id) {
            $filter_id = "AND a.id = {$id}";
        }
        $db = getDBO();
        $sql = "    SELECT          a.* ,b.subject,
                                    b.create_date AS org_create,
                                    b.invite_code AS invite,
                                    b.display_image AS display_image,
                                    b.history_status,
                                    b.noti_status,
                                    b.ot_status,
                                    b.logout_status,
                                    b.time_status,
                                    b.leave_cancel_status
                    FROM            user_relationship AS a
                    INNER JOIN      org_information AS b
                    ON              b.status = '1'
                    AND             a.org_id = b.id
                    AND             a.type = 'admin'
                                    {$filter_uid}
                                    {$filter_id}
                    ORDER BY a.id DESC
                    ";
        $db->setQuery($sql);
        $data = $db->loadAssocList();

        if (count($data)) {
            $arr = array();
            for ($i = 0; $i < count($data); $i++) {
                $db1 = getDBO();
                $sql1 = "
                        SELECT          org_id
                        FROM            users
                        WHERE           id = {$uid}
                        AND             org_id = {$data[$i]['org_id']}
                    ";
                $db1->setQuery($sql1);
                $data1 = $db1->loadAssocList();
                $arr[$i] = array(
                    "id" => $data[$i]['id'],
                    "org_id" => $data[$i]['org_id'],
                    "subject" => $data[$i]['subject'],
                    "create_by" => $data[$i]['uid'],
                    "active_org" => count($data1) ? true : false,
                    "org_create" => $data[$i]['org_create'],
                    "invite" => $data[$i]['invite'],
                    "history" => $data[$i]['history_status'],
                    "noti" => $data[$i]['noti_status'],
                    "ot" => $data[$i]['ot_status'],
                    "logout" => $data[$i]['logout_status'],
                    "time_status" => $data[$i]['time_status'],
                    "leave_cancel_status" => $data[$i]['leave_cancel_status'],
                    "display_image" => $data[$i]['display_image'] != null ? $data[$i]['display_image'] : '',
                );
            }
            $rs[0] = array(
                "msg" => "success",
                "status" => true,
                "result" => $arr
            );
        } else {
            $rs[0] = array(
                "msg" => "fails",
                "status" => false,
                "result" => []
            );
        }


        echo json_encode($rs, JSON_UNESCAPED_UNICODE);
        exit();
    }
    function updateSwitchOrg()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        //-----
        $uid = $var['uid'] ? $var['uid'] : request('uid');
        $org_id = $var['org_id'] ? $var['org_id'] : request('org_id');


        $obj = new stdClass();
        $obj->id = $uid;
        $obj->org_id = $org_id;

        $db = getDBO();
        $insert = $db->updateObject('users', $obj, 'id');
        if ($insert) {
            $rs[0] = array(
                "msg" => "success",
                "status" => "true",
            );
        } else {
            $rs[0] = array(
                "msg" => "fails",
                "status" => "false",
            );
        }
        echo json_encode($rs, JSON_UNESCAPED_UNICODE);
        exit();
    }
    function updateSuspendOrg()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        //-----
        $uid = $var['uid'] ? $var['uid'] : request('uid');
        $org_id = $var['org_id'] ? $var['org_id'] : request('org_id');

        if ($uid != '' && $org_id != '') {
            $obj = new stdClass();
            $obj->id = $org_id;
            $obj->delete_by = $uid;
            $obj->delete_date = date('Y-m-d H:i:s');
            $obj->delete_ip = getIPAddress();
            $obj->status = '2';
            $db = getDBO();
            $insert = $db->updateObject('org_information', $obj, 'id');
            if ($insert) {
                $rs[0] = [
                    'msg' => 'success',
                    'status' => true,
                ];
            } else {
                $rs[0] = [
                    'msg' => 'fails',
                    'status' => false,
                ];
            }
        } else {
            $rs[0] = [
                'msg' => 'fails',
                'status' => false,
            ];
        }
        echo json_encode($rs, JSON_UNESCAPED_UNICODE);
        exit();
    }

    function insertCateLeave()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        $uid = $var['uid'] ? $var['uid'] : request('uid');
        $org_id = $var['org_id'] ? $var['org_id'] : request('org_id');
        $subject = $var['subject'] ? $var['subject'] : request('subject');
        $total = $var['total'] ? $var['total'] : request('total', '0');
        $seq = $var['seq'] ? $var['seq'] : request('seq', '0');
        $status = $var['status'] ? $var['status'] : request('status', '0');
        if ($org_id) {
            ///---
            $tb = 'leave_attachments';
            $tb2 = 'leave_' . $org_id . '_attachments';
            $sql_create = " CREATE TABLE IF NOT EXISTS $tb2 LIKE $tb ";
            $db1 = getDBO();
            $db1->setQuery($sql_create);
            $db1->query();

            ///---
            $tb = 'leave_information';
            $tb2 = 'leave_' . $org_id . '_information';
            $sql_create = " CREATE TABLE IF NOT EXISTS $tb2 LIKE $tb ";
            $db1 = getDBO();
            $db1->setQuery($sql_create);
            $db1->query();

            ///---
            $tb = 'leave_category';
            $tb2 = 'leave_' . $org_id . '_category';
            $sql_create = " CREATE TABLE IF NOT EXISTS $tb2 LIKE $tb ";
            $db1 = getDBO();
            $db1->setQuery($sql_create);
            $data_cate = $db1->query();
            if ($data_cate) {
                $table_cate = 'leave_' . $org_id . '_category';
                $db = getDBO();
                $sql = "SELECT          * 
                        FROM            {$table_cate}
                        WHERE           cate_name = 'หมวดหลัก'";
                $db->setQuery($sql);
                $cate = $db->loadAssocList();
                if (!$cate) {
                    $db->setQuery(" INSERT INTO `{$table_cate}` (`parent_id`, `seq`, `cate_name`, `total`, `create_by`, `create_ip`, `create_date`, `update_by`, `update_ip`, `update_date`, `delete_by`, `delete_ip`, `delete_date`, `status`) VALUES
                    (0, 0, 'หมวดหลัก', 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '1'),
                    (1, 0, 'ลาป่วย', 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '1'),
                    (1, 0, 'ลากิจ', 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '1');
                    COMMIT;");
                    $db->query();
                }
            }

            $obj = new stdClass();
            $obj->parent_id = "1";
            $obj->cate_name = $subject;
            $obj->total = $total;
            $obj->seq = $seq;
            $obj->status = $status;
            $obj->create_by = $uid;
            $obj->create_date = date('Y-m-d H:i:s');
            $obj->create_ip = getIPAddress();
            $insert = $db->insertObject($table_cate, $obj);
            if ($insert) {
                $rs = [
                    'msg' => 'success',
                    'status' => true,
                ];
            } else {
                $rs = [
                    'msg' => 'fails',
                    'status' => false,
                ];
            }
        } else {
            $rs = [
                'msg' => 'fails',
                'status' => false,
            ];
        }

        echo json_encode($rs, JSON_UNESCAPED_UNICODE);
        exit();
    }

    function updateCateLeave()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        $uid = $var['uid'] ? $var['uid'] : request('uid');
        $org_id = $var['org_id'] ? $var['org_id'] : request('org_id');
        $id = $var['id'] ? $var['id'] : request('id');
        $subject = $var['subject'] ? $var['subject'] : request('subject');
        $total = $var['total'] ? $var['total'] : request('total', '0');
        $seq = $var['seq'] ? $var['seq'] : request('seq', '0');
        $status = $var['status'] ? $var['status'] : request('status', '0');
        if ($org_id) {
            $db = getDBO();
            $obj = new stdClass();
            $obj->id = $id;
            $obj->cate_name = $subject;
            $obj->total = $total;
            $obj->seq = $seq;
            $obj->status = $status;
            $obj->update_by = $uid;
            $obj->update_date = date('Y-m-d H:i:s');
            $obj->update_ip = getIPAddress();
            $table_cate = 'leave_' . $org_id . '_category';
            $insert = $db->updateObject($table_cate, $obj, 'id');
            if ($insert) {
                $rs = [
                    'msg' => 'success',
                    'status' => true,
                ];
            } else {
                $rs = [
                    'msg' => 'fails',
                    'status' => false,
                ];
            }
        } else {
            $rs = [
                'msg' => 'fails',
                'status' => false,
            ];
        }

        echo json_encode($rs, JSON_UNESCAPED_UNICODE);
        exit();
    }

    function insertInfoLeave()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        //-----
        $uid = $var['uid'] ? $var['uid'] : request('uid');
        $org_id = $var['org_id'] ? $var['org_id'] : request('org_id');
        $cause = $var['cause'] ? $var['cause'] : request('cause');
        $cid = $var['cid'] ? $var['cid'] : request('cid');
        $firstdate = $var['firstdate'] ? $var['firstdate'] : request('firstdate');
        $lastdate = $var['lastdate'] ? $var['lastdate'] : request('lastdate');
        $firstTime = $var['firstTime'] ? $var['firstTime'] : request('firstTime');
        $numDate = $var['numDate'] ? $var['numDate'] : request('numDate');
        $lastTime = $var['lastTime'] ? $var['lastTime'] : request('lastTime');
        $phoneNum = $var['phoneNum'] ? $var['phoneNum'] : request('phoneNum');
        $selectFulltime = $var['selectFulltime'] ? $var['selectFulltime'] : request('selectFulltime');
        $uploadKey = md5(time() . rand(0, 100));
        if ($org_id) {

            ///---
            $tb = 'leave_attachments';
            $tb2 = 'leave_' . $org_id . '_attachments';
            $sql_create = " CREATE TABLE IF NOT EXISTS $tb2 LIKE $tb ";
            $db1 = getDBO();
            $db1->setQuery($sql_create);
            $db1->query();

            ///---
            $tb = 'leave_information';
            $tb2 = 'leave_' . $org_id . '_information';
            $sql_create = " CREATE TABLE IF NOT EXISTS $tb2 LIKE $tb ";
            $db1 = getDBO();
            $db1->setQuery($sql_create);
            $db1->query();

            ///---
            $tb = 'leave_category';
            $tb2 = 'leave_' . $org_id . '_category';
            $sql_create = " CREATE TABLE IF NOT EXISTS $tb2 LIKE $tb ";
            $db1 = getDBO();
            $db1->setQuery($sql_create);
            $db1->query();

            //check ลาซ้ำ
            // $table = 'leave_' . $org_id . '_information';
            // $sql = "SELECT          *
            //         FROM            {$table}
            //         WHERE           status = '1'
            //         AND             cid = '{$cid}'
            //         AND             (FirstDate BETWEEN '{$firstdate}' AND '{$lastdate}' OR LastDate BETWEEN '{$firstdate}' AND '{$lastdate}')
            //         AND             create_by = '{$uid}'
            //         ";
            // $db1->setQuery($sql);
            // $data = $db1->loadAssocList();
            // if ($data) {
            //     $rs = [
            //         'msg' => 'fails',
            //         'status' => false,
            //     ];
            //     response_json(json_encode($rs));
            //     exit();
            // }

            $obj = new stdClass();
            $obj->uploadKey = $uploadKey;
            $obj->cid = $cid;
            $obj->subject = $cause;
            $obj->phoneNum = $phoneNum;
            $obj->FirstDate = $firstdate;
            $obj->LastDate = $lastdate;
            $obj->firstTime = $firstTime;
            $obj->lastTime = $lastTime;
            $obj->numDate = $numDate;
            $obj->create_by = $uid;
            $obj->create_date = date('Y-m-d H:i:s');
            $obj->create_ip = getIPAddress();
            $obj->selectFulltime = $selectFulltime;
            $table = 'leave_' . $org_id . '_information';
            $db = getDBO();
            $insert = $db->insertObject($table, $obj);
            $topic_id = $db->insertid();
            if ($insert) {
                $table_cate = 'leave_' . $org_id . '_category';
                $sql = "SELECT          * 
                        FROM            {$table_cate}
                        WHERE           cate_name = 'หมวดหลัก'";
                $db->setQuery($sql);
                $cate = $db->loadAssocList();
                if (!$cate) {
                    $db = getDBO();
                    $db->setQuery(" INSERT INTO `{$table_cate}` (`parent_id`, `seq`, `cate_name`, `total`, `create_by`, `create_ip`, `create_date`, `update_by`, `update_ip`, `update_date`, `delete_by`, `delete_ip`, `delete_date`, `status`) VALUES
                                    (0, 0, 'หมวดหลัก', 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '1'),
                                    (1, 0, 'ลาป่วย', 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '1'),
                                    (1, 0, 'ลากิจ', 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '1');
                                    COMMIT;");
                    $db->query();
                }


                $rs = [
                    'msg' => 'success',
                    'uploadKey' => $uploadKey,
                    'status' => true,
                ];

                response_json(json_encode($rs));

                //uploadFile
                if ($_FILES) {
                    $tableFile = 'leave_' . $org_id;
                    $this->uploadFileImagesFlutter($uploadKey, $_FILES, $tableFile);
                }



                //insert noti
                $this->insertNotiLeave($org_id, $topic_id, "1", $uid, $uid);
            } else {
                $rs = [
                    'msg' => 'fails',
                    'status' => false,
                ];
                response_json(json_encode($rs));
            }
        } else {
            $rs = [
                'msg' => 'fails',
                'status' => false,
            ];
            response_json(json_encode($rs));
        }
        // echo json_encode($rs, JSON_UNESCAPED_UNICODE);
        exit();
    }

    function getListNotiLeave()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        //-----
        $org_id = $var['org_id'] ? $var['org_id'] : request('org_id');
        $uid = $var['uid'] ? $var['uid'] : request('uid');
        $tab = $var['tab'] ? $var['tab'] : request('tab');
        $table = 'leave_' . $org_id . '_information';
        $db = getDBO();
        $items = array();
        $sql_search = "";
        $sql_group = "";
        if ($org_id) {
            $sql = "SELECT          * 
                    FROM            user_relationship
                    WHERE           org_id = '{$org_id}'
                    AND             uid = '{$uid}'
                    ";
            $db->setQuery($sql);
            $types = $db->loadAssocList();
            //check leave approve
            $users = $this->getUsers($uid);
            if ($types[0]['type'] == "admin") {
                $sql_search = "AND (uid = '{$uid}' OR status_leave IN ('1','4'))";
            } else if ($users['leave_approve'] == "1") {
                $sql_search = "AND (uid = '{$uid}' OR status_leave IN ('1','4'))";
            } else {
                $sql_search = "AND uid = '{$uid}' AND userclass != 'admin'";
            }

            if ($tab == "2") {
                $sql = "SELECT          * 
                        FROM            {$table}
                        WHERE           status = '1'
                        AND             status_leave = '1'
                        AND             YEAR(create_date) = YEAR(CURRENT_DATE())
                        AND             create_by != '{$uid}'
                        ORDER BY status_leave ASC, FirstDate ASC";
                $db->setQuery($sql);
                $data = $db->loadAssocList();
                $arr_data = array();
                if ($data) {
                    $len = count($data);
                    if ($len) {
                        for ($i = 0; $i < $len; $i++) {
                            $sql = "SELECT          * 
                                    FROM            users
                                    WHERE           id = '{$data[$i]['create_by']}'
                                    ";
                            $db->setQuery($sql);
                            $dataUser = $db->loadAssocList();
                            if ($dataUser[0]['leave_aid'] == $uid) {
                                $arr_data[] = $data[$i];
                            }
                        }
                    }
                    if ($_GET['debug']) {
                        pre($arr_data);
                        exit();
                    }
                    if ($arr_data) {
                        $index = 0;
                        for ($i = 0; $i < count($arr_data); $i++) {
                            shortThaiDateTime($arr_data[$i]['create_date']);
                            $type_leave = $this->checkCateLeave($arr_data[$i]['cid'], $org_id);
                            $subject = "";
                            if ($uid == $arr_data[$i]['create_by']) {
                                if ($arr_data[$i]['status_leave'] == "1") {
                                    $subject = "คุณได้ส่งคำขอ" . $type_leave;
                                } else if ($arr_data[$i]['status_leave'] == "4") {
                                    $subject = "คุณได้ยกเลิกคำขอ" . $type_leave;
                                } else {
                                    $subject = $arr_data[$i]['subject'];
                                }
                            } else {
                                $subject = $arr_data[$i]['subject'];
                            }
                            $userclass = getMyOrgSubType($arr_data[$i]['create_by'], $org_id);
                            $items[$index] = array(
                                'id' => $arr_data[$i]['id'],
                                'topic_id' => $arr_data[$i]['id'],
                                'org_id' => $org_id,
                                'userclass' => $userclass,
                                'subject' => $arr_data[$i]['subject'],
                                'status_noti' =>  $arr_data[$i]['status'],
                                'status_leave' => $arr_data[$i]['status_leave'],
                                'create_date' => substr($arr_data[$i]['create_date'], 0, -3) . ' น.',
                            );
                            $index++;
                        }
                        $item[0] = array(
                            'msg' => 'success',
                            'status' => true,
                            'result' => $items,
                        );
                    } else {
                        $item[0] = array(
                            'msg' => 'failed',
                            'status' => false,
                            'result' => $items,
                        );
                    }
                } else {
                    $item[0] = array(
                        'msg' => 'failed',
                        'status' => false,
                        'result' => $items,
                    );
                }
            } else {
                $sql = "SELECT          * 
                FROM            leave_notification_information
                WHERE           org_id = '$org_id'
                {$sql_search}
                AND             status != '2'
                {$sql_group}
                ORDER BY create_date DESC";
                $db->setQuery($sql);
                $data = $db->loadAssocList();
                if ($data) {
                    $index = 0;
                    for ($i = 0; $i < count($data); $i++) {
                        $sql = "SELECT          * 
                                FROM            users
                                WHERE           id = '{$data[$i]['create_by']}'";
                        $db->setQuery($sql);
                        $dataUser = $db->loadAssocList();
                        if ($dataUser[0]['leave_aid'] == $uid || $uid == $data[$i]['uid']) {
                            shortThaiDateTime($data[$i]['create_date']);
                            $type_leave = $this->checkCateLeave($data[$i]['topic_id'], $data[$i]['org_id']);
                            $subject = "";
                            if ($uid == $data[$i]['uid']) {
                                if ($data[$i]['status_leave'] == "1") {
                                    $subject = "คุณได้ส่งคำขอ" . $type_leave;
                                } else if ($data[$i]['status_leave'] == "4") {
                                    $subject = "คุณได้ยกเลิกคำขอ" . $type_leave;
                                } else {
                                    $subject = $data[$i]['subject'];
                                }
                            } else {
                                $subject = $data[$i]['subject'];
                            }
                            $items[$index] = array(
                                'id' => $data[$i]['id'],
                                'topic_id' => $data[$i]['topic_id'],
                                'org_id' => $data[$i]['org_id'],
                                'userclass' => $data[$i]['userclass'],
                                'subject' => $subject,
                                'status_noti' =>  $data[$i]['status'],
                                'status_leave' => $data[$i]['status_leave'],
                                'create_date' => substr($data[$i]['create_date'], 0, -3) . ' น.',
                            );
                            $index++;
                        }
                    }
                    $item[0] = array(
                        'msg' => 'success',
                        'status' => true,
                        // 'debug' => $debug,
                        'result' => $items,
                    );
                } else {
                    $item[0] = array(
                        'msg' => 'failed',
                        'status' => false,
                        'result' => $items,
                    );
                }
            }
            $debug = $sql;
        } else {
            $item[0] = array(
                'msg' => 'failed',
                'status' => false,
                'result' => $items,
            );
        }

        echo json_encode($item, JSON_UNESCAPED_UNICODE);
        exit();
    }

    public function sortArrayNotiListDate($arr_data)
    {
        usort($arr_data, function ($a, $b) {
            return strtotime($b['create_date']) - strtotime($a['create_date']);
        });
    }


    private function checkCateLeave($id, $org_id)
    {
        $db = getDBO();
        $table_info = 'leave_' . $org_id . '_information';
        $sql = "SELECT          cid
                FROM            {$table_info}
                WHERE           id = '{$id}'";
        $db->setQuery($sql);
        $cid = $db->loadAssocList();
        $cid = $cid[0]['cid'];

        $table_cate = 'leave_' . $org_id . '_category';
        $sql = "SELECT          * 
                FROM            {$table_cate}
                WHERE           id = '{$cid}'";
        $db->setQuery($sql);
        $cate = $db->loadAssocList();
        return $cate[0]['cate_name'];
    }

    function insertNotiLeave($org_id, $topic_id, $status_leave, $uid, $create_by)
    {
        $db = getDBO();
        $uploadKey = md5(time() . rand(0, 100));
        if ($org_id && $topic_id) {
            $subject = "";
            $userclass = "member";
            $users = $this->getUsers($uid);
            $fullname = str_replace(',', ' ', $users['fullname']);
            $type_leave = $this->checkCateLeave($topic_id, $org_id);
            if ($status_leave == "1") {
                $subject = $fullname . " ได้ส่งคำขอ" . $type_leave;
                $userclass = "admin";
            } else if ($status_leave == "2") {
                $subject = "คำขอ" . $type_leave . "ของคุณ ได้อนุมัติเรียบร้อยแล้ว";
            } else if ($status_leave == "3") {
                $subject = "คำขอ" . $type_leave . "ของคุณ ไม่อนุมัติให้ลาได้ในครั้งนี้";
            } else if ($status_leave == "4") {
                $subject = $fullname . " ได้ยกเลิกคำขอ" . $type_leave;
                $userclass = "admin";
            }

            $obj = new stdClass();
            $obj->uploadKey = $uploadKey;
            $obj->org_id = $org_id;
            $obj->topic_id = $topic_id;
            $obj->subject = $subject;
            $obj->userclass = $userclass;
            $obj->menu = "leave";
            $obj->status = "0";
            $obj->status_leave = $status_leave;
            $obj->uid = $create_by;
            $obj->create_by = $uid;
            $obj->create_date = date('Y-m-d H:i:s');
            $obj->create_ip = getIPAddress();
            $insert = $db->insertObject("leave_notification_information", $obj);
            if ($insert) {
                if ($status_leave == "1" || $status_leave == "4") {
                    //ส่งหาผู้อนุมัติ
                    $usr = $this->getUsers($create_by);
                    $leave_aid = $usr['leave_aid'];
                    if ($leave_aid) {
                        $this->setDataNotification($leave_aid, $subject);
                    }
                } else {
                    //ส่งหาผู้ขอ
                    $this->setDataNotification($create_by, $subject);
                }
            }
        }
    }

    private function uploadFileImagesFlutter($uploadKey = "", $files, $cmd = "", $uid = "", $type = "")
    {

        $arrExt = array("jpg", "jepg", "png", "gif");

        if (!count($files)) {
            return 0;
        }
        if ($cmd) {
            $table['file'] = $cmd . '_attachments';
            $file_path = 'files/com_' . $cmd . '/';
        }
        $db = getDBO();

        $arrFiles = array();
        for ($i = 0; $i < count($files['file']['name']); $i++) {
            $arrFiles[] = array(
                "name" => $files['file']['name'][$i],
                "type" => $files['file']['type'][$i],
                "tmp_name" => $files['file']['tmp_name'][$i],
                "error" => $files['file']['error'][$i],
                "size" => $files['file']['size'][$i],
            );
        }

        $arrLen = count($arrFiles);
        for ($j = 0; $j < $arrLen; $j++) {
            $upload_file = upload_file($file_path, $arrFiles[$j]);
            if ($upload_file) {
                if ($cmd != "users") {
                    $obj = new stdClass();
                    $obj->uploadKey = $uploadKey;
                    $obj->filename = array_pop(explode('/', $upload_file['path']));
                    $obj->filepath = $upload_file['path'];
                    $obj->filesizes = $upload_file['size'];
                    $obj->extension = $upload_file['extension'];
                    if ($type) {
                        $obj->attact_type = $type;
                    } else {
                        if (in_array($upload_file['extension'], $arrExt)) {
                            $obj->attact_type = 'i';
                        } else {
                            $obj->attact_type = 'f';
                        }
                    }
                    $obj->status = '1';
                    $obj->create_ip = getIPAddress();
                    $obj->create_date = date("Y-m-d H:i:s");
                    $db->insertObject($table['file'], $obj);
                    $sql[] = $db->getQuery();
                }
            }
        }
    }

    function getCateLeave()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        //-----
        $org_id = $var['org_id'] ? $var['org_id'] : request('org_id');
        $id = $var['id'] ? $var['id'] : request('id');
        $table = "leave_" . $org_id . "_category";
        $db = getDBO();
        $sql = "SELECT          * 
                FROM            {$table}
                WHERE           parent_id = '1'
                AND             status = '1'
                AND             id > '3'
                ORDER BY seq ASC
				";
        $db->setQuery($sql);
        $data = $db->loadAssocList();
        $items = array();
        $items[0] = array(
            'id' => "",
            'subject' => "- เลือก -",
        );
        $index = 1;
        for ($i = 0; $i < count($data); $i++) {
            $items[$index] = array(
                'id' => $data[$i]['id'],
                'subject' => $data[$i]['cate_name'],
            );
            $index++;
        }

        $item[0] = array(
            'msg' => 'success',
            'status' => true,
            'result' => $items,
        );
        echo json_encode($item, JSON_UNESCAPED_UNICODE);
        exit();
    }

    function getCateLeaveOrg()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        //-----
        $org_id = $var['org_id'] ? $var['org_id'] : request('org_id');
        $uid = $var['uid'] ? $var['uid'] : request('uid');
        $table = 'leave_' . $org_id . '_category';
        $items = array();
        $index = 0;
        $db = getDBO();

        if ($org_id) {
            $sql = "SELECT          * 
                    FROM            {$table}
                    WHERE           parent_id = '1'
                    AND             status != '2'
                    ORDER BY seq ASC";
            $db->setQuery($sql);
            $data = $db->loadAssocList();
            for ($i = 0; $i < count($data); $i++) {
                if ($data[$i]['id'] == "2" || $data[$i]['id'] == "3") {
                    $total = $this->getTotalLeave($org_id, $uid, ($data[$i]['id']));
                } else {
                    $total = $this->getTotalLeave($org_id, $uid, $data[$i]['id']);
                }
                $items[$index] = array(
                    'id' => $data[$i]['id'],
                    'subject' => $data[$i]['cate_name'],
                    'total' => "{$total}",
                    'totalAll' => $data[$i]['total'],
                );
                $index++;
            }
            $item[0] = array(
                'msg' => 'success',
                'status' => true,
                'result' => $items,
            );
        } else {
            $item[0] = array(
                'msg' => 'failed',
                'status' => false,
                'result' => $items,
            );
        }

        echo json_encode($item, JSON_UNESCAPED_UNICODE);
        exit();
    }

    function getCateLeaveDetail()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        //-----
        $org_id = $var['org_id'] ? $var['org_id'] : request('org_id');
        $uid = $var['uid'] ? $var['uid'] : request('uid');
        $id = $var['id'] ? $var['id'] : request('id');
        $table = 'leave_' . $org_id . '_category';
        $items = array();
        $index = 0;
        $db = getDBO();

        if ($org_id) {
            $sql = "SELECT          * 
                    FROM            {$table}
                    WHERE           parent_id = '1'
                    AND             status != '2'
                    AND             id = '{$id}'
                    ORDER BY seq ASC";
            $db->setQuery($sql);
            $data = $db->loadAssocList();
            for ($i = 0; $i < count($data); $i++) {
                if ($data[$i]['id'] == "2" || $data[$i]['id'] == "3") {
                    $total = $this->getTotalLeave($org_id, $uid, ($data[$i]['id']));
                } else {
                    $total = $this->getTotalLeave($org_id, $uid, $data[$i]['id']);
                }
                $items[$index] = array(
                    'id' => $data[$i]['id'],
                    'subject' => $data[$i]['cate_name'],
                    'total' => $data[$i]['total'],
                    'seq' => $data[$i]['seq'],
                    'status_cate' => $data[$i]['status'],
                );
                $index++;
            }
            $item[0] = array(
                'msg' => 'success',
                'status' => true,
                'result' => $items,
            );
        } else {
            $item[0] = array(
                'msg' => 'failed',
                'status' => false,
                'result' => $items,
            );
        }

        echo json_encode($item, JSON_UNESCAPED_UNICODE);
        exit();
    }

    function getDetailLeave()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        //-----
        $org_id = $var['org_id'] ? $var['org_id'] : request('org_id');
        $uid = $var['uid'] ? $var['uid'] : request('uid');
        $id = $var['id'] ? $var['id'] : request('id');
        $table = 'leave_' . $org_id . '_information';
        $tableFile = 'leave_' . $org_id . '_attachments';
        $db = getDBO();
        $items = array();
        if ($org_id) {
            $sql = "SELECT          * 
                    FROM            {$table}
                    WHERE           status = '1'
                    AND             id = '{$id}'";
            $db->setQuery($sql);
            $data = $db->loadAssocList();
            if ($data) {

                //update read noti
                $db->setQuery("UPDATE leave_notification_information SET `status`= '1' WHERE topic_id = '{$id}' AND org_id = '{$org_id}' ");
                $db->query();
                $update_debug = $db->getQuery();

                shortThaiDate($data[0]['FirstDate']);
                shortThaiDate($data[0]['LastDate']);
                shortThaiDate($data[0]['create_date']);
                $users = $this->getUsers($data[0]['create_by']);
                $totalLeave = $this->getTotalLeaveApproveAll($org_id, $data[0]['create_by'], $data[0]['cate_id']);
                $dateLeave = "";
                $dateEnd = "";
                $status_leave = "";
                $cate_name = "";
                $dateType = "";
                $indexFiles = 0;
                if ($data[0]['selectFulltime'] == "1") {
                    $dateLeave = $data[0]['FirstDate'];
                    $dateEnd = $data[0]['LastDate'];
                    $dateType = " วัน";
                } else {
                    $dateLeave = $data[0]['FirstDate'] . ' ' . substr($data[0]['firstTime'], 0, 5) . '-' . substr($data[0]['lastTime'], 0, 5) . ' น.';
                    $dateType = " ชม.";
                }
                if ($data[0]['status_leave'] == "1") {
                    $status_leave = "รออนุมัติ";
                } else if ($data[0]['status_leave'] == "2") {
                    $status_leave = "อนุมัติแล้ว";
                } else if ($data[0]['status_leave'] == "3") {
                    $status_leave = "ไม่อนุมัติ";
                } else {
                    $status_leave = "ยกเลิกการลา";
                }
                if ($data[0]['cid'] == "2") {
                    $cate_name = "ลาป่วย";
                } else if ($data[0]['cid'] == "3") {
                    $cate_name = "ลากิจ";
                } else {
                    $cate_name = "อื่นๆ";
                }
                $sql = "SELECT          * 
                        FROM            {$tableFile}
                        WHERE           uploadKey = '{$data[0]['uploadKey']}'
                        AND             status = '1'
                        ORDER BY id DESC
                        LIMIT  2
                        ";
                $db->setQuery($sql);
                $dataFile = $db->loadAssocList();
                if ($dataFile) {
                    for ($j = 0; $j < count($dataFile); $j++) {
                        $itemsFiles[$indexFiles] = array(
                            'id' => $dataFile[$j]['id'],
                            'filename' => $dataFile[$j]['filename'],
                            'path' => base_url() . $dataFile[$j]['filepath'],
                            'extension' => $dataFile[$j]['extension'],
                        );
                        $indexFiles++;
                    }
                }
                $item[0]['cateName'] = $cate_name;
                $item[0]['fullname'] = str_replace(',', ' ', $users['fullname']);
                $item[0]['subject'] = $data[0]['subject'];
                $item[0]['position'] = $users['position'] ? $users['position'] : '-';
                $item[0]['leaveDate'] = $dateLeave;
                $item[0]['leaveEnd'] = $dateEnd;
                $item[0]['leaveNum'] = $data[0]['numDate'] . $dateType;
                $item[0]['createDate'] = $data[0]['create_date'];
                $item[0]['recommend'] = $data[0]['recommend'] ? $data[0]['recommend'] : "0";
                $item[0]['totalLeave'] = $totalLeave != 0 ? $totalLeave : "";
                $item[0]['cid'] = $data[0]['cid'];
                $item[0]['cate_name'] = $this->checkCateLeave($data[0]['id'], $org_id);
                $item[0]['leaveStatus'] = $data[0]['status_leave'];
                $item[0]['create_by'] = $data[0]['create_by'];
                $item[0]['phone'] = $data[0]['phoneNum'];
                // $item[0]['create_by'] = $data[0]['create_by'];
                $item[0]['leaveStatusText'] = $status_leave;
                $item[0]['files'] = $itemsFiles;
                $item[0]['msg'] = "success";
                $item[0]['status'] = true;
                $item[0]['update_debug'] = '';
                // $item[0]['update_debug'] = $update_debug;
            } else {
                $item[0] = array(
                    'msg' => 'failed',
                    'status' => false,
                    'result' => $items,
                );
            }
        } else {
            $item[0] = array(
                'msg' => 'failed',
                'status' => false,
                'result' => $items,
            );
        }
        echo json_encode($item, JSON_UNESCAPED_UNICODE);
        exit();
    }

    function updateStatusLeave()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        //-----
        $org_id = $var['org_id'] ? $var['org_id'] : request('org_id');
        $uid = $var['uid'] ? $var['uid'] : request('uid');
        $id = $var['id'] ? $var['id'] : request('id');
        // $create_by = $var['create_by'] ? $var['create_by'] : request('create_by');
        $status_leave = $var['status_leave'] ? $var['status_leave'] : request('status_leave');
        $table = 'leave_' . $org_id . '_information';
        $table_info = 'org_information';
        $leave_cancel_status = "0";
        $db = getDBO();
        //check cancel leave approve
        $sql = "SELECT          * 
                FROM            {$table_info}
                WHERE           id = '{$org_id}'";
        $db->setQuery($sql);
        $rs = $db->loadAssocList();
        if ($status_leave == "4") {
            $leave_cancel_status = $rs[0]['leave_cancel_status'] ? $rs[0]['leave_cancel_status'] : "0";
        }
        $items = array();
        if ($org_id) {
            $obj = new stdClass();
            $obj->id = $id;
            $obj->status_leave = $status_leave;
            $obj->update_by = $uid;
            if ($leave_cancel_status == "1") {
                $obj->recommend = "1";
            }
            $obj->update_date = date('Y-m-d H:i:s');
            $obj->update_ip = getIPAddress();
            $insert = $db->updateObject($table, $obj, 'id');
            if ($insert) {

                $sql = "SELECT          * 
                        FROM            {$table}
                        WHERE           id = '{$id}'";
                $db->setQuery($sql);
                $data = $db->loadAssocList();

                $item[0] = array(
                    "msg" => "success",
                    "status" => true,
                );

                response_json(json_encode($item));

                //insert noti
                $this->insertNotiLeave($org_id, $id, $status_leave, $uid, $data[0]['create_by']);

                if ($status_leave == "2") {
                    $_REQUEST['id'] = $id;
                    $_REQUEST['org_id'] = $org_id;
                    $_REQUEST['uid'] = $uid;
                    $_REQUEST['create_by'] = $data[0]['create_by'];
                    $this->setLineNotify();
                }
            } else {
                $item[0] = array(
                    "msg" => "failed",
                    "status" => false,
                );
                response_json(json_encode($item));
            }
        } else {
            $item[0] = array(
                'msg' => 'failed',
                'status' => false,
                'result' => $items,
            );
            response_json(json_encode($item));
        }
        // echo json_encode($item, JSON_UNESCAPED_UNICODE);
        exit();
    }

    function updateCancelStatusLeave()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        //-----
        $org_id = $var['org_id'] ? $var['org_id'] : request('org_id');
        $uid = $var['uid'] ? $var['uid'] : request('uid');
        $id = $var['id'] ? $var['id'] : request('id');
        $status_leave = $var['status_leave'] ? $var['status_leave'] : request('status_leave');
        $table = 'leave_' . $org_id . '_information';
        $db = getDBO();
        //check cancel leave approve
        $items = array();
        if ($org_id) {
            $obj = new stdClass();
            $obj->id = $id;
            if ($status_leave == "2") {
                $obj->status_leave = "2";
            }
            $obj->update_by = $uid;
            $obj->recommend = $status_leave == "1" ? "0" : "1";
            $obj->update_date = date('Y-m-d H:i:s');
            $obj->update_ip = getIPAddress();
            $insert = $db->updateObject($table, $obj, 'id');
            if ($insert) {

                $item[0] = array(
                    "msg" => "success",
                    "status" => true,
                );

                response_json(json_encode($item));
            } else {
                $item[0] = array(
                    "msg" => "failed",
                    "status" => false,
                );
                response_json(json_encode($item));
            }
        } else {
            $item[0] = array(
                'msg' => 'failed',
                'status' => false,
                'result' => $items,
            );
            response_json(json_encode($item));
        }
        // echo json_encode($item, JSON_UNESCAPED_UNICODE);
        exit();
    }

    function getUsers($id)
    {
        $db = getDBO();
        $db->setQuery(" SELECT * FROM users WHERE id='{$id}' ");
        $rs = $db->loadAssocList();
        return @$rs[0];
    }

    function getListLeave()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        //-----
        $org_id = $var['org_id'] ? $var['org_id'] : request('org_id');
        $uid = $var['uid'] ? $var['uid'] : request('uid');
        $statusLeave = $var['status_leave'] ? $var['status_leave'] : request('status_leave');
        $cid = $var['cid'] ? $var['cid'] : request('cid');
        $month_start = $var['month_start'] ? $var['month_start'] : request('month_start');
        $year_start = $var['year_start'] ? $var['year_start'] : request('year_start');
        $month_end = $var['month_end'] ? $var['month_end'] : request('month_end');
        $year_end = $var['year_end'] ? $var['year_end'] : request('year_end');

        $sql_search = "";
        if ($month_start && $year_start) {
            $year_start = $year_start - 543;
            $month_start = $this->fineMonth($month_start);
            $date_start = $year_start . '-' . $month_start . '-01';
            $sql_search .= " AND DATE(create_date) >= '{$date_start}' ";
        } else {
            $sql_search = "AND  YEAR(create_date) = YEAR(CURRENT_DATE())";
        }

        if ($month_end && $year_end) {
            $year_end = $year_end - 543;
            $month_end = $this->fineMonth($month_end);
            $date_end = $year_end . '-' . $month_end . '-01';
            $date_end = date('Y-m-t', strtotime($date_end));
            $sql_search .= " AND DATE(create_date) <= '{$date_end}' ";
        } else {
            $sql_search = "AND  YEAR(create_date) = YEAR(CURRENT_DATE())";
        }

        $table = 'leave_' . $org_id . '_information';
        $tableFile = 'leave_' . $org_id . '_attachments';
        $search_sql = "";
        $search_sql_cid = "";
        if ($statusLeave) {
            $search_sql = "AND  status_leave IN ({$statusLeave})";
        }
        if ($cid) {
            $cid_arr = explode(',', $cid);
            if (count($cid_arr) != 3) {
                if (in_array("3", $cid_arr)) {
                    if (count($cid_arr) == 1) {
                        $search_sql_cid = "AND  cid NOT IN (1,2)";
                    } else {
                        $result = $cid_arr[0] - $cid_arr[1];
                        $result = abs($result);
                        $search_sql_cid = "AND cid NOT IN ('{$result}')";
                    }
                } else {
                    $cid_data = implode("','", $cid_arr);
                    $search_sql_cid = "AND  cid IN ('{$cid_data}')";
                }
            }
        }
        $db = getDBO();
        $items = array();
        $itemsFiles = array();
        if ($org_id) {
            $sql = "SELECT          * 
                    FROM            {$table}
                    WHERE           create_by = '$uid'
                    AND             status = '1'
                    {$sql_search}
                    {$search_sql}
                    {$search_sql_cid}
                    ORDER BY status_leave ASC, FirstDate ASC";
            $db->setQuery($sql);
            $data = $db->loadAssocList();
            $debug = $sql;
            if ($data) {
                $index = 0;
                $indexFiles = 0;
                $dateLeave = "";
                $status_leave = "";
                $cate_name = "";
                for ($i = 0; $i < count($data); $i++) {
                    shortThaiDate($data[$i]['FirstDate']);
                    shortThaiDate($data[$i]['LastDate']);
                    shortThaiDate($data[$i]['create_date']);
                    if ($data[$i]['selectFulltime'] == "1") {
                        $dateLeave = $data[$i]['FirstDate'] . ' - ' . $data[$i]['LastDate'];
                    } else {
                        $dateLeave = $data[$i]['FirstDate'] . ' ' . substr($data[$i]['firstTime'], 0, 5) . '-' . substr($data[$i]['lastTime'], 0, 5) . ' น.';
                    }
                    if ($data[$i]['status_leave'] == "1") {
                        $status_leave = "รออนุมัติ";
                    } else if ($data[$i]['status_leave'] == "2") {
                        $status_leave = "อนุมัติแล้ว";
                    } else if ($data[$i]['status_leave'] == "3") {
                        $status_leave = "ไม่อนุมัติ";
                    } else {
                        $status_leave = "ยกเลิกการลา";
                    }
                    if ($data[$i]['cid'] == "2") {
                        $cate_name = "ลาป่วย";
                    } else if ($data[$i]['cid'] == "3") {
                        $cate_name = "ลากิจ";
                    } else {
                        $cate_name = "อื่นๆ";
                    }
                    //check file;
                    $sql = "SELECT          * 
                            FROM            {$tableFile}
                            WHERE           uploadKey = '{$data[$i]['uploadKey']}'
                            AND             status = '1'";
                    $db->setQuery($sql);
                    $dataFile = $db->loadAssocList();
                    if ($dataFile) {
                        for ($j = 0; $j < count($dataFile); $j++) {
                            $itemsFiles[$indexFiles] = array(
                                'id' => $dataFile[$j]['id'],
                                'filename' => $dataFile[$j]['filename'],
                                'path' => base_url() . $dataFile[$j]['filepath'],
                                'extension' => $dataFile[$j]['extension'],
                            );
                            $indexFiles++;
                        }
                    }

                    $items[$index] = array(
                        'id' => $data[$i]['id'],
                        'cid' => $data[$i]['cid'],
                        'types' => $data[$i]['selectFulltime'],
                        'create_date' => $data[$i]['create_date'],
                        'dateLeave' => $dateLeave,
                        'status_leave' => $data[$i]['status_leave'],
                        'status_leave_text' => $status_leave,
                        'cate_name' => $cate_name,
                        // 'files' =>  $itemsFiles,
                    );

                    $index++;
                }

                $item[0] = array(
                    'sick' => $this->getTotalLeave($org_id, $uid, "2"),
                    'leave' => $this->getTotalLeave($org_id, $uid, "3"),
                    'other' => $this->getTotalLeave($org_id, $uid, ""),
                    'msg' => 'success',
                    'sql' => $debug,
                    'status' => true,
                    'result' => $items,
                );
            } else {
                $item[0] = array(
                    'sick' => '0',
                    'leave' => '0',
                    'other' => '0',
                    'msg' => 'failed',
                    'sql' => $debug,
                    'status' => false,
                    'result' => $items,
                );
            }
        } else {
            $item[0] = array(
                'sick' => '0',
                'leave' => '0',
                'other' => '0',
                'msg' => 'failed',
                'sql' => '',
                'status' => false,
                'result' => $items,
            );
        }

        echo json_encode($item, JSON_UNESCAPED_UNICODE);
        exit();
    }

    function fineMonth($month)
    {
        if ($month == "มกราคม") {
            return "01";
        } else if ($month == "กุมภาพันธ์") {
            return "02";
        } else if ($month == "มีนาคม") {
            return "03";
        } else if ($month == "เมษายน") {
            return "04";
        } else if ($month == "พฤษภาคม") {
            return "05";
        } else if ($month == "มิถุนายน") {
            return "06";
        } else if ($month == "กรกฎาคม") {
            return "07";
        } else if ($month == "สิงหาคม") {
            return "08";
        } else if ($month == "กันยายน") {
            return "09";
        } else if ($month == "ตุลาคม") {
            return "10";
        } else if ($month == "พฤศจิกายน") {
            return "11";
        } else if ($month == "ธันวาคม") {
            return "12";
        }
    }

    function getListLeaveWait()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        //-----
        $org_id = $var['org_id'] ? $var['org_id'] : request('org_id');
        $uid = $var['uid'] ? $var['uid'] : request('uid');
        $statusLeave = $var['status_leave'] ? $var['status_leave'] : request('status_leave');
        $cid = $var['cid'] ? $var['cid'] : request('cid');
        $month_start = $var['month_start'] ? $var['month_start'] : request('month_start');
        $year_start = $var['year_start'] ? $var['year_start'] : request('year_start');
        $month_end = $var['month_end'] ? $var['month_end'] : request('month_end');
        $year_end = $var['year_end'] ? $var['year_end'] : request('year_end');

        $sql_search = "";
        if ($month_start && $year_start) {
            $year_start = $year_start - 543;
            $month_start = $this->fineMonth($month_start);
            $date_start = $year_start . '-' . $month_start . '-01';
            $sql_search .= " AND DATE(create_date) >= '{$date_start}' ";
        } else {
            $sql_search = "AND  YEAR(create_date) = YEAR(CURRENT_DATE())";
        }

        if ($month_end && $year_end) {
            $year_end = $year_end - 543;
            $month_end = $this->fineMonth($month_end);
            $date_end = $year_end . '-' . $month_end . '-01';
            $date_end = date('Y-m-t', strtotime($date_end));
            $sql_search .= " AND DATE(create_date) <= '{$date_end}' ";
        } else {
            $sql_search = "AND  YEAR(create_date) = YEAR(CURRENT_DATE())";
        }

        $table = 'leave_' . $org_id . '_information';
        $tableFile = 'leave_' . $org_id . '_attachments';
        $search_sql = "";
        $search_sql_cid = "";
        if ($statusLeave) {
            $search_sql = "AND  status_leave IN ({$statusLeave})";
        }
        if ($cid) {
            $cid_arr = explode(',', $cid);
            if (count($cid_arr) != 3) {
                if (in_array("3", $cid_arr)) {
                    if (count($cid_arr) == 1) {
                        $search_sql_cid = "AND  cid NOT IN (1,2)";
                    } else {
                        $result = $cid_arr[0] - $cid_arr[1];
                        $result = abs($result);
                        $search_sql_cid = "AND cid NOT IN ('{$result}')";
                    }
                } else {
                    $cid_data = implode("','", $cid_arr);
                    $search_sql_cid = "AND  cid IN ('{$cid_data}')";
                }
            }
        }
        $db = getDBO();
        $items = array();
        $itemsFiles = array();
        if ($org_id) {
            $sql = "SELECT          * 
                    FROM            {$table}
                    WHERE           status = '1'
                    AND             status_leave = '1'
                    AND             create_by != '{$uid}'
                    {$sql_search}
                    {$search_sql}
                    {$search_sql_cid}
                    ORDER BY status_leave ASC, FirstDate ASC";
            $db->setQuery($sql);
            $data = $db->loadAssocList();
            if ($_GET['debug']) {
                pre($sql);
                exit();
            }
            if ($data) {
                $index = 0;
                $indexFiles = 0;
                $dateLeave = "";
                $status_leave = "";
                $cate_name = "";
                for ($i = 0; $i < count($data); $i++) {
                    shortThaiDate($data[$i]['FirstDate']);
                    shortThaiDate($data[$i]['LastDate']);
                    shortThaiDate($data[$i]['create_date']);
                    if ($data[$i]['selectFulltime'] == "1") {
                        $dateLeave = $data[$i]['FirstDate'] . ' - ' . $data[$i]['LastDate'];
                    } else {
                        $dateLeave = $data[$i]['FirstDate'] . ' ' . substr($data[$i]['firstTime'], 0, 5) . '-' . substr($data[$i]['lastTime'], 0, 5) . ' น.';
                    }
                    if ($data[$i]['status_leave'] == "1") {
                        $status_leave = "รออนุมัติ";
                    } else if ($data[$i]['status_leave'] == "2") {
                        $status_leave = "อนุมัติแล้ว";
                    } else if ($data[$i]['status_leave'] == "3") {
                        $status_leave = "ไม่อนุมัติ";
                    } else {
                        $status_leave = "ยกเลิกการลา";
                    }
                    if ($data[$i]['cid'] == "2") {
                        $cate_name = "ลาป่วย";
                    } else if ($data[$i]['cid'] == "3") {
                        $cate_name = "ลากิจ";
                    } else {
                        $cate_name = "อื่นๆ";
                    }
                    $users = $this->getUsers($data[$i]['create_by']);
                    //check file;
                    $sql = "SELECT          * 
                            FROM            {$tableFile}
                            WHERE           uploadKey = '{$data[$i]['uploadKey']}'
                            AND             status = '1'";
                    $db->setQuery($sql);
                    $dataFile = $db->loadAssocList();
                    if ($dataFile) {
                        for ($j = 0; $j < count($dataFile); $j++) {
                            $itemsFiles[$indexFiles] = array(
                                'id' => $dataFile[$j]['id'],
                                'filename' => $dataFile[$j]['filename'],
                                'path' => base_url() . $dataFile[$j]['filepath'],
                                'extension' => $dataFile[$j]['extension'],
                            );
                            $indexFiles++;
                        }
                    }

                    $items[$index] = array(
                        'id' => $data[$i]['id'],
                        'cid' => $data[$i]['cid'],
                        'types' => $data[$i]['selectFulltime'],
                        'create_date' => $data[$i]['create_date'],
                        'fullname' => str_replace(',', ' ', $users['fullname']),
                        'dateLeave' => $dateLeave,
                        'status_leave' => $data[$i]['status_leave'],
                        'status_leave_text' => $status_leave,
                        'cate_name' => $cate_name,
                        // 'files' =>  $itemsFiles,
                    );

                    $index++;
                }

                $item[0] = array(
                    'sick' => $this->getTotalLeave($org_id, $uid, "2"),
                    'leave' => $this->getTotalLeave($org_id, $uid, "3"),
                    'other' => $this->getTotalLeave($org_id, $uid, ""),
                    'msg' => 'success',
                    'status' => true,
                    'result' => $items,
                );
            } else {
                $item[0] = array(
                    'sick' => '0',
                    'leave' => '0',
                    'other' => '0',
                    'msg' => 'failed',
                    'status' => false,
                    'result' => $items,
                );
            }
        } else {
            $item[0] = array(
                'sick' => '0',
                'leave' => '0',
                'other' => '0',
                'msg' => 'failed',
                'status' => false,
                'result' => $items,
            );
        }

        echo json_encode($item, JSON_UNESCAPED_UNICODE);
        exit();
    }

    function getListHistoryLeave()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        //-----
        $org_id = $var['org_id'] ? $var['org_id'] : request('org_id');
        $uid = $var['uid'] ? $var['uid'] : request('uid');
        $statusLeave = $var['status_leave'] ? $var['status_leave'] : request('status_leave');
        $cid = $var['cid'] ? $var['cid'] : request('cid');
        $month_start = $var['month_start'] ? $var['month_start'] : request('month_start');
        $year_start = $var['year_start'] ? $var['year_start'] : request('year_start');
        $month_end = $var['month_end'] ? $var['month_end'] : request('month_end');
        $year_end = $var['year_end'] ? $var['year_end'] : request('year_end');

        $sql_search = "";
        if ($month_start && $year_start) {
            $year_start = $year_start - 543;
            $month_start = $this->fineMonth($month_start);
            $date_start = $year_start . '-' . $month_start . '-01';
            $sql_search .= " AND DATE(create_date) >= '{$date_start}' ";
        } else {
            $sql_search = "AND  YEAR(create_date) = YEAR(CURRENT_DATE())";
        }

        if ($month_end && $year_end) {
            $year_end = $year_end - 543;
            $month_end = $this->fineMonth($month_end);
            $date_end = $year_end . '-' . $month_end . '-01';
            $date_end = date('Y-m-t', strtotime($date_end));
            $sql_search .= " AND DATE(create_date) <= '{$date_end}' ";
        } else {
            $sql_search = "AND  YEAR(create_date) = YEAR(CURRENT_DATE())";
        }

        $table = 'leave_' . $org_id . '_information';
        $tableFile = 'leave_' . $org_id . '_attachments';
        $search_sql = "";
        $search_sql_cid = "";
        if ($statusLeave) {
            $search_sql = "AND  status_leave IN ({$statusLeave})";
        }
        if ($cid) {
            $cid_arr = explode(',', $cid);
            if (count($cid_arr) != 3) {
                if (in_array("3", $cid_arr)) {
                    if (count($cid_arr) == 1) {
                        $search_sql_cid = "AND  cid NOT IN (1,2)";
                    } else {
                        $result = $cid_arr[0] - $cid_arr[1];
                        $result = abs($result);
                        $search_sql_cid = "AND cid NOT IN ('{$result}')";
                    }
                } else {
                    $cid_data = implode("','", $cid_arr);
                    $search_sql_cid = "AND  cid IN ('{$cid_data}')";
                }
            }
        }
        $db = getDBO();
        $items = array();
        $itemsFiles = array();
        if ($org_id) {
            $sql = "SELECT          * 
                    FROM            {$table}
                    WHERE           status = '1'
                    AND             status_leave != '1'
                    {$sql_search}
                    {$search_sql}
                    {$search_sql_cid}
                    ORDER BY status_leave ASC, create_date DESC";
            $db->setQuery($sql);
            $data = $db->loadAssocList();
            if ($data) {
                $index = 0;
                $indexFiles = 0;
                $dateLeave = "";
                $status_leave = "";
                $cate_name = "";
                for ($i = 0; $i < count($data); $i++) {
                    shortThaiDate($data[$i]['FirstDate']);
                    shortThaiDate($data[$i]['LastDate']);
                    shortThaiDate($data[$i]['create_date']);
                    if ($data[$i]['selectFulltime'] == "1") {
                        $dateLeave = $data[$i]['FirstDate'] . ' - ' . $data[$i]['LastDate'];
                    } else {
                        $dateLeave = $data[$i]['FirstDate'] . ' ' . substr($data[$i]['firstTime'], 0, 5) . '-' . substr($data[$i]['lastTime'], 0, 5) . ' น.';
                    }
                    if ($data[$i]['status_leave'] == "1") {
                        $status_leave = "รออนุมัติ";
                    } else if ($data[$i]['status_leave'] == "2") {
                        $status_leave = "อนุมัติแล้ว";
                    } else if ($data[$i]['status_leave'] == "3") {
                        $status_leave = "ไม่อนุมัติ";
                    } else {
                        $status_leave = "ยกเลิกการลา";
                    }
                    if ($data[$i]['cid'] == "2") {
                        $cate_name = "ลาป่วย";
                    } else if ($data[$i]['cid'] == "3") {
                        $cate_name = "ลากิจ";
                    } else {
                        $cate_name = "อื่นๆ";
                    }
                    $users = $this->getUsers($data[$i]['create_by']);
                    //check file;
                    $sql = "SELECT          * 
                            FROM            {$tableFile}
                            WHERE           uploadKey = '{$data[$i]['uploadKey']}'
                            AND             status = '1'";
                    $db->setQuery($sql);
                    $dataFile = $db->loadAssocList();
                    if ($dataFile) {
                        for ($j = 0; $j < count($dataFile); $j++) {
                            $itemsFiles[$indexFiles] = array(
                                'id' => $dataFile[$j]['id'],
                                'filename' => $dataFile[$j]['filename'],
                                'path' => base_url() . $dataFile[$j]['filepath'],
                                'extension' => $dataFile[$j]['extension'],
                            );
                            $indexFiles++;
                        }
                    }

                    $items[$index] = array(
                        'id' => $data[$i]['id'],
                        'cid' => $data[$i]['cid'],
                        'types' => $data[$i]['selectFulltime'],
                        'create_date' => $data[$i]['create_date'],
                        'dateLeave' => $dateLeave,
                        'fullname' => str_replace(',', ' ', $users['fullname']),
                        'status_leave' => $data[$i]['status_leave'],
                        'status_leave_text' => $status_leave,
                        'cate_name' => $cate_name,
                        // 'files' =>  $itemsFiles,
                    );

                    $index++;
                }

                $item[0] = array(
                    'sick' => $this->getTotalLeave($org_id, $uid, "2"),
                    'leave' => $this->getTotalLeave($org_id, $uid, "3"),
                    'other' => $this->getTotalLeave($org_id, $uid, ""),
                    'msg' => 'success',
                    'status' => true,
                    'result' => $items,
                );
            } else {
                $item[0] = array(
                    'sick' => '0',
                    'leave' => '0',
                    'other' => '0',
                    'msg' => 'failed',
                    'status' => false,
                    'result' => $items,
                );
            }
        } else {
            $item[0] = array(
                'sick' => '0',
                'leave' => '0',
                'other' => '0',
                'msg' => 'failed',
                'status' => false,
                'result' => $items,
            );
        }

        echo json_encode($item, JSON_UNESCAPED_UNICODE);
        exit();
    }

    function getBadgeLeave()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        //-----
        $org_id = $var['org_id'] ? $var['org_id'] : request('org_id');
        $uid = $var['uid'] ? $var['uid'] : request('uid');
        $table = 'leave_' . $org_id . '_information';
        $db = getDBO();
        if ($org_id) {
            $sql = "SELECT          * 
                    FROM            user_relationship
                    WHERE           org_id = '{$org_id}'
                    AND             uid = '{$uid}'
                    ";
            $db->setQuery($sql);
            $types = $db->loadAssocList();

            //check leave approve
            $users = $this->getUsers($uid);
            if ($types[0]['type'] == "admin" || $users['leave_approve'] == "1") {
                $sql = "SELECT          * 
                        FROM            {$table}
                        WHERE           status = '1'
                        AND             status_leave = '1'
                        AND             YEAR(create_date) = YEAR(CURRENT_DATE())
                        AND             create_by != '{$uid}'
                        ORDER BY status_leave ASC, FirstDate ASC";
                $db->setQuery($sql);
                if ($_GET['debug']) {
                    pre($sql);
                    exit();
                }
                $data = $db->loadAssocList();

                $arr_data = array();
                if ($data) {
                    // $leave_aid = $users['leave_aid'];
                    $len = count($data);
                    if ($len) {
                        for ($i = 0; $i < $len; $i++) {
                            $sql = "SELECT          * 
                                    FROM            users
                                    WHERE           id = '{$data[$i]['create_by']}'
                                    ";
                            $db->setQuery($sql);
                            $dataUser = $db->loadAssocList();
                            if ($dataUser[0]['leave_aid'] == $uid) {
                                $arr_data[] = $data[$i];
                            }
                        }
                    }
                } else {
                    $sql = "SELECT          * 
                            FROM            {$table}
                            WHERE           status = '1'
                            AND             status_leave = '4'
                            AND             recommend = '1'
                            AND             YEAR(create_date) = YEAR(CURRENT_DATE())
                            AND             create_by != '{$uid}'
                            ORDER BY status_leave ASC, FirstDate ASC";
                    $db->setQuery($sql);
                    $rs = $db->loadAssocList();
                    $len = count($rs);
                    if ($len) {
                        for ($i = 0; $i < $len; $i++) {
                            $sql = "SELECT          * 
                                    FROM            users
                                    WHERE           id = '{$rs[$i]['create_by']}'
                                    ";
                            $db->setQuery($sql);
                            $dataUser = $db->loadAssocList();
                            if ($dataUser[0]['leave_aid'] == $uid) {
                                $arr_data[] = $rs[$i];
                            }
                        }
                        $len = count($arr_data);
                        $item[0] = array(
                            'badge' => "{$len}",
                            'msg' => 'success',
                            'status' => true,
                        );
                        echo json_encode($item, JSON_UNESCAPED_UNICODE);
                        exit();
                    }
                }
            } else {
                $sql = "SELECT          * 
                        FROM            leave_notification_information
                        WHERE           org_id = '$org_id'
                        AND             uid = '{$uid}' 
                        AND             userclass != 'admin'
                        AND             status = '0'";
                $db->setQuery($sql);
                $data = $db->loadAssocList();
            }
            if ($data) {
                $len = count($arr_data);
                if ($_GET['debug']) {
                    pre($arr_data);
                    // pre($sql);
                    // exit();
                }
                $item[0] = array(
                    'badge' => "{$len}",
                    'msg' => 'success',
                    'status' => true,
                );
            } else {
                $item[0] = array(
                    'badge' => '0',
                    'msg' => 'failed',
                    'status' => false,
                );
            }
        } else {
            $item[0] = array(
                'badge' => '0',
                'msg' => 'failed',
                'status' => false,
            );
        }
        echo json_encode($item, JSON_UNESCAPED_UNICODE);
        exit();
    }

    function getBadgeNotiLeave($org_id, $uid)
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        //-----
        // $org_id = $var['org_id'] ? $var['org_id'] : request('org_id');
        // $uid = $var['uid'] ? $var['uid'] : request('uid');
        $table = 'leave_' . $org_id . '_information';
        $db = getDBO();
        if ($org_id) {
            $sql = "SELECT          * 
                    FROM            user_relationship
                    WHERE           org_id = '{$org_id}'
                    AND             uid = '{$uid}'
                    ";
            $db->setQuery($sql);
            $types = $db->loadAssocList();

            //check leave approve
            $users = $this->getUsers($uid);
            if ($types[0]['type'] == "admin" || $users['leave_approve'] == "1") {
                $sql = "SELECT          * 
                        FROM            {$table}
                        WHERE           status = '1'
                        AND             status_leave = '1'
                        AND             YEAR(create_date) = YEAR(CURRENT_DATE())
                        AND             create_by != '{$uid}'
                        ORDER BY status_leave ASC, FirstDate ASC";
                $db->setQuery($sql);
                if ($_GET['debug']) {
                    pre($sql);
                    exit();
                }
                $data = $db->loadAssocList();

                $arr_data = array();
                if ($data) {
                    // $leave_aid = $users['leave_aid'];
                    $len = count($data);
                    if ($len) {
                        for ($i = 0; $i < $len; $i++) {
                            $sql = "SELECT          * 
                                    FROM            users
                                    WHERE           id = '{$data[$i]['create_by']}'
                                    ";
                            $db->setQuery($sql);
                            $dataUser = $db->loadAssocList();
                            if ($dataUser[0]['leave_aid'] == $uid) {
                                $arr_data[] = $data[$i];
                            }
                        }
                    }
                } else {
                    $sql = "SELECT          * 
                            FROM            {$table}
                            WHERE           status = '1'
                            AND             status_leave = '4'
                            AND             recommend = '1'
                            AND             YEAR(create_date) = YEAR(CURRENT_DATE())
                            AND             create_by != '{$uid}'
                            ORDER BY status_leave ASC, FirstDate ASC";
                    $db->setQuery($sql);
                    $rs = $db->loadAssocList();
                    $len = count($rs);
                    if ($len) {
                        for ($i = 0; $i < $len; $i++) {
                            $sql = "SELECT          * 
                                    FROM            users
                                    WHERE           id = '{$rs[$i]['create_by']}'
                                    ";
                            $db->setQuery($sql);
                            $dataUser = $db->loadAssocList();
                            if ($dataUser[0]['leave_aid'] == $uid) {
                                $arr_data[] = $rs[$i];
                            }
                        }
                        $len = count($arr_data);
                        return $len;
                        exit();
                    }
                }
            } else {
                $sql = "SELECT          * 
                        FROM            leave_notification_information
                        WHERE           org_id = '$org_id'
                        AND             uid = '{$uid}' 
                        AND             userclass != 'admin'
                        AND             status = '0'";
                $db->setQuery($sql);
                $data = $db->loadAssocList();
            }
            if ($data) {
                $len = count($arr_data);
                return $len;
            } else {
                return 0;
            }
        } else {
            return 0;
        }
        exit();
    }

    function getTotalLeave($org_id, $uid, $cid = "")
    {
        $table = 'leave_' . $org_id . '_information';
        $db = getDBO();
        $search = "";
        if ($cid) {
            $search = "AND             cid = '{$cid}'";
        } else {
            $search = "AND             cid NOT IN (1,2)";
        }
        $sql = "SELECT          * 
                FROM            {$table}
                WHERE           create_by = '$uid'
                AND             status = '1'
                AND             status_leave = '2'
                AND             YEAR(create_date) = YEAR(CURRENT_DATE())
                {$search}";
        $db->setQuery($sql);
        $data = $db->loadAssocList();
        $len = count($data);
        return $len;
    }

    function getDayTotalLeaveApproveAll($org_id, $uid)
    {
        $table = 'leave_' . $org_id . '_information';
        $db = getDBO();
        $search = "";
        $sql = "SELECT          sum(numDate) AS total
                FROM            {$table}
                WHERE           create_by = '$uid'
                AND             status = '1'
                AND             status_leave = '2'  
                AND             cid IN ('2','3')
                AND             YEAR(create_date) = YEAR(CURRENT_DATE())
                {$search}";
        $db->setQuery($sql);
        $data = $db->loadAssocList();
        $len = $data[0]['total'];
        return $len;
    }

    function getDataLeaveFull($org_id, $uid)
    {
        $table = 'leave_' . $org_id . '_information';
        $db = getDBO();
        $search = "";
        $sql = "SELECT          *
                FROM            {$table}
                WHERE           create_by = '$uid'
                AND             status = '1'
                AND             status_leave = '2'  
                AND             cid IN ('2','3')
                AND             YEAR(create_date) = YEAR(CURRENT_DATE())";
        $db->setQuery($sql);
        $data = $db->loadAssocList();
        // $len = $data[0]['total'];
        return $data;
    }

    function getDayTotalLeaveApproveSubAll($org_id, $uid)
    {
        $table = 'leave_' . $org_id . '_information';
        $db = getDBO();
        $search = "";
        $sql = "SELECT          sum(numDate) AS total
                FROM            {$table}
                WHERE           create_by = '$uid'
                AND             status = '1'
                AND             status_leave = '2'  
                -- AND             selectFulltime = '2' 
                AND             cid = '6'
                AND             YEAR(create_date) = YEAR(CURRENT_DATE())
                {$search}";
        $db->setQuery($sql);
        $data = $db->loadAssocList();
        $len = $data[0]['total'];
        return $len;
    }

    function getTotalLeaveApproveAll($org_id, $uid, $cid = '')
    {
        $table = 'leave_' . $org_id . '_information';
        $db = getDBO();
        $search = "";
        $sql = "SELECT          * 
                FROM            {$table}
                WHERE           create_by = '$uid'
                AND             status = '1'
                AND             status_leave = '2'  
                AND             YEAR(create_date) = YEAR(CURRENT_DATE())
                {$search}";
        $db->setQuery($sql);
        $data = $db->loadAssocList();
        $len = count($data);
        return $len;
    }

    function getTotalLeaveApproveSubAll($org_id, $uid, $cid = '')
    {
        $table = 'leave_' . $org_id . '_information';
        $db = getDBO();
        $search = "";
        $sql = "SELECT          * 
                FROM            {$table}
                WHERE           create_by = '$uid'
                AND             status = '1'
                AND             status_leave = '2'  
                -- AND             selectFulltime = '2' 
                AND             cid = '6'
                AND             YEAR(create_date) = YEAR(CURRENT_DATE())
                {$search}";
        $db->setQuery($sql);
        $data = $db->loadAssocList();
        $len = count($data);
        return $len;
    }

    function getTotalLeaveAll()
    {
        $org_id = '1';
        $uid = '254';
        $table = 'leave_' . $org_id . '_information';
        $db = getDBO();
        $search = "";
        $sql = "SELECT          * 
                FROM            {$table}
                WHERE           create_by = '$uid'
                AND             status = '1'
                AND             status_leave = '2'  
                AND             YEAR(create_date) = YEAR(CURRENT_DATE())
                {$search}";
        $db->setQuery($sql);
        $data = $db->loadAssocList();
        $len = count($data);
        pre($len);
        exit();
    }

    function updateSeqOrg()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        //-----
        $id = $var['id'] ? $var['id'] : request('id');
        $seq = $var['seq'] ? $var['seq'] : request('seq');

        $obj = new stdClass();
        $obj->id = $id;
        $obj->seq = $seq;
        $db = getDBO();
        $insert = $db->updateObject('org_information', $obj, 'id');
        if ($insert) {
            $rs[0] = array(
                "msg" => "success",
                "status" => "true",
            );
        } else {
            $rs[0] = array(
                "msg" => "fails",
                "status" => "false",
            );
        }
        echo json_encode($rs, JSON_UNESCAPED_UNICODE);
        exit();
    }

    function updateHistoryStatus()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        //-----
        $id = $var['id'] ? $var['id'] : request('id');
        $history_status = $var['history_status'] ? $var['history_status'] : request('history_status');

        $obj = new stdClass();
        $obj->id = $id;
        $obj->history_status = $history_status ? $history_status : '0';
        $db = getDBO();
        $insert = $db->updateObject('org_information', $obj, 'id');
        if ($insert) {
            $rs[0] = array(
                "msg" => "success",
                "status" => "true",
            );
        } else {
            $rs[0] = array(
                "msg" => "fails",
                "status" => "false",
            );
        }
        echo json_encode($rs, JSON_UNESCAPED_UNICODE);
        exit();
    }

    function updateNotiStatus()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        //-----
        $id = $var['id'] ? $var['id'] : request('id');
        $noti_status = $var['noti_status'] ? $var['noti_status'] : request('noti_status');

        $obj = new stdClass();
        $obj->id = $id;
        $obj->noti_status = $noti_status ? $noti_status : '0';
        $db = getDBO();
        $insert = $db->updateObject('org_information', $obj, 'id');
        if ($insert) {
            $rs[0] = array(
                "msg" => "success",
                "status" => "true",
            );
        } else {
            $rs[0] = array(
                "msg" => "fails",
                "status" => "false",
            );
        }
        echo json_encode($rs, JSON_UNESCAPED_UNICODE);
        exit();
    }

    function updateOTStatus()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        //-----
        $id = $var['id'] ? $var['id'] : request('id');
        $ot_status = $var['ot_status'] ? $var['ot_status'] : request('ot_status');

        $obj = new stdClass();
        $obj->id = $id;
        $obj->ot_status = $ot_status ? $ot_status : '0';
        $db = getDBO();
        $insert = $db->updateObject('org_information', $obj, 'id');
        if ($insert) {
            $rs[0] = array(
                "msg" => "success",
                "status" => "true",
            );
        } else {
            $rs[0] = array(
                "msg" => "fails",
                "status" => "false",
            );
        }
        echo json_encode($rs, JSON_UNESCAPED_UNICODE);
        exit();
    }

    function updateLogoutStatus()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        //-----
        $id = $var['id'] ? $var['id'] : request('id');
        $logout_status = $var['logout_status'] ? $var['logout_status'] : request('logout_status');

        $obj = new stdClass();
        $obj->id = $id;
        $obj->logout_status = $logout_status ? $logout_status : '0';
        $db = getDBO();
        $insert = $db->updateObject('org_information', $obj, 'id');
        if ($insert) {
            $rs[0] = array(
                "msg" => "success",
                "status" => "true",
            );
        } else {
            $rs[0] = array(
                "msg" => "fails",
                "status" => "false",
            );
        }
        echo json_encode($rs, JSON_UNESCAPED_UNICODE);
        exit();
    }

    function updateTimeStatus()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        //-----
        $id = $var['id'] ? $var['id'] : request('id');
        $time_status = $var['time_status'] ? $var['time_status'] : request('time_status');

        $obj = new stdClass();
        $obj->id = $id;
        $obj->time_status = $time_status ? $time_status : '0';
        $db = getDBO();
        $insert = $db->updateObject('org_information', $obj, 'id');
        if ($insert) {
            $rs[0] = array(
                "msg" => "success",
                "status" => "true",
            );
        } else {
            $rs[0] = array(
                "msg" => "fails",
                "status" => "false",
            );
        }
        echo json_encode($rs, JSON_UNESCAPED_UNICODE);
        exit();
    }

    function updateLeaveCancelStatus()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        //-----
        $id = $var['id'] ? $var['id'] : request('id');
        $cancel_status = $var['cancel_status'] ? $var['cancel_status'] : request('cancel_status');

        $obj = new stdClass();
        $obj->id = $id;
        $obj->leave_cancel_status = $cancel_status ? $cancel_status : '0';
        $db = getDBO();
        $insert = $db->updateObject('org_information', $obj, 'id');
        if ($insert) {
            $rs[0] = array(
                "msg" => "success",
                "status" => "true",
            );
        } else {
            $rs[0] = array(
                "msg" => "fails",
                "status" => "false",
            );
        }
        echo json_encode($rs, JSON_UNESCAPED_UNICODE);
        exit();
    }

    function updateStatusSuperAdmin()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        //-----
        $id = $var['id'] ? $var['id'] : request('id');
        $super_status = $var['status'] ? $var['status'] : request('status');

        $obj = new stdClass();
        $obj->id = $id;
        $obj->super_status = $super_status ? $super_status : '0';
        $db = getDBO();
        $insert = $db->updateObject('users', $obj, 'id');
        if ($insert) {
            $rs[0] = array(
                "msg" => "success",
                "status" => "true",
            );
        } else {
            $rs[0] = array(
                "msg" => "fails",
                "status" => "false",
            );
        }
        echo json_encode($rs, JSON_UNESCAPED_UNICODE);
        exit();
    }

    function updateStatusBranchID()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        //-----
        $id = $var['id'] ? $var['id'] : request('id');
        $admin_branch_id = $var['admin_branch_id'] ? $var['admin_branch_id'] : request('admin_branch_id');

        $obj = new stdClass();
        $obj->id = $id;
        $obj->admin_branch_id = $admin_branch_id ? $admin_branch_id : '0';
        $db = getDBO();
        $insert = $db->updateObject('users', $obj, 'id');
        if ($insert) {
            $rs[0] = array(
                "msg" => "success",
                "status" => "true",
            );
        } else {
            $rs[0] = array(
                "msg" => "fails",
                "status" => "false",
            );
        }
        echo json_encode($rs, JSON_UNESCAPED_UNICODE);
        exit();
    }

    public function sendNotiCheckIn()
    {
        //check data in attend
        $db = getDBO();
        //check data in org
        $sql = "SELECT          * 
                FROM            org_information
                WHERE           status = '1'
                AND             noti_status = '1'
                AND             parent_id = '0'";
        $db->setQuery($sql);
        $rs = $db->loadAssocList();
        $len = count($rs);
        $item = array();
        if ($len) {
            $index = 0;
            for ($i = 0; $i < $len; $i++) {
                //check data in branch
                $sql = "SELECT          * 
                        FROM            org_information
                        WHERE           status = '1'
                        AND             noti_status = '1'
                        AND             parent_id = '{$rs[$i]['id']}'
                        ";
                $db->setQuery($sql);
                $data = $db->loadAssocList();
                if ($data) {
                    //check time in branch
                    for ($j = 0; $j < count($data); $j++) {
                        $sql = "SELECT          * 
                                FROM            user_relationship
                                WHERE           org_id = '{$rs[$i]['id']}'
                                AND             org_sub_id = '{$data[$j]['id']}'
                                AND             time_id != ''
                                -- GROUP BY        time_id
                                ";
                        $db->setQuery($sql);
                        $time = $db->loadAssocList();
                        if ($time) {
                            //send to org
                            $item[$index] = array(
                                'org_id' => $data[$j]['id'],
                                'time_id' => $time[0]['time_id'],
                            );
                            $index++;
                        }
                    }
                }
            }
        }
        if ($item) {
            $token = array();

            $notification = array(
                'title' => 'IsmartLogin',
                'body' => 'เหลือเวลาอีก 5 นาที คุณจะถึงเวลาเข้าทำงาน',
            );

            $package_name_android = "com.cityvariety.ismart_login";
            $package_name_ios = 'com.cityvariety.ismartlogin';

            $data = array(
                'display_image' => '',
                'id' => "1",
                'subject' => "แจ้งเตือนก่อนเข้าทำงาน IsmartLogin",
                'title' => "แจ้งเตือนก่อนเข้าทำงาน IsmartLogin",
                'description' => "เหลือเวลาอีก 5 นาที คุณจะถึงเวลาเข้าทำงาน",
                'body' => "เหลือเวลาอีก 5 นาที คุณจะถึงเวลาเข้าทำงาน",
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                'notificationID' => '' . rand(1, 999)
            );

            $apns = array(
                'payload' => array(
                    'aps' => array(
                        'alert' => array(
                            'title' => $data['title'],
                            'body' => $data['body'],
                        ),
                        'sound' => 'default',  // Sound for iOS
                        'badge' => 0 // Badge count for iOS app icon
                    ),
                ),
            );

            $android = array(
                'notification' => array(
                    'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                ),
            );

            $message = array(
                'notification' => $notification,
                'data' => $data,
                'android' => $android,
                'apns' => $apns
            );

            $curr_day = (date('N') - 1);
            $curr_time = date('H:i');

            $org_id = '';
            $len_item = count($item);
            for ($i = 0; $i < $len_item; $i++) {
                $sql = "SELECT          * 
                        FROM            time_information
                        WHERE           id = '{$item[$i]['time_id']}'";
                $db->setQuery($sql);
                $rs_data = $db->loadAssocList();
                // if ($item[$i]['org_id'] == "3") {
                if ($rs_data[0]['description']) {
                    $allTime = json_decode($rs_data[0]['description'], true);
                }
                if ($allTime) {
                    if ($allTime[$curr_day]) {
                        $time_start = $allTime[$curr_day]['time_start'];
                        $time_send = date('H:i', strtotime($time_start . '- 5 minutes'));
                        // pre($curr_time);
                        // pre($time_send);
                        if ($curr_time == $time_send) {
                            $condition_android = "'{$package_name_android}' in topics && 'org_{$item[$i]['org_id']}' in topics";
                            $condition_ios = "'{$package_name_ios}' in topics && 'org_{$item[$i]['org_id']}' in topics";


                            $message['condition'] = $condition_ios;
                            $rs['send_target'] = $this->send_notification($message);

                            $message['condition'] = $condition_android;
                            $rs['send_target'] = $this->send_notification($message);

                            // android
                            // $this->send_notificationOLD($token, $notification, $data, $package_name_android, $condition_android);
                            // ios
                            // $this->send_notificationOLD($token, $notification, $data, $package_name_ios, $condition_ios);
                        }
                    }
                }
                // }
            }
        }
    }

    public function sendNotiCheckInTest()
    {
        //check data in attend
        $db = getDBO();
        //check data in org
        $sql = "SELECT          * 
                FROM            org_information
                WHERE           status = '1'
                AND             noti_status = '1'
                AND             parent_id = '0'
                ";
        $db->setQuery($sql);
        $rs = $db->loadAssocList();
        $len = count($rs);
        $item = array();
        if ($len) {
            $index = 0;
            for ($i = 0; $i < $len; $i++) {
                //check data in branch
                $sql = "SELECT          * 
                        FROM            org_information
                        WHERE           status = '1'
                        AND             noti_status = '1'
                        AND             parent_id = '{$rs[$i]['id']}'
                        ";
                $db->setQuery($sql);
                $data = $db->loadAssocList();
                if ($data) {
                    //check time in branch
                    for ($j = 0; $j < count($data); $j++) {
                        $sql = "SELECT          * 
                                FROM            user_relationship
                                WHERE           org_id = '{$rs[$i]['id']}'
                                AND             org_sub_id = '{$data[$j]['id']}'
                                AND             time_id != ''
                                -- GROUP BY        time_id
                                ";
                        $db->setQuery($sql);
                        $time = $db->loadAssocList();
                        if ($time) {
                            //send to org
                            $item[$index] = array(
                                'org_id' => $data[$j]['id'],
                                'time_id' => $time[0]['time_id'],
                            );
                            $index++;
                        }
                    }
                }
            }
        }
        //data branch and time send noti
        pre($item);
        exit();
        if ($item) {
            $token = array();
            $notification = array(
                'title' => 'IsmartLogin',
                'sound' => 1,
                'body' => 'เหลือเวลาอีก 5 นาที คุณจะถึงเวลาเข้าทำงาน',
                'icon' => 'https://ismartlogin.cityvariety.com/images/logo_app.png',
            );
            $package_name_android = "com.cityvariety.ismart_login";
            $package_name_ios = 'com.cityvariety.ismartlogin';

            $data = array(
                'display_image' => '',
                'id' => "1",
                'subject' => "แจ้งเตือนก่อนเข้าทำงาน IsmartLogin",
                'title' => "แจ้งเตือนก่อนเข้าทำงาน IsmartLogin",
                'description' => "เหลือเวลาอีก 5 นาที คุณจะถึงเวลาเข้าทำงาน",
                'body' => "เหลือเวลาอีก 5 นาที คุณจะถึงเวลาเข้าทำงาน",
                'sound' => 1,
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                'notificationID' => rand(1, 999)
            );

            $curr_day = (date('N') - 1);
            $curr_time = date('H:i');
            $org_id = '';
            $len_item = count($item);
            // pre($len_item);
            for ($i = 0; $i < $len_item; $i++) {
                $sql = "SELECT          * 
                        FROM            time_information
                        WHERE           id = '{$item[$i]['time_id']}'
                        ";
                $db->setQuery($sql);
                $rs_data = $db->loadAssocList();
                // exit($sql);
                // pre($rs_data);
                if ($rs_data[0]['description']) {
                    $allTime = json_decode($rs_data[0]['description'], true);
                }
                // pre($allTime);
                if ($allTime) {
                    if ($allTime[4]) {
                        $time_start = $allTime[4]['time_start'];
                        $time_send = date('H:i', strtotime($time_start . '- 6 minutes'));
                        pre($time_start);
                        pre($time_send);
                        pre($item[$i]['org_id']);
                        if ($curr_time == $time_send) {
                            pre($curr_time);
                            pre($time_send);
                            pre($item[$i]['org_id']);
                        }
                    }
                }
            }
        }
    }

    public function setDataNotificationOLD($uid, $subject)
    {
        $token = array();
        $notification = array(
            'title' => "แจ้งการลา IsmartLogin",
            'body' => $subject,
            'sound' => 1,
            'icon' => 'https://ismartlogin.cityvariety.com/images/logo_app.png',
        );
        $package_name_android = "com.cityvariety.ismart_login";
        $package_name_ios = 'com.cityvariety.ismartlogin';

        $data = array(
            'display_image' => '',
            'id' => "1",
            'subject' => "IsmartLogin",
            'title' => $subject,
            'description' => $subject,
            'body' => $subject,
            'sound' => 1,
            'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
            'notificationID' => rand(1, 999)
        );

        // $org_id = '339';
        $condition_android = "'{$package_name_android}' in topics && 'users_{$uid}' in topics";
        $condition_ios = "'{$package_name_ios}' in topics && 'users_{$uid}' in topics";
        //android
        $this->send_notificationOLD($token, $notification, $data, $package_name_android, $condition_android);
        //iod
        $this->send_notificationOLD($token, $notification, $data, $package_name_ios, $condition_ios);
    }

    public function sendNotiTest()
    {
        $uid = '17';
        $subject = 'ทดสอบการส่งข้อความ';
        $this->setDataNotification($uid, $subject);
    }

    public function setDataNotification($uid, $subject)
    {

        $package_name_android = "com.cityvariety.ismart_login";
        $package_name_ios = 'com.cityvariety.ismartlogin';

        $notification = array(
            'title' => "แจ้งการลา IsmartLogin",
            'body' => $subject,
        );

        $data = array(
            'title' => $subject,
            'description' => $subject,
            'display_image' => '',
            'id' => "1",
            'subject' => "IsmartLogin",
            'body' => $subject,
            'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
            'notificationID' => '' . rand(1, 999),
        );

        $org_id = getMyOrgId($uid);
        $org_id = $org_id['org_id'];
        $badge =  $this->getBadgeNotiLeave($org_id, $uid);
        $badge = intval($badge);

        $apns = array(
            'payload' => array(
                'aps' => array(
                    'alert' => array(
                        'title' => $data['title'],
                        'body' => $data['body'],
                    ),
                    'sound' => 'default',  // Sound for iOS
                    'badge' => $badge // Badge count for iOS app icon
                ),
            ),
        );

        $android = array(
            'notification' => array(
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
            ),
        );

        $message = array(
            'notification' => $notification,
            'data' => $data,
            'android' => $android,
            'apns' => $apns
        );

        $rs = array();

        $message['condition'] = "'{$package_name_ios}' in topics && 'users_{$uid}' in topics";
        $rs['send_target'] = $this->send_notification($message);

        $message['condition'] = "'{$package_name_android}' in topics && 'users_{$uid}' in topics";
        $rs['send_target'] = $this->send_notification($message);
    }


    // Maximum payload for both message types is 4KB, except when sending messages from the Firebase console, which enforces a 1024 character limit.
    private function send_notificationOLD($token, $payload_notification, $payload_data, $package_name, $condition = '')
    {
        $url = 'https://fcm.googleapis.com/fcm/send';

        $fields = array(
            'to' => '/topics/' . $package_name,
            'priority' => 'high',
            'data' => $payload_data
        );

        if ($payload_notification) {
            $fields['notification'] = $payload_notification;
        }

        if ($token) {
            if (is_array($token)) {
                $len = count($token);
                if ($len == 1) {
                    $fields['to'] = $token[0];
                    unset($fields['registration_ids']);
                } else if ($len > 1) {
                    $fields['registration_ids'] = $token;
                    unset($fields['to']);
                }
            } else {
                $fields['to'] = $token;
                unset($fields['registration_ids']);
            }
        }

        if ($condition) {
            $fields['condition'] = $condition;
            unset($fields['registration_ids']);
            unset($fields['to']);
        }


        $headers = array(
            'Authorization: key=AAAAd_oM1ZU:APA91bE0o4Lr-ipsG3unyM1QLWWSvkCWiGiwgN_oog4iPi8WHUnMHrYxwgYvW5Y0vBjAzQ7dmhVlgzvgP9gMG7N3JoRWTo4RL6Rq39HYOLCDyVtjr5YTb7h-uP1DkdYQyKR1LqHVw6VZ',
            'Content-Type: application/json'
        );

        // Open connection
        $ch = curl_init();

        // Set the url, number of POST vars, POST data
        curl_setopt($ch, CURLOPT_URL, $url);

        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

        // Disabling SSL Certificate support temporary
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);

        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($fields));

        // Execute post
        $result = curl_exec($ch);
        curl_close($ch);

        // pre($result);
        // return $result;
    }

    public function checkAppVersion()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;

        $platform = $var['platform'] ? $var['platform'] : request('platform', 'android');
        $version = $var['version'] ? $var['version'] : request('version');

        $result = array();
        $result['status'] = 1;
        // $result['url'] = "";
        // $result['msg'] = ""; //$version . '/' . $info['version'];
        // $result['important'] = 0; // 0 ใช้งานต่อได้, 1 บังคับอัพเดท

        echo json_encode($result);
        exit();

        //if ($platform == "android") {
        $info = $this->get_online_app_info($platform);
        //}

        $result['debug']['info'] = $info;

        $public = explode('.', $info['version']);
        $current = explode('.', $version);
        $len = count($current);
        for ($i = 0; $i < $len; $i++) {
            $v_current = intval($current[$i]);
            $v_public = intval(@$public[$i]);
            if ($v_current > $v_public) {
                break;
            } else if ($v_current < $v_public) {
                $result['status'] = 0;
                $result['url'] = $info['url'];
                $result['msg'] = 'กรุณาอัพเดทแอปพลิเคชั่น'; //$version . '/' . $info['version'];
                $result['important'] = 1; // 0 ใช้งานต่อได้, 1 บังคับอัพเดท
                break;
            } else {
                continue;
            }
        }

        echo json_encode($result);
        exit();
    }

    private function get_online_app_info($platform)
    {
        // check in database before
        $result = array(
            'url' => $url,
            'version' => '1.0.0',
        );
        if ($platform === 'ios') {
            // $url = 'https://itunes.apple.com/lookup?id=1561564431&t=' . time();
            // $json = file_get_contents($url);
            // $rs = json_decode($json, true);
            // $result = array(
            //     'url' => 'https://itunes.apple.com/th/app/id1561564431?ls=1&mt=8&t=' . time(),
            //     'version' => $rs['results'][0]['version'],
            // );
            $result = array(
                'url' => 'https://itunes.apple.com/th/app/id1561564431?ls=1&mt=8&t=' . time(),
                'version' => '1.1.26',
            );
        } else if ($platform === 'android') {
            // $this->load->library('simple_html_dom');
            // $url = 'https://play.google.com/store/apps/details?id=com.cityvariety.ismart_login&t=' . time();

            // $element = 'span[class=htlgb]';
            // $html = file_get_html($url);

            // if (@$html) {
            //     $result['version'] = trim($html->find($element, 6)->plaintext);
            //     $result['url'] = $url;
            // }
            $result = array(
                'url' => 'https://play.google.com/store/apps/details?id=com.cityvariety.ismart_login&t=' . time(),
                'version' => '1.1.26',
            );
        }

        return $result;
    }

    public function getTimeInServer()
    {
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;

        $result = array();
        $result['time'] = date('H:i');

        echo json_encode($result);
        exit();
    }

    public function setLineNotify()
    {
        $db = getDBO();

        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;

        $id = $var['id'] ? $var['id'] : request('id');
        $uid = $var['uid'] ? $var['uid'] : request('uid');
        $org_id = $var['org_id'] ? $var['org_id'] : request('org_id');
        $create_by = $var['create_by'] ? $var['create_by'] : request('create_by');
        $platform = $var['platform'] ? $var['platform'] : request('platform', 'android');

        $fullname = '';
        $uname = '';
        $dateLeave = '';
        $totalLeave = '';
        $msg = '';

        $table = 'leave_' . $org_id . '_information';
        $table_cate = 'leave_' . $org_id . '_category';

        $sql = "SELECT          * 
                FROM            {$table}
                WHERE           status = '1'
                AND             id = '{$id}'";
        $db->setQuery($sql);
        $data = $db->loadAssocList();

        //check line token
        $sql = "SELECT          * 
                FROM            org_information
                WHERE           id = '{$org_id}'
                ";
        $db->setQuery($sql);
        $line_token = $db->loadAssocList();
        $line_token = $line_token[0]['token_key_line'] ? $line_token[0]['token_key_line'] : Site::$key_line;

        // pre($data);
        $result = array();
        if ($data) {

            shortThaiDate($data[0]['FirstDate']);
            shortThaiDate($data[0]['LastDate']);
            shortThaiDate($data[0]['create_date']);
            shortThaiDateTime($data[0]['update_date']);

            $dateLeave = $data[0]['FirstDate'];
            $dateEnd = $data[0]['LastDate'];
            $totalLeave = $this->getTotalLeaveApproveAll($org_id, $data[0]['create_by'], $data[0]['cate_id']);
            $totalSubLeave = $this->getTotalLeaveApproveSubAll($org_id, $data[0]['create_by'], $data[0]['cate_id']);
            $totalLeaveDay = $this->getDayTotalLeaveApproveAll($org_id, $data[0]['create_by']);
            $dataLeaveFull = $this->getDataLeaveFull($org_id, $data[0]['create_by']);
            $totalSubLeaveDay = $this->getDayTotalLeaveApproveSubAll($org_id, $data[0]['create_by']);

            $uname = $this->getUsers($data[0]['create_by']);
            $fullname = $this->getUsers($data[0]['update_by']);
            $uname['fullname'] = $uname['nickname'] ? $uname['nickname'] : $uname['fullname'];
            $fullname['fullname'] = $fullname['nickname'] ? $fullname['nickname'] : $fullname['fullname'];


            $sql = "SELECT          cate_name 
                    FROM            {$table_cate}
                    WHERE           status = '1'
                    AND             id = '{$data[0]['cid']}'";
            $db->setQuery($sql);
            $catename = $db->loadAssocList();


            // $msg = "มีรายการอนุมัติการลางานใหม่" . PHP_EOL;
            $msg = "" . PHP_EOL;

            if ($data[0]['selectFulltime'] == "2") {
                $timeLeave = substr($data[0]['firstTime'], 0, 5);
                $timeEnd = substr($data[0]['lastTime'], 0, 5);
                $msg .= str_replace(',', ' ', $uname['fullname']) . " ขอ" . $catename[0]['cate_name'] . " " . $timeLeave . " - " . $timeEnd . " น. " . $dateLeave . PHP_EOL . PHP_EOL;
            } else {
                if ($data[0]['numDate'] > 1) {
                    $msg .= str_replace(',', ' ', $uname['fullname']) . " ขอ" . $catename[0]['cate_name'] . " " . $data[0]['numDate'] . " วัน " . $dateLeave . " - " . $dateEnd . PHP_EOL . PHP_EOL;
                    // $msg .= "ลา " . $data[0]['numDate'] . " วัน" . PHP_EOL;
                } else {
                    $msg .= str_replace(',', ' ', $uname['fullname']) . " ขอ" . $catename[0]['cate_name'];
                    if ($data[0]['numDate'] == 1) {
                        $msg .= " " . $data[0]['numDate'] . " วัน";
                    } else if ($data[0]['numDate'] == 0.5) {
                        $msg .= " ลาครึ่งวัน";
                    }
                    $msg .= " " . $dateLeave . PHP_EOL . PHP_EOL;
                }
            }


            // $msg .=  str_replace(',', ' ', $uname['fullname']) . " ได้รับอนุมัติการลาจาก " . str_replace(',', ' ', $fullname['fullname']) . PHP_EOL;
            $msg .= "อนุมัติโดย " . str_replace(',', ' ', $fullname['fullname']) . " เมื่อ " . $data[0]['update_date'] . PHP_EOL . PHP_EOL;
            if ($data[0]['selectFulltime'] == "2") {
                $msg .= "ลาย่อยทั้งหมด " . $totalSubLeave . " ครั้ง(รวม " . number_format($totalSubLeaveDay, 1) . " ชั่วโมง)";
            } else {
                $msg .= "ลาทั้งหมด " . $totalLeave . " ครั้ง(รวม " . number_format($totalLeaveDay, 1) . " วัน)" . PHP_EOL;
                if ($dataLeaveFull) {
                    $len_data = count($dataLeaveFull);
                    if ($len_data > 0) {
                        $leave_half = array();
                        $leave_full = array();
                        for ($i = 0; $i < $len_data; $i++) {
                            if ($dataLeaveFull[$i]['numDate'] == "0.5") {
                                $leave_half[] = $dataLeaveFull[$i]['numDate'];
                            } else {
                                $leave_full[] = $dataLeaveFull[$i]['numDate'];
                            }
                        }
                        if (count($leave_half) > 0) {
                            $sum_half = array_sum($leave_half);
                            $msg .= "ลาครึ่งวันทั้งหมด " . count($leave_half) . " ครั้ง(รวม " . number_format($sum_half, 1) . " วัน)" . PHP_EOL;
                        }
                        if (count($leave_full) > 0) {
                            $sum_full = array_sum($leave_full);
                            $msg .= "ลาเต็มวันทั้งหมด " . count($leave_full) . " ครั้ง(รวม " . number_format($sum_full, 1) . " วัน)" . PHP_EOL;
                        }
                    }
                }
                if ($totalSubLeave > 0) {
                    $msg .= "ลาย่อยทั้งหมด " . $totalSubLeave . " ครั้ง(รวม " . number_format($totalSubLeaveDay, 1) . " ชั่วโมง)";
                }
            }

            $mes = $msg;

            header('Content-Type: text/html; charset=utf-8');
            $line_api = 'https://notify-api.line.me/api/notify';

            $str = $mes; //ข้อความที่ต้องการส่ง สูงสุด 1000 ตัวอักษร
            $image_thumbnail_url = ''; // ขนาดสูงสุด 240×240px JPEG
            $image_fullsize_url = ''; // ขนาดสูงสุด 1024×1024px JPEG
            $message_data = array(
                'message' => $str,
                'imageThumbnail' => $image_thumbnail_url,
                'imageFullsize' => $image_fullsize_url,
            );
            $result = $this->send_notify_line($line_api, $line_token, $message_data);
            if ($org_id == '1') {
                if ($str) {
                    $token = Site::$cityLeaveToken;
                    $this->sendTextToLineGroup($token, $str);
                    //send to telegram
                    $botToken = TelegramConfig::$botToken;
                    $chatId = TelegramConfig::$chatIdLeave;
                    // $this->sendTelegramMessage($botToken, $chatId, $str);
                }
            }
        }
        return $result;
    }

    public function setLineNotifyTest()
    {
        $db = getDBO();

        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;

        $id = $var['id'] ? $var['id'] : request('id');
        $uid = $var['uid'] ? $var['uid'] : request('uid');
        $org_id = $var['org_id'] ? $var['org_id'] : request('org_id');
        $create_by = $var['create_by'] ? $var['create_by'] : request('create_by');
        $platform = $var['platform'] ? $var['platform'] : request('platform', 'android');

        $fullname = '';
        $uname = '';
        $dateLeave = '';
        $totalLeave = '';
        $msg = '';

        $table = 'leave_' . $org_id . '_information';
        $table_cate = 'leave_' . $org_id . '_category';

        $sql = "SELECT          * 
                FROM            {$table}
                WHERE           status = '1'
                AND             id = '{$id}'";
        $db->setQuery($sql);
        $data = $db->loadAssocList();

        //check line token
        $sql = "SELECT          * 
                FROM            org_information
                WHERE           id = '{$org_id}'
                ";
        $db->setQuery($sql);
        $line_token = $db->loadAssocList();
        $line_token = $line_token[0]['token_key_line'] ? $line_token[0]['token_key_line'] : Site::$key_line;

        // pre($data);
        $result = array();
        if ($data) {

            shortThaiDate($data[0]['FirstDate']);
            shortThaiDate($data[0]['LastDate']);
            shortThaiDate($data[0]['create_date']);
            shortThaiDateTime($data[0]['update_date']);

            $dateLeave = $data[0]['FirstDate'];
            $dateEnd = $data[0]['LastDate'];
            $totalLeave = $this->getTotalLeaveApproveAll($org_id, $data[0]['create_by'], $data[0]['cate_id']);
            $totalSubLeave = $this->getTotalLeaveApproveSubAll($org_id, $data[0]['create_by'], $data[0]['cate_id']);
            $totalLeaveDay = $this->getDayTotalLeaveApproveAll($org_id, $data[0]['create_by']);
            $dataLeaveFull = $this->getDataLeaveFull($org_id, $data[0]['create_by']);
            $totalSubLeaveDay = $this->getDayTotalLeaveApproveSubAll($org_id, $data[0]['create_by']);

            $uname = $this->getUsers($data[0]['create_by']);
            $fullname = $this->getUsers($data[0]['update_by']);
            $uname['fullname'] = $uname['nickname'] ? $uname['nickname'] : $uname['fullname'];
            $fullname['fullname'] = $fullname['nickname'] ? $fullname['nickname'] : $fullname['fullname'];


            $sql = "SELECT          cate_name 
                    FROM            {$table_cate}
                    WHERE           status = '1'
                    AND             id = '{$data[0]['cid']}'";
            $db->setQuery($sql);
            $catename = $db->loadAssocList();


            // $msg = "มีรายการอนุมัติการลางานใหม่" . PHP_EOL;
            $msg = "" . PHP_EOL;

            if ($data[0]['selectFulltime'] == "2") {
                $timeLeave = substr($data[0]['firstTime'], 0, 5);
                $timeEnd = substr($data[0]['lastTime'], 0, 5);
                $msg .= str_replace(',', ' ', $uname['fullname']) . " ขอ" . $catename[0]['cate_name'] . " " . $timeLeave . " - " . $timeEnd . " น. " . $dateLeave . PHP_EOL . PHP_EOL;
            } else {
                if ($data[0]['numDate'] > 1) {
                    $msg .= str_replace(',', ' ', $uname['fullname']) . " ขอ" . $catename[0]['cate_name'] . " " . $data[0]['numDate'] . " วัน " . $dateLeave . " - " . $dateEnd . PHP_EOL . PHP_EOL;
                    // $msg .= "ลา " . $data[0]['numDate'] . " วัน" . PHP_EOL;
                } else {
                    $msg .= str_replace(',', ' ', $uname['fullname']) . " ขอ" . $catename[0]['cate_name'];
                    if ($data[0]['numDate'] == 1) {
                        $msg .= " " . $data[0]['numDate'] . " วัน";
                    } else if ($data[0]['numDate'] == 0.5) {
                        $msg .= " ลาครึ่งวัน";
                    }
                    $msg .= " " . $dateLeave . PHP_EOL . PHP_EOL;
                }
            }


            // $msg .=  str_replace(',', ' ', $uname['fullname']) . " ได้รับอนุมัติการลาจาก " . str_replace(',', ' ', $fullname['fullname']) . PHP_EOL;
            $msg .= "อนุมัติโดย " . str_replace(',', ' ', $fullname['fullname']) . " เมื่อ " . $data[0]['update_date'] . PHP_EOL . PHP_EOL;
            if ($data[0]['selectFulltime'] == "2") {
                $msg .= "ลาย่อยทั้งหมด " . $totalSubLeave . " ครั้ง(รวม " . number_format($totalSubLeaveDay, 1) . " ชั่วโมง)";
            } else {
                $msg .= "ลาทั้งหมด " . $totalLeave . " ครั้ง(รวม " . number_format($totalLeaveDay, 1) . " วัน)" . PHP_EOL;
                if ($dataLeaveFull) {
                    $len_data = count($dataLeaveFull);
                    if ($len_data > 0) {
                        $leave_half = array();
                        $leave_full = array();
                        for ($i = 0; $i < $len_data; $i++) {
                            if ($dataLeaveFull[$i]['numDate'] == "0.5") {
                                $leave_half[] = $dataLeaveFull[$i]['numDate'];
                            } else {
                                $leave_full[] = $dataLeaveFull[$i]['numDate'];
                            }
                        }
                        if (count($leave_half) > 0) {
                            $sum_half = array_sum($leave_half);
                            $msg .= "ลาครึ่งวันทั้งหมด " . count($leave_half) . " ครั้ง(รวม " . number_format($sum_half, 1) . " วัน)" . PHP_EOL;
                        }
                        if (count($leave_full) > 0) {
                            $sum_full = array_sum($leave_full);
                            $msg .= "ลาเต็มวันทั้งหมด " . count($leave_full) . " ครั้ง(รวม " . number_format($sum_full, 1) . " วัน)" . PHP_EOL;
                        }
                    }
                }
                if ($totalSubLeave > 0) {
                    $msg .= "ลาย่อยทั้งหมด " . $totalSubLeave . " ครั้ง(รวม " . number_format($totalSubLeaveDay, 1) . " ชั่วโมง)";
                }
            }

            $mes = $msg;
            pre($mes);
            exit();
        }
        return $result;
    }


    private function send_notify_line($line_api, $access_token, $message_data)
    {
        $headers = array('Method: POST', 'Content-type: multipart/form-data', 'Authorization: Bearer ' . $access_token);

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $line_api);
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

    public function sendReportLeave()
    {
        $db = getDBO();

        //check server มีปัญหา
        $curr_date = date('Y-m-d');
        $sql = "SELECT          * 
                FROM            noti_leave_information
                WHERE           DATE(create_date) = DATE({$curr_date})
                ORDER BY id DESC
                LIMIT 1";
        $db->setQuery($sql);
        $data = $db->loadAssocList();

        // pre($sql);
        // exit();
        if (!$data) {
            $org_id = '1';
            $msg = '';
            $table = 'leave_' . $org_id . '_information';
            $table_cate = 'leave_' . $org_id . '_category';
            $curr_date = DATE('Y-m-d');
            // $curr_date = '2023-07-06';
            $sql = "SELECT          * 
                    FROM            {$table}
                    WHERE           status = '1'
                    AND             status_leave = '2'
                    AND             DATE('{$curr_date}') BETWEEN `FirstDate` AND `LastDate`";
            $db->setQuery($sql);
            // AND             DATE(LastDate) = DATE('{$curr_date}')
            // pre($sql);
            // exit();
            $rs = $db->loadAssocList();
            $len = count($rs);

            shortThaiDate($curr_date);

            if ($len > 0) {
                $msg = "วันนี้ " . $curr_date . " มีผู้ลา " . $len . " คน " . PHP_EOL;
                for ($i = 0; $i < $len; $i++) {
                    $uname = $this->getUsers($rs[$i]['create_by']);
                    $name = $uname['nickname'] ? $uname['nickname'] : $uname['fullname'];
                    $sql = "SELECT          cate_name 
                            FROM            {$table_cate}
                            WHERE           status = '1'
                            AND             id = '{$rs[$i]['cid']}'";
                    $db->setQuery($sql);
                    $catename = $db->loadAssocList();
                    $timeLeave = '';
                    if ($catename[0]['cate_name'] == "ลาย่อยระหว่างวัน") {
                        $timeLeave = substr($rs[$i]['firstTime'], 0, 5) . " - " . substr($rs[$i]['lastTime'], 0, 5) . " น.";
                    }
                    $msg .= ($i + 1) . ". " . str_replace(",", " ", $name) . " " . $catename[0]['cate_name'] . " " . $timeLeave . PHP_EOL;
                }
            } else {
                $msg = "วันนี้ " . $curr_date . " ไม่มีผู้ลา" . PHP_EOL;
            }
            // pre($msg);
            // exit();
            $mes = $msg;
            $line_token = '8liRTzSrUHr4f2l62DUm3Wd1fgLOzytGqL85lYKPCNF';
            header('Content-Type: text/html; charset=utf-8');
            $line_api = 'https://notify-api.line.me/api/notify';

            $str = $mes; //ข้อความที่ต้องการส่ง สูงสุด 1000 ตัวอักษร
            $image_thumbnail_url = ''; // ขนาดสูงสุด 240×240px JPEG
            $image_fullsize_url = ''; // ขนาดสูงสุด 1024×1024px JPEG
            $message_data = array(
                'message' => $str,
                'imageThumbnail' => $image_thumbnail_url,
                'imageFullsize' => $image_fullsize_url,
            );
            $result = $this->send_notify_line($line_api, $line_token, $message_data);
            if ($str) {
                $token = Site::$cityLeaveToken;
                $this->sendTextToLineGroup($token, $str);
                //telegram
                $botToken = TelegramConfig::$botToken;
                $chatId = TelegramConfig::$chatIdLeave;
                // $this->sendTelegramMessage($botToken, $chatId, $str);
            }
            if ($result) {
                $obj = new stdClass();
                $obj->subject = "แจ้งลา";
                $obj->create_date = date('Y-m-d H:i:s');
                $db->insertObject("noti_leave_information", $obj);
            }
        }
    }



    public function sendReportLeaveCheck()
    {
        $db = getDBO();

        //check server มีปัญหา
        $curr_date = date('Y-m-d');
        $sql = "SELECT          * 
                FROM            noti_leave_information
                WHERE           DATE(create_date) = DATE({$curr_date})
                ORDER BY id DESC
                LIMIT 1";
        $db->setQuery($sql);
        $data = $db->loadAssocList();

        if (!$data) {
            $org_id = '1';
            $msg = '';
            $table = 'leave_' . $org_id . '_information';
            $table_cate = 'leave_' . $org_id . '_category';
            $curr_date = DATE('Y-m-d');
            $sql = "SELECT          * 
                    FROM            {$table}
                    WHERE           status = '1'
                    AND             status_leave = '2'
                    AND             DATE('{$curr_date}') BETWEEN `FirstDate` AND `LastDate`";
            $db->setQuery($sql);
            $rs = $db->loadAssocList();
            $len = count($rs);

            shortThaiDate($curr_date);

            if ($len > 0) {
                $msg = "วันนี้ " . $curr_date . " มีผู้ลา " . $len . " คน " . PHP_EOL;
                for ($i = 0; $i < $len; $i++) {
                    $uname = $this->getUsers($rs[$i]['create_by']);
                    $sql = "SELECT          cate_name 
                            FROM            {$table_cate}
                            WHERE           status = '1'
                            AND             id = '{$rs[$i]['cid']}'";
                    $db->setQuery($sql);
                    $catename = $db->loadAssocList();
                    $timeLeave = '';
                    if ($catename[0]['cate_name'] == "ลาย่อยระหว่างวัน") {
                        $timeLeave = substr($rs[$i]['firstTime'], 0, 5) . " - " . substr($rs[$i]['lastTime'], 0, 5) . " น.";
                    }
                    $msg .= ($i + 1) . ". " . str_replace(",", " ", $uname['fullname']) . " " . $catename[0]['cate_name'] . " " . $timeLeave . PHP_EOL;
                }
            } else {
                $msg = "วันนี้ " . $curr_date . " ไม่มีผู้ลา" . PHP_EOL;
            }
            pre($msg);
            exit();
        }
    }


    function checkTableNotUse()
    {
        ini_set('memory_limit', '4000M');
        $var = json_decode(file_get_contents('php://input'));
        $var = (array) $var;
        //-----
        $db = getDBO();
        $sql = "SELECT  * 
                FROM    org_information 
                WHERE   1";
        $db->setQuery($sql);
        $rs = $db->loadAssocList();
        $len = count($rs);
        if ($len > 0) {
            $no = 0;
            $no_data = 0;
            $table_drop = array();
            $table_drop_cate = array();
            $table_drop_file = array();
            $table_drop_mary = array();
            for ($i = 0; $i < $len; $i++) {
                $org_id = $rs[$i]['id'];
                $table = 'attend_' . $org_id . '_information';
                $sql = "SELECT  * 
                        FROM    {$table} 
                        WHERE   1";
                $db->setQuery($sql);
                $rs_data = $db->loadAssocList();
                $len_data = count($rs_data);
                if ($len_data) {
                    // echo "มีข้อมูลในตาราง {$table} <br>";
                    // $no_data++;
                    // pre($rs[$i]['subject']);
                    // pre($table);
                } else {
                    $sql = "SHOW TABLES LIKE '{$table}'";
                    $db->setQuery($sql);
                    $rs_table = $db->loadAssocList();
                    if ($rs_table) {
                        $no++;
                        echo "ไม่มีข้อมูลในตาราง {$table} <br>";
                    }
                    // $sql = "SELECT  * 
                    //         FROM    users 
                    //         WHERE   org_id = '{$org_id}'";
                    // $db->setQuery($sql);
                    // $rs_data2 = $db->loadAssocList();
                    // $len_data2 = count($rs_data2);

                    // // echo $len_data2;
                    // if (!$len_data2) {

                    //     $table_info = 'attend_' . $org_id . '_information';
                    //     $table_cate = 'attend_' . $org_id . '_category';
                    //     $table_file = 'attend_' . $org_id . '_attachments';
                    //     $table_mary = 'attend_' . $org_id . '_summary';

                    //     $sql = "SHOW TABLES LIKE '{$table_mary}'";
                    //     $db->setQuery($sql);
                    //     $rs_table = $db->loadAssocList();
                    //     if($rs_table){
                    //         $table_drop[] = $table_info;
                    //         $table_drop_cate[] = $table_cate;
                    //         $table_drop_file[] = $table_file;
                    //         $table_drop_mary[] = $table_mary;
                    //     }
                    // }
                }
            }
            echo "ไม่มีข้อมูลในตารางทั้งหมด {$no} ตาราง <br>";
            // $table_drop_sql = implode(", ", $table_drop_mary);
            // // pre($table_drop_sql);
            // $sql = "DROP TABLE {$table_drop_sql};";
            // $db->setQuery($sql);
            // echo $db->getQuery();
        }
    }

    public function debugNotification()
    {
        $package_name_ios = "com.cityvariety.ismartlogin";

        $id = 6500;
        $cid = 0;
        $fn_name = 'newsDetail';
        $subject = 'ทดสอบแจ้งเตือน';
        $description = 'ทดสอบแจ้งเตือน รายละเอียด';
        $menu = 'news';

        $notification = array(
            'title' => empty($description) ? '' : $subject,
            'body' => empty($subject) ? $description : $subject, // Required for iOS
        );

        $data = array(
            'title' => $subject,
            'body' => $description,
            'display_image' => '',
            'id' => '' . $id, // required
            'cid' => '' . $cid,
            'fn_name' => $fn_name, // required
            'subject' => $subject, // required
            'description' => $description,
            'menu' => $menu, // required
            'notificationID' => '' . rand(1, 999),
        );

        $badge =  $this->getBadgeNotiLeave("1", "59");
        $badge = intval($badge);

        $apns = array(
            'payload' => array(
                'aps' => array(
                    'alert' => array(
                        'title' => $data['title'],
                        'body' => $data['body'],
                    ),
                    'sound' => 'default',  // Sound for iOS
                    'badge' => $badge // Badge count for iOS app icon
                ),
            ),
        );

        $android = array(
            'notification' => array(
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
            ),
        );

        $message = array(
            'notification' => $notification,
            'data' => $data,
            'android' => $android,
            'apns' => $apns
        );

        $rs = array();

        $message['condition'] = "'{$package_name_ios}' in topics && 'users_17' in topics";
        $rs['send_target'] = $this->send_notification($message);

        pre($rs);
    }

    private function send_notification($message)
    {
        if (empty($message)) {
            return false;
        }

        $url = 'https://dashboard.cityvariety.co.th/firebase/cloud_messaging/send';
        $headers = array(
            'Content-Type: application/json',
        );

        $fields = array(
            'project_id' => 'lib-flutter',
            'data' => array('message' => $message),
            'debug_mode' => '1',
        );

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($fields));

        $result = curl_exec($ch);
        curl_close($ch);

        return $result;
    }


    function checkDataTableUseAll()
    {
        $db = getDBO();
        $sql = "SHOW TABLES FROM checkin_cv LIKE '%information%'";
        $db->setQuery($sql);
        $rs = $db->loadAssocList();
        // pre($rs);
        if ($rs) {
            $len = count($rs);
            for ($i = 0; $i < $len; $i++) {
                $table = $rs[$i]['Tables_in_checkin_cv (%information%)'];
                $sql = "SELECT  * 
                        FROM    {$table} 
                        WHERE   1
                        ORDER BY id DESC
                        LIMIT   1";
                $db->setQuery($sql);
                $rs_data = $db->loadAssocList();
                if ($rs_data) {
                    $create_date = $rs_data[0]['create_date'];
                    if ($create_date) {
                        $checkDate = new DateTime($create_date);
                        $checkDate->add(new DateInterval('P3M'));
                        $today = new DateTime();
                        if ($today >= $checkDate) {
                            $result = str_replace(['attend_', '_information'], '', $table);
                            if (ctype_digit($result)) {
                                $sql = "SELECT * 
                                       FROM    org_information 
                                       WHERE   id = '{$result}'";
                                $db->setQuery($sql);
                                $rs_org = $db->loadAssocList();
                                if ($rs_org) {
                                    if ($rs_org[0]['create_date']) {
                                        $date_check =  new DateTime('2024-08-01');
                                        $create_date_org = new DateTime($rs_org[0]['create_date']);
                                        if ($create_date_org < $date_check) {
                                            echo $result . '<br>';
                                            //delete table
                                            // $info = "attend_" . $result . "_information";
                                            // $cate = "attend_" . $result . "_category";
                                            // $file = "attend_" . $result . "_attachments";
                                            // $mary = "attend_" . $result . "_summary";
                                            // $sql = "DROP TABLE {$info}, {$cate}, {$file}, {$mary}";
                                            // $db->setQuery($sql);
                                            // $db->query();
                                            // // exit($db->getQuery());
                                            // //check status org
                                            // $sql = "UPDATE org_information 
                                            //         SET    status = '2' 
                                            //         WHERE  id = '{$result}'";
                                            // $db->setQuery($sql);
                                            // $db->query();
                                            // //update user org 
                                            // $sql = "UPDATE users 
                                            //         SET    org_id = '0' 
                                            //         WHERE  org_id = '{$result}'";
                                            // $db->setQuery($sql);
                                            // $db->query();
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    $result = str_replace(['attend_', '_information'], '', $table);
                    if (ctype_digit($result)) {
                        $sql = "SELECT * 
                                FROM    org_information 
                                WHERE   id = '{$result}'";
                        $db->setQuery($sql);
                        $rs_org = $db->loadAssocList();
                        if ($rs_org) {
                            if ($rs_org[0]['create_date']) {
                                $date_check =  new DateTime('2024-08-01');
                                $create_date_org = new DateTime($rs_org[0]['create_date']);
                                if ($create_date_org < $date_check) {
                                    echo $result . '<br>';
                                    //delete table
                                    // $info = "attend_" . $result . "_information";
                                    // $cate = "attend_" . $result . "_category";
                                    // $file = "attend_" . $result . "_attachments";
                                    // $mary = "attend_" . $result . "_summary";
                                    // $sql = "DROP TABLE {$info}, {$cate}, {$file}, {$mary}";
                                    // $db->setQuery($sql);
                                    // $db->query();
                                    // // exit($db->getQuery());
                                    // //check status org
                                    // $sql = "UPDATE org_information 
                                    //                 SET    status = '2' 
                                    //                 WHERE  id = '{$result}'";
                                    // $db->setQuery($sql);
                                    // $db->query();
                                    // //update user org 
                                    // $sql = "UPDATE users 
                                    //                 SET    org_id = '0' 
                                    //                 WHERE  org_id = '{$result}'";
                                    // $db->setQuery($sql);
                                    // $db->query();
                                }
                            }
                        }
                    }
                }
            }
        }
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

   public function getLogDataLogin()
    {
        $db = getDBO();
        
        // 1. ดึงรายชื่อองค์กร
        $sql = "SELECT org_id FROM `users` WHERE `status` = '1' AND org_id != '0' GROUP BY org_id";
        $db->setQuery($sql);
        $rs = $db->loadAssocList();
        
        // 2. กำหนดตัวแปร
        $yesterday = date('Y-m-d', strtotime('-1 day'));
        $yesterday_show = date('d/m/Y', strtotime('-1 day')); 
        
        // กำหนด Header ของข้อความ
        $header_msg = "📊 สรุปการใช้งาน IsmartLogin" . PHP_EOL . "📅 ประจำวันที่ " . $yesterday_show . PHP_EOL . "------------------" . PHP_EOL;
        
        $current_msg = $header_msg;
        $collected_data = array(); 
        
        if ($rs) {
            $len = count($rs);

            // --- Phase 1: เก็บข้อมูลลง Array ---
            for ($i = 0; $i < $len; $i++) {
                $org_id = $rs[$i]['org_id'];
                $table = 'attend_' . $org_id . '_information';
                $count_usage = 0;

                // เช็คตาราง
                $sql_check = "SHOW TABLES LIKE '{$table}'";
                $db->setQuery($sql_check);
                $table_exists = $db->loadAssocList();

                if ($table_exists) {
                    $sql = "SELECT count(id) AS total FROM {$table} WHERE DATE(create_date) = '{$yesterday}' AND status = '1'";
                    $db->setQuery($sql);
                    $rs_data = $db->loadAssocList();
                    if ($rs_data) {
                        $count_usage = intval($rs_data[0]['total']);
                    }
                }

                // ดึงชื่อองค์กร (เฉพาะที่มีคนใช้งาน > 0)
                if ($count_usage > 0) {
                    $sql_org = "SELECT subject FROM org_information WHERE id = '{$org_id}'";
                    $db->setQuery($sql_org);
                    $org_info = $db->loadAssocList();
                    
                    if ($org_info) {
                        $collected_data[] = array(
                            'name' => $org_info[0]['subject'],
                            'count' => $count_usage
                        );
                    }
                }
            }

            // --- Phase 2: เรียงลำดับข้อมูล (Sort Descending) ---
            if (!empty($collected_data)) {
                usort($collected_data, function($a, $b) {
                    return $b['count'] - $a['count']; // เรียงจาก มาก -> น้อย
                });

                // --- Phase 3: สร้างข้อความและทยอยส่ง ---
                foreach ($collected_data as $item) {
                    $line = "🏢 " . $item['name'] . " : " . $item['count'] . " คน" . PHP_EOL;
                    
                    // Logic ตัดแบ่งข้อความ (Pagination)
                    if (mb_strlen($current_msg . $line, 'UTF-8') > 900) {
                        $this->sendLineChunk($current_msg); // ส่งชุดเก่า
                        
                        // เริ่มชุดใหม่
                        $current_msg = "📊 สรุปการใช้งาน (ต่อ) ..." . PHP_EOL . "------------------" . PHP_EOL;
                    }
                    
                    $current_msg .= $line;
                }

                // ส่งชุดสุดท้ายที่เหลือ
                $this->sendLineChunk($current_msg);

                echo json_encode([
                    "status" => true, 
                    "msg" => "Sent sorted messages successfully (Filtered > 0)",
                    "total_active_orgs" => count($collected_data)
                ], JSON_UNESCAPED_UNICODE);

            } else {
                echo json_encode(["status" => false, "msg" => "No active usage found yesterday"]);
            }

        } else {
            echo json_encode(["status" => false, "msg" => "No organizations found"]);
        }
        exit();
    }

    // --- ฟังก์ชันย่อยสำหรับส่งไลน์ ---
    private function sendLineChunk($msg) {
        $line_token = "C7780f4fde1552d4e12b438ea6555552f"; 
        $this->sendTextToLineGroup($line_token, $msg);
    }
}
