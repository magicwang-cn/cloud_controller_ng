require "presenters/message_bus/service_binding_presenter"

module VCAP::CloudController
  module Dea
    class StartAppMessage < Hash
      def initialize(app, index, config, blobstore_url_generator)
        super()

        self[:droplet]        = app.guid
        self[:name]           = app.name
        self[:uris]           = app.uris
        self[:prod]           = app.production
        self[:sha1]           = app.droplet_hash
        self[:executableFile] = "deprecated"
        self[:executableUri]  = blobstore_url_generator.droplet_download_url(app)
        self[:version]        = app.version

        self[:services] = app.service_bindings.map do |sb|
          ServiceBindingPresenter.new(sb).to_hash
        end

        self[:limits] = {
            mem:  app.memory,
            disk: app.disk_quota,
            fds:  app.file_descriptors
        }

        staging_env = EnvironmentVariableGroup.running.environment_json
        app_env     = app.environment_json || {}
        env         = staging_env.merge(app_env).map { |k, v| "#{k}=#{v}" }
        self[:env]  = env

        self[:cc_partition]         = config[:cc_partition]
        self[:console]              = app.console
        self[:debug]                = app.debug
        self[:start_command]        = app.command
        self[:health_check_timeout] = app.health_check_timeout
        self[:vcap_application]     = app.vcap_application
        self[:index]                = index
        self[:egress_network_rules] = EgressNetworkRulesPresenter.new(app.space.security_groups).to_array
      end

      def has_app_package?
        return !self[:executableUri].nil?
      end
    end
  end
end
