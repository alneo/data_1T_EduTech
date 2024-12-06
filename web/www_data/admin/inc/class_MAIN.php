<?php
class class_MAIN{
    private $DB,$chpu,$URLS,$PGDB;
    function __construct(){
        GLOBAL $ST,$DB;
        $this->DB = $DB;
        if(isset($params['html'])&&$params['html']==0){}else {
            $this->chpu = new class_CHPU('admin');
            $CHPU = new class_CHPU('admin');
            $this->URLS = $CHPU->uri();
        }
    }
    function HTML($params){
        $out=array();
        if(isset($params['smarty'])){
            $smarty = $params['smarty'];
        }
        //unset($_SESSION['range']);
        if(isset($_POST['range_set'])){
            $_SESSION['range']['start'] = strtotime($_POST['range_start']);
            $_SESSION['range']['end'] = strtotime($_POST['range_end']);
            $_SESSION['range']['course_sel'] = (int)$_POST['course_id'];
        }
        if(!isset($_SESSION['range'])) {
            $start = mktime(0,0,0,date('m'),date('d')-7,date('Y'));
            $end = mktime(0,0,0,date('m'),date('d'),date('Y'));
            $_SESSION['range'] = array('start'=>$start,'end'=>$end,'course_sel'=>77);
        }
        $smarty->assign('range',$_SESSION['range']);

        $des = 'view';
        $out['title'] = 'Главная';
        $out['name'] = 'Главная';

        if(isset($_SESSION['user'])){
            $smarty->assign('aUSER',$_SESSION['user']);
        }else{
            $smarty->assign('aUSER',array());
        }
        if($des=='view'){
            $smarty->assign('courses',$this->courses_get());
            $smarty->assign('info',$this->PG_info());
        }
        $out['body'] = $smarty->fetch('page_main.html');

        return $out;
    }
    function PG_connect(){
        GLOBAL $ST;
        $this->PGDB = new class_PGSQL($ST['PGSQL']['host'], $ST['PGSQL']['database'], $ST['PGSQL']['user'], $ST['PGSQL']['password'],$ST['PGSQL']['port']);
    }

    /**
     * Получение массива курсов
     * @return array
     */
    function courses_get(){
        $out = array();
        $this->PG_connect();
        $result = $this->PGDB->QUR_SEL('select course_id,name from courses_v2 order by name;');
        $this->PGDB->closeConnection();
        if ($result['err'] == 0) {
            foreach($result['rez'] as $k => $v){
                $out[$v['course_id']] = $v['name'];
            }
        }
        return $out;
    }

