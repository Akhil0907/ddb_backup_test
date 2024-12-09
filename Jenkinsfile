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
    string(name: 'restore_from_backup_time', defaultValue: params.restore_from_backup_time ?: '')
      
   
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
            sh 'terraform init -no-color'
        }
    }
}

            stage('install cli') {
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
                    }
                }
            }
            
        stage('Restore DynamoDB Table') {
            when {
                expression { return params.restore_from_backup_table_address?.trim() }
            }
            steps {
                    // First script block to handle regex operations
                    script {
                        def terraformStateOutput = sh(script: "terraform state show ${restore_from_backup_table_address}", returnStdout: true).trim()
                        def cleanTerraformStateOutput = terraformStateOutput.replaceAll(/\x1B\[[0-9;]*[mK]/, '')

                        // Extract table name
                        def tableNameMatcher = cleanTerraformStateOutput =~ /name\s+=\s+"([^"]+)"/
                        def currentTableName = tableNameMatcher ? tableNameMatcher[0][1] : null
                        env.CURRENT_TABLE_NAME = currentTableName

                        if (currentTableName) {
                            // Determine new table name
                            def tableVersionMatcher = currentTableName =~ /-v(\d+)$/
                            if (tableVersionMatcher) {
                                def currentVersion = tableVersionMatcher[0][1] as int
                                def newVersion = currentVersion + 1
                                env.NEW_TABLE_NAME = currentTableName.replaceFirst(/-v\d+$/, "-v${newVersion}")
                            } else {
                                env.NEW_TABLE_NAME = "${currentTableName}-v2"
                            }
                        } else {
                            error 'DynamoDB table name not found'
                        }
                    }

                    // Second script block to execute shell commands
                    script {
                        sh """
                            aws dynamodb restore-table-to-point-in-time \
                                --source-table-name ${env.CURRENT_TABLE_NAME} \
                                --target-table-name ${env.NEW_TABLE_NAME} \
                                --no-use-latest-restorable-time --restore-date-time ${restore_from_backup_time} \
                                --region{aws_region}
                        """
                        sh "aws dynamodb wait table-exists --table-name ${env.NEW_TABLE_NAME}"
                        sh "terraform state rm ${restore_from_backup_table_address} || true"
                        sh "terraform import ${restore_from_backup_table_address} ${env.NEW_TABLE_NAME}"
                        sh "terraform plan -no-color"
                        sh "terraform apply -no-color -auto-approve"
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
