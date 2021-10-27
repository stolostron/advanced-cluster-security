# advanced-cluster-security
Learn how quickly you can get Advanced Cluster Security deployed in your Open Cluster Management installation.

## Deploy the Central Server

Deploy this policy to your HUB to install the Advanced Cluster Security Central Server.

- [Central Server Policy](https://github.com/open-cluster-management/policy-collection/blob/main/community/CM-Configuration-Management/policy-acs-operator-central.yaml)

**NOTE** You can install the Central Server manually (using OperatorHub instead of the policy above).  The Central Server can be installed into any namespace.

## Deploy the Secure Cluster Services

Wait a few minutes for the Central Server to install.  Then you will need to setup your command line to have the following CLI and API token.
- `ROX_API_TOKEN` This is a token created in the Central Server to allow the `roxctl` command to make API calls to the Central Server.
- `roxctl` This is the Advanced Cluster Security command line interface.  It's needed to create some certificate bundles that the Secure Cluster Services all need to use.

### Get a token

Follow these steps to get the `ROX_API_TOKEN` for the command line:
1. On your HUB, run `oc get route -n stackrox central`
2. Open a browser to the hostname returned in the `HOST/PORT` column.  Make sure you use `https://hostname` so a secure connection is made. 
3. Run the command `oc get secret -n stackrox central-htpasswd -o yaml | grep password | awk ' { print $2}' | sed -n 1p | base64 -d &&echo ""` to get the base64 encoded password and to decode the encoded password.
4. Login to the Advanced Cluster Security Central Server with the userid `admin` and the password obtained above.
5. Select `Platform Configuration` and then select `Integrations` from the menu.  Scroll to the end of the list of integrations and select the StackRox API Token integration.
6. Select the New Integration button.  In the dialog that appears, specify a name for the token and select the `admin` role.  Click generate.
7. Copy the generated token and on your command line run a command like `export ROX_API_TOKEN=value` to add the token to your shell environment.

### Download roxctl

Follow these steps to obtain the `roxctl` command:
1. On the Red Hat Advanced Cluster Security for Kubernetes web console there is a download icon for downloading the CLI on the header.  Click the download CLI link and select your platform.
2. Save the `roxctl` command and make sure you can execute it from your path.

### Install yq if not already present:
For RHEL follow these steps
https://snapcraft.io/install/yq/rhel

RHEL 8 prep
1. The EPEL repository can be added to RHEL 8 with the following command: `sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm`
2. The EPEL repository can be added to RHEL 7 with the following command: `sudo dnf upgrade`

RHEL 7 prep
1. `sudo rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm`

Install yq
1. Snap can now be installed as follows: `sudo dnf install snapd`
2. Once installed, the systemd unit that manages the main snap communication socket needs to be enabled: `sudo systemctl enable --now snapd.socket`
3. To enable classic snap support, enter the following to create a symbolic link between /var/lib/snapd/snap and /snap: `sudo ln -s /var/lib/snapd/snap /snap`
4. To install yq, simply use the following command: `sudo snap install yq`
5. Either log out and back in again or restart your system to ensure snap’s paths are updated correctly.

### Deploy the certificate bundle

Follow these steps to deploy the certificates that the Advanced Cluster Security Secure Cluster Services will need to connect to the Central Server.
1. Download the script from this repository [deploy-bundle.sh](scripts/deploy-bundle.sh) `wget https://raw.githubusercontent.com/open-cluster-management/advanced-cluster-security/main/scripts/deploy-bundle.sh`
2. Run the script with the command: `./scripts/deploy-bundle.sh -i bundle.yaml | oc apply -f -`

**NOTE** If you installed the Central Server into a namespace other than `stackrox`, you must specify the namespace using the `-c <central-server-namespace>` option.

### Deploy the policy

Follow these steps to deploy the Secure Cluster Services policy.  **Note** that this policy requires the steps above to have been completed.
1. On the HUB cluster, deploy the policy [Policy to install the Red Hat Advanced Cluster Security Secure Cluster Services](https://github.com/open-cluster-management/policy-collection/blob/main/community/CM-Configuration-Management/policy-acs-operator-secured-clusters.yaml)
2. Make sure the policy is set to `enforce` for the `remediationAction`


Note that the default configuration for the bundle and for the policy is to deploy to all managed cluster that are labeled with `vendor=OpenShift`.  This procedure is only intended to work with OpenShift managed clusters.
