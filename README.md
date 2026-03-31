<h1>Ritual Roast: Automated 3-Tier AWS Architecture</h1>
<h3>Background</h3>
<p>
Ritual Roast is a fictitious company embarking on an advertising campaign to engage with their customers<br>
by hosting a recipe competition where customers complete the online form with their recipe and contact details.<br>
The chefs will try the recipe and decide the winner to receive a prize.<br>
The company aims to build a mailing list from the emails for future campaigns.
</p>

<h3>Project Evolution & Motivation</h3>
<p>
The project is based on the architectural  concepts from the <a href="https://www.udemy.com/course/aws-solutions-architect-capstone-projects/">AWS Solutions Architect SAA-C03 – Hands-On Projects</a> course on Udemy.<br>
The original course consists of manual infrastructure deployment via the AWS Management Console.<br>
This project converts that into a sophisticated Infrastructure as code (IAC) deployment using <strong>Terraform</strong>. 
In implementing this project I demonstrate my skills and ability to turn complex architectures<br>
into practical production worthy solutions.



<h3>High-Level Design (HLD)</h3>
<p>
The diagram below is the schematics for Ritual Roast, provided in the course.<br>
This along with other documents (???#@#@# Say what they are ~#$#'#???) provide the road map for this Terraform implementation.
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

<h3>🏗️ Architecture Overview</h3>

Deep dive summary of the HLD

The project features a high-availability 3 tier deployment

<h3>🌐 Networking</h3>

<p>
This project is deployed in <strong>"eu-west-2"</strong> region. With the exception of the S3 bucket "rr-capstone-${bucket-hex}" <br>all the resources used in this project are deployed under the Ritual Roast VPC, <strong>"ritual-roast-vpc"</strong>.<br>
Note, S3 buckets are global and unique.<br>
The configuration specification for this project can be found at <a href="./documents/Ritual Roast Resource Specs.pdf">Ritual Roast Resource Configuration</a>.<br>
It sets out what values to use for each resource, where possible, such as the VPC CIDR range <b>10.16.0.0/16</b> <br>hence all the subnet CIDR blocks, subnet names and availability zones for each Tier, in additions to other<br>
resource parameter settings.<br>

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
</p>
Elastic IPs will be allocated for the NAT gateway and released when the project is destroyed.<br>
With respect to Terraform, the creation of the VPC and Subnets are handled in <a href="./networking.tf">networking.tf</a>.<br>Both the NAT gateway and the IGW creation are handled in <a href="./gateways.tf">gateways.tf<a>


<h3>🔒 Security</h3>
<p>
Since all subnets are by default associated to the VPC default route table, to prevent exposing private resources <br>to the internet, a single route is created via NAT gateways placed in a public subnet that has an internet gateway(IGW) attached.<br>This essentially gives private resources an Egress only communication with the outside.
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
<strong>Security Groups<strong>
Each Tier has it's own security group which enables only the necessary communication ingress and egress<br>
via security group rules. The presentation tier's security group, <b>"LoadBalancer-SG"</b> has an ingress rule
<br>that accepts traffic from the internet on port 80, and an egress rule that allows it, essentially the <br> Application Load Balancer (ALB) to send traffic to the application tier i.e. any resource that has the<br> <b>Web-App-SG</b> security group attached. In this case that would be the EC2 instances created by the ASG.<br>
The application tier's security group <b>Web-App-SG</b> in turn has an ingress rule that accepts traffic from<br>
the <b>LoadBalancer-SG</b> on port 5000 and an egress rule that allows communication to any protocol to any ip.<br>
However, these instances are on a private subnet using a NAT gateway for outbound communication to the internet.<br>These instances also need to communicate both to the presentation tier and the data tier, <b>Database-SG</b> <br> security group. The <b>Database-SG</b> has an ingress rule accepting traffic on port 3306 from <b>Web-App-SG</b><br> and from itself for the secret rotation from Secrets Manager.



<b>Session Manager</b>

<h3>🚀 Technical Highlights</h3>

-> VPC
    -> CIDR range
    -> Subnets and subnets cidr range  (Please see doc)
    -> Security groups
    -> Routing via default router NAT


-> S3
    -> python scrip for flask app
    -> Remote backend and state lock

-> Roles

-> Lambda function

-> ASG
    -> Launch template - Userdata
        -> systemd service
        -> mysql client
        -> 

-> Secret manager / Chicken and egg problem

-> RDS
    -> Multi-AZ failover







<h3>🛠️ Tech Stack</h3>

Make a table of this:

| Category | Tools |
| :--- | :--- |
| **Cloud Provider** | AWS (EC2, RDS, ALB, ASG, Lambda, Secrets Manager, S3) |
| **IaC** | Terraform (v1.7+) |
| **Language** | Python 3.9 (Flask Framework) |
| **Database** | MySQL 8.x |
| **OS** | Amazon Linux 2023 







<h3>📖 Deployment Instructions</h3>









<h3>🛡️ Disclaimer</h3>

<p>
*The application logic and frontend design are inspired by
 the Ritual Roast project in the Udemy course mentioned above.
 All infrastructure code, automation scripts,
 and secret rotation logic were independently developed by me
 with the help of Gemini 3
</p>