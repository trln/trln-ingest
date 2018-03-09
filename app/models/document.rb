require 'spofford/deepstruct'

# represents a bibliographic record
class Document < ApplicationRecord
  # need to set this explicitly
  self.primary_key = 'id'

  validates :local_id, :owner, :content, :txn, presence: true

  # "transaction" is an ActiveRecord attribute, so we have to call the
  # association something else; 'txn' is short
  belongs_to :txn, class_name: 'Transaction'
end
