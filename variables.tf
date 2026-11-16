## Config Data Directory and File Names
variable "wnw_rules_json_file_path" {
  type        = string
  description = "Path to the json file containing the WAN Network rule data."
}

variable "section_to_start_after_id" {
  type        = string
  description = "The ID of the section after which to start adding rules."
  default     = null
}


variable "policy_enabled" {
  description = "Manage the account-level WAN Network policy toggle. null leaves the toggle unmanaged; true/false manages it via cato_wan_network_policy."
  type        = bool
  default     = null
}

variable "allow_empty_policy" {
  type        = bool
  default     = false
  description = "Safety guard: fail planning when the policy JSON contains 0 rules unless explicitly allowed. Protects against a truncated or wrong-tenant export destroying the live policy. Set true only for intentional greenfield/teardown."
}

variable "allocated_ip_id_map" {
  description = "Optional map of SOURCE allocated-IP display names (\"<pop> - <ip>\") to this tenant's allocation IDs. Allocated-IP names embed the Cato-ASSIGNED ip AND the API's by-NAME resolver for AllocatedIp refs is unreliable (by-ID always works) -- the calling folder resolves each allocation by its stable (description, popLocation) identity via the cato_allocatedIp data source and passes the resulting ids here. Empty map = pass refs through unchanged (source-tenant plans)."
  type        = map(string)
  default     = {}
}
