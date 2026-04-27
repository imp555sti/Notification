<?php

declare(strict_types=1);

namespace Tests\Unit\Lib;

use Lib\MessageService;
use PDO;
use PDOStatement;
use PHPUnit\Framework\MockObject\MockObject;
use PHPUnit\Framework\TestCase;

/**
 * MessageServiceの単体テスト
 */
class MessageServiceTest extends TestCase
{
    private function createPdoMock(): MockObject
    {
        $pdo = $this->getMockBuilder(PDO::class)
            ->disableOriginalConstructor()
            ->onlyMethods(['prepare'])
            ->getMock();

        return $pdo;
    }

    private function createStatementMock(): MockObject
    {
        $statement = $this->getMockBuilder(PDOStatement::class)
            ->disableOriginalConstructor()
            ->onlyMethods(['bindParam', 'execute', 'fetch', 'fetchAll'])
            ->getMock();

        return $statement;
    }

    /**
     * @testdox 送信SQLの実行成功時に true を返す
     */
    public function testSendMessageReturnsTrueWhenStatementExecutes(): void
    {
        $pdo = $this->createPdoMock();
        $statement = $this->createStatementMock();
        $senderId = 1;
        $receiverId = 2;
        $content = 'hello';

        $pdo->expects($this->once())
            ->method('prepare')
            ->with($this->stringContains('INSERT INTO messages'))
            ->willReturn($statement);

        $statement->expects($this->exactly(3))
            ->method('bindParam')
            ->withConsecutive(
                [':sender_id', $senderId],
                [':receiver_id', $receiverId],
                [':content', $content]
            )
            ->willReturn(true);

        $statement->expects($this->once())
            ->method('execute')
            ->willReturn(true);

        $service = new MessageService($pdo);

        $this->assertTrue($service->sendMessage($senderId, $receiverId, $content));
    }

    /**
     * @testdox 送信SQLの実行失敗時に false を返す
     */

    public function testSendMessageReturnsFalseWhenStatementFails(): void
    {
        $pdo = $this->createPdoMock();
        $statement = $this->createStatementMock();
        $senderId = 1;
        $receiverId = 2;
        $content = 'hello';

        $pdo->expects($this->once())
            ->method('prepare')
            ->willReturn($statement);

        $statement->expects($this->exactly(3))
            ->method('bindParam')
            ->willReturn(true);

        $statement->expects($this->once())
            ->method('execute')
            ->willReturn(false);

        $service = new MessageService($pdo);

        $this->assertFalse($service->sendMessage($senderId, $receiverId, $content));
    }

    /**
     * @testdox 履歴取得で取得した配列をそのまま返す
     */

    public function testGetMessagesReturnsFetchedRows(): void
    {
        $pdo = $this->createPdoMock();
        $statement = $this->createStatementMock();
        $messages = [
            ['id' => 1, 'sender_id' => 1, 'content' => 'first'],
            ['id' => 2, 'sender_id' => 2, 'content' => 'second'],
        ];
        $user1Id = 1;
        $user2Id = 2;

        $pdo->expects($this->once())
            ->method('prepare')
            ->with($this->stringContains('ORDER BY created_at ASC'))
            ->willReturn($statement);

        $statement->expects($this->exactly(2))
            ->method('bindParam')
            ->withConsecutive(
                [':user1_id', $user1Id],
                [':user2_id', $user2Id]
            )
            ->willReturn(true);

        $statement->expects($this->once())
            ->method('execute')
            ->willReturn(true);

        $statement->expects($this->once())
            ->method('fetchAll')
            ->with(PDO::FETCH_ASSOC)
            ->willReturn($messages);

        $service = new MessageService($pdo);

        $this->assertSame($messages, $service->getMessages($user1Id, $user2Id));
    }

    /**
     * @testdox 最終確認時刻がない場合は未読件数と空の更新一覧を返す
     */

