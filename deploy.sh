#!/bin/bash

# Check if an argument was provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 {node|python}"
    exit 1
fi

# Get the argument
arg=$1
LANG="${arg,,}"

# Check the argument value
case $LANG in
    node)
        echo "You chose Node.js"
        ;;
    python)
        echo "You chose Python"
        ;;
    *)
        echo "Invalid argument: $arg"
        echo "Usage: $0 {node|python}"
        exit 1
        ;;
esac

# Get the directory where the script is located
SCRIPT_DIR="$(realpath "$(dirname "$0")")"
SOURCES_DIR=$SCRIPT_DIR/prom-$LANG

echo CURRENT NAMESPACE=$(oc project -q)
# Function to check if a resource exists
check_openshift_resource_exists() {
    local resource_type="$1"
    local resource_name="$2"    

    if oc get $resource_type $resource_name >/dev/null 2>&1; then
        return 0  # True: resource exists
    else
        return 1  # False: resource does not exist
    fi
}

# Create ImageStream for Prometheus Example if not exists
if check_openshift_resource_exists ImageStream prom-$LANG; then
  echo "ImageStream prom-$LANG exists"
else
  cat <<EOF | oc apply -f -
apiVersion: image.openshift.io/v1
kind: ImageStream
metadata:
  name: prom-$LANG
spec:
  lookupPolicy:
    local: true
EOF
  # Create BuildConfig for Prometheus Python Example if not exists
  cat <<EOF | oc apply -f - 
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  labels:
    build: prom-$LANG
  name: prom-$LANG
spec:
  output:
    to:
      kind: ImageStreamTag
      name: prom-$LANG:latest
  source:
    binary: {}
    type: Binary
  strategy:
    dockerStrategy: 
      dockerfilePath: Dockerfile
    type: Docker
EOF
fi
  
# Remove previous build objects
oc delete build --selector build=prom-$LANG > /dev/null 
# Start build for prom sample
oc start-build prom-$LANG --from-file $SOURCES_DIR
# Follow the logs until completion 
oc logs $(oc get build --selector build=prom-$LANG -oNAME) -f 
# Check if a deployment already exists
if check_openshift_resource_exists Deployment prom-$LANG; then
  # update deployment
  echo "Updating deployment..."
  oc set image \
    deployment/prom-$LANG \
    prom-$LANG=$(oc get istag prom-$LANG:latest -o jsonpath='{.image.dockerImageReference}')
else
  echo "Creating deployment, service, service monitor and route"
  # Create deployment
  oc create deploy prom-$LANG --image=prom-$LANG:latest 
  # Create service
  cat <<EOF | oc apply -f -
apiVersion: v1
kind: Service
metadata:
  labels:
    app: prom-$LANG
  name: prom-$LANG
spec:
  ports:
  - name: $LANG
    port: 8000
    protocol: TCP
    targetPort: 8000
  selector:
    app: prom-$LANG
EOF
  # Create service monitor
  cat <<EOF | oc apply -f -
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  labels:
    app: prom-$LANG
  name: prom-$LANG
spec:
  endpoints:
  - interval: 30s
    port: $LANG
  selector:
    matchLabels:
      app: prom-$LANG
EOF
  # Create route
  cat <<EOF | oc apply -f - 
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  labels:
    app: prom-$LANG
  name: prom-$LANG
spec:
  port:
    targetPort: 8000
  to:
    kind: Service
    name: prom-$LANG
  tls: 
    termination: edge
EOF
fi