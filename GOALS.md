# Project goals: AWS cost cut, before and after, with the saving in dollars

This repo (joheee/AwsCostOptimization) is portfolio project #8 for my Upwork
DevOps profile. The point is the **case study**: a client should look at it and
think "this person will find where my AWS bill goes, cut it without breaking
anything, and show me the saving in dollars before I commit to a change".

Cost jobs on Upwork ask for the same few things: find the waste, rightsize,
stop non-prod outside working hours, and write a short recommendation. This
project does all of that on a stack I already built: project 1
([joheee/AwsEcsFoundationTerraform](https://github.com/joheee/AwsEcsFoundationTerraform)),
a VPC, ECS on Fargate behind an ALB and RDS PostgreSQL in `ap-southeast-2`.

The "before" is a deliberately oversized staging environment: sized like a
busy prod and running 24/7, the way many client accounts look. The "after" is
the same app with each waste removed, one change at a time, so every saving has
its own line in the table.

## The pitch (what a client buys)

> "AWS cost review with the fixes in Terraform, 2 days." I map your monthly
> bill to the resources behind it, find the oversized and always-on parts, and
> change them in your Terraform: smaller and Graviton instances, Spot for
> non-prod, fewer NAT gateways, log retention and S3 lifecycle rules, and a
> schedule that stops non-prod at night and on weekends. You get a cost table
> for every change before it is applied, the Terraform diff, and a one-page
> recommendation that covers what I did not change (Savings Plans, a cheaper
> architecture) with the numbers.

It matches jobs like "Azure cost optimization", "cloud footprint optimizer",
"move to low-cost AWS" and "VM start/stop schedule" from the demand research.

## How it is built

- `before/` and `after/` are two small root modules. Both use project 1's
  modules (`network`, `ecs_service`, `rds_postgres`) through a Git source
  pinned to a project 1 commit, so the case study tracks real code and does not
  copy it.
- Any cost lever the modules don't have yet (Graviton `cpu_architecture`,
  Fargate Spot capacity provider, an S3 gateway endpoint) is added to project 1
  as a new optional variable whose default keeps today's behaviour. Project 1's
  staging and prod plans must show no changes after such a commit.
- Prices come from Infracost (`breakdown` for each side, `diff` between them),
  with one shared `infracost-usage.yml` so usage-based items (NAT data, logs,
  S3 storage) use the same assumptions on both sides.
- Applied locally, with state in project 1's existing state bucket under
  separate keys. No CI roles, no OIDC: this is a one-day demo, not a platform.

## Objectives

1. **Oversized "before".** `before/` with an `oversized.tfvars` that looks like
   a typical over-provisioned non-prod: three AZs with a NAT gateway each,
   four Fargate tasks at 1 vCPU / 2 GB on x86, Container Insights on, RDS
   `db.m7g.large` multi-AZ with 200 GB, log groups kept for a year, and an S3
   bucket of backups with no lifecycle rule. Exact sizes are fixed on day 1 so
   the total lands in a believable range (roughly $500 to $800 a month).
2. **Baseline cost.** `infracost breakdown` of `before/` with the shared usage
   file, saved as JSON and as a table. Deploy `before/` for about an hour,
   `curl` the ALB to show it works, and save CloudWatch CPU and memory for the
   service and the database during a short load test. Then destroy it.
3. **One change per lever, each priced.** In `after/`, apply the levers one at
   a time and save an Infracost diff for each step, so the table shows what
   each change saved:
   - Rightsize Fargate tasks and the RDS class from the measured CPU and
     memory (and say how short the measurement window was).
   - Graviton (ARM64) for Fargate and RDS.
   - Fargate Spot for the non-prod service. Fargate Spot has not supported
     ARM64 tasks; check on day 1. If that is still true, the service uses
     whichever of the two saves more and the table says why.
   - Where Infracost can't price a lever (Spot, possibly ARM64 Fargate), the
     saving is calculated from the AWS price list and marked as such.
   - One NAT gateway instead of three, plus a free S3 gateway endpoint.
   - RDS single-AZ and gp3 storage sized to the data.
   - Log retention of 14 days, Container Insights off for non-prod, and an S3
     lifecycle rule (Standard-IA, then expire) on the backup bucket.
4. **Office-hours schedule.** EventBridge Scheduler stops non-prod outside
   working hours: ECS desired count to 0 and RDS stopped at 19:00, started at
   08:00, weekdays only (Asia/Jakarta). The scheduler role can only touch this
   service and this database. Proven on a deployed `after/` by moving the
   schedule a few minutes ahead and checking the service and database state
   with the AWS CLI. The saving from the schedule is calculated by hand from
   unit prices (Infracost can't model hours) and shown on its own line.
5. **Cost table and diff.** The README and case study have one table: before,
   each lever, after, and after with the schedule, in dollars per month and
   as a percentage. The headline number is the total monthly cut (for example
   "from $X to $Y a month, Z% less"), with the always-on and the scheduled
   figure kept apart so nothing is overstated.
6. **What I did not change, with numbers.** A short section the client can act
   on: Savings Plans or reserved instances for prod (the saving at today's
   rates, and why I don't buy commitments on a client's behalf), and a cheaper
   architecture option (for example Lightsail containers and a Lightsail
   database for a small app) priced from the AWS price list. Paper only,
   nothing deployed.
7. **One-page recommendation and case study.** `case-study/cost-review.md` and
   a PDF: the one-page summary a business owner reads (current cost, new
   cost, saving, risks of each change, what to do next), then the method,
   prices and assumptions. `case-study/TEMPLATE.md` to reuse on client jobs.
8. **Client-style README.** What the review covers, the cost table, how to
   run the Infracost comparison yourself, the cost of the demo itself, and a
   link to the case study.

## Stretch

- Infracost in a GitHub Actions check that posts the before/after diff on a
  pull request (no AWS access needed).
- A real Cost Explorer screenshot of the demo day, next to the Infracost
  estimate, to show the estimate and the bill agree.
- Turn on AWS Compute Optimizer and compare its advice with mine. It needs
  opt-in (an account-level change, ask first) and at least a day of metrics,
  so only if the timing works.

## Out of scope

- Buying Savings Plans or reserved instances. They are a 1 or 3 year
  commitment; the case study only prices them.
- Deploying the Lightsail option.
- A NAT instance (for example fck-nat): Terraform's `aws_instance` reads the
  instance back with `ec2:DescribeInstances`, which the org SCP denies. It goes
  in the recommendation as an option for clients without that SCP.
- Azure or GCP. The pitch says "AWS"; the method carries over.
- Changing project 1's own staging or prod sizing.

## Constraints

- Region `ap-southeast-2` only (org SCP). The SCP denies
  `ec2:DescribeInstances` and `elasticloadbalancing:DescribeLoadBalancerAttributes`
  (both observed). Don't add anything that needs them.
- Cost: under $5 in total. The oversized `before/` runs for about an hour
  (roughly $1 per hour at the target size), `after/` for a few hours to test
  the schedule (cents). Destroy both the same day. Nothing standing; no final
  snapshots.
- Every number in the case study comes from a saved Infracost output, a saved
  AWS price list lookup or a saved CLI or CloudWatch output, and the case study
  says which. Hand calculations show their inputs.
- The before/after comparison uses the same usage file, Infracost version and
  region on both sides.

## Plan (2 days)

| Day | Work |
|---|---|
| 1 | Repo skeleton, `before/` sizes fixed, usage file, baseline Infracost. Any new project 1 module variables (no-change plans for staging and prod). `before/` deployed, curl and a short load test, metrics saved, destroyed. |
| 2 | `after/` with one Infracost diff per lever. Scheduler module. `after/` deployed, schedule tested, destroyed. Cost table, recommendation, case study and PDF, README. Upwork portfolio entry. |

## Tools and software

Terraform (>= 1.10) with the AWS provider 6.x · Infracost (breakdown, diff,
usage file) · AWS Fargate and Fargate Spot · Graviton (ARM64) · Amazon RDS
PostgreSQL · EventBridge Scheduler · CloudWatch metrics · S3 lifecycle rules ·
VPC gateway endpoints · AWS Price List · AWS Cost Explorer (stretch) ·
AWS Compute Optimizer (stretch) · Bash · pandoc (PDF)

## Definition of done

- [ ] `before/` and `after/` use project 1's modules through a pinned Git source; any new module variable keeps project 1's staging and prod plans unchanged.
- [ ] Baseline Infracost breakdown of `before/` saved, with the shared usage file.
- [ ] `before/` deployed, answered a `curl`, load-test metrics saved, destroyed the same day.
- [ ] One saved Infracost diff per cost lever, each with its monthly saving.
- [ ] Office-hours schedule stops and starts the service and database on a deployed `after/` (CLI output saved); `after/` destroyed the same day.
- [ ] Cost table in the README: before, each lever, after, after with the schedule, in dollars and percent.
- [ ] Savings Plans and a cheaper architecture option priced in the recommendation (not bought, not deployed).
- [ ] `case-study/cost-review.md`, its PDF and `case-study/TEMPLATE.md` written.
- [ ] Demo cost recorded (under $5), nothing left running, no secrets, state or account IDs committed.
- [ ] README has the scope, the cost table, how to rerun the comparison and a link to the case study.
