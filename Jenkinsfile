#!groovy

def PRNumber
def sonarCommand
def version

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
                    sonarCommand = "\"${SONAR_HOME}/bin/sonar-scanner\" -Dsonar.login=${env.SONAR_TOKEN}"
                    if (env.BRANCH_NAME == "master") {
                        echo "Analysing master branch"
                    } else if (env.BRANCH_NAME == "develop") {
                        echo "Analysing develop branch" 
                        def conf = new XmlSlurper().parse("${WORKSPACE}/src/Configuration.xml")
                        conf.children().children().children().each { 
                            if (it.name() == "Version") { 
                                version = it.toString() 
                            } 
                        }
                        sonarCommand = sonarCommand + " -Dsonar.projectVersion=${version}"    
                    } else if (env.BRANCH_NAME.startsWith("PR-")) {
                        PRNumber = env.BRANCH_NAME.tokenize("PR-")[0]
                        sonarCommand = sonarCommand + " -Dsonar.analysis.mode=preview -Dsonar.github.pullRequest=${PRNumber} -Dsonar.github.repository=FoxyLinkIO/FoxyLink -Dsonar.github.oauth=${env.GITHUB_TOKEN}"
                    }
                }
                echo sonarCommand
                //cmd(sonarCommand)
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
