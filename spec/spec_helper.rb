require "fileutils"
require "digest/sha1"
require "tmpdir"
require "tempfile"
require "set"
require "yaml"
require "nats/client"
require "redis"
require "restclient"
require "director"


SPEC_ROOT = File.expand_path(File.dirname(__FILE__))
ASSETS_DIR = File.join(SPEC_ROOT, "assets")
BOSH_ROOT_DIR = File.expand_path File.join(SPEC_ROOT, "..")
BOSH_TMP_DIR = File.expand_path File.join(BOSH_ROOT_DIR, "tmp")

Dir.glob("#{SPEC_ROOT}/support/**/*.rb") do |filename|
  require filename
end

TEST_RELEASE_TEMPLATE = File.join(ASSETS_DIR, "test_release_template")
TEST_RELEASE_DIR = File.join(ASSETS_DIR, "test_release")

CLI_DIR        = File.expand_path("../../../cli", __FILE__)
BOSH_CACHE_DIR = Dir.mktmpdir
BOSH_WORK_DIR  = File.join(ASSETS_DIR, "bosh_work_dir")
BOSH_CONFIG    = File.join(ASSETS_DIR, "bosh_config.yml")

STDOUT.sync = true

module Bosh
  module Spec
    module IntegrationTest
      class CliUsage; end
      class HealthMonitor; end
    end
  end
end

RSpec.configure do |c|
  c.before(:each) do |example|
    cleanup_bosh
    setup_test_release_dir
  end

  c.filter_run :focus => true if ENV["FOCUS"]
end

def spec_asset(name)
  File.expand_path("../assets/#{name}", __FILE__)
end

def yaml_file(name, object)
  f = Tempfile.new(name)
  f.write(Psych.dump(object))
  f.close
  f
end

def director_version
  version = `(git show-ref --head --hash=8 2> /dev/null || echo 00000000)`
  "Ver: #{Bosh::Director::VERSION} (#{version.lines.first.strip})"
end

def setup_test_release_dir
  FileUtils.cp_r(TEST_RELEASE_TEMPLATE, TEST_RELEASE_DIR, :preserve => true)
  Dir.chdir(TEST_RELEASE_DIR) do
    ignore = %w(r
        blobs
        dev-releases
        config/dev.yml
        config/private.yml
        releases/*.tgz
        dev_releases
        .dev_builds
        .final_builds/jobs/**/*.tgz
        .final_builds/packages/**/*.tgz
        blobs
        .blobs
    )
    File.open('.gitignore', 'w+') do |f|
      f.write(ignore.join("\n") + "\n")
    end
    `git init;
     git config user.name "John Doe";
     git config user.email "john.doe@example.org";
     git add .;
     git commit -m "Initial Test Commit"`
  end
end

def cleanup_bosh
  [
   BOSH_CONFIG,
   BOSH_CACHE_DIR,
   TEST_RELEASE_DIR
  ].each do |item|
    FileUtils.rm_rf(item)
  end
end