    public function testCheckUpdatesWithoutLastCheckTimeReturnsUnreadCountAndEmptyUpdates(): void
    {
        $pdo = $this->createPdoMock();
        $statement = $this->createStatementMock();
        $receiverId = 10;
        $senderId = 20;

        $pdo->expects($this->once())
            ->method('prepare')
            ->with($this->stringContains('count(*) as unread_count'))
            ->willReturn($statement);

        $statement->expects($this->exactly(2))
            ->method('bindParam')
            ->withConsecutive(
                [':sender_id', $senderId],
                [':receiver_id', $receiverId]
            )
            ->willReturn(true);

        $statement->expects($this->once())
            ->method('execute')
            ->willReturn(true);

        $statement->expects($this->once())
            ->method('fetch')
            ->with(PDO::FETCH_ASSOC)
            ->willReturn(['unread_count' => '3']);

        $statement->expects($this->never())
            ->method('fetchAll');

        $service = new MessageService($pdo);
        $result = $service->checkUpdates($receiverId, $senderId);

        $this->assertSame('3', $result['unread_count']);
        $this->assertSame([], $result['updates']);
        $this->assertArrayHasKey('timestamp', $result);
    }

    /**
     * @testdox 最終確認時刻がある場合は更新一覧を含めて返す
     */

    public function testCheckUpdatesWithLastCheckTimeReturnsUnreadCountAndUpdates(): void
    {
        $pdo = $this->createPdoMock();
        $unreadStatement = $this->createStatementMock();
        $updatesStatement = $this->createStatementMock();
        $receiverId = 10;
        $senderId = 20;
        $lastCheckTime = '2026-04-27 12:00:00';
        $updates = [
            ['id' => 9, 'sender_id' => 20, 'content' => 'changed', 'status' => 'edited'],
        ];

        $pdo->expects($this->exactly(2))
            ->method('prepare')
            ->withConsecutive(
                [$this->stringContains('count(*) as unread_count')],
                [$this->stringContains('updated_at > :last_check')]
            )
            ->willReturnOnConsecutiveCalls($unreadStatement, $updatesStatement);

        $unreadStatement->expects($this->exactly(2))
            ->method('bindParam')
            ->withConsecutive(
                [':sender_id', $senderId],
                [':receiver_id', $receiverId]
            )
            ->willReturn(true);

        $unreadStatement->expects($this->once())
            ->method('execute')
            ->willReturn(true);

        $unreadStatement->expects($this->once())
            ->method('fetch')
            ->with(PDO::FETCH_ASSOC)
            ->willReturn(['unread_count' => 1]);

        $updatesStatement->expects($this->exactly(3))
            ->method('bindParam')
            ->withConsecutive(
                [':sender_id', $senderId],
                [':receiver_id', $receiverId],
                [':last_check', $lastCheckTime]
            )
            ->willReturn(true);

        $updatesStatement->expects($this->once())
            ->method('execute')
            ->willReturn(true);

        $updatesStatement->expects($this->once())
            ->method('fetchAll')
            ->with(PDO::FETCH_ASSOC)
            ->willReturn($updates);

        $service = new MessageService($pdo);
        $result = $service->checkUpdates($receiverId, $senderId, $lastCheckTime);

        $this->assertSame(1, $result['unread_count']);
        $this->assertSame($updates, $result['updates']);
        $this->assertArrayHasKey('timestamp', $result);
    }

    /**
     * @testdox 既読更新の実行成功時に true を返す
     */

    public function testMarkAsReadExecutesUnreadUpdateForPair(): void
    {
        $pdo = $this->createPdoMock();
        $statement = $this->createStatementMock();
        $senderId = 7;
        $receiverId = 8;

        $pdo->expects($this->once())
            ->method('prepare')
            ->with($this->stringContains('SET is_read = true'))
            ->willReturn($statement);

        $statement->expects($this->exactly(2))
            ->method('bindParam')
            ->withConsecutive(
                [':sender_id', $senderId],
                [':receiver_id', $receiverId]
            )
            ->willReturn(true);

        $statement->expects($this->once())
            ->method('execute')
            ->willReturn(true);

        $service = new MessageService($pdo);

        $this->assertTrue($service->markAsRead($senderId, $receiverId));
    }

