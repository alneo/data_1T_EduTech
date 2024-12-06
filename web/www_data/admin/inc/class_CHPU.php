<?php
class class_CHPU{
    public $UParts = array();
    public $workDIR = '';

    function __construct($WorkDIR=''){
        $this->workDIR = $WorkDIR;
        $this->init();
    }
    function init(){
        $urlparts = explode( "/", $_SERVER['REQUEST_URI'] );
        $wd = str_replace('/','',$this->workDIR);
        foreach($urlparts as $k => $v){
            if($v!=''&&$v!=$wd) {
                //для страничной навигации уберем p
                if($v[0]=='p'&&is_numeric($v[1])) {
                    $v = str_replace('p','',$v);
                    $this->UParts['page'] = $v;
                }else{
                    $this->UParts[] = $v;
                }
            }
        }
    }
    public function uri(){
        return $this->UParts;
    }
}