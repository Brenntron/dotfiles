class FileReputationDisputeSerializer < ActiveModel::Serializer
  attributes :id, :status, :source, :platform, :descriptio, :file_name, :file_size, :sha256_hash, :sample_type,
             :disposition, :disposition_suggested,
             :sandbox_score, :sandbox_threshold, :sandbox_signer,
             :threatgrid_score, :threatgrid_threshold, :threatgrid_signer,
             :reversing_labs_score, :reversing_labs_signer
end
