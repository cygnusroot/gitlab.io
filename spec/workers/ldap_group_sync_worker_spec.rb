require 'spec_helper'

describe LdapGroupSyncWorker do
  include LdapHelpers
  let(:subject) { described_class.new }
  let(:group) { create(:group) }

  def expect_fake_proxy(provider)
    fake = double
    expect(EE::Gitlab::LDAP::Sync::Proxy)
      .to receive(:open).with(provider).and_yield(fake)
    fake
  end

  before do
    allow(Sidekiq.logger).to receive(:info)
  end

  describe '#perform' do
    it 'syncs a single group when group_id is present' do
      expect(subject).to receive(:sync_groups).with([group])

      subject.perform(group.id)
    end

    it 'creates a proxy for syncing a single provider' do
      fake_proxy = expect_fake_proxy('the-provider')
      expect(subject).to receive(:sync_groups).with([group], proxy: fake_proxy)

      subject.perform(group.id, 'the-provider')
    end
  end

  describe '#sync_groups' do
    it 'syncs a group when it was found without a proxy' do
      expect(subject).to receive(:sync_group).with(group, proxy: nil)

      subject.sync_groups([group])
    end

    it 'syncs with an existing proxy when one was given' do
      fake_proxy = double('proxy')
      expect(subject).to receive(:sync_group).with(group, proxy: fake_proxy)

      subject.sync_groups([group], proxy: fake_proxy)
    end
  end

  describe '#sync_group' do
    it 'syncs a single provider when a provider was given' do
      proxy = EE::Gitlab::LDAP::Sync::Proxy.new('ldapmain', ldap_adapter)

      expect(EE::Gitlab::LDAP::Sync::Group).to receive(:execute)
                                                   .with(group, proxy)

      subject.sync_group(group, proxy: proxy)
    end

    it 'syncs all providers when no proxy was given' do
      expect(EE::Gitlab::LDAP::Sync::Group).to receive(:execute_all_providers)
                                                   .with(group)

      subject.sync_group(group)
    end
  end
end
