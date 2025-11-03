# Terraform Cato Bulk WAN Network Rules Module

This module allows you to bulk import WAN Network (WNW) rules and sections from a JSON configuration file, and define the order of those rules and sections within the Cato policy.

## Usage

The module reads a JSON configuration file that defines:
- **Rules**: Individual WAN Network rules with their configurations
- **Sections**: Logical groupings for organizing rules
- **Rule ordering**: Defines which rules belong to which sections and their order within sections

### Basic Example

```hcl
module "bulk_wnw_rules" {
  source = "catonetworks/bulk-wnw-rules/cato"
  
  wnw_rules_json_file_path = "./config_data/all_wnw_rules_and_sections_simple_working.json"
  section_to_start_after_id = "existing-section-id" # Optional
}
```

### JSON Configuration Structure

The JSON file should contain a nested structure with the following key components:

- `data.policy.wanNetwork.policy.rules[]` - Array of WAN Network rules
- `data.policy.wanNetwork.policy.sections[]` - Array of sections with index and name
- `data.policy.wanNetwork.policy.rules_in_sections[]` - Mapping of rules to sections with ordering

#### Key Fields:

**Rules Array**: Each rule contains standard WNW rule properties like name, description, enabled status, rule type, route type, source, destination, application, configuration settings, bandwidth priority, and exceptions.

**Sections Array**: Defines sections with:
- `section_index`: The order of the section in the policy
- `section_name`: The display name of the section

**Rules in Sections Array**: Maps rules to sections with:
- `index_in_section`: The order of the rule within its section
- `section_name`: The section this rule belongs to
- `rule_name`: The name of the rule to place in the section

### How Rule Ordering Works

Based on the example:
1. **Section 11** ("My WNW Section 11") is created first
2. **Section 22** ("My WNW Section 22") is created second
3. **Rule 11** is placed in Section 11 at position 1
4. **Rule 33** is placed in Section 22 at position 1
5. **Rule 22** is placed in Section 22 at position 2

The final policy structure will be:
```
├── My WNW Section 11
│   └── My WNW Rule 11
└── My WNW Section 22
    ├── My WNW Rule 33
    └── My WNW Rule 22
```

### Parameters

- `wnw_rules_json_file_path`: Path to your JSON configuration file
- `section_to_start_after_id`: (Optional) ID of an existing section after which to insert the new sections

<details>
<summary>Click to expand full JSON configuration example</summary>

```json
{
  "data": {
    "policy": {
      "wanNetwork": {
        "policy": {
          "enabled": true,
          "rules": [
            {
              "rule": {
                "name": "My WNW Rule 11",
                "description": "My WNW Rule 1",
                "enabled": true,
                "ruleType": "WAN",
                "routeType": "NONE",
                "source": {},
                "destination": {},
                "application": {},
                "configuration": {
                  "activeTcpAcceleration": false,
                  "packetLossMitigation": false,
                  "preserveSourcePort": false,
                  "allocationIp": [],
                  "backhaulingSite": [],
                  "popLocation": []
                },
                "bandwidthPriority": {
                  "name": "255"
                }
              }
            },
            {
              "rule": {
                "name": "My WNW Rule 22",
                "description": "My WNW Rule 2",
                "enabled": true,
                "ruleType": "INTERNET",
                "source": {},
                "destination": {},
                "application": {},
                "configuration": {
                  "activeTcpAcceleration": false,
                  "packetLossMitigation": false,
                  "preserveSourcePort": false,
                  "allocationIp": [],
                  "backhaulingSite": [],
                  "popLocation": []
                },
                "bandwidthPriority": {
                  "name": "255"
                }
              }
            },
            {
              "rule": {
                "name": "My WNW Rule 33",
                "description": "My WNW Rule 3",
                "enabled": true,
                "ruleType": "WAN",
                "routeType": "NONE",
                "source": {},
                "destination": {},
                "application": {},
                "configuration": {
                  "activeTcpAcceleration": false,
                  "packetLossMitigation": false,
                  "preserveSourcePort": false,
                  "allocationIp": [],
                  "backhaulingSite": [],
                  "popLocation": []
                },
                "bandwidthPriority": {
                  "name": "255"
                }
              }
            }
          ],
          "sections": [
            {
              "section_index": 1,
              "section_name": "My WNW Section 11"
            },
            {
              "section_index": 2,
              "section_name": "My WNW Section 22"
            }
          ],
          "rules_in_sections": [
            {
              "index_in_section": 1,
              "section_name": "My WNW Section 11",
              "rule_name": "My WNW Rule 11"
            },
            {
              "index_in_section": 2,
              "section_name": "My WNW Section 22",
              "rule_name": "My WNW Rule 22"
            },
            {
              "index_in_section": 1,
              "section_name": "My WNW Section 22",
              "rule_name": "My WNW Rule 33"
            }
          ]
        }
      }
    }
  }
}
```
</details>

