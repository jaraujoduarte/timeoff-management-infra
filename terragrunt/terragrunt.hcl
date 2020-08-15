terraform {
  extra_arguments "retry_lock" {
    commands = [
      "init",
      "apply",
      "refresh",
      "import",
      "plan",
      "taint",
      "untaint"
    ]

    arguments = [
      "-lock-timeout=15m"
    ]
  }

  extra_arguments "var_files" {
    commands = [
      "apply",
      "plan",
      "import",
      "push",
      "refresh",
      "destroy"
    ]

    optional_var_files = [
      "${get_parent_terragrunt_dir()}/common.tfvars",
      "${get_parent_terragrunt_dir()}/vars/${get_env("TF_VAR_env", "dev")}.tfvars",
      "${get_terragrunt_dir()}/vars/${get_env("TF_VAR_env", "dev")}.tfvars",
    ]

    # env_vars = {
    #   TF_VAR_branch_name = run_cmd("git rev-parse --abbrev-ref HEAD")
    # }
  }
}

remote_state {
    backend = "s3"
    config = {
        bucket         = "${get_env("TF_VAR_env", "dev")}-gorillatest-jaraujoduarte-tf-state"
        key            = "${path_relative_to_include()}/terraform.tfstate"
        region         = "us-east-1"
        encrypt        = true
        dynamodb_table = "gorillatest-jaraujoduarte"
    }
}

skip = true
