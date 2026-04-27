FROM registry.access.redhat.com/ubi8/php-74:latest

USER root

# PostgreSQL拡張とカバレッジ取得用Xdebugをインストール
RUN dnf install -y php-pdo php-pgsql php-pecl-xdebug && \
    dnf clean all

# テスト時にコードカバレッジを取得できるようにする
RUN printf '%s\n' \
    'zend_extension=xdebug.so' \
    'xdebug.mode=coverage' \
    'xdebug.start_with_request=no' \
    > /etc/php.d/15-xdebug.ini

# タイムゾーン設定
ENV TZ=Asia/Tokyo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# S2Iイメージのドキュメントルートに対して AllowOverride All を設定
RUN sed -i 's/AllowOverride None/AllowOverride All/g' /opt/app-root/etc/conf.d/*.conf 2>/dev/null || true

# S2I 標準の起動スクリプトを使用
CMD ["/usr/libexec/s2i/run"]
