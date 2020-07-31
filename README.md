# minikube-jenkins-macos

Setup your local CI/CD development on macOS
(It's high level steps to follow, I will add more detail steps later)

1. Add below entry to /etc/hosts
127.0.0.1 kubernetes.docker.internal

2. Install Docker Desktop on Mac
https://docs.docker.com/docker-for-mac/install/

3. Add insecure-registry to docker engine
click docker->Preferences
click Docker Engine tab
add below entries
 "insecure-registries": [
    "host.docker.internal:5000"
  ]
click Apply & Restart

4. Install Minikube and startup 
#installation
https://kubernetes.io/docs/tasks/tools/install-minikube/
#startup minikube 
minikube start --apiserver-name=host.docker.internal --insecure-registry=host.docker.internal:5000


5. Download latest docker client (linux version) and replace docker in this repo
https://download.docker.com/linux/static/stable/x86_64/
https://docs.docker.com/engine/install/binaries/#install-daemon-and-client-binaries-on-linux

6. Download kubectl client (linux version) and replace kubeclt in this repo
curl -O https://storage.googleapis.com/kubernetes-release/release/v1.8.4/bin/linux/amd64/kubectl
https://coreos.com/tectonic/docs/latest/tutorials/kubernetes/configure-kubectl.html

7. Build docker image with jenkins, docker and kubecli
docker build -t jenkins-minikube .

8. Deploy jenkins-minikube to docker
#create volume 
docker volume create jenkins
#replace <account> to your username
docker run -d -u root -p 8080:8080 -p 50000:50000 -v jenkins_data:/var/jenkins_home -v /var/run/docker.sock:/var/run/docker.sock -v /Users/yuguo/.kube:/root/.kube -v /Users/<account>/.minikube:/Users/<account>/.minikube jenkins-minikube:latest

9. Edit minikube config file "/Users/<account>/.kube/config
change 
    server: https://127.0.0.1:32792
to
    server: https://host.docker.internal:32792
note: the port number could be different from above

10. install and run docker local registry
https://hub.docker.com/_/registry
docker run -d -p 5000:5000 --restart always --name registry registry:2

11. setup your first jenkins job
#open jenkins in browser
http://localhost:5000
#install maven and pipeline plugins
#create jenkins job with below sample scripe 
pipeline {
    agent any

    tools {
        // Install the Maven version configured as "M3" and add it to the path.
        maven "maven"
    }

    stages {
        stage('Build') {
            steps {
                // Get some code from a GitHub repository
                git 'https://github.com/guoyucn/personal-java.git'

                // Run Maven on a Unix agent.
                sh "mvn -Dmaven.test.failure.ignore=true clean package"

                //build docker image
                sh "docker build -t host.docker.internal:5000/datacentric:1.0.0 ."
                
                //push image to registry 
                sh "docker push host.docker.internal:5000/datacentric:1.0.0"
            }

        }
        stage('Deploy') {
            steps {
                // Run Maven on a Unix agent.
                sh "kubectl run datacentric --image=host.docker.internal:5000/datacentric:1.0.0"

            }

        }
    }
}

12. docker image will be deployed to minikube 
 
