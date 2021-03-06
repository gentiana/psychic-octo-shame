class User < ActiveRecord::Base
  has_many :microposts, dependent: :destroy
  has_many :subscriptions, foreign_key: :follower_id, dependent: :destroy
  has_many :subscribers,   foreign_key: :author_id,
                           class_name: Subscription,  dependent: :destroy
  has_many :followed_users, through: :subscriptions, source: :author
  has_many :followers,      through: :subscribers
  
  EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(?:\.[a-z\d\-]+)*\.[a-z]+\z/i
  validates :name,  presence: true, length: { maximum: 50 }
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: EMAIL_REGEX }
  validates :password, length: { minimum: 6 }
  
  has_secure_password
  
  before_save { email.downcase! }
  before_create :create_remember_token
  
  def feed
    Micropost.from_users_followed_by(self)
  end
  
  def filtered_microposts(phrase)
    if phrase
      microposts.where "LOWER(content) LIKE ?", "%#{phrase.strip.downcase}%"
    else
      microposts
    end
  end
  
  def following?(other_user)
    subscriptions.find_by(author_id: other_user.id)
  end
  
  def follow!(other_user)
    subscriptions.create!(author_id: other_user.id)
  end
  
  def unfollow!(other_user)
    subscriptions.find_by(author_id: other_user.id).destroy
  end
  
  class << self
    def new_remember_token
      SecureRandom.urlsafe_base64
    end
    
    def digest(token)
      Digest::SHA1.hexdigest(token.to_s)
    end
    
    def search(phrase)
      if phrase
        where "LOWER(name) LIKE ?", "%#{phrase.strip.downcase}%"
      else
        all
      end
    end
  end
  
  
  private
  
  def create_remember_token
    self.remember_token = User.digest(User.new_remember_token)
  end
end
