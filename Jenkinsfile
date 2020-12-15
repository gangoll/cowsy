pipeline {
    agent  any
    
    tools {
  terraform 'terraform'
   }
    stages {
        stage('pull') {
            steps {
                
   

                sh 'git init || true'
                sh ' git pull git@github.com:gangoll/cowsy.git  || git clone git@github.com:gangoll/cowsy.git .'
                script {
                    commit=sh (script: "git log -1 | tail -1", returnStdout: true).trim()
                   
                }
                echo "${commit}"
                
            
        }

        }          
      
 


        // stage('build') { // new container to test
        //     steps {
        //         script{
                   
        //                 dir('cowsay'){ 
        //                     sh "docker build -t cowsay:test  ."
        //                     sh "docker run -d --name=cowsay_test -p 200:200 cowsay:test"

        //                 }
       
        //             }
        //         }
        //     }
        
        // stage('test') {
            
        //     steps { 
        //             catchError {
        //             script{             //if script returns 1 the job will fail!!
        //                 echo "testing..."
        //                 sh "sleep 15"
        //                 sh 'chmod +x test.sh || true'
        //                  RESULT=sh './test.sh'
        //                 // RESULT=sh (script: './test.sh', returnStdout: true).trim()
        //                 echo "Result: ${RESULT}"
        //              }
                 
        //      }}
        // }
        
        stage('deploy')
        {

        when {
                    expression {BRANCH_NAME =~ /^(master$| release\/*)/ || commit == "test"
                    }
        }
        steps
        {
        
          script{       
                     dir('cowsay')  {
                        echo "depploying..."
                        sh "cp /home/ubuntu/access_code ."
                        sh "cp /home/ubuntu/key.pem ."
                        sh "./rep.sh"
                        sh "terraform init || true"
                       sh "terraform destroy --auto-approve || true"
                       sh "terraform apply --auto-approve"


                       
                        
                    
                         }}
        }
        }
    }

    post {
        always{
            echo 'Removing testing containers:'
            sh "docker rm -f cowsay_test || true" //app container
             
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