    /**
     * @testdox 既読更新の実行失敗時に false を返す
     */
    public function testMarkAsReadReturnsFalseWhenExecutionFails(): void
    {
        $pdo = $this->createPdoMock();
        $statement = $this->createStatementMock();
        $senderId = 7;
        $receiverId = 8;

        $pdo->expects($this->once())
            ->method('prepare')
            ->willReturn($statement);

        $statement->expects($this->exactly(2))
            ->method('bindParam')
            ->willReturn(true);

        $statement->expects($this->once())
            ->method('execute')
            ->willReturn(false);

        $service = new MessageService($pdo);

        $this->assertFalse($service->markAsRead($senderId, $receiverId));
    }

    /**
     * @testdox 自分のメッセージ編集成功時に true を返す
     */

    public function testEditMessageUpdatesOnlyOwnedMessage(): void
    {
        $pdo = $this->createPdoMock();
        $statement = $this->createStatementMock();
        $messageId = 11;
        $userId = 5;
        $content = 'updated';

        $pdo->expects($this->once())
            ->method('prepare')
            ->with($this->stringContains("status = 'edited'"))
            ->willReturn($statement);

        $statement->expects($this->exactly(3))
            ->method('bindParam')
            ->withConsecutive(
                [':content', $content],
                [':id', $messageId],
                [':user_id', $userId]
            )
            ->willReturn(true);

        $statement->expects($this->once())
            ->method('execute')
            ->willReturn(true);

        $service = new MessageService($pdo);

        $this->assertTrue($service->editMessage($messageId, $userId, $content));
    }

    /**
     * @testdox 自分のメッセージ編集失敗時に false を返す
     */
    public function testEditMessageReturnsFalseWhenExecutionFails(): void
    {
        $pdo = $this->createPdoMock();
        $statement = $this->createStatementMock();
        $messageId = 11;
        $userId = 5;
        $content = 'updated';

        $pdo->expects($this->once())
            ->method('prepare')
            ->willReturn($statement);

        $statement->expects($this->exactly(3))
            ->method('bindParam')
            ->willReturn(true);

        $statement->expects($this->once())
            ->method('execute')
            ->willReturn(false);

        $service = new MessageService($pdo);

        $this->assertFalse($service->editMessage($messageId, $userId, $content));
    }

    /**
     * @testdox 自分のメッセージ削除成功時に true を返す
     */

    public function testDeleteMessageMarksMessageAsDeleted(): void
    {
        $pdo = $this->createPdoMock();
        $statement = $this->createStatementMock();
        $messageId = 11;
        $userId = 5;

        $pdo->expects($this->once())
            ->method('prepare')
            ->with($this->stringContains("status = 'deleted'"))
            ->willReturn($statement);

        $statement->expects($this->exactly(2))
            ->method('bindParam')
            ->withConsecutive(
                [':id', $messageId],
                [':user_id', $userId]
            )
            ->willReturn(true);

        $statement->expects($this->once())
            ->method('execute')
            ->willReturn(true);

        $service = new MessageService($pdo);

        $this->assertTrue($service->deleteMessage($messageId, $userId));
    }

    /**
     * @testdox 自分のメッセージ削除失敗時に false を返す
     */
    public function testDeleteMessageReturnsFalseWhenExecutionFails(): void
    {
        $pdo = $this->createPdoMock();
        $statement = $this->createStatementMock();
        $messageId = 11;
        $userId = 5;

        $pdo->expects($this->once())
            ->method('prepare')
            ->willReturn($statement);

        $statement->expects($this->exactly(2))
            ->method('bindParam')
            ->willReturn(true);

        $statement->expects($this->once())
            ->method('execute')
            ->willReturn(false);

        $service = new MessageService($pdo);

        $this->assertFalse($service->deleteMessage($messageId, $userId));
    }
}