    function PG_info(){
        $out = array();
        $this->PG_connect();
        $out['courses']=$this->courses_get();
        $course_id = $_SESSION['range']['course_sel'];

        //Определим начало и конец курса
        $sql = "select min(date_shown) start_data, (min(date_shown) + INTERVAL '10 weeks') finish_data from public.schedule_v2 where course_id = ".$course_id.";";
        $this->PG_connect();
        $result_korse_datas = $this->PGDB->QUR_SEL($sql);
        $this->PGDB->closeConnection();

        $key = 'glu0';
        $out[$key] = array();
        if ($result_korse_datas['err'] == 0) {
            $start_date_kurs = date('Y-m-d',strtotime($result_korse_datas['rez'][0]['start_data']));
            $finish_date_kurs = date('Y-m-d',strtotime($result_korse_datas['rez'][0]['finish_data']));
            $dt1 = date('Y-m-d', $_SESSION['range']['start']);
            $dt2 = date('Y-m-d', $_SESSION['range']['end']);
            $m1 = array(':course_id', ':start_date', ':finish_date', ':start_kurs_date', ':finish_kurs_date');
            $m2 = array($course_id, "'" . $dt1 . "'", "'" . $dt2 . "'", "'" . $start_date_kurs . "'", "'" . $finish_date_kurs . "'");
            $sql = str_replace($m1, $m2, file_get_contents('sqls/main_graph_01.sql'));
            //:course_id=3 :start_date='2024-01-12' :finish_date='2024-01-26' :start_kurs_date='2023-12-01' :finish_kurs_date='2024-06-30'

            $cache = $this->cache_check($sql);
            if (!count($cache)) {
                $this->PG_connect();
                $result = $this->PGDB->QUR_SEL($sql);
                $this->PGDB->closeConnection();
                if ($result['err'] == 0) {
                    $out[$key] = $result['rez'];
                } else {
                    $out[$key] = array();
                }
                $this->cache_check($sql, $out);
            } else {
                $out[$key] = $cache[$key];
            }
        }

        $key = 'inga1';
        $out[$key] = array();
        $dt1 = date('Y-m-d', $_SESSION['range']['start']);
        $dt2 = date('Y-m-d', $_SESSION['range']['end']);
        $m1 = array(':course_id', ':start_date', ':finish_date');
        $m2 = array($course_id, "'" . $dt1 . "'", "'" . $dt2 . "'");
        $sql = str_replace($m1, $m2, file_get_contents('sqls/main_graph_02.sql'));
        //:course_id=77 :start_date=2023-12-01 :finish_date=2024-01-30

        $cache = $this->cache_check($sql);
        if (!count($cache)) {
            $this->PG_connect();
            $result = $this->PGDB->QUR_SEL($sql);
            $this->PGDB->closeConnection();
            if ($result['err'] == 0) {
                $out[$key] = $result['rez'];
            } else {
                $out[$key] = array();
            }
            $this->cache_check($sql, $out);
        } else {
            $out[$key] = $cache[$key];
        }
        $out[$key.'_dt']=array();
        foreach($out[$key] as $k => $v){
            $out[$key.'_dt']['labels'][] = $v['year_week'];
            $out[$key.'_dt']['values'][] = $v['view_act'];
        }
        unset($out[$key]);
        if(!isset($out[$key.'_dt']['labels'])) $out[$key.'_dt']['labels'] = array();
        if(!isset($out[$key.'_dt']['values'])) $out[$key.'_dt']['values'] = array();
        $out[$key]['labels'] = "'".implode("','",$out[$key.'_dt']['labels'])."'";
        $out[$key]['values'] = implode(',',$out[$key.'_dt']['values']);
        unset($out[$key.'_dt']);

        $key = 'glu3';
        $out[$key] = array();
        if ($result_korse_datas['err'] == 0) {
            $start_date_kurs = date('Y-m-d',strtotime($result_korse_datas['rez'][0]['start_data']));
            $finish_date_kurs = date('Y-m-d',strtotime($result_korse_datas['rez'][0]['finish_data']));
            $dt1 = date('Y-m-d', $_SESSION['range']['start']);
            $dt2 = date('Y-m-d', $_SESSION['range']['end']);
            $m1 = array(':course_id', ':start_date', ':finish_date', ':start_kurs_date', ':finish_kurs_date');
            $m2 = array($course_id, "'" . $dt1 . "'", "'" . $dt2 . "'", "'" . $start_date_kurs . "'", "'" . $finish_date_kurs . "'");
            $sql = str_replace($m1, $m2, file_get_contents('sqls/main_graph_04.sql'));
            //:course_id=49 :start_date='2023-12-01' :finish_date='2023-12-28'
            $cache = $this->cache_check($sql);
            if (!count($cache)) {
                $this->PG_connect();
                $result = $this->PGDB->QUR_SEL($sql);
                $this->PGDB->closeConnection();
                if ($result['err'] == 0) {
                    $out[$key] = $result['rez'];
                } else {
                    $out[$key] = array();
                }
                $this->cache_check($sql, $out);
            } else {
                $out[$key] = $cache[$key];
            }
            $out[$key . '_dt'] = array();
            $i = 0;
            foreach ($out[$key] as $k => $v) {
                $out[$key . '_dt']['labels'][] = $v['k_day'];
                $out[$key . '_dt']['sleept'][] = $v['sleept'];
                $out[$key . '_dt']['zasyp'][] = $v['zasyp'];
                $out[$key . '_dt']['activ'][] = $v['activ'];
            }
            unset($out[$key]);
            if (!isset($out[$key . '_dt']['labels'])) $out[$key . '_dt']['labels'] = array();
            if (!isset($out[$key . '_dt']['sleept'])) $out[$key . '_dt']['sleept'] = array();
            if (!isset($out[$key . '_dt']['zasyp'])) $out[$key . '_dt']['zasyp'] = array();
            if (!isset($out[$key . '_dt']['activ'])) $out[$key . '_dt']['activ'] = array();
            $out[$key]['labels'] = "'" . implode("','", $out[$key . '_dt']['labels']) . "'";
            $out[$key]['sleept'] = implode(',', $out[$key . '_dt']['sleept']);
            $out[$key]['zasyp'] = implode(',', $out[$key . '_dt']['zasyp']);
            $out[$key]['activ'] = implode(',', $out[$key . '_dt']['activ']);
            unset($out[$key . '_dt']);
        }

        $key = 'dimz01';
        $out[$key] = array();
        $sql = 'SELECT data_create, AVG(value) AS avg_value FROM model_stats where model_info = \'project_1911\' GROUP BY data_create ORDER BY data_create;';
        $cache = $this->cache_check($sql);
        if (!count($cache)) {
            $this->PG_connect();
            $result = $this->PGDB->QUR_SEL($sql);
            $this->PGDB->closeConnection();
            if ($result['err'] == 0) {
                $out[$key] = $result['rez'];
            } else {
                $out[$key] = array();
            }
            $this->cache_check($sql, $out);
        } else {
            $out[$key] = $cache[$key];
        }
        $out[$key.'_dt']=array();
        $i=0; foreach($out[$key] as $k => $v){
            if($i==0) {
                $out[$key . '_dt']['labels'][] = date('d.m.Y',strtotime($v['data_create']));
                $out[$key . '_dt']['values'][] = round($v['avg_value'],2);
            }
            $i++; if($i==7) $i=0;
        }
        unset($out[$key]);
        $out[$key]['labels'] = "'".implode("','",$out[$key.'_dt']['labels'])."'";
        $out[$key]['values'] = implode(',',$out[$key.'_dt']['values']);
        unset($out[$key.'_dt']);

        $key = 'dimz02';
        $out[$key] = array();
        $sql = 'SELECT day_num AS "time", PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY value) AS q1, PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY value) AS median, PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY value) AS q3 FROM model_stats where model_info = \'project_1911\' GROUP BY day_num ORDER BY day_num;';
        $cache = $this->cache_check($sql);
        if (!count($cache)) {
            $this->PG_connect();
            $result = $this->PGDB->QUR_SEL($sql);
            $this->PGDB->closeConnection();
            if ($result['err'] == 0) {
                $out[$key] = $result['rez'];
            } else {
                $out[$key] = array();
            }
            $this->cache_check($sql, $out);
        } else {
            $out[$key] = $cache[$key];
        }
        $out[$key.'_dt']=array();
        $i=0; foreach($out[$key] as $k => $v){
            $out[$key . '_dt']['labels'][] = $v['time'];
            $out[$key . '_dt']['q1'][] = round($v['q1'],2);
            $out[$key . '_dt']['median'][] = round($v['median'],2);
            $out[$key . '_dt']['q3'][] = round($v['q3'],2);
        }
        unset($out[$key]);
        $out[$key]['labels'] = "'".implode("','",$out[$key.'_dt']['labels'])."'";
        $out[$key]['q1'] = implode(',',$out[$key.'_dt']['q1']);
        $out[$key]['median'] = implode(',',$out[$key.'_dt']['median']);
        $out[$key]['q3'] = implode(',',$out[$key.'_dt']['q3']);
        unset($out[$key.'_dt']);

        return $out;
    }

    /**
     * Проверка существования кэша, если есть data то сохранение
     * TODO: или оптимизировать запросы или обновлять кэш!
     * @param $sql (string)
     * @param $data (array)
     * @return (array)
     */
    function cache_check($sql,$data=array()){
        $cache_file = __DIR__.'/../cache/'.md5($sql).'.json';
        if(count($data)){
            file_put_contents($cache_file,json_encode($data,JSON_UNESCAPED_UNICODE));
            return array();
        }else {
            if (file_exists($cache_file)) {
                return json_decode(file_get_contents($cache_file), 1);
            } else {
                return array();
            }
        }
    }
}