---
layout: post
title: "Fanatical Quality Engineering in Rackspace VMware Practice Area"
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

# Fanatical Quality Engineering in Rackspace VMware Practice Area

In Rackspace VMware practice area, we value the quality of our products very much. We believe that quality is a team effort. Quality engineering team works with the development team, project management team, product engineering team and devops team to improve the quality of developed products. Our Quality has three key pillars: functionality, performance and security. Our goal is to identify and fix defects as early as possible so that we can deliver secure functional products that perform well for our customers. 

<!-- more -->


## Test Strategy and Process 

For every new product, Quality Engineering team collaborates with all teams to create product test strategy and review them together. The test strategy covers all aspects of our testing. 

* Overview
* Architecture Diagram
* Project Timelines
* Team Contacts
* Dependencies And Integration Systems
* In Scope
* Out of Scope
* Test Approach
* Functional Testing
* End 2 End (E2E) Testing
* Performance Testing
* Security Testing
* Exit Criteria
* Risks & Mitigations

The product test strategy is a live document. We keep updating the document based on changes in the product design, coding and testing. We are using Agile development process in VMware Practice Area. For each sprint, development team, quality engineering team and scrum master create Jira stories and pick stories together. The development team focuses on product coding and unit tests. The quality engineering team focuses on functional testing, end to end testing, performance testing and security testing. Any identified defect is entered into the Jira system so that the development team can verify and fix them as soon as possible. We are automating all our tests so that they can be incorporated into the continuous integration process of our products. 

## Unit Testing 

