/**
 * Request was, if an pipeline using an SSH Agent gets reconnected to the next replica when the active replica fails
 */
pipeline {
    agent {
        /**
         * This label reference an SSH agent
         */
        label "ssh-agent"
    }
    triggers {
        cron '* * * * *'
    }

    stages {
        stage('Stage1') {
            steps {
                sh '''
                    set +x
                    	printf '%s %s\n' "$(date) Running on Agent-Pod: $(hostname)"
                    	#sleep for 60 sec, kill the active replica now and check if SSH agent gets reconnected to the other replica
                    	sleep 60
                '''
            }
        }
    }
}
