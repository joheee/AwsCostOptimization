# AWS cost optimization: before and after, in dollars

A cost review of a small AWS setup that costs far more than it needs to,
with the fixes made in Terraform and the saving priced line by line.

> **Status: in progress.** The plan is fixed (see [GOALS.md](GOALS.md)); the
> Terraform, the cost table and the case study are being built. No numbers
> below are results yet. Every dollar figure will come from a saved Infracost
> output, an AWS price list lookup or CLI output in this repo.

## What this shows

Most AWS bills I look at have the same problems: servers sized for a launch
that never came, old disk types, things left running that nobody uses, and
non-prod running all night and all weekend. This repo is a worked example of
finding and fixing those, the way I would for a client:

1. Price the current setup from its Terraform.
2. Change one thing at a time and price each change, so you can see what
   every fix is worth before you approve it.
3. Apply the changes and check the app still works.
4. Write a one-page recommendation, including the savings I did not make for
   you (commitments and bigger architecture changes) with their numbers.

## The setup

One web server and one PostgreSQL database in `ap-southeast-2`, plus the
leftovers that build up in a real account. Everything is in one small
Terraform folder; `before.tfvars` and `after.tfvars` are the only difference
between the two sides.

| | Before | After |
|---|---|---|
| Web server | `m7i.xlarge` (x86), 200 GB gp2 | `t4g.small` (Graviton), 20 GB gp3 |
| Database | `db.m7i.large`, multi-AZ, 200 GB gp2 | `db.t4g.micro`, single-AZ, 20 GB gp3 |
| NAT gateway | 1, nothing routes through it | removed |
| Unattached EBS volume | 500 GB gp2 | removed |
| Idle Elastic IP | 1 | released |
| Log retention | never expires | 14 days |
| S3 backups | Standard, no lifecycle rule | Standard-IA after 30 days, expire after 90 |
| Running hours | 24/7 | web server and database stopped 19:00 to 08:00 and at weekends |

The office-hours schedule uses EventBridge Scheduler. Its role can only stop
and start these two instances.

## Cost table

_To be filled from the saved scans in `costs/`._ It will show the monthly cost
before, the saving from each change, the cost after, and the cost after with
the schedule, in dollars and as a percentage. The always-on saving and the
schedule saving are kept on separate lines so the headline number is not
inflated.

## How the numbers are made

- **Infracost** prices the Terraform for each side (`breakdown`) and the gap
  between them (`diff`). Both sides use the same `infracost-usage.yml`, so
  usage-based items (S3 storage, logs, NAT data) rest on the same
  assumptions.
- **AWS price list** covers what Infracost can't model, mainly the hours saved
  by the schedule. Those rows show their inputs.
- **The live run**: each side is deployed for a short time, checked with
  `curl` and CloudWatch, then destroyed the same day.

## Not changed, but priced

- **Savings Plans and reserved instances.** They lock you in for one or three
  years, so the review prices them and leaves the decision to you.
- **A cheaper architecture.** For an app this small, Lightsail (an instance
  and a managed database) is priced as an option. Not deployed.

## Repo layout (planned)

| Path | What it holds |
|---|---|
| `*.tf` | The Terraform: network, web server, database, storage, schedule |
| `before.tfvars`, `after.tfvars` | The two sides of the review |
| `infracost-usage.yml` | Usage assumptions shared by both sides |
| `costs/` | Saved Infracost output and price lookups |
| `evidence/` | Redacted `curl`, CloudWatch and scheduler output |
| `case-study/` | The written review, its PDF and a blank template |

## Cost of the demo

The budget is under $5 in total. The "before" side runs for about an hour and
the "after" side for a few hours to test the schedule, and both are destroyed
the same day. The real cost will be recorded here.

## Related projects

- [AwsEcsFoundationTerraform](https://github.com/joheee/AwsEcsFoundationTerraform):
  a two-environment AWS foundation (VPC, ECS on Fargate, RDS) deployed by
  GitHub Actions.
- [AwsSecurityAudit](https://github.com/joheee/AwsSecurityAudit): a security
  audit of that foundation with Prowler and Checkov, fixes and a before and
  after scan.
