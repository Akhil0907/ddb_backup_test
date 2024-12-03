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

  /* stage('Extract and Calculate Table Name') {
            steps {
                script {
    
                    def currentTableName = sh(script: """
                        terraform show -json | jq -r '
                        .values.root_module.resources[] |
                        select(.type == "aws_dynamodb_table" |
                        .values.name
                        '""", returnStdout: true).trim()

                    def newTableName = "${currentTableName}-v1"
                    def version = 1

                    while (sh(script: "aws dynamodb describe-table --table-name ${newTableName}", returnStatus: true) == 0) {
                        version++
                        newTableName = "${currentTableName}-v${version}"
                    }

                    env.CURRENT_TABLE_NAME = currentTableName
                    env.NEW_TABLE_NAME = newTableName
                }
            }
        }*/

      stage('Terraform Init') {
    steps {
        script {
            sh '''
            no "no" | terraform init -no-color -var-file="values.tfvars"
            '''
        }
    }
}

          stage('Extract and Calculate Table Name') {
    steps {
        script {
            sh '''
             terraform state show 'aws_dynamodb_table.sandbox-bkp4'
            '''
        }
    }
}

        /*stage('Extract and Calculate Table Name') {
    steps {
        script {
            // Extract the table name using terraform show and JsonSlurper
            def terraformOutput = sh(script: "terraform show -json", returnStdout: true).trim()
            def jsonSlurper = new groovy.json.JsonSlurper()
            def terraformState = jsonSlurper.parseText(terraformOutput)
            def currentTableName = terraformState.values.root_module.resources.find { it.type == "aws_dynamodb_table" }?.values?.name

            if (currentTableName) {
                echo "Extracted DynamoDB Table Name: ${currentTableName}"

                // Initialize the new table name with the base table name and version
                def newTableName = "${currentTableName}-v1"
                def version = 1

                // Check if the new table name already exists and increment the version if necessary
                while (sh(script: "aws dynamodb describe-table --table-name ${newTableName}", returnStatus: true) == 0) {
                    version++
                    newTableName = "${currentTableName}-v${version}"
                }
                echo "Final New DynamoDB Table Name: ${newTableName}"

                // Set environment variables for use in other stages
                env.CURRENT_TABLE_NAME = currentTableName
                env.NEW_TABLE_NAME = newTableName
            } else {
                error "DynamoDB table not found in Terraform state"
            }
        }
    }
}*/
          /*stage('Restore Table using PITR') {
            steps {
                script {
                    sh '''
                    aws dynamodb restore-table-to-point-in-time \
                    --source-table-name sandbox_poc_bkp5 \
                    --target-table-name sandbox_poc_bkp6 \
                    --use-latest-restorable-time
                    '''
                }
            }
        }*/

        //   stage('Restore Table using on demand backup') {
        //     steps {
        //         script {
        //             sh '''
        //             aws dynamodb restore-table-from-backup \
        //             --target-table-name ${destinationTable} \
        //             --backup-arn ${backupArn} \
        //             --use-latest-restorable-time
        //             '''
        //         }
        //     }
        // }
    
    //      stage('Wait for Restore') {
    //         steps {
    //             script {
    //                 sh '''
    //                 aws dynamodb wait table-exists \
    //                 --table-name backup_table_4
    //                 '''
    //             }
    //         }
    //     }

    //     stage('Verify Restored Table') {
    //        steps  {
    //            script  {
    //                sh '''
    //                aws dynamodb describe-table --table-name backup_table_4
    //                '''
    //            }
    //        }
              
    //     }
              
    //     stage('Terraform Init') {
    //         steps {
    //             script {
    //                 sh 'terraform init'
    //             }
    //         }
    //     }

    //      stage('Import table') {
    //         steps {
    //             script {
    //                 sh '''
    //                  terraform import aws_dynamodb_table.content backup_table_4
    //                 '''
    //             }
    //         }
    //     }

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
