Facter.add("version_nodejs_installed") do
  setcode do
    Facter::Util::Resolution.exec('/usr/local/node/node-default/bin/node -v 2> /dev/null')
  end
end
