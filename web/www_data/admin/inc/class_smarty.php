<?php
require('inc/smarty/Smarty.class.php');
class class_smarty extends Smarty{
    function config($TPL){
        $smarty = new Smarty;
        $smarty->template_dir = $TPL.'/';
        $smarty->compile_dir = $TPL.'/templates_c/';
        $smarty->config_dir = $TPL.'/configs/';
        $smarty->cache_dir = $TPL.'/cache/';
        //$smarty->force_compile = true;
        $smarty->debugging = false;
        $smarty->caching = false;
        $smarty->cache_lifetime = 120;
        return $smarty;
    }
}
?>