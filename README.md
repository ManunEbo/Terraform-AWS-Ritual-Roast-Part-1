<h1>Ritual Roast: Automated 3-Tier AWS Architecture</h1>
<h3>1. 🏞️ Background</h3>
<p>
Ritual Roast is a fictitious company embarking on an advertising campaign to engage with their customers<br>
by hosting a recipe competition where customers complete the online form with their recipe and contact details.<br>
The chefs will try the recipe and decide the winner to receive a prize.<br>
The company aims to build a mailing list from the emails for future campaigns.
</p>

<h3>2.💡 Project Evolution & Motivation</h3>
<p>
The project is based on the architectural  concepts from the <a href="https://www.udemy.com/course/aws-solutions-architect-capstone-projects/">AWS Solutions Architect SAA-C03 – Hands-On Projects</a> course on Udemy.<br>
The original course consists of manual infrastructure deployment via the AWS Management Console.<br>
This project converts that into a sophisticated Infrastructure as code (IAC) deployment using <strong>Terraform</strong>. 
In implementing this project I demonstrate my skills and ability to turn complex architectures<br>
into practical production worthy solutions.

<h3>3. 🗺️ High-Level Design (HLD)</h3>
<p>
The diagram below is the schematics for Ritual Roast, provided in the course.<br>
This along with the "Ritual Roast Resource Configuration.pdf" document provide the road map<br> for this Terraform implementation. I've also included the python script "ritual-roast.py" script, for completeness.
</p>
<img src="images/RR-HLD Architecture.png" alt="Architecture diagram provided by the IaaS Academy Udemy Course.">

<p>
The HLD illustrates the 3-Tier Architecture with the <b>DMZ</b> presentation Tier, <b>Web/App</b> Application Tier<br> and <b>Data</b> the Data Tier.<br>
The presentation Tier consists of a LoadBalancer that accept traffic from the internet and Loadbalances it to<br>
the Aplication Tier's Auto Scaling Group(ASG), highly available and resilient, EC2 instances in the Web/App<br> private subnets. The instances pull source codes from an S3 to build the application.
<br>The application processes packets and communicates to and fro with the Data tier.<br>

Communication between resources is enabled via security groups i.e. only resources with the right<br>
security group attached can communicate vice versa.<br>
Security is further enhanced by preventing exposure to the internet for resources in private subnets.<br>

The Data tier is home to the RDS MySQL database with Multi-AZ failover. The database credentials are stored<br> and rotated by Secrets Manager with the help of a lambda function which has a role to facilitate communication.<br>
There is a separate role to enable communication between the EC2 instances, the application, and the database.
</p>

<h3>4. 🌐 Networking</h3>

<p>
This project is deployed in <strong>"eu-west-2"</strong> region. With the exception of the S3 bucket "rr-capstone-${bucket-hex}" <br>all the resources used in this project are deployed under the Ritual Roast VPC, <strong>"ritual-roast-vpc"</strong>.<br>
Note, S3 buckets are global and unique.<br>
The configuration specification for this project can be found at <a href="./documents/Ritual Roast Resource Specs.pdf">Ritual Roast Resource Configuration</a>. A summary of this is presented under section<br>
 "6. Technical highlights". It sets out what values to use for each resource, where possible,<br>
 such as the VPC CIDR range <b>10.16.0.0/16</b> hence all the subnet CIDR blocks, subnet names<br>
 and availability zones for each Tier, in additions to other resource parameter settings.<br>


<h3>5. 🔒 Security</h3>
<p>
<b>Summary</b>: The security groups apply the principle of least privilege. They tightly restrict traffic<br>
(e.g., the DB only talks to the Web tier and Lambda secrets rotation function).<br>
EC2 instances sit in private subnets, only accessible via the ALB or Systems Manager<br>
(via the attached SSM IAM policy).<br>

Since all subnets are by default associated to the VPC default route table, to prevent exposing private resources <br>to the internet, a single route is created via NAT gateways placed in a public subnet that has an internet gateway(IGW) attached.<br>This essentially gives private resources an egress only communication with the outside.
</p>

```
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.rr_nat_gateway.id
  }
```

<p>
A separate route table is created for public resources to access the internet via the IGW.
</p>

