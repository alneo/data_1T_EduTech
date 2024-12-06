<?php
class class_UI{
    public $smarty;
    public $urls,$param,$MAIN_URL;
    public $user;
    function __construct($param){
        GLOBAL $ST;
        $this->param = $param;
        $this->smarty = $this->smarty_init($this->param);
        $this->urls = $this->chpu_init();
        $this->user = $this->user_init();
        $this->MAIN_URL = $ST['MAIN_URL'];
    }

    public function init(){
        $PAGE = $this->routing();
        $SITE['title'] = 'ET';
        $smarty = $this->smarty;
        $smarty->assign('CHPU',$this->urls);
        $smarty->assign('PAGE',$PAGE);
        $smarty->assign('SITE',$SITE);
        $smarty->assign('MENU',$this->razdels());
        $smarty->assign('MAIN_URL',$this->MAIN_URL);
        if(isset($_SESSION['user'])){
            $smarty->assign('aUSER',$_SESSION['user']);
        }else{
            $smarty->assign('aUSER',array());
        }
        if(!isset($PAGE['tpl'])) $PAGE['tpl'] ='tpl_index.html';
        $smarty->display($PAGE['tpl']);
    }

    function razdels(){
        GLOBAL $ST;
        $route = $ST['route'];
        return $route;
    }

    function routing(){
        $out = array();
        $route = $this->razdels();
        $url = $this->urls;
        if($url[0]=='') $url[0]='main';

        if(isset($route[$url[0]])){
            $urlc = $route[$url[0]];
            if(isset($urlc['class'])){
                if(isset($urls['auth'])&&$urls['auth']=='true'){
                    $params['urls']=$this->urls;
                    $params['smarty']=$this->smarty;
                    $cUSER = new class_USERS($params);
                }
                $params['urls']=$url;
                $params['smarty']=$this->smarty;
                $params['page_name']=$urlc['name'];
                $params['url']=$urlc['url'];
                $className =  $urlc['class'];
                $instance = new $className($params);
                $out = $instance->HTML($params);
            }
        }
        return $out;
    }

    function smarty_init($param){
        $smartyC = new class_smarty();
        if(isset($param['tpl'])) {
            $smarty = $smartyC->config($param['tpl']);
            $smarty->assign('TPL', $param['tpl']);
        }
        else {
            $smarty = $smartyC->config(__DIR__.'/tpl');
            $smarty->assign('TPL', '/tpl');
        }
        return $smarty;
    }

    function chpu_init(){
        $CHPU = new class_CHPU('admin');
        $URLS = $CHPU->uri();
        if(!isset($URLS[0])) $URLS[0]='';
        return $URLS;
    }

    function user_init(){
        $cUSER = new class_USERS(array('smarty'=>$this->smarty));
        return $cUSER;
    }
}