<?php

declare(strict_types=1);

namespace Tests\Unit\Lib;

use Lib\Database;
use PHPUnit\Framework\TestCase;
use ReflectionClass;

/**
 * Databaseの単体テスト
 */
class DatabaseTest extends TestCase
{
    /** @var array<string, string|false> */
    private array $originalEnv = [];

    protected function setUp(): void
    {
        parent::setUp();

        foreach ($this->getManagedEnvKeys() as $key) {
            $this->originalEnv[$key] = getenv($key);
        }
    }

    protected function tearDown(): void
    {
        foreach ($this->originalEnv as $key => $value) {
            if ($value === false) {
                putenv($key);
                continue;
            }

            putenv($key . '=' . $value);
        }

        parent::tearDown();
    }

    /**
     * @testdox 環境変数が無い場合は既定の接続情報を使う
     */
    public function testConstructorUsesDefaultConfigurationWhenEnvironmentVariablesAreMissing(): void
    {
        foreach ($this->getManagedEnvKeys() as $key) {
            putenv($key);
        }

        $database = new Database();

        $this->assertSame('db', $this->readPrivateProperty($database, 'host'));
        $this->assertSame('chat_db', $this->readPrivateProperty($database, 'db_name'));
        $this->assertSame('chat_user', $this->readPrivateProperty($database, 'username'));
        $this->assertSame('chat_password', $this->readPrivateProperty($database, 'password'));
    }

    /**
     * @testdox 環境変数がある場合は既定値より優先する
     */
    public function testConstructorPrefersEnvironmentVariablesOverDefaults(): void
    {
        putenv('DATABASE_HOST=test-host');
        putenv('DATABASE_NAME=test-db');
        putenv('DATABASE_USER=test-user');
        putenv('DATABASE_PASSWORD=test-password');

        $database = new Database();

        $this->assertSame('test-host', $this->readPrivateProperty($database, 'host'));
        $this->assertSame('test-db', $this->readPrivateProperty($database, 'db_name'));
        $this->assertSame('test-user', $this->readPrivateProperty($database, 'username'));
        $this->assertSame('test-password', $this->readPrivateProperty($database, 'password'));
    }

    /**
     * @testdox 接続失敗時は null を返す
     */
    public function testConnectReturnsNullWhenConnectionFails(): void
    {
        putenv('DATABASE_HOST=db');
        putenv('DATABASE_NAME=chat_db');
        putenv('DATABASE_USER=chat_user');
        putenv('DATABASE_PASSWORD=invalid_password_for_test');

        $database = new Database();

        $this->assertSame(null, $database->connect());
    }

    /**
     * @return array<int, string>
     */
    private function getManagedEnvKeys(): array
    {
        return [
            'DATABASE_HOST',
            'DATABASE_NAME',
            'DATABASE_USER',
            'DATABASE_PASSWORD',
        ];
    }

    /**
     * @return mixed
     */
    private function readPrivateProperty(Database $database, string $propertyName)
    {
        $reflection = new ReflectionClass($database);
        $property = $reflection->getProperty($propertyName);
        $property->setAccessible(true);

        return $property->getValue($database);
    }
}