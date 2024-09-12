# Advanced Cluster Security

Learn how quickly you can get Advanced Cluster Security deployed in your Advanced Cluster Management installation.
There are 2 paths to getting started with this solution:
1. Use ACM to fully install ACS. ACM will manage the certificates needed by the Secured Clusters.
2. Use ACM to deploy ACS Secured Clusters to ACM Managed Clusters. ACM will not manage the Central server and will monitor, but not manage, the needed certificates.

Note that the default configuration is to deploy to all managed clusters that are labeled with `vendor=OpenShift`.  This procedure is only intended to work with OpenShift managed clusters.

## Prerequisites

These instructions require the latest generally available Advanced Cluster Management operator to already be installed. 
If you require an older version of Advanced Cluster Management, use a corresponding release branch of the
https://github.com/stolostron/policy-collection repository.

Resources that must exist on the ACM Hub Cluster.
1. The policies namespace
2. A `ManagedClusterSetBinding` for the policies namespace to the `default` `ClusterSet`.
   ```
   apiVersion: cluster.open-cluster-management.io/v1beta2
   kind: ManagedClusterSetBinding
   metadata:
     namespace: policies
     name: default
   spec:
     clusterSet: default
   ```

### Deploy ACS from the OPP PolicySet

Read the [instructions](https://github.com/open-cluster-management-io/policy-collection/blob/main/policygenerator/policy-sets/stable/openshift-plus/README.md) 
for installing OPP (OpenShift Platform Plus) which includes installing ACS, but also installs ODF, and Quay. This PolicySet will be modified to focus only on
deploying ACS.

NOTE: It is not necessary to deploy the OpenShift Plus Setup `PolicySet` mentioned in the OPP instructions.  That setup creates the `policies` namespace and the
`ManagedClusterSetBinding` mentioned in the prerequisites section, but it also deploys storage nodes needed by other OPP components which isn't necessary for ACS.
You must ensure your cluster does have enough resource capacity to deploy ACS.

Follow these steps to modify the OPP PolicySet
1. Fork and clone the https://github.com/open-cluster-management-io/policy-collection repository.
2. Navigate to the `policy-collection/policygenerator/policy-sets/stable/openshift-plus` directory.
3. Edit the policyGenerator.yaml file and comment out everything in the `policies` section of the yaml file that is not in between the lines:
   - `# ACS Policies - start`
   - `# ACS Policies - end`
4. Follow the instructions in the [README.md](https://github.com/open-cluster-management-io/policy-collection/tree/main/policygenerator/policy-sets/stable/openshift-plus/README.md) 
   file to deploy the OpenShift Platform Plus PolicySet.  The details regarding the community OpenShift Plus Setup PolicySet can be ignored.

### Deploy ACS from the Secured Cluster PolicySet

If you have an ACM deployment and the ACS Central server is already deployed to your ACM hub, use this
[link](https://github.com/open-cluster-management-io/policy-collection/tree/main/policygenerator/policy-sets/community/acs-secure)
to obtain the details on how to install Secured Clusters onto your ACM Managed Clusters.

