shared_examples 'geo base sync execution' do
  describe '#execute' do
    let(:project) { build('project')}

    context 'when can acquire exclusive lease' do
      before do
        allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain) { 12345 }
      end

      it 'executes the synchronization' do
        expect(subject).to receive(:sync_repository)

        subject.execute
      end
    end

    context 'when exclusive lease is not acquired' do
      before do
        allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain) { nil }
      end

      it 'is does not execute synchronization' do
        expect(subject).not_to receive(:sync_repository)

        subject.execute
      end
    end
  end
end
