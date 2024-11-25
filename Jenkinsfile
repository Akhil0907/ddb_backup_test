String awsCredentialsId = 'aws_credentials'
String credentialsId = 'github_key'
String branchName = 'main'
String repoName = 'ddb_backup_test'
String envUrl = "git@github.com:Akhil0907/${repoName}.git"

pipeline {
    agent any
    
  parameters {
    string(name: 'aws_region', defaultValue: params.aws_region_primary ?: 'us-east-1')
    string(name: 'source_table_name', defaultValue:'')
    string(name: 'target_table_name', defaultValue:'')
    string(name: 'backup_arn', defaultValue: params.environment_name ?: '')
    booleanParam(name: 'use_pitr_backup', defaultValue: false, description: 'Use PITR for restore')
  }
    
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

       stage('Test')
        { 
            steps 
            { 
                script
                { 
                    echo "params.use_pitr_backup: ${params.use_pitr_backup}"
                    echo "source_table_name: ${params.SOURCE_TABLE}"
                    echo "target_table_name: ${params.DESTINATION_TABLE}"
                }
            } 
        }

    //   stage('Install AWS CLI') {
    //      steps {
    //              sh """
    //             if ! command -v aws &> /dev/null
    //            then
    //             curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    //             unzip awscliv2.zip
    //             ./aws/install -i ${AWS_CLI_DIR} -b ${AWS_CLI_DIR}/bin
    //         fi
    //         """
    //     }
    // }

          stage('Install Homebrew') 
           { 
               steps
               { 
                   sh ''' 
                   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                   ''' 
               } 
           } 
        stage('Install AWS CLI') 
        { 
            steps 
            { 
                sh ''' 
                if ! command -v aws &> /dev/null then 
                brew install awscli 
                fi 
                '''
            }
        }


        //  stage('Read AWS Credentials') {
        //     steps {
        //         withCredentials([file(credentialsId: 'aws_credentials', variable: 'AWS_CREDENTIALS_FILE')]) {
        //             script {
        //                 def awsCredentials = readJSON file: AWS_CREDENTIALS_FILE
        //                 env.AWS_ACCESS_KEY_ID = awsCredentials.AccessKeyId
        //                 env.AWS_SECRET_ACCESS_KEY = awsCredentials.SecretAccessKey
        //                 env.AWS_SESSION_TOKEN = awsCredentials.SessionToken 
        //             }
        //         }
        //     }
        // }


     stage('Read AWS Credentials') { 
         steps { 
             withCredentials([[ 
                 $class: 'AmazonWebServicesCredentialsBinding', 
                 credentialsId: 'aws_credentials' ]]) 
                { 
                 script {
                     env.AWS_ACCESS_KEY_ID = "${AWS_ACCESS_KEY_ID}"
                     env.AWS_SECRET_ACCESS_KEY = "${AWS_SECRET_ACCESS_KEY}"
                 } 
                }
         }
     }

        stage('Restore Table') {
            steps { 
                script { 
                    if (params.use_pitr_backup) 
                    { 
                        sh '''
                        aws dynamodb restore-table-to-point-in-time --source-table-name ${env.SOURCE_TABLE} --target-table-name ${env.DESTINATION_TABLE} --use-latest-restorable-time
                        '''
                    } 
                    else
                    { 
                        sh ''' 
                        aws dynamodb restore-table-from-backup --target-table-name ${env.DESTINATION_TABLE} --backup-arn ${env.BACKUP_ARN} --use-latest-restorable-time
                        '''
                    } 
                } 
            }
        }
    
         stage('Wait for Restore') {
            steps {
                script {
                    sh '''
                    aws dynamodb wait table-exists \
                    --table-name ${target_table_name}
                    '''
                }
            }
        }
              
        stage('Terraform Init') {
            steps {
                script {
                    sh '''
                    terraform init -backend-config="bucket=tf-test-1" -backend-config="key=devops.tfstate"
                    '''
                }
            }
        }

         stage('Import table') {
            steps {
                script {
                    sh '''
                     terraform import aws_dynamodb_table.content ${target_table_name}
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                script {
                    sh '''
                     terraform plan -no-color -var-file="values.tfvars"
                    '''
                }
            }
        }
        
        stage('Terraform Apply') {
            steps {
                script {
                    sh '''
                     terraform apply -no-color -var-file="values.tfvars"
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
