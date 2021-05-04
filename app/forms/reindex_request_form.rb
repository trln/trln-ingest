class ReindexRequestForm 
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :commit, :boolean
  attribute :from, :time
  attribute :to, :time
  attribute :institution, :string
  attribute :action, :string

  attr_accessor(
    :from,
    :to,
    :confirm,
    :action,
  )
  attr_reader :institution

  validates :from, presence: true
  validates :to, presence: true
  validate :form_makes_sense

  def initialize(attributes={})
    super
    @from ||= Time.now - 3600
    @to ||= Time.now
    # if this were truly an activemodel instance this would
    # be done by the framework, but here we are
    @from = @from.to_datetime if @from.is_a?(String)
    @to = @to.to_datetime if @to.is_a?(String)

    @action ||=  'reindex'
    
    @commit ||= false
  end

  def institution=(val)
    @institution = val.downcase
  end

  def institution_options
    [ ['Duke', 'duke' ],
      ['NC Central', 'nccu'],
      ['NC State', 'ncsu'],
      ['UNC-Chapel Hill', 'unc']
    ]
  end

  def valid_institution?
    institution.nil? or institution.empty? or %w[duke nccu ncsu unc trln].include?(institution)
  end

  def form_makes_sense
    errors.add(:base, "'from' must be before 'to'") if from >= to
    errors.add(:base, "institution #{institution}' is invalid") unless valid_institution?
    errors.add(:base, "action '#{action}' not understood") unless %w[reindex reingest].include?(action)
    throw(:abort) if errors.any?
  end
end

