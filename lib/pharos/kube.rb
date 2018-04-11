# frozen_string_literal: true

require 'kubeclient'
require 'deep_merge'

module Pharos
  module Kube
    autoload :CertManager, 'pharos/kube/cert_manager'
    autoload :Client, 'pharos/kube/client'

    RESOURCE_LABEL = 'pharos.kontena.io/stack'
    RESOURCE_ANNOTATION = 'pharos.kontena.io/stack-checksum'

    # @param host [String]
    # @return [Kubeclient::Client]
    def self.client(host, version = 'v1')
      @kube_client ||= {}
      unless @kube_client[version]
        config = Kubeclient::Config.read(File.join(Dir.home, ".pharos/#{host}"))
        path_prefix = version == 'v1' ? 'api' : 'apis'
        api_version, api_group = version.split('/').reverse
        @kube_client[version] = Pharos::Kube::Client.new(
          (config.context.api_endpoint + "/#{path_prefix}/#{api_group}"),
          api_version,
          ssl_options: config.context.ssl_options,
          auth_options: config.context.auth_options
        )
      end
      @kube_client[version]
    end

    # @param host [String]
    # @return [Boolean]
    def self.config_exists?(host)
      File.exist?(File.join(Dir.home, ".pharos/#{host}"))
    end

    # @example
    #   resource_path('host-nodes', '*.yml')
    #   => "<PHAROS_DIR>/resources/host-nodes/*.yml"
    # @param path_component [String, ..] extra path components to join to the result
    # @return [String]
    def self.resource_path(*joinables)
      File.join(__dir__, 'resources', *joinables)
    end

    # Returns a list of .yml and .yml.erb pathnames in the stack's resource directory
    # @param stack [String]
    # @return [Array<Pathname>]
    def self.resource_files(stack)
      Pathname.glob(resource_path(stack, '*.{yml,yml.erb}')).sort_by(&:to_s)
    end

    # @param host [Pharos::Configuration::Host]
    # @param stack [String]
    # @param vars [Hash]
    # @return [Array<Kubeclient::Resource>]
    def self.apply_stack(host, stack, vars = {})
      checksum = SecureRandom.hex(16)
      resources = []
      resource_files(stack).each do |file|
        resource = parse_resource_file(file, vars)
        resource.metadata.labels ||= {}
        resource.metadata.annotations ||= {}
        resource.metadata.labels[RESOURCE_LABEL] = stack
        resource.metadata.annotations[RESOURCE_ANNOTATION] = checksum
        apply_resource(host, resource)
        resources << resource
      end
      prune_stack(host, stack, checksum)

      resources
    end

    # @param host [Pharos::Configuration::Host]
    # @param stack [String]
    # @param checksum [String]
    # @return [Array<Kubeclient::Resource>]
    def self.prune_stack(host, stack, checksum)
      pruned = []
      client(host, '').apis.groups.each do |api_group|
        group_client = client(host, api_group.preferredVersion.groupVersion)
        group_client.entities.each do |type, meta|
          next if type.end_with?('_review')
          objects = group_client.get_entities(type, meta.resource_name, label_selector: "#{RESOURCE_LABEL}=#{stack}")
          objects.select { |obj|
            obj.metadata.annotations.nil? || obj.metadata.annotations[RESOURCE_ANNOTATION] != checksum
          }.each { |obj|
            obj.apiVersion = api_group.preferredVersion.groupVersion
            delete_resource(host, obj)
            pruned << obj
          }
        end
      end

      pruned
    end

    # @param host [String]
    # @param resource [Kubeclient::Resource]
    # @return [Kubeclient::Resource]
    def self.apply_resource(host, resource)
      resource_client = client(host, resource.apiVersion)

      begin
        resource_client.update_resource(resource)
      rescue Kubeclient::ResourceNotFoundError
        resource_client.create_resource(resource)
      end
    end

    # @param host [String]
    # @param resource [Kubeclient::Resource]
    # @return [Kubeclient::Resource]
    def self.create_resource(host, resource)
      resource_client = client(host, resource.apiVersion)
      resource_client.create_resource(resource)
    end

    # @param host [String]
    # @param resource [Kubeclient::Resource]
    # @return [Kubeclient::Resource]
    def self.update_resource(host, resource)
      resource_client = client(host, resource.apiVersion)
      resource_client.update_resource(resource)
    end

    # @param host [String]
    # @param resource [Kubeclient::Resource]
    # @return [Kubeclient::Resource]
    def self.get_resource(host, resource)
      resource_client = client(host, resource.apiVersion)
      resource_client.get_resource(resource)
    end

    # @param host [String]
    # @param resource [Kubeclient::Resource]
    # @return [Kubeclient::Resource]
    def self.delete_resource(host, resource)
      resource_client = client(host, resource.apiVersion)
      begin
        if resource.metadata.selfLink
          api_group = resource.metadata.selfLink.split("/")[1]
          resource_path = resource.metadata.selfLink.gsub("/#{api_group}/#{resource.apiVersion}", '')
          resource_client.rest_client[resource_path].delete
        else
          definition = resource_client.entities[underscore_entity(resource.kind.to_s)]
          resource_client.get_entity(definition.resource_name, resource.metadata.name, resource.metadata.namespace)
          resource_client.delete_entity(
            definition.resource_name, resource.metadata.name, resource.metadata.namespace,
            kind: 'DeleteOptions',
            apiVersion: 'v1',
            propagationPolicy: 'Foreground'
          )
        end
      rescue Kubeclient::ResourceNotFoundError
        false
      end
    end

    # @param path [String]
    # @return [Kubeclient::Resource]
    def self.parse_resource_file(path, vars = {})
      Kubeclient::Resource.new(Pharos::YamlFile.new(path).load(vars))
    end

    # @param kind [String]
    # @return [String]
    def self.underscore_entity(kind)
      Kubeclient::ClientMixin.underscore_entity(kind.to_s)
    end
  end
end