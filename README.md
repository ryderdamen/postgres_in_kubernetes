# PostgreSQL in Kubernetes
This repository contains an example of a stateful postgreSQL instance running in kubernetes. This example is designed to work with Google Cloud Platform's GKE.

## Note
This is not a scalable or fault-tolerant deployment of postgreSQL. While this can operate in a production environment, it's recommended for projects that get little traffic or can handle periodic downtimes of around 30 seconds. For something more, stick to a regular deployment of postgres outside of your kubernetes cluster, and point internal k8 services to it. For everyone else who wants to run a bunch of little databases, keep reading.

## How It Works
This repository runs a postgres database in kubernetes that can survive restarts of nodes (virtual machines) and pods (running conatiners). If the node containing the pod is shut down, the pod will terminate as well. When this happens, a new pod will be spun up somewhere else and mount the persistent volume claim - a piece of disk somewhere that we've tied to the `/var/lib/postgres/data` directory, so that the database will persist on restart.

If this were to happen, there would be about 10-20 seconds of downtime while your kube-master gets everything back up to minimum availability.

### The Components

I've split up the components into separate .yaml files for clarity, but they can just as easily be combined into one file with `---` in between.

| Component | Overview of what it does |
| ------------- |-------------|
| [deployment.yaml](kubernetes/deployment.yaml) | Handles the provisioning of database pods, and configuration of the postgres instance |
| [pvc.yaml](kubernetes/pvc.yaml) | Provisions the physical disk and claim for storing postgres data, so it persists with pod restarts. |
| [secret.yaml](kubernetes/secret.yaml) | Used for storing the base64 encoded database root password (currently `password`). |
| [service.yaml](kubernetes/service.yaml) | Exposes the deployment (one pod) to the world (or the rest of the cluster depending on how configured). |

## Deployment
To deploy to your kubernetes cluster, first configure kubectl with your desired credentials, adjust the variables in the `kuberenetes` folder, and then run:
```bash
make deploy
```

This deployment will create an externally accessible database through a LoadBalancer service. You can find the external IP for it by running `kubectl get svc`.

## Stateful Data
Since this is a database, only one replica in the deployment (pod) can be running at any given time. More than one pod will have conflicts for who can mount the postgres data persistent volume claim. This means it is not possible to scale horizontally, as is the advantage for running most things on kubernetes.

There are pros and cons to running postgreSQL instances on kubernetes - but I do it because I have a lot of little projects that use postgres that I want to keep separate, and keep it cheap. Kubernetes allows me to minimize the blast radius around a specific database instance, and not have to provision a new virtual machine for each one.


## Database Backups
Since only one container can mount the persistent disk at any given time, this makes running a separate container with the `pg_dump` command not a great option. To do this, the live database would have to be shut off while the backup is taking place. Currently, in GCP, [there is an option that allows you to create a schedule of snapshots on persistent disks](https://console.cloud.google.com/compute/snapshotSchedulePolicies/add). This is enough to backup the entire postgres database, as the /var/lib/postgres/data directory contains all necessary stateful info.