#!/bin/bash
# =============================================================================
# KUBERNETES APACHE WEB APP LAB RUNNER SCRIPT
# =============================================================================
# This script automates the entire Kubernetes Apache Web App Lab.
# It walks through 6 phases of Kubernetes concepts, executing commands
# step-by-step with pauses between phases so you can observe the results.
#
# PHASES:
#   1. Basic Pod Lifecycle    — Run and test a standalone Apache pod
#   2. Deployments & Services — Create managed deployments and expose via Service
#   3. Scaling                — Scale the deployment to multiple replicas
#   4. Debugging              — Intentionally break and fix the deployment
#   5. Exec & Modification    — Modify a running container's content
#   6. Self-Healing & Cleanup — Demonstrate Kubernetes' self-healing, then clean up
#
# PREREQUISITES:
#   - kubectl must be installed and configured
#   - A Kubernetes cluster must be running (Minikube, Kind, or Docker Desktop)
#   - curl must be available for HTTP testing
#
# USAGE: bash lab_runner.sh
# =============================================================================

# 'set -e' makes the script exit immediately if any command fails.
# This prevents the script from continuing in a broken state.
set -e

# --- COLOR DEFINITIONS -------------------------------------------------------
# ANSI color codes for terminal output formatting.
# These make the output easier to read by color-coding different message types.
GREEN='\033[0;32m'    # Green — used for success messages and phase headers
YELLOW='\033[1;33m'   # Yellow — used for instructions, objectives, and prompts
RED='\033[0;31m'      # Red — used for error messages
NC='\033[0m'          # NC (No Color) — resets the terminal color back to default

# Print the lab title banner
echo -e "${YELLOW}========================================="
echo "   Kubernetes Apache Web App Lab Runner  "
echo -e "=========================================${NC}\n"

# --- HELPER FUNCTION ---------------------------------------------------------
# pause() displays a prompt and waits for the user to press Enter.
# This gives the user time to observe the output before moving to the next phase.
pause() {
  echo -e "\n${YELLOW}Press [Enter] to continue to the next step...${NC}"
  read -r  # 'read -r' waits for user input; -r prevents backslash interpretation
}

# =============================================================================
# PREREQUISITE CHECK
# =============================================================================
# Before running the lab, verify that kubectl is installed and can connect
# to a running Kubernetes cluster. Without these, nothing else will work.

echo -e "${GREEN}Verifying Prerequisites...${NC}"

# 'command -v kubectl' checks if kubectl is installed and available in PATH.
# '&> /dev/null' suppresses all output (both stdout and stderr).
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl could not be found. Please install kubectl.${NC}"
    exit 1  # Exit with error code 1
fi

# 'kubectl get nodes' attempts to connect to the cluster and list nodes.
# If this fails, the cluster isn't running or kubectl isn't configured.
if ! kubectl get nodes &> /dev/null; then
    echo -e "${RED}Error: Cannot connect to Kubernetes cluster. Please ensure Minikube, Kind, or Docker Desktop is running.${NC}"
    exit 1
fi
echo -e "${GREEN}Kubernetes cluster is running and accessible!${NC}"
pause

# =============================================================================
# PHASE 1: BASIC POD
# =============================================================================
# A Pod is the smallest deployable unit in Kubernetes.
# In this phase, we create a standalone Pod running the Apache HTTP Server (httpd).
# Standalone Pods are ephemeral — once deleted, they are gone forever.
# Kubernetes does NOT automatically recreate standalone Pods.

echo -e "${GREEN}--- Phase 1: Basic Pod ---${NC}"
echo -e "${YELLOW}Objective: Deploy a standalone Apache HTTP Server Pod.${NC}\n"

# 'kubectl run' creates a single Pod (similar to 'docker run').
# apache-pod: The name we're giving to this Pod
# --image=httpd: Use the official Apache HTTP Server image from Docker Hub
echo "Command: kubectl run apache-pod --image=httpd"
kubectl run apache-pod --image=httpd

# Wait until the Pod reaches the 'Ready' condition (container is running).
# --timeout=60s: Give up after 60 seconds if the Pod isn't ready.
echo -e "\nWaiting for the pod to be running..."
kubectl wait --for=condition=Ready pod/apache-pod --timeout=60s

