# CloudBees Ci Traditional HA/HS (active/active) Demo Lab Environment

Docker compose setup for a [Cloudbees CI traditional installation](https://docs.cloudbees.com/docs/cloudbees-ci/latest/traditional-install-guide/) in [HA (active/active) mode](https://docs.cloudbees.com/docs/cloudbees-ci/latest/ha/ha-fundamentals)

See these links for the background

* https://docs.cloudbees.com/docs/cloudbees-ci/latest/ha/ha-fundamentals
* https://docs.cloudbees.com/docs/cloudbees-ci/latest/ha/ha-considerations
* https://docs.cloudbees.com/docs/cloudbees-ci/latest/ha/specific-ha-installation-traditional

# Links

References we have used for the development of this demo environment:

* https://docs.cloudbees.com/docs/cloudbees-ci/latest/ha/specific-ha-installation-traditional
* https://docs.cloudbees.com/docs/cloudbees-ci/latest/ha/ha-considerations
* [docs/HAProxy/1_Using_SSL_Certificates_with_HAProxy.pdf](docs/HAProxy/1_Using_SSL_Certificates_with_HAProxy.pdf)
* https://www.haproxy.com/blog/haproxy-configuration-basics-load-balance-your-servers
* https://www.haproxy.com/documentation/haproxy-configuration-manual/latest/
* https://www.haproxy.com/documentation/haproxy-configuration-tutorials/load-balancing/websocket/#configure-websockets
* https://www.haproxy.com/documentation/haproxy-configuration-tutorials/core-concepts/backends/
* https://docs.docker.com/compose/networking/
* https://www.claudiokuenzler.com/blog/900/how-to-use-docker-host-ip-address-inside-application-container
* https://eventuate.io/docs/usingdocker.html
* https://docs.linuxserver.io/images/docker-webtop/#lossless-mode

# Architecture

The docker-compose setup for the HA/HS demo follows the design below.
Each CloudBees component as well as the HAProxy is running in a dedicated docker container orchestrated by docker-compose.

The demo has the following limitations:

* SSL 443 is not enabled yet. All traffic for local demo is going through port 80/8080
* NFS server is not part of the demo. We will use a local directory on the host system

![Ci-HAProxy.png](docs/Ci-HAProxy.png)

The setup consists of the following containers:

* Operations Center
* Controller 1
* Controller 2
* SSH-Agent 1
* HAProxy Load Balancer
* Optional, but not required: Linux box with Firefox accessible via VNC from an external browser

The setup is self-sufficient and does not require any modifications on the Docker host or anywhere else outside of the docker compose environment.
There are two exceptions to highlight:

* Persistence - local paths on the docker host are used as persistence volumes. NFS volumes are not used at the moment in the demo lab. Controller 1 and Controller 2 share the same $JENKINS_HOME dir.
* If you want to access the demo via a browser from Docker host, you need entries in `/etc/hosts` (see chapters below)

The Operations Center and both controllers are behind HAProxy.

* If a request comes to HAProxy with $OC_URL host header, it is forwarded to the Operations Center container
* If a request comes with $CLIENTS_URL host header, it is load balanced between all client controllers
* The load balancing for client controllers has sticky sessions enabled

# Pre-requirements

* This demo has been tested
  * on MacOs 14.7
  * Docker-Desktop 4.24.0 (122432)
  * Engine: 24.0.6
  * Compose: v2.22.0-desktop.2
  * Docker-compose v3
  * Web browser, Firefox and Chrome has been tested

Required tools:

* [Docker desktop](https://docs.docker.com/desktop/install/mac-install/)
* ping (not mandatory, but used in the `up.sh` script to test name resolution)
* ssh-keygen (If you don`t have an SSH key available)
* A Web browser

# Quick Start

* Clone this repository
* Ensure you have an SSH private and public key under the path `~/.ssh/id_rsa` and `~/.ssh/id_rsa.pub`
  * If you don't have an SSH key, run `ssh-keygen -t rsa -f ~/.ssh/id_rsa` to create one
  * The key is required for the agent we want to connect to the HA/HS Controller in this demo
  * If you have your key already under another path or name, adjust it in the [env.sh](env.sh) configuration file
* Optional: Add a CloudBees Wildcard License to avoid license screen. If you dont add a license now, you can request a trial license later in the Operations Center welcome screen
  * Add a CloudBees Wildcard licence key to this files. CasC will read this files and apply the license during startup
  * see 
    * [secter/cb-wildcard-license.cert](secter/cb-wildcard-license.cert)
    * [secrets/cb-wildcard-license.key](secrets/cb-wildcard-license.key)
* Run `up.sh`
  * The related containers will start now. The essential configuration are already setup using Configuration as Code
  * You will get redirected to you browser to the Operations Center when all container are up and running. This might take some minutes
* Browser access to the Operations Center
  * Option1: Use a Browser in a box: Follow these instructions [Join the containerized browser in a Box](#Option1_Join_the_containerized_browser_in_a_Box)
    * This option doesn't require changes on your host in `/etc/hosts`
  * Option2: Use your Browser on your Machine: Follow these instructions [Use your Firefox/Chrome on your docker host](#Option2_Use_your_browser_on_your_docker_host)
    * This option require changes on your host in `/etc/hosts`
* Open the Operations Center
  * use `admin/admin` for login
* Request a license (first option in the screen "Request trial license")
* Click on the pre provisioned controller "ha" in the Operations Center UI
* Add `http://client.ha`and click `push configuration` and `join operations center`
* Now you are on an Controller running in HA/HS mode. A test Pipeline job using an SSH agent is already running

# Files

[env.sh](env.sh)

The essential variables are explained here, take a look in to the `env.sh` file for more detailed settings.
Usually you don`t need to change something here, potentially the SSH key variables need to be adjusted to your needs

* `SSH_PRIVATE_KEY_PATH` mandatory: path to your SSH private key  
* `SSH_PUBLIC_KEY_PATH`  mandatory: path to your SSH public key
* `CJOC_LICENSE_PRIVATE_KEY` optional: You can add your CloudBees wildcard license key to this file: [secrets/cb-wildcard-license.key](secrets/cb-wildcard-license.key)
* `CJOC_LICENSE_CERTIFICATE` optional: You can add your CloudBees wildcard license certificate to this file: [secrets/cb-wildcard-license.cert](secrets/cb-wildcard-license.cert)
* `OC_URL` is the URL you want the Operations Center to respond on.
* `CLIENTS_URL` is for the controllers. There is only one URL for both controllers.
* `DOCKER_IMAGE_OC` and `DOCKER_IMAGE_CLIENT_CONTROLLER` are the CB CI versions on oOerations Center and controllers
* `IP_PREFIX` is a prefix for the internal docker compose network
* `PERSISTENCE_PREFIX` is the path for the persistence volumes on the docker host

[docker-compose.yaml.template](docker-compose.yaml.template)

This template is used to render the `docker-compose.yaml` file using the environment variables in `env.sh`. Please do not modify docker-compose.yaml directly, since it will be overwritten by `up.sh`. Modify this template instead.

[up.sh](up.sh)

A helper script to:

- Create the persistence volumes
- Render the docker-compose.yaml from the template.
- Run `docker compose up`

[haproxy.cfg](haproxy.cfg)

This is the haproxy configuration used in the haproxy container to balance and forward the incoming traffic to the related cloudbees components
It includes:

* frontend and backend config
* client header forwarding
* enabled websockets
* enabled sticky sessions
* balance mode (roundrobin)
* health checks

[restartControllers.sh](restartControllers.sh)

* restarts the controllers

[down.sh](down.sh)

* run `docker compose down` and scale down all containers

[deleteVolumes.sh](deleteVolumes.sh)

* delete the persistance dir including all mounted volumes 

[casc/cjoc](casc/cjoc)

* contains the casc bundle files to provision the Operations Center during startup (up.sh)

[casc/controller](casc/controller)

* contains the casc bundle files to provision the controllers during startup (up.sh)

[secrets](secrets)

Placeholder files where to add your CloudBees Wildcard license cert and key.
This is optional. If a wildcard license is supplied you will pass the license welcome screen on the Operations Center 
* [secrets/cb-wildcard-license.key](secrets/cb-wildcard-license.key)
* [secrets/cb-wildcard-license.cert](secrets/cb-wildcard-license.cert)

# Steps

## Start/Deploy

- Examine `env.sh` and modify if needed.
- Examine `docker-compose.yaml.template` and modify if needed.
- Run `up.sh`
- Wait until all components are up and access via one of the browser options

## Stop

Run `down.sh`. This will issue docker compose down to stop the running containers.

## Clean up

- Stop the running containers using `down.sh`. Then,
- Run `deleteVolumes.sh`. This will delete the persistence directories on the host (docker volumes)

## Browser Access

Just Firefox and Chrome has been tested to access the environment.
There are two options on how to access the CloudBess CI demo lab:

### Option1_Join_the_containerized_browser_in_a_Box

* open a browser on your host machine and point it to [http://localhost:3000](http://localhost:3000).
* This will open a VNC session to the Linux container with a Firefox browser in it.
* From the start menu (Top to the left) open Firefox browser.

![ff-box](docs/ff-box.png)

* open `http://oc.ha`

### Option2_Use_your_browser_on_your_docker_host

* Add the following to your `/etc/hosts` file

> 127.0.0.1	localhost oc.ha client.ha

* Then open Firefox/Chrome on your PC: [http://oc.ha](http://oc.ha)
* Optional (if you can not resolve the hostnames): Flush the DNS cache (MacOs)

> sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder

## Open the Operations Center

* Point the browser to http://$OC_URL  (by default this is http://oc.ha/)
* (Not required when using CasC) Unlock the Operations Center, you will find the key in the docker-compose logs on your console
* (Not required when using CasC) You can use this command to get the password

```
docker-compose exec operations-center   cat /var/jenkins_home/secrets/initialAdminPassword
```

![oc-unlock.png](docs/oc-unlock.png)

* Request a licence and add admin user details
* (Not required when using CasC)  Install the suggested Plugins
* (Not required when using CasC)  Under Operations Center -> Manage Jenkins -> Security
  * Disable TCP Port 50000 (we don't need it, all traffic in this demo is HTTP or SSH)

![oc-disable50000.png](docs/oc-disable50000.png)

* (Not required when using CasC) Enforce Security realm and SSO

![oc-enforce-security.png](docs/oc-enforce-security.png)

## Create a client controller item

* (Not required when using CasC) In the Operations Center, create a client controller item.
* (Not required when using CasC) Ensure you have "websocket" enabled in the connection configuration

![Screenshot20240919at084705.png](docs/image3.png)
![oc-pushconnectiondetails.png](docs/oc-pushconnectiondetails.png)
![Screenshot20240919at084705.png](docs/image2.png)

* Required: Push the configuration to http://$CLIENTS_URL  (by default this is http://client.ha/ )
  * Not required: Try to access http://$CLIENTS_URL/ in Firefox
  * Not required: Request a licence and add admin user details
* (Not required when using CasC) Get the Controller1 initial password

> docker-compose exec ha-client-controller-1    cat /var/jenkins_home/secrets/initialAdminPassword

* (Not required when using CasC) Install HA plugin (active/active) on http://$CLIENTS_URL/

![controller-installhaplugin.png](docs/controller-installhaplugin.png)

* (Not required when using CasC)The two replicas must be restarted.
  ```
  docker-compose restart ha-client-controller-1
  docker-compose restart ha-client-controller-2
  ```
* Controller 2 will begin starting when controller 1 is ready
* It takes some minutes now, you can see the HA status in the controllers` Manage Jenkins section

![Screenshot20240919at084705.png](docs/image1.png)

## On the controller: Create a jenkins ssh credential

Note: Not required when using CasC

Join the Controller and add an SSH Credentials (private key)

![controller-ssh-cred.png](docs/controller-ssh-cred.png)

### Optional, if you don't have an ssh key: Create a key pair

`ssh-keygen -t rsa -f ~/.ssh/id_rsa`

Adjust the path to the ssh key in the `env.sh` file

> export JENKINS_AGENT_SSH_PUBKEY=$(cat ~/.ssh/id_rsa.pub)

or

> export JENKINS_AGENT_SSH_PUBKEY=$(cat <YOUR_PATH_HERT>/agent-key.pub)

Use the private part in the Controller when defining credentials to connect to the agent.
Choose credentials with username and private key. Username is jenkins.

## Create a SSH Agent Node

Note: Not required when using CasC

![createSSHAgent.png](docs/createSSHAgent.png)

## Create a test Pipeline

Note: Not required when using CasC

Once the SSH Agent has been created you can create a simple Test Pipeline on the HA Controller

[test/Jenkinsfile-ssh-agent.groovy](test/Jenkinsfile-ssh-agent.groovy)

Once the Pipeline is started you can  demo one replica to demo the build will take over to the other replica and continues to run if the controller replica is shut down

* Start the Pipeline
* Check what replica you are running on
* Enable HA developer mode to show the info icon to the bottom of the Controller
* This show you also the IP address of your session replica
* shut your controller replica down (see in `docker-compose.yaml` for the ip address mapped to the docker container name)

```
docker-compose stop ha-client-controller-1 # or ha-client-controller-2 depending on where yu are 
```

* Reload the Controller page in your browser, you should be now on the other replica and job should resume to work

# Troubleshooting

## Browser shows Side is nt secured/Missing SSL Certificate

We run on localhost, an SSL certificate is not part of the demo now.
If you hit SSL issues in your browser when you access the Operations Center, do the following:

### Disable "HTTPS Only" mode

If you hit SSL cert issues in your browser, do the following:

(Haven't checked yet how to do this in Chrome, if required)

* As the demo HAProxy doesn't support HTTPS/SSL yet, we use Firefox with disabled `HTTPS only mode` see https://support.mozilla.org/en-US/kb/https-only-prefs
* Adjust the following exceptions:

Under Firefox settings search "HTTPS Only"

Disable HTTPS only:

![ff-https-only](docs/ff-httpsonly.png)

Add exceptions:

![ff-exceptions](docs/ff-exceptions.png)

# Extra Notes used during development of the demo (Not required for the setup)

## DNS Flush (MacOs)

> sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder

## Useful Docker commands

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

### List docker processes

```
docker-compose top
```

## Details SSH Agents

### Create your ssh keys

> ssh-keygen -t rsa -b 2048 -C "your_email@example.com"

### Add your public key the agent container

add the ssh-pub key in your `docker-compose.yaml` file

```
    environment:
      - JENKINS_AGENT_SSH_PUBKEY="YOUR_PUB_KEY"

```

Restart the agent container if required

> docker-compose restart agent

Verify if the key has been applied: (Join the docker agent container and check the `/home/jenkins/.ssh` directory)

# TODO and next steps

- Use {DOCKER_IP} and Controller/Cjoc sub path in ha_proxy, remove the vnc ubuntu image
- Verify to introduce NFS
- Enable SSL on HAPRoxy (Lets-encrypt or self-signed certs?)
- Agents: Creating agent key pair in up.sh
- Fill the public part automatically in docker compose template (with envsubst in up.sh)
- Casc: Add configuration as code to simplify the setup and plugin installation
