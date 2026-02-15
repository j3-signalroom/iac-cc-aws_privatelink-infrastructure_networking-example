#!/bin/bash

#
# *** Purpose ***
# To create or destroy the infrastructure for the Confluent Cloud Cluster Linking with PrivateLink example.
#
# *** Script Syntax ***
# ./deploy.sh=<create | destroy> --profile=<SSO_PROFILE_NAME>
#                                --confluent-api-key=<CONFLUENT_API_KEY>
#                                --confluent-api-secret=<CONFLUENT_API_SECRET>
#                                --tfe-token=<TFE_TOKEN>
#                                --tgw-id=<TGW_ID>
#                                --tgw-rt-id=<TGW_RT_ID>
#                                --tfc-agent-vpc-id=<TFC_AGENT_VPC_ID>
#                                --tfc-agent-vpc-rt-ids=<TFC_AGENT_VPC_RT_IDs>
#                                --dns-vpc-id=<DNS_VPC_ID>
#                                --dns-vpc-rt-ids=<DNS_VPC_RT_IDs>
#                                --vpn-vpc-id=<VPN_VPC_ID>
#                                --vpn-vpc-rt-ids=<VPN_VPC_RT_IDs>
#                                --vpn-endpoint-id=<VPN_ENDPOINT_ID>
#                                --vpn-target-subnet-ids=<VPN_TARGET_SUBNET_IDs>
#
#


set -euo pipefail  # Stop on error, undefined variables, and pipeline errors

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NO_COLOR='\033[0m'

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NO_COLOR} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NO_COLOR} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NO_COLOR} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NO_COLOR} $1"
}

# Configuration folders
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/terraform"

print_info "Terraform Directory: $TERRAFORM_DIR"

argument_list="--profile=<SSO_PROFILE_NAME> --confluent-api-key=<CONFLUENT_API_KEY> --confluent-api-secret=<CONFLUENT_API_SECRET> --tfe-token=<TFE_TOKEN> --tgw-id=<TGW_ID> --tgw-rt-id=<TGW_RT_ID> --tfc-agent-vpc-id=<TFC_AGENT_VPC_ID> --tfc-agent-vpc-rt-ids=<TFC_AGENT_VPC_RT_IDs> --dns-vpc-id=<DNS_VPC_ID> --dns-vpc-rt-ids=<DNS_VPC_RT_IDs> --vpn-vpc-id=<VPN_VPC_ID> --vpn-vpc-rt-ids=<VPN_VPC_RT_IDs>"

# Check required command (create or destroy) was supplied
case $1 in
  create)
    create_action=true;;
  destroy)
    create_action=false;;
  *)
    echo
    print_error "(Error Message 001)  You did not specify one of the commands: create | destroy."
    echo
    print_error "Usage:  Require all twelve arguments ---> `basename $0`=<create | destroy> $argument_list"
    echo
    exit 85 # Common GNU/Linux Exit Code for 'Interrupted system call should be restarted'
    ;;
esac

# Default required variables
AWS_PROFILE=""
confluent_api_key=""
confluent_api_secret=""
tfe_token=""
tgw_id=""
tgw_rt_id=""
tfc_agent_vpc_id=""
tfc_agent_vpc_rt_ids=""
dns_vpc_id=""
dns_vpc_rt_ids=""
vpn_vpc_id=""
vpn_vpc_rt_ids=""
vpn_endpoint_id=""
vpn_target_subnet_ids=""