# 'kubectl describe pod' shows detailed information about the Pod:
# We pipe through grep to show only the most relevant fields.
echo -e "\nInspecting the pod:"
echo "Command: kubectl describe pod apache-pod"
kubectl describe pod apache-pod | grep -E 'Name:|Image:|Status:'

# --- PORT FORWARDING & TESTING ---
# 'kubectl port-forward' creates a tunnel from localhost to the Pod.
# This maps local port 8081 → Pod's port 80 (where Apache listens).
# The '&' runs this in the background so the script can continue.
# '$!' captures the PID (Process ID) of the background process for later cleanup.
echo -e "\n${YELLOW}Testing the application...${NC}"
echo "Command: kubectl port-forward pod/apache-pod 8081:80 &"
kubectl port-forward pod/apache-pod 8081:80 > /dev/null 2>&1 &
PF_PID=$!  # Save the Process ID of the port-forward background process

# Give port-forward a moment to establish the tunnel before sending requests
sleep 3

# Use curl to send an HTTP GET request to the forwarded port.
# Apache's default page contains the text "It works!" which we check for.
echo -e "\nPinging http://localhost:8081..."
if curl -s http://localhost:8081 | grep "It works!"; then
    echo -e "${GREEN}Success: Received 'It works!'${NC}"
else
    echo -e "${RED}Failed to reach Apache pod via port-forward.${NC}"
fi

# Clean up: Kill the port-forward background process.
# '2>/dev/null || true' suppresses errors if the process already exited.
echo -e "\nCleaning up the port-forward process (PID: $PF_PID)..."
kill $PF_PID 2>/dev/null || true

# Delete the standalone Pod to demonstrate its ephemeral nature.
# Unlike Deployments, a deleted standalone Pod is permanently gone.
echo -e "\n${YELLOW}Deleting the standalone pod...${NC}"
echo "Command: kubectl delete pod apache-pod"
kubectl delete pod apache-pod
pause

# =============================================================================
# PHASE 2: DEPLOYMENTS & SERVICES
# =============================================================================
# A Deployment manages Pods automatically — it ensures the desired number of
# Pod replicas are always running. If a Pod dies, the Deployment creates a new one.
# A Service provides a stable network endpoint (IP + port) to access the Pods.
# The Service load-balances traffic across all Pods in the Deployment.

echo -e "${GREEN}--- Phase 2: Deployments & Services ---${NC}"
echo -e "${YELLOW}Objective: Create a Deployment for lifecycle management and expose it via a Service.${NC}\n"

# 'kubectl create deployment' creates a Deployment resource.
# Unlike 'kubectl run', this creates a Deployment controller that manages Pods.
# The Deployment ensures at least 1 replica of the Apache Pod is always running.
echo "Command: kubectl create deployment apache --image=httpd"
kubectl create deployment apache --image=httpd

# Wait until the Deployment reports as 'available' (at least one Pod is ready).
echo -e "\nWaiting for deployment to be available..."
kubectl wait --for=condition=available deployment/apache --timeout=60s

# 'kubectl expose' creates a Service resource that exposes the Deployment.
# --port=80: The port the Service listens on (matches Apache's port)
# --type=NodePort: Makes the Service accessible from outside the cluster
#   via a randomly assigned port on each node (typically 30000-32767).
echo -e "\nExposing deployment:"
echo "Command: kubectl expose deployment apache --port=80 --type=NodePort"
kubectl expose deployment apache --port=80 --type=NodePort

# --- TESTING THE SERVICE ---
# Port-forward through the Service (not directly to a Pod) to test load balancing.
echo -e "\n${YELLOW}Testing the Service...${NC}"
echo "Command: kubectl port-forward service/apache 8082:80 &"
kubectl port-forward service/apache 8082:80 > /dev/null 2>&1 &
PF_PID=$!  # Save PID for cleanup
sleep 3    # Wait for tunnel to establish

echo -e "\nPinging http://localhost:8082..."
if curl -s http://localhost:8082 | grep "It works!"; then
    echo -e "${GREEN}Success: Service is routing traffic to the Deployment!${NC}"
