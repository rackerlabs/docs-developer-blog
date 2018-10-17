---
layout: post
title: "Fanatical Security Delivered by Quality Engineering Security Team"
date: 2018-10-18 07:00
comments: true
author: Michael Xin
published: true
authorIsRacker: true
authorAvatar: https://s.gravatar.com/avatar/5c2bae8f6f4c9669249888f5b8e1f5b0
bio: "Michael Xin is a senior QE/Security manager in Rackspace. He is leading VMware QE team and QE Security team. Michael is passionate about quality and security for Rackspace products. Michael has years of experience in application security, security SDLC, test automation, cloud computing, agile development and CI/CD."
categories:
    - Automation
    - Security
    - Developers
    - Orchestration
---

Our customers require us to develop software that is trustworthy and secure. Privacy also demands attention. To ignore privacy concerns of users can invite blocked deployments, litigation, negative media coverage, and mistrust. The Quality Engineering (QE) security team’s goal is to minimize security- and privacy-related defects in design, code, and documentation, and to detect and eliminate these defects as early as possible in the software development life cycle (SDLC). Developers who most effectively address security threats and protect privacy earn users’ loyalties and distinguish themselves from their competitors.

<!-- more -->


### The job of the quality engineering security team 

The quality engineering security team is responsible for the security component of the QE process. The goal of the team is to ensure all customer product development, including code & backend infrastructure, are secured as part of the SDLC. We are one of the three pillars of software quality:

* Does it function?
* Does it perform?
* Is it secure?

This process includes conducting threat models, system architecture and infrastructure reviews, dynamic and static code testing/reviews, API/web UI testing, infrastructure testing, penetration testing, and adherence to secure development standards.

For every new product, the quality engineering security team collaborates with all teams to create a product security test strategy and review the strategy with all the teams together. The security test strategy covers the following security testing aspects: 


* Overview
* Threat Model (Data Flow) Diagram
* Contacts
* In Scope
* Out Of Scope
* Security Testing Process
   * Threat Modeling
   * Vulnerability Assessment and Pen Testing
   * Code Review/Static Analysis
   * Web Application Testing
   * API Testing
* Exit Criteria
* Risks
* References

During the design stage, we conduct threat modeling for the application. The threat modeling session focuses on sensitive data and data flows across various components. The session helps us identify potential security defects in the design stage so that we can address them early. Once the development team starts coding, the QE security team conducts a security code review of the source code using both automatic tool and manual reviewing approach. After we deploy the application into the staging environment, the QE Security team conducts web application and API security testing. We prioritize identified defects based on their severity and impact. The QE security team works with the development team and QE team to make sure that any critical or high security defects are addressed before the application is released into the production environment.


### Agile security 

The trend of the security field is to integrate with the development process as early as possible with minimum interruption of their operation. The security team should be able to speak the same language as the development team to get their buy-in about security. Since every development team is using Agile development process in Rackspace, the security team also adapted the Agile process for our operation. We are using the same Jira system that all other teams are using to track all our tasks and stories so that they are aware of our progress. For any incoming security request, we create a Jira ticket and add the requester as the observer. For identified defects, we create Jira defects in the development team’s Jira project directly so that they can pick up the story and fix them quickly. The security team also has daily standup to check the progress of Jira stories of the team members. We run retrospective meetings every two weeks to identify rooms for improvement in our process. 



### Threat Modeling 

Threat Modeling Is a Core Element of the overall Security Life-cycle (SDL). As part of the design phase of the SDL, threat modeling allows software architects to identify and mitigate potential security issues early, when they are relatively easy and cost-effective to resolve. Therefore, it helps reduce the total cost of development. 

The threat modeling session is a technical discussion of the design and deployment strategy utilized by the product.  A rough diagram will be created by the product security team as the discussion ensues.  Depending on the complexity and type of product, the session will cover issues such as:

