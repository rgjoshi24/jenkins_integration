pipeline {
    // The running agent is node labled as a "master", in this case, it the master. It can also assign to multiple workers or groups.
    agent { label "master"}
    stages {
        // Delete the workspace for duplicate configuration which may cause an error.
        stage('Delete the workspace'){
            steps {
              sh "sudo rm -rf $WORKSPACE/*"
            }
        }
        // Install the ChefDK on the new container
        stage ('Installing ChefDK'){
            steps{
                script {
                    // When the chef-client exist, skip it, if not, go ahead and install chefdk
                    def exists = fileExists '/usr/bin/chef-client'
                    if (exists){
                        echo "Skipping ChefDK install - already installed"
                    } else{ 
                        echo "Install ChefDK"
                        sh 'sudo apt-get install -y wget'
                        sh 'wget https://packages.chef.io/files/stable/chefdk/3.9.0/ubuntu/18.04/chefdk_3.9.0-1_amd64.deb'
                        sh 'sudo dpkg -i chefdk_3.9.0-1_amd64.deb'
                    }
                }
            }
        }
        // Download Apache Cookbook. Have to clone the apache cookbook into your own repo first
        stage('Download Apache Cookbook'){
            steps {
                git credentialsId: 'git-repo-creds', url: 'git@github.com:hchiao1/apache.git'
            }
        }

        // Install Ruby and Test Kitechen
        stage ('Install Ruby, Test Kitchen and needed Ruby gems'){
            steps{
                sh 'sudo usermod -aG root,docker tomcat'
                sh 'sudo apt-get install rubygems -y'
                sh 'sudo apt-get install ruby-dev -y'
                sh 'sudo gem install bundler -v 2.0.1 --no-doc'
                sh 'bundle install'
            }
        }

        // Run the Test Kitchen 
        stage ("Run Test Kitchen"){
            steps{
                sh 'sudo kitchen test'
            }
        }

        // Notice the Slacke channel
        stage ("Notice Slack Channel"){
            steps{
                slackSend message: 'Student-7: Please approve ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.JOB_URL} | Open>)'
            }
        }

        // Wait for approval, please go ahead on the Jenkins UI
        stage ("Wait for approval"){
            steps{
                input 'Please approve this build'
            }
        }

        // Upload to the Chef Server, and start converage node
        stage ("Upload the Chef Server, Converge Nodes"){
            steps{
                withCredentials([zip(credentialsId: 'chef-starter-zip', variable: 'CHEFREPO')]) {
                    sh "mkdir -p $CHEFREPO/chef-repo/cookbooks/apache"
                    sh "mv $WORKSPACE/* $CHEFREPO/chef-repo/cookbooks/apache"
                    sh "sudo rm -rf $CHEFREPO/chef-repo/cookbooks/apache/Berksfile.lock"
                    sh "knife node list -c $CHEFREPO/chef-repo/.chef/knife.rb"
                    sh "knife cookbook upload apache --force -o $CHEFREPO/chef-repo/cookbooks -c $CHEFREPO/chef-repo/.chef/knife.rb"

                    withCredentials([sshUserPrivateKey(credentialsId: 'lab_pk', keyFileVariable: 'LABPK', passphraseVariable: '', usernameVariable: 'ubuntu')]) {
                        sh "knife ssh 'role:webserver' --ssh-user ubuntu -i $LABPK 'sudo chef-client' -c $CHEFREPO/chef-repo/.chef/knife.rb"
                    } 
                }
            }
        }
    }

    // Post Build Step. Send out slack notification if the build success, if not, sent out email instead
    post{
        success{
            slackSend message: 'Build $JOB_NAME $BUILD_NUMBER Successful!'
        }
        failure{
            echo "Build Failed"
            mail  body: "Build ${env.JOB_NAME} ${env.BUILD_NUMBER} failed. Please check the build at ${env.JOB_URL}", from: 'admin@myclass.email', subject: 'Build Failure', to: 'hchiao1@outlook.com'
        }
    }
}