else
    echo -e "${RED}Failed to reach service via port-forward.${NC}"
fi

echo -e "\nCleaning up the port-forward process (PID: $PF_PID)..."
kill $PF_PID 2>/dev/null || true
pause

# =============================================================================
# PHASE 3: SCALING
# =============================================================================
# Scaling increases (or decreases) the number of Pod replicas in a Deployment.
# More replicas = more capacity to handle traffic + higher availability.
# Kubernetes distributes traffic across all replicas via the Service.

echo -e "${GREEN}--- Phase 3: Scaling ---${NC}"
echo -e "${YELLOW}Objective: Scale the deployment to handle more traffic.${NC}\n"

# 'kubectl scale' changes the desired replica count for the Deployment.
# --replicas=2: Tell Kubernetes we want 2 copies of the Apache Pod running.
# The Deployment controller will create the additional Pod automatically.
echo "Command: kubectl scale deployment apache --replicas=2"
kubectl scale deployment apache --replicas=2

# Wait for the new Pods to spin up, then list all Pods with the label 'app=apache'.
# '-l app=apache' filters Pods by the label that the Deployment automatically applied.
echo -e "\nWaiting for new pods to spin up..."
sleep 5
echo "Command: kubectl get pods -l app=apache"
kubectl get pods -l app=apache
pause

# =============================================================================
# PHASE 4: DEBUGGING
# =============================================================================
# This phase intentionally breaks the Deployment by setting a wrong container image.
# This demonstrates:
#   1. How Kubernetes handles failures gracefully (old Pods stay running)
#   2. How to identify and debug errors using kubectl
#   3. How to fix a broken deployment

echo -e "${GREEN}--- Phase 4: Debugging ---${NC}"
echo -e "${YELLOW}Objective: Intentionally break the app by specifying a non-existent image and observe the error.${NC}\n"

# Temporarily disable 'set -e' (exit on error) because we EXPECT errors here.
# Without this, the script would exit when Kubernetes fails to pull the bad image.
set +e

# 'kubectl set image' updates the container image for a Deployment.
# We intentionally set a non-existent image name 'wrongimage' to trigger an error.
# Kubernetes will try to pull this image and fail, resulting in:
#   - ImagePullBackOff: Kubernetes is waiting before retrying the image pull
#   - ErrImagePull: The image pull attempt failed
echo "Command: kubectl set image deployment/apache httpd=wrongimage"
kubectl set image deployment/apache httpd=wrongimage

# Wait for Kubernetes to attempt the rollout and observe the failure.
echo -e "\nWaiting a few seconds for Kubernetes to attempt the rollout..."
sleep 15

# List Pods to show the error status (ImagePullBackOff or ErrImagePull).
echo "Command: kubectl get pods -l app=apache"
kubectl get pods -l app=apache

echo -e "\n${YELLOW}You should see Pods with 'ImagePullBackOff' or 'ErrImagePull'.${NC}"

# Find a failing Pod's name to describe it for detailed error info.
# We use grep to find Pods in error state and awk to extract just the Pod name.
FAILING_POD=$(kubectl get pods -l app=apache | grep -E 'ImagePullBackOff|ErrImagePull' | awk '{print $1}' | head -n 1)

if [ -n "$FAILING_POD" ]; then
    # 'kubectl describe pod' shows events and details — the last 15 lines
    # typically contain the error details (e.g., "repository does not exist").
    echo -e "\nDescribing failing pod '$FAILING_POD' for more info:"
    echo "Command: kubectl describe pod $FAILING_POD"
    kubectl describe pod "$FAILING_POD" | tail -n 15
else
    echo "No failing pods caught immediately, but they are likely pending."
fi
pause

# --- FIX THE DEPLOYMENT ---
# Now we fix the Deployment by setting the correct image back.
echo -e "${GREEN}Fixing the application...${NC}"
set -e  # Re-enable exit on error now that we're past the intentional failure

# 'kubectl set image' corrects the image back to the official 'httpd' image.
echo "Command: kubectl set image deployment/apache httpd=httpd"
kubectl set image deployment/apache httpd=httpd

