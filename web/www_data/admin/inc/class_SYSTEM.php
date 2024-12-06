<?php

class class_SYSTEM{
    function __construct(){
    }

    /**
     * Загрузка файлов
     * @param $name
     * @param string $ddir
     * @param int $replacefile
     * @return array
     */
    public function uploadfiles($name, $ddir = ''){
        GLOBAL $ST;
        $out = array();
        $uploaddir = 'uploads/';
        if ($ddir != '') $uploaddir .= $ddir . '/';
        if (!file_exists($uploaddir)) mkdir($uploaddir, 0777, true);
        if (isset($_FILES[$name])) {
            foreach($_FILES[$name]['name'] as $kf => $vf) {
                $NAME = $_FILES[$name]['name'][$kf];
                $TMP_NAME = $_FILES[$name]['tmp_name'][$kf];
                $TYPE = $_FILES[$name]['type'][$kf];
                $ERROR = $_FILES[$name]['error'][$kf];
                //echo $NAME.':'.$TMP_NAME.':'.$TYPE.':'.$ERROR.'<br>';
                if(($TYPE=='image/jpeg'||$TYPE=='image/png')&&$ERROR==0) {
                    $pi = pathinfo($NAME);
                    $fx = $pi['extension'];
                    $fn = $pi['filename'];
                    $out[$kf]['realname'] = $fn . '.' . $fx;
                    $rf = $this->translit($fn) . '_'.time().'.' . $fx;
                    $uploadfile = $uploaddir . $rf;
                    if (move_uploaded_file($TMP_NAME, $uploadfile)) {
                        $out[$kf]['file'] = $rf;
                        $out[$kf]['path'] = $uploaddir;
                        $out[$kf]['err'] = 0;
                        $out[$kf]['msg'] = 'файл загрузили';
                    } else {
                        $out[$kf]['file'] = '';
                        $out[$kf]['path'] = $uploaddir;
                        $out[$kf]['err'] = 1;
                        $out[$kf]['err1'] = $_FILES[$name]["error"];
                        $out[$kf]['msg'] = 'файл не загрузили';
                    }
                }
            }
        }
        return $out;
    }

    /**
     * Загрузка файла
     * @param $name
     * @param string $ddir
     * @param int $replacefile
     * @return array
     */
    public function uploadfile($name, $ddir = '', $replacefile = 0){
        GLOBAL $ST;
        $out = array();
        $uploaddir = 'uploads/';
        if ($ddir != '') $uploaddir .= $ddir . '/';
        if (!file_exists($uploaddir)) mkdir($uploaddir, 0777, true);
        if (isset($_FILES[$name])) {
            $pi = pathinfo($_FILES[$name]['name']);
            $fx = $pi['extension'];
            $fn = $pi['filename'];
            $out['realname'] = $fn.'.'.$fx;
            if(isset($_SESSION['user'])){
                $rf = $_SESSION['user']['id'].'_'.$this->translit($fn) . '.' . $fx;
            }else{
                $rf = '0_'.$this->translit($fn) . '.' . $fx;
            }
            $uploadfile = $uploaddir . $rf;
            if($replacefile==0) {
                if (file_exists($uploadfile)) {
                    if (isset($_SESSION['user'])) {
                        $rf = $_SESSION['user']['id'] . '_' . $this->translit($fn) . '_' . mt_rand(1000, 9999) . '.' . $fx;
                    } else {
                        $rf = '0_' . $this->translit($fn) . '_' . mt_rand(1000, 9999) . '.' . $fx;
                    }
                }
                $uploadfile = $uploaddir . $rf;
            }
            $fisset=false;
            if($replacefile==2) {//2ой режим если есть файл то не грузим его
                if(file_exists($uploadfile)) $fisset=true;
                $out['file'] = $rf;
                $out['path'] = $uploaddir;
                $out['err'] = 0;
                $out['msg'] = 'файл существовал';
            }
            if(!$fisset){
                if (move_uploaded_file($_FILES[$name]['tmp_name'], $uploadfile)) {
                    $out['file'] = $rf;
                    $out['path'] = $uploaddir;
                    $out['err'] = 0;
                    $out['msg'] = 'файл загрузили';
                } else {
                    $out['file'] = '';
                    $out['path'] = $uploaddir;
                    $out['err'] = 1;
                    $out['err1'] = $_FILES[$name]["error"];
                    $out['msg'] = 'файл не загрузили';
                }
            }
        }
        return $out;
    }
    public function human_filesize($bytes) {
        $bytes = floatval($bytes);
        $arBytes = array(
            0 => array(
                "UNIT" => "Тб",
                "VALUE" => pow(1024, 4)
            ),
            1 => array(
                "UNIT" => "Гб",
                "VALUE" => pow(1024, 3)
            ),
            2 => array(
                "UNIT" => "Мб",
                "VALUE" => pow(1024, 2)
            ),
            3 => array(
                "UNIT" => "Кб",
                "VALUE" => 1024
            ),
            4 => array(
                "UNIT" => "б",
                "VALUE" => 1
            ),
        );

        foreach($arBytes as $arItem)
        {
            if($bytes >= $arItem["VALUE"])
            {
                $result = $bytes / $arItem["VALUE"];
                $result = str_replace(".", "," , strval(round($result, 2)))." ".$arItem["UNIT"];
                break;
            }
        }
        return $result;
    }
    public function translit($st)
    {
        $a = array_merge(array_combine(preg_split('//u', "абвгдеёзийклмнопрстуфхцьыэАБВГДЕЁЗИЙКЛМНОПРСТУФХЦЬЫЭabcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_"), preg_split('//u', "abvgdeeziyklmnoprstufhc'ieABVGDEEZIYKLMNOPRSTUFHC'IEabcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_")), array("ж" => "zh", "ч" => "ch", "ш" => "sh", "щ" => "shch", "ъ" => "", "ю" => "yu", "я" => "ya", "Ж" => "Zh", "Ч" => "Ch", "Ш" => "Sh", "Щ" => "Shch", "Ъ" => "", "Ю" => "Yu", "Я" => "Ya"));
        $r = preg_split('//u', $st);
        $out = '';
        foreach ($r as $v) {
            if (isset($a[$v]))
                $out .= $a[$v];
        }
        return $out;
    }

