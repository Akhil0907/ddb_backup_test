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
     parameters {
    string(name: 'restore_from_backup_table_address', defaultValue: params.restore_from_backup_table_address ?: '')
   
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
            terraform init -no-color -var-file="values.tfvars"
            '''
        }
    }
}

        stage('Append Version to Table Name') {
    steps {
        script {
            def terraformStateOutput = sh(script: "terraform state show ${restore_from_backup_table_address}", returnStdout: true).trim()
            def tableNameMatcher = terraformStateOutput =~ /name\s+=\s+"([^"]+)"/
            def currentTableName = tableNameMatcher ? tableNameMatcher[0][1] : null

            if (currentTableName) {
                echo "Extracted DynamoDB Table Name: ${currentTableName}"
                def newTableName
                def tableVersionMatcher = currentTableName =~ /-v(\d+)$/
                if (tableVersionMatcher) {
                    def currentVersion = tableVersionMatcher[0][1] as int
                    def newVersion = currentVersion + 1
                    newTableName = currentTableName.replaceFirst(/-v\d+$/, "-v${newVersion}")
                } else {
                    newTableName = "${currentTableName}-v1"
                }
                echo "New DynamoDB Table Name: ${newTableName}"
                env.CURRENT_TABLE_NAME = currentTableName
                env.NEW_TABLE_NAME = newTableName
            } else {
                error "DynamoDB table name not found in Terraform state"
            }
        }
    }
}
        
      /*   stage('Restore Table using PITR') {
    steps {
        script {
            sh """
            aws dynamodb restore-table-to-point-in-time \
            --source-table-name ${env.CURRENT_TABLE_NAME} \
            --target-table-name ${env.NEW_TABLE_NAME} \
            --use-latest-restorable-time
            """
        }
    }
}
     
        stage('Wait for Restore') {
            steps {
              script {
                 sh """
                 aws dynamodb wait table-exists \
                 --table-name ${env.NEW_TABLE_NAME}
                """
              }
           }
     }*/
/*
     stage('Terraform Import') {
    steps {
        script {
            // Remove the existing resource from the state
            sh """
            terraform state rm aws_dynamodb_table.content || true
            """

            // Import the resource
            sh """
            terraform import -var-file="values.tfvars" aws_dynamodb_table.content ${env.NEW_TABLE_NAME}
            """
        }
    }
}

        stage('Terraform Plan') {
            steps {
                script {
                    sh """
                     terraform plan -var="dynamodb_table_name=${env.NEW_TABLE_NAME}"
                    """
              }
            }
        }

         stage('Terraform Approve') {
            steps {
                input message: 'Do you want to proceed with Terraform Apply?', ok: 'Approve'
            }
        }
        
        
        stage('Terraform Apply') {
          steps {
               script {
                  sh """
                   yes "yes" | terraform apply -var="dynamodb_table_name=${env.NEW_TABLE_NAME}"
                  """
               }
             }
         }
    */
    }
    post {
        always {
            cleanWs()
        }
    }
}