* How do various parts of the product communicate with each other?
* Is that communication encrypted?
* What protocol is used for the communication?
* How does the product authenticate requests its makes or receives?
* What software stack is used by this product? OS?
* Where will this product be deployed?  Iron, private cloud, public cloud...
* How is access granted and maintained for administration work?
* How are the servers and applications patched?
* How do you share passwords within your team?
* How to you prevent one user from accessing another data?
* If customer cancels or otherwise stops using the product, how securely is their data erased?

The process will be an interactive, iterative process generally starting from a customer use of the product and will cover the general use cases for that product. The modeling is concerned with the flow of data through the products system(s) and the products interactions with external systems.  
 

![Sample Product DataFlow Diagram]({% asset_path 2018-10-18-fanatical-security-delivered-by-quality-engineering-security-team/dataflow_diagram.png %})


After delivery of the threat model, a reminder will be set by the QE security team to touch base with the product team to ensure the product has not made any design-level changes and the previously created threat model still accurately describes the products data flows.  If, at that future date, the product has made changes, a short threat model update session will be scheduled to review the existing threat model and update it as necessary.


### Security code review

Security code review is the process of auditing the source code for an application to verify that the proper security controls are working to eradicate possible application security defects. Security code review is a method of assuring developers are following secure development guidance. 

