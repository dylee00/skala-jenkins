# PLANS.md

## Jenkins 환경 준비
- [x] Jenkins 컨테이너 `748ff3f40b09` 실행 상태 확인
- [x] Jenkins 컨테이너 내부에서 `python3` 사용 가능 여부 확인
- [x] Jenkins 컨테이너 내부에서 `git` 사용 가능 여부 확인
- [x] Jenkins 컨테이너 내부에서 `docker` CLI 사용 가능 여부 확인
- [x] 필요 시 `Dockerfile.jenkins` 기준으로 Jenkins 이미지 재구성 계획 수립

## Jenkins 플러그인 및 초기 설정
- [x] `install-jenkins-ci-plugins.sh`로 필수 플러그인 설치
- [x] Jenkins 재시작 후 필수 플러그인 활성화 확인
- [x] Jenkins 관리자 계정 생성
- [x] Jenkins에 `github-pat` Credential 등록
- [x] Jenkins에 `harbor-robot` Credential 등록

## Pipeline Job 구성
- [x] Jenkins에서 `Pipeline` 타입 Job 생성
- [x] `Pipeline script from SCM` 방식으로 GitHub 저장소 연결
- [x] 저장소 URL을 `.env`의 `GITHUB_REPO` 값으로 설정
- [x] 브랜치를 `*/main`으로 설정
- [x] Script Path를 `Jenkinsfile`로 설정
- [x] 필요 시 `jenkins_pipeline.sh` 기반 수동 Pipeline 입력 방식 준비

## CI 실행 검증
- [x] Jenkins Job 수동 실행
- [x] GitHub checkout 성공 확인
- [x] `python3 app.py` 실행 성공 확인
- [x] `python3 test_app.py` 테스트 성공 확인
- [x] Docker 이미지 빌드 성공 확인
- [x] Harbor 로그인 성공 확인
- [x] Harbor 이미지 push 성공 확인

## Harbor 배포 검증
- [x] Harbor Registry 경로가 `.env`의 `DOCKER_LOGIN` 값과 일치하는지 확인
- [x] Harbor에서 최신 이미지 업로드 여부 확인
- [x] `latest` 태그 반영 여부 확인

## Webhook 자동화 구성
- [x] `ngrok http 8080`으로 Jenkins 외부 접근 주소 생성
- [x] Jenkins 시스템 URL을 ngrok 주소로 설정
- [x] GitHub 저장소에 Jenkins Webhook 등록
- [x] Webhook Payload URL을 `/github-webhook/` 경로로 설정
- [x] Webhook 이벤트를 push 기준으로 설정

## 자동 빌드 최종 검증
- [x] `main` 브랜치에 검증용 커밋 push
- [x] GitHub Webhook으로 Jenkins Job 자동 실행 확인
- [x] 자동 실행 후 Harbor 이미지 갱신 확인
