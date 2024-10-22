/* Naming guidelines:
 * - Service categories taken from https://docs.aws.amazon.com/whitepapers/latest/aws-overview/amazon-web-services-cloud-platform.html
 * - Each variable should end with the word "color"
 * - If a service category includes the word "service(s)", exclude it
 * - If some words in the service category title are plural, keep them as plural, e.g., "Developer Tools" is "developer_tools_color"
 * - Do not shorten words, e.g., "Business Applications" is "business_applications_color"
 * - Do not include "and", e.g., "Management and Governance" is "management_governance_color"
 * - Break up service categories when they can stand on their own, e.g., "Security, Identity, and Compliance" has 3 standalone categories
 * - Use acronyms when well known and there's no room for ambiguity, e.g., "cd" could be continuous delivery or content delivery
*/

locals {
  analytics_color               = "purple"
  application_integration_color = "deeppink"
  ar_vr_color                   = "deeppink"
  blockchain_color              = "orange"
  business_application_color    = "red"
  compliance_color              = "orange"
  compute_color                 = "orange"
  containers_color              = "orange"
  content_delivery_color        = "purple"
  cost_management_color         = "green"
  database_color                = "blue"
  developer_tools_color         = "blue"
  end_user_computing_color      = "green"
  front_end_web_color           = "red"
  game_tech_color               = "purple"
  iam_color                     = "red"
  iot_color                     = "green"
  management_governance_color   = "pink"
  media_color                   = "orange"
  migration_transfer_color      = "green"
  ml_color                      = "green"
  mobile_color                  = "red"
  networking_color              = "purple"
  quantum_technologies_color    = "orange"
  robotics_color                = "red"
  satellite_color               = "blue"
  security_color                = "red"
  storage_color                 = "green"
}
