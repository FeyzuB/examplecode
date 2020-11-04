class Partnerhub < ActiveRecord::Base

  def self.most_used_services
    PartnerCompanyService.group(:service_id, :service_type).order('count_id DESC').limit(5).count(:id)
  end

  def self.all_used_services
    services = PartnerCompanyService.all.includes(:service).select('DISTINCT ON (partner_company_services.service_id,partner_company_services.service_type) *').order("partner_company_services.service_id")
  end

  def self.all_partners
    companies = Company.where(:partner => true, :closed_at => nil, :temp_closed_at => nil).includes(:seal_assignments, :published_reviews, partner_company: [:live_cases, :company, :partner_company_type, :partner_company_services, partner_company_profile: [:partner_company_profile_snippet]])
    partners = []

    companies.each do |company|
      if !company.partner_company.partner_company_profile.live_at.nil? && !company.partner_company.approved_at.nil?
        temp = {}
        temp[:workspace_id] = company.partner_company.company.id
        temp[:workspace_slug] = company.partner_company.company.slug
        temp[:company_name] = company.partner_company.company.company_name
        temp[:partner_slogan] = company.partner_company.slogan
        temp[:company_logo] = company.partner_company.company.logo.url(:xxl)
        temp[:partner_header] = company.partner_company.partner_company_profile.get_header
        temp[:partner_title] = company.partner_company.partner_company_profile.partner_company_profile_snippet.title
        temp[:partner_intro] = company.partner_company.partner_company_profile.partner_company_profile_snippet.intro
        temp[:partner_type] = company.partner_company.partner_company_type.type_agency
        temp[:partner_services] = company.partner_company.partner_company_services.preload(:service).size
        temp[:partner_members] = company.partner_company.partner_company_profile_users.size
        temp[:reviews] = company.partner_company.get_review_score(company.published_reviews)
        temp[:seal_count] = company.seal_assignments.size
        temp[:case_count] = company.partner_company.live_cases.size
        partners.push(temp)
      end
    end
    partners
  end

  # NOTE: get recommened partners by service
  def self.recommened_partners_by_service(service, service_type)
    case service_type
    when "Category"
      category = Category.find(service)
      category_name = category.cat_name
    when "SubCategory"
      category = SubCategory.find(service)
      category_name = category.sub_name
    when "Platform"
      category = Platform.find(service)
      category_name = category.plat_name
    end

    partners_with_service = category.partner_company_services.includes(partner_company: [:live_cases, :partner_company_certiwards, company: [:published_reviews, :seal_assignments], partner_company_profile: [:partner_company_profile_snippet]]).order(created_at: :desc)
    partners = []

    # NOTE: build here to check if sniippet exists if so toon dat,
    partners_with_service.each do |partner_with_service|
      if !partner_with_service.partner_company.partner_company_profile.live_at.nil? && !partner_with_service.partner_company.approved_at.nil?
        temp = {}
        temp[:service_name] = category_name
        temp[:workspace_id] = partner_with_service.partner_company.company.id
        temp[:workspace_slug] = partner_with_service.partner_company.company.slug
        temp[:company_name] = partner_with_service.partner_company.company.company_name
        temp[:partner_slogan] = partner_with_service.partner_company.slogan
        temp[:company_logo] = partner_with_service.partner_company.company.logo.url(:xxl)
        temp[:certiward_count] = partner_with_service.partner_company.partner_company_certiwards.size
        temp[:minimum_budget] = partner_with_service.partner_company.minimum_budget
        temp[:minimum_budget_hourly] = partner_with_service.partner_company.minimum_budget_hourly
        temp[:partner_availability] = partner_with_service.partner_company.partner_company_availability.available_choice
        temp[:partner_header] = partner_with_service.partner_company.partner_company_profile.get_header
        temp[:partner_title] = partner_with_service.partner_company.partner_company_profile.partner_company_profile_snippet.title
        temp[:partner_intro] = partner_with_service.partner_company.partner_company_profile.partner_company_profile_snippet.intro
        temp[:reviews] = partner_with_service.partner_company.get_review_score(partner_with_service.partner_company.company.published_reviews)
        temp[:seal_count] = partner_with_service.partner_company.company.seal_assignments.size
        temp[:case_count] = partner_with_service.partner_company.live_cases.size
        partners.push(temp)
      end
    end
    partners
  end

  def self.search_partners_by_service(search)
    categories = Category.where("LOWER(categories.cat_name) LIKE LOWER(concat('%', ?, '%'))", search).includes(partner_company_services: [partner_company: [:live_cases, :partner_company_certiwards, :partner_company_type, company: [:published_reviews, :seal_assignments], partner_company_profile: [:partner_company_profile_snippet]]])
    sub_categories = SubCategory.where("LOWER(sub_categories.sub_name) LIKE LOWER(concat('%', ?, '%'))", search).includes(partner_company_services: [partner_company: [:live_cases, :partner_company_certiwards, :partner_company_type, company: [:published_reviews, :seal_assignments], partner_company_profile: [:partner_company_profile_snippet]]])
    sub_platforms = SubPlatform.where("LOWER(sub_platforms.plat_name) LIKE LOWER(concat('%', ?, '%'))", search).includes(partner_company_services: [partner_company: [:live_cases, :partner_company_certiwards, :partner_company_type, company: [:published_reviews, :seal_assignments], partner_company_profile: [:partner_company_profile_snippet]]])
    partners = []

    categories.each do |category|
      category.partner_company_services.each do |partner_company_service|
        if !partner_company_service.partner_company.partner_company_profile.live_at.nil? && !partner_company_service.partner_company.approved_at.nil?
          temp = {}
          temp[:workspace_id] = partner_company_service.partner_company.company.id
          temp[:workspace_slug] = partner_company_service.partner_company.company.slug
          temp[:company_name] = partner_company_service.partner_company.company.company_name
          temp[:partner_slogan] = partner_company_service.partner_company.slogan
          temp[:company_logo] = partner_company_service.partner_company.company.logo.url(:xxl)
          temp[:certiward_count] = partner_company_service.partner_company.partner_company_certiwards.size
          temp[:minimum_budget] = partner_company_service.partner_company.minimum_budget
          temp[:minimum_budget_hourly] = partner_company_service.partner_company.minimum_budget_hourly
          temp[:partner_availability] = partner_company_service.partner_company.partner_company_availability.available_choice
          temp[:partner_type] = partner_company_service.partner_company.partner_company_type.type_agency
          temp[:partner_header] = partner_company_service.partner_company.partner_company_profile.get_header
          temp[:partner_title] = partner_company_service.partner_company.partner_company_profile.partner_company_profile_snippet.title
          temp[:partner_intro] = partner_company_service.partner_company.partner_company_profile.partner_company_profile_snippet.intro
          temp[:reviews] = partner_company_service.partner_company.get_review_score(partner_company_service.partner_company.company.published_reviews)
          temp[:seal_count] = partner_company_service.partner_company.company.seal_assignments.size
          temp[:case_count] = partner_company_service.partner_company.live_cases.size
          partners.push(temp) if partners.select {|k| k[:workspace_id] == partner_company_service.partner_company.company.id}.empty?
        end
      end
    end

    sub_categories.each do |sub_category|
      sub_category.partner_company_services.each do |partner_company_service|
        if !partner_company_service.partner_company.partner_company_profile.live_at.nil? && !partner_company_service.partner_company.approved_at.nil?
          temp = {}
          temp[:workspace_id] = partner_company_service.partner_company.company.id
          temp[:workspace_slug] = partner_company_service.partner_company.company.slug
          temp[:company_name] = partner_company_service.partner_company.company.company_name
          temp[:partner_slogan] = partner_company_service.partner_company.slogan
          temp[:company_logo] = partner_company_service.partner_company.company.logo.url(:xxl)
          temp[:certiward_count] = partner_company_service.partner_company.partner_company_certiwards.size
          temp[:minimum_budget] = partner_company_service.partner_company.minimum_budget
          temp[:minimum_budget_hourly] = partner_company_service.partner_company.minimum_budget_hourly
          temp[:partner_availability] = partner_company_service.partner_company.partner_company_availability.available_choice
          temp[:partner_type] = partner_company_service.partner_company.partner_company_type.type_agency
          temp[:partner_header] = partner_company_service.partner_company.partner_company_profile.get_header
          temp[:partner_title] = partner_company_service.partner_company.partner_company_profile.partner_company_profile_snippet.title
          temp[:partner_intro] = partner_company_service.partner_company.partner_company_profile.partner_company_profile_snippet.intro
          temp[:reviews] = partner_company_service.partner_company.get_review_score(partner_company_service.partner_company.company.published_reviews)
          temp[:seal_count] = partner_company_service.partner_company.company.seal_assignments.size
          temp[:case_count] = partner_company_service.partner_company.live_cases.size
          partners.push(temp) if partners.select {|k| k[:workspace_id] == partner_company_service.partner_company.company.id}.empty?
        end
      end
    end

    sub_platforms.each do |sub_platform|
      sub_platform.partner_company_services.each do |partner_company_service|
        if !partner_company_service.partner_company.partner_company_profile.live_at.nil? && !partner_company_service.partner_company.approved_at.nil?
          temp = {}
          temp[:workspace_id] = partner_company_service.partner_company.company.id
          temp[:workspace_slug] = partner_company_service.partner_company.company.slug
          temp[:company_name] = partner_company_service.partner_company.company.company_name
          temp[:partner_slogan] = partner_company_service.partner_company.slogan
          temp[:company_logo] = partner_company_service.partner_company.company.logo.url(:xxl)
          temp[:certiward_count] = partner_company_service.partner_company.partner_company_certiwards.size
          temp[:minimum_budget] = partner_company_service.partner_company.minimum_budget
          temp[:minimum_budget_hourly] = partner_company_service.partner_company.minimum_budget_hourly
          temp[:partner_availability] = partner_company_service.partner_company.partner_company_availability.available_choice
          temp[:partner_type] = partner_company_service.partner_company.partner_company_type.type_agency
          temp[:partner_header] = partner_company_service.partner_company.partner_company_profile.get_header
          temp[:partner_title] = partner_company_service.partner_company.partner_company_profile.partner_company_profile_snippet.title
          temp[:partner_intro] = partner_company_service.partner_company.partner_company_profile.partner_company_profile_snippet.intro
          temp[:reviews] = partner_company_service.partner_company.get_review_score(partner_company_service.partner_company.company.published_reviews)
          temp[:seal_count] = partner_company_service.partner_company.company.seal_assignments.size
          temp[:case_count] = partner_company_service.partner_company.live_cases.size
          partners.push(temp) if partners.select {|k| k[:workspace_id] == partner_company_service.partner_company.company.id}.empty?
        end
      end
    end

    partners
  end

  def self.search_partners_by_name(search)
    partners_by_name = Company.where(:partner => true, :closed_at => nil, :temp_closed_at => nil).where("LOWER(companies.company_name) LIKE LOWER(concat('%', ?, '%'))", search).includes(:seal_assignments, :published_reviews, partner_company: [:live_cases, :partner_company_availability, :partner_company_certiwards, :partner_company_type, :company, partner_company_profile: [:partner_company_profile_snippet]])
    partners = []

    partners_by_name.each do |partner_by_name|
      if !partner_by_name.partner_company.partner_company_profile.live_at.nil? && !partner_by_name.partner_company.approved_at.nil?
        temp = {}
        temp[:workspace_id] = partner_by_name.partner_company.company.id
        temp[:workspace_slug] = partner_by_name.partner_company.company.slug
        temp[:company_name] = partner_by_name.partner_company.company.company_name
        temp[:partner_slogan] = partner_by_name.partner_company.slogan
        temp[:company_logo] = partner_by_name.partner_company.company.logo.url(:xxl)
        temp[:certiward_count] = partner_by_name.partner_company.partner_company_certiwards.size
        temp[:minimum_budget] = partner_by_name.partner_company.minimum_budget
        temp[:minimum_budget_hourly] = partner_by_name.partner_company.minimum_budget_hourly
        temp[:partner_availability] = partner_by_name.partner_company.partner_company_availability.available_choice
        temp[:partner_type] = partner_by_name.partner_company.partner_company_type.type_agency
        temp[:partner_header] = partner_by_name.partner_company.partner_company_profile.get_header
        temp[:partner_title] = partner_by_name.partner_company.partner_company_profile.partner_company_profile_snippet.title
        temp[:partner_intro] = partner_by_name.partner_company.partner_company_profile.partner_company_profile_snippet.intro
        temp[:reviews] = partner_by_name.partner_company.get_review_score(partner_by_name.partner_company.company.published_reviews)
        temp[:seal_count] = partner_by_name.seal_assignments.size
        temp[:case_count] = partner_by_name.partner_company.live_cases.size
        partners.push(temp) if partners.select {|k| k[:workspace_id] == partner_by_name.partner_company.company.id}.empty?
      end
    end
    partners
  end

  def self.wishlist_companies(wishlist)
    partners = []
    wishlist.each do |ww|
      company = Company.where(:id => ww["partner"].to_i).first
      if !company.nil?
        reviews = Review.published_reviews(company.id, nil)
        temp = {}
        temp[:company_id] = company.id
        temp[:company_slug] = company.slug
        temp[:company_name] = company.company_name
        temp[:company_logo] = company.logo.url(:xxl)
        temp[:scores] = company.partner_company.get_review_score(reviews)
        temp[:review_count] = reviews.size
        partners.push(temp)
      end
    end
    partners
  end
end
