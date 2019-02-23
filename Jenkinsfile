def sonarCommand
def PRNumber

pipeline {
    agent any
    environment {
        SONAR_TOKEN = credentials('sonar-login')
        GITHUB_TOKEN = credentials('sonarqube-silverbulleters')
    }
    stages {
        stage('QASonar') {
            steps {
                script {
                    sonarCommand = "\"${SONAR_HOME}/bin/sonar-scanner\""
                    PRNumber = env.BRANCH_NAME.tokenize("PR-")[0]
                }
                //try {
                    cmd(sonarCommand + " -Dsonar.login=${env.SONAR_TOKEN} -Dsonar.github.pullRequest=${PRNumber} -Dsonar.github.repository=FoxyLink -Dsonar.github.oauth=${env.GITHUB_TOKEN}")
                //} catch (e) {
                //    echo 'Sonar status : ${e}'
                //}
            }   
        }
    }
}

def cmd(command) {
    if (isUnix()) {
        sh "${command}"
    } else {
        bat "chcp 65001\n${command}"
    }
}
