class PersonalFileUploader < FileUploader
  store_in_system true

  # Re-Override
  def self.root
    options.storage_path
  end

  def self.base_dir(model)
    File.join(options.base_dir, system_dir, model_path_segment(model))
  end

  def self.model_path_segment(model)
    return 'temp/' unless model

    File.join(model.class.to_s.underscore, model.id.to_s)
  end

  def object_store
    return Store::LOCAL unless model

    super
  end

  # Revert-Override
  def store_dir
    store_dirs[object_store]
  end

  def store_dirs
    {
      Store::LOCAL => File.join(base_dir, dynamic_segment),
      Store::REMOTE => File.join(*[
                                   system_dir,
                                   model_path_segment,
                                   dynamic_segment
                                 ].compact)
    }
  end

  private

  def secure_url
    File.join('/', base_dir, secret, file.filename)
  end
end
