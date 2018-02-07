module Geo
  class RepositoryVerificationWorker
    include ApplicationWorker
    include GeoQueue
    include Gitlab::ShellAdapter
    include ExclusiveLeaseGuard
    include Gitlab::Geo::LogHelpers

    BATCH_SIZE    = 1000
    LEASE_TIMEOUT = 60.minutes

    def perform(geo_node_id)
      return unless Gitlab::Geo.geo_database_configured?
      return unless Gitlab::Geo.secondary?

      # Prevent multiple Sidekiq workers from performing verifications
      try_obtain_lease do
        geo_node = GeoNode.find(geo_node_id)

        find_registries_without_checksum.find_in_batches(batch_size: BATCH_SIZE) do |batch|
          batch.each do |registry|
            verify_project(registry)
          end
        end
      end
    rescue ActiveRecord::RecordNotFound => e
      log_error('Could not find Geo node, skipping repository verification', geo_node_id: geo_node_id, error: e)
    end

    def verify_project(registry)
      project = registry.project

      if should_verify_repository?(registry, :repository)
        verify_repository(registry, project.disk_path, project.state&.repository_checksum, :repository)
      end

      if should_verify_repository?(registry, :wiki)
        verify_repository(registry, project.wiki.disk_path, project.state&.wiki_checksum, :wiki)
      end
    end

    def verify_repository(registry, repository, original_checksum, type)
      log_info("Verifying #{type.to_s.capitalize} at #{repository.path}")

      if repository.exists?
        # checksum = repository.calculate_checksum TODO it will probably be this
        checksum = calculate_checksum(repository)

        if checksum != original_checksum
          record_status(registry, type, nil, "#{type.to_s.capitalize} checksum did not match")
        else
          record_status(registry, type, checksum)
        end
      else
        record_status(registry, type, nil, "#{type.to_s.capitalize} was not found")
      end
    end

    private

    # when should we verify?
    # - primary repository has not changed in 6 hours
    # - primary repository was checked after the last repository update
    # - secondary repository was successfully synced after the last repository update
    def should_verify_repository?(registry, type)
      last_checked_at = registry.project.state&.send("last_#{type}_check_at")
      last_successful_sync_at = registry.send("last_#{type}_successful_sync_at")

      registry.project.last_repository_updated_at < 6.hours.ago &&
        !last_checked_at.nil? && last_checked_at > registry.project.last_repository_updated_at &&
        !last_successful_sync_at.nil? && last_successful_sync_at > registry.project.last_repository_updated_at
    end

    def find_registries_without_checksum
      Geo::ProjectRegistry.where('repository_checksum IS NULL')
    end

    def record_status(registry, type, checksum: nil, error: nil)
      attrs = { "#{type}_checksum" => nil, "last_#{type}_verification_at" => nil, "last_#{type}_verification_failure" => nil }

      if checksum
        attrs["#{type}_checksum"] = checksum
        attrs["last_#{type}_verification_at"] = Time.now
      else
        attrs["last_#{type}_verification_failure"] = error
      end

      registry.update!(attrs)
    end

    def lease_timeout
      LEASE_TIMEOUT
    end

    #------------------------------------------------------------------------------

    # TODO temporary for now
    def calculate_checksum(repository)
      repo = Rugged::Repository.new(repository.path)
      repo.references.inject(nil) do |checksum, ref|
        value = Digest::SHA1.hexdigest(ref.target&.oid + ref.name)

        if checksum.nil?
          value
        else
          (checksum.hex ^ value.hex).to_s(16)
        end
      end
    end
  end
end
