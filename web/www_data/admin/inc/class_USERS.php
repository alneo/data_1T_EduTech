<?php
class class_USERS{
    public $DB = NULL;
    public $URLS = NULL;
    public $Tusers = '';
    private $chpu,$smarty;
    public function __construct($params=array()){
        GLOBAL $DB,$ST;
        if(isset($params['smarty'])){
            $this->smarty = $params['smarty'];
        }
        $this->DB = $DB;
        $this->Tusers = $ST['dbpf'].'_users';
        $this->table();
        if(isset($params['html'])&&$params['html']==0){

        }else {
            $this->chpu = new class_CHPU('admin');
            $CHPU = new class_CHPU('admin');
            $this->URLS = $CHPU->uri();
            $this->check();
        }
    }

    private function table(){
        $this->DB->QUR('CREATE TABLE IF NOT EXISTS `'.$this->Tusers.'` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `data_c` int(11) NOT NULL,
        `email` varchar(255) NOT NULL,
        `passw` varchar(255) NOT NULL,
        `status` tinyint(4) NOT NULL,
        `dostup` JSON NOT NULL,
        primary key (id)
        ) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;');
    }
    //id data_c email passw status
    function HTML($params){
        $out=array();
        if(isset($params['smarty'])){
            $smarty = $params['smarty'];
        }
        $des = 'view';
        $path = '/admin/'.$params['url'].'/';
        $PAGE['title'] = $PAGE['name'] = $params['page_name'];

        if (isset($this->URLS[1])) {
            $des = $this->URLS[1];
        }
        if (isset($_POST['add'])) {
            $data = $this->prepare_data($_POST);
            $this->add($data);
            $des = 'view';
        }
        if (isset($_POST['edit'])) {
            $data = $this->prepare_data($_POST);
            $data['id'] = (int)$_POST['id'];
            $this->edit($data);
            $des = 'view';
        }
        if ($des == 'add') {
            $smarty->assign('item', array('email'=>'','status'=>1,'dostup'=>array(),'id'=>0));
        }
        if ($des == 'edit') {
            $id = (int)$this->URLS[2];
            $item = $this->item($id);
            $smarty->assign('item', $item);
        }
        if ($des == 'del') {
            $id = (int)$this->URLS[2];
            $sql = 'DELETE FROM '.$this->Tusers.' WHERE id='.$id.' LIMIT 1';
            $rez = $this->DB->QUR($sql);
            $des = 'view';
        }
        if ($des == 'enter') {
            $id = (int)$this->URLS[2];
            $sql = 'SELECT * FROM '.$this->Tusers.' WHERE id='.$id.' LIMIT 1';
            $rez = $this->DB->QUR_SEL($sql);
            if(!$rez['err']&&$rez['kol']){
                $rez['rez'][0]['dostup'] = json_decode($rez['rez'][0]['dostup'],1);
                $_SESSION['user'] = $rez['rez'][0];
                unset($_SESSION['user']['passw']);
            }
            header('Location: /admin/main/');
        }
        if ($des == 'view') {
            $items = $this->items();
            $smarty->assign('items', $items);
        }
        $smarty->assign('menus', $this->menus());
        $smarty->assign('statuses', $this->statuses());
        $smarty->assign('des', $des);
        $smarty->assign('path', $path);
        $PAGE['body'] = $smarty->fetch('page_users.html');
        return $PAGE;
    }

    function userInfo($id){
        $out = array();
        $sql = 'SELECT * FROM '.$this->Tusers.' WHERE id='.$id.' LIMIT 1';
        $rez = $this->DB->QUR_SEL($sql);
        if (!$rez['err'] && $rez['kol']) {
            $out = $rez['rez'][0];
        }
        return $out;
    }

