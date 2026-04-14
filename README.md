<h1>Ritual Roast: Automated 3-Tier AWS Architecture</h1>
<h1>1. 🏞️ Background</h1>
<p>
Ritual Roast is a fictitious company embarking on an advertising campaign to engage with their customers<br>
by hosting a recipe competition where customers complete the online form with their recipe and contact details.<br>
The chefs will try the recipe and decide the winner to receive a prize.<br>
The company aims to build a mailing list from the emails for future campaigns.
</p>

<h1>2.💡 Project Evolution & Motivation</h1>
<p>
The project is based on the architectural  concepts from the <a href="https://www.udemy.com/course/aws-solutions-architect-capstone-projects/">AWS Solutions Architect SAA-C03 – Hands-On Projects</a> course on Udemy.<br>
The original course consists of manual infrastructure deployment via the AWS Management Console.<br>
This project converts that into a sophisticated Infrastructure as code (IAC) deployment using <strong>Terraform</strong>. 
In implementing this project I demonstrate my skills and ability to turn complex architectures<br>
into practical production worthy solutions.

<h1>3. 🗺️ High-Level Design (HLD)</h1>
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

<h1>4. 🌐 Networking</h1>

<p>
This project is deployed in <strong>"eu-west-2"</strong> region. With the exception of the S3 bucket "rr-capstone-${bucket-hex}" <br>all the resources used in this project are deployed under the Ritual Roast VPC, <strong>"ritual-roast-vpc"</strong>.<br>
Note, S3 buckets are global and unique.<br>
The configuration specification for this project can be found at <a href="./documents/Ritual Roast Resource Specs.pdf">Ritual Roast Resource Configuration</a>. A summary of this is presented under section<br>
 "6. Technical highlights". It sets out what values to use for each resource, where possible,<br>
 such as the VPC CIDR range <b>10.16.0.0/16</b> hence all the subnet CIDR blocks, subnet names<br>
 and availability zones for each Tier, in additions to other resource parameter settings.<br>


<h1>5. 🔒 Security</h1>
<p>
<b>Summary</b>: The security groups apply the principle of least privilege. They tightly restrict traffic<br>
(e.g., the DB only talks to the Web tier and Lambda secrets rotation function).<br>
EC2 instances sit in private subnets, only accessible via the ALB or Systems Manager<br>
(via the attached SSM IAM policy).<br>

Since all subnets are by default associated to the VPC default route table, to prevent exposing private resources <br>to the internet, a single route is created via NAT gateways placed in a public subnet that has an internet gateway(IGW) attached.<br>This essentially gives private resources an egress only communication with the outside.
</p>

<code>
<pre>
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.rr_nat_gateway.id
  }
</code>
</pre>

<p>
A separate route table is created for public resources to access the internet via the IGW.
</p>

<code>
<pre>
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ritual-roast-igw.id
  }
</code>
</pre>

<h2>Security Groups</h2>

<ul>Security groups restricts ingress and egress communication between resources using rules.
<li>
<h3>LoadBalancer-SG</h3>
<ol>
<li>ingress rule that accepts traffic from the internet on port 80</li>
<li>egress rule allowing traffic to the application tier<br> i.e. any resource attached to Web-App-SG security group</li>
<li>This allows the ALB to send traffic to the Flask application<br>served from the EC2 instances created by the ASG.</li>
</ol>
</li>

<li>
<h3>Web-App-SG</h3>
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
<h3>Database-SG</h3>
<ol>
<li>ingress rule accepting traffic on port 3306 from Web-App-SG</li>
<li>ingress rule accepting traffic on port 3306 from Lambda-SG</li>
<li>Managed RDS instances do not initiate outbound connections<br>
so no need for egress rules.</li>
</ol>
</li>

<li>
<h3>Lambda-SG</h3>
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

<h2>Secrets Manager</h2>
<p>
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
</p>

<h3>Session Manager</h3>
<p>
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
</p>

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

<h2>AutoScaling Group (ASG)</h2>
<p>
ASG bridges the gap between static infrastructure and dynamic, self-healing architecture.<br>
The use of 3 separate subnets in 3 different AZs ensures high availability within the region.<br>
i.e. if one AZ goes down, we still have 2 available.<br>
</p>

<h3>Launch template - Userdata</h3>

