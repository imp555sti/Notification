<?php

declare(strict_types=1);

namespace Tests\Integration\Http\Api;

use PHPUnit\Framework\TestCase;

class FetchEndpointTest extends TestCase
{
    private const HOST = '127.0.0.1';
    private const PORT = 18081;

    /** @var resource|null */
    private static $serverProcess = null;

    /** @var resource[] */
    private static array $pipes = [];

    public static function setUpBeforeClass(): void
    {
        $command = sprintf(
            'php -S %s:%d -t /opt/app-root/src/public',
            self::HOST,
            self::PORT
        );

        $descriptorSpec = [
            0 => ['pipe', 'r'],
            1 => ['pipe', 'w'],
            2 => ['pipe', 'w'],
        ];

        self::$serverProcess = proc_open($command, $descriptorSpec, self::$pipes);

        if (!is_resource(self::$serverProcess)) {
            self::fail('PHP built-in server の起動に失敗しました。');
        }

        self::waitForServerReady();
    }

    public static function tearDownAfterClass(): void
    {
        if (is_resource(self::$serverProcess)) {
            proc_terminate(self::$serverProcess);
            proc_close(self::$serverProcess);
        }

        foreach (self::$pipes as $pipe) {
            if (is_resource($pipe)) {
                fclose($pipe);
            }
        }
    }

    /**
     * @testdox fetch.php は GET 以外で 405 を返す
     */
    public function testFetchReturns405WhenMethodIsNotGet(): void
    {
        [$statusCode, $responseBody] = $this->request(
            'POST',
            '/api/fetch.php?user1_id=1&user2_id=2',
            ''
        );

        $this->assertSame(405, $statusCode);
        $this->assertStringContainsString('Method Not Allowed', $responseBody);
    }

    /**
     * @testdox fetch.php は必須パラメータ不足で 400 を返す
     */
    public function testFetchReturns400WhenRequiredParametersAreMissing(): void
    {
        [$statusCode, $responseBody] = $this->request('GET', '/api/fetch.php?user1_id=1');

        $this->assertSame(400, $statusCode);
        $this->assertStringContainsString('Missing required parameters', $responseBody);
    }

    /**
     * @testdox fetch.php 正常時に messages 配列を返す
     */
    public function testFetchReturnsMessagesArrayOnSuccess(): void
    {
        [$statusCode, $responseBody] = $this->request(
            'GET',
            '/api/fetch.php?user1_id=1&user2_id=2'
        );

        $this->assertSame(200, $statusCode);

        $decoded = json_decode($responseBody, true);

        $this->assertIsArray($decoded);
        $this->assertArrayHasKey('messages', $decoded);
        $this->assertIsArray($decoded['messages']);
    }

    private static function waitForServerReady(): void
    {
        $deadline = microtime(true) + 5.0;

        while (microtime(true) < $deadline) {
            $connection = @fsockopen(self::HOST, self::PORT);
            if (is_resource($connection)) {
                fclose($connection);
                return;
            }

            usleep(100000);
        }

        self::fail('PHP built-in server の起動待機がタイムアウトしました。');
    }

    /**
     * @return array{0:int,1:string}
     */
    private function request(string $method, string $path, string $body = ''): array
    {
        $context = stream_context_create([
            'http' => [
                'method' => $method,
                'header' => "Content-Type: application/json\r\n",
                'content' => $body,
                'ignore_errors' => true,
                'timeout' => 5,
            ],
        ]);

        $responseBody = file_get_contents(
            sprintf('http://%s:%d%s', self::HOST, self::PORT, $path),
            false,
            $context
        );

        $headers = $http_response_header ?? [];
        $statusCode = 0;

        if (isset($headers[0]) && preg_match('/\s(\d{3})\s/', $headers[0], $matches) === 1) {
            $statusCode = (int) $matches[1];
        }

        return [$statusCode, $responseBody !== false ? $responseBody : ''];
    }
}
