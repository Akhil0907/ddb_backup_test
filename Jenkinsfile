// Declare variables as Groovy string variables
String credentialsId = 'github_ssh_key'
String awsCredentialsId = 'aws-credential-mfa'
String branchName = 'main'
String repoName = 'ddb_backup_test'
String envUrl = "git@github.com:Akhil0907/${repoName}.git"


pipeline {
    agent any

  parameters {
    string(name: 'aws_region', defaultValue: params.aws_region_primary ?: 'us-east-1')
    string(name: 'restore_from_backup_table_address', defaultValue: params.restore_from_backup_table_address ?: '')
   
  }
    environment {
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
            sh 'terraform init -no-color -var-file="values.tfvars"'
        }
    }
}

        stage('DynamoDB Table Restore') {
            when {
                expression { return params.restore_from_backup_table_address?.trim() }
            }
            steps {
                script {
                    // Install AWS CLI if not already installed
                    sh '''
                if ! command -v aws &> /dev/null
               then
                curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                unzip awscliv2.zip
                ./aws/install -i ${AWS_CLI_DIR} -b ${AWS_CLI_DIR}/bin
            fi
            '''

                    // Extract the table name using terraform state show and regular expressions
                    def terraformStateOutput = sh(script: "terraform state show ${params.restore_from_backup_table_address}", returnStdout: true).trim()
                    def cleanTerraformStateOutput = terraformStateOutput.replaceAll(/\x1B\[[0-9;]*[mK]/, '')
                    def tableNameMatcher = cleanTerraformStateOutput =~ /name\s+=\s+"([^"]+)"/
                    def currentTableName = tableNameMatcher ? tableNameMatcher[0][1] : null

                    if (currentTableName) {
                        def newTableName
                        def tableVersionMatcher = currentTableName =~ /-v(\d+)$/
                        if (tableVersionMatcher) {
                            def currentVersion = tableVersionMatcher[0][1] as int
                            def newVersion = currentVersion + 1
                            newTableName = currentTableName.replaceFirst(/-v\d+$/, "-v${newVersion}")
                        } else {
                            newTableName = "${currentTableName}-v1"
                        }
                        env.CURRENT_TABLE_NAME = currentTableName
                        env.NEW_TABLE_NAME = newTableName

                        echo "Extracted DynamoDB Table Name: ${currentTableName}"
                        echo "New DynamoDB Table Name: ${newTableName}"
                      } else {
                            error 'DynamoDB table name not found in Terraform state'
                        }
                }
            }
        }
                 stage('restore') {
              steps {
                    script {
                            // Restore the table
                     sh """
                      aws dynamodb restore-table-to-point-in-time \
                      --source-table-name ${env.CURRENT_TABLE_NAME} \
                      --target-table-name ${env.NEW_TABLE_NAME} \
                      --use-latest-restorable-time \
                      --region ${aws_region}
                      """
                    
                      sh "aws dynamodb wait table-exists --table-name ${env.NEW_TABLE_NAME}"

                      sh "terraform state rm ${params.restore_from_backup_table_address} || true"
                      sh "terraform import ${params.restore_from_backup_table_address} ${env.NEW_TABLE_NAME}"
                      sh "terraform plan -no-color -var-file="values.tfvars""
                      sh "terraform apply -no-color -var-file="values.tfvars" -auto-approve"
     
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