    function file_force_download($file) {
        if (file_exists($file)) {
            if (ob_get_level()) {
                ob_end_clean();
            }
            // заставляем браузер показать окно сохранения файла
            header('Content-Description: File Transfer');
            header('Content-Type: application/octet-stream');
            header('Content-Disposition: attachment; filename=' . basename($file));
            header('Content-Transfer-Encoding: binary');
            header('Expires: 0');
            header('Cache-Control: must-revalidate');
            header('Pragma: public');
            header('Content-Length: ' . filesize($file));
            readfile($file);
            exit;
        }
    }

    function num_word($value, $words, $show = true){
        $num = $value % 100;
        if ($num > 19) {
            $num = $num % 10;
        }
        $out = ($show) ?  $value . ' ' : '';
        switch ($num) {
            case 1:  $out .= $words[0]; break;
            case 2:
            case 3:
            case 4:  $out .= $words[1]; break;
            default: $out .= $words[2]; break;
        }
        return $out;
    }

    /**
     * Секунды в дни часы минуты секунды
     * @param $secs
     * @return string
     */
    function secToStr($secs,$t=0){
        $res = ''; $out=array();
        $days = $out['days'] = floor($secs / 86400);
        $secs = $secs % 86400;
        if($days!=0) {
            $out['daysn'] = $this->num_word($days, array('день', 'дня', 'дней'),false);
            $res .= $this->num_word($days, array('день', 'дня', 'дней')) . ', ';
        }
        $hours = $out['hours'] = floor($secs / 3600);
        $secs = $secs % 3600;
        if($hours!=0) {
            $out['hoursn'] = $this->num_word($hours, array('час', 'часа', 'часов'),false);
            $res .= $this->num_word($hours, array('час', 'часа', 'часов')) . ', ';
        }
        $minutes = $out['minutes'] = floor($secs / 60);
        $secs = $out['secs'] = $secs % 60;
        if($minutes!=0) {
            $out['minutesn'] = $this->num_word($minutes, array('минута', 'минуты', 'минут'),false);
            $res .= $this->num_word($minutes, array('минута', 'минуты', 'минут')) . ', ';
        }
        $out['secsn'] = $this->num_word($secs, array('секунда', 'секунды', 'секунд'),false);
        $res .= $this->num_word($secs, array('секунда', 'секунды', 'секунд'));
        if(!$t) {
            return $res;
        } else {
            $out['hours'] = str_pad($out['hours'], 2, "0", STR_PAD_LEFT);
            $out['minutes'] = str_pad($out['minutes'], 2, "0", STR_PAD_LEFT);
            $out['secs'] = str_pad($out['secs'], 2, "0", STR_PAD_LEFT);
            return $out;
        }
    }
}