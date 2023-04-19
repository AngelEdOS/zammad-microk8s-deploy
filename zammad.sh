#!/bin/sh

if [ $# != 2 ]; then
  echo "Es necesario pasar un argumento especificando el numero
de puerto con el que se accederá a zammad, y como segundo argumento
el puerto por donde se accederá al pgAdmin"
  exit 1
fi

if [ $1 -lt 30000 ] ;then
  echo "El puerto debe ser mayor o igual a 30,000"
  exit 1
fi

if [ $2 -lt 30000 ] ;then
  echo "El puerto debe ser mayor o igual a 30,000"
  exit 2
fi

if  which "microk8s" > /dev/null ; then
  echo "El programa \"microk8s\" está instalado."
  
  #verificar si el usuario se encuentra en el grupo microk8s
  groups | grep microk8s > /dev/null
  if [  $? -ne 0 ]; then
    echo "el usuario debe pertenecer al grupo microk8s, agreguelo o ejecute con sudo"
    exit 1
  fi 


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
  type: NodePort" > svc-zammad-override.yaml

microk8s kubectl apply -f svc-zammad-override.yaml

echo "apiVersion: apps/v1
kind: Deployment
metadata:
  name: pgadmin
spec:
  selector:
   matchLabels:
    app: pgadmin
  replicas: 1
  template:
    metadata:
      labels:
        app: pgadmin
    spec:
      containers:
        - name: pgadmin4
          image: dpage/pgadmin4
          env:
            - name: PGADMIN_DEFAULT_EMAIL
              value: \"admin@admin.com\"
            - name: PGADMIN_DEFAULT_PASSWORD
              value: \"admin\"
            - name: PGADMIN_PORT
              value: \"80\"
          ports:
            - containerPort: 80
              name: pgadminport
---
apiVersion: v1
kind: Service
metadata:
  name: pgadmin
  labels:
    app: pgadmin
spec:
  selector:
    app: pgadmin
  type: NodePort
  ports:
    - port: 80
      nodePort: $2" > pgAdmin.yml

microk8s kubectl apply -f pgAdmin.yml -n zammad

rm svc-zammad-override.yaml
rm pgAdmin.yml


echo "/n/n zammad running in port $1"
echo "/n/n pgAdmin running in port $2"