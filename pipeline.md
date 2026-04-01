# pipeline.md

## 목표
- Jenkins 컨테이너에서 GitHub 저장소를 checkout 한다.
- Python 실행과 테스트를 통과한 뒤 Docker 이미지를 빌드한다.
- Harbor Registry(`amdp-registry.skala-ai.com/skala26a-ai2`)에 `skala050-jenkins` 이미지를 push 한다.
- GitHub Webhook으로 Jenkins 빌드가 자동 실행되도록 연결한다.
- 현재 실행 중인 Jenkins 컨테이너 `748ff3f40b09`를 기준으로 설정한다.

## 사용 파일
- Jenkins 컨테이너 이미지 정의: `Dockerfile.jenkins`
- 애플리케이션 이미지 정의: `Dockerfile`
- Jenkins 저장소 기반 파이프라인: `Jenkinsfile`
- Jenkins UI에 직접 붙여넣을 파이프라인: `jenkins_pipeline.sh`
- Jenkins 컨테이너 실행: `docker-compose.yaml`
- Jenkins 플러그인 목록: `jenkins-ci-plugins.txt`
- Jenkins 플러그인 설치 스크립트: `install-jenkins-ci-plugins.sh`
- 참조 환경 변수: `.env`

## 사전 조건
- 로컬에 Docker가 설치되어 있어야 한다.
- Jenkins 컨테이너 `748ff3f40b09`가 실행 중이어야 한다.
- GitHub 저장소는 `https://github.com/dylee00/skala-jenkins`를 사용한다.
- Harbor 프로젝트 경로는 `.env`의 `DOCKER_LOGIN` 값을 사용한다.
- Jenkins에서 사용할 Credentials ID는 아래 이름으로 맞춘다.
  - GitHub PAT: `github-pat`
  - Harbor 계정: `harbor-robot`

## Jenkins Credentials 등록 규칙
- `github-pat`
  - Kind: `Username with password`
  - Username: `.env`의 `USERNAME`
  - Password: `.env`의 `PERSONAL_ACCESS_TOKENS`
- `harbor-robot`
  - Kind: `Username with password`
  - Username: `.env`의 `DOCKER_ID`
  - Password: `.env`의 `DOCKER_PASSWORD`

## 상세 작업 절차
1. Jenkins 컨테이너 상태 확인
   - 대상 컨테이너 ID: `748ff3f40b09`
   - 확인 명령: `docker ps --filter id=748ff3f40b09`
   - 추가 확인 명령: `docker inspect -f '{{.Name}} {{.State.Status}}' 748ff3f40b09`
   - 완료 기준: 대상 컨테이너 상태가 `running` 이어야 한다.

2. Jenkins 플러그인 설치
   - 실행 명령: `./install-jenkins-ci-plugins.sh 748ff3f40b09`
   - 필수 플러그인: `workflow-aggregator`, `git`, `github`, `credentials-binding`, `pipeline-model-definition`
   - 완료 기준: Jenkins 재시작 후 플러그인이 활성화되어야 한다.

3. Jenkins 관리자 초기 설정
   - 브라우저에서 `http://localhost:8080` 접속
   - 관리자 계정 생성
   - `Manage Jenkins > Credentials`에서 `github-pat`, `harbor-robot` 추가
   - 완료 기준: 두 credential이 정확한 ID로 등록되어야 한다.

4. Jenkins Pipeline Job 생성
   - Job 타입: `Pipeline`
   - Pipeline 정의 방식은 두 가지 중 하나를 선택한다.
   - 저장소 기반 권장안
     - `Pipeline script from SCM`
     - SCM: `Git`
     - Repository URL: `https://github.com/dylee00/skala-jenkins.git`
     - Credentials: `github-pat`
     - Branch: `*/main`
     - Script Path: `Jenkinsfile`
   - 수동 입력 대안
     - `Pipeline script`
     - 현재 디렉토리의 `jenkins_pipeline.sh` 내용을 그대로 붙여넣기
   - 완료 기준: Job 설정 저장 후 syntax 오류 없이 열려야 한다.

5. 기존 Jenkins 컨테이너 내부 실행 환경 점검
   - 확인 명령: `docker exec 748ff3f40b09 sh -lc 'python3 --version'`
   - 확인 명령: `docker exec 748ff3f40b09 sh -lc 'git --version'`
   - 확인 명령: `docker exec 748ff3f40b09 sh -lc 'docker --version'`
   - 완료 기준: `python3`, `git`, `docker` CLI가 모두 사용 가능해야 한다.
   - 하나라도 없으면 현재 문서만으로는 Harbor push가 불가능하므로 `Dockerfile.jenkins` 기준으로 Jenkins 이미지를 다시 구성해야 한다.

6. 파이프라인 수동 1회 실행
   - `Build Now` 실행
   - 확인 항목
     - `Checkout` 단계에서 GitHub clone 성공
     - `Build` 단계에서 `python3 app.py` 성공
     - `Test` 단계에서 `python3 test_app.py` 성공
     - `Docker Build` 단계에서 이미지 2개 태그 생성
     - `Harbor Push` 단계에서 Harbor push 성공
   - 완료 기준: `${DOCKER_LOGIN}/skala-jenkins:latest` 이미지가 Harbor에 보여야 한다.

7. Jenkins 외부 공개 준비
   - ngrok 설치 후 Jenkins 8080 포트를 외부에 공개한다.
   - 예시 명령: `ngrok http 8080`
   - Jenkins URL은 `Manage Jenkins > System` 또는 `Configure System`에서 ngrok 주소로 맞춘다.
   - 완료 기준: 외부 브라우저에서 Jenkins에 접근 가능해야 한다.

8. GitHub Webhook 등록 요청
   - 사용자에게 아래 정보를 전달하고 Webhook 등록을 요청한다.
   - Payload URL: `https://<ngrok-domain>/github-webhook/`
   - Content type: `application/json`
   - Events: `Just the push event`
   - 완료 기준: 사용자가 GitHub 저장소 Webhook 추가를 완료해야 한다.

9. Webhook 자동 빌드 검증
   - GitHub 저장소 `main` 브랜치에 새 커밋 push
   - Jenkins Job이 자동으로 시작되는지 확인
   - Harbor에서 신규 태그 또는 최신 `latest` 갱신 확인
   - 완료 기준: GitHub push 이후 Jenkins와 Harbor가 모두 자동 갱신되어야 한다.

## 파이프라인 동작 요약
- `Checkout`: GitHub 저장소를 `github-pat` credential로 clone
- `Build`: `python3 app.py` 실행
- `Test`: `python3 test_app.py` 실행
- `Docker Build`: 현재 저장소의 `Dockerfile`로 이미지 빌드
- `Harbor Push`: `harbor-robot` credential로 Harbor 로그인 후 `BUILD_NUMBER`, `latest` 태그 push

## 확인이 필요한 운영 항목
- 현재 실행 중인 `748ff3f40b09` 컨테이너에 `python3`, `git`, `docker` CLI가 없으면 파이프라인이 중간에 실패한다.
- GitHub 기본 브랜치가 `main`이 아니면 `Jenkinsfile`의 branch 값을 수정해야 한다.
- Harbor 프로젝트 경로가 바뀌면 `Jenkinsfile`과 `jenkins_pipeline.sh`의 `HARBOR_REGISTRY`를 함께 수정해야 한다.
- `.env`의 민감 정보는 Jenkins 등록 후 별도 비밀 저장소로 옮기거나 회전하는 것이 안전하다.