## Working with Existing Rules (Brownfield Deployments)

For brownfield deployments where you have existing WAN Network rules in your Cato Management Application, you can use the Cato CLI to export and import these rules into Terraform state.

### Installing and Configuring Cato CLI

1. **Install the Cato CLI:**
   ```bash
   pip3 install catocli
   ```

2. **Configure the CLI with your Cato credentials:**
   ```bash
   catocli configure set
   ```
   This will prompt you for your Cato Management Application credentials and account information.

### Exporting Existing Rules

To export your existing WAN Network rules and sections into the JSON format required by this module:

```bash
catocli export wnw_rules
```

This command will generate a JSON file containing all your existing WNW rules and sections in the correct format for this Terraform module.

### Importing Rules into Terraform State

Once you have the JSON configuration file, you can import the existing rules and sections into Terraform state. This is useful for:

- **Brownfield deployments**: Managing existing rules with Terraform
- **Backup and restore**: Restoring rules to a known good state after unintended changes
- **State management**: Bringing existing infrastructure under Terraform control

To import the rules into Terraform state:

```bash
catocli import wnw_rules_to_tf config_data/all_wnw_rules_and_sections_simple_working.json --module-name=module.wnw_rules
```

**Parameters:**
- `config_data/all_wnw_rules_and_sections_simple_working.json`: Path to your exported JSON file
- `--module-name=module.wnw_rules`: The name of your Terraform module instance

### Typical Brownfield Workflow

1. **Export existing rules:**
   ```bash
   catocli export wnw_rules
   ```

2. **Create your Terraform configuration:**
   ```hcl
   module "wnw_rules" {
     source = "./terraform-cato-bulk-wnw-rules"
     
     wnw_rules_json_file_path = "./config_data/all_wnw_rules_and_sections_simple_working.json"
   }
   ```

3. **Import existing state:**
   ```bash
   catocli import wnw_rules_to_tf config_data/all_wnw_rules_and_sections_simple_working.json --module-name=module.wnw_rules
   ```

4. **Run Terraform plan to verify:**
   ```bash
   terraform plan
   ```
   This should show no changes if the import was successful.

### Backup and Restore Workflow

If unintended changes are made directly to rules and sections in the Cato Management Application, you can restore to the last known good state:

1. **Apply your last known good configuration:**
    ```bash
    terraform apply
    ```
    This will restore rules and sections to match your Terraform configuration.

2. **Alternatively, re-export and compare:**

    ```bash
    catocli export wnw_rules
    ```

## Compare with your existing JSON file to identify changes
   

## Using Module Outputs

The module provides comprehensive outputs that can be used for monitoring, auditing, integration with other systems, and operational insights. Below are practical examples of how to use these outputs in your Terraform configuration.

<details>
<summary>Click to expand example client-side outputs</summary>

