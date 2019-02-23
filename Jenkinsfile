pipeline {
    agent any
    
    stages {
        stage('QASonar') {
            steps {
                try {
                    echo "FoxyLink"
                } catch (e) {
                    echo "Sonar status : ${e}"
                }
            }
        }
    }
}