The development team is responsible of unit tests to ensure that all small pieces of the code have been test thoroughly.  The team is using [Spock testing framework](http://spockframework.org/) to create unit test cases. Spock is a testing and specification framework for Java and Groovy applications. Spock is a more powerful alternative to the traditional JUnit stack, by leveraging Groovy features. Since our products normally interact with lots of internal systems, we also mock those dependent systems. For example, here is one unit test case for one of our product: 


```
package com.rackspace.vdo.vmvp
import com.rackspace.vdo.vmvp.test.support.VmvpConsumerExtensionsBaseSpec
import grails.util.TypeConvertingMap
import org.springframework.security.core.userdetails.UserDetails
import spock.lang.Shared
import spock.lang.Unroll

/**
 * Unit Tests for AccountShowConsumer.
 */
class AccountShowConsumerSpec extends VmvpConsumerExtensionsBaseSpec {

  
    AccountShowConsumer consumer

    @Shared
    VdacFailure embedFailure

    def setup() {
        IdentityUser userDetails = Mock(IdentityUser)
        vmvpFactory = Mock(VmvpFactory)
        vmvpFactory.makeAccountDetailsResponse(*_) >> Mock(AccountDetailsResponse)
        consumer = new AccountShowConsumer() {
            @Override
            UserDetails getUserDetails() {
                return userDetails
            }
        }
        consumer.rabbitMessagePublisher = rabbitMessagePublisher
        consumer.vmvpFactory = vmvpFactory

        embedFailure = new SimpleVdacFailure(httpStatus: 101, errorCode: 'x')
    }

    @Unroll
    def 'test fetch one account #input'() {
        setup:
        consumer.vdacDataService = Mock(VdacDataService) {
            loadAccount(*_) >> Mock(Account)
        }

        when:
        consumer.handleMessage(new TypeConvertingMap(input), messageContext)

        then:
        1 * rabbitMessagePublisher.send(_) >> { rabbitMessageProperties = it[0] }
        rabbitMessageProperties.routingKey == REPLY_TO
        rabbitMessageProperties.body.view == expView
        rabbitMessageProperties.headers["http-status"] == expHttpStatus

        where:
        expHttpStatus | expView         || input
        200           | '/account/show'  || [accountId: ACCOUNT_ID]
    }
  }

```

## Functional Testing

Functional testing refers to activities that verify a specific action or function of the code. These are usually found in the code requirements documentation, although some development methodologies work from use cases or user stories. Functional tests tend to answer the question of "can the user do this" or "does this particular feature work." Functional test cases have positive test cases and negative cases. We are using [WireMock]( http://wiremock.org/) to mock all external systems that our products interact. WireMock is a flexible API mocking tool for fast, robust and comprehensive testing. We are developing a collection of mock web services, which allows us to independently control the state of dependencies. This will allow us to test specific functionality quickly, run tests locally and on development environments, and perform more specialized testing.  For example, here is one functional test case for one of our products:

```
import unittest
import framework
import framework.config
import framework.utils
from framework.mappings_file_loader import MappingsFileLoader
from framework.mock_service_factory import MockServiceFactory
from qe_coverage.unittest_decorators import tags, unless_coverage, categories

class vMvpAccountsTest(unittest.TestCase):
    @unless_coverage
    def setUp(self):
        self.mock_service_factory = MockServiceFactory()
        self.identity = self.mock_service_factory.mock_service('identity')
        self.identity.reset_all_requests()

        self.core = self.mock_service_factory.mock_service('core')
        self.core.reset_all_requests()

        self.scenarios = scenario_adapter_factory.create_scenario_adapter(DatabaseType.POSTGRES, AppName.VSPOT)

        self.mappings_file_loader = MappingsFileLoader(suite_dir)
        self.mappings_file_loader.load_mappings_for('users', 'identity', self.identity)

        self.vrax = vRaxApiClient(vrax_url, default_identity_token)

    @unless_coverage
    def tearDown(self):
        self.scenarios.__exit__()

    @tags('positive', 'TAAS-987', 'p1')
    def test_get_account_by_number(self):
        """
        Get account by number happy path without links
        """
        accounts = self.scenarios.create_accounts(5)
        expected_account = accounts.popitem()[1]

        response = self.vrax.vmvp.accounts.get_by_number(expected_account.number)

        self.assertEqual(response.status_code, 200)
        json_response = framework.utils.validate_json(response.text)
        self.assertTrue(json_response)
        account = AccountObject.deserialize(json_response)
        self.assertEqual(account.number, expected_account.number)

```


## End to End Testing

End to end testing aims to test the functionality of an application under product-like circumstances and data to make sure that it meets the requirement specification. Once our application is deployed into a working staging environment, quality engineering team starts working on end to end testing. First, we create various test scenarios based on conversations with all teams and document them in our test strategy. Secondly,  we use [pytest framework]( 
https://pytest.org) to automate the test scenarios to make sure that we have enough coverage for our applications. We also make our end to end test suite available so that the development team can run them if necessary. For example, here is one test case of our end to end testing: 

```
@pytest.mark.categories('VMVP Accounts')
class TestVmvpAccounts:
    @pytest.fixture(autouse=True)
    def expected_virtual_machines(self, vrax_url):
        self.accounts_json = {
            'account_5002019': account_5002019.json(vrax_url),
            'account_5002020': account_5002020.json(vrax_url),
            'account_5002021': account_5002023.json(vrax_url)
        }

    @pytest.mark.RBAC
    @pytest.mark.GET
    @pytest.mark.tags('positive', 'integration', 'p0', 'TAAS-1453')
    def test_vmvp_get_account_by_number_rbac(self, vrax_client, rbac_tokens, rbac_roles, environment):
        """
        Validate RBAC for endpoint from CSV
        :param vrax_client: fixture of generic vRaxApiClient(without default_token)
        :param rbac_tokens: fixture of list of dicts [{role:token},{role:token}]
        :param rbac_roles: list of roles to be tested from user.json
        :param environment: fixture of staging, development, production
        """
        if environment == "production":
            pytest.skip("RBAC tests can only run on development or staging")

        method = "vmvp.accounts.get_by_number"

        def call_method(token): return vrax_client.vmvp.accounts.get_by_number(account_number=TestAccounts.accounts[0], token=token)

        success, errors = framework.rbac.call_rbac(csv_file=csv_file,
                                                   method=method,
                                                   call_method=call_method,
                                                   api_client_method_header=api_client_method_header,
                                                   rbac_roles=rbac_roles,
                                                   rbac_tokens=rbac_tokens)
        assert success, "Error in RBAC: {}".format(errors)

    @pytest.mark.GET
    @pytest.mark.tags('positive', 'integration', 'p1', 'TAAS-1177', 'TAAS-1255', 'TAAS-1272', 'TAAS-1371', 'TAAS-1564')
    def test_vmvp_getaccount(self, vrax_api):
        """
        Validate happy path
        https://one.rackspace.com/pages/viewpage.action?title=Phase+1+-+API+Contracts&spaceKey=mgdvirtdev#Phase1-APIContracts-GET/managed-virt/{accountId}
        :param vrax_api: vrax api client to invoke the api
        :return: 200 success
        """

        self._call_and_validate_embeds_and_links(vrax_api, embed=[])
```


## Performance Testing

Performance testing is generally executed to determine how a system or sub-system performs in terms of responsiveness and stability under a particular workload. It can also serve to investigate, measure, validate or verify other quality attributes of the system, such as scalability, reliability and resource usage.


We choose [Gatling](https://gatling.io/) as our perfromance testing framework. Gatling is an open-source load and performance testing framework based on Scala, Akka and Netty. Gatling is written in Scala, which allows you to run it on any system. Gatling enables us to create to create performance tests as code. Gatling also creates detailed metrics dashboard in html format after test execution out of box. Gatling can simulate multiple virtual users with a single thread based on the actor mode. Gatling can be easily integrated with Continuous Integration pipelines by using Jenkins Gatling plugin. 


We create performance test cases for all API calls. We measure the response time of all API calls. We simulate large number of customers calling various API at the same time. The tests are run in both staging environment and production environment. Once we have the test results ready, we analyze the metrics results to make sure that the performance meet our expectations. If there are any performance issues, the teams collabrate on fixing the issue. The goal is to provide a product that performs well even with unexpected large number of customers and requests. 


For example, here is one test case from our performance test suite:

```
import com.rackspace.objects.{VMVP, HttpConfig}
import com.typesafe.config.ConfigFactory
import io.gatling.core.Predef._
import io.gatling.http.Predef._

class ListHypervisors extends Simulation {

  val conf = ConfigFactory.load()
  val concurrentUsers = conf.getInt("simulations.concurrentUsers")
  val numSamples = conf.getInt("simulations.numberSamples")
  val uri1 = "https://vrax.rackspace.com/managed-virt/{accountID}/hypervisors"
  
  val scn = scenario("ListHypervisors")
    .feed(csv("token.csv").random)
    .repeat(numSamples) {
      exec(session => {
        val accountURL = "/managed-virt/" + VMVP.getRandomAccountId()
        println("GET " + accountURL + "/hypervisors")
        session.set("accountURL", accountURL)
      })
      .exec(http("List hypervisors")
        .get("${accountURL}/hypervisors")
        .headers(HttpConfig.headers_0)
        .check(status.is(200)))
    }

  setUp(scn.inject(atOnceUsers(concurrentUsers))).protocols(HttpConfig.httpConf)
}

```

## Security Testing

In Rackspace VMware Practice Area, Security is our top priority. QE Security works with the development team and QE team to integrate security checks into the SDLC process. 

During design stage, we conduct threat modeling for the application.  Threat modeling is a white board session to break down the application from security and risk perspective. The session focuses on sensitive data and data flows across various components.  We learn about trust boundary, attack surface, potential risks & security controls about the applications. Threat modeling helps us identify potential security defects in the design stage so that we can get this address early. 

Once the development team starts coding, QE security team conducts security code review of the source code. We are using commercial solution of automatic security code scanning tool that can scan thousands of lines of code in short time. However, the findings generated by the tool might contain false positives. QE security team work with the development team to verify each finding to filter out false positives. In addition, QE security team also conducts manual security code review of key components of the source code. During security code review, we focus on identifying common security defects as defined in [OWASP Top 10]( https://www.owasp.org/index.php/Category:OWASP_Top_Ten_2017_Project): 
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

After we deploy the application into the staging environment, QE team starts their E2E testing to make sure that the application is working. At the same time,  QE Security team also conducts Web application/APi security testing in the staging environment. We used security testing tools such as Burp, Syntribos, Zap to test the application for the listed security defects. 

We prioritize identified defects based on their severity and impact. QE security team work with the development team and QE team to make sure that any critical or high security defects are addressed before the application is released into the production environment. 


## Testing Environment

We have been collaborating with DevOps to improve our testing environment. DevOps added our physical servers as a tenant to a vRealize Automation instance. This approach gives us dedicated resources for creating and destroying VMWare servers dynamically. We do not need to manage our servers and can concentrate on automating test cases. 
 
To utilize our new dynamic environment with more jobs and more automation, we have made a significant amount of changes to our existing workflow components, deployment playbooks, test jobs in Jenkins, etc.  Our new testing environment is ready with new features. 

* VMWare-QE went from being limited to running up to two tests at a time on long-lived static build nodes to now being able to run 22 tests simultaneously with the ability to easily increase this further if we require
* Our functional tests now dynamically create a server, build the testing application(s) on that server, run tests on that server, collect results and artifacts, and destroy the dynamic server
* Application logs are forwarded to Splunk to allow search and review
* This increased capacity as well as our test jobs and deployment updates allow for Developers to self-serve our tests with a variety of parameters
* This sets the ground work for even further automation and integration into the development pipeline that can be added iteratively.



## Fanatical Quality

In Rackspace VMware practice area, quality is everyone's responsibilities. Quality engineering team, development team, Devops team, security team and project management team work together to make sure that we deliver products with great quality to our customers. The teams concentrate on improving the SDLC process using automation and new technology. Together, we provide fanatical experience to our customers. 
