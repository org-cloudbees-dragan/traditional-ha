# Test for demo

## Test Pipeline 

[Jenkinsfile-ssh-agent.groovy](Jenkinsfile-ssh-agent.groovy) is a simple test pipeline that prints out the agent host name as wel as the controller replica hostname

* The Pipeline is already setup by CasC on the HA Controller 
* Optional.You can run the Pipeline periodically when you remove the comment: 
    ```
          /** trigger every minute  
              triggers {
                  cron '* * * * *'
       }*/
    ```

Simple Test Scenario:

* Start the Pipeline, maybe increase the sleep time in the Pipeline configuration screen before to 120
* Review the Pipeline Build console log, you will see the agent and controller hostname (your active replica)
* Stop the active Replica
 > docker compose stop <ha-client-controller-1 | ha-client-controller-2>  
* Reload the Controller page in the UI 
* You are now on the other replica 
* Review  developer mode information below in the Controller screen 
* Review the HA overview page under Controller -> Manage Jenkins -> HA 
* Review the Pipeline Build console log: Agent hostname is the same, Controller hostname has changed 
* Start the replica you have stopped previsouly again 
 > docker compose start <ha-client-controller-1 | ha-client-controller-2>
* Wait some minutes and review the HA overview page under Controller -> Manage Jenkins -> HA

## Test script 

* Running the [testJobTrigger.sh](testJobTrigger.sh]) will trigger the Test Pipeline job in a loop by curl
* Curl doesnt send the cookie back in the next request so that each new request will get balanced by HAProxy to the Controller with less workload available. 
* While this script is running, you can also stop one of the controller in another terminal and then check the output of the script 



You need to create an ADMIN TOKEN on the Operations Center first.

Run the script:

> ./testJobTrigger.sh <ADMIN_TOKEN>

output:  (You can see each request passes to another controller replica, HAPRoxy round robbin) 

```
#######################################
start build of Job: testpipeline
LOCATION:                    http://client.ha/queue/item/1906176575203385912/
CONTROLLER_REPLICA:          8f09fe15eb03@7
CONTROLLER_REPLICA_IP:       172.47.0.7
CONTROLLER_STICKY_COOKIE:    cloudbees_sticky=client_controller_1;
#######################################
start build of Job: testpipeline
LOCATION:                    http://client.ha/queue/item/8297333667126857149/
CONTROLLER_REPLICA:          ca6d130f20e4@6
CONTROLLER_REPLICA_IP:       172.47.0.8
CONTROLLER_STICKY_COOKIE:    cloudbees_sticky=client_controller_2;
#######################################
start build of Job: testpipeline
LOCATION:                    http://client.ha/queue/item/4103591515808461672/
CONTROLLER_REPLICA:          8f09fe15eb03@7
CONTROLLER_REPLICA_IP:       172.47.0.7
CONTROLLER_STICKY_COOKIE:    cloudbees_sticky=client_controller_1;
#######################################
start build of Job: testpipeline
LOCATION:                    http://client.ha/queue/item/6696135951568096215/
CONTROLLER_REPLICA:          ca6d130f20e4@6
CONTROLLER_REPLICA_IP:       172.47.0.8
CONTROLLER_STICKY_COOKIE:    cloudbees_sticky=client_controller_2;
#######################################
....
```