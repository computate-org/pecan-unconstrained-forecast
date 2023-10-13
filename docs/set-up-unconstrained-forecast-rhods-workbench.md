# Set up unconstrained forecast RHODS Workbench

- Log in to the [NERC OpenShift Console here](https://console.apps.shift.nerc.mghpcc.org). 
- Click on your username in the top right, and select [ Copy login command ]. 
- Paste the command into your terminal. 

## Download the RHODS Unconstrained Forecast Secret

- Download the RHODS Unconstrained Forecast Secret

```bash
oc -n software-application-innovation-lab-sail-projects-fcd6dfa get secret/rhods-unconstrained-forecast -o yaml > ~/Downloads/rhods-unconstrained-forecast-secret.yaml
```

## Set up a RHODS Workbench for the Unconstrained Forecast

- Visit the [RHODS dashboard in NERC](https://rhods-dashboard-redhat-ods-applications.apps.shift.nerc.mghpcc.org/projects/software-application-innovation-lab-sail-projects-fcd6dfa)
- Click the [ Create Workbench ] button. 
- Give your workbench a unique name like `ctate-rhods-pecan`. 
- Image selection: PEcAn Unconstrained Forecast
- Container size: Medium or greater
- In "Environment variables", click "Add variable"
  - Select environment variable type: Secret
  - Select one: Upload
  - Click [ Upload ] and select the `~/Downloads/rhods-unconstrained-forecast-secret.yaml`
- Select "Create new persistent storage"
  - Name: Use the name of your workbench
  - Persistent storage size: 20Gi or greater
- Click [ Create workbench ]

## Create a route for your RHODS workbench

By default, our namespace `software-application-innovation-lab-sail-projects-fcd6dfa` is too long for the default Route creation for RHODS to work correctly, 
so we need to create a route to our RHODS workbench manually. 

- Visit the [Routes for our namespace here](https://console.apps.shift.nerc.mghpcc.org/k8s/ns/software-application-innovation-lab-sail-projects-fcd6dfa/route.openshift.io~v1~Route). 
- Click [ Create Route ]. 
- Name: same as your workbench name
- Hostname: Make sure you give your route a unique hostname that ends with `-rhods-pecan.apps.shift.nerc.mghpcc.org`
- Path: /
- Service: Your workbench name, but ending in `-tls`
- Target port: 443
- Select `Secure route`
- TLS termination: Reencrypt
- Insecure traffic: Redirect
- Don't worry about certificates, leave them blank
- Click [ Create ]

Now you should be able to open your RHODS workbench

# Setting up a GitHub personal access token for pecan development in RHODS

- Create a [new GitHub personal acces token here](https://github.com/settings/personal-access-tokens/new) to your repo. 
- Select "Only select repositories", and select your pecan repo. 
- Under "Content", select "Access: Read and Write". 
- Copy the token to the clipboard, then set up the following environment variables in a Terminal in RHODS: 

```bash
GITHUB_USERNAME=...
GITHUB_TOKEN=...
git config --global user.email '...'
git config --global user.name '...'
echo "https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com" > ~/.git-credentials
git config --global credential.helper store
```

Now you should be able to commit and push your pecan changes to GitHub. 

# Running an ecological forecast in RHODS

- Open a Terminal in your workbench: File -> New -> Terminal
- Clone a current PEcAn Git Repo

```bash
git clone https://github.com/${ INSERT YOUR FORK HERE}/pecan.git ~/pecan
cd ~/pecan/
git remote add computate https://github.com/computate/pecan.git
git checkout develop
git pull
git checkout -b hf_landscape_computate
git pull computate hf_landscape

git config pull.rebase false
```

- Make a directory for `forecast_example` and rsync the forecast_example: 

```bash
mkdir ~/forecast_example/
oc rsync ~/Downloads/forecast_example/ ctate-rhods-pecan-0:/opt/app-root/src/forecast_example/
```

- Try out the HARV_metdownload_efi.R script in the Terminal: 

```bash
Rscript pecan/scripts/HARV_metdownload_efi.R
```