    public function prepare_data($data){
        if(isset($data['data_c'])) $data['data_c']=strtotime($data['data_c']); else $data['data_c']=time();
        if(isset($data['email'])) $data['email']=$this->DB->rescape($data['email']); else $data['email']='';
        if(isset($data['passw'])&&$data['passw']!='') $data['passw']=$this->DB->rescape($this->password($data['passw'])); else $data['passw']='';
        if(isset($data['status'])) $data['status']=$this->DB->rescape($data['status']); else $data['status']=0;
        if(isset($data['dostup'])) $data['dostup']=$this->DB->rescape(json_encode($data['dostup']));
        else $data['dostup']=$this->DB->rescape(json_encode(array()));
        return $data;
    }
    public function items(){
        $out = array();
        $sql = 'SELECT * FROM '.$this->Tusers;
        $rez = $this->DB->QUR_SEL($sql);
        if(!$rez['err']&&$rez['kol']){
            foreach($rez['rez'] as $k => $v){
                $v['dostup'] = json_decode($v['dostup'],1);
                $out[] = $v;
            }
        }
        return $out;
    }
    public function item($id){
        $out = array();
        $sql = 'SELECT * FROM '.$this->Tusers.' WHERE id='.$id;
        $rez = $this->DB->QUR_SEL($sql);
        if(!$rez['err']&&$rez['kol']){
            $out = $rez['rez'][0];
            $out['dostup'] = json_decode($out['dostup'],1);
        }
        return $out;
    }
    public function add($data){
        $sql = 'INSERT INTO '.$this->Tusers.' VALUES(0,'.$data['data_c'].',"'.$data['email'].'","'.$data['passw'].'",'.$data['status'].',"'.$data['dostup'].'")';
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
        $password=''; if($data['passw']!='') $password=',passw="'.$data['passw'].'"';
        $sql = 'UPDATE '.$this->Tusers.' SET data_c='.$data['data_c'].', email="'.$data['email'].'"'.$password.',status='.$data['status'].',dostup="'.$data['dostup'].'" WHERE id='.$data['id'];
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
    public function statuses($status=-1){
        $statuses = array(0=>'Забанен',1=>'Обычный',50=>'Модератор',99=>'Администратор');
        if($status==-1) return $statuses; else return $statuses[$status];
    }
    public function menus($name=''){
        GLOBAL $ST;
        $UIrazdels = $ST['route'];
        foreach ($UIrazdels as $k => $v) $menus[$v['url']] = $v['name'];
        if($name=='') return $menus; else return $menus[$name];
    }

    /**
     * Проверка на авторизацию пользователя
     * @throws SmartyException
     */
    public function check(){
        $smarty = $this->smarty;
        if(isset($this->URLS[0])&&$this->URLS[0]=='logout'){
            unset($_SESSION['user']);
        }
        if(!isset($_SESSION['user'])){
            if(isset($_POST['enter'])){
                $email = $_POST['email'];
                $passw = $_POST['password'];

                $user = $this->check_user_auth($email,$passw);
                if(count($user)){
                    header('Location: /admin/main/');
                    exit();
                }
            }
            $smarty->display('tpl_auth.html');
            exit();
        }else{
            $dostup=false;
            if(!isset($this->URLS[0])) $this->URLS[0]='';
            if(isset($_SESSION['user']['dostup'])&&count($_SESSION['user']['dostup'])){
                if($this->URLS[0]!='') {
                    if (in_array($this->URLS[0], $_SESSION['user']['dostup'])) {
                        $dostup = true;
                    }
                }else{
                    $dostup = true;
                }
            }
            if(!$dostup){
                header('Location: /admin/');
                exit();
            }
        }
    }
    public function check_user_auth($email,$passw){
        $out=array();
        $email = preg_replace('/[^A-Za-z0-9@_\.]/', '', $email);

        $passw = $this->password($passw);
        $sql = 'SELECT id FROM '.$this->Tusers;
        $rez = $this->DB->QUR_SEL($sql);
        if(!$rez['err']){
            if(!$rez['kol']){
                $dostup[] = 'users';
                $dostup[] = 'adm1n';
                $sql = 'INSERT INTO '.$this->Tusers.' VALUES(0,'.time().',"'.$this->DB->rescape($email).'","'.$this->DB->rescape($passw).'",99,"'.$this->DB->rescape(json_encode($dostup)).'")';
                $rez = $this->DB->QUR($sql);
            }
        }

        $sql = 'SELECT * FROM '.$this->Tusers.' WHERE email="'.$this->DB->rescape($email).'" AND passw="'.$this->DB->rescape($passw).'"';
        $rez = $this->DB->QUR_SEL($sql);
        if(!$rez['err']&&$rez['kol']){
            $rez['rez'][0]['dostup'] = json_decode($rez['rez'][0]['dostup'],1);
            $_SESSION['user'] = $rez['rez'][0];
            $_SESSION['user']['dostup'][]='adm1n';
            unset($_SESSION['user']['passw']);
            $out = $_SESSION['user'];
        }
        return $out;
    }
    private function password($passw){
        return md5('2023ASDF'.$passw.'_H3fsd@1fgsd');
    }
    public function gen_password($length = 6){
        $password = '';
        $arr = array(
            'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
            'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
            'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
            'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
            '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '!', '@', '#',
            '$', '_', '-', '(', ')'
        );
        for ($i = 0; $i < $length; $i++) {
            $password .= $arr[random_int(0, count($arr) - 1)];
        }
        return $password;
    }
}
