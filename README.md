# Azure Arc demo

## Azure Arc References

### Web Links

* <https://aka.ms/AzureArc>
* <https://aka.ms/AzureArcLearn>
* <https://aka.ms/AzureArcSkilling>
* <https://aka.ms/AzureArc-Yammer>

### Repos

* <https://github.com/microsoft/azure_arc>
* <https://github.com/Azure/azure-arc-kubernetes-examples>
* <https://github.com/Azure/arc-k8s-demo>
* <https://github.com/Azure/arc-helm-demo>
* <https://github.com/Azure/AzureStackHCI-EvalGuide>

## Set up

This guide assumes you are an Azure user with WSL setup with an Ubuntu distro. Required binaries include az and jq.

You will also need [Ansible](https://docs.ansible.com/ansible/latest/scenario_guides/guide_azure.html) installed locally.

### Azure subscription

1. Check the status of the required providers:

    ```bash
    az provider list --query "[? namespace == 'Microsoft.HybridCompute' || namespace == 'Microsoft.GuestConfiguration']" --output table
    ```

1. If unregistered:

    ```bash
    az provider register --namespace 'Microsoft.HybridCompute'
    az provider register --namespace 'Microsoft.GuestConfiguration'
    ```

Standard provider config is default and [authenticates using the Azure CLI](https://www.terraform.io/docs/providers/azurerm/guides/azure_cli.html).

### GCP

Create a project and a service account, storing the credentials. Useful [cheat sheet](https://gist.github.com/pydevops/cffbd3c694d599c6ca18342d3625af97
.)

1. Install the [Google Cloud SDK](https://cloud.google.com/sdk/docs/install#deb) into Ubuntu

1. Sign up for a [free GCP account](https://cloud.google.com/free) and login

    ```bash
    gcloud auth login
    gcloud projects list
    ```

1. Check the billing

    ```bash
    gcloud beta billing accounts list --format json
    ```

    [
      {
        "displayName": "My Billing Account",
        "name": "billingAccounts/01C77E-257934-C7CC40",
        "open": true
      }
    ]

    ```bash
    gcp_billing_account=$(gcloud beta billing accounts list --format="value(name)")
    ```

1. Create a new project

    ```bash
    gcp_project=azure-arc-richeney
    gcloud projects create $gcp_project --name "Azure Arc"--set-as-default
    ```

    > Set the gcp_project to a unique value

1. Link to the billing name

    ```bash
    gcloud beta billing projects link $gcp_project --billing-account $gcp_billing_account
    ```

    ```yaml
    billingAccountName: billingAccounts/01C77E-257934-C7CC40
    billingEnabled: true
    name: projects/azure-arc-richeney/billingInfo
    projectId: azure-arc-richeney
    ```

1. Enable the Google Compute APIs

    ```bash
    gcloud services enable compute.googleapis.com
    ```

1. Create a service account

    ```bash
    gcloud iam service-accounts create terraform --description "Terraform service account for GCP" --display-name Terraform
    gcloud iam service-accounts list
    ```

    Example output:

    ```text
    DISPLAY NAME  EMAIL                                                 DISABLED
    Terraform     terraform@azure-arc-richeney.iam.gserviceaccount.com  False
    ```

    ```bash
    gcp_sa=terraform@$gcp_project.iam.gserviceaccount.com
    ```

1. Add as Editor on the project

    ```bash
    gcloud projects add-iam-policy-binding $gcp_project --member=serviceAccount:$gcp_sa --role=roles/editor
    ```

    ```yaml
    Updated IAM policy for project [azure-arc-richeney].
    bindings:
    - members:
      - serviceAccount:terraform@azure-arc-richeney.iam.gserviceaccount.com
      role: roles/editor
    - members:
      - user:richeney@microsoft.com
      role: roles/owner
    etag: BwWxADyD3AE=
    version: 1
    ```

1. Export the credentials file

    ```bash
    gcloud iam service-accounts keys create ~/.gcp/account.json --iam-account terraform@azure-arc-richeney.iam.gserviceaccount.com
    ```

    ```text
    created key [a138760f38b8bb04687d092ed86a55f8bb35f616] of type [json] as [/home/richeney/.gcp/account.json] for     [terraform@azure-arc-richeney.iam.gserviceaccount.com]
    ```

The var.gcp_credentials default value is `~/.gcp/account.json`.

**Set var.gcp_project in terraform.tfvars to your GCP project name, e.g. `azure-arc-richeney`.**

#### GCP References

* <https://ssh.cloud.google.com/>
* <https://cloud.google.com/sdk/docs/quickstart-debian-ubuntu>
* <https://www.terraform.io/docs/providers/google/guides/getting_started.html>
* <https://cloud.google.com/community/tutorials/getting-started-on-gcp-with-terraform>
* <https://console.cloud.google.com/> - ends 26 Nov 2020

### AWS

1. Install the AWS CLI v2

    ```bash
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    ```

1. Sign up for a [free AWS account](https://aws.amazon.com/free/) and login

1. Grab your access keys from [Account Name | My Security Credentials](https://console.aws.amazon.com/iam/home#/security_credentials)

1. Basic configuration

    ```bash
    aws configure
    ```

    ```text
    AWS Access Key ID [None]: <redacted>
    AWS Secret Access Key [None]: <redacted>
    Default region name [None]: eu-west-2
    Default output format [None]: json
    ```

    The access keys will be added to the default section of the `~/.aws/credentials` file. The preferences will be added to the defaults section of the `~/.aws/config` file.

    The CLI commands will work now.

1. Create a Terraform IAM user

    ```bash
    aws iam create-user --user-name terraform
    ```

    ```json
    {
        "User": {
            "Path": "/",
            "UserName": "terraform",
            "UserId": "AIDAUMQBX6OBRFHKWTZDL",
            "Arn": "arn:aws:iam::301725119363:user/terraform",
            "CreateDate": "2020-10-06T14:49:44+00:00"
        }
    }
    ```

1. Add to the admin group

    ```bash
    aws iam add-user-to-group --user-name terraform --group-name admin
    aws iam get-group --group-name admin
    ```

1. Create an access key

Grab the output as a JSON string.

    ```bash
    json=$(aws iam create-access-key --user-name terraform --output json)
    echo $json
    ```

1. Add to the credentials file

    ```bash
    cat >> ~/.aws/credentials <<EOF

    [terraform]
    aws_access_key_id = $(jq -r .AccessKey.AccessKeyId <<< $json)
    aws_secret_access_key = $(jq -r .AccessKey.SecretAccessKey <<< $json)
    EOF

    cat ~/.aws/credentials
    ```


#### AWS References

* <https://aws.amazon.com/free/>
* <https://aws.amazon.com/console/>
* <https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html#concepts-available-regions>
* <https://console.aws.amazon.com/ec2/>
* <https://docs.aws.amazon.com/sdk-for-java/v1/developer-guide/setup-credentials.html>

## Running it

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

The AWS and GCP files will create an Ubuntu VM. It uses cloud init to set up SSH and then uses Ansible to download the Debian package for azcmagent, install it and then connect up to Azure using the injected service principal credentials.
