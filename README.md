# Python Docker Starter Example
This is an example Python Docker application that will run JupyterLab.

This pattern can be used to run any long-running Python service that is not expected to terminate.

For short-term jobs that *are* expected to terminate, you won't need the Helm chart steps at the end. 


# Prerequisites
You will need to install [Docker Desktop](https://docs.docker.com/get-docker/)

You can use these steps to modify and rebuild this example using Docker


# Quick Start
Recommended developer workflow:
1. Make edits and `docker compose up -d --build` - to restart the application
2. Navigate to http://localhost:8888 - test your changes
3. `docker compose down` - shut down the application
4. `docker compose build && docker compose push` - build and publish the image
5. `kubectl apply -f kubernetes.yaml` - run image in Kubernetes cluster (image must be published first)
6. Navigate to http://localhost:8888 again to perform integration testing
7. `kubectl delete -f kubernetes.yaml` - shut it down again
8. Create a new Helm chart describing how to run this Docker image
    * The Helm chart will use templates and variable values to produce something like `kubernetes.yaml`
    * Ideally, we should include `values.yaml` (default values), `values.local.yaml` (config for local development), and `values.prod.yaml` (config for production).
    * WARNING: for production passwords and secrets, **DO NOT** commit them to git in plaintext. We will need to create a [SealedSecret](https://github.com/bitnami-labs/sealed-secrets#sealed-secrets-for-kubernetes) first to secure these resources.
9. Install the helm chart and perform final testing locally
10. Add an ArgoCD app to deploy the Helm chart to the production cluster using the correct config values (e.g. `values.prod.yaml`)


# Development
First, you'll need to create a pre-packaged Docker image that will run your application for you.

Feel free to use this repo as a starting point and make modifications as needed :)

## 1) Startup
To build and run the application:
```bash
% docker compose up -d --build
```
OR
```bash
$ docker build -t moleculemaker/python-example-app .
$ docker run -itd -p 8888:8888 -v $(pwd):/home/jovyan --name python-example-app moleculemaker/python-example-app
```

## 2) Making Changes
Once the application is running, you can navigate to http://localhost:8888 in your browser to see the running application.

You can use JupyterLab to edit and test your code, as well as for keeping and formatting your notes.

On http://localhost:8888, open the `Example.ipynb` notebook to see an example.

You can use Markdown cells to create formatted instructions or use `%run filename.py` to run pure Python functions.

Shift + Enter can be used to evaluate the cell and/or format markdown.

## 3) Shutdown
To stop the application, you can run:
```bash
$ docker compose down
```
OR
```bash
$ docker stop python-example-app && docker rm -f python-example-app
```

# 4) Publishing the Docker Image
To share this image with others (and to use it in production), we must push to an image repository.

We can use DockerHub for this, but any public image repo should work.

You can create an account on [DockerHub](https://hub.docker.com/) if you haven't already and push your images there.

## Login to DockerHub
You'll need to log into your DockerHub account to be able to push images.

You can login to this account from the `docker` CLI:
```bash
$ docker login
```

This will prompt you for your DockerHub username and password.

## Pushing an Image to DockerHub
To push the image to DockerHub:
```bash
$ docker compose push
```
OR
```bash
$ docker push moleculemaker/python-example-app
```

This will upload the latest image from your local machine to DockerHub.

## Pulling an Image from DockerHub
To pull the image from DockerHub:
```bash
$ docker compose pull
```
OR
```bash
$ docker pull moleculemaker/python-example-app
```

This will fetch the latest image from DockerHub and download it to your local machine.


# 5-9) Testing in Kubernetes
The last step needed is to create a [Helm chart](https://kubernetes.io/docs/concepts/overview/working-with-objects/kubernetes-objects/) describing how to run this Docker image. We will use this chart to create [Kubernetes YAML](https://kubernetes.io/docs/concepts/overview/working-with-objects/kubernetes-objects/) files that will run our image in the cluster.

An example YAML file and a Helm chart that can be used to change variables.


## Testing in Local Kubernetes cluster
We can [use Docker Desktop to run a local Kubernetes cluster](https://docs.docker.com/desktop/kubernetes/) to test this application.

**WARNING: make sure to `docker compose down`  your existing containers to avoid port conflicts with Kubernetes**


## Startup
We can use the included `integration/kubernetes.yaml` to test running this application in a local cluster:
```bash
$ helm upgrade --install hello-python . -f values.local.yaml
```
OR
```bash
$ kubectl apply -f integration/kubernetes.yaml
```

You should then be able to access the application on http://localhost:8888 as before.

## Applying a Domain Name
If you run the NGINX Ingress controller, you can use http://python.example.localhost as well:
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade ingress-nginx ingress-nginx/ingress-nginx --install --set controller.hostNetwork=true
```

NOTE: any hostname ending in `.localhost` should resolve to your local machine

The image is now running the same way that it will run in production.


## Shutdown
To shut down the application, you can run the following:
```bash
$ helm uninstall hello-python
```
OR
```bash
$ kubectl delete -f integration/kubernetes.yaml
```


# 10) Deploying to Production
The final step is to deploy this Helm chart to our production cluster.

We can do this automatically using ArgoCD, which will upgrade our running Helm chart when we make changes to the GitHub repo.


## Accessing ArgoCD
If you do not have access to ArgoCD, contact your project admin to make them aware of any new contributions to the project. If you are part of the development team, you can request access to cool cluster resources like ArgoCD and Rancher.


## Using ArgoCD
If you have access to ArgoCD, you can Create a new Argo App on the cluster.

The ArgoCD app will accept a git repo/path containing your Helm chart, and a path to the `values.yaml` file that it should use to deploy this instance.

For this example, we would create an ArgoCD app like the one in [integration/python-example-app.application.yaml](./integration/python-example-app.application.yaml)

After we create this Application resource, it will deploy the given `source` Helm chart automatically to the `destination` cluster/namespace.


# Looking Forward: Automated Maintenance
With all the steps we've taken above, we are able to automate the last few manual steps here.

## Updates to the Source Code
Changes to the source code will require occasionally building and pushing a new Docker image.

We can automate this process using [GitHub Actions](https://docs.github.com/en/actions/quickstart), and have provided [docker.yml](./.github/workflows/docker.yml) to help!

This simple workflow will trigger when changes are pushed to the default branch of the repo, if a Pull Request is created, or if a new release version is tagged.

The workflow will automatically build a new Docker image with appropriate image tags and push the image to DockerHub.

## Updates to the Helm Chart
ArgoCD will keep the running application in sync as we change the Helm chart in our repo.

We just need to push changes to the `main` branch for ArgoCD to pick them up.

## Missing Automation: Delete Pod to use new Docker Image
We are still missing one automated piece here to deploy the new image automatically after the build completes, but we are looking into tools to fill this gap. We may need to do this part manually for now, since it would involve shutting down / restarting the running services and we should manually choose when this happens.

See https://stackoverflow.com/a/55914480
