pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        APP_IMAGE_NAME = 'skala-jenkins'
        HARBOR_REGISTRY = 'amdp-registry.skala-ai.com/skala26a-ai2'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        IMAGE_LATEST = 'latest'
    }

    triggers {
        githubPush()
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'GitHub 저장소를 가져옵니다.'
                git branch: 'main',
                    credentialsId: 'github-pat',
                    url: 'https://github.com/dylee00/skala-jenkins.git'
            }
        }
        stage('Build') {
            steps {
                echo '애플리케이션 빌드를 확인합니다.'
                sh 'python3 app.py'
            }
        }
        stage('Test') {
            steps {
                echo '테스트를 수행합니다.'
                sh 'python3 test_app.py'
            }
        }
        stage('Docker Build') {
            steps {
                echo '배포 이미지를 빌드합니다.'
                sh '''
                    docker build \
                      -t ${HARBOR_REGISTRY}/${APP_IMAGE_NAME}:${IMAGE_TAG} \
                      -t ${HARBOR_REGISTRY}/${APP_IMAGE_NAME}:${IMAGE_LATEST} \
                      .
                '''
            }
        }
        stage('Harbor Push') {
            steps {
                echo 'Harbor Registry로 이미지를 업로드합니다.'
                withCredentials([usernamePassword(
                    credentialsId: 'harbor-robot',
                    usernameVariable: 'HARBOR_USERNAME',
                    passwordVariable: 'HARBOR_PASSWORD'
                )]) {
                    sh '''
                        set -eu
                        echo "${HARBOR_PASSWORD}" | docker login ${HARBOR_REGISTRY} -u "${HARBOR_USERNAME}" --password-stdin
                        docker push ${HARBOR_REGISTRY}/${APP_IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${HARBOR_REGISTRY}/${APP_IMAGE_NAME}:${IMAGE_LATEST}
                        docker logout ${HARBOR_REGISTRY}
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "Harbor 배포 완료: ${HARBOR_REGISTRY}/${APP_IMAGE_NAME}:${IMAGE_TAG}"
        }
        failure {
            echo '파이프라인이 실패했습니다. Jenkins 콘솔 로그를 확인하세요.'
        }
        always {
            sh '''
                docker image rm ${HARBOR_REGISTRY}/${APP_IMAGE_NAME}:${IMAGE_TAG} || true
                docker image rm ${HARBOR_REGISTRY}/${APP_IMAGE_NAME}:${IMAGE_LATEST} || true
            '''
            deleteDir()
        }
    }
}
