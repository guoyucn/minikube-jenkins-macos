# minikube-jenkins-macos

Setup your local CI/CD development with minikube and jenkins on macOS  

## Installation

1. Add below entry to /etc/hosts  
`127.0.0.1 kubernetes.docker.internal`

2. Install Docker Desktop on Mac  
https://docs.docker.com/docker-for-mac/install/

3. Add insecure-registry to Docker Engine  
3.1 Click Docker > Preferences  
3.2 Click Docker Engine tab  
3.3 Add below entries  
 `"insecure-registries": [
    "host.docker.internal:5000" 
  ]`  
3.4 Click Apply & Restart  

4. Install minikube and startup   
4.1 Follow instructions to install minikube  
`https://kubernetes.io/docs/tasks/tools/install-minikube/`  
4.2 Startup minikube  
`minikube start --apiserver-name=host.docker.internal --insecure-registry=host.docker.internal:5000`  

5. Download latest docker client (linux version) and replace `jenkins-image/docker` file in this repo  
`https://download.docker.com/linux/static/stable/x86_64/`  
`https://docs.docker.com/engine/install/binaries/#install-daemon-and-client-binaries-on-linux`  

6. Download kubectl client (linux version) and replace `jenkins-image/kubectl` file in this repo  
`curl -O https://storage.googleapis.com/kubernetes-release/release/v1.8.4/bin/linux/amd64/kubectl`  
`https://coreos.com/tectonic/docs/latest/tutorials/kubernetes/configure-kubectl.html`  

7. Build docker image containing Jenkins, kubectl and docker  
`cd jenkins-image`  
`docker build -t jenkins-minikube .`  

8. Deploy jenkins-minikube to docker  
8.1 Create docker volume for jenkins  
`docker volume create jenkins`  
8.2 Run Jenkins application in docker. (replace `<account>` to your macbook username)  
`docker run -d -u root -p 8080:8080 -p 50000:50000 -v jenkins_data:/var/jenkins_home -v /var/run/docker.sock:/var/run/docker.sock -v /Users/yuguo/.kube:/root/.kube -v /Users/<account>/.minikube:/Users/<account>/.minikube jenkins-minikube:latest`    

9. Edit minikube config file (`/Users/<account>/.kube/config`)  
change  
    `server: https://127.0.0.1:32792`  
to  
    `server: https://host.docker.internal:32792`    
note: the port number could be different from above  

10. Install and run docker local registry  
10.1 Run docker registry  
`docker run -d -p 5000:5000 --restart always --name registry registry:2`  
10.2 Verify  
`curl host.docker.internal:5000/v2/_catalog`  

## Setup your first Jenkins Job
1. Setup Jenkins  
1.1 Open http://localhost:8080  
1.2 Follow instruction to login Jenkins  
1.3 Install `Git client` and `Pipeline: Job` plugin  

2. Create jenkins job  
2.1 Create new Pipeline with name `Hello-Go`  
2.2 Under Pipeline section, fillin below script and Save  
```
pipeline {
    agent any
    
    stages {
        stage('build') {
            steps {
                // Get some code from a GitHub repository
                sh ''' rm -rf minikube-jenkins-macos
                git clone --depth=1 https://github.com/guoyucn/minikube-jenkins-macos.git
                cd minikube-jenkins-macos/
                docker build -t hello-builder --target builder .
                docker build -t host.docker.internal:5000/hello-final:1.0.0 --target final .
                docker push host.docker.internal:5000/hello-final:1.0.0
                '''
            }
        }
        stage('deploy') {
            steps {
                sh ''' 
                kubectl create deployment hello-go --image=host.docker.internal:5000/hello-final:1.0.0
                kubectl expose deployment hello-go --type=LoadBalancer --port=8081 --target-port=8081
                '''
            }
        }
    }
}
```
3. Click `Build Now` to build the Pipeline

## Verify 
1. Run `minikube service hello-go`  
2. Browser will be opened with content `Hello World`  