# 'kubectl rollout status' watches the rollout until it succeeds.
# A "rollout" is the process of updating Pods to use the new image.
echo -e "\nWaiting for rollout to succeed..."
kubectl rollout status deployment/apache
pause

# =============================================================================
# PHASE 5: EXEC & OPTIONAL CHALLENGE
# =============================================================================
# 'kubectl exec' lets you run commands INSIDE a running container.
# This is useful for debugging, inspecting files, or (as shown here)
# modifying the web server's content at runtime. Note that changes made
# this way are TEMPORARY — they are lost if the Pod restarts.

echo -e "${GREEN}--- Phase 5: Exec & Optional Challenge ---${NC}"
echo -e "${YELLOW}Objective: Execute a command inside a running container to modify the web page.${NC}\n"

# Find a running Pod's name to exec into.
# --field-selector=status.phase=Running: Only select Pods that are actually running
# awk 'NR>1': Skip the header line from kubectl output
# head -n 1: Take only the first matching Pod name
RUNNING_POD=$(kubectl get pods -l app=apache --field-selector=status.phase=Running | awk 'NR>1 {print $1}' | head -n 1)

# Use 'kubectl exec' to run a bash command inside the container.
# This replaces Apache's default index.html with our custom message.
# The file at /usr/local/apache2/htdocs/index.html is Apache's web root.
echo "Command: kubectl exec -it $RUNNING_POD -- bash -c 'echo \"Hello from Kubernetes\" > /usr/local/apache2/htdocs/index.html'"
kubectl exec "$RUNNING_POD" -- bash -c 'echo "Hello from Kubernetes" > /usr/local/apache2/htdocs/index.html'

# --- VERIFY THE MODIFICATION ---
# Port-forward and curl to confirm the page content was changed.
echo -e "\n${YELLOW}Testing the modification via port-forward...${NC}"
kubectl port-forward service/apache 8082:80 > /dev/null 2>&1 &
PF_PID=$!
sleep 3

echo -e "\nPinging http://localhost:8082..."
OUTPUT=$(curl -s http://localhost:8082)  # Capture the HTTP response
echo "Output: $OUTPUT"

# Check if the response contains our custom message
if [[ "$OUTPUT" == *"Hello from Kubernetes"* ]]; then
    echo -e "${GREEN}Success: The index.html was modified inside the container!${NC}"
else
    echo -e "${RED}Failed to verify the modified content.${NC}"
fi

echo -e "\nCleaning up the port-forward process (PID: $PF_PID)..."
kill $PF_PID 2>/dev/null || true
pause

# =============================================================================
# PHASE 6: SELF-HEALING & CLEANUP
# =============================================================================
# Kubernetes' self-healing means the Deployment controller continuously watches
# the cluster state. If a Pod is deleted or crashes, the controller automatically
# creates a new Pod to maintain the desired replica count.
# This phase demonstrates that by manually deleting a Pod and watching it respawn.

echo -e "${GREEN}--- Phase 6: Self-Healing & Cleanup ---${NC}"
echo -e "${YELLOW}Objective: Demonstrate self-healing by deleting a running Pod.${NC}\n"

# Manually delete a running Pod. The Deployment controller will detect that
# the actual state (1 Pod) doesn't match the desired state (2 replicas)
# and will immediately create a replacement Pod.
echo "Command: kubectl delete pod $RUNNING_POD"
kubectl delete pod "$RUNNING_POD"

# Wait briefly, then list Pods to show the replacement was created automatically.
echo -e "\nWatching the deployment automatically recreate the pod..."
echo "Command: kubectl get pods -l app=apache"
sleep 2
kubectl get pods -l app=apache
pause

# --- CLEANUP ALL LAB RESOURCES ---
# Remove everything we created during the lab to leave the cluster clean.
echo -e "${YELLOW}Cleaning up all lab resources...${NC}"

# Delete the Deployment (this also deletes all Pods managed by it)
echo "Command: kubectl delete deployment apache"
kubectl delete deployment apache

# Delete the Service (the stable network endpoint)
echo "Command: kubectl delete service apache"
kubectl delete service apache

echo -e "\n${GREEN}Lab Runner Execution Complete! All resources cleaned up.${NC}"