We use a commercial solution with an automatic security code-scanning tool that can scan thousands of lines of code in a short time. However, the findings generated by the tool might contain false positives. The QE security team works with the development team to verify each finding to filter out false positives. In addition, the QE security team also conducts a manual security code review of key components of the source code. During the security code review, we focus on identifying the following common security defects as defined in the [OWASP Top 10]( https://www.owasp.org/index.php/Category:OWASP_Top_Ten_2017_Project): 
* A1:2017-Injection
* A2:2017-Broken Authentication
* A3:2017-Sensitive Data Exposure
* A4:2017-XML External Entities (XXE)
* A5:2017-Broken Access Control
* A6:2017-Security Misconfiguration
* A7:2017-Cross-Site Scripting (XSS)
* A8:2017-Insecure Deserialization
* A9:2017-Using Components with Known Vulnerabilities
* A10:2017-Insufficient Logging&Monitoring
 
 We have code review checklists for different type of application. The quality engineering security team can leverage these checklists to make sure that the review to be compreshensive. For exmpale, here is the authentication part from security source code review checklist for web application: 

* 2.1    Authentication  Are application trust boundaries identified on the data flow diagrams in the design document?
* 2.2 Authentication  Does the design identify the identities that are used to access resources across all trust boundaries?
* 2.3 Authentication  Does the application require authentication for all resource access attempts except for publicly accessible resources?
* 2.4 Authentication  Does the design identify the mechanisms used to protect user credentials whilst in transit?
* 2.5 Authentication  Does the application ensure that minimal error information is returned in the event of authentication failure?
* 2.6 Authentication  Does the application use authentication controls that fail in a secure manner?
* 2.7 Authentication  Is the identity used to authenticate with the database (including level of access required) detailed in the design document?
* 2.8 Authentication  Have the identities being used by this application been configured for least-privileged access?
* 2.9 Authentication  Are authentication related tokens such as cookies transmitted over secured connections?
* 2.10    Authentication  Does the application restrict the number of failed logon attempts ?
* 2.11    Authentication  Does the application enforce the use of complex passwords (meet Rackspace password complexity rules)?


### API security testing 

API security testing is a process of comparing the state of API against a set of security requirements. Unlike security code review, API security testing needs a fully functional application to run various security tests. Prior to actively testing the product's systems, the quality engineering security team works with the teams to determine the appropriate scope for the API test. Once scope has been determined, the security team works with the product team to determine an workable testing window for the testing to occur. Once the schedule testing window has arrived, the security team begins the active testing phase with reconnaissance and system enumeration activities such as Reading the API documentation to understand how to interact with the API, Creating legitimate calls to the API, etc. 


API security testing can be done using automatic tools or manually. Normally, it is a mix of manual verification with automatic tools. For example, you can use Burp, an intercepting proxy, to view and modify the HTTP communication between the tester and the API.  You can include certain test string in the payload and verify whether it is subject to SQL injection by checking the response from the server. At the same time, you can also use intruder from Burp to automatically send thousands of different test payloads to the server. We have a checklist of different categories of tests that we should perform to provide comprehensive coverage: 
* Info Gathering
* Configuration Management Testing
* Authentication Testing
* Session Management
* Authorization Testing
* Business logic Testing
* Data Validation Testing
* Denial of Service Testing
* Web Services testing

Each different categories of security tests have separate list of security tests. For example, the following security tests belong to Data Validation Testing:

* Testing for Stored Cross Site Scripting
* Testing for SQL Injection
* Testing for LDAP Injection
* Testing for ORM Injection
* Testing for XML Injection
* Testing for XPath Injection
* Testing for IMAP/SMTP Injection
* Testing for Code Injection
* Testing for OS Commanding Injection 
* Testing for Buffer Overflow
* Testing for Incubated vulnerability


### Infrastructure security testing

Infrastructure security testing is the process of identifying, classifying and prioritizing vulnerabilities in computer systems and network infrastructures. The process is intended to identify threats and the risks they pose. We normally use automated testing tools, such as Nessus or Nexpose scanner, whose results are listed in a test finding report. For each vulnerability reported by the commercial scanner, the quality engineering security team manually verifies the reported vulnerability to remove any false positives from the final report of test findings. 


Infrastructure security testing can identify the following security defects for computer systems and networks: 

* Vulnerabilities that allow a remote hacker to control or access sensitive data on a system.
* Misconfiguration (e.g. open mail relay, missing patches, etc.).
* Default passwords, a few common passwords, and blank/absent passwords on some system accounts. 
* Denials of service against the TCP/IP stack by using malformed packets
* Preparation for PCI DSS audits


### Security and automation 

The average ratio between the number of developers and the number of quality engineering security members is close to 50:1 in the industry. The quality engineering security team struggles meeting the security requests from the development team if they are still using manual process even with automation tools. At the same time, the development team is releasing their products faster and faster by leverage technologies such as Continuous Integration and Continuous Delivery (CI/CD). Traditional security team cannot handle CI/CD since their testing cycles last days or weeks. 

In order to meet these new challenges, our security team focus on automation for both tooling and processes. Every member of our security team is a software developer who can write code and work on automation. The security team provides developer-friendly security tools that can be integrated into the development process. The running time of these tools is minutes or seconds. Otherwise, the development team will move forward without security. At the same time, the security team run the same toolset for better coverage with longer running time separately.  Together, we increase the tool coverage with both team happy. 

The quality engineering security team have been working on various automation tools. We have released some open source tools. We are looking forward to releasing more in the future. 

* [Syntribos]( https://github.com/openstack/syntribos) is an open source automated API security testing tool that is maintained by members of the OpenStack Security Project.Given a simple configuration file and an example HTTP request, syntribos can replace any API URL, URL parameter, HTTP header and request body field with a given set of strings. Syntribos iterates through each position in the request automatically. Syntribos aims to automatically detect common security defects such as SQL injection, LDAP injection, buffer overflow, etc. In addition, syntribos can be used to help identify new security defects by automated fuzzing.
* [DefectDojo]( https://www.defectdojo.org/) is a security program and vulnerability management tool. DefectDojo allows you to manage your application security program, maintain product and application information, schedule scans, triage vulnerabilities and push findings into defect trackers. Consolidate your findings into one source of truth with DefectDojo.
* Security Pipeline is an integration framework that integrate various security tools such as Blackbox testing and security code scanning tools. It can be used by the security team to automate the security testing process for our products.  


### Fanatical security

Security is very important for the success of Rackspace. The quality engineering security team is part of the quality engineering organization of which security is a component of the overall responsibility. The others are functional and performance testing. The focus of the quality engineering security team is similar to that of the developers - build a product that is functional, secured, and performs as expected. The security team works with other teams to identify and address security defects before the product is released to customers. Security testing is conducted throughout the entire software development life cycle (SDLC) so that security defects may be addressed in a timely manner. Together, we provide fanatical security experience to our customers.

