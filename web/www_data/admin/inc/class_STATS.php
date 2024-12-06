<?php
class class_STATS{
    private $DB;
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
        $out['title'] = 'Статистика';
        $out['name'] = 'Статистика';

        if(isset($_SESSION['user'])){
            $smarty->assign('aUSER',$_SESSION['user']);
        }else{
            $smarty->assign('aUSER',array());
        }
        if($des=='view'){
            $smarty->assign('stats',$this->stats());
        }
        $out['body'] = $smarty->fetch('page_stats.html');

        return $out;
    }
    function PG_connect(){
        $this->PGDB = new class_PGSQL('95.64.227.126', 'edutechdb', 'edutechadmin', 'RGF2_32;lkas@fds',21000);
    }
    function stats(){
        $out = array();
        $this->PG_connect();
        //CREATE TABLE ds_stats_m1 (
        //    id SERIAL PRIMARY KEY,
        //    login VARCHAR(30),
        //    file_name VARCHAR(200),
        //    file_type VARCHAR(10),
        //    file_owner VARCHAR(10),
        //    filesize INTEGER,
        //    last_modified TIMESTAMP,
        //    row_count INTEGER,
        //    py_block INTEGER
        //);
        //CREATE TABLE ds_stats_m2 (
        //    id SERIAL PRIMARY KEY,
        //    id_stats_m1 SERIAL,
        //    metric_descr VARCHAR(100),
        //    metric_name VARCHAR(100),
        //    metric_value real
        //);
        $sql = 'select * from ds_stats_m1';
        $result = $this->PGDB->QUR_SEL($sql);
        if ($result['err'] == 0) {
            $out['items'] = array();
            foreach ($result['rez'] as $k => $v){
                $data = $this->PGDB->QUR_SEL('select metric_descr from ds_stats_m2 WHERE id_stats_m1='.$v['id'].' GROUP BY metric_descr');
                $v['metric_descrs'] = array();
                foreach ($data['rez'] as $k1 => $v1){
                    $pos=40;
                    if($v1['metric_descr']=='2.1.1. Линейная регрессия') $pos=1;
                    if($v1['metric_descr']=='2.1.2. Дерево решений') $pos=2;
                    if($v1['metric_descr']=='2.2 Обучение ансамблей моделей') $pos=3;
                    if($v1['metric_descr']=='2.2.1. Случайный лес') $pos=4;
                    if($v1['metric_descr']=='2.2.2. Градиентный бустинг sklearn') $pos=5;
                    if($v1['metric_descr']=='2.2.3. XGBoost') $pos=6;
                    if($v1['metric_descr']=='2.2.4. CatBoost') $pos=7;
                    if($v1['metric_descr']=='2.2.5. Light Gradient Boosted Machine') $pos=8;
                    if($v1['metric_descr']=='3. Сравнение и визуализация результатов') $pos=9;
                    if($v1['metric_descr']=='4. Тестирование качества прогнозирования прогресса по курсу в разных учебных группах') $pos=10;
                    if($v1['metric_descr']=='4.1. Тестирование 77 группы') $pos=11;
                    if($v1['metric_descr']=='5. Визуализация результатов. Сериализация моделей для их дальнейшего использования') $pos=12;
                    if($v1['metric_descr']=='5.1. Визуализация примеров прогнозирования прогресса по курсу для разных учебных групп') $pos=13;
                    if($v1['metric_descr']=='5.2. Сериализация моделей') $pos=14;

                    $data1 = $this->PGDB->QUR_SEL('select metric_name,metric_value from ds_stats_m2 WHERE id_stats_m1='.$v['id'].' AND metric_descr=\''.$v1['metric_descr'].'\' ORDER BY metric_name!=\'Validation Week 1\',metric_name!=\'Validation Week 2\',metric_name!=\'Validation Week 3\',metric_name!=\'Validation Week 4\',metric_name!=\'Validation Week 5\',metric_name!=\'Validation Week 6\',metric_name!=\'Validation Week 7\',metric_name!=\'Validation Week 8\',metric_name!=\'Validation Week 9\',metric_name!=\'Validation Week 10\',metric_name!=\'Week 1\',metric_name!=\'Week 2\',metric_name!=\'Week 3\',metric_name!=\'Week 4\',metric_name!=\'Week 5\',metric_name!=\'Week 6\',metric_name!=\'Week 7\',metric_name!=\'Week 8\',metric_name!=\'Week 9\',metric_name!=\'Week 10\'');
                    $v1['metric_names'] = array();
                    foreach ($data1['rez'] as $k2 => $v2){
                        $v1['metric_names'][$v2['metric_name']] = $v2['metric_value'];
                    }
                    $v['metric_descrs'][$pos] = $v1;
                    ksort($v['metric_descrs']);
                }
                $out['items'][] = $v;
            }
        } else {
            $out['items'] = array();
        }

        $sql = 'select metric_descr from ds_stats_m2 GROUP BY metric_descr;';
        $result = $this->PGDB->QUR_SEL($sql);
        if ($result['err'] == 0) {
            $out['graph'] = array();
            $out['datas'] = array();
            foreach ($result['rez'] as $k => $v){
                $d1 = $this->PGDB->QUR_SEL('select metric_name from ds_stats_m2 WHERE metric_descr=\''.$v['metric_descr'].'\' GROUP BY metric_name;');
                foreach ($d1['rez'] as $k1 => $v1){
                    $out['graph'][$v['metric_descr']]['lines']['type'] = 'line';
                    $out['graph'][$v['metric_descr']]['lines']['label'] = $v1['metric_name'];
                    $out['graph'][$v['metric_descr']]['lines']['borderWidth'] = 1;
                    $out['graph'][$v['metric_descr']]['lines']['data'] = array();

                    $sql2 = 'select m1.last_modified,m2.metric_value from ds_stats_m1 as m1, ds_stats_m2 as m2 WHERE m2.metric_descr=\''.$v['metric_descr'].'\' AND m2.metric_name=\''.$v1['metric_name'].'\' AND m1.id=m2.id_stats_m1 ORDER BY m2.id;';
                    $d2 = $this->PGDB->QUR_SEL($sql2);
                    foreach ($d2['rez'] as $k2 => $v2){
                        $date=date('H:i d.m.Y',strtotime($v2['last_modified']));
                        $out['datas'][] = $date;
                        $out['graph'][$v['metric_descr']]['lines']['data'][] = (float)$v2['metric_value'];
                    }
                    $out['graph'][$v['metric_descr']]['linesj'][]=json_encode($out['graph'][$v['metric_descr']]['lines'],JSON_UNESCAPED_UNICODE);
                    unset($out['graph'][$v['metric_descr']]['lines']);
                }
            }
            $out1['graph']['2.1.1. Линейная регрессия'] = $out['graph']['2.1.1. Линейная регрессия'];
            $out1['graph']['2.1.2. Дерево решений'] = $out['graph']['2.1.2. Дерево решений'];
            $out1['graph']['2.2 Обучение ансамблей моделей'] = $out['graph']['2.2 Обучение ансамблей моделей'];
            $out1['graph']['2.2.1. Случайный лес'] = $out['graph']['2.2.1. Случайный лес'] ;
            $out1['graph']['2.2.2. Градиентный бустинг sklearn'] = $out['graph']['2.2.2. Градиентный бустинг sklearn'];
            $out1['graph']['2.2.3. XGBoost'] = $out['graph']['2.2.3. XGBoost'];
            $out1['graph']['2.2.4. CatBoost'] = $out['graph']['2.2.4. CatBoost'];
            $out1['graph']['2.2.5. Light Gradient Boosted Machine'] = $out['graph']['2.2.5. Light Gradient Boosted Machine'];
            $out1['graph']['3. Сравнение и визуализация результатов'] = $out['graph']['3. Сравнение и визуализация результатов'];
            $out1['graph']['4. Тестирование качества прогнозирования прогресса по курсу в разных учебных группах'] = $out['graph']['4. Тестирование качества прогнозирования прогресса по курсу в разных учебных группах'];
            $out1['graph']['4.1. Тестирование 77 группы'] = $out['graph']['4.1. Тестирование 77 группы'];
            $out1['graph']['5. Визуализация результатов. Сериализация моделей для их дальнейшего использования'] = $out['graph']['5. Визуализация результатов. Сериализация моделей для их дальнейшего использования'];
            $out1['graph']['5.1. Визуализация примеров прогнозирования прогресса по курсу для разных учебных групп'] = $out['graph']['5.1. Визуализация примеров прогнозирования прогресса по курсу для разных учебных групп'];
            $out1['graph']['5.2. Сериализация моделей'] = $out['graph']['5.2. Сериализация моделей'];
            $out['graph'] = $out1['graph'];
        } else {
            $out['graph'] = array();
        }
        $out['datas'] = array_unique($out['datas']);
        $this->PGDB->closeConnection();
        return $out;
    }
}