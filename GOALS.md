# Project goals: AWS cost cut, before and after, with the saving in dollars

This repo (joheee/AwsCostOptimization) is portfolio project #8 for my Upwork
DevOps profile. The point is the **case study**: a client should look at it and
think "this person will find where my AWS bill goes, cut it without breaking
anything, and show me the saving in dollars before I commit to a change".

Cost jobs on Upwork ask for the same few things: find the waste, rightsize,
stop non-prod outside working hours, and write a short recommendation. This
project does all of that on a small, typical setup: one web server, one
PostgreSQL database and the leftovers that pile up around them.

## The pitch (what a client buys)

> "AWS cost review with the fixes in Terraform, 2 days." I map your monthly
> bill to the resources behind it, find the oversized, forgotten and always-on
> parts, and change them in your Terraform: smaller and Graviton instances,
> gp3 instead of gp2, no idle NAT gateway or Elastic IP, log retention and S3
> lifecycle rules, and a schedule that stops non-prod at night and on
> weekends. You get a cost table for every change before it is applied, the
> Terraform diff, and a one-page recommendation that covers what I did not
> change (Savings Plans, a cheaper architecture) with the numbers.

It matches jobs like "Azure cost optimization", "cloud footprint optimizer",
"move to low-cost AWS" and "VM start/stop schedule" from the demand research.

## How it is built

- One small Terraform root module in this repo, no modules from other repos.
  `before.tfvars` and `after.tfvars` are the only difference between the two
  sides, so the tfvars diff **is** the cost fix a client would review.
- The stack, about 15 resources:
  - A VPC with two public subnets (RDS needs two AZs) and an internet gateway.
  - One EC2 web server running nginx from `user_data`, with its security group.
  - One RDS PostgreSQL instance, private, reachable only from the web server.
  - The waste a real account collects, each behind a toggle: a NAT gateway
    nobody routes through, an unattached EBS volume, an idle Elastic IP, a log
    group that never expires and an S3 bucket with no lifecycle rule.
  - In `after` only: an EventBridge Scheduler office-hours schedule.
- Prices come from Infracost (`breakdown` for each side, `diff` between them),
  with one shared `infracost-usage.yml` so usage-based items (S3 storage, logs,
  NAT data) use the same assumptions on both sides.
- Applied locally, state in project 1's existing state bucket under its own
  key. No CI roles, no OIDC, no ALB or ECS: this is a one-day demo.

| | before | after |
|---|---|---|
| Web server | `m7i.xlarge` (x86), 200 GB gp2 | `t4g.small` (Graviton), 20 GB gp3 |
| Database | `db.m7i.large`, multi-AZ, 200 GB gp2 | `db.t4g.micro`, single-AZ, 20 GB gp3 |
| NAT gateway | 1, unused | none |
| Unattached EBS volume | 500 GB gp2 | deleted (snapshot first in real life) |
| Idle Elastic IP | 1 | released |
| Log retention | never expires | 14 days |
| S3 backups | Standard, no lifecycle | Standard-IA after 30 days, expire after 90 |
| Schedule | 24/7 | EC2 and RDS stopped 19:00 to 08:00 and weekends |

Exact sizes are fixed on day 1 so the "before" lands in a believable range
(roughly $500 to $800 a month).

## Objectives

1. **Simple stack, two tfvars.** The root module above, with every waste item
   and size as a variable. `terraform plan` works for both var files.
2. **Baseline cost.** `infracost breakdown` with `before.tfvars` and the shared
   usage file, saved as JSON and as a table. Deploy `before` for about an hour,
   `curl` the web server to show it works, and save its CloudWatch CPU (free
   basic metrics) during a short load test to back the rightsizing. Destroy.
3. **One change per lever, each priced.** A small script applies the levers
   one at a time (each step is a var file or `-var` overrides) and saves an
   Infracost diff per step, so the table shows what each change saved:
   rightsize and Graviton for EC2, rightsize and single-AZ for RDS, gp2 to
   gp3, remove the idle NAT gateway, Elastic IP and unattached volume, log
   retention, S3 lifecycle.
