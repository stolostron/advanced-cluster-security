#!/bin/bash

set -e
set -o pipefail


CMDNAME=`basename $0`

# Display help information
help () {
  echo "Deploy image access secret to hub and target clusters by RHACM Subscription"
  echo ""
  echo "Prerequisites:"
  echo " - kubectl CLI must be pointing to the cluster to which to deploy verification key"
  echo " - roxctl and yq commands must be installed"
  echo ""
  echo "Usage:"
  echo "  $CMDNAME [-l <key=value>] [-p <path/to/file>] [-n <namespace>] [-s <name>]"
  echo ""
  echo "  -h|--help                   Display this menu"
  echo "  -a|--acs <hostname:port>         The ACS Central Server hostname:port to connect to."
  echo "  -i|--init <bundle-file>     The central init-bundles file name to save certs to."
  echo "                                (Default name is cluster-init-bundle.yaml"
  echo ""
} >&2

if [ -z "$ROX_API_TOKEN" ]; then
	echo "The ROX_API_TOKEN environment variable must be set to a valid API token." >&2
	exit 1
fi

# The namespace is required to be stackrox
NAMESPACE=stackrox

# Parse arguments
while [[ $# -gt 0 ]]; do
        key="$1"
        case $key in
            -h|--help)
            help
            exit 0
            ;;
            -a|--acs)
            shift
            ACS_HOST=${1}
            shift
            ;;
            -i|--init)
            shift
            BUNDLE_FILE=${1}
            shift
            ;;
            *)    # default
            echo "Invalid input: ${1}" >&2
            exit 1
            shift
            ;;
        esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [[ -z $ACS_HOST ]]; then
	echo "The '-a|--acs <hostname:port>' parameter is required." >&2
	exit 1
fi

if [[ -z $BUNDLE_FILE ]]; then
	echo "The '-i|--init <init-bundle>' parameter is required." >&2
	exit 1
fi

if [[ -z $NAMESPACE ]]; then
  NAMESPACE=stackrox
fi


if ! [ -x "$(command -v kubectl)" ]; then
    echo 'Error: kubectl is not installed.' >&2
    exit 1
fi

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    BASE='base64 -w 0'
elif [[ "$OSTYPE" == "darwin"* ]]; then
    BASE='base64'
fi

if [ -f "${BUNDLE_FILE}" ]; then
	echo "# Using existing bundle file." >&2
else
	echo "# Creating new bundle file." >&2
	roxctl -e "$ACS_HOST" central init-bundles generate cluster-init-bundle --output ${BUNDLE_FILE} >&2
	if [ $? -ne 0 ]; then
		echo "Failed to create the init-bundles required with 'roxctl'." >&2
		exit 1
	fi
fi

CACERT=`yq eval '.ca.cert' ${BUNDLE_FILE} | sed 's/^/                    /'`
cat <<EOF
---
apiVersion: v1
kind: Namespace
metadata:
  name: stackrox
---
apiVersion: v1
kind: Namespace
metadata:
  name: stackrox-staging
---
apiVersion: v1
kind: Namespace
metadata:
  name: stackrox-cluster-channel
---
apiVersion: v1
data:
  admission-control-cert.pem: `yq eval '.admissionControl.serviceTLS.cert' ${BUNDLE_FILE} | ${BASE}`
  admission-control-key.pem: `yq eval '.admissionControl.serviceTLS.key' ${BUNDLE_FILE} | ${BASE}`
  ca.pem: `yq eval '.ca.cert' ${BUNDLE_FILE} | ${BASE}`
kind: Secret
metadata:
  annotations:
    apps.open-cluster-management.io/deployables: "true"
  name: admission-control-tls
  namespace: ${NAMESPACE}-staging
type: Opaque
---
apiVersion: v1
data:
  collector-cert.pem: `yq eval '.collector.serviceTLS.cert' ${BUNDLE_FILE} | ${BASE}`
  collector-key.pem: `yq eval '.collector.serviceTLS.key' ${BUNDLE_FILE} | ${BASE}`
  ca.pem: `yq eval '.ca.cert' ${BUNDLE_FILE} | ${BASE}`
kind: Secret
metadata:
  annotations:
    apps.open-cluster-management.io/deployables: "true"
  name: collector-tls
  namespace: ${NAMESPACE}-staging
type: Opaque
---
apiVersion: v1
data:
  sensor-cert.pem: `yq eval '.sensor.serviceTLS.cert' ${BUNDLE_FILE} | ${BASE}`
  sensor-key.pem: `yq eval '.sensor.serviceTLS.key' ${BUNDLE_FILE} | ${BASE}`
  ca.pem: `yq eval '.ca.cert' ${BUNDLE_FILE} | ${BASE}`
  acs-host: `echo ${ACS_HOST} | ${BASE}`
kind: Secret
metadata:
  annotations:
    apps.open-cluster-management.io/deployables: "true"
  name: sensor-tls
  namespace: ${NAMESPACE}-staging
type: Opaque
---
apiVersion: apps.open-cluster-management.io/v1
kind: Channel
metadata:
  name: secured-cluster-resources
  namespace: ${NAMESPACE}-staging
spec:
  pathname: ${NAMESPACE}-staging
  type: Namespace
---
apiVersion: apps.open-cluster-management.io/v1
kind: Subscription
metadata:
  name: secured-cluster-sub
  namespace: ${NAMESPACE}
spec:
  channel: ${NAMESPACE}-staging/secured-cluster-resources
  placement:
    placementRef:
      kind: PlacementRule
      name: secured-cluster-placement
---
apiVersion: apps.open-cluster-management.io/v1
kind: PlacementRule
metadata:
  name: secured-cluster-placement
  namespace: ${NAMESPACE}
spec:
  clusterConditions:
  - status: "True"
    type: ManagedClusterConditionAvailable
  clusterSelector:
    matchExpressions:
    - key: vendor
      operator: In
      values:
      - OpenShift
---
EOF
