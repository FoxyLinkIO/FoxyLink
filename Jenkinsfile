pipeline {
    agent any
    environment {
        SONAR_LOGIN = credentials('sonar-login')
    }
    stages {
        stage('QASonar') {
            steps { 
                //def sonarcommand = "@\"${SONAR_HOME}/bin/sonar-scanner\""
                //try {
                    cmd("\"${SONAR_HOME}/bin/sonar-scanner\" -Dsonar.login=${SONAR_LOGIN} -Dsonar.analysis.mode=issues -Dsonar.github.pullRequest=${PRNumber} -Dsonar.github.repository=${repository} -Dsonar.github.oauth=${githubOAuth}")
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