```
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ritual-roast-igw.id
  }
```
<strong>Security Groups</strong>

<ul>Security groups restricts ingress and egress communication between resources using rules.
<li>
<b>LoadBalancer-SG</b><br>
<ol>
<li>ingress rule that accepts traffic from the internet on port 80</li>
<li>egress rule allowing traffic to the application tier<br> i.e. any resource attached to Web-App-SG security group</li>
<li>This allows the ALB to send traffic to the Flask application<br>served from the EC2 instances created by the ASG.</li>
</ol>
</li>

<li>
<b>Web-App-SG</b>
<ol>
<li>ingress rule that accepts traffic from <br>LoadBalancer-SG on port 5000</li>
<li>egress rule that allows communication to any protocol to any ip</li>
<li>Note these instances are on a private subnet using<br>NAT gateway for outbound communication to the internet <br>thus security is not compromised.
</li>
<li>Since security groups are stateful, it will redirect packets back to LoadBalancer-SG<br>
without explicitly defining an egress rule for that</li>
<li>The single egress rule, enables communication with Database-SG</li>
</ol>
</li>

<li>
<b>Database-SG</b>
<ol>
<li>ingress rule accepting traffic on port 3306 from Web-App-SG</li>
<li>ingress rule accepting traffic on port 3306 from Lambda-SG</li>
<li>Managed RDS instances do not initiate outbound connections<br>
so no need for egress rules.</li>
</ol>
</li>

<li>
<b>Lambda-SG</b>
<ol>
<li>ingress rule accepting traffic from Database-SG on port 3306</li>
<li>egress rule allowing tcp traffic to any destination on port 443.<br>
This allows the lambda function to communicate with Secrets Manager
</li>
<li>Since the lambda function is placed in private subnets and accesses<br>
the internet via the NAT gateway it cannot be reached from the outside.
</li>
</ol>
</li>

</ul>

<b>Secrets Manager</b>
Secrets Manager is preferred over other methods credential management<br>
for the following reasons:
<ul>
<li>
Minimizes human error from credential management entirely
</li>
<li>
Mitigates the dangers of storing credentials<br>
in static,plaintext that easily leak into source code or logs.
</li>
<li>
Heavily minimize the attack surface; by fetching the secret dynamically<br>
at runtime
</li>
<li>
Lambda function automatically rotate the password every 7 days<br>
drastically narrows the window of opportunity for an attacker to use a leaked key/password
</li>
<li>
Provides an audit trail via its native integration with AWS CloudTrail
</li>
</ul>


<b>Session Manager</b><br>
Session manager is preferred over SSH for the following reasons:

<ul>
<li>
<b>Zero Inbound Network Exposure</b>:
<ol>
<li>
SSH requires that the security group exposes port 22<br>
on a publicly accessible subnet<br>
Session manager removes the need for bastion hosts<br>
instances remain private
</li>
<li>Instances are no longer constant targets<br>
for brute-force attacks and network scanners</li>
<li>
Session Manager requires no open inbound ports<br>
just a HTTPS outbound tunnel from the instance to<br>
the Systems Manager control plane
</li>
</ol>
</li>

<li>
<b>Elimination of SSH Key Management</b>
<ol>
<li>No more sharing keys with other developers</li>
<li>No more forgetting to rotate keys</li>
<li>No security risk of compromised keys</li>
<li>With session manager, AWS IAM handles the authentication<br>
and authorization
</li>
</ol>
</li>

<li>
<b>Absolute Traceability & Tamper-Proof Logging</b>
<ol>
<li>
SSH does not natively log what a user actually types<br>
once they get into the server
</li>
<li>
If a malicious actor or a mistake takes down a database,<br>
tracing back who ran the specific command on a shared<br>
Linux user account is incredibly difficult
</li>
<li>
Session Manager provides a built-in, tamper-proof audit trail
</li>
<li>AWS records every single session</li>
<li>
It can be configured to stream and save <br>
every single keystroke and command output directly<br>
to an encrypted Amazon S3 bucket or AWS CloudWatch logs
</li>
<li>
This satisfies massive compliance frameworks<br>
(like SOC2 and PCI-DSS) out of the box
</li>
</ol>
</li>

