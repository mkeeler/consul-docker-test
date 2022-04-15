variable "prometheus_container_name" {
  type = string
  default = "prometheus"
  description = "The name of the Prometheus container"
}

variable "grafana_container_name" {
  type = string
  default = "grafana"
  description = "The name of the Grafana container"
}

variable "unique_id" {
  type = string
  default = ""
  description = "A unique string to append to the docker resources"
}

variable "prometheus_port_mapping" {
   type = number
   default = 0
   description = "The port to map to the docker host to access prometheus"
}

variable "grafana_port_mapping" {
   type = number
   default = 3000
   description = "The port to map to the docker host to access prometheus"
}

variable "networks" {
  type = list(string)
  default = []
  description = "List of networks to connect the container to"
}

variable "env" {
   type = map(string)
   default = {}
   description = "A map containing environment variables and their values for the containers"
}

variable "prometheus_jobs" {
   type = list(any)
   description = "A list of prometheus job configuration. Each job should include a name, path and targets parameters as a minimum"
   
   validation {
      condition = length(var.prometheus_jobs) > 0
      error_message = "At least one prometheus job must be specified."
   }
   
   validation {
      condition = anytrue([for job in var.prometheus_jobs : !can(toMap(job))])
      error_message = "One or more prometheus jobs are not a map or equivalent."
   }
   
   validation {
      condition = anytrue([for job in var.prometheus_jobs : job["name"] != "" ])
      error_message = "One or more prometheus jobs are missing a 'name' field."
   }
   
   validation {
      condition = anytrue([for job in var.prometheus_jobs : job["path"] != "" ])
      error_message = "One or more prometheus jobs are missing a 'path' field."
   }
   
   // validation {
   //    condition = anytrue([for job in var.prometheus_jobs : !can(tolist(job["targets"]))])
   //    error_message = "One or more prometheus jobs has a 'targets' field that isn't a list or equivalent."
   // }
   
   validation {
      condition = anytrue([for job in var.prometheus_jobs : length(job["targets"]) > 0])
      error_message = "One or more prometheus jobs has an empty 'targets' field."
   }
}