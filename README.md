# Superset Bigquery PoC
Sample code for deploying [Apache Superset](https://superset.apache.org/)
on Google Cloud with Kubernetes.

> WARNING! This does not result in a production-ready deployment!
> This is not officially supported Solita Cloud project!

That being said, Solitans can contact @bensku in Slack for assistance.

## Requirements
Before we start, make sure you have these tools installed and configured:
* [`gcloud`](https://cloud.google.com/sdk/docs/install) CLI (authenticated to your project) and [`gke-gcloud-auth-plugin`](https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl#install_plugin)
* `kubectl`
* `helm`
* `git`
* [OpenTofu](https://opentofu.org/docs/intro/install/)

I recommend using your local computer. Cloud Shell can install things, but
port forwarding will not work so you can't (securely) access Superset.
For Windows, e.g. Git Bash should suffice.

## Installation
First step of installation is to clone this repository and install OpenTofu
providers (plugins) that we need to deploy:

```sh
git clone https://github.com/solita/superset-bigquery.git
cd superset-bigquery
tofu init
```

After this, we can proceed to actual deployment:
```sh
# Set your project details as environment variables - we'll need these later
export PROJECT_ID=...
export GCP_REGION=europe-north1 # Finland
tofu apply -var project_id=$PROJECT_ID -var region=$GCP_REGION
```

This creates a Kubernetes cluster and installs Superset (and Bigquery driver)
into it. The whole process can easily take 10-15 minutes, and should need no
input from you. Time for a coffee break?

Finally, we should configure your local `kubectl` to access the Superset cluster:
```sh
gcloud container clusters get-credentials superset-cluster --region $GCP_REGION --project $PROJECT_ID
```

## Accessing Superset
The easiest *secure* way to access Superset is via port-forwarding:
```sh
kubectl -n superset port-forward svc/superset 8088
```

With this running, you can access the cluster at
[localhost:8088](http://localhost:8088). Username and password are `admin` and `admin`

You can also expose the installation over Internet **insecurely** by modifying
the OpenTofu stack:
```sh
tofu apply -var project_id=$PROJECT_ID -var region=$GCP_REGION -var expose=true
kubectl -n superset get ing # If you don't see an ADDRESS, wait 5-10 minutes and check again
```

... but this will allow **anyone in Internet** to log in, unless you configure
some kind of authentication.

## Adding BigQuery data source
BigQuery can be added like any other database.

For credentials, download service account key in JSON format from Google
Cloud console. To be precise:

1. Search "service accounts" and open that page
2. Open `superset-sa@<something>.iam.gserviceaccount.com`
3. Navigate to keys tab
4. "Add key" -> "Create new key" -> select JSON format
5. Upload the file you got to Superset

After this, everything should "just work"!

## Uninstallation
To destroy Superset installation and the Kubernetes cluster, run:

```sh
tofu apply -var project_id=$PROJECT_ID -var region=$GCP_REGION
```

(use the `export` commands from installation instructions if needed)