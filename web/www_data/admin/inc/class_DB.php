<?php
class class_DB{
    private $mysqli;
    function __construct($database,$user,$password='',$host='127.0.0.1',$port=3310){
        $this->mysqli = new mysqli($host, $user, $password, $database, $port);
        if (mysqli_connect_error()) {
            die('Ошибка подключения (' . mysqli_connect_errno() . ') '. mysqli_connect_error());
        }
    }
    /*
    ЗАПРОС С ВЫБОРКОЙ И ВОЗВРАТ МАССИВА, 0 ЭЛЕМЕНТ КОЛ-ВО СТРОК
    */
    function QUR_SEL($sql){
        $out = array();
        //$this->users_logs($sql);
        $qur = $this->mysqli->query($sql);
        if ($qur){
            $kol = $qur->num_rows;
            $out['err'] = false;
            $out['kol'] = $kol;
            if ($kol){
                while($rez = $qur->fetch_assoc()){
                    $out['rez'][] = $rez;
                }
            }
        }else {
            $out['err'] = true;
            $out['sql']=$sql;
            $out['rep']='ОШИБКА БД!!! <br/>'.$sql.'<br />('.$this->mysqli->errno.') '.$this->mysqli->error;
        }
        //$this->mysqli->close();
        return $out;
    }
    /*
	ЗАПРОС К БАЗЕ ДАННЫХ, И ВОЗВРАТ РЕЗУЛЬТАТА ЗАПРОСА
	*/
    function QUR($sql){
        $out = array();
        //$this->users_logs($sql);
        $qur = $this->mysqli->query($sql);
        if ($qur){
            $out['err']=false;
            $out['id']=$this->lastinsertID();
        }else{
            $out['err']=true;
            $out['sql']=$sql;
            $out['id']=0;
            $out['rep']='ОШИБКА БД!!! <br/>'.$sql.'<br />('.$this->mysqli->errno.') '.$this->mysqli->error;
        }
        //$this->mysqli->close();
        return $out;
    }

    function rescape($param){
        return $this->mysqli->real_escape_string($param);
    }
    function lastinsertID(){
        return $this->mysqli->insert_id;
    }
    function users_logs($sqll){
        if(isset($_SESSION['user'])) {
            $url  = $this->rescape($_SERVER['REQUEST_URI']);
            $sqlq = $this->rescape($sqll);
            $post = ''; if(isset($_POST)&&count($_POST)) $post = $this->rescape(json_encode($_POST,JSON_UNESCAPED_UNICODE));
            $ip   = $this->rescape($this->getIp());
            $sql  = 'INSERT INTO tb1_users_logs VALUES (0,' . time() . ',' . $_SESSION['user']['id'] . ',"' . $url . '","' . $sqlq . '","' . $post . '","' . $ip . '")';
            $rez = $this->mysqli->query($sql);
        }
    }
    function getIp() {
        $keys = [
            'HTTP_CLIENT_IP',
            'HTTP_X_FORWARDED_FOR',
            'REMOTE_ADDR'
        ];
        foreach ($keys as $key) {
            if (!empty($_SERVER[$key])) {
                $array = explode(',', $_SERVER[$key]);
                $ip = trim(end($array));
                if (filter_var($ip, FILTER_VALIDATE_IP)) {
                    return $ip;
                }
            }
        }
    }
}
?>