<p>
The original userdata script from the course had a few issues that needed attention:
<ol>
<li>
The command to run ritual-roast.py looked like:<br>
<code>nohup python3 ritual-roast.py > /var/log/flask-app.log 2>&1 &</code><br>
This just ensures that the command runs, in the background,<br>
even if the shell is terminated and that it redirects errors to<br>
standard out which is then sent to <b>/var/log/flask-app.log</b>
</li>
<li>If the App crashes, this would not restart it</li>
<li>Registering the application as a service with systemd service<br>
enables Linux to restart the service if it crashes.
</li>
<li>
Using the <b>exec</b> command captures the entire scripts output<br>
like a blackbox flight recorder<br>

<pre>
<code>
  exec > /var/log/user-data.log 2>&1
</code>
</pre>

not just the output of running the python script, as in the original.
</li>
<li>
This is useful because <b>AWS user data runs completely in the background<br>
and if the script fails, it fails silently, no output</b><br>
Putting the exec command at the top of the output means we're collecting<br>
all the output, including errors, and redirecting them to a file.
</li>

<li>
Downloading the AWS global-bundle.pem ensures that communication with the database<br>
are secured via ssl. In additions adding the <b>-sS --fail -O</b> options ensure that<br>
strict certificate checking is performed and that the script <b>hard-fails</b> if the secure<br>
connection can't be verified.
</li>

<li>
Ensuring root owns the certificate and readonly access for others<br>
enhances security i.e. if the ec2-user owns the certificate a breach of security<br>
would give a bad actor ec2-user permissions enabling them to swap the valid<br>
certificate with a malicious copy.
</li>

<li>
However, no checksum of the certificate file is carried out here.<br>
A SHA256 Checksum would be a security enhancement to ensure that<br>
the certificate has not been tampered with.
</li>

<li>
The use of an isolated Python virtual environment prevents dependency conflict<br>
between the application and the operating system native tools.
</li>

</ol>
</p>

<h3>Updating Launch template</h3>

<p>
Updating the Launch template will lead to AWS throwing an error regarding the ASG.<br>
Below are the steps that lead to this error:
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

<code>
<pre>
  ${aws_launch_template.rr_launch_template.latest_version}-${random_id.asg_suffix.hex}

  name = "rr-asg-${aws_launch_template.rr_launch_template.latest_version}-${random_id.asg_suffix.hex}"
</code>
</pre>
<p>
This is a strategy called "Immutable Infrastructure" i.e. replacing resources entirely instead<br>
of modifying them in place.

Now when we run:
<code>
<pre>
  tf apply -auto-approve
</code>
</pre>

</p>
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

<code>
<pre>
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0

    disable_scale_in = false
  }
</code>
</pre>

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

<code>
<pre>
  depends_on = [
    aws_secretsmanager_secret_version.db_host_update,
    aws_db_instance.ritual_roast_db
  ]
</code>
</pre>

<p>
specifies the order in which resources will be created. 

<ol>
<li>This ensures that the database is created first</li>
<li>
Once the database is created, the secret storing database credentials is updated<br>
with the database host information<br>

<pre>
<code>
  "host     = aws_db_instance.ritual_roast_db.address"
</code>
</pre>

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

<h2>S3 remote bucket</h2>
<p>
Using a separate Terraform deployment, an S3 bucket was created to act as the Ritual Roast central repository.<br>
This S3 is used as the repository for the application code; the backend for the Terraform state file<br>
and the state lock file; it also houses the index.zip script for the lambda function to rotate secrets.<br>
The bucket has versioning enabled facilitating the flexibility to roll back faulty configuration changes/updates.
</p>

<h3>Application repository</h3>

<p>
The source code for the flask application is bundled up and uploaded to this bucket. This decouples the source<br>
code from the project infrastructure enabling greater flexibility for pushing changes.<br>
All instances created by the ASG will pull code from this bucket. This means all the instances will have the<br> latest code, at the point of creation. Thus identical, with the exception of new updates.<br>
To refresh the instances so they have the latest updates we can run the following on aws cli:
</p>

<code>
<pre>
  aws autoscaling start-instance-refresh \
      --auto-scaling-group-name rr_autoscaling_group \
      --preferences '{"MinHealthyPercentage": 50}'
</code>
</pre>

<p>
The aws cli is used above instead of Terraform because no changes have been made to the ASG or Launch template
meaning "tf plan" will show no changes to be made. However, forcing an instance refresh will destroy and replace the instances one by one pulling the freshly updated source code in the process.
Note, the instances use roles with s3 bucket access policy to sync with s3, at boot.
</p>

