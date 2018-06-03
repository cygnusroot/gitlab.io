module Gitlab
  module Kubernetes
    class ConfigMap
      # TODO: Make this CE compat
      def initialize(name, values = "")
        @name = name
        @values = values
      end

      def generate
        resource = ::Kubeclient::Resource.new
        resource.metadata = metadata
        resource.data = { values: values }
        resource
      end

      # TODO: Make this CE compat
      def config_map_name
        "values-content-configuration-#{name}"
      end

      private

      attr_reader :name, :values

      def metadata
        {
          name: config_map_name,
          namespace: namespace,
          labels: { name: config_map_name }
        }
      end

      def namespace
        Gitlab::Kubernetes::Helm::NAMESPACE
      end
    end
  end
end
