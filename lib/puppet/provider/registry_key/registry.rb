# REMIND: need to support recursive delete of subkeys & values

Puppet::Type.type(:registry_key).provide(:registry) do
  require 'pathname' # JJM WORK_AROUND #14073
  require Pathname.new(__FILE__).dirname.dirname.dirname.expand_path + 'modules/registry/registry_base'
  extend Puppet::Modules::Registry::RegistryBase

  defaultfor :operatingsystem => :windows
  confine    :operatingsystem => :windows

  def self.instances
    hkeys.keys.collect do |hkey|
      new(:provider => :registry, :name => "#{hkey.to_s}")
    end
  end

  def create
    Puppet.debug("create key #{resource[:path]}")
    keypath.hkey.create(keypath.subkey, Win32::Registry::KEY_ALL_ACCESS | keypath.access) {|reg| true }
  end

  def exists?
    Puppet.debug("exists? key #{resource[:path]}")
    !!keypath.hkey.open(keypath.subkey, Win32::Registry::KEY_READ | keypath.access) {|reg| true } rescue false
  end

  def destroy
    Puppet.debug("destroy key #{resource[:path]}")

    raise "Cannot delete root key: #{resource[:path]}" unless keypath.subkey
    reg_delete_key_ex = Win32API.new('advapi32', 'RegDeleteKeyEx', 'LPLL', 'L')

    if reg_delete_key_ex.call(keypath.hkey.hkey, keypath.subkey, keypath.access, 0) != 0
      raise "Failed to delete registry key: #{resource[:path]}"
    end
  end

  def keypath
    @keypath ||= resource.parameter(:path)
  end

  def values
    names = []
    # Only try and get the values for this key if the key itself exists.
    if exists? then
      keypath.hkey.open(keypath.subkey, Win32::Registry::KEY_READ | keypath.access) do |reg|
        reg.each_value do |name, type, data| names << name end
      end
    end
    names
  end
end