<li>
<b>Native Multi-Factor Authentication (MFA)</b>
<ol>
<li>
Setting up MFA for standard Linux SSH usually requires complex,<br>
manual configurations with third-party PAM (Pluggable Authentication Modules) or complex bastion setups.
</li>
<li>
Since authentication is enabled via IAM<br>
we can make use of existing IAM or corporate identity provider policies
</li>
<li>Additional security measures can be enforced via MFA<br>
for authentication</li>
</ol>
</li>

</ul>


<h1>6. 🚀 Technical Highlights</h1>

<h2>VPC and Subnetting</h2>
Ritual Roast requires 16 subnets or sub networks from the VPC CIDR <strong>(10.16.0.0/16)<strong><br> 
This can be achieved by borrowing from the host bits. The table below shows the derivation of the subnets.<br>
</p>

<table style="width:100%">
  <tr>
    <th>n bits</th>
    <th>n networks</th>
    <th>New CIDR</th>
    <th>New n host IP</th>
  </tr>
  <tr>
    <td>1</td>
    <td>2^1 = 2</td>
    <td>/17</td>
    <td>2^(32-17) = 2^15 = 32768</td>
  </tr>
  <tr>
    <td>2</td>
    <td>2^2 = 4</td>
    <td>/18</td>
    <td>2^(32-18) = 2^14 = 16384</td>
  </tr>
    <tr>
    <td>3</td>
    <td>2^3 = 8</td>
    <td>/19</td>
    <td>2^(32-19) = 2^13 = 8192</td>
  </tr>
    <tr>
    <td>4</td>
    <td>2^4 = 16</td>
    <td>/20</td>
    <td>2^(32-20) = 2^12 = 4096</td>
  </tr>
    <tr>
    <td>5</td>
    <td>2^5 = 32</td>
    <td>/21</td>
    <td>2^(32-21) = 2^11 = 2048</td>
  </tr>
    <tr>
    <td>6</td>
    <td>2^6 = 64</td>
    <td>/22</td>
    <td>2^(32-22) = 2^10 = 1024</td>
  </tr>
    <tr>
    <td>7</td>
    <td>2^7 = 128</td>
    <td>/23</td>
    <td>2^(32-23) = 2^09 = 512</td>
  </tr>
</table>
<br>

<p>
Of the 16 subnets required by Ritual Roast, 4 are reserved for possible future AZ in <b>eu-west-2</b><br>
The remaining 12 subnets are broken down into 4 groups:
</p>

<table style="width:100%">
  <tr>
    <th>Public subnets</th>
    <th>Web subnets</th>
    <th>App subnets</th>
    <th>Data subnets</th>
  </tr>
  <tr>
    <td>10.16.0.0/20</td>
    <td>10.16.64.0/20</td>
    <td>10.16.128.0/20</td>
    <td>10.16.192.0/20</td>
  </tr>
  <tr>
    <td>10.16.16.0/20</td>
    <td>10.16.80.0/20</td>
    <td>10.16.144.0/20</td>
    <td>10.16.208.0/20</td>
  </tr>
    <tr>
    <td>10.16.32.0/20</td>
    <td>10.16.96.0/20</td>
    <td>10.16.160.0/20</td>
    <td>10.16.224.0/20</td>
  </tr>>
</table>

<p>
To see the actual names allocated to each of the subnet, please refer to <a href="./documents/Ritual Roast Resource Configuration.pdf">Ritual Roast Resource Configuration</a><br>
Note, in every subnet, there are 5 IP addresses that are reserved thus cannot be used:
<ul>
<li><b>10.16.0.0:</b> Network address</li>
<li><b>10.16.0.1:</b> Reserved by AWS for the VPC Router</li>
<li><b>10.16.0.2:</b> Reserved by AWS for the DNS server</li>
<li><b>10.16.0.3:</b> Reserved by AWS for future use</li>
<li><b>10.16.15.255:</b> Network broadcast address</li>
</ul>

Elastic IPs will be allocated for the NAT gateway and released when the project is destroyed.<br>
With respect to Terraform, the creation of the VPC and Subnets are handled in <a href="./networking.tf">networking.tf</a>.<br>Both the NAT gateway and the IGW creation are handled in <a href="./gateways.tf">gateways.tf<a>

</p>




