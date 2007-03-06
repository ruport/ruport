if defined? Gem
  require "gem_plugin"
  GemPlugin::Manager.instance.load "ruport" => GemPlugin::INCLUDE
end