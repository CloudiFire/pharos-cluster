describe "Pharos::Phases::ValidateVersion", if: Pharos.oss? do
  before :all do
    Pharos::Phases.send(:remove_const, :ValidateVersion) if Pharos::Phases.const_defined?(:ValidateVersion)
    load File.expand_path(File.join(__dir__, '../../../lib/pharos/phases/validate_version.rb'))
  end

  let(:host) { Pharos::Configuration::Host.new(address: '192.0.2.1', role: 'master') }
  let(:network_config) { {} }
  let(:config) { Pharos::Config.new(hosts: [host]) }
  let(:ssh) { instance_double(Pharos::Transport::SSH) }
  let(:cluster_context) { Hash.new }
  subject { Pharos::Phases::ValidateVersion.new(host, config: config, cluster_context: cluster_context) }

  before do
    allow(host).to receive(:transport).and_return(ssh)
  end

  describe '#validate_version' do
    it 'allows re-up for stable releases' do
      stub_const('Pharos::VERSION', '1.3.3')
      expect{subject.validate_version('1.3.3')}.not_to change{cluster_context['unsafe_upgrade']}
    end

    it 'allows re-up for development releases' do
      stub_const('Pharos::VERSION', '2.0.0-alpha.1')
      expect{subject.validate_version('2.0.0-alpha.1')}.not_to change{cluster_context['unsafe_upgrade']}
    end

    it 'allows upgrade from patch-release to another' do
      stub_const('Pharos::VERSION', '2.0.1')
      expect{subject.validate_version('2.0.0')}.not_to change{cluster_context['unsafe_upgrade']}
    end

    it 'allows upgrade from patch-release to development patch-release' do
      stub_const('Pharos::VERSION', '2.0.1-alpha.1')
      expect{subject.validate_version('2.0.0')}.not_to change{cluster_context['unsafe_upgrade']}
    end

    it 'does not allow downgrade on development releases' do
      stub_const('Pharos::VERSION', '2.0.0-alpha.1')
      expect{subject.validate_version('2.0.0-alpha.2')}.to raise_error(RuntimeError, /Downgrade/)
    end

    it 'does not allow downgrade on stable releases' do
      stub_const('Pharos::VERSION', '1.3.3')
      expect{subject.validate_version('2.0.0')}.to raise_error(RuntimeError, /Downgrade/)
    end

    it 'does not allow downgrade from stable to prerelease' do
      stub_const('Pharos::VERSION', '2.0.0-alpha.1')
      expect{subject.validate_version('2.0.0')}.to raise_error(RuntimeError, /Downgrade/)
    end

    it 'does not allow downgrade from prerelease to stable' do
      stub_const('Pharos::VERSION', '2.0.0')
      expect{subject.validate_version('2.0.1-alpha.1')}.to raise_error(RuntimeError, /Downgrade/)
    end

    it 'does not allow upgrade to point-release' do
      stub_const('Pharos::VERSION', '2.1.0')
      expect{subject.validate_version('2.0.0')}.to change{cluster_context['unsafe_upgrade']}
    end
  end
end
