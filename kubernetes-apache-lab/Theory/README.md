# Kubernetes Apache Web App Lab

## Objective
Deploy and manage a simple Apache-based web server using Kubernetes to demonstrate Pod lifecycle management, deployment scaling, runtime container modification, self-healing, and debugging failure scenarios.

## Prerequisites
* A running Kubernetes cluster (Minikube, Kind, or Docker Desktop)
* `kubectl` CLI installed and configured
* Local terminal access

## Step-by-step Procedure & Commands Used

**Step 1 — Run Apache Pod**  
Deploy a standalone Pod using the `httpd` image.
```bash
kubectl run apache-pod --image=httpd
kubectl get pods
kubectl describe pod apache-pod
```

**Step 2 — Verify Application**  
Forward a local port to access the Pod.
```bash
kubectl port-forward pod/apache-pod 8081:80
```
*Expected output:* Navigating to `http://localhost:8081` in your browser will display the default Apache "It works!" page.

**Step 3 — Delete Pod**  
```bash
kubectl delete pod apache-pod
```
*Explanation:* Standalone Pods have no self-healing. Once deleted, it is permanently removed from the cluster.

**Step 4 — Create Deployment**  
Create a Deployment to ensure the application runs continuously.
```bash
kubectl create deployment apache --image=httpd
kubectl get deployments
kubectl get pods
```

**Step 5 — Expose Deployment**  
Expose the deployment via a Service for easier access.
```bash
kubectl expose deployment apache --port=80 --type=NodePort
kubectl port-forward service/apache 8082:80
```

## Scaling Task
**Step 6 — Scale Deployment**  
Increase the number of running instances.
```bash
kubectl scale deployment apache --replicas=2
kubectl get pods
```
*Explanation:* You will now see multiple `apache` pods running to distribute load and provide high availability.

## Modification Task
**Step 7 — Modify Application**  
Change the default web page content directly inside a running container.
```bash
kubectl exec -it <pod-name> -- /bin/bash
echo "Hello from Kubernetes" > /usr/local/apache2/htdocs/index.html
exit
```
*Explanation:* Refresh your browser at `http://localhost:8082`. The page will now say "Hello from Kubernetes" instead of "It works!".

## Debugging Task
**Step 8 — Debugging Scenario**  
Intentionally break the deployment.
```bash
kubectl set image deployment/apache httpd=wrongimage
kubectl get pods
```
*Explanation:* The new pods will show an `ImagePullBackOff` or `ErrImagePull` error because the container runtime cannot pull the non-existent `wrongimage`.

**Step 9 — Fix Deployment**  
Fix the broken deployment by reverting to the correct image.
```bash
kubectl set image deployment/apache httpd=httpd
```

## Self-healing demonstration
**Step 10 — Self Healing**  
Delete a running pod to observe the Deployment controller in action.
```bash
kubectl delete pod <pod-name>
kubectl get pods -w
```
*Explanation:* The Deployment guarantees the desired number of replicas. Removing a pod triggers an automatic recreation of a replacement pod immediately.

## Verification Steps
Throughout the lab, we verified:
1. Pod status using `kubectl get pods` and `kubectl describe pod`.
2. Application availability via `kubectl port-forward` and browser checks.
3. Scaling success by observing replica counts.
4. Error states and self-healing behavior through watch flags (`-w`).

## Observations
* Standalone Pods are ephemeral and do not recover from deletion.
* Deployments provide robust lifecycle management, including scaling, rolling updates, and self-healing.
* Modifications made directly inside a container via `exec` are temporary; if the pod is recreated, the manual changes are lost.
* Kubernetes correctly isolates misconfigurations (like bad images), leaving existing pods running while attempting to roll out new ones.

## Conclusion
This lab reinforces the fundamental differences between unmanaged Pods and Deployments in Kubernetes. Utilizing Deployments and Services is crucial for running stable, scalable, and self-healing applications in production environments.

## GitHub Submission Instructions
1. Initialize a Git repository in your project root if you haven't already:
   ```bash
   git init
   ```
2. Add the `kubernetes-apache-lab/` directory and its contents:
   ```bash
   git add kubernetes-apache-lab/
   ```
3. Commit the changes with a descriptive message:
   ```bash
   git commit -m "Add Kubernetes Apache Lab submission under Theory folder"
   ```
4. Push the changes to your remote repository:
   ```bash
   git push origin main
   ```
