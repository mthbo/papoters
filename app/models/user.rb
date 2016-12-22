class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, omniauth_providers: [:facebook]

  has_many :offers, foreign_key: 'advisor_id', dependent: :destroy
  has_many :client_deals, foreign_key: 'client_id', class_name: 'Deal'
  has_many :pinned_offers, foreign_key: 'client_id', dependent: :destroy
  has_many :advisor_deals, through: :offers, source: :deals
  has_many :messages

  has_attachment :photo, accept: [:jpg, :png, :gif]

  geocoded_by :address
  after_validation :geocode, if: :address_changed?

  def name_anonymous
    "#{first_name} #{last_name.first}."
  end

  def age
    if birth_date
      today = Date.today
      d = Date.new(today.year, birth_date.month, birth_date.day)
      age = d.year - birth_date.year - (d > today ? 1 : 0)
      "#{age} yr"
    end
  end

  def country_name
    country_data = ISO3166::Country[country]
    country_data.translations[I18n.locale.to_s] || country_data.name
  end

  def address_short
    if city && country
      "#{city}, #{country_name}"
    elsif city && !country
      "#{city}"
    elsif !city && country
      "#{country_name}"
    else
      " - "
    end
  end

  def grade
    if advisor_deals_closed.count > 20
      "Guide"
    elsif advisor_deals_closed.count > 10
      "Champion"
    elsif advisor_deals_closed.count > 3
      "Advisor"
    else
      "Papoter"
    end
  end

  def deals
    client_deals + advisor_deals
  end

  def advisor_deals_request
    advisor_deals.where(status: :request)
  end

  def advisor_deals_proposition
    advisor_deals.where(status: :proposition)
  end

  def advisor_deals_open
    advisor_deals.where(status: :open)
  end

  def advisor_deals_closed
    advisor_deals.where(status: :closed)
  end

  def advisor_deals_reviewed
    advisor_deals.where.not(client_review: nil).order(client_review_at: :desc)
  end

  def client_deals_request
    client_deals.where(status: :request)
  end

  def client_deals_proposition
    client_deals.where(status: :proposition)
  end

  def client_deals_open
    client_deals.where(status: :open)
  end

  def client_deals_closed
    client_deals.where(status: :closed)
  end

  def client_deals_reviewed
    client_deals.where.not(client_review: nil).order(advisor_review_at: :desc)
  end

  def deals_request
    advisor_deals_requests + client_deals_requests
  end

  def deals_proposition
    advisor_deals_proposition + client_deals_proposition
  end

  def deals_open
    advisor_deals_open + client_deals_open
  end

  def deals_closed
    advisor_deals_closed + client_deals_closed
  end

  def deals_reviewed
    deals_sorted = (advisor_deals_reviewed + client_deals_reviewed).sort_by do |deal|
      deal.client == self ? deal.advisor_review_at : deal.client_review_at
    end
    deals_sorted.reverse
  end


  def self.find_for_facebook_oauth(auth)
    user_params = auth.to_h.slice(:provider, :uid)
    user_params.merge! auth.info.slice(:email, :first_name, :last_name)
    user_params[:facebook_picture_url] = auth.info.image
    user_params[:token] = auth.credentials.token
    user_params[:token_expiry] = Time.at(auth.credentials.expires_at)

    user = User.where(provider: auth.provider, uid: auth.uid).first
    user ||= User.where(email: auth.info.email).first # User did a regular sign up in the past.
    if user
      user.update(user_params)
    else
      user = User.new(user_params)
      user.password = Devise.friendly_token[0,20]  # Fake password for validation
      user.save
    end

    return user
  end

end