# Get the arguments passed by shift to remove the first word
# then iterate over the rest of the arguments
shift
for arg in "$@" # $@ sees arguments as separate words
do
    case $arg in
        *"--profile="*)
            AWS_PROFILE=$arg;;
        *"--confluent-api-key="*)
            arg_length=20
            confluent_api_key=${arg:$arg_length:$(expr ${#arg} - $arg_length)};;
        *"--confluent-api-secret="*)
            arg_length=23
            confluent_api_secret=${arg:$arg_length:$(expr ${#arg} - $arg_length)};;
        *"--tfe-token="*)
            arg_length=12
            tfe_token=${arg:$arg_length:$(expr ${#arg} - $arg_length)};;
        *"--tgw-id="*)
            arg_length=9
            tgw_id=${arg:$arg_length:$(expr ${#arg} - $arg_length)};;
        *"--tgw-rt-id="*)
            arg_length=12
            tgw_rt_id=${arg:$arg_length:$(expr ${#arg} - $arg_length)};;
        *"--tfc-agent-vpc-id="*)
            arg_length=19
            tfc_agent_vpc_id=${arg:$arg_length:$(expr ${#arg} - $arg_length)};;
        *"--dns-vpc-id="*)
            arg_length=13
            dns_vpc_id=${arg:$arg_length:$(expr ${#arg} - $arg_length)};;
        *"--vpn-vpc-id="*)
            arg_length=13
            vpn_vpc_id=${arg:$arg_length:$(expr ${#arg} - $arg_length)};;
        *"--tfc-agent-vpc-rt-ids="*)
            arg_length=23
            tfc_agent_vpc_rt_ids=${arg:$arg_length:$(expr ${#arg} - $arg_length)};;
        *"--dns-vpc-rt-ids="*)
            arg_length=17
            dns_vpc_rt_ids=${arg:$arg_length:$(expr ${#arg} - $arg_length)};;
        *"--vpn-vpc-rt-ids="*)
            arg_length=17
            vpn_vpc_rt_ids=${arg:$arg_length:$(expr ${#arg} - $arg_length)};;
        *"--vpn-endpoint-id="*)
            arg_length=18
            vpn_endpoint_id=${arg:$arg_length:$(expr ${#arg} - $arg_length)};;
        *"--vpn-target-subnet-ids="*)
            arg_length=24
            vpn_target_subnet_ids=${arg:$arg_length:$(expr ${#arg} - $arg_length)};;
    esac
done

# Check required --profile argument was supplied
if [ -z "$AWS_PROFILE" ]
then
    echo
    print_error "(Error Message 002)  You did not include the proper use of the --profile=<SSO_PROFILE_NAME> argument in the call."
    echo
    print_error "Usage:  Require all twelve arguments ---> `basename $0 $1` $argument_list"
    echo
    exit 85 # Common GNU/Linux Exit Code for 'Interrupted system call should be restarted'
fi

# Check required --confluent-api-key argument was supplied
if [ -z "$confluent_api_key" ]
then
    echo
    print_error "(Error Message 003)  You did not include the proper use of the --confluent-api-key=<CONFLUENT_API_KEY> argument in the call."
    echo
    print_error "Usage:  Require all twelve arguments ---> `basename $0 $1` $argument_list"
    echo
    exit 85 # Common GNU/Linux Exit Code for 'Interrupted system call should be restarted'
fi

# Check required --confluent-api-secret argument was supplied
if [ -z "$confluent_api_secret" ]
then
    echo
    print_error "(Error Message 004)  You did not include the proper use of the --confluent-api-secret=<CONFLUENT_API_SECRET> argument in the call."
    echo
    print_error "Usage:  Require all twelve arguments ---> `basename $0 $1` $argument_list"
    echo
    exit 85 # Common GNU/Linux Exit Code for 'Interrupted system call should be restarted'
fi

# Check required --tfe-token argument was supplied
if [ -z "$tfe_token" ]
then
    echo
    print_error "(Error Message 005)  You did not include the proper use of the --tfe-token=<TFE_TOKEN> argument in the call."
    echo
    print_error "Usage:  Require all twelve arguments ---> `basename $0 $1` $argument_list"
    echo
    exit 85 # Common GNU/Linux Exit Code for 'Interrupted system call should be restarted'
fi

# Check required --tgw-id argument was supplied
if [ -z "$tgw_id" ]
then
    echo
    print_error "(Error Message 006)  You did not include the proper use of the --tgw-id=<TGW_ID> argument in the call."
    echo
    print_error "Usage:  Require all twelve arguments ---> `basename $0 $1` $argument_list"
    echo
    exit 85 # Common GNU/Linux Exit Code for 'Interrupted system call should be restarted'
fi

# Check required --tgw-rt-id argument was supplied
if [ -z "$tgw_rt_id" ]
then
    echo
    print_error "(Error Message 007)  You did not include the proper use of the --tgw-rt-id=<TGW_RT_ID> argument in the call."
    echo
    print_error "Usage:  Require all twelve arguments ---> `basename $0 $1` $argument_list"
    echo
    exit 85 # Common GNU/Linux Exit Code for 'Interrupted system call should be restarted'
fi

# Check required --tfc-agent-vpc-id argument was supplied
if [ -z "$tfc_agent_vpc_id" ]
then
    echo
    print_error "(Error Message 008)  You did not include the proper use of the --tfc-agent-vpc-id=<TFC_AGENT_VPC_ID> argument in the call."
    echo
    print_error "Usage:  Require all twelve arguments ---> `basename $0 $1` $argument_list"
    echo
    exit 85 # Common GNU/Linux Exit Code for 'Interrupted system call should be restarted'
fi

# Check required --dns-vpc-id argument was supplied
if [ -z "$dns_vpc_id" ]
then
    echo
    print_error "(Error Message 009)  You did not include the proper use of the --dns-vpc-id=<DNS_VPC_ID> argument in the call."
    echo
    print_error "Usage:  Require all twelve arguments ---> `basename $0 $1` $argument_list"
    echo
    exit 85 # Common GNU/Linux Exit Code for 'Interrupted system call should be restarted'
fi

# Check required --vpn-vpc-id argument was supplied
if [ -z "$vpn_vpc_id" ]
then
    echo
    print_error "(Error Message 010)  You did not include the proper use of the --vpn-vpc-id=<VPN_VPC_ID> argument in the call."
    echo
    print_error "Usage:  Require all twelve arguments ---> `basename $0 $1` $argument_list"
    echo
    exit 85 # Common GNU/Linux Exit Code for 'Interrupted system call should be restarted'
fi

# Check required --tfc-agent-vpc-rt-ids argument was supplied
if [ -z "$tfc_agent_vpc_rt_ids" ]
then
    echo
    print_error "(Error Message 011)  You did not include the proper use of the --tfc-agent-vpc-rt-ids=<TFC_AGENT_VPC_RT_IDs> argument in the call."
    echo
    print_error "Usage:  Require all twelve arguments ---> `basename $0 $1` $argument_list"
    echo
    exit 85 # Common GNU/Linux Exit Code for 'Interrupted system call should be restarted'
fi

# Check required --dns-vpc-rt-ids argument was supplied
if [ -z "$dns_vpc_rt_ids" ]
then
    echo
    print_error "(Error Message 012)  You did not include the proper use of the --dns-vpc-rt-ids=<DNS_VPC_RT_IDs> argument in the call."
    echo
    print_error "Usage:  Require all twelve arguments ---> `basename $0 $1` $argument_list"
    echo
    exit 85 # Common GNU/Linux Exit Code for 'Interrupted system call should be restarted'
fi

# Check required --vpn-vpc-rt-ids argument was supplied
if [ -z "$vpn_vpc_rt_ids" ]
then
    echo
    print_error "(Error Message 013)  You did not include the proper use of the --vpn-vpc-rt-ids=<VPN_VPC_RT_IDs> argument in the call."
    echo
    print_error "Usage:  Require all twelve arguments ---> `basename $0 $1` $argument_list"
    echo
    exit 85 # Common GNU/Linux Exit Code for 'Interrupted system call should be restarted'
fi

# Check required --vpn-endpoint-id argument was supplied
if [ -z "$vpn_endpoint_id" ]
then
    echo
    print_error "(Error Message 014)  You did not include the proper use of the --vpn-endpoint-id=<VPN_ENDPOINT_ID> argument in the call."
    echo
    print_error "Usage:  Require all twelve arguments ---> `basename $0 $1` $argument_list"
    echo
    exit 85 # Common GNU/Linux Exit Code for 'Interrupted system call should be restarted'
fi

# Check required --vpn-target-subnet-ids argument was supplied
if [ -z "$vpn_target_subnet_ids" ]
then
    echo
    print_error "(Error Message 015)  You did not include the proper use of the --vpn-target-subnet-ids=<VPN_TARGET_SUBNET_IDs> argument in the call."
    echo
    print_error "Usage:  Require all twelve arguments ---> `basename $0 $1` $argument_list"
    echo
    exit 85 # Common GNU/Linux Exit Code for 'Interrupted system call should be restarted'
fi


# Get the AWS SSO credential variables that are used by the AWS CLI commands to authenicate
print_step "Authenticating to AWS SSO profile: $AWS_PROFILE..."
aws sso login $AWS_PROFILE
eval $(aws2-wrap $AWS_PROFILE --export)
export AWS_REGION=$(aws configure get region $AWS_PROFILE)

# Confluent Root Path
confluent_secret_root_path=/confluent_cloud_resource/iac-cc-aws_privatelink-cluster_linking-example

# Function to deploy infrastructure
deploy_infrastructure() {
    print_step "Deploying infrastructure with Terraform..."
    
    cd "$TERRAFORM_DIR"
    
    # UNCOMMENT WHEN YOU WANT TO USE A terraform.tfvars FILE INSTEAD OF ENVIRONMENT VARIABLES
    # Create terraform.tfvars file with the required variables
    # printf "aws_region=\"${AWS_REGION}\"\
    # \naws_access_key_id=\"${AWS_ACCESS_KEY_ID}\"\
    # \naws_secret_access_key=\"${AWS_SECRET_ACCESS_KEY}\"\
    # \naws_session_token=\"${AWS_SESSION_TOKEN}\"\
    # \nconfluent_api_key=\"${confluent_api_key}\"\
    # \nconfluent_api_secret=\"${confluent_api_secret}\"\
    # \nconfluent_secret_root_path=\"${confluent_secret_root_path}\"\
    # \ntfe_token=\"${tfe_token}\"\
    # \ndns_vpc_id=\"${dns_vpc_id}\"\
    # \ntfc_agent_vpc_id=\"${tfc_agent_vpc_id}\"\
    # \nvpn_vpc_id=\"${vpn_vpc_id}\"\
    # \ntfc_agent_vpc_rt_ids=${tfc_agent_vpc_rt_ids}\
    # \ndns_vpc_rt_ids=${dns_vpc_rt_ids}\
    # \nvpn_vpc_rt_ids=${vpn_vpc_rt_ids}\
    # \nvpn_endpoint_id=\"${vpn_endpoint_id}\"\
    # \nvpn_target_subnet_ids=\"${vpn_target_subnet_ids}\"\
    # \ntgw_id=\"${tgw_id}\"
    # \ntgw_rt_id=\"${tgw_rt_id}\"" > terraform.tfvars

    # Export Terraform variables as environment variables
    export TF_VAR_aws_region="${AWS_REGION}"
    export TF_VAR_aws_access_key_id="${AWS_ACCESS_KEY_ID}"
    export TF_VAR_aws_secret_access_key="${AWS_SECRET_ACCESS_KEY}"
    export TF_VAR_aws_session_token="${AWS_SESSION_TOKEN}"
    export TF_VAR_confluent_api_key="${confluent_api_key}"
    export TF_VAR_confluent_api_secret="${confluent_api_secret}"
    export TF_VAR_confluent_secret_root_path="${confluent_secret_root_path}"
    export TF_VAR_tfe_token="${tfe_token}"
    export TF_VAR_tgw_id="${tgw_id}"
    export TF_VAR_tgw_rt_id="${tgw_rt_id}"
    export TF_VAR_vpn_vpc_id="${vpn_vpc_id}"
    export TF_VAR_dns_vpc_id="${dns_vpc_id}"
    export TF_VAR_tfc_agent_vpc_id="${tfc_agent_vpc_id}"
    export TF_VAR_tfc_agent_vpc_rt_ids=${tfc_agent_vpc_rt_ids}
    export TF_VAR_dns_vpc_rt_ids=${dns_vpc_rt_ids}
    export TF_VAR_vpn_vpc_rt_ids=${vpn_vpc_rt_ids}
    export TF_VAR_vpn_endpoint_id="${vpn_endpoint_id}"
    export TF_VAR_vpn_target_subnet_ids="${vpn_target_subnet_ids}"

    # Initialize Terraform
    print_info "Initializing Terraform..."
    terraform init

    # Plan Terraform
    print_info "Running Terraform plan..."
    terraform plan -out=tfplan -refresh=false > tfplan.out
    
    # Apply Terraform
    read -p "Do you want to apply this plan? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Applying Terraform plan..."

        # Stage 3 Apply: Apply the rest of the infrastructure
        terraform apply tfplan 
        rm tfplan
        print_info "Infrastructure deployed successfully!"

        print_info "Creating the Terraform visualization..."
        terraform graph | dot -Tpng > ../docs/images/terraform-visualization.png
        print_info "Terraform visualization created at: ../docs/images/terraform-visualization.png"
        cd ..
        return 0
    else
        print_warn "Deployment cancelled"
        rm tfplan
        return 1
    fi
}

# Function to undeploy infrastructure
undeploy_infrastructure() {
    print_step "Destroying infrastructure with Terraform..."

    cd "$TERRAFORM_DIR"
    
    # Initialize Terraform if needed
    print_info "Initializing Terraform..."
    terraform init
    
    # Export Terraform variables as environment variables
    export TF_VAR_aws_region="${AWS_REGION}"
    export TF_VAR_aws_access_key_id="${AWS_ACCESS_KEY_ID}"
    export TF_VAR_aws_secret_access_key="${AWS_SECRET_ACCESS_KEY}"
    export TF_VAR_aws_session_token="${AWS_SESSION_TOKEN}"
    export TF_VAR_confluent_api_key="${confluent_api_key}"
    export TF_VAR_confluent_api_secret="${confluent_api_secret}"
    export TF_VAR_confluent_secret_root_path="${confluent_secret_root_path}"
    export TF_VAR_tfe_token="${tfe_token}"
    export TF_VAR_tgw_id="${tgw_id}"
    export TF_VAR_tgw_rt_id="${tgw_rt_id}"
    export TF_VAR_vpn_vpc_id="${vpn_vpc_id}"
    export TF_VAR_dns_vpc_id="${dns_vpc_id}"
    export TF_VAR_tfc_agent_vpc_id="${tfc_agent_vpc_id}"
    export TF_VAR_tfc_agent_vpc_rt_ids=${tfc_agent_vpc_rt_ids}
    export TF_VAR_dns_vpc_rt_ids=${dns_vpc_rt_ids}
    export TF_VAR_vpn_vpc_rt_ids=${vpn_vpc_rt_ids}
    export TF_VAR_vpn_endpoint_id="${vpn_endpoint_id}"
    export TF_VAR_vpn_target_subnet_ids="${vpn_target_subnet_ids}"

    # Destroy
    print_info "Running Terraform destroy..."
    
    # Auto approves the destroy plan without prompting, and destroys based on state only, without
    # trying to refresh data sources
    terraform destroy -auto-approve -refresh=false
    
    print_info "Infrastructure destroyed successfully!"

    print_info "Creating the Terraform visualization..."
    terraform graph | dot -Tpng > ../docs/images/terraform-visualization.png
    print_info "Terraform visualization created at: ../docs/images/terraform-visualization.png"
    cd ..
}   

# Main execution flow
if [ "$create_action" = true ]
then
    deploy_infrastructure
else
    undeploy_infrastructure
    exit 0
fi
