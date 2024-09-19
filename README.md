# CloudBees Ci traditional-ha/hs demo 

Docker compose setup for a traditional Cloudbees CI installation in HA (active/active) mode



# Links

* https://docs.cloudbees.com/docs/cloudbees-ci/latest/ha/specific-ha-installation-traditional
* https://docs.cloudbees.com/docs/cloudbees-ci/latest/ha/ha-considerations
* https://docs.docker.com/compose/networking/
* https://www.haproxy.com/blog/haproxy-configuration-basics-load-balance-your-servers
* https://www.haproxy.com/documentation/haproxy-configuration-manual/latest/
* https://www.claudiokuenzler.com/blog/900/how-to-use-docker-host-ip-address-inside-application-container
* https://eventuate.io/docs/usingdocker.html

## Architecture

The docker-compose setup follows this design with the following limitations:

* SSL 443 is not enabled yet. All traffic for local demo is going through port 80/8080
* NFS server is not part of the demo. We will use a local directory on the host system 

* ![Ci-HAProxy.png](docs/Ci-HAProxy.png)


## Setup

The setup consists of the following containers:

- Operations center
- Controller 1
- Controller 2
- SSH-Agent 1
- HAProxy Load Balancer
- Linux box with Firefox accessible via VNC from an external browser

The setup is self sufficient and does not require any modifications on the Docker host or anywhere else outside of the docker compose environment, except for the persistence - local paths on the docker host are used as persistence volumes. NFS volumes are not used at the moment.
Controller 1 and Controller 2 share the same $JENKINS_HOME dir.

The Operations Center and both controllers are behind HAProxy.

- If a request comes to HAProxy with $OC_URL host header, it is forwarded to the operations center container
- If a request comes with $CLIENTS_URL host header, it is load balanced between all client controllers
- The load balancing for client controllers has sticky sessions enabled

### env.sh

- `OC_URL` is the URL you want the operations center to respond on.
- `CLIENTS_URL` is for the controllers. There is only one URL for both controllers.
- `DOCKER_IMAGE_OC` and `DOCKER_IMAGE_CLIENT` are the CB CI versions on operations center and controllers
- `IP_PREFIX` is a prefix for the internal docker compose network
- `PERSISTENCE_PREFIX` is the path for the persistence volumes on the docker host

### docker-compose.yaml.template

This template is used to render the `docker-compose.yaml` file using the environment variables in `env.sh`. Please do not modify docker-compose.yaml directly, since it will be overwritten by `up.sh`. Modify this template instead.

### up.sh

A helper script to:

- Create the persistence volumes
- Render the docker-compose.yaml from the template.
  - `sudo` is used to create the persistence volumes and assign the permissions.
- Run `docker compose up`

## Deploy

- Examine `env.sh` and modify if needed.
- Examine `docker-compose.yaml.template` and modify if needed.
- Run `up.sh`.

## Operate

The `browser` container exposes port 6080 to the docker host.
To access the Operations Center:

### Join the Desktop VM in your Browser

* open a browser and point it to http://docker-host-ip:6080. This will open a VNC session to the Linux container.
* From the start menu open Firefox browser.
* Point the Firefox browser to http://$OC_URL  (by default this is http://oc.ha/ )

### Create a client controller item

* In the Operations Center, create a client controller item.
* Ensure you have "websocket" enabled in the connection configuration

```
kind: clientController
name: controllerha
description: ''
displayName: controllerha
properties:
- configurationAsCode: {
    }
- sharedHeaderLabelOptIn:
    optIn: true
- healthReporting:
    enabled: true
- owner:
    delay: 5
    owners: ''
- envelopeExtension:
    allowExceptions: false
- sharedConfigurationOptOut:
    optOut: false
- webSocket:
    enabled: true
```


* ![Screenshot20240919at084705.png](docs/image3.png)
* ![Screenshot20240919at084705.png](docs/image2.png)
* Push the configuration to http://$CLIENTS_URL  (by default this is http://client.ha/ )
  * Try to access http://$CLIENTS_URL/ in Firefox (VNC)
  * alternative: try to access http://ha-client-controller-1:8080
  * Request a licence and add admin user details