-> ASG

        -> 
<h2>AutoScaling Group (ASG)</h2>
<p>
ASG bridges the gap between static infrastructure and dynamic, self-healing architecture.<br>

The use of 3 separate subnets in 3 different AZs ensures high availability within the region.<br>
i.e. if one AZ goes down, we still have 2 available.<br>
</p>
#### Then come here ####
<h3>Launch template - Userdata</h3>
      -> systemd service
      -> mysql client





<h3>Updating Launch template</h3>

<p>
Updating the Launch template will lead to AWS throwing an error regarding the ASG<br>
below are the steps that lead to this error:
</p>

<ol>
<li>In AWS the name of the ASG is it's unique identifier</li>
<li>AWS does not allow two ASGs to exist with the same name<br>
simultaneously.
</li>
<li>AWS also does not allow the renaming of an ASG once created<br>
i.e. it's an immutable property
</li>

</ol>
<br>
The problem: Terraform's default behaviour<br>
Lets assume we don't change ASG name while updating the Launch template<br>
Terraform will try to do this in the following order
<ol>
<li>Terraform sees Launch template changed</li>
<li>To prevent application down time</li>
<li>It attempts to create the <b>new</b> ASG with the <b>new</b> template<br>
before destroying the old ASG
</li>
<li>AWS throws an error:<br>
<i><b>"AutoScalingGroup with name 'rr-asg' already exists."</b></i>
</li>
<li>Forcing Terraform to delete the old one first using<br>
<i><b>"lifecycle { create_before_destroy = false }"</b></i><br>
Would create a different problem.
</li>
<li>AWS takes several minutes to drain traffic from an instance<br>
and delete an ASG</li>
<li>Terraform would time out waiting for the old ASG to be deleted<br>
so that it can use the name to create the new one
</li>

</ol>

<br>
The solution:
We bypass the above problems by injecting some random hex characters into the ASG name
using the latest launch template version:
<br>
</p>

```
${aws_launch_template.rr_launch_template.latest_version}-${random_id.asg_suffix.hex}

name = "rr-asg-${aws_launch_template.rr_launch_template.latest_version}-${random_id.asg_suffix.hex}"
```
<p>
This is a strategy called "Immutable Infrastructure" i.e. replacing resources entirely instead<br>
of modifying them in place.

Now when we run:
</p>

```
$ tf apply -auto-approve
```

<p>
The following happens:

<ol>
<li>
Terraform sees the version in the name string changed<br>
from <b>"v1-abcd"</b> to <b>"v2-abcd"</b><br>
<i>Note, these are example random hex values that would be used</i>
</li>
<li>It creates a brand new ASG named <b>"rr-asg-2-abcd"</b>
side by side with the old ASG
</li>
<li>For a brief moment both sets of instances will be running</li>
<li>Then the ALB will start sending traffic to the new ASG</li>
<li>Once the new instances are healthy<br>
Terraform safely deletes the old ASG <b>rr-asg-1-abcd</b><br>
and it's instances
</li>
<li>This is essentially a Blue/Green style deployment</li>
<li>Ultimately, the end user experiences zero downtime</li>

</ol>

</p>


<h3>Target tracking configuration</h3>

<p>
Target tracking allows the infrastructure to smooth out spikes in traffic without over-provisioning<br>
and wasting money. This process is facilitated by communication between ALB, CloudWatch and ASG.<br>
Setting the target tracking to 50.0 is the middle ground, perhaps not optimal.<br>
However, for the purpose of this demonstration, it is satisfactory.<br>
</p>

```
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0

    disable_scale_in = false
  }
```
<p>
When traffic increases, the following happen:<br>

<ol>
<li>
The ALB receives increased traffic and<br>
distributes between the two instances<br>
using Round-Robin algorithm
</li>
<li>
CPU spikes above the threshold of 50%, averaged across the two instances<br>
lets say it reaches 80%
</li>
<li>
The CloudWatch alarm is triggered and the ASG is notified<br>
of the high CPU utilization across the two instances
</li>
<li>
ASG spins up an extra instance or two based on the Launch template<br>
up to the defined maximum, 4 in this case.
</li>
<li>
Instance(s) prepare to receive traffic in the warm up period<br>
3 minutes in this case. Here the instance runs the <b>user_data</b> script.<br>
This is where the packages are installed<br>
and the application tests connection to the database.
</li>
<li>
After the 3 minutes, the instance(s) are ready to receive traffic.<br>
The ALB registers the new instances and starts sending them traffic.<br>
The distribution of the traffic between the instances reduces the<br>
"Average CPU Utilization" down towards the target 50%
</li>
</ol>

