# Terraform Jupyter Notebooks 

Terraform Code to deploy self-managed Jupyter Notebooks in AWS using Spot Instances

## Usage

* Deploy the Network Infrastructure and the Spot Instance 

```md
make create
```

* Check the Output

```md
terraform output
```

## Access to Jupyter instance

```md
ssh_ip=$(terraform output -json ec2_spot_instance_public_ip | jq -r '.[0]')
ssh -l ec2-user $ssh_ip
```