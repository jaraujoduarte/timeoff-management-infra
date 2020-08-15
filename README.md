# Infra as code - EKS / TimeOff Management Application Test
Repository containing infra as code for the TimeOff Management Application (Gorilla Logic DevOps test).


# Design



# Setup
In order to deploy the resources defined in this repo make sure to set the following tooling in your machine:

```
- Terragrunt >= v0.23.0
- Terraform >= v0.12.0
- Kubectl >= 1.16
```

# Deployment
- Set the target environment
```
source env/dev.sh
```

- Run the Terraform plans
```
cd $PROJECT_ROOT/terragrunt
terragrunt apply-all
```

- Since AWS Fargate is being used for both "regular" and system pods, a fix needs to be applied so the CoreDNS pods don't stay in pending state due to no nodes being available. To do this, the deployment definition needs to be patched and the rollout restarted:
```
kubectl patch deployment coredns -n kube-system --type json -p='[{"op": "remove", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type"}]'
kubectl rollout restart -n kube-system deployment coredns
```

- Create the necessary RBAC configuration for the ALB controller and the ALB controller itself. Before applying the manifests, modify the  VPC ID in the `k8s/alb-ingress-controller.yaml` file which necessary if using Fargate for the ALB to know where to spin up the LBs.
```
cd $PROJECT_ROOT/k8s
kubectl apply -f .
```