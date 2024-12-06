<?php

class class_PGSQL {
    private $conn;

    public function __construct($host, $dbname, $user, $password,$port) {
        $this->conn = pg_connect("host=$host dbname=$dbname user=$user password=$password port=$port");
    }

    public function QUR($sql) {
        $result = pg_query($this->conn, $sql);
        if (!$result) {
            return ['err' => 1, 'rr' => 1, 'msg' => pg_last_error($this->conn)];
        } else {
            return ['err' => 0, 'rr' => 0, 'id' => pg_last_oid($result)];
        }
    }

    public function QUR_SEL($sql) {
        $result = pg_query($this->conn, $sql);
        if (!$result) {
            return ['err' => 1, 'rr' => 1, 'msg' => pg_last_error($this->conn)];
        } else {
            $rows = pg_fetch_all($result);
            return ['err' => 0, 'rr' => 0, 'rez' => $rows, 'kol' => pg_num_rows($result)];
        }
    }

    public function rescape($value) {
        return pg_escape_string($this->conn, $value);
    }
    public function closeConnection() {
        pg_close($this->conn);
    }
}

?>