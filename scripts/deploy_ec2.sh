#!/usr/bin/env bash
# EC2 에서 실행되는 배포 스크립트: 저장소를 최신 main 으로 맞추고 docker compose 로 (재)배포합니다.
#  - 여러 번 실행해도 컨테이너가 중복으로 늘지 않습니다 (compose 프로젝트 이름 고정 + 같은 서비스는 교체).
#  - 동시에 두 번 실행되면 두 번째는 바로 종료합니다 (잠금).
#  - 끝에 /health 로 응답을 확인하고, api/web 컨테이너가 각각 1개인지 검사합니다.
#
# 사용 (EC2 안에서):   bash scripts/deploy_ec2.sh
# 환경변수(선택):      REPO_URL, BRANCH(기본 main), APP_DIR(기본 ~/energy_efficiency)
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/mswGGBB/energy_efficiency.git}"
BRANCH="${BRANCH:-main}"
APP_DIR="${APP_DIR:-$HOME/energy_efficiency}"
HEALTH_URL="${HEALTH_URL:-http://localhost/health}"
export COMPOSE_PROJECT_NAME="energy_efficiency"   # 항상 같은 이름 -> 기존 컨테이너를 새 것으로 교체

# 1) 동시 배포 방지
exec 9>"${LOCK_FILE:-/tmp/energy-deploy.lock}"
if ! flock -n 9; then
  echo "이미 다른 배포가 진행 중입니다. 종료합니다."
  exit 1
fi

# 2) 코드를 최신 main 으로 맞추기 (처음이면 clone)
if [ -d "$APP_DIR/.git" ]; then
  cd "$APP_DIR"
  git remote set-url origin "$REPO_URL"
  git fetch --prune origin "+refs/heads/${BRANCH}:refs/remotes/origin/${BRANCH}"
  git checkout -q -B "$BRANCH" "origin/${BRANCH}"
  git reset --hard "origin/${BRANCH}"
else
  git clone --branch "$BRANCH" "$REPO_URL" "$APP_DIR"
  cd "$APP_DIR"
fi
echo "배포 커밋: $(git rev-parse --short HEAD) - $(git log -1 --pretty=%s)"

# 3) 빌드하고 교체 (같은 서비스는 새 컨테이너로 바뀌고, 더 이상 없는 서비스는 제거)
docker compose up --build -d --remove-orphans
docker image prune -f >/dev/null 2>&1 || true     # 오래된 중간 이미지 정리 (디스크 절약)

# 4) 응답 확인 (최대 약 90초)
ok=0
for _ in $(seq 1 30); do
  if curl -fsS "$HEALTH_URL" >/dev/null 2>&1; then ok=1; break; fi
  sleep 3
done
if [ "$ok" != 1 ]; then
  echo "헬스 체크 실패: $HEALTH_URL"
  docker compose ps
  docker compose logs --tail 30
  exit 1
fi

# 5) 중복 배포 검사: api, web 이 각각 정확히 1개여야 함
api=$(docker compose ps -q api | wc -l | tr -d ' ')
web=$(docker compose ps -q web | wc -l | tr -d ' ')
echo "실행 중 컨테이너: api=${api}, web=${web} (둘 다 1이어야 정상)"
if [ "$api" != 1 ] || [ "$web" != 1 ]; then
  echo "컨테이너 개수가 이상합니다."
  docker compose ps
  exit 1
fi
docker compose ps
echo "배포 완료: $(git rev-parse --short HEAD)"