4. **Office-hours schedule.** EventBridge Scheduler stops the EC2 instance and
   the RDS instance at 19:00 and starts them at 08:00, weekdays only
   (Asia/Jakarta). The scheduler role can only stop and start these two
   instances. Proven on a deployed `after` by moving the schedule a few
   minutes ahead and checking the instance states with the AWS CLI. The saving
   is calculated from unit prices (Infracost can't model hours) and shown on
   its own line.
5. **Cost table and diff.** The README and case study have one table: before,
   each lever, after, and after with the schedule, in dollars per month and as
   a percentage. The headline number is the total monthly cut ("from $X to $Y
   a month, Z% less"), with the always-on and the scheduled figure kept apart
   so nothing is overstated.
6. **What I did not change, with numbers.** A short section the client can act
   on: Savings Plans or reserved instances (the saving at today's rates, and
   why I don't buy commitments on a client's behalf), and a cheaper
   architecture option (Lightsail instance and database for a small app),
   priced from the AWS price list. Paper only.
7. **One-page recommendation and case study.** `case-study/cost-review.md` and
   a PDF: the one-page summary a business owner reads (current cost, new cost,
   saving, the risk of each change, what to do next), then the method, prices
   and assumptions. `case-study/TEMPLATE.md` to reuse on client jobs.
8. **Client-style README.** What the review covers, the cost table, the tfvars
   diff, how to run the Infracost comparison yourself, the cost of the demo
   itself, and a link to the case study.

## Stretch

- Infracost in a GitHub Actions check that posts the before/after diff on a
  pull request (no AWS access needed).
- A Cost Explorer screenshot of the demo day next to the Infracost estimate.
- AWS Compute Optimizer: needs opt-in (account-level, ask first) and at least a
  day of metrics, so only if the timing works.

## Out of scope

- Buying Savings Plans or reserved instances. They are a 1 or 3 year
  commitment; the case study only prices them.
- Deploying the Lightsail option.
- ECS, an ALB, Kubernetes or multiple environments. Project 1 covers those;
  this project is about the bill, not the platform.
- Azure or GCP. The pitch says "AWS"; the method carries over.

## Constraints

- Region `ap-southeast-2` only (org SCP). The SCP was believed to deny
  `ec2:DescribeInstances`, which Terraform's `aws_instance` needs, but the call
  succeeded as the admin user on 2026-11-18. Check it on day 1
  (`aws ec2 describe-instances --region ap-southeast-2`). If it is denied, the
  web server becomes one Fargate task with a public IP (no ALB) and the EC2
  levers move to Fargate size and ARM64.
- `elasticloadbalancing:DescribeLoadBalancerAttributes` is also denied; there
  is no load balancer here, so it doesn't matter.
- Cost: under $5 in total. `before` runs for about an hour (about $1 at the
  target sizes), `after` for a few hours to test the schedule (cents). Destroy
  both the same day, with no final snapshot.
- Every number in the case study comes from a saved Infracost output, a saved
  AWS price list lookup or a saved CLI or CloudWatch output, and the case study
  says which. Hand calculations show their inputs.
- The before/after comparison uses the same usage file, Infracost version and
  region on both sides.

## Plan (2 days)

| Day | Work |
|---|---|
| 1 | SCP check. Root module, both tfvars, usage file, baseline Infracost. `before` deployed, curl and a short load test, CPU saved, destroyed. |
| 2 | Lever script with one Infracost diff per step. Scheduler. `after` deployed, schedule tested, destroyed. Cost table, recommendation, case study and PDF, README. Upwork portfolio entry. |

Progress (2026-11-21): day 1 is half done. SCP check passed (EC2 stays), the
module, both tfvars and the baseline Infracost are pushed, both plans are
clean. Still to do on day 1: deploy `before`, curl, load test, destroy. The
lever script is the next piece of day 2 work and can be done before the deploy.

## Tools and software

Terraform (>= 1.10) with the AWS provider 6.x · Infracost (breakdown, diff,
usage file) · Amazon EC2 and Graviton · Amazon RDS PostgreSQL · EBS gp3 ·
EventBridge Scheduler · CloudWatch metrics · S3 lifecycle rules · AWS Price
List · AWS Lightsail (priced only) · AWS Cost Explorer (stretch) · Bash ·
pandoc (PDF)

## Definition of done

- [x] One root module; `before.tfvars` and `after.tfvars` are the only difference, and both plan cleanly.
- [x] Baseline Infracost breakdown of `before` saved, with the shared usage file.
- [ ] `before` deployed, answered a `curl`, load-test CPU saved, destroyed the same day.
- [ ] One saved Infracost diff per cost lever, each with its monthly saving.
- [ ] Office-hours schedule stops and starts EC2 and RDS on a deployed `after` (CLI output saved); `after` destroyed the same day.
- [ ] Cost table in the README: before, each lever, after, after with the schedule, in dollars and percent.
- [ ] Savings Plans and a Lightsail option priced in the recommendation (not bought, not deployed).
- [ ] `case-study/cost-review.md`, its PDF and `case-study/TEMPLATE.md` written.
- [ ] Demo cost recorded (under $5), nothing left running, no secrets, state or account IDs committed.
- [ ] README has the scope, the cost table, the tfvars diff, how to rerun the comparison and a link to the case study.
