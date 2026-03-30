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
<img src="images/RR-HLD Architecture.png" alt="Architecture diagram provided by the IaaS Academy Udemy Course.">



<h3>🏗️ Architecture Overview</h3>

Deep dive summary of the HLD

The project features a high-availability 3 tier deployment





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