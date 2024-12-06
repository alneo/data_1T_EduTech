<?php
include_once 'config.php';
error_reporting(E_ALL);
$step = '';
$des = '';
$id = 0;

if(count($argv)>1){
    $step = $argv[1];
    if(isset($argv[2])) $des = $argv[2];
    if(isset($argv[3])) $id = $argv[3];
}else{
    if(isset($_GET['step'])) $step=$_GET['step'];
    if(isset($_GET['des'])) $des=$_GET['des'];
    if(isset($_GET['id'])) $id=$_GET['id'];
}

if($step=='onsearch_work'){//php cron.php onsearch_work

}
