# == Schema Information
#
# Table name: emails
#
#  id         :integer          not null, primary key
#  user_id    :integer          not null
#  email      :string(255)      not null
#  created_at :datetime
#  updated_at :datetime
#

class Email < ActiveRecord::Base
  include Sortable

  belongs_to :user

  validates :user_id, presence: true
  validates :email, presence: true, uniqueness: true, email: true
  validate :unique_email, if: ->(email) { email.email_changed? }

  before_validation :cleanup_email

  def cleanup_email
    self.email = self.email.downcase.strip
  end

  def unique_email
    self.errors.add(:email, 'has already been taken') if User.exists?(email: self.email)
  end
end