<h3>Flask App (ritual-roast.py)</h3>
<p>
This single script, <a href="./documents/ritual-roast.py">ritual-roast.py</a> is the infrastructure aware central nervous system of the project. It is the intersection betweeen the python backend and the Flask frontend web server.

It does the following:
<ol>
<li>
The <b>template_folder</b> is where Flask looks for <b>index.html</b>, the entry point
</li>

<li>
The <b>static_folder</b> is where the .css, .js and the images are found
This stylizes and animates the website 
</li>

<li>
The <b>CORS</b> (Cross Origin Resourse Sharing) here tells the browser.
This is an open API. However, in production the domain name would be used in place of "*"
<pre>
<code>
CORS(app, resources={r"/*": {"origins": "*"}})
</code>
</pre>
But here it assists the ALB by preventing the browser muting the API response.
</li>

<li>
The script interacts with AWS via boto3 to pull DB credentials from Secrets Manager
</li>

<li>
These credentials are then used in conjuction with an ssl certificate to encrypt and securely connect to the DB in a <b>Zero Trust</b> fashion i.e. we assume a breach even in a private VPC so we lock down everything.
</li>

<li>
The DB connection function completes with a create table query, if the table does not yet exist. 
</li>

<li>
<b>The script has several functions to perform specific tasks with the database</b>
</li>

<li>
The <b>get_recipes</b> function retrieves the recipes from the database
</li>

<li>
The <b>add_recipe</b> function sends a new recipe to the database
</li>

<li>
The <b>health_check</b> function is the liveness probe that the ALB sends HTTP get requests to ensure that the EC2 instance is healthy i.e. when the ALB probes <b>/health</b> the EC2 instance runs this function and sends the response back to the ALB.
</li>

<li>
The <b>serve</b> function is the traffic controller linking the incoming URL request (the path) to the physical file on the webserver. <b>If the path exists</b>, it delivers the contents else it returns what ever is setup for the 404 NOT FOUND.
</li>

<li>
Finally, the `__main__` block acts as a startup gatekeeper. It forces the app to verify the database connection before it tries to host the website. If the database is missing, the script kills itself on purpose with a `sys.exit(1)`. This is a deliberate "Fail-Fast" move: it prevents the server from sitting there broken and tells the OS (Systemd) to keep rebooting the app until the database finally wakes up.
</li>
</ol>
</p>

<h3>Terraform backend</h3>
<p>
The terraform state file `tf.state` is essentially a copy of the current configuration of our resources managed by this terraform project. The state file should be stored remotely to facilitate collaboration. The remote location(backend) should be secure and encrypted yet accessible to all collaborators with the right security credentials.
In this project an S3 bucket is used as the remote backend.

Once all collaborators have access to the bucket, it is necessary to prevent multiple collaborators pushing changes simultaneously, which would overwrite the previous change without notice. To avoid this, a state lock file is used, `use_lockfile = true`. This ensures that only a single collaborator can apply/push configuration changes to our infrastructure at a time. While they make those changes the state file is locked and others are prevented from doing so. When they finish, the state lock is released enabling others to see the changes by running `terraform plan` and to push their changes to the project with `terraform apply`.
The backend configuration loooks like:
<pre><code>
  backend "s3" {
    bucket       = "rr-capstone-5b160b287a99a6d9"
    key          = "state/terraform.tfstate"
    region       = "eu-west-2"
    encrypt      = true
    use_lockfile = true
  }
</code></pre>

With respect to the providers and version constrains, the following is used:
<ul>
<li>
<b>Required Version (1.14.3)</b>: This strictly pins the Terraform CLI version preventing "Version Drift", where a team member using a newer or older version of Terraform might introduce syntax that is incompatible with the rest of the team.
</li>

<li>
<b>AWS Provider (~> 6.38.0)</b>: The pessimistic constraint operator (~>) allows Terraform to pull in minor updates and security patches for the AWS provider while blocking major version jumps that could introduce breaking changes to resources like RDS or EC2.
</li>
</ul>
</p>

<h2>AWS Lambda for rotaing secrets Python code</h2>

