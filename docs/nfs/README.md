### WORK IN PROGRESS ###

THIS IS IN PROGRESS: I AM NOT SURE ABOUT THE VALUE FOR THE DEMO ENV

* Setup on how to use NFS on MacOs local mashine using nfsd

* https://sean-handley.medium.com/how-to-set-up-docker-for-mac-with-native-nfs-145151458adc
* https://www.jeffgeerling.com/blog/2020/revisiting-docker-macs-performance-nfs-volumes
* https://madewithlove.com/blog/improving-docker-performance-for-macos/
* https://forums.docker.com/t/nfs-native-support/48531/29?page=2
* https://github.com/docker/for-mac/issues/5534
* https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Enabling-network-NFS-shares-in-Mac-OS-X.html
* https://www.devguide.at/en/docker/docker-nfs-implementation-for-better-performance-in-macos-11-big-sur/
* https://www.cyberciti.biz/faq/apple-mac-osx-nfs-mount-command-tutorial/
* https://firehydrant.com/blog/nfs-with-docker-on-macos-catalina/


docker build -t nfs-server .
docker run --rm -ti --name nfs-server --privileged -v /tmp:/srv/nfs -p 2049:2049 nfs-server
docker volume ls -q |xargs  docker volume rm

sudo nfsd update
sudo nfsd enable


/net/<hostname_of_sharing_Mac>/Users.

