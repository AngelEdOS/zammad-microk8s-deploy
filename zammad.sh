#!/bin/sh

if [ $# != 1 ]; then
  echo " $# Es necesario pasar un argumento especificando el numero
  de puerto con el que se accederá a zammad"
  exit 1
fi

if  which "microk8s" >/dev/null ; then
echo "El programa \"microk8s\" está instalado."
else
echo "No está instalado \"microk8s\"  se procederá con su instalación."

snap install microk8s --classic --channel=1.26
usermod -a -G microk8s $USER
chown -f -R $USER ~/.kube
microk8s status --wait-ready

fi

echo "enable the volumes use"
microk8s enable rbac
microk8s enable storage
microk8s enable dns dashboard registry

echo "create the zammad namespace"
microk8s kubectl create namespace zammad
microk8s helm repo add zammad https://zammad.github.io/zammad-helm
microk8s helm upgrade --install zammad zammad/zammad --namespace=zammad

echo "apiVersion: v1
kind: Service
metadata:
  annotations:
    meta.helm.sh/release-name: zammad
    meta.helm.sh/release-namespace: zammad
  labels:
    app.kubernetes.io/instance: zammad
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: zammad
    app.kubernetes.io/version: 5.4.0-10
    helm.sh/chart: zammad-8.2.2
  name: zammad
  namespace: zammad
spec:
  externalTrafficPolicy: Cluster
  internalTrafficPolicy: Cluster
  ipFamilies:
  - IPv4
  ipFamilyPolicy: SingleStack
  ports:
  - name: http
    nodePort: $1
    port: 8080
    protocol: TCP
    targetPort: http
  selector:
    app.kubernetes.io/instance: zammad
    app.kubernetes.io/name: zammad
  sessionAffinity: None
  type: NodePort" > svc-zammad-overide.yaml

microk8s kubectl apply -f svc-zammad-overide.yaml

echo "/n/n zammad running in port $1"