<p>
This script breaks down the secrets rotation process into functions that perform specific tasks:
<ul>
<li>`createSecret`, Generate a new password</li>
<li>`setSecret`, Change the password on the database</li>
<li>`testSecret`, test connection using new password</li>
<li>`finishSecret`, update the secret credentials to the new password</li>
</ul>
The various components are then invoked as per usecase via the handler function, the switchboard.

Below are brief summaries of each component:

<ol>
<li>
<b>Python Logging module</b> links the lambda function to CloudWatch Logs i.e. this sends metrics, error logs in this case, that aids debugging failures. Note, the log level has been set to `INFO` which reports general,
no debugging noise, outputs and errors. `logger = logging.getLogger()` and `logger.setLevel(logging.INFO)`
</li>


<li>
`generate_random_password`: This function generates a new 16 character  strong password that will replace the current secret.
</li>

<li>
`get_secret_dict`: This function retrieves and parses the secret in json format ready to be consumed by<br>
other functions. The use of token identifies and locks in the specific version of the secret `VersionId`<br>
for the tasks at hand. In additions, `VersionStage` allows the lambda function to work with both the old<br>
`AWSCURRENT` and the new `AWSPENDING` passwords i.e. to change the password, lambda needs to first<br>
authenticate using the current password and then reset the password to the new one.
</li>

<li>
`create_secret`: This function performs the following:
<ul>
<li>Retrieves the secret, in json format dictionary, with `VersionStages` set as `AWSCURRENT`</li>
<li>Invokes the `generate_random_password` function to create a new password</li>
<li>Replacing the <b>dictionary's</b> `AWSCURRENT` password inplace</li>
<li>
Pushes the change back to Secrets Manager<br>
tagging it with `VersionStages` equal to `AWSPENDING`
</li>
<li>
This ensures that we don't overwrite the current password<br>
by mistake before the change over.
</li>
<li>
The push is ignored if a secret with `VersionStages` equal to `AWSPENDING`<br>
already exists. 
</li>
</ul>
</li>

<li>
`set_secret`: This function is the only point of contact with the database.<br>
It performs the following tasks:<br>
<ol>
<li>Retrieves both the current password `AWSCURRENT`<br>
and the new password `AWSPENDING` </li>
<li>Connects to the database using the current password</li>
<li>
Executes an `ALTER USER` command to change the password<br>
to the new password.<br>

<pre>
<code>
  with conn.cursor() as cursor:
      # Execute SQL to change the password inside the database engine
      cursor.execute(f"ALTER USER '{username}'@'%' IDENTIFIED BY '{new_password}';")
  conn.commit()
  conn.close()
</code>
</pre>

</li>
<li>Then commits the change and closes the connection</li>
<li>
If something goes wrong, the error is handled with the exception<br>
which logs the error.<br>

<pre>
<code>
 except Exception as e:
        logger.error(f"Failed to update database password: {e}")
        raise 
</code>
</pre>

</li>

</ol>
</li>

<li>
`test_secret`: This function proves that the password update was a success.<br>
It performs the following tasks:
<ol>
<li>
Tests connection to the database with the newly updated password.<br>
That's the password labeled as `AWSPENDING`
</li>
<li>If the connection is successful it closes the connection.</li>
<li>
If it errors out, it logs the error before the raised exception terminates the execution<br>
and reports the failure to CloudWatch, essentially slamming the emergency breaks on and<br>
sounding the alarm.

<pre><code>
except Exception as e:
    logger.error(f"Failed to update database password: {e}")
    raise 
</code></pre>
</li>


</ol>
</li>

<li>
`finish_secret`: This function updates the secret in Secrets Manager.<br>
It performs the following tasks:<br>
<ol>
<li>Retrieves the secret from Secrets Manager</li>

<li>
Verifies that the secret hasn't already been updated (swapped)<br>
by checking that the version id of `AWSCURRENT` doesn't match the token,<br>
the id on `AWSPENDING` password, if it does then it skip this step and exits.
</li>

