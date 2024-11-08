// Declare variables as Groovy string variables
String awsCredentialsId = 'aws_credentials' // Replace with your actual credentials ID
String awsCredentialsFile = 'aws_credentials.json' // Path to the file in the Jenkins workspace
String credentialsId = 'github_ssh_key'
String branchName = 'main'
String repoName = 'ddb_backup_test'
String envUrl = "git@github.com:Akhil0907/${repoName}.git"
String sourceTable = 
String destinationTable = 

pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        AWS_CLI_DIR = "${env.WORKSPACE}/aws-cli" // Custom installation directory for AWS CLI
        PATH = "${env.AWS_CLI_DIR}/v2/current/bin:${env.PATH}" // Add AWS CLI to PATH
    }
    
    tools {
        terraform 'terraform 1.9.8' // Ensure this version is configured in Jenkins
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

        stage('Terraform Init') {
            steps {
                script {
                    sh 'terraform init'
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
                        // Read AWS credentials from the JSON string
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
                    // Restore the DynamoDB table to a specific point in time
                    sh '''
                    aws dynamodb restore-table-to-point-in-time \
                    --source-table-name ${sourceTable} \
                    --target-table-name ${destinationTable} \
                    --use-latest-restorable-time
                    '''
                }
            }
        }

         stage('Import table') {
            steps {
                script {
                    // Restore the DynamoDB table to a specific point in time
                    sh '''
                     terraform import aws_dynamodb_table.content ${destinationTable}
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                script {
                    // Restore the DynamoDB table to a specific point in time
                    sh '''
                     terraform plan -var="table_name=${destinationTable}"
                    '''
                }
            }
        }
        
        stage('Terraform Apply') {
            steps {
                script {
                    // Restore the DynamoDB table to a specific point in time
                    sh '''
                     terraform apply -var="table_name=${destinationTable}"
                    '''
                }
            }
        }
    }
    
    post {
        always {
            // Clean up workspace
            cleanWs()
        }
    }
}
