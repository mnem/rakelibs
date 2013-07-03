require 'yaml'
require 'deep_merge'

def load_configuration_with_optional_override main_config, override_config
  main_configuration = {}
  user_configuration = {}

  main_configuration = YAML::load(File.read(main_config)) if File.exists? main_config
  user_configuration = YAML::load(File.read(override_config)) if File.exists? override_config

  main_configuration.deep_merge! user_configuration
end

RAKE_CONFIG = load_configuration_with_optional_override 'rakeconfig.yml', 'rakeconfig.user.yml'
