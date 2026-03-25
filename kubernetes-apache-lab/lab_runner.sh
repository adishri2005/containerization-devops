#!/bin/bash

# Exit on any error, but handle specific failures gracefully where intended
set -e

# Color definitions
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}========================================="
echo "   Kubernetes Apache Web App Lab Runner  "
echo -e "=========================================${NC}\n"

# Helper function to pause
pause() {
  echo -e "\n${YELLOW}Press [Enter] to continue to the next step...${NC}"
  read -r
}

# 1. Prerequisite Check
echo -e "${GREEN}Verifying Prerequisites...${NC}"
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl could not be found. Please install kubectl.${NC}"
    exit 1
fi

if ! kubectl get nodes &> /dev/null; then
    echo -e "${RED}Error: Cannot connect to Kubernetes cluster. Please ensure Minikube, Kind, or Docker Desktop is running.${NC}"
    exit 1
fi
echo -e "${GREEN}Kubernetes cluster is running and accessible!${NC}"
pause

# ==========================================================
# Phase 1: Basic Pod
# ==========================================================
echo -e "${GREEN}--- Phase 1: Basic Pod ---${NC}"
echo -e "${YELLOW}Objective: Deploy a standalone Apache HTTP Server Pod.${NC}\n"

echo "Command: kubectl run apache-pod --image=httpd"
kubectl run apache-pod --image=httpd

echo -e "\nWaiting for the pod to be running..."
kubectl wait --for=condition=Ready pod/apache-pod --timeout=60s

echo -e "\nInspecting the pod:"
echo "Command: kubectl describe pod apache-pod"
kubectl describe pod apache-pod | grep -E 'Name:|Image:|Status:'

echo -e "\n${YELLOW}Testing the application...${NC}"
echo "Command: kubectl port-forward pod/apache-pod 8081:80 &"
kubectl port-forward pod/apache-pod 8081:80 > /dev/null 2>&1 &
PF_PID=$!

# Give port-forward a moment to establish
sleep 3

echo -e "\nPinging http://localhost:8081..."
if curl -s http://localhost:8081 | grep "It works!"; then
    echo -e "${GREEN}Success: Received 'It works!'${NC}"
else
    echo -e "${RED}Failed to reach Apache pod via port-forward.${NC}"
fi

echo -e "\nCleaning up the port-forward process (PID: $PF_PID)..."
kill $PF_PID 2>/dev/null || true

echo -e "\n${YELLOW}Deleting the standalone pod...${NC}"
echo "Command: kubectl delete pod apache-pod"
kubectl delete pod apache-pod
pause

# ==========================================================
# Phase 2: Deployments & Services
# ==========================================================
echo -e "${GREEN}--- Phase 2: Deployments & Services ---${NC}"
echo -e "${YELLOW}Objective: Create a Deployment for lifecycle management and expose it via a Service.${NC}\n"

echo "Command: kubectl create deployment apache --image=httpd"
kubectl create deployment apache --image=httpd

echo -e "\nWaiting for deployment to be available..."
kubectl wait --for=condition=available deployment/apache --timeout=60s

echo -e "\nExposing deployment:"
echo "Command: kubectl expose deployment apache --port=80 --type=NodePort"
kubectl expose deployment apache --port=80 --type=NodePort

echo -e "\n${YELLOW}Testing the Service...${NC}"
echo "Command: kubectl port-forward service/apache 8082:80 &"
kubectl port-forward service/apache 8082:80 > /dev/null 2>&1 &
PF_PID=$!
sleep 3

echo -e "\nPinging http://localhost:8082..."
if curl -s http://localhost:8082 | grep "It works!"; then
    echo -e "${GREEN}Success: Service is routing traffic to the Deployment!${NC}"
else
    echo -e "${RED}Failed to reach service via port-forward.${NC}"
fi

echo -e "\nCleaning up the port-forward process (PID: $PF_PID)..."
kill $PF_PID 2>/dev/null || true
pause

# ==========================================================
# Phase 3: Scaling
# ==========================================================
echo -e "${GREEN}--- Phase 3: Scaling ---${NC}"
echo -e "${YELLOW}Objective: Scale the deployment to handle more traffic.${NC}\n"

echo "Command: kubectl scale deployment apache --replicas=2"
kubectl scale deployment apache --replicas=2

