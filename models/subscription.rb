class Subscription
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :subscription_type
  field :initialized, :type => Boolean, :default => false
  field :data, :type => Hash, :default => {}
    
  validate :data_check
  
  validates_presence_of :user_id
  validates_presence_of :subscription_type
  
  # will eventually refer to individual subscription type's validation method
  def data_check
    if data['keyword'].blank?
      errors.add(:base, "Enter a keyword or phrase to subscribe to.")
    end
  end
end