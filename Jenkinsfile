// Optional Pipeline equivalent; the course uses the freestyle setup in README.md.
pipeline {
    agent any
    tools { jdk 'jdk21'; maven 'maven3' }
    options {
        skipDefaultCheckout(true)
        disableConcurrentBuilds()
        timeout(time: 20, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }
    stages {
        stage('Checkout') { steps { checkout scm } }
        stage('Test and package') {
            steps {
                dir('.') {
                    sh 'mvn -B -ntp clean verify'
                    sh 'bash scripts/verify-jar.sh'
                }
            }
        }
    }
    post {
        always { junit testResults: 'target/surefire-reports/*.xml', allowEmptyResults: true }
        success { archiveArtifacts artifacts: 'target/mytest.jar', fingerprint: true }
    }
}
