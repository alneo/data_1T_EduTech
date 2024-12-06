<?php
class class_STUDENTS{
    private $DB,$PGD,$URLS,$chpu,$PGDB;
    function __construct(){
        GLOBAL $ST,$DB;
        $this->DB = $DB;
        if(isset($params['html'])&&$params['html']==0){

        }else {
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
        $des = 'view';
        $path = '/admin/'.$params['url'].'/';
        $PAGE['title'] = $params['name'] = $params['page_name'];
        if (isset($this->URLS[1])) {
            $des = $this->URLS[1];
        }

        $out['title'] = 'Главная';
        $out['name'] = 'Главная';

        if(isset($_POST['ajdes'])){
            header('Content-Type: application/json; charset=utf-8');
            $out=array();
            if($_POST['ajdes']=='date_cur_change'){
                $_SESSION['date_cur'] = $_POST['date'];
                $out['err']=0;
            }
            echo json_encode($out);
            exit();
        }

        if(isset($_SESSION['user'])){
            $smarty->assign('aUSER',$_SESSION['user']);
        }else{
            $smarty->assign('aUSER',array());
        }

        if($des=='user'){
            $id_user = (int)$this->URLS[2];
            $student = $this->PG_user_get($id_user);
            $smarty->assign('student',$student);
        }
        if($des=='view'){
            //сброс фильтрации
            if(isset($_POST['filter_clear'])){
                $_SESSION['filter'] = array(
                    'filter_kurs'=>array(),
                    'filter_status'=>array(),
                    'filter_pa_status_start'=>-100,
                    'filter_pa_status_end'=>100,
                    'filter_pa_kurs_start'=>0,
                    'filter_pa_kurs_end'=>100,
                    'filter_date'=>date('d.m.Y'),
                );
            }
            //сохранение фильтрации
            if(isset($_POST['filter_do'])){
                $_SESSION['filter'] = $_POST;//TODO: перепроверить данные пользователя!
            }

            if(!$_SESSION['filter']['filter_kurs']) $_SESSION['filter']['filter_kurs']=array();
            if(!$_SESSION['filter']['filter_date']) $_SESSION['filter']['filter_date']='02.12.2023';
            $smarty->assign('filter',$_SESSION['filter']);
            $smarty->assign('students',$this->PG_users_get(50));
            $smarty->assign('courses',$this->courses_get());
        }
        $smarty->assign('des',$des);
        $out['body'] = $smarty->fetch('page_students.html');

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
    function PG_user_get($id_user){
        $out = array();
        if(!isset($_SESSION['students'][$id_user])) {
            $_SESSION['students'][$id_user] = 'Не определили';
        }
        $out['fio'] = $_SESSION['students'][$id_user];

        $sql = 'SELECT us.user_id,us.tg_bot,cv."name" as kurs FROM users_v2 us, courses_v2 cv where us.course_id=cv.course_id AND us.user_id=' . $id_user;
        $cache = $this->cache_check($sql);
        if(!count($cache)) {
            $this->PG_connect();
            $result = $this->PGDB->QUR_SEL($sql);
            $this->PGDB->closeConnection();
            if ($result['err'] == 0) {
                $out['info'] = $result['rez'];
            } else {
                $out['info'] = array();
            }
            $this->cache_check($sql,$out);
        }else{
            $out['info'] = $cache['info'];
        }
        $sql = 'SELECT created_at,user_agent,window_size FROM authorization_v2 where user_id=' . $id_user.' ORDER BY created_at DESC LIMIT 10';
        $cache = $this->cache_check($sql);
        if(!count($cache)) {
            $this->PG_connect();
            $result = $this->PGDB->QUR_SEL($sql);
            $this->PGDB->closeConnection();
            if ($result['err'] == 0) {
                $out['auth'] = $result['rez'];
            } else {
                $out['auth'] = array();
            }
            $this->cache_check($sql,$out);
        }else{
            $out['auth'] = $cache['auth'];
        }

        $sql = 'with one_user as(
            select user_id, page_id activity_id, attestation 
            from activity_history_viewed_v2 ahvv 
            where (user_id = ' . $id_user.') and (page_type <> \'занятие\')),
        one_user_acts as(select distinct(ou.*), case when erv.result = \'Пропуск\' then 0 else cast(erv.result as int4) end as result,
            erv.success, agv.att_priznak, agv.obyaz_priznak 
        from one_user ou left join exercise_results_v2 as erv --(select * from exercise_results_v2 where success = 1)
            on ou.user_id = erv.user_id and ou.activity_id = erv.activity_id 
        left join activities_guide_v2 agv on erv.activity_id = agv.activity_id)
        select count(distinct activity_id) filter(where att_priznak=0) sum_task_id,
            count(distinct activity_id) filter(where obyaz_priznak = 1 and att_priznak=0) sum_obyaz_activity,
            count(distinct activity_id) filter(where obyaz_priznak = 0) sum_neobyaz_activivty,
            avg(result) avg_result, max(uv.m2_attestation) attestation, max(uv.m2_progress)  progress
        from one_user_acts oua left join users_v2 uv on oua.user_id = uv.user_id';
        $cache = $this->cache_check($sql);
        if(!count($cache)) {
            $this->PG_connect();
            $result = $this->PGDB->QUR_SEL($sql);
            $this->PGDB->closeConnection();
            if ($result['err'] == 0) {
                $out['tasks'] = $result['rez'];
            } else {
                $out['tasks'] = array();
            }
            $this->cache_check($sql,$out);
        }else{
            $out['tasks'] = $cache['tasks'];
        }
        if($out['tasks'][0]['attestation']=='Не сдана') $out['tasks'][0]['attestation']=0;
        if($out['tasks'][0]['progress']=='Нет данных') $out['tasks'][0]['progress']=0;

        $sql = 'select 
            ahv2.created_at,ahv2.page_type,ahv2.module,ahv2.attestation,ahv2.activity_type,
            ag2.course,ag2.theme,ag2.exercise,ag2.activity_type,ag2.activity,ag2.obyaz_priznak
        from 
            activity_history_viewed_v2 as ahv2, 
            activities_guide_v2 as ag2 
        where 
            ahv2.user_id = ' . $id_user.' AND
            ag2.activity_id = ahv2.page_id
        ORDER BY ahv2.created_at DESC LIMIT 10';
        $cache = $this->cache_check($sql);
        if(!count($cache)) {
            $this->PG_connect();
            $result = $this->PGDB->QUR_SEL($sql);
            $this->PGDB->closeConnection();
            if ($result['err'] == 0) {
                $out['activity'] = $result['rez'];
            } else {
                $out['activity'] = array();
            }
            $this->cache_check($sql,$out);
        }else{
            $out['activity'] = $cache['activity'];
        }

        $sql = 'select 
            wbl.datetime,wbl.event_name,wbl.conn_format,wbl.webinar_vvod,
            ag2.course,ag2.theme,ag2.exercise,ag2.activity_type,ag2.activity,ag2.obyaz_priznak
        from 
            webinars_logs_v2 as wbl, 
            activities_guide_v2 as ag2 
        where 
            wbl.user_id = ' . $id_user.' AND wbl.event_name=\'Подключение\' AND
            ag2.activity_id = wbl.webinar_id
        ORDER BY wbl.datetime DESC LIMIT 10';
        $cache = $this->cache_check($sql);
        if(!count($cache)) {
            $this->PG_connect();
            $result = $this->PGDB->QUR_SEL($sql);
            $this->PGDB->closeConnection();
            if ($result['err'] == 0) {
                $out['webinars'] = $result['rez'];
            } else {
                $out['webinars'] = array();
            }
            $this->cache_check($sql,$out);
        }else{
            $out['webinars'] = $cache['webinars'];
        }

        $sql = 'select 
            exr2.created_at,exr2.result,exr2.success,
            ag2.course,ag2.theme,ag2.exercise,ag2.activity_type,ag2.activity,ag2.obyaz_priznak
        from 
            exercise_results_v2 as exr2, 
            activities_guide_v2 as ag2 
        where 
            exr2.user_id = ' . $id_user.' AND
            ag2.activity_id = exr2.activity_id
        ORDER BY exr2.created_at DESC LIMIT 10';
        $cache = $this->cache_check($sql);
        if(!count($cache)) {
            $this->PG_connect();
            $result = $this->PGDB->QUR_SEL($sql);
            $this->PGDB->closeConnection();
            if ($result['err'] == 0) {
                $out['exercise'] = $result['rez'];
            } else {
                $out['exercise'] = array();
            }
            $this->cache_check($sql,$out);
        }else{
            $out['exercise'] = $cache['exercise'];
        }


        $sql = 'select 
            exr2.created_at,exr2.result,exr2.success,
            ag2.course,ag2.theme,ag2.exercise,ag2.activity_type,ag2.activity,ag2.obyaz_priznak
        from 
            exercise_results_v2 as exr2, 
            activities_guide_v2 as ag2 
        where 
            exr2.user_id = ' . $id_user.' AND
            ag2.activity_id = exr2.activity_id
        ORDER BY exr2.created_at DESC LIMIT 10';
        $cache = $this->cache_check($sql);
        if(!count($cache)) {
            $this->PG_connect();
            $result = $this->PGDB->QUR_SEL($sql);
            $this->PGDB->closeConnection();
            if ($result['err'] == 0) {
                $out['exercise'] = $result['rez'];
            } else {
                $out['exercise'] = array();
            }
            $this->cache_check($sql,$out);
        }else{
            $out['exercise'] = $cache['exercise'];
        }

        $out['state'] = $this->state_get($id_user);
        $out['info1'] = $this->uspev_get($id_user);

        $out['profile'] = $this->student_profile($id_user);
        $out['history'] = $this->history_get($id_user);

        return $out;
    }
    function PG_users_get($kol=100){
        $out = array();
        $this->PG_connect();

        $filter_date = date('Y-m-d', strtotime($_SESSION['filter']['filter_date']));

        $success_ot = round($_SESSION['filter']['filter_pa_kurs_start']/100,2);
        $success_do = round($_SESSION['filter']['filter_pa_kurs_end']/100,2);
        if($success_ot=='') $success_ot=0;
        if($success_do=='') $success_do=0.99;
        if(isset($_SESSION['filter']['filter_status'])){
            $statuss = implode(',',$_SESSION['filter']['filter_status']);
        }else{
            $statuss = implode(',',array(0,1,2));
        }

        $m1 = array(':courses_id', ':filter_date',':success_ot',':success_do',':statuss');
        $m2 = array(implode(',',$_SESSION['filter']['filter_kurs']), "'" . $filter_date . "'",$success_ot,$success_do,$statuss);
        $sql = str_replace($m1, $m2, file_get_contents('sqls/students_list.sql'));

        $result = $this->PGDB->QUR_SEL($sql);
        $this->PGDB->closeConnection();
        if ($result['err'] == 0) {
            $out['err'] = 0;
            $out['kol'] = $result['kol'];
            foreach ($result['rez'] as $k => $row) {
                $row['m2_success'] = $this->user_get_m2_success($row['user_id'],$_SESSION['filter']['filter_date']);
                $row['m2_progress'] = $this->user_get_m2_progress($row['user_id'],$_SESSION['filter']['filter_date']);
                $out['items'][$row['user_id']] = $row;
                $out['items'][$row['user_id']]['state'] = $this->state_get($row['user_id']);
                $out['items'][$row['user_id']]['pa_state'] = $this->pa_state_get($row['user_id']);
                $out['items'][$row['user_id']]['info'] = $this->uspev_get($row['user_id']);
            }
        } else {
            $out['err'] = 1;
            $out['kol'] = 0;
            $out['msg'] = $result['msg'];
            $out['items'] = array();
        }
        return $out;
    }
    
    /**
     * Получение данных о пользователе на конкретную дату
     * @param $user_id
     * @param $date
     * @return array
     */
    function user_get_m2_progress($user_id, $date){
        $out = array();
        $out['date'] = $date;
        $out['result'] = 0;
        $date_cr = date('Y-m-d',strtotime($date)).' 00:00:00.000';

        $this->PG_connect();
        $sql = 'SELECT * FROM model_stats where id_user = '.$user_id.' and data_create=\''.$date_cr.'\' AND model_info = \'project_1911\' ORDER BY id DESC';
        $result = $this->PGDB->QUR_SEL($sql);
        $this->PGDB->closeConnection();
        if ($result['err'] == 0) {
            if(count($result['rez'])){
                $out['result'] = $result['rez'][0]['value'];
            }
        }else{
            $out['result'] = 0;
        }
        return $out;
    }

    /**
     * Получение данных о пользователе на конкретную дату m2_success
     * @param $user_id
     * @param $date
     * @return array
     */
    function user_get_m2_success($user_id, $date){
        $out = array();
        $out['date'] = $date;
        $out['result'] = 0;
        $date_cr = date('Y-m-d',strtotime($date)).' 00:00:00.000';

        $this->PG_connect();
        //$sql = 'SELECT * FROM model_stats where id_user = '.$user_id.' and data_create=\''.$date_cr.'\' AND model_info = \'project_2411_clf\' AND metrika = \'m2_success\' ORDER BY id DESC';
        //Выберем предыдущее значение, чтобы показать динамику
        $sql = 'SELECT * FROM model_stats where id_user = '.$user_id.' and data_create<=\''.$date_cr.'\' AND model_info = \'project_2411_clf\' AND metrika = \'m2_success\' ORDER BY id ASC LIMIT 7';
        $result = $this->PGDB->QUR_SEL($sql);
        $this->PGDB->closeConnection();
        if ($result['err'] == 0) {
            if(count($result['rez'])){
                $out['result1'] = round(($result['rez'][0]['value']*100),2);//7 дней назад
                $out['result2'] = round(($result['rez'][6]['value']*100),2);//текущий день
            }
        }else{
            $out['result1'] = 0;
            $out['result2'] = 0;
        }
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

    function students_temp(){
        $students = file('students.txt');
        return $students;
    }

    function student_profile($id_user){
        $cache_file = __DIR__.'/../cache/profiles_'.$id_user.'.json';
        if(!file_get_contents($cache_file)) {
            $json = file_get_contents('https://randomuser.me/api/?seed=' . $id_user);
        }else{
            $json = file_get_contents($cache_file);
        }
        $out = json_decode($json,1);
        return $out['results'][0];
    }

    function state_get($user_id){//TODO: пересмотреть необходимость! pa_state_get тоже получаем текущий статус!
        $out = array();
        $this->PG_connect();
        $filter_date = date('Y-m-d', strtotime($_SESSION['filter']['filter_date']));
        $sql = 'SELECT status FROM table_glu_dt_v3 WHERE k_day = \''.$filter_date.'\'::date and user_id = '.$user_id;
        $result = $this->PGDB->QUR_SEL($sql);
        $this->PGDB->closeConnection();
        if ($result['err'] == 0) {
            $out['err'] = 0;
            $out['status'] = $result['rez'][0]['status'];
        }else{
            $out['err'] = 1;
            $out['status'] = -1;
        }
        return $out;
    }

    /**
     * Вероятность смены статуса
     * @param $user_id
     * @return array
     */
    function pa_state_get($user_id){
        $out = array();
        $filter_date = date('Y-m-d', strtotime($_SESSION['filter']['filter_date']));
        $m1 = array(':date_cur', ':user_id');
        $m2 = array("'".$filter_date."'",$user_id);
        $sql = str_replace($m1, $m2, file_get_contents('sqls/students_pa_status.sql'));
        $this->PG_connect();
        $result = $this->PGDB->QUR_SEL($sql);
        $this->PGDB->closeConnection();
        if ($result['err'] == 0) {
            $out['err'] = 0;
            $out['status'] = $result['rez'][0]['status'];
            $out['case'] = $result['rez'][0]['case'];
        }else{
            $out['err'] = 1;
            $out['status'] = -1;
            $out['case'] = '';
        }
        return $out;
    }

    function uspev_get($user_id){
        $out = array();
        $out['err'] = 0;
        //--Успеваемость-средний балл
        $sql = 'select avg(case when result = \'Пропуск\' then 0 else result::int end)::int as "uspev" from exercise_results_v2 where user_id='.$user_id;
        $cache = $this->cache_check($sql);
        if(!count($cache)) {
            $this->PG_connect();
            $result = $this->PGDB->QUR_SEL($sql);
            $this->PGDB->closeConnection();
            if ($result['err'] == 0) {
                $out['uspev'] = $result['rez'][0]['uspev'];
                if ($out['uspev'] == '') $out['uspev'] = 0;
            } else {
                $out['uspev'] = 0;
            }
            $this->cache_check($sql,$out);
        }else{
            $out['uspev'] = $cache['uspev'];
        }

        //--Успеваемость-прогресс. Формула: Кол-во сделанных  оцениваемых заданий / кол-во всех оцениваемых заданий по расписанию) * 100%
        $sql = 'with t1 as( select user_id
        	, count(distinct activivty_id) filter(where obyaz_priznak=1 and is_attestation=0 and result_time is not null) sum_required_exercises
        	, count(distinct activivty_id) filter(where obyaz_priznak=1 and is_attestation=0) sum_required_activity from public.dataset_h_v3
        group by 1 ) select round((1.0*sum_required_exercises/sum_required_activity * 100), 2) "prog_ob_proc" from t1 where user_id='.$user_id;
        $cache = $this->cache_check($sql);
        if(!count($cache)) {
            $this->PG_connect();
            $result = $this->PGDB->QUR_SEL($sql);
            $this->PGDB->closeConnection();
            if ($result['err'] == 0) {
                $out['prog_ob_proc'] = $result['rez'][0]['prog_ob_proc'];
                if($out['prog_ob_proc']=='') $out['prog_ob_proc'] = 0;
            }else{
                $out['prog_ob_proc'] = 0;
            }
            $this->cache_check($sql,$out);
        }else{
            $out['prog_ob_proc'] = $cache['prog_ob_proc'];
        }
        return $out;
    }
    function history_get($user_id){
        $out = array();
        $out['err'] = 0;
        $out['act_obyaz_ch1']['labels'] = array();
        $out['act_obyaz_ch1']['data'] = array();
        $out['act_obyaz_ch2']['labels'] = array();
        $out['act_obyaz_ch2']['data'] = array();
        $out['act_obyaz_ch3']['labels'] = array();
        $out['act_obyaz_ch3']['data'] = array();
        //--Кол-во просмотров  обязательных activity_id (sum_required_activity_viewed)
        $sql = 'select date_shown, count(distinct created_at) kol from public.dataset_h_v3 where obyaz_priznak=1 and is_attestation=0 and  user_id = '.$user_id.' group by date_shown';
        $sql = 'select date_shown 
  , count(distinct created_at) filter(where obyaz_priznak=1 and is_attestation=0) as view_obyaz_activity
  , count(distinct created_at) filter(where obyaz_priznak=0) as view_neobyaz_activity
  , count(distinct created_at) filter(where is_attestation=1) as view_attestation_activity
from public.dataset_h_v3 where created_at < current_date and user_id ='.$user_id.' group by date_shown;';
        $cache = $this->cache_check($sql);
        if(!count($cache)) {
            $this->PG_connect();
            $result = $this->PGDB->QUR_SEL($sql);
            $this->PGDB->closeConnection();
            if ($result['err'] == 0) {
                foreach($result['rez'] as $k => $v){
                    $v['date_shown'] = date('d.m.Y',strtotime($v['date_shown']));
                    $out['act_obyaz_ch1']['labels'][]=$v['date_shown'];
                    $out['act_obyaz_ch1']['data'][]=$v['view_obyaz_activity'];
                    $out['act_obyaz_ch2']['labels'][]=$v['date_shown'];
                    $out['act_obyaz_ch2']['data'][]=$v['view_neobyaz_activity'];
                    $out['act_obyaz_ch3']['labels'][]=$v['date_shown'];
                    $out['act_obyaz_ch3']['data'][]=$v['view_attestation_activity'];
                }
            } else {
                $out['act_obyaz_ch1']['labels']=array();
                $out['act_obyaz_ch1']['data']=array();
                $out['act_obyaz_ch2']['labels']=array();
                $out['act_obyaz_ch2']['data']=array();
                $out['act_obyaz_ch3']['labels']=array();
                $out['act_obyaz_ch3']['data']=array();
            }
            $this->cache_check($sql,$out);
        }else{
            $out['act_obyaz_ch1'] = $cache['act_obyaz_ch1'];
            $out['act_obyaz_ch2'] = $cache['act_obyaz_ch2'];
            $out['act_obyaz_ch3'] = $cache['act_obyaz_ch3'];
        }
        if(!is_array($out['act_obyaz_ch1']['labels'])) $out['act_obyaz_ch']['labels'] = array();
        if(!is_array($out['act_obyaz_ch1']['data'])) $out['act_obyaz_ch']['data'] = array();
        if(!is_array($out['act_obyaz_ch2']['labels'])) $out['act_obyaz_ch']['labels'] = array();
        if(!is_array($out['act_obyaz_ch2']['data'])) $out['act_obyaz_ch']['data'] = array();
        if(!is_array($out['act_obyaz_ch3']['labels'])) $out['act_obyaz_ch']['labels'] = array();
        if(!is_array($out['act_obyaz_ch3']['data'])) $out['act_obyaz_ch']['data'] = array();

        return $out;
    }

    /**
     * Получение информации по студенту id_user(int) на дату date(string)
     * @param $param
     * @return array
     */
    function student_get_info($param){
        $id_user=0; if(isset($param['id_user'])) $id_user = (int)$param['id_user'];
        $date=''; if(isset($param['date'])) $date = strtotime($param['date']);
        $out = array();

        //Коллеги, всем привет! Поскольку  возник вопрос об оперативном формировании срезов по времени с помощью чистого SQL для вывода данных на веб-интерфейс, я сделал скрипт SQL, который:
        //1) не использует готовые датасеты/вьюшки и обращается только к исходным таблицам
        //2) считает несколько метрик на каждый день курса (метрики можно добавить еще)
        //     - общая задержка выполнения обязательных заданий в днях на дату среза,
        //     - количество выполненных обязательных заданий на дату среза,
        //     - количество выполненных необязательных заданий на дату среза,
        //     - текущий прогресс по формуле, которую вывела Люба,
        //3) нет фильтра по студентам, т.к. в веб-интерфейсе это не нужно,
        //4) работает очень быстро, хотя уверен, его еще можно оптимизировать дополнительно
        //
        //Могут быть незначительные расхождения, связанные с разной логикой в моем расчете и в других датасетах, т.к. где-то может стоять знак "больше", а где-то "больше или равно" или по другому учитываются флаги. Если что, это все поправимо для приведения к общим итогам.
        //@ryurikovich_37
        $sql = 'with success_acts as (
    select user_id, activity_id, min(created_at) first_success
    from exercise_results_v2 erv 
    where (success = 1) and (activity_id is not null)
    group by user_id, activity_id  
), first_views as(
    select user_id, page_id activity_id, attestation, min(created_at) first_view
    from activity_history_viewed_v2
    where page_type = \'активность\'
    group by user_id, activity_id, attestation
),schedule as(
    select course_id, activivty_id, date_shown 
    from schedule_v2 sv
    where (type = \'активность\')
),schedule_plus as(
    select sc.course_id, agv.activity_id, sc.date_shown, agv.obyaz_priznak, agv.att_priznak 
    from schedule sc
    join activities_guide_v2 agv 
    on (sc.activivty_id = agv.activity_id) 
),all_acts as(
    select user_id, uv.course_id, activity_id, date_shown, obyaz_priznak, att_priznak
    from users_v2 uv
    full outer join schedule_plus as sch
    on uv.course_id = sch.course_id
),all_activities as(
    select aa.user_id, aa.course_id, aa.activity_id, date_shown, obyaz_priznak, att_priznak, first_success, first_view
    from all_acts aa
    left join success_acts sa
    on (aa.user_id) = (sa.user_id) and (aa.activity_id) = (sa.activity_id)
    left join first_views fa
    on (aa.user_id) = (fa.user_id) and (aa.activity_id) = (fa.activity_id)
),days_table as(
    select date_trunc(\'day\', dd):: date k_day
    from generate_series
        ( \'2023-12-01\'::timestamp 
        , \'2024-01-31\'::timestamp
        , \'1 day\'::interval) dd 
),course_description as(
    select course_id, sum(obyaz_priznak) required_number
    from activities_guide_v2 agv2 
    where att_priznak = 0
    group by course_id 
),metrics_1 as(
    select k_day,t1.user_id,t1.course_id,t1.activity_id,
    case 
        when  (k_day > t1.date_shown) and (obyaz_priznak = 1) and  ((k_day < t1.first_success) or (t1.first_success is null)) then  k_day-date_trunc(\'day\', t1.date_shown):: date else 0
    end required_activities_delay,
    case 
        when  (k_day >= t1.first_success) and (obyaz_priznak = 1) then  1 else 0 end success_required_done,
    case 
        when  (k_day >= t1.first_success) and (obyaz_priznak = 0) then  1 else 0
    end success_optional_done
    from (select * from all_activities where user_id = '.$id_user.' and att_priznak = 0) t1
    cross join days_table
),metrics_2 as(
    select k_day, user_id, course_id, 
    sum(required_activities_delay) required_activities_delay, 
    sum(success_required_done) success_required_done,
    sum(success_optional_done) success_optional_done
    from metrics_1
    group by user_id, k_day, course_id
    order by k_day
)
    select m2.*, required_number,
    100 * (success_required_done + success_optional_done)/(required_number + success_optional_done) current_progress
    from metrics_2 m2 left join course_description cd on m2.course_id = cd.course_id';
        return $out;
    }
}