# CLAUDE.md

Read `GOALS.md` first. It defines what this repo creates, what is out of scope
and the definition of done. When a choice is unclear, pick the option that makes
the "a real AWS bill cut, with every dollar of the saving backed by a saved
number" story clearer, and the simpler stack wins over a more complete one.

## Context

- This repo (joheee/AwsCostOptimization) is portfolio project #8: a cost
  review of a deliberately oversized small stack (one EC2 web server, one RDS
  PostgreSQL, the usual leftovers), with the fixes in Terraform, an Infracost
  before/after table, an office-hours schedule and a one-page recommendation.
- Self-contained on purpose: no modules from project 1
  (joheee/AwsEcsFoundationTerraform) or anywhere else, no ECS, no ALB, no CI
  roles. Keep it at about 15 resources. Reuse project 1's style (pinned
  versions, `default_tags`, small files by concern), not its code.
- Region `ap-southeast-2` only (org SCP). `ec2:DescribeInstances` was believed
  denied but succeeded as the admin user on 2026-11-18; check it before the
  first plan. If it is denied, follow the Fargate fallback in GOALS.md
  "Constraints". `elasticloadbalancing:DescribeLoadBalancerAttributes` is
  denied (observed). Don't try to work around the SCP.
- The `ecs-foundation-prod-final` snapshot and project 1's CI roles belong to
  project 1. Don't touch them.

## Layout

- Repo root: one Terraform root module. `versions.tf`, `network.tf` (VPC, two
  public subnets, internet gateway, optional NAT gateway), `web.tf` (EC2,
  security group, `user_data` with nginx, optional Elastic IP and unattached
  volume), `database.tf` (RDS, subnet group, security group),
  `storage.tf` (S3 backup bucket, optional lifecycle rule, log group),
  `schedule.tf` (EventBridge Scheduler and its role, off in `before`),
  `variables.tf`, `outputs.tf`.
- `before.tfvars`, `after.tfvars`: the only difference between the two sides.
  Non-secret sizing and toggles only.
- `backend.hcl`: project 1's state bucket, key `cost-case/terraform.tfstate`,
  `use_lockfile = true`. One state; switch sides by applying the other var
  file or by destroying first. Init with `terraform init -backend-config=backend.hcl`.
- `infracost-usage.yml`: one usage file shared by both sides.
- `costs/`: `levers.sh` (one Infracost diff per lever), saved Infracost output
  (`before.json`, `diff-<nn>-<lever>.txt`, `after.json`) and price list lookups
  for the hand calculations.
- `evidence/`: redacted CLI and CloudWatch output (curl, load test CPU,
  scheduler runs).
- `case-study/`: `cost-review.md`, the PDF, `TEMPLATE.md`.
- `.github/workflows/checks.yml`: fmt, validate, tflint, shellcheck. No AWS
  access. An Infracost diff on pull requests is a stretch goal.

## Working rules

- Never commit secrets, the Infracost API key, `*.tfstate`, `.terraform/`,
  saved plan files or an unredacted account ID. Pass the Infracost key as
  `INFRACOST_API_KEY` in the environment. Commit `*.example` files.
- Tags through the provider's `default_tags`: `project = aws-cost-case`,
  `environment = before` or `after`, `managed_by = terraform`.
- Pin Terraform (>= 1.10), the AWS provider (`~> 6.0`), the AMI lookup (by
  name filter and owner) and the Infracost CLI version. Commit
  `.terraform.lock.hcl`.
- The before/after comparison uses the same usage file, Infracost version and
  region on both sides. Record the commands and versions in the case study.
- Every number in the README and case study comes from a saved file in
  `costs/` or `evidence/`, and says whether it is Infracost, the AWS price list
  or a hand calculation (show the inputs). Don't claim a saving that hasn't
  been measured or priced. Keep the always-on and the scheduled saving apart.
- Database passwords never go through Terraform: `manage_master_user_password
  = true`. The web server doesn't need the database to serve its page.
- Least privilege: the scheduler role may only call `ec2:StopInstances` /
  `ec2:StartInstances` on this instance and `rds:StopDBInstance` /
  `rds:StartDBInstance` on this database. No SSH: the security group opens
  port 80 only. Explain any `"*"` resource in a comment.
- Cost: under $5 for the whole project. Flag anything that adds cost before
  adding it. `before` runs for about an hour, `after` only as long as the
  schedule test needs. Destroy the same day, with `skip_final_snapshot = true`.
  Never buy Savings Plans or reserved instances.
- Account-level changes (Compute Optimizer opt-in, Cost Explorer settings,
  budgets) change the whole account. Show the exact change and ask first.
- Never run `terraform apply` or `destroy` without being asked; show the plan
  first. Save plans outside the repo; they contain the account ID. Never
  append an apply to a plan command; the user applies saved plans.
- Run `terraform fmt -recursive`, `terraform validate`, `tflint` and
  `shellcheck` before every commit.
- Commits: author `joheee <johevinblesstowi07@gmail.com>`, no Co-Authored-By
  trailer. Ask before committing or pushing. Push to `main`.
- Tick the boxes in the GOALS.md "Definition of done" as items are finished.

## Notes

- Infracost reads the HCL and needs no AWS access. It can't model hours (the
  office-hours schedule); price that from the AWS price list and say so.
- Stopped EC2 still pays for its EBS volume and public IPv4 address; stopped
  RDS still pays for storage and restarts on its own after 7 days. The
  schedule saving only covers instance hours.
- RDS storage can't shrink in place, and gp2 to gp3 or a smaller instance
  means a modify window. In a real account, smaller storage means a snapshot
  restore or a migration; say that in the recommendation. Here `after` is a
  fresh deploy.
- An unattached volume is deleted only after a snapshot in a real account
  (the snapshot costs less). Here it holds nothing, so no snapshot.
