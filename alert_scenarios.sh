# Alerts Scenarios 
# Pod-related alerts
kubectl get prometheusrule -n monitoring -o json | \
  jq -r '
    .items[] |
    .metadata.name as $name |
    [.spec.groups[].rules[]? | select(.alert != null) | .alert] as $alerts |
    $alerts[]? | select(test("KubePod|Container")) | "\($name): \(.)"
  '
# Node-related
kubectl get prometheusrule -n monitoring -o json | \
  jq -r '
    .items[] |
    .metadata.name as $name |
    [.spec.groups[].rules[]? | select(.alert != null) | .alert] as $alerts |
    $alerts[]? | select(test("KubeNode|Node")) | "\($name): \(.)"
  '
#Pending Pod

kubectl apply -n dev -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: pending-pod
spec:
  containers:
  - name: nginx
    image: nginx
    resources:
      requests:
        memory: "500Gi"
EOF

# Terminating Pod
cat <<EOF > stuck-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: stuck-pod
  finalizers:
  - example.com/do-not-delete
spec:
  restartPolicy: Never
  containers:
  - name: busybox
    image: busybox:1.36
    command: ["sleep", "3600"]
EOF

kubectl apply -f stuck-pod.yaml
kubectl delete pod stuck-pod
kubectl patch pod stuck-pod -p '{"metadata":{"finalizers":[]}}' --type=merge
kubectl delete pod stuck-pod --grace-period=0 --force

#ImagePull Issue
kubectl run imagepull-pod --image=doesnotexist:123 --restart=Never

#Containerrecreated
kubectl run  containerrecreating-pod --image=nginx --restart=Always \
  --overrides='
{
  "spec": {
    "containers": [
      {
        "name": "nginx",
        "image": "nginx",
        "volumeMounts": [
          {"mountPath": "/data", "name": "missing"}
        ]
      }
    ],
    "volumes": [
      {"name": "missing", "persistentVolumeClaim": {"claimName": "does-not-exist"}}
    ]
  }
}'

#PV available, PVC unbound
cat <<EOF > setup-sc-pv-pvc.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: slow
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: Immediate
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: available-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: slow
  hostPath:
    path: /mnt/available-test
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pending-pvc
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: nonexistent-sc
EOF

kubectl apply -f setup-sc-pv-pvc.yaml
kubectl delete sc slow
kubectl get sc,pv,pvc

#Taint on the nodes

kubectl taint nodes my-cluster-control-plane key=value:NoSchedule
kubectl taint nodes my-cluster-worker key=value:NoSchedule
kubectl taint nodes my-cluster-worker2 key=value:NoSchedule

# Untaint the Nodes
kubectl taint nodes my-cluster-control-plane key=value:NoSchedule-
kubectl taint nodes my-cluster-worker key=value:NoSchedule-
kubectl taint nodes my-cluster-worker2 key:NoSchedule-

#Notready Nodes
# Stop the node
docker stop my-cluster-worker2

# Start node
docker start my-cluster-worker2

