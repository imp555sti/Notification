<?php

namespace Lib;

use PDO;

/**
 * メッセージ関連のビジネスロジックを扱うクラス
 */
class MessageService
{
    private $conn;
    private $table_name = "messages";

    public function __construct($db)
    {
        $this->conn = $db;
    }

    /**
     * メッセージを送信する
     *
     * @param int $sender_id
     * @param int $receiver_id
     * @param string $content
     * @return bool
     */
    public function sendMessage($sender_id, $receiver_id, $content)
    {
        $query = "INSERT INTO " . $this->table_name . " (sender_id, receiver_id, content) VALUES (:sender_id, :receiver_id, :content)";
        $stmt = $this->conn->prepare($query);

        $stmt->bindParam(":sender_id", $sender_id);
        $stmt->bindParam(":receiver_id", $receiver_id);
        $stmt->bindParam(":content", $content);

        if ($stmt->execute()) {
            return true;
        }
        return false;
    }

    /**
     * メッセージ履歴を取得する
     *
     * @param int $user1_id
     * @param int $user2_id
     * @return array
     */
    public function getMessages($user1_id, $user2_id)
    {
        $query = "SELECT m.*, u.name as sender_name 
                  FROM " . $this->table_name . " m
                  JOIN users u ON m.sender_id = u.id
                  WHERE (sender_id = :user1_id AND receiver_id = :user2_id) 
                     OR (sender_id = :user2_id AND receiver_id = :user1_id)
                  ORDER BY created_at ASC";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":user1_id", $user1_id);
        $stmt->bindParam(":user2_id", $user2_id);
        $stmt->execute();

        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    /**
     * 新着メッセージや状態変更を確認する (ポーリング用)
     *
     * @param int $receiver_id
     * @param int $sender_id
     * @param string|null $last_check_time
     * @return array
     */
    public function checkUpdates($receiver_id, $sender_id, $last_check_time = null)
    {
        // 未読メッセージ (相手から自分へ)
        $query_unread = "SELECT count(*) as unread_count 
                         FROM " . $this->table_name . " 
                         WHERE sender_id = :sender_id 
                           AND receiver_id = :receiver_id 
                           AND is_read = false";
        
        $stmt = $this->conn->prepare($query_unread);
        $stmt->bindParam(":sender_id", $sender_id);
        $stmt->bindParam(":receiver_id", $receiver_id);
        $stmt->execute();
        $unread_data = $stmt->fetch(PDO::FETCH_ASSOC);
        $unread_count = $unread_data['unread_count'] ?? 0;

        // 最新の更新 (新規メッセージ、編集、削除)
        // last_check_time 以降に created_at または updated_at があるものを取得
        $updates = [];
        if ($last_check_time) {
            $query_updates = "SELECT * FROM " . $this->table_name . "
                              WHERE ((sender_id = :sender_id AND receiver_id = :receiver_id) 
                                  OR (sender_id = :receiver_id AND receiver_id = :sender_id))
                                AND (created_at > :last_check OR updated_at > :last_check)
                              ORDER BY created_at ASC";
             $stmt = $this->conn->prepare($query_updates);
             $stmt->bindParam(":sender_id", $sender_id);
             $stmt->bindParam(":receiver_id", $receiver_id);
             $stmt->bindParam(":last_check", $last_check_time);
             $stmt->execute();
             $updates = $stmt->fetchAll(PDO::FETCH_ASSOC);
        }

        return [
            'unread_count' => $unread_count,
            'updates' => $updates,
            'timestamp' => date('Y-m-d H:i:s')
        ];
    }

    /**
     * メッセージを既読にする
     *
     * @param int $sender_id
     * @param int $receiver_id
     * @return bool
     */
    public function markAsRead($sender_id, $receiver_id)
    {
        $query = "UPDATE " . $this->table_name . " 
                  SET is_read = true 
                  WHERE sender_id = :sender_id 
                    AND receiver_id = :receiver_id
                    AND is_read = false";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":sender_id", $sender_id);
        $stmt->bindParam(":receiver_id", $receiver_id);
        
        return $stmt->execute();
    }
    
    /**
     * メッセージを編集する
     *
     * @param int $message_id
     * @param int $user_id
     * @param string $content
     * @return bool
     */
    public function editMessage($message_id, $user_id, $content)
    {
        // 自分のメッセージかつ、一定時間内(要件にはないが一般的に)等の制限があればここでチェック
        // 今回は「直近の送信」とあるので、とりあえず自分のメッセージであることだけチェック
        
        $query = "UPDATE " . $this->table_name . "
                  SET content = :content, status = 'edited', updated_at = CURRENT_TIMESTAMP
                  WHERE id = :id AND sender_id = :user_id";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":content", $content);
        $stmt->bindParam(":id", $message_id);
        $stmt->bindParam(":user_id", $user_id);
        
        return $stmt->execute();
    }

    /**
     * メッセージを取り消す(論理削除)
     *
     * @param int $message_id
     * @param int $user_id
     * @return bool
     */
    public function deleteMessage($message_id, $user_id)
    {
        $query = "UPDATE " . $this->table_name . "
                  SET status = 'deleted', updated_at = CURRENT_TIMESTAMP
                  WHERE id = :id AND sender_id = :user_id";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":id", $message_id);
        $stmt->bindParam(":user_id", $user_id);
        
        return $stmt->execute();
    }
}
