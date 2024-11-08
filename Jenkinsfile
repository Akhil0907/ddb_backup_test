String awsCredentialsId = 'aws_credentials'
String awsCredentialsFile = 'aws_credentials.json'
String credentialsId = 'github_ssh_key'
String branchName = 'main'
String repoName = 'ddb_backup_test'
String envUrl = "git@github.com:Akhil0907/${repoName}.git"
String sourceTable = 
String destinationTable = 
String backupArn = 

pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        AWS_CLI_DIR = "${env.WORKSPACE}/aws-cli"
        PATH = "${env.AWS_CLI_DIR}/v2/current/bin:${env.PATH}"
    }
    
    tools {
        terraform 'terraform 1.9.8'
    }

    stages {
        stage('Checkout') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: credentialsId, keyFileVariable: 'SSH_KEY')]) {
                    sh """
                    GIT_SSH_COMMAND="ssh -i \$SSH_KEY -o StrictHostKeyChecking=no" git clone --depth=1 --branch ${branchName} ${envUrl}
                    """
                }
            }
        }

      stage('Install AWS CLI') {
         steps {
                 sh """
                if ! command -v aws &> /dev/null
               then
                curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                unzip awscliv2.zip
                ./aws/install -i ${AWS_CLI_DIR} -b ${AWS_CLI_DIR}/bin
            fi
            """
        }
    }

         stage('Read AWS Credentials') {
            steps {
                withCredentials([file(credentialsId: 'aws_credentials', variable: 'AWS_CREDENTIALS_FILE')]) {
                    script {
                        def awsCredentials = readJSON file: AWS_CREDENTIALS_FILE
                        env.AWS_ACCESS_KEY_ID = awsCredentials.AccessKeyId
                        env.AWS_SECRET_ACCESS_KEY = awsCredentials.SecretAccessKey
                        env.AWS_SESSION_TOKEN = awsCredentials.SessionToken 
                    }
                }
            }
        }

          stage('Restore Table using PITR') {
            steps {
                script {
                    sh '''
                    aws dynamodb restore-table-to-point-in-time \
                    --source-table-name ${sourceTable} \
                    --target-table-name ${destinationTable} \
                    --use-latest-restorable-time
                    '''
                }
            }
        }

          stage('Restore Table using on demand backup') {
            steps {
                script {
                    sh '''
                    aws dynamodb restore-table-from-backup \
                    --target-table-name ${destinationTable} \
                    --backup-arn ${backupArn} \
                    --use-latest-restorable-time
                    '''
                }
            }
        }
    
         stage('Wait for Restore') {
            steps {
                script {
                    sh '''
                    aws dynamodb wait table-exists \
                    --table-name ${destinationTable}
                    '''
                }
            }
        }

        stage('Verify Restored Table') {
           steps  {
               script  {
                   sh '''
                   aws dynamodb describe-table --table-name ${destinationTable}
                   '''
               }
           }
              
        }
              
        stage('Terraform Init') {
            steps {
                script {
                    sh 'terraform init'
                }
            }
        }

         stage('Import table') {
            steps {
                script {
                    sh '''
                     terraform import aws_dynamodb_table.content ${destinationTable}
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                script {
                    sh '''
                     terraform plan -var="table_name=${destinationTable}"
                    '''
                }
            }
        }
        
        stage('Terraform Apply') {
            steps {
                script {
                    sh '''
                     terraform apply -var="table_name=${destinationTable}"
                    '''
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
    }
}
