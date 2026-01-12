<?php

namespace Lib;

use PDO;
use PDOException;

/**
 * データベース接続クラス
 */
class Database
{
    private $host;
    private $db_name;
    private $username;
    private $password;
    private $conn;

    public function __construct()
    {
        $this->host = getenv('DATABASE_HOST') ?: 'db';
        $this->db_name = getenv('DATABASE_NAME') ?: 'chat_db';
        $this->username = getenv('DATABASE_USER') ?: 'chat_user';
        $this->password = getenv('DATABASE_PASSWORD') ?: 'chat_password';
    }

    /**
     * データベース接続を取得する
     *
     * @return PDO|null
     */
    public function connect()
    {
        $this->conn = null;

        try {
            $dsn = "pgsql:host=" . $this->host . ";port=5432;dbname=" . $this->db_name;
            $this->conn = new PDO($dsn, $this->username, $this->password);
            $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            $this->conn->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
        } catch (PDOException $e) {
            // 本番環境ではエラーログに出力するなど適切な処理を行う
            error_log("Connection error: " . $e->getMessage());
        }

        return $this->conn;
    }
}
