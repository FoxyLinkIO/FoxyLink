pipeline {
    agent any
    
    stages {
        stage('QASonar') {
            steps {   
                //try {
                    cmd("${SONAR_HOME}/bin/sonnar-scanner -Dsonar.login=${SONAR_LOGIN} -Dsonar.analysis.mode=issues -Dsonar.projectVersion=0.9.9.338")
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
