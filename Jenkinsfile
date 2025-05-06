pipeline {
    agent {
        docker {
            image 'hashicorp/terraform:latest' 
            args '--entrypoint=""'
        }
    }

    environment {
        TF_IN_AUTOMATION = 'true'
    }

    stages {
        stage('Terraform Apply') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'my-AWS-access-keys'
                ]]) {
                    sh '''
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY

                        git clone https://github.com/MuhanedAhmed/jenkins-lab2-task8.git
                        cd jenkins-lab2-task8

                        terraform init
                        terraform apply --auto-approve 
                        terraform destroy --auto-approve 
                    '''
                }
            }
        }
    }
}