#!/bin/sh
docker build -t hello-builder --target builder .
docker build -t host.docker.internal:5000/hello-final:1.0.0 --target final .
docker push host.docker.internal:5000/hello-final:1.0.0
kubectl create deployment hello-go --image=host.docker.internal:5000/hello-final:1.0.0
kubectl expose deployment hello-go --type=LoadBalancer --port=8081 --target-port=8081
minikube service hello-go