* Install HA plugin (active/active) on http://$CLIENTS_URL/
* Controller 2 will begin starting when controller 1 is ready
  * Restart the controllers

```
docker-compose restart ha-client-controller-1
docker-compose restart ha-client-controller-2
```

* You can see the HA status in the controllers` Manage Jenkins section
* ![Screenshot20240919at084705.png](docs/image1.png)

### Agent

Create a key pair with: `ssh-keygen -t rsa -f agent-key`

Put the contents of agent-key.pub in the env var JENKINS_AGENT_SSH_PUBKEY in docker-compose.yaml.template.
Use the private part in the Controller when defining credentials to connect to the agent.
Choose credentials with username and private key. Username is jenkins.

## Stop

Run `down.sh`. This will issue docker compose down to stop the running containers.

## Clean up

- Stop the running containers using `down.sh`. Then,
- Run `delete_volumes.sh`. This will delete the persistence directories on the host (docker volumes)

## Docker commands

### Inspect network

```
docker network ls
docker network inspect traditional-ha_demo-network
```

### Restart container

```
docker-compose restart <container>
```

Example:

```
docker-compose restart ha-client-controller-1
docker-compose restart ha-client-controller-2
```

# SSH Agents

## Create your ssh keys

> ssh-keygen -t rsa -b 2048 -C "your_email@example.com"

## Add your public key the agent container

> docker exec -ti agent -c cat $(cat id_rsa.pub) > /home/jenkins/.ssh(authorized_keys

## On the controller: Create a jenkins ssh credential

## Create a SSH Agent Node

![Screenshot20240919at084705.png](docs/createSSHAgent.png)



When setting up SSH, it's important to ensure that the permissions for the SSH directory and its files are configured correctly for security. Here’s how the typical directory structure and permissions should look:

Directory Structure
SSH Directory:

Path: ~/.ssh/
Files in the SSH Directory:

id_rsa (private key)
id_rsa.pub (public key)
authorized_keys (contains public keys for SSH access)
config (optional configuration file)
known_hosts (tracks known host public keys)
Recommended Permissions
Here's how to set the permissions correctly:


# Set the permissions for the .ssh directory
> chmod 700 ~/.ssh

# Set the permissions for the private key
> chmod 600 ~/.ssh/id_rsa

# Set the permissions for the public key
> chmod 644 ~/.ssh/id_rsa.pub

# Set the permissions for the authorized_keys file
> chmod 600 ~/.ssh/authorized_keys

# Set the permissions for the config file (if it exists)
> chmod 644 ~/.ssh/config

# Set the permissions for the known_hosts file (if it exists)
> chmod 644 ~/.ssh/known_hosts

Explanation of Permissions

* 700 for ~/.ssh/: This allows only the user to read, write, and execute. This is essential to prevent other users from accessing the SSH configuration.
* 600 for id_rsa and authorized_keys: This restricts the files so only the user can read and write them. The private key must be kept secret.
* 644 for id_rsa.pub, config, and known_hosts: These files can be read by others, but only the owner can write to them.
Example Commands
You can set these permissions using the following commands in your terminal:

```
mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/id_rsa ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys ~/.ssh/config ~/.ssh/known_hosts
chmod 600 ~/.ssh/id_rsa ~/.ssh/authorized_keys
chmod 644 ~/.ssh/id_rsa.pub ~/.ssh/config ~/.ssh/known_hosts
```

This ensures that your SSH setup is secure and functions correctly. Let me know if you have further questions!





ChatGPT can make mistakes. Check important info.

## TODO and next steps

- Use {DOCKER_IP} and Controller/Cjoc sub path in ha_proxy, remove the vnc ubuntu image
- Verify to introduce NFS
- Enable SSL on HAPRoxy (Lets-encrypt or self-signed certs?) 
- Agents: Creating agent key pair in up.sh
- Fill the public part automatically in docker compose template (with envsubst in up.sh)
- Casc: Add configuration as code to simplify the setup and plugin installation