<br>
When traffic drops, the following happen:

<ol>
<li>
The ALB receives few traffic and the CPU<br>
utilization drops significantly below the threshold
</li>
<li>
This triggers a "Low CPU Alarm" in CloudWatch<br>
and CloudWatch notifies the ASG
</li>
<li>
This setting "<b>disable_scale_in = false</b>" enables the ASG<br>
to reduce the number of instances, scale in.<br>
The ASG selects an instance to terminate
</li>
<li>
The process of connection draining starts before the ASG terminates the instance<br>
The ALB stops sending new traffic to the instance and the instance is allowed to finish<br>
any requests it is currently processing before termination.
</li>
<li>When the draining is complete the ASG terminates the instance<br>

</li>
<li></li>
</ol>
<br>
Although this makes the infrastructure dynamic and flexible to handle demand more effectively<br>
the warm up period of 3 minutes is a barrier which does impact on the availability of services,<br>
when it's really needed. There are alternatives, <b>not discussed here</b>, that reduce warm up period<br>
significantly such as containerization with ECS or Fargate. This will drop the warmup time from 3 minutes to<br>
10-15 seconds.
</p>

<h3>Including a "depends_on" parameter:</h3>

```
  depends_on = [
    aws_secretsmanager_secret_version.db_host_update,
    aws_db_instance.ritual_roast_db
  ]
```

<p>
specifies the order in which resources will be created. 

<ol>
<li>This ensures that the database is created first</li>
<li>
Once the database is created, the secret storing database credentials is updated<br>
with the database host information<br>
<b>"host     = aws_db_instance.ritual_roast_db.address"</b>
</li>
<li>The ASG then launches instances that use the host information<br>
to connect to the database
</li>
</ol>

Without the above sequence<br>

<ol>
<li>Terraform would create ASG and RDS instances in parralel<br>
to save time.
</li>
<li>AWS RDS takes 5 to 13 minutes to fully provision</li>
<li>While the ASG will spin up EC2 instances in a few minutes</li>
<li>The instances will attempt to connect to the database<br>
with incorrect host value i.e. the "PLACEHOLDER"
</li>
<li>The database is unvailable as its still provisioning</li>
<li>The Application crashes and triggers an exit<br>
<b>"sys.exit(1)</b>
</li>
<li>Systemd waits 5 seconds and restarts the application service<br>
and it crashes again
</li>
<li>The ALB checks the /health endpoint of the instances</li>
<li>since the application keeps crashing, the health checks fails.</li>
<li>Since the ASG is using ALB health metrics<br>
The ALB will tell the ASG that the instances are unhealthy
</li>
<li>The ASG would then terminate those instances and recreate new ones<br>
which would also fail their health checks
</li>
<li>This loop would go on until the RDS instance is ready to receive traffic
</li>
<li>A very expensive process</li>

</ol>






</p>

-> S3
    -> python scrip for flask app
    -> Remote backend and state lock

-> Roles

-> Lambda function

-> Secret manager / Chicken and egg problem

-> RDS
    -> Multi-AZ failover







<h3>7. 🛠️ Tech Stack</h3>

Make a table of this:

| Category | Tools |
| :--- | :--- |
| **Cloud Provider** | AWS (EC2, RDS, ALB, ASG, Lambda, Secrets Manager, S3) |
| **IaC** | Terraform (v1.7+) |
| **Language** | Python 3.9 (Flask Framework) |
| **Database** | MySQL 8.x |
| **OS** | Amazon Linux 2023 







<h3>8. 📖 Deployment Instructions</h3>









<h3>9. 🛡️ Disclaimer</h3>

<p>
*The application logic and frontend design are inspired by
 the Ritual Roast project in the Udemy course mentioned above.
 All infrastructure code, automation scripts,
 and secret rotation logic were independently developed by me
 with the help of Gemini 3
</p>