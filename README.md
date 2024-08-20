## Local environment to test excessive git requests


### For ArgoCD Issue 19382

- Run setup-local-env.sh as described below
- Apply the test Application
    ```sh
    kubectl apply test-19382/application/application.yaml
    ```
- Open ArgoCD
- From the `test-19382-values` directory run `add-and-commit.sh`, this will run updates until interrupted
    ```sh
    cd test-19382-values
    ./add-and-commit.sh
    ```


### Requirements
- git
- helm
- kubectl
- kubernetes environment such as minikube or k3d, scripts will use your current context to deploy applications

### Environment spinup

This does require a manual step once the gog server is up to create an access token and place it in the file `gittoken.txt` this only has to be done
after the git server has been recreated

```sh
./setup-local-env.sh
```

### Environment teardown

This will uninstall the helm chart and attempt to remove the crds. As of now the test applications created by argo will get orphaned

```sh
./cleanup.sh
```