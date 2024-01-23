#!/usr/bin/env bash
set -eE

# Pre-pre-flight? 🤷
if [[ -n "$MSYSTEM" ]]; then
  echo "Seems like you are using an MSYS2-based system (such as Git Bash) which is not supported. Please use WSL instead."
  exit 1
fi

source install/_lib.sh

# Pre-flight. No impact yet.
source install/parse-cli.sh
source install/detect-platform.sh
source install/dc-detect-version.sh
source install/error-handling.sh
# We set the trap at the top level so that we get better tracebacks.
trap_with_arg cleanup ERR INT TERM EXIT

# 从当前 git 获取最新commit
source install/check-latest-commit.sh

# 检查 docker / docker-compose / cpu / mem / kvm 是否满足要求
source install/check-minimum-requirements.sh

# Let's go! Start impacting things.
# 关闭相关联的service
source install/turn-things-off.sh

# 创建中间件依赖的 volume
source install/create-docker-volumes.sh

# 创建默认配置
source install/ensure-files-from-examples.sh

source install/ensure-relay-credentials.sh

# 生成一个随机密钥，替换 sentry conf 内的的随机密钥
source install/generate-secret-key.sh

# 拉取 docker-compose.yml 里的镜像
source install/update-docker-images.sh

# docker-compose build
source install/build-docker-images.sh

# 下载 postgres wal2json 插件
source install/install-wal2json.sh


source install/bootstrap-snuba.sh

# 创建 kafka topic
source install/create-kafka-topics.sh

# 如果 pg 是9.6版本则升级到14
source install/upgrade-postgres.sh

# 执行 web upgrade
source install/set-up-and-migrate-database.sh

source install/geoip.sh

# 先启动除 relay 和 nginx 以外的所有服务，再启动 relay, 再 reload nginx
source install/wrap-up.sh
