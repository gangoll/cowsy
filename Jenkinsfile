pipeline {
    agent any
    tools {
  terraform 'terraform'
          

    }
    stages {
        stage('pull') {
            steps {
                sh 'git pull git@github.com:gangoll/ted-search.git || git clone  git@github.com:gangoll/ted-search.git .'
                script {
                    commit=sh (script: "git log -1 | tail -1", returnStdout: true).trim()
                   
                }
                echo "${commit}"
                
            }
        }          
      
 

        stage('build') { // new container to test
            steps {
                script{
                    sh 'docker network create testing || true'
                   
                        dir('cowsay'){ 
                            sh "docker build -t cowsay:test  ."
                            sh "docker run -d --network testing --name=cowsay cowsay"
                           
                        }
                    
                    
            
                    }
                }
            }
        
        stage('test') {
            
            steps { 
                 dir('app'){
                    script{             //if script returns 1 the job will fail!!
                        echo "testing..."
                        sh 'chmod +x test.sh || true'
                        RESULT=sh (script: './test.sh', returnStdout: true).trim()
                        echo "Result: ${RESULT}"
                     }
                 }
             }
        }
        
        stage('deply')
        {

        when {
                    expression {BRANCH_NAME =~ /^(master$| release\/*)/ || commit == "test"
                    }
        }
        steps
        {
        
          script{             //if script returns 1 the job will fail!!
                        echo "depploying..."
                        sh "terraform init || true"
                       sh "terraform destroy -auto-approve || true"
                       sh "terraform apply -auto-approve"
                        
                     if ("${commit}" == "test"){
                        sh '''
                        sed -i "s/localhost:8080/$(head -1 to-replace)/g" test.sh
                         ./test.sh
                         '''
                        }
                         }
        }
        }
    }

    post {
        always{
            echo 'Removing testing containers:'
            sh "docker rm -f cowsay || true" //app container
            sh "docker rm -f cowsay || true" 
        }

        success{     
            script{           
               
                
                     
                     mail to: "gangoll1992@gmail.com"
                     subject: "${env.JOB_NAME} - (${env.BUILD_NUMBER}) Successfuly"
                     body: "APP building SUCCESSFUL!, see console output at ${env.BUILD_URL} to view the results"
                
            }                
        }
        

        failure{  
            script{   

                
                           mail to: "gangoll1992@gmail.com"
                           subject: "${env.JOB_NAME} - (${env.BUILD_NUMBER}) FAILED"
                           body: "APP building FAIL!, Check console output at ${env.BUILD_URL} to view the results"
                
                
            }
        }
    } 
}