```hcl
# Basic deployment information
output "deployment_info" {
  description = "Basic information about the WAN Network deployment"
  value = {
    total_sections = module.wnw_rules.deployment_summary.total_sections_created
    total_rules    = module.wnw_rules.deployment_summary.total_rules_created
    enabled_rules  = module.wnw_rules.deployment_summary.enabled_rules_count
    disabled_rules = module.wnw_rules.deployment_summary.disabled_rules_count
    source_file    = module.wnw_rules.parsed_configuration.source_file_path
  }
}

# Quick reference for rule and section IDs
output "quick_reference" {
  description = "Quick reference maps for rules and sections"
  value = {
    section_ids = module.wnw_rules.section_ids
    rule_ids    = module.wnw_rules.rule_ids
  }
}

# Network policy overview
output "network_policy_overview" {
  description = "Overview of the network policy configuration"
  value = {
    wan_rules_count      = module.wnw_rules.deployment_summary.wan_rules_count
    internet_rules_count = module.wnw_rules.deployment_summary.internet_rules_count
    wan_rules            = module.wnw_rules.wan_rules
    internet_rules       = module.wnw_rules.internet_rules
    disabled_rules       = module.wnw_rules.disabled_rules
  }
}

# Rule type analysis
output "rule_type_analysis" {
  description = "Analysis of rules by type (WAN, INTERNET)"
  value = {
    rules_by_type = module.wnw_rules.rules_by_type
    type_counts = {
      wan_rules      = length(module.wnw_rules.rules_by_type.WAN)
      internet_rules = length(module.wnw_rules.rules_by_type.INTERNET)
    }
  }
}

# Detailed section structure
output "section_structure" {
  description = "Detailed view of how rules are organized in sections"
  value       = module.wnw_rules.sections_to_rules_mapping
}

# Bulk move operation details
output "bulk_move_details" {
  description = "Details about the bulk move operation that organized the rules"
  value       = module.wnw_rules.bulk_move_operation
}

# Configuration validation
output "configuration_validation" {
  description = "Validation information about the parsed configuration"
  value = {
    source_file           = module.wnw_rules.parsed_configuration.source_file_path
    rules_in_json         = module.wnw_rules.parsed_configuration.rules_data_count
    sections_in_json      = module.wnw_rules.parsed_configuration.sections_data_count
    rule_mappings_in_json = module.wnw_rules.parsed_configuration.rules_mapping_count
    section_order         = module.wnw_rules.parsed_configuration.section_names_ordered
    rules_created         = module.wnw_rules.deployment_summary.total_rules_created
    sections_created      = module.wnw_rules.deployment_summary.total_sections_created
  }
}

# Example: Filtered outputs for specific use cases
output "critical_rules" {
  description = "Example of filtering rules for WAN-specific routing rules"
  value = {
    wan_rule_names = module.wnw_rules.wan_rules
    wan_rule_count = length(module.wnw_rules.wan_rules)
    wan_rule_ids   = [for rule_name in module.wnw_rules.wan_rules : module.wnw_rules.rule_ids[rule_name]]
  }
}

# Example: Rules that might need attention
output "rules_needing_attention" {
  description = "Example of identifying rules that might need attention"
  value = {
    disabled_rules       = module.wnw_rules.disabled_rules
    disabled_rules_count = length(module.wnw_rules.disabled_rules)
    disabled_rule_ids    = [for rule_name in module.wnw_rules.disabled_rules : module.wnw_rules.rule_ids[rule_name]]
  }
}

# Example: Rule type-specific analysis
output "wan_routing_analysis" {
  description = "Analysis of WAN routing rules"
  value = {
    wan_rules       = module.wnw_rules.rules_by_type.WAN
    wan_rules_count = length(module.wnw_rules.rules_by_type.WAN)
    wan_rule_ids = {
      for rule_name in module.wnw_rules.rules_by_type.WAN :
      rule_name => module.wnw_rules.rule_ids[rule_name]
    }
  }
}

# Example: Section-specific information
output "section_details" {
  description = "Example of extracting detailed information about sections"
  value = {
    section_names = module.wnw_rules.section_names
    sections_with_rule_counts = {
      for section_name, section_data in module.wnw_rules.sections_to_rules_mapping :
      section_name => {
        section_id = section_data.section_id
        rule_count = length(section_data.rules)
        rule_names = [for rule in section_data.rules : rule.rule_name]
        rule_types = {
          for rule in section_data.rules :
          rule.rule_name => try(module.wnw_rules.rules[rule.rule_name].rule_type, "UNKNOWN")
        }
      }
    }
  }
}

# Example: For integration with monitoring systems
output "monitoring_metrics" {
  description = "Example metrics that could be sent to monitoring systems"
  value = {
    deployment_timestamp      = timestamp()
    total_network_rules       = module.wnw_rules.deployment_summary.total_rules_created
    total_network_sections    = module.wnw_rules.deployment_summary.total_sections_created
    active_network_rules      = module.wnw_rules.deployment_summary.enabled_rules_count
    inactive_network_rules    = module.wnw_rules.deployment_summary.disabled_rules_count
    wan_routing_rules_count   = module.wnw_rules.deployment_summary.wan_rules_count
    internet_rules_count      = module.wnw_rules.deployment_summary.internet_rules_count
    configuration_source      = basename(module.wnw_rules.parsed_configuration.source_file_path)
    bulk_move_operation_data  = module.wnw_rules.bulk_move_operation
  }
}

# Example: For audit and compliance reporting
output "audit_report" {
  description = "Example audit report using module outputs"
  value = {
    deployment_summary = {
      date                = timestamp()
      source_config_file  = module.wnw_rules.parsed_configuration.source_file_path
      sections_deployed   = module.wnw_rules.deployment_summary.total_sections_created
      rules_deployed      = module.wnw_rules.deployment_summary.total_rules_created
      rules_by_status = {
        enabled  = module.wnw_rules.deployment_summary.enabled_rules_count
        disabled = module.wnw_rules.deployment_summary.disabled_rules_count
      }
      rules_by_type = {
        wan      = module.wnw_rules.deployment_summary.wan_rules_count
        internet = module.wnw_rules.deployment_summary.internet_rules_count
      }
    }
    rule_organization = module.wnw_rules.sections_to_rules_mapping
    disabled_rules_list = module.wnw_rules.disabled_rules
    wan_rules_list      = module.wnw_rules.wan_rules
    internet_rules_list = module.wnw_rules.internet_rules
    rule_type_breakdown = module.wnw_rules.rules_by_type
  }
}

# Example: WAN Network-specific analysis
output "wan_network_analysis" {
  description = "WAN Network-specific analysis for compliance and monitoring"
  value = {
    wan_routing = {
      total_wan_rules = length(module.wnw_rules.rules_by_type.WAN)
      enabled_wan_rules = [
        for rule_name in module.wnw_rules.rules_by_type.WAN :
        rule_name if contains(module.wnw_rules.enabled_rules, rule_name)
      ]
      disabled_wan_rules = [
        for rule_name in module.wnw_rules.rules_by_type.WAN :
        rule_name if contains(module.wnw_rules.disabled_rules, rule_name)
      ]
    }
    internet_routing = {
      total_internet_rules = length(module.wnw_rules.rules_by_type.INTERNET)
      enabled_internet_rules = [
        for rule_name in module.wnw_rules.rules_by_type.INTERNET :
        rule_name if contains(module.wnw_rules.enabled_rules, rule_name)
      ]
      disabled_internet_rules = [
        for rule_name in module.wnw_rules.rules_by_type.INTERNET :
        rule_name if contains(module.wnw_rules.disabled_rules, rule_name)
      ]
    }
  }
}
```
</details>