echo -e "\nWaiting for new pods to spin up..."
sleep 5
echo "Command: kubectl get pods -l app=apache"
kubectl get pods -l app=apache
pause

# ==========================================================
# Phase 4: Debugging
# ==========================================================
echo -e "${GREEN}--- Phase 4: Debugging ---${NC}"
echo -e "${YELLOW}Objective: Intentionally break the app by specifying a non-existent image and observe the error.${NC}\n"

# Temporarily disable exit on error for the broken state validation
set +e

echo "Command: kubectl set image deployment/apache httpd=wrongimage"
kubectl set image deployment/apache httpd=wrongimage

echo -e "\nWaiting a few seconds for Kubernetes to attempt the rollout..."
sleep 15
echo "Command: kubectl get pods -l app=apache"
kubectl get pods -l app=apache

echo -e "\n${YELLOW}You should see Pods with 'ImagePullBackOff' or 'ErrImagePull'.${NC}"

# Get a failing pod name
FAILING_POD=$(kubectl get pods -l app=apache | grep -E 'ImagePullBackOff|ErrImagePull' | awk '{print $1}' | head -n 1)

if [ -n "$FAILING_POD" ]; then
    echo -e "\nDescribing failing pod '$FAILING_POD' for more info:"
    echo "Command: kubectl describe pod $FAILING_POD"
    kubectl describe pod "$FAILING_POD" | tail -n 15
else
    echo "No failing pods caught immediately, but they are likely pending."
fi
pause

echo -e "${GREEN}Fixing the application...${NC}"
set -e # Re-enable exit on error
echo "Command: kubectl set image deployment/apache httpd=httpd"
kubectl set image deployment/apache httpd=httpd

echo -e "\nWaiting for rollout to succeed..."
kubectl rollout status deployment/apache
pause

# ==========================================================
# Phase 5: Exec & Optional Challenge
# ==========================================================
echo -e "${GREEN}--- Phase 5: Exec & Optional Challenge ---${NC}"
echo -e "${YELLOW}Objective: Execute a command inside a running container to modify the web page.${NC}\n"

RUNNING_POD=$(kubectl get pods -l app=apache --field-selector=status.phase=Running | awk 'NR>1 {print $1}' | head -n 1)

echo "Command: kubectl exec -it $RUNNING_POD -- bash -c 'echo \"Hello from Kubernetes\" > /usr/local/apache2/htdocs/index.html'"
kubectl exec "$RUNNING_POD" -- bash -c 'echo "Hello from Kubernetes" > /usr/local/apache2/htdocs/index.html'

echo -e "\n${YELLOW}Testing the modification via port-forward...${NC}"
kubectl port-forward service/apache 8082:80 > /dev/null 2>&1 &
PF_PID=$!
sleep 3

echo -e "\nPinging http://localhost:8082..."
OUTPUT=$(curl -s http://localhost:8082)
echo "Output: $OUTPUT"
if [[ "$OUTPUT" == *"Hello from Kubernetes"* ]]; then
    echo -e "${GREEN}Success: The index.html was modified inside the container!${NC}"
else
    echo -e "${RED}Failed to verify the modified content.${NC}"
fi

echo -e "\nCleaning up the port-forward process (PID: $PF_PID)..."
kill $PF_PID 2>/dev/null || true
pause

# ==========================================================
# Phase 6: Self-Healing & Cleanup
# ==========================================================
echo -e "${GREEN}--- Phase 6: Self-Healing & Cleanup ---${NC}"
echo -e "${YELLOW}Objective: Demonstrate self-healing by deleting a running Pod.${NC}\n"

echo "Command: kubectl delete pod $RUNNING_POD"
kubectl delete pod "$RUNNING_POD"

echo -e "\nWatching the deployment automatically recreate the pod..."
echo "Command: kubectl get pods -l app=apache"
sleep 2
kubectl get pods -l app=apache
pause

echo -e "${YELLOW}Cleaning up all lab resources...${NC}"
echo "Command: kubectl delete deployment apache"
kubectl delete deployment apache
echo "Command: kubectl delete service apache"
kubectl delete service apache

echo -e "\n${GREEN}Lab Runner Execution Complete! All resources cleaned up.${NC}"