<li>
If the secret hasn't been swapped yet then remove the version id from `current_version`<br>
and move the version id to ``token` which would update the value held in<br>
`AWSCURRENT` to the value in `AWSPENDING`.<br>
This is called an "atomic swap".
</li>
</ol>
</li>

<li>
`lambda_handler`: This function is the central nervous system of the operation,<br>
responsible for managing the secrets lifecycle from start to finish.<br>
It performs the following tasks:
<ol>
<li>
Secret manager invokes this function, passing to it two arguments:
<ol>
<li>
<b>event</b>: A dictionary containing 4 key values:<br>
SecretId, ClientRequestToken, Step, and RotationToken<br>
Note, the step is the current phase of the rotation<br>
one of; `createSecret`, `setSecret`, `testSecret`, or `finishSecret`
</li>

<li>
<b>context</b>: This provides metadata regarding the execution environment<br>
such as `aws_request_id`.
</li>
</ol>
</li>

<li>
The function extracts the key values from the event into variables<br>
for later use.
</li>
<li>
The function verifies that the rotation is enabled `RotationEnabled` by retrieving<br>
the metadata with `describe_secret`.<br>
Note, if rotation is <b>not</b> enabled, the error is logged, and this will raise<br>
a `ValueError` which terminates the execution and reports a failure metric to CloudWatch.
</li>
<li>
Once `RotationEnabled` is verified execution of the rotation functions begin,<br>
conditional on the phase, `step` value, retrieved from the event.
</li>

<li>
Thus Secrets Manager invokes this function 4 times each time with a different value<br>
for phase.
</li>
<li>
If an invalid value is passed into `step` then the error is logged and a `ValueError` is raised.<br>
once again terminating the execution and reporting the failure to CloudWatch.
</li>

</ol>
</li>

</ol>

</p>


<h3>Terraform remote backend</h3>
    -> Remote backend and state file and state lock

<p>
State Management Modernization: > This project leverages Native S3 State Locking (introduced in Terraform 1.10+). By setting use_lockfile = true, we eliminate the need for a separate DynamoDB table, reducing architectural complexity and cost while maintaining full protection against concurrent state modifications.
</p>

<h2>IAM Roles</h2>
<h3>Lambda secrets rotation role `lambda_secrets_role`</h3>

<p>
The role is an aggregation of permissions that allow the function to communicate with AWS services for<br>
the successfull execution of secrets rotation. The lambda function assumes the role when it is invoked by<br>
Secrets Manager.<br>

<pre>
<code>
resource "aws_iam_role" "lambda_secrets_role" {
  name = "lambda_secrets_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Effect = "Allow"
      Sid    = ""
    }]
  })

  tags = merge(local.common_tags, {
    Name = "lambda_secrets_role"
  })
}
</code>
</pre>

Following the principle of least privileges, the following permissions are attached to the role:<br>

<ul>
<li>
`lambda_vpc_access`: This policy attachment pulls in an AWS managed policy `AWSLambdaVPCAccessExecutionRole`<br>

<pre>
<code>
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
</code>
</pre>

which facilitates a number of actions required for the lambda function:<br>
<ol>

<li>
`ec2:CreateNetworkInterface`: Allows the lambda function to create <b>Elastic Network Interfaces(ENI)</b><br>
inside the private subnets. This is how it is able to find and communicate with the database i.e. it gives<br>
the lambda function footing in the database subnets. Note the lambda function can reside in another subnet<br> that has access to the database subnets.
</li>

<li>
<b>View Network Topology</b>: a combination of these actions; `ec2:DescribeNetworkInterfaces`, `ec2:DescribeSubnets`,`ec2:DescribeSecurityGroups`, allow the lambda function to look around the network <br>
essentially finding it's path to the database.
</li>

<li>
`ec2:DeleteNetworkInterface`: Because lambda functions are ephemeral, when it has completed the rotation tasks <br> it needs to delete the <b>ENIs</b> that were created to eliminate left over/orphaned resources costs.

</li>

</ol>
</li>

<li>
  `lambda_basic_execution`: This policy attachment allows the Lambda function to <b>tell its story</b>. 
  It pulls in the AWS managed policy <code>AWSLambdaBasicExecutionRole</code>:
  <pre><code>
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  </code></pre>
  This facilitates the communication between the Lambda and <b>AWS CloudWatch</b> via the following actions:

  <ol>
    <li>
      <strong><code>logs:CreateLogGroup</code></strong>: On the very first run, this allows the Lambda to create a "folder" in CloudWatch (the <b>Log Group</b>). This is the dedicated space where all future logs for this function will live.
    </li>
    <li>
      <strong><code>logs:CreateLogStream</code></strong>: This allows the Lambda to create individual "files" (<b>Log Streams</b>) for every separate execution. This is good housekeeping; it ensures that logs from different rotation attempts don't get jumbled together, making debugging much easier.
    </li>
    <li>
      <strong><code>logs:PutLogEvents</code></strong>: This is the action that actually "writes" to the file. It allows the <code>logger.info()</code> and <code>logger.error()</code> messages from the Python script to be posted into CloudWatch so you can actually read the "emergency alarm" if something goes wrong.
    </li>
  </ol>
</li>

<li>
<strong><code>rr_lambda_secrets_custom_policy</code></strong>: This is a surgical, "Least Privilege" userdefined  policy that gives the Lambda function the exact tools it needs to rotate credentials without exposing the rest of the AWS account. These tools are the actions that can be performed on restricted secrets resources that match this prefix `secret:rr-db-secret-*` in the name.
<pre> 
<code>
        Resource = "arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.current.account_id}:secret:rr-db-secret-*"
</code>
</pre>

The actions include:
<ul>
<li>`secretsmanager:GetSecretValue`: Retrieves the current "locked" credentials.</li>
<li>`secretsmanager:DescribeSecret`: Obtains metadata (e.g., rotation status) to ensure the logic is in sync.</li>
<li>`secretsmanager:PutSecretValue`: Allows lambda to create a new secret/password</li>
<li>`secretsmanager:UpdateSecret`: Allows lambda to update the secret value</li>
</ul>

The policy also permits the role to send metrics to AWS CloudWatch. Note, this is for numerical data that is used
in Dashboards and graphs. This is accomplished using the following action:
<ul>
<li>`cloudwatch:PutMetricData`: Allows lambda to write numerical data to CloudWatch Metrics</li>
</ul>
</li>
</ul>
</p>

<p>
In additions to the role policies, we have a resource based policy <strong><code>aws_lambda_permission</code></strong> that is attached directly to the lambda function. This permission tells the lambda who can communicate with it i.e. this is what enables Secrets Manager to invoke the lambda function.
<pre>
<code>
resource "aws_lambda_permission" "rr_allow_secretsmanager_to_call_lambda" {
  statement_id  = "AllowExecutionFromSecretsManager"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.secret_rotation_function.function_name
  principal     = "secretsmanager.amazonaws.com"
}
</code>
</pre>
</p>

<h3>EC2 access to S3 and secrets role `rr_ec2_s3_secret_role`</h3>

<p>
This role enables the EC2 instances created by the ASG to securely perform the following tasks:

<ol>
<li>Communicate with S3 to pull assets and configurations. Note this policy specifies explicitly which bucket this applies to
<pre><code>
        Resource = [
          "${data.aws_s3_bucket.RR-bucket.arn}",
          "${data.aws_s3_bucket.RR-bucket.arn}/*"
        ]
</code></pre>
</li>
<li>Communicate with Secrets Manager to retrieve database credentials. Note, it's also explicitly specified which secret this applies to:
<pre><code>
        Resource = "${aws_secretsmanager_secret.db_secret.arn}"
</code></pre>

Using the resource ARN makes the secret retrieval flexible to changes in secrets version as the secrets rotate
i.e. instead of being locked into one version, which would break the application, the application automatically consumes the latest version.
</li>
<li>Communicate with AWS Systems Manager (SSM)</li>
</ol>

The communication with S3 and Secrets Manager are enabled by the `rr_ec2_s3_secret_policy` policy actions.
Here is a breakdown of these actions:
<ol>

<li>
`s3:GetObject`: Allow instances to retrieve objects from S3.
</li>

<li>
`s3:ListBucket`: Allows the instances to see the contents of the S3 bucket.
</li>

<li>
`secretsmanager:GetSecretValue`: Allows the instances to retrieve the secrets value i.e. the DB credentials
from Secrets Manager.
</li>
</ol>

The communication with <b>SSM</b> is enabled by attaching `AmazonSSMManagedInstanceCore` policy to the role.
This essentially achieves the following:
<ol>
<li>
Enable remote access to private instances without using SSH i.e. the instances no longer need to be publicly accessible
</li>

<li>
Thus no need for port 22 i.e. since the SSM agent initiates a secure outbound connection to AWS, the instance remains unreachable from the public internet, drastically reducing the attack surface.
</li>

<li>
No need for Bastion hosts to play the middle man facilitating access to private subnets i.e. now we have secure direct access to the private instances.
</li>

<li>
Audit Trail: Every command typed in an SSM session can be logged to CloudWatch or S3. Standard SSH doesn't have this kind of monitoring visibility.
</li>
</ol>

Note In AWS, <strong>you cannot attach an IAM Role directly to an EC2 instance. You must attach an Instance Profile to the instance, and that profile carries the Role</strong>. By using an Instance Profile, we eliminate the need for long-lived, static "Access Keys" stored on the server. Instead, the instance utilizes temporary, rotating credentials provided by the Instance Metadata Service (IMDS).

<pre>
<code>
resource "aws_iam_instance_profile" "rr_instance_profile" {
  name = "rr-instance-profile"
  role = aws_iam_role.rr_ec2_s3_secret_role.name # Links to your existing role
}
</code>
</pre>

By linking this profile to the Auto Scaling Group's Launch Template, every new instance created during a scale-out event is automatically "born" with the correct identity and permissions, requiring zero manual configuration.

<pre>
<code>
  iam_instance_profile {
    name = aws_iam_instance_profile.rr_instance_profile.name
  }
</code>
</pre>

</p>



<h2>Lambda Function</h2>

<p>
This lambda function `secret_rotation_function` executes the python code `index.py` to perform the necessary tasks for rotation. The following components ensure that the function is both secure and robust for the job at hand.
<ol>
<li><strong>Private subnets</strong>: 
Placing this Lambda inside the database_subnets ensures that the traffic between the Lambda and the Database never touches the public internet. It’s a private-to-private handshake.
<pre>
<code>
    subnet_ids = [
      aws_subnet.database_subnets[0].id,
      aws_subnet.database_subnets[1].id,
      aws_subnet.database_subnets[2].id
    ]
</code>
</pre>

</li>

<li>
<strong>source_code_hash</strong>: 
using filebase64sha256 creates a unique digital signature of the file ensuring that Terraform is notified when the underlying Python code has changed i.e. any change to the file causes the sha256 of the file to change. 
<pre>
<code>
  source_code_hash = filebase64sha256("./index.zip")
</code>
</pre>
Without this, applying any code update with `terraform apply` would do nothing. This is because terraform looks at the name index.zip and if the file name is still the same, it assumes no change.
</li>


<li>
`depends_on` Orchestration logic:
VPC-based Lambdas require specific permissions to create Elastic Network Interfaces (ENIs) during initialization. Because AWS IAM is eventually consistent, a Lambda might attempt to boot before its permissions have fully propagated.
<pre>
<code>
  depends_on = [
    aws_iam_role_policy_attachment.lambda_vpc_access
  ]
</code>
</pre>
depends_on acts as a sequencing gate, forcing Terraform to wait until the VPC permissions are fully attached and active before attempting to initialize the Lambda function.
</li>


<li>
<b>Dedicated Networking</b> (`Lambda-SG`): The function is assigned a dedicated Security Group, allowing for granular control over outbound traffic to the RDS instance while maintaining strict isolation from the application-tier EC2s
<pre>
<code>
    security_group_ids = [aws_security_group.Lambda-SG.id]
</code>
</pre>
</li>
</ol>
</p>

<h2>Secrets Manager: Chicken and Egg Problem</h2>

<p><strong>The Problem: The Circular Dependency</strong>
The database has the following credentials requirement to boot up:
<ul>
<li>Database Username</li>
<li>Database Password</li>
</ul>

Since the secret holds the database credentials required for the EC2 instances to connect to the database, it has the following credentials requirements:
<ul>
<li>Database Username</li>
<li>Database Password</li>
<li>dbname</li>
<li>port</li>
<li>host</li>
</ul>

The `host` value is only known when the database has booted. Thus attempting to create the secret without it will fail with a circular dependency error. Since the database needs the secret prior booting, this results in a conflict of interests.
<strong>We can't have the Host Address until the RDS is created, but we can't (ideally) create a fully functional Secret until we have the Host Address.</strong>

Three steps were employed to resolve the conflict:
<ol>

<li>
Initialize the secret with a placeholder for `host` value. This is the skeleton version of the secret:
<pre>
<code>
resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = "placeholder"
    port     = 3306
    dbname   = "ritual_roast"
  })
}
</code>
</pre>
Once the skeleton version is created to ensure the infrastructure remains "rotation-aware," we utilize a data source to track the AWSCURRENT version of the secret.
<pre>
<code>
data "aws_secretsmanager_secret_version" "latest_credentials" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  depends_on = [aws_secretsmanager_secret_version.db_secret_version]
}
</code>
</pre>
By placing this data source immediately after the initial "Skeleton" version, we ensure that Terraform can resolve the secret's metadata without waiting for the entire RDS provisioning process (which can take 10-15 minutes).
</li>

<li>
Now that the database requirements are met, it can start up successfully.
Once the RDS instance is "Available," a second `aws_secretsmanager_secret_version` resource (using a `depends_on` constraint) injects the real Database Host Address into the secret.
<pre>
<code>
resource "aws_secretsmanager_secret_version" "db_host_update" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    dbname   = "ritual_roast"
    port     = 3306
    host     = aws_db_instance.ritual_roast_db.address
  })

  depends_on = [aws_db_instance.ritual_roast_db]

  lifecycle {
    ignore_changes = [ secret_string ]
  }
}
</code>
</pre>
</li>

<li>
<strong>Automating rotation with `lifecyle` block</strong>: To prevent Terraform from interfering with future password rotations, we implemented a `lifecycle { ignore_changes }` block. This ensures that once the Rotation Lambda takes over management of the credentials, Terraform will not attempt to revert the password to its initial state during subsequent infrastructure updates.

This also prevents application downtime i.e. without the above, if Terraform resets the password to the one in the variables.tf, but the Database is already using the rotated password from the Lambda, the app crashes instantly.
</li>
</ol>
</p>

<h2>RDS</h2>
<p>
The database layer is engineered for resilience and strict network isolation, serving as the "Source of Truth" for the Ritual Roast application.
The following factors are key components of the database layer:

<ol>
<li>
<b>Dedicated Subnet Group</b>: The RDS instance is confined to a private db_subnet_group spanning three Availability Zones. 
<pre>
<code>
resource "aws_db_subnet_group" "rr_db_subnet_group" {
  name = "rr-db-subnet-group"
  subnet_ids = [
    aws_subnet.database_subnets[0].id,
    aws_subnet.database_subnets[1].id,
    aws_subnet.database_subnets[2].id
  ]
}
</code>
</pre>

This ensures the database is unreachable from the public internet and is only accessible via the application-tier Security Group `Web-App-SG` and the lambda security group `Lambda-SG`.
</li>

<li><strong>Resilience & Performance</strong>:
<ul>

<li>
<strong>Multi-AZ Deployment:</strong>: `multi_az` is enabled to ensure high availability. AWS automatically provisions and maintains a synchronous standby replica in a different Availability Zone, providing automatic failover in the event of an infrastructure failure.
</li>

<li>
<strong>Modern Storage (`gp3`)</strong>: General Purpose SSD (gp3) storage allows for independent scaling of IOPS and throughput, providing a more predictable and cost-effective performance profile than older storage types.
</li>
</ul>
</li>

<li>
<strong>Automated Credential Management</strong>: 
<ul>
<li>
<strong>Late-Binding Credentials</strong>: The database is initialized using credentials dynamically retrieved from the Secrets Manager "Skeleton" version. This ensures that the DB is never provisioned with hard-coded passwords.
</li>

<li>
<strong>Rotation-Safe Lifecycle</strong>: To support automated password rotation, we implemented a `lifecycle { ignore_changes = [password] }` block. This allows the Secret Rotation Lambda to manage the database password independently of the Terraform state, preventing accidental credential reverts during future infrastructure updates.
</li>
</ul>
</li>

</ol>

</p>

<h1>8. 🛠️ Tech Stack</h1>

<table>
  <tr>
    <th>Category</th>
    <th>Tools</th>
  </tr>
  <tr>
    <td>Cloud Provider</td>
    <td>AWS (EC2, RDS, ALB, ASG, Lambda, Secrets Manager, S3)</td>
  </tr>
  
  <tr>
    <td>IaC</td>
    <td>Terraform (v1.14.3)</td>
  </tr>
  
  <tr>
    <td>Language</td>
    <td>Python 3.9 (Flask Framework)</td>
  </tr>

  <tr>
    <td>Database</td>
    <td>MySQL 8.x</td>
  </tr>

  <tr>
    <td>OS</td>
    <td>Amazon Linux 2023</td>
  </tr>
  
</table>


<h3>9. 🛡️ Disclaimer</h3>

<p>
*The application logic and frontend design are inspired by the Ritual Roast project in the Udemy course mentioned above.

All infrastructure code, automation scripts, and secret rotation logic were independently developed by me with the help of Gemini 3.
</p>