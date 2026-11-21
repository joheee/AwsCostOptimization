# CLAUDE.md

Read `GOALS.md` first. It defines what this repo creates, what is out of scope
and the definition of done. When a choice is unclear, pick the option that makes
the "a real AWS bill cut, with every dollar of the saving backed by a saved
number" story clearer.

## Context

- This repo (joheee/AwsCostOptimization) is portfolio project #8: a cost
  review of an oversized copy of project 1 (joheee/AwsEcsFoundationTerraform),
  with the fixes in Terraform, an Infracost before/after table, an office-hours
  schedule and a one-page recommendation.
- `before/` and `after/` use project 1's modules through a Git source pinned to
  a commit (`git::https://github.com/joheee/AwsEcsFoundationTerraform.git//modules/<name>?ref=<sha>`).
  Don't copy the modules here. New cost levers (ARM64, Fargate Spot, an S3
  gateway endpoint) go into project 1 as optional variables whose defaults keep
  today's behaviour; project 1's CLAUDE.md rules apply there, and its staging
  and prod plans must show no changes.
- Region `ap-southeast-2` only (org SCP). The SCP denies
  `ec2:DescribeInstances` and `elasticloadbalancing:DescribeLoadBalancerAttributes`
  (both observed). Don't add anything that needs them (this rules out a NAT
  instance via `aws_instance`), and don't try to work around the SCP.
- The `ecs-foundation-prod-final` snapshot and project 1's CI roles belong to
  project 1. Don't touch them.

## Layout

- `before/`: root module, oversized sizing in `oversized.tfvars`.
- `after/`: root module with the levers applied, `rightsized.tfvars`, and the
  scheduler (`schedule.tf`: EventBridge Scheduler, its IAM role).
- Each root has `versions.tf`, `main.tf`, `variables.tf`, `outputs.tf` and a
  `backend.hcl` (project 1's state bucket, keys `cost-case/before.tfstate` and
  `cost-case/after.tfstate`, `use_lockfile = true`). Init with
  `terraform init -backend-config=backend.hcl`.
- `infracost-usage.yml`: one usage file shared by both sides.
- `costs/`: saved Infracost output (`before.json`, one `diff-<lever>.txt` per
  lever, `after.json`) and the price list lookups for hand calculations. Commit
  them only after checking they hold no account ID.
- `evidence/`: redacted CLI and CloudWatch output (curl, load test metrics,
  scheduler runs).
- `case-study/`: `cost-review.md`, the PDF, `TEMPLATE.md`.
- `.github/workflows/checks.yml`: fmt, validate, tflint, shellcheck. No AWS
  access. Infracost diff on pull requests is a stretch goal.

## Working rules

- Never commit secrets, the Infracost API key, `*.tfstate`, `.terraform/`,
  saved plan files or an unredacted account ID. Pass the Infracost key as
  `INFRACOST_API_KEY` in the environment. Commit `*.example` files.
- Tags through the provider's `default_tags`: `project = aws-cost-case`,
  `environment = before` or `after`, `managed_by = terraform`.
- Pin Terraform (>= 1.10), the AWS provider (`~> 6.0`), the project 1 module
  ref and the Infracost CLI version. Commit `.terraform.lock.hcl`.
- The before/after comparison uses the same usage file, Infracost version and
  region on both sides. Record the commands and versions in the case study.
- Every number in the README and case study comes from a saved file in
  `costs/` or `evidence/`, and says whether it is Infracost, the AWS price list
  or a hand calculation (show the inputs). Don't claim a saving that hasn't
  been measured or priced. Keep the always-on and the scheduled saving apart.
- Least privilege: the scheduler role may only call `ecs:UpdateService` on this
  service and `rds:StopDBInstance` / `rds:StartDBInstance` on this database.
  Explain any `"*"` resource in a comment.
- Database passwords never go through Terraform (`manage_master_user_password`
  in project 1's module).
- Cost: under $5 for the whole project. Flag anything that adds cost before
  adding it. `before/` runs for about an hour, `after/` only as long as the
  schedule test needs. Destroy both the same day, with no final snapshot.
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

- Project 1's README has an Infracost table for its own staging (~$93) and
  prod (~$236). Use it as a sanity check, not as the "before".
- Infracost reads the HCL and needs no AWS access. It can't model hours
  (the office-hours schedule) and may not price Fargate Spot or ARM64 Fargate;
  price those from the AWS price list and say so.
- RDS restarts on its own after 7 days stopped; a weekly schedule covers that.
  The ALB and NAT gateway can't be stopped, so the schedule saving only covers
  Fargate and RDS instance hours.
- Storage can't shrink in place on RDS. In a real client account, smaller
  storage means a snapshot restore or a migration; say that in the
  recommendation.
