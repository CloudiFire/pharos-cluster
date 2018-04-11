# frozen_string_literal: true

autoload :Kubeclient, 'kubeclient'
autoload :Base64, 'base64'
autoload :SecureRandom, 'securerandom'
autoload :YAML, 'yaml'
autoload :RestClient, 'rest-client'
autoload :Pastel, 'pastel'
autoload :Logger, 'logger'

module Pharos
  autoload :Types, 'pharos/types'
  autoload :Config, 'pharos/config'
  autoload :ConfigSchema, 'pharos/config_schema'
  autoload :Kube, 'pharos/kube'
  autoload :YamlFile, 'pharos/yaml_file'
  autoload :Addon, 'pharos/addon'
  autoload :AddonManager, 'pharos/addon_manager'
  autoload :Phase, 'pharos/phase'
  autoload :Phases, 'pharos/phases'
  autoload :PhaseManager, 'pharos/phase_manager'
  autoload :Logging, 'pharos/logging'
  autoload :ClusterManager, 'pharos/cluster_manager'

  module SSH
    autoload :Client, 'pharos/ssh/client'
    autoload :Manager, 'pharos/ssh/manager'
    autoload :RemoteCommand, 'pharos/ssh/remote_command'
    autoload :RemoteFile, 'pharos/ssh/remote_file'
    autoload :Tempfile, 'pharos/ssh/tempfile'
  end

  module Terraform
    autoload :JsonParser, 'pharos/terraform/json_parser'
  end

  module Addons
  end

  module Phases
  end

  module Configuration
    autoload :Host, 'pharos/configuration/host'
  end
end