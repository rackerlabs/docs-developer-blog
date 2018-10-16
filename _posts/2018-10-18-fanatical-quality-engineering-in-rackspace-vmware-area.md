---
layout: post
title: "Fanatical Quality Engineering in Rackspace VMware Practice Area"
date: 2018-09-28 07:00
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

Handling a huge scale of infrastructure requires automation and infrastructure as code. [Terraform](https://www.terraform.io) is a tool that helps to manage a wide variety of systems including dynamic server lifecycle, configuration of source code repositories, databases, and even monitoring services. Terraform uses text configuration files to define the desired state of infrastructure. From those files, Terraform provides information on the changes to be made based on the current state of that infrastructure, and can make those changes.

<!-- more -->

## Installation

Terraform can be downloaded for a variety of systems at the [Terraform downloads page](https://www.terraform.io/downloads.html). After downloading, extract the archive and move the `terraform` binary to a location on your PATH. That's it. Because it's written in Go, it includes all dependancies and is a single binary.

## Configuration

Terraform does not [officially support Rackspace Cloud](https://www.terraform.io/docs/providers/openstack/index.html#rackspace-compatibility) as a provider, but the OpenStack provider does work on the Rackspace Cloud and only needs a bit of configuration to get started. We use the following configuration for this simple example:

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

Theres a few things to point out in the configuration. When there are a lot of variables to be managed, variables are typically included in seperate files. Since this example only has a few, the variables are added in our configuration file right at the top. Another good thing to know about variables is that Terraform reads environment variables of `TF_VAR_<variable>`. That means that to prevent writing secrets in configuration files, environment variables of `TF_VAR_rax_pass`, `TF_VAR_rax_user`, and `TF_VAR_rax_pass` can be created and are read by Terraform at runtime.

To create an environment variable, use the following method to enter the value without that value being recorded as it would be when entering it direcly on the command line.

```
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

Another note on the configuration, `image_id` and `flavor_id` need be updated to values for what you want to create. Most OpenStack or command line clients that interface with Rackspace have a method to list available images and flavors. If you don't have one installed and ready, take a look at the [image](https://developer.rackspace.com/docs/cloud-servers/v2/api-reference/svr-images-operations/) and [flavor](https://developer.rackspace.com/docs/cloud-servers/v2/api-reference/svr-flavors-operations/) API documentation to see how to get these right from the Cloud Server API.

Finally, the network configuration provided in this configuration specifies the use of the default public and private network on the server that we create. Using the OpenStack plugin on Rackspace Cloud does require specifying networks, and not including specific networks in the configuration might result in the creation taking longer than expected and errors when attempting to destroy.

## Terraform steps

Now that we have created our desired configuration in a simple text file, there are just a few steps to push that to a real environment. We will use the following commands to interact with our environment.

1. `terraform init`
1. `terraform plan`
1. `terraform apply`
1. `terraform destroy`

### Terraform init

Terraform fetches the current state of the environment to compare it against the written configuration with `terraform init`. By default, this state information is recorded in a local file. There are other methods for storing this information, and Terraform can be configured to store the state information remotely. Using a remote store ensures that different members of the team all share the same environment state when using Terraform. For this example, we use the default local state file.

Use `terraform init` to initialize the current state of the environment.

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

### Terraform plan

I would argue that this next step is the most important. Running `terraform plan` compares the current state of the environment with the changes required to make the environment match the configuration written. This is important to ensure that what we expect to happen is what is going to happen. This simple example probably won't run into any collisions on a normal environment, but always double check to make sure that any `destroy` actions listed in the plan output are intended.

```
$ terraform plan
Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.

openstack_compute_instance_v2.terraform-test: Refreshing state... (ID: a3fd1c5a-5d01-4434-a673-223cc3266696)

------------------------------------------------------------------------

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  + openstack_compute_instance_v2.terraform-test
      id:                       <computed>
      access_ip_v4:             <computed>
      access_ip_v6:             <computed>
      all_metadata.%:           <computed>
      availability_zone:        <computed>
      flavor_id:                "2"
      flavor_name:              <computed>
      force_delete:             "false"
      image_id:                 "8f47cf87-1e90-4370-b59d-730256265dce"
      image_name:               <computed>
      key_pair:                 "mykey"
      name:                     "terraform-test"
      network.#:                "2"
      network.0.access_network: "false"
      network.0.fixed_ip_v4:    <computed>
      network.0.fixed_ip_v6:    <computed>
      network.0.floating_ip:    <computed>
      network.0.mac:            <computed>
      network.0.name:           "public"
      network.0.port:           <computed>
      network.0.uuid:           "00000000-0000-0000-0000-000000000000"
      network.1.access_network: "false"
      network.1.fixed_ip_v4:    <computed>
      network.1.fixed_ip_v6:    <computed>
      network.1.floating_ip:    <computed>
      network.1.mac:            <computed>
      network.1.name:           "private"
      network.1.port:           <computed>
      network.1.uuid:           "11111111-1111-1111-1111-111111111111"
      power_state:              "active"
      region:                   "DFW"
      security_groups.#:        <computed>
      stop_before_destroy:      "false"


Plan: 1 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------

Note: You didn't specify an "-out" parameter to save this plan, so Terraform
can't guarantee that exactly these actions will be performed if
"terraform apply" is subsequently run.
```

### Terraform apply

With the backend initialized and the changes that will be caused by applying this configuration confirmed, we now run `terraform apply`. This action first provides the same output as seen with `terraform plan` and requires confirmation to continue. Additionally this provides output every ten seconds to monitor elapsed time as these changes are made, and a summary on completion.

```
$ terraform apply
openstack_compute_instance_v2.terraform-test: Refreshing state... (ID: a3fd1c5a-5d01-4434-a673-223cc3266696)

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  + openstack_compute_instance_v2.terraform-test
      id:                       <computed>
      access_ip_v4:             <computed>
      access_ip_v6:             <computed>
      all_metadata.%:           <computed>
      availability_zone:        <computed>
      flavor_id:                "2"
      flavor_name:              <computed>
      force_delete:             "false"
      image_id:                 "8f47cf87-1e90-4370-b59d-730256265dce"
      image_name:               <computed>
      key_pair:                 "mykey"
      name:                     "terraform-test"
      network.#:                "2"
      network.0.access_network: "false"
      network.0.fixed_ip_v4:    <computed>
      network.0.fixed_ip_v6:    <computed>
      network.0.floating_ip:    <computed>
      network.0.mac:            <computed>
      network.0.name:           "public"
      network.0.port:           <computed>
      network.0.uuid:           "00000000-0000-0000-0000-000000000000"
      network.1.access_network: "false"
      network.1.fixed_ip_v4:    <computed>
      network.1.fixed_ip_v6:    <computed>
      network.1.floating_ip:    <computed>
      network.1.mac:            <computed>
      network.1.name:           "private"
      network.1.port:           <computed>
      network.1.uuid:           "11111111-1111-1111-1111-111111111111"
      power_state:              "active"
      region:                   "DFW"
      security_groups.#:        <computed>
      stop_before_destroy:      "false"


Plan: 1 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

openstack_compute_instance_v2.terraform-test: Creating...
  access_ip_v4:             "" => "<computed>"
  access_ip_v6:             "" => "<computed>"
  all_metadata.%:           "" => "<computed>"
  availability_zone:        "" => "<computed>"
  flavor_id:                "" => "2"
  flavor_name:              "" => "<computed>"
  force_delete:             "" => "false"
  image_id:                 "" => "8f47cf87-1e90-4370-b59d-730256265dce"
  image_name:               "" => "<computed>"
  key_pair:                 "" => "mykey"
  name:                     "" => "terraform-test"
  network.#:                "" => "2"
  network.0.access_network: "" => "false"
  network.0.fixed_ip_v4:    "" => "<computed>"
  network.0.fixed_ip_v6:    "" => "<computed>"
  network.0.floating_ip:    "" => "<computed>"
  network.0.mac:            "" => "<computed>"
  network.0.name:           "" => "public"
  network.0.port:           "" => "<computed>"
  network.0.uuid:           "" => "00000000-0000-0000-0000-000000000000"
  network.1.access_network: "" => "false"
  network.1.fixed_ip_v4:    "" => "<computed>"
  network.1.fixed_ip_v6:    "" => "<computed>"
  network.1.floating_ip:    "" => "<computed>"
  network.1.mac:            "" => "<computed>"
  network.1.name:           "" => "private"
  network.1.port:           "" => "<computed>"
  network.1.uuid:           "" => "11111111-1111-1111-1111-111111111111"
  power_state:              "" => "active"
  region:                   "" => "DFW"
  security_groups.#:        "" => "<computed>"
  stop_before_destroy:      "" => "false"
openstack_compute_instance_v2.terraform-test: Still creating... (10s elapsed)
openstack_compute_instance_v2.terraform-test: Still creating... (20s elapsed)
openstack_compute_instance_v2.terraform-test: Still creating... (30s elapsed)
openstack_compute_instance_v2.terraform-test: Still creating... (40s elapsed)
openstack_compute_instance_v2.terraform-test: Still creating... (50s elapsed)
openstack_compute_instance_v2.terraform-test: Still creating... (1m0s elapsed)
openstack_compute_instance_v2.terraform-test: Creation complete after 1m9s (ID: 2c1537b4-0bfa-4293-a6fb-b708553263f7)

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

```

Once the apply is complete, this server is now accessible and can be viewed in the Rackspace Cloud portal, API, or your command line interface of choice.

### Terraform destroy

Once the resource, or resources, are no longer needed, the resource can be destroyed just as easily as it was created. Running `terraform destroy` displays what will be destroyed and requires confirmation to remove the resources provided from the configuration.

```
$ terraform destroy
openstack_compute_instance_v2.terraform-test: Refreshing state... (ID: 2c1537b4-0bfa-4293-a6fb-b708553263f7)

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  - openstack_compute_instance_v2.terraform-test


Plan: 0 to add, 0 to change, 1 to destroy.

Do you really want to destroy?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

openstack_compute_instance_v2.terraform-test: Destroying... (ID: 2c1537b4-0bfa-4293-a6fb-b708553263f7)
openstack_compute_instance_v2.terraform-test: Still destroying... (ID: 2c1537b4-0bfa-4293-a6fb-b708553263f7, 10s elapsed)
openstack_compute_instance_v2.terraform-test: Destruction complete after 16s

Destroy complete! Resources: 1 destroyed.
```

## Next steps

I have covered the basics on how to use Terraform with Rackspace Cloud, but I did not scratch the surface of what to use Terraform for. Check out [the docs](https://www.terraform.io/docs/index.html) to see the huge amount of things Terraform can manage to increase your productivity, as well as the consistency and reliability of your infrastructure.