### Output Use Cases

These example outputs demonstrate various practical applications:

- **`deployment_info`**: Quick deployment overview for dashboards
- **`quick_reference`**: ID mappings for referencing resources in other modules
- **`network_policy_overview`**: Network-focused analysis of rule types
- **`rule_type_analysis`**: Understanding WAN vs Internet routing patterns
- **`section_structure`**: Understanding rule organization and hierarchy
- **`bulk_move_details`**: Operational details about the deployment process
- **`configuration_validation`**: Comparing JSON input with actual deployment
- **`critical_rules`**: Filtering for WAN-specific routing rules
- **`rules_needing_attention`**: Identifying disabled rules for review
- **`wan_routing_analysis`**: Analyzing rules for WAN routing
- **`section_details`**: Detailed section analysis with rule counts and types
- **`monitoring_metrics`**: Metrics formatted for monitoring systems with WAN Network-specific counters
- **`audit_report`**: Comprehensive audit trail for compliance with rule type breakdown
- **`wan_network_analysis`**: WAN Network-specific analysis by rule type

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.13 |
| <a name="requirement_cato"></a> [cato](#requirement\_cato) | >= 0.0.51 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_cato"></a> [cato](#provider\_cato) | >= 0.0.51 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [cato_bulk_wnw_move_rule.all_wnw_rules](https://registry.terraform.io/providers/catonetworks/cato/latest/docs/resources/bulk_wnw_move_rule) | resource |
| [cato_wnw_rule.rules](https://registry.terraform.io/providers/catonetworks/cato/latest/docs/resources/wnw_rule) | resource |
| [cato_wnw_section.sections](https://registry.terraform.io/providers/catonetworks/cato/latest/docs/resources/wnw_section) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_section_to_start_after_id"></a> [section\_to\_start\_after\_id](#input\_section\_to\_start\_after\_id) | The ID of the section after which to start adding rules. | `string` | `null` | no |
| <a name="input_wnw_rules_json_file_path"></a> [wnw\_rules\_json\_file\_path](#input\_wnw\_rules\_json\_file\_path) | Path to the json file containing the WAN Network rule data. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bulk_move_operation"></a> [bulk\_move\_operation](#output\_bulk\_move\_operation) | Details of the bulk move operation |
| <a name="output_deployment_summary"></a> [deployment\_summary](#output\_deployment\_summary) | Summary statistics of the deployment |
| <a name="output_disabled_rules"></a> [disabled\_rules](#output\_disabled\_rules) | List of disabled rule names |
| <a name="output_enabled_rules"></a> [enabled\_rules](#output\_enabled\_rules) | List of enabled rule names |
| <a name="output_internet_rules"></a> [internet\_rules](#output\_internet\_rules) | List of rules with INTERNET rule type |
| <a name="output_parsed_configuration"></a> [parsed\_configuration](#output\_parsed\_configuration) | Parsed configuration data from the JSON file |
| <a name="output_rule_ids"></a> [rule\_ids](#output\_rule\_ids) | Map of rule names to their IDs |
| <a name="output_rule_names"></a> [rule\_names](#output\_rule\_names) | List of all created rule names |
| <a name="output_rules"></a> [rules](#output\_rules) | Map of all created WAN Network rules with their details |
| <a name="output_rules_by_type"></a> [rules\_by\_type](#output\_rules\_by\_type) | Rules organized by type |
| <a name="output_rules_to_sections_mapping"></a> [rules\_to\_sections\_mapping](#output\_rules\_to\_sections\_mapping) | Mapping of rules to their assigned sections with ordering |
| <a name="output_section_ids"></a> [section\_ids](#output\_section\_ids) | Map of section names to their IDs |
| <a name="output_section_names"></a> [section\_names](#output\_section\_names) | List of all created section names |
| <a name="output_sections"></a> [sections](#output\_sections) | Map of all created WAN Network sections with their details |
| <a name="output_sections_to_rules_mapping"></a> [sections\_to\_rules\_mapping](#output\_sections\_to\_rules\_mapping) | Mapping of sections to their assigned rules with ordering |
| <a name="output_wan_rules"></a> [wan\_rules](#output\_wan\_rules) | List of rules with WAN rule type |
<!-- END_TF_DOCS -->
