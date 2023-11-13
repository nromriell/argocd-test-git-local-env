#!/bin/bash

TEST_APP_COUNT=${1:-10}

# minikube start

# helm dependency build local-env

# To fix crd dependency on prometheus
helm show crds local-env > crds.yaml && kubectl create -f crds.yaml && rm crds.yaml

kubectl create namespace argocd
kubectl create namespace git
kubectl create namespace test

# Wait so that we can get into the git pod
helm upgrade --install local-env local-env --namespace argocd -f local-env/values.yaml --atomic --wait
# Now argocd crds are created, so we can install the application
helm upgrade --install local-env local-env --namespace argocd -f local-env/values.yaml --atomic --wait --set createApp=true

kubectl port-forward -n git service/git 3000:3000 > /dev/null &
kubectl port-forward service/local-env-grafana -n argocd 3001:80 > /dev/null 2> /dev/null &
kubectl port-forward service/local-env-argocd-server -n argocd 3002:80 > /dev/null 2> /dev/null &

# Wait for git to come up
echo "Waiting for git to come up..."
until $(curl --output /dev/null --silent --head --fail http://localhost:3000); do
    printf '.'
    sleep 1
done

echo "Git ui available at http://localhost:3000"
echo "Grafana available at http://localhost:3001"
echo "ArgoCD available at http://localhost:3002"

curl -X POST -H 'Content-Type: application/x-www-form-urlencoded' 'http://localhost:3000/install?db_type=SQLite3&db_host=127.0.0.1%3A5432&db_user=gogs&db_passwd=&db_name=gogs&db_schema=public&ssl_mode=disable&db_path=data%2Fgogs.db&app_name=Gogs&repo_root_path=%2Fdata%2Fgit%2Fgogs-repositories&run_user=git&domain=localhost&ssh_port=22&http_port=3000&app_url=http%3A%2F%2Flocalhost%3A3000%2F&log_root_path=%2Fapp%2Fgogs%2Flog&default_branch=main&smtp_host=&smtp_from=&smtp_user=&smtp_passwd=&enable_captcha=on&admin_name=test-user&admin_passwd=password-test&admin_confirm_passwd=password-test&admin_email=test-user@example.com'

# If file gittoken.txt does not exist
if [ ! -f 'gittoken.txt' ]; then
  echo "Navigate to http://localhost:3000/login login with username: test-user password: password-test"
  echo "Go to http://localhost:3000/user/settings/applications and create a new token with any name"
  echo "Place the value of the token in gittoken.txt at the root of this repo"
  read  -n 1 -p "Press any key to continue..."
fi

AUTH_TOKEN=$(cat gittoken.txt)

echo "Setting up test repos..."
for repo in 'test-apps' 'test-deploy' 'test-values'; do
  cd $repo
  if [[ "$repo" == "test-values" ]]; then
    rm -f values-*.yaml
    ./create-files.sh $TEST_APP_COUNT
  fi
  # reset git state if it exists
  curl -X POST -H "Authorization: token $AUTH_TOKEN" -H "Content-Type: application/json" http://localhost:3000/api/v1/admin/users/test-user/repos --data '{"name":"'$repo'", "private": false}'
  rm -rf .git
  git init -b main
  git add -A
  git commit -m "initial commit"
  git remote add origin "http://test-user:password-test@localhost:3000/test-user/$repo.git"
  git push -f -u origin main
  rm -rf .git
  cd ..
done

echo "Done"
ARGO_ADMIN_PASS=$(kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)
echo "ArgoCD is available at http://localhost:3002 with admin password: $ARGO_ADMIN_PASS"
echo "Will continue to run port-forwards. Press Ctrl+C to exit"
wait
