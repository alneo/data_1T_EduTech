<?php
class class_CONFIG{
    private $DB,$Tconfig,$chpu,$URLS;
    function __construct($params=array()){
        GLOBAL $ST,$DB;
        $this->DB = $DB;
        $this->Tconfig = $ST['dbpf'].'_config';
        $this->table();
        if(isset($params['html'])&&$params['html']==0){

        }else {
            $this->chpu = new class_CHPU('admin');
            $CHPU = new class_CHPU('admin');
            $this->URLS = $CHPU->uri();
        }
    }

    private function table(){
        $this->DB->QUR('CREATE TABLE IF NOT EXISTS `'.$this->Tconfig.'` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `data_c` int(11) NOT NULL,
        `model_classif` varchar(255) NOT NULL,
        `model_prognoz` varchar(255) NOT NULL,
        `model_studyie` varchar(255) NOT NULL,
        `client_config` JSON NOT NULL,
        `model_config` JSON NOT NULL,
        `email_config` JSON NOT NULL,
        `status` tinyint(4) NOT NULL,
        primary key (id)
        ) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;');
    }

    function HTML($params){
        $out=array();
        if(isset($params['smarty'])){
            $smarty = $params['smarty'];
        }

        $des = 'view';
        $out['title'] = 'Настройка';
        $out['name'] = 'Главная';

        if(isset($_SESSION['user'])){
            $smarty->assign('aUSER',$_SESSION['user']);
        }else{
            $smarty->assign('aUSER',array());
        }
        if($des=='view'){
            if(isset($_POST['save_config'])){
                if($_POST['id']!=0){
                    $rez = $this->edit($_POST);
                }else{
                    $rez = $this->add($_POST);
                }
            }
            $item = $this->item(1);
            if(!$item){
                $item = array(
                    'id' => 0,
                    'data_c' => date('Y-m-d'),
                   'model_classif' => '',
                   'model_prognoz' => '',
                   'model_studyie' => '',
                    'client_config' => array(
                        'host' => '',
                        'port' => '',
                        'database' => '',
                        'login' => '',
                        'passw' => ''
                    ),
                   'model_config' => array(
                        'host' => '',
                        'port' => '',
                        'path' => '',
                        'login' => '',
                        'passw' => ''
                    ),
                    'email_config' => array(
                        'email' => '',
                        'host' => '',
                        'login' => '',
                        'passw' => '',
                        'port' => '',
                       'secur' => ''
                    )
                );
            }
            $smarty->assign('item',$item);
        }
        $out['body'] = $smarty->fetch('page_config.html');

        return $out;
    }


    public function prepare_data($data){
        //id, data_c, model_classif, model_prognoz, model_studyie, client_config, model_config, email_config, status
        if(isset($data['data_c'])) $data['data_c']=strtotime($data['data_c']); else $data['data_c']=time();
        if(isset($data['model_classif'])) $data['model_classif']=$this->DB->rescape($data['model_classif']); else $data['model_classif']='';
        if(isset($data['model_prognoz'])) $data['model_prognoz']=$this->DB->rescape($data['model_prognoz']); else $data['model_prognoz']='';
        if(isset($data['model_studyie'])) $data['model_studyie']=$this->DB->rescape($data['model_studyie']); else $data['model_studyie']='';
        if(isset($data['client_config'])) $data['client_config']=$this->DB->rescape(json_encode($data['client_config'],JSON_UNESCAPED_UNICODE));
        else $data['client_config']=$this->DB->rescape(json_encode(array()));
        if(isset($data['model_config'])) $data['model_config']=$this->DB->rescape(json_encode($data['model_config'],JSON_UNESCAPED_UNICODE));
        else $data['model_config']=$this->DB->rescape(json_encode(array()));
        if(isset($data['email_config'])) $data['email_config']=$this->DB->rescape(json_encode($data['email_config'],JSON_UNESCAPED_UNICODE));
        else $data['email_config']=$this->DB->rescape(json_encode(array()));
        if(isset($data['status'])) $data['status']=$this->DB->rescape($data['status']); else $data['status']=0;
        return $data;
    }
    public function items(){
        $out = array();
        $sql = 'SELECT * FROM '.$this->Tconfig;
        $rez = $this->DB->QUR_SEL($sql);
        if(!$rez['err']&&$rez['kol']){
            foreach($rez['rez'] as $k => $v){
                $v['client_config'] = json_decode($v['client_config'],1);
                $v['model_config'] = json_decode($v['model_config'],1);
                $v['email_config'] = json_decode($v['email_config'],1);
                $out[] = $v;
            }
        }
        return $out;
    }
    public function item($id){
        $out = array();
        $sql = 'SELECT * FROM '.$this->Tconfig.' WHERE id='.$id;
        $rez = $this->DB->QUR_SEL($sql);
        if(!$rez['err']&&$rez['kol']){
            $out = $rez['rez'][0];
            $out['client_config'] = json_decode($out['client_config'],1);
            $out['model_config'] = json_decode($out['model_config'],1);
            $out['email_config'] = json_decode($out['email_config'],1);
        }
        return $out;
    }

    /**
     * Получение одного параметра
     * @param $field
     * @param $id
     * @return array|mixed
     */
    public function item_get($field,$id=1){
        $out = array();
        $sql = 'SELECT * FROM '.$this->Tconfig.' WHERE id='.$id;
        $rez = $this->DB->QUR_SEL($sql);
        if(!$rez['err']&&$rez['kol']){
            $out = $rez['rez'][0];
            $out['client_config'] = json_decode($out['client_config'],1);
            $out['model_config'] = json_decode($out['model_config'],1);
            $out['email_config'] = json_decode($out['email_config'],1);

            if(isset($out[$field])) $out = $out[$field];
        }
        return $out;
    }
    public function add($data){
        $data = $this->prepare_data($data);
        $sql = 'INSERT INTO '.$this->Tconfig.' VALUES(0,'.$data['data_c'].',"'.$data['model_classif'].'","'.$data['model_prognoz'].'","'.$data['model_studyie'].'","'.$data['client_config'].'","'.$data['model_config'].'","'.$data['email_config'].'",'.$data['status'].')';
        $rez = $this->DB->QUR($sql);
        if(!$rez['err']){
            $out['err']=0;
            $out['msg']='добавили';
            $out['id']=$this->DB->lastinsertID();
        }else{
            $out['err']=1;
            $out['msg']='не добавили';
        }
        return $out;
    }
    public function edit($data){
        $data = $this->prepare_data($data);
        $sql = 'UPDATE '.$this->Tconfig.' SET data_c='.$data['data_c'].', model_classif="'.$data['model_classif'].'", model_prognoz="'.$data['model_prognoz'].'", model_studyie="'.$data['model_studyie'].'", client_config="'.$data['client_config'].'", model_config="'.$data['model_config'].'", email_config="'.$data['email_config'].'",status='.$data['status'].' WHERE id='.$data['id'];
        $rez = $this->DB->QUR($sql);
        if(!$rez['err']){
            $out['err']=0;
            $out['msg']='изменили';
        }else{
            $out['err']=1;
            $out['msg']='не изменили';
        }
        return $out;
    }
}