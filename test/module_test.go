package test

import (
	"crypto/tls"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/aws"
	dns_helper "github.com/gruntwork-io/terratest/modules/dns-helper"
	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

func MetricsServerTest(t *testing.T, kubectlOptionsKubeSystem *k8s.KubectlOptions) {
	_, err := k8s.GetServiceE(t, kubectlOptionsKubeSystem, "metrics-server")
	if err != nil {
		t.Errorf("Error failed to get metric-server service: %v\n", err)
	}
}

func ClusterAutoscalerTest(t *testing.T, kubectlOptionsKubeSystem *k8s.KubectlOptions) {
	_, err := k8s.GetServiceE(t, kubectlOptionsKubeSystem, "cluster-autoscaler-aws-cluster-autoscaler")
	if err != nil {
		t.Errorf("Error failed to get cluster-autoscaler service: %v\n", err)
	}
}

func LoadBalancerTest(t *testing.T, kubectlOptionsKubeSystem *k8s.KubectlOptions) {
	_, err := k8s.GetServiceE(t, kubectlOptionsKubeSystem, "aws-load-balancer-webhook-service")
	if err != nil {
		t.Errorf("Error failed to get aws-load-balancer-webhook-service: %v\n", err)
	}
}

func CloudwatchTest(t *testing.T, kubectlOptionsKubeSystem *k8s.KubectlOptions) {
	_, err := k8s.GetServiceE(t, kubectlOptionsKubeSystem, "fluent-bit")
	if err != nil {
		t.Errorf("Error failed to get fluent-bit service: %v\n", err)
	}
}

func NodeTest(t *testing.T, kubectlOptions *k8s.KubectlOptions) {
	nodes, err := k8s.GetReadyNodesE(t, kubectlOptions)
	if err != nil {
		t.Errorf("Error failed to get nodes: %v\n", err)
	}
	require.Equal(t, 4, len(nodes))
}

func Test(t *testing.T) {
	t.Parallel()

	fixtureFolder := "./fixture"

	// At the end of the test, clean up any resources that were created
	defer test_structure.RunTestStage(t, "teardown", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, fixtureFolder)

		kubeConfig := terraform.Output(t, terraformOptions, "kubeconfig")
		file, err := os.CreateTemp(os.TempDir(), "kubeconfig-")
		require.NoError(t, err)
		_, err = file.Write([]byte(kubeConfig))
		require.NoError(t, err)

		kubectlOptions := &k8s.KubectlOptions{ConfigPath: file.Name(), Namespace: "default"}
		k8s.RunKubectl(t, kubectlOptions, "delete", "service/nginx")
		k8s.RunKubectl(t, kubectlOptions, "delete", "service/windows")
		t.Log("Waiting 30s to give time for load balancers to be removed")
		time.Sleep(30 * time.Second)

		terraform.Destroy(t, terraformOptions)
	})

	// Deploy the example
	test_structure.RunTestStage(t, "setup", func() {
		terraformOptions := configureTerraformOptions(t, fixtureFolder)

		// Save the options so later test stages can use them
		test_structure.SaveTerraformOptions(t, fixtureFolder, terraformOptions)

		// This will init and apply the resources and fail the test if there are any errors
		terraform.InitAndApply(t, terraformOptions)
	})

	// Check the VPC and networking
	test_structure.RunTestStage(t, "validate_vpc", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, fixtureFolder)

		// AWS
		awsRegion := terraformOptions.Vars["aws_region"].(string)

		vpcId := terraform.Output(t, terraformOptions, "vpc_id")
		vpc := aws.GetVpcById(t, vpcId, awsRegion)
		require.Equal(t, vpc.Id, vpcId)

		// Subnets
		subnets := aws.GetSubnetsForVpc(t, vpcId, awsRegion)
		//dynamic_subnets should create 1 private and 1 public subnet for each availability zone.
		require.Equal(t, 3*2, len(subnets))

		// public subnet
		publicSubnetIds := terraform.OutputList(t, terraformOptions, "public_subnet_ids")
		require.Equal(t, 3, len(publicSubnetIds))
		for _, subnetId := range publicSubnetIds {
			// Verify if the network that is supposed to be public is really public
			assert.True(t, aws.IsPublicSubnet(t, subnetId, awsRegion))
		}

		// private subnet
		privateSubnetIds := terraform.OutputList(t, terraformOptions, "private_subnet_ids")
		require.Equal(t, 3, len(privateSubnetIds))
		for _, subnetId := range privateSubnetIds {
			// Verify if the network that is supposed to be private is really private
			assert.False(t, aws.IsPublicSubnet(t, subnetId, awsRegion))
		}

	})

	// validate services.
	test_structure.RunTestStage(t, "validate_services", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, fixtureFolder)

		kubeConfig := terraform.Output(t, terraformOptions, "kubeconfig")
		file, err := os.CreateTemp(os.TempDir(), "kubeconfig-")
		require.NoError(t, err)
		//log.Printf(deQuoted)
		_, err = file.Write([]byte(kubeConfig))
		require.NoError(t, err)

		kubectlOptions := &k8s.KubectlOptions{ConfigPath: file.Name(), Namespace: "default"}

		// Check the nodes
		NodeTest(t, kubectlOptions)

		// Check metric-server is running
		kubectlOptionsKubeSystem := &k8s.KubectlOptions{ConfigPath: file.Name(), Namespace: "kube-system"}
		MetricsServerTest(t, kubectlOptionsKubeSystem)

		// test cluster autosclaer is running
		ClusterAutoscalerTest(t, kubectlOptionsKubeSystem)

		// test load balancer is running
		LoadBalancerTest(t, kubectlOptionsKubeSystem)

		// test fluent-bit is running
		kubectlOptionsCloudwatch := &k8s.KubectlOptions{ConfigPath: file.Name(), Namespace: "amazon-cloudwatch"}
		CloudwatchTest(t, kubectlOptionsCloudwatch)

		//Check the linux nginx image is running
		nginx_pods := k8s.ListPods(t, kubectlOptions, metav1.ListOptions{LabelSelector: "app=nginx"})
		for key := range nginx_pods {
			err := k8s.WaitUntilPodAvailableE(t, kubectlOptions, nginx_pods[key].Name, 60, 1*time.Second)
			require.NoError(t, err)
		}
		_, err = k8s.GetServiceE(t, kubectlOptions, "nginx")
		if err != nil {
			t.Errorf("Error failed to get nginx service: %v\n", err)
		}

		windows_pods := k8s.ListPods(t, kubectlOptions, metav1.ListOptions{LabelSelector: "app=windows"})
		for key := range windows_pods {
			err := k8s.WaitUntilPodAvailableE(t, kubectlOptions, windows_pods[key].Name, 60, 1*time.Second)
			require.NoError(t, err)
		}
		_, err = k8s.GetServiceE(t, kubectlOptions, "windows")
		if err != nil {
			t.Errorf("Error failed to get windows service: %v\n", err)
		}
		t.Log("Waiting 120s to give test post time to run liveness checks")
		time.Sleep(120 * time.Second)

		// if the liveness prove fails then the pod restarts. So for this test if restart count is 0 then network policies are working.
		test_netpol_pods := k8s.ListPods(t, kubectlOptions, metav1.ListOptions{LabelSelector: "networkIsolation=no_ingress_egress"})
		for key := range test_netpol_pods {
			require.Zero(t, test_netpol_pods[key].Status.ContainerStatuses[0].RestartCount)
		}

	})

	// Check the Frontend
	test_structure.RunTestStage(t, "validate_frontend", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, fixtureFolder)

		// Frontend
		windows := terraform.Output(t, terraformOptions, "windows")
		windowsHttp := "http://" + windows
		linux := terraform.Output(t, terraformOptions, "linux")
		linuxHttp := "http://" + linux

		// Setup a TLS configuration to submit with the helper, a blank struct is acceptable
		maxRetries := 60
		timeBetweenRetries := 10 * time.Second
		tlsConfig := tls.Config{}

		dnsQuery := dns_helper.DNSQuery{Type: "A", Name: linux}
		_, err := dns_helper.DNSLookupAuthoritativeAllWithRetryE(t, dnsQuery, nil, maxRetries, timeBetweenRetries)
		if err != nil {
			t.Errorf("DNS for %s not propagated in time. Error: %v\n", linux, err)
		}

		dnsQuery = dns_helper.DNSQuery{Type: "A", Name: windows}
		_, err = dns_helper.DNSLookupAuthoritativeAllWithRetryE(t, dnsQuery, nil, maxRetries, timeBetweenRetries)
		if err != nil {
			t.Errorf("DNS for %s not propagated in time. Error: %v\n", windows, err)
		}

		// once dns is propagates the service should ought to be up so don't wait or try as much.
		maxRetries = 10
		timeBetweenRetries = 5 * time.Second

		// Verify that we get back a 200 OK that contains correct text
		http_helper.HttpGetWithRetryWithCustomValidation(t, linuxHttp, &tlsConfig, maxRetries, timeBetweenRetries, func(statusCode int, body string) bool {
			return (statusCode == 200) && strings.Contains(body, "nginx web server is successfully installed")
		})

		// Verify that we get back a 200 OK that contains correct text
		http_helper.HttpGetWithRetryWithCustomValidation(t, windowsHttp, &tlsConfig, maxRetries, timeBetweenRetries, func(statusCode int, body string) bool {
			return (statusCode == 200) && strings.Contains(body, "IIS Windows Server")
		})

	})

}

func configureTerraformOptions(t *testing.T, fixtureFolder string) *terraform.Options {

	// Pick a random AWS region to test in. This helps ensure your code works in all regions.
	//awsRegion := aws.GetRandomStableRegion(t, nil, nil)

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: fixtureFolder,

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"aws_region": "us-east-1",
		},
	}
	return terraformOptions
}
