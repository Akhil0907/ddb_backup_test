String credentialsId = 'github_ssh_key'
String awsCredentialsId = 'aws-credential-mfa'
String branchName = 'main'
String repoName = 'ddb_backup_test'
String envUrl = "git@github.com:Akhil0907/${repoName}.git"

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
                withCredentials([string(credentialsId: 'aws-credential-mfa', variable: 'AWS_CREDENTIALS_JSON')]) {
                    script {
                        def awsCredentials = readJSON text: AWS_CREDENTIALS_JSON
                        env.AWS_ACCESS_KEY_ID = awsCredentials.AccessKeyId
                        env.AWS_SECRET_ACCESS_KEY = awsCredentials.SecretAccessKey
                        env.AWS_SESSION_TOKEN = awsCredentials.SessionToken 
                    }
                }
            }
        }
        
 stage('Terraform Init') {
    steps {
        script {
            sh '''
            no "no" | terraform init -no-color -var-file="values.tfvars"
            '''
        }
    }
}
 
stage('Append Version to Table Name') {
    steps {
        script {
            // Extract the table name using terraform state show and regular expressions
            def terraformOutput = sh(script: "terraform state show aws_dynamodb_table.sandbox-bkp4", returnStdout: true).trim()
            def matcher = terraformOutput =~ /name\s+=\s+"([^"]+)"/
            def currentTableName = matcher ? matcher[0][1] : null

            if (currentTableName) {
                echo "Extracted DynamoDB Table Name: ${currentTableName}"

                // Append a version number to the current table name
                def newTableName = "${currentTableName}-v1"
                echo "New DynamoDB Table Name: ${newTableName}"

                // Set environment variables for use in other stages
                env.CURRENT_TABLE_NAME = currentTableName
                env.NEW_TABLE_NAME = newTableName
            } else {
                error "DynamoDB table name not found in Terraform state"
            }
        }
    }
}
         stage('Restore Table using PITR') {
            steps {
                script {
                    sh '''
                    aws dynamodb restore-table-to-point-in-time \
                    --source-table-name ${env.CURRENT_TABLE_NAME} \
                    --target-table-name ${env.NEW_TABLE_NAME} \
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
                 --table-name ${env.NEW_TABLE_NAME}
                '''
          }
          }
     }


         stage('Import table') {
        steps {
              script {
                  sh '''
                   terraform import aws_dynamodb_table.content ${env.NEW_TABLE_NAME}
                 '''
             }
         }
        }

    //     stage('Terraform Plan') {
    //         steps {
    //             script {
    //                 sh '''
    //                  terraform plan -var="table_name=backup_table_4"
    //                 '''
    //             }
    //         }
    //     }
        
    //     stage('Terraform Apply') {
    //         steps {
    //             script {
    //                 sh '''
    //                  terraform apply -var="table_name=backup_table_4"
    //                 '''
    //             }
    //         }
    //     }
    // }
    }
    post {
        always {
            cleanWs()
        }
    }
}
