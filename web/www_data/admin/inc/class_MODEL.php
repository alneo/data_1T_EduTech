<?php
class class_MODEL{
    private $DB,$MODELURL;
    function __construct(){
        GLOBAL $ST,$DB;
        $this->DB = $DB;
        $this->MODELURL = 'http://%MODEL_ip%:%MODEL_port%';
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
        $out['title'] = 'Предсказания';
        $out['name'] = 'Предсказания';

        if(isset($_SESSION['user'])){
            $smarty->assign('aUSER',$_SESSION['user']);
        }else{
            $smarty->assign('aUSER',array());
        }
        if($des=='view'){
            $param = array();
            $CONFIG = new class_CONFIG(array('html'=>0));
            $model_prognoz = $CONFIG->item_get('model_prognoz');
            $smarty->assign('model_prognoz',$model_prognoz);
            if(isset($_POST['check'])){
                $param['user_id'] = (int)$_POST['user_id'];
                $param['week'] = (int)$_POST['week'];

                $rez = $this->cCurl('/m2_progress/'.$model_prognoz.'/'.$param['week'].'/'.$param['user_id']);
                $rez = json_decode($rez['out'],1);
                $rez['json'] = json_decode($rez['json'],1);
                $param['rez'] = $rez;
            }
            $smarty->assign('param',$param);
        }
        $out['body'] = $smarty->fetch('page_model.html');

        return $out;
    }

    function cCurl($url='/m2_progress/3/1',$post=array()){
        $out='';
        if( $curl = curl_init() ) {
            curl_setopt($curl, CURLOPT_URL, $this->MODELURL.$url);
            curl_setopt($curl, CURLOPT_RETURNTRANSFER,true);
            curl_setopt($curl, CURLOPT_HEADER, 1);
            if(count($post)) {
                curl_setopt($curl, CURLOPT_POST, true);
                curl_setopt($curl, CURLOPT_POSTFIELDS, json_encode($post));
            }
            $headers = array(
                "accept: application/json",
                "Content-Type: application/json",
            );
            curl_setopt($curl, CURLOPT_HTTPHEADER, $headers);
            $response = curl_exec($curl);
            $header_size = curl_getinfo($curl, CURLINFO_HEADER_SIZE);
            $header = substr($response, 0, $header_size);
            $out = substr($response, $header_size);
            $info = curl_getinfo($curl);
            curl_close($curl);
        }
        return array('out'=>$out,'header'=>$header,'info'=>$info);
    }
}