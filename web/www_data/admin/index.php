<?php
session_start();
error_reporting(E_ALL);
include_once 'config.php';

$param['tpl'] = 'tpl';
$UI = new class_UI($param);
$PAGE = $UI->init();