# network

Creates a custom-mode VPC, regional subnets with Private Google Access and flow logs, a Cloud Router and Cloud NAT in every subnet region, and a firewall baseline:

- Ingress default deny at priority 65534, with logs.
- Egress default deny at priority 65534, with logs.
- Explicit internal allow between the module's subnet CIDRs.
- Explicit SSH allow from the Identity-Aware Proxy range `35.235.240.0/20` to the `allow-iap-ssh` tag.
- Optional explicit health-check allow.
- Any further allows are passed in `ingress_rules` and `egress_rules`.

Internet egress is not opened unless an `egress_rules` entry names the destination. An ingress rule that uses `0.0.0.0/0` or `::/0` is rejected.

## Example

```hcl
module "network" {
  source = "../../modules/network"

  project_id   = module.project.project_id
  network_name = "example-client-vpc"
  subnets = {
    app = {
      region = "us-central1"
      cidr   = "10.16.0.0/20"
    }
  }
  egress_rules = [
    {
      name               = "allow-https"
      priority           = 1000
      protocol           = "tcp"
      ports              = ["443"]
      destination_ranges = ["0.0.0.0/0"]
    }
  ]
}
```

## Validate

```bash
tofu init -backend=false
tofu validate
```
