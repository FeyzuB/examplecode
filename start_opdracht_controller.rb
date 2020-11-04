class StartOpdrachtController < FGlobalController
  include Wicked::Wizard

  layout "start_opdracht/layouts/application"
  before_filter :get_workspaces
  before_action :set_steps
  before_action :setup_wizard
  before_action :set_sets_variable

  rescue_from Wicked::Wizard::InvalidStepError do not_found end

  def show
    case step
      when :'welkom-terug'
        if session[:return] == true || session[:ass_token]
          @savedObject = Assignment.find_or_initialize_by(:assignment_code => session[:ass_token])
          @assignment = @savedObject
          session[:client_name] = current_user.user_profile.first_name if current_user
        else
          skip_step
        end
      when :'ingelogd-intro'
        if !current_user.nil?
          @assignment = Assignment.find_or_initialize_by(:assignment_code => session[:ass_token])
          @savedObject = current_user
        else
          skip_step
        end
      when :'ingelogd-opdracht-voor-een'
        @savedObject = Assignment.find_by(:assignment_code => session[:ass_token])
        @assignment = @savedObject
        if session[:ass_token].nil?
          jump_to(:start)
        elsif past_step?(@savedObject.current_step.to_sym)
          jump_to(@savedObject.current_step.to_sym)
        else
          if !current_user.nil?
            if params[:back] == "true"
              if UserCompany.count_owner(current_user.id) <= 1
                @company = UserCompany.get_user_admin_companies(current_user).first
                if session[:midwayLogin] == true
                  @midwayLogin = true
                end
              else
                jump_to(:'ingelogd-intro')
              end
            else
              if UserCompany.count_owner(current_user.id) <= 1
                @company = UserCompany.get_user_admin_companies(current_user).first
                if session[:midwayLogin] == true
                  @midwayLogin = true
                end
              else
                skip_step
              end
            end
          else
            skip_step
          end
        end
      when :'ingelogd-opdracht-voor-meerdere'
        @savedObject = Assignment.find_by(:assignment_code => session[:ass_token])
        @assignment = @savedObject
        if session[:ass_token].nil?
          jump_to(:start)
        elsif past_step?(@savedObject.current_step.to_sym)
          jump_to(@savedObject.current_step.to_sym)
        else
          if !current_user.nil?
            if params[:back] == "true"
              if UserCompany.count_owner(current_user.id) <= 1
                jump_to(:'ingelogd-opdracht-voor-een')
              else
                @companies = UserCompany.get_user_admin_companies(current_user)
                if session[:midwayLogin] == true
                  @midwayLogin = true
                end
              end
            else
              if UserCompany.count_owner(current_user.id) <= 1 && @savedObject.company_id == nil
                jump_to(:dienst)
              elsif UserCompany.count_owner(current_user.id) <= 1 && @savedObject.company.old == true
                jump_to(:'dienst')
              elsif UserCompany.count_owner(current_user.id) <= 1 && @savedObject.company.old == false
                jump_to(:dienst)
              else
                @companies = UserCompany.get_user_admin_companies(current_user)
                if session[:midwayLogin] == true
                  @midwayLogin = true
                end
              end
            end
          else
            skip_step
          end
        end
      when :start
        if !cookies[:"homepage-service"].nil?
          downcase_service = cookies[:"homepage-service"].downcase unless cookies[:"homepage-service"].nil?
          if !Suggestion.where("lower(suggestion) = ?", downcase_service).empty? || !Category.where("lower(cat_name) = ?", downcase_service).empty? || !SubCategory.where("lower(sub_name) = ?", downcase_service).empty? || !SubPlatform.where("lower(plat_name) = ?", downcase_service).empty?
            skip_step
          else
            @savedObject = Assignment.find_or_initialize_by(:assignment_code => session[:ass_token])
            @user_profile = UserProfile.new
          end
        elsif !cookies[:"wishlist"].nil?
          skip_step
        else
          @savedObject = Assignment.find_or_initialize_by(:assignment_code => session[:ass_token])
          @user_profile = UserProfile.new
        end

        @assignment = @savedObject
      when :'start-dienst'
        @savedObject = Assignment.find_or_initialize_by(:assignment_code => session[:ass_token])
        @assignment = @savedObject
        @user_profile = UserProfile.new

        if params[:back] == "true"
          jump_to(:start)
        else
          if cookies[:"homepage-service"].nil?
            skip_step
          else
            @downcase_service = cookies[:"homepage-service"].downcase unless cookies[:"homepage-service"].nil?
            if Suggestion.where("lower(suggestion) = ?", @downcase_service).empty? && Category.where("lower(cat_name) = ?", @downcase_service).empty? && SubCategory.where("lower(sub_name) = ?", @downcase_service).empty? && SubPlatform.where("lower(plat_name) = ?", @downcase_service).empty?
              jump_to(:start)
            end

            skip_step if !cookies[:"homepage-service"].nil? && !cookies[:"wishlist"].nil?
          end
        end
      when :'start-wishlist'
        @savedObject = Assignment.find_or_initialize_by(:assignment_code => session[:ass_token])
        @assignment = @savedObject
        @user_profile = UserProfile.new

        if cookies[:"wishlist"].nil?
          if params[:back] == "true"
            if !cookies[:"homepage-service"].nil?
              jump_to(:'start-dienst')
            else
              jump_to(:start)
            end
          else
            skip_step
          end
        end

        skip_step if !cookies[:"homepage-service"].nil? && !cookies[:"wishlist"].nil?
      when :'start-wishlist-dienst'
        @savedObject = Assignment.find_or_initialize_by(:assignment_code => session[:ass_token])
        @assignment = @savedObject
        @user_profile = UserProfile.new

        if params[:back] == "true"
          if cookies[:wishlist].nil? && cookies[:"homepage-service"].nil?
            jump_to(:start)
          elsif !cookies[:wishlist].nil? && cookies[:"homepage-service"].nil?
            jump_to(:'start-wishlist')
          else
            @downcase_service = cookies[:"homepage-service"].downcase unless cookies[:"homepage-service"].nil?
            if Suggestion.where("lower(suggestion) = ?", @downcase_service).empty? && Category.where("lower(cat_name) = ?", @downcase_service).empty? && SubCategory.where("lower(sub_name) = ?", @downcase_service).empty? && SubPlatform.where("lower(plat_name) = ?", @downcase_service).empty?
              jump_to(:start)
            else
              jump_to(:'start-dienst')
            end
          end
        else
          if !cookies[:"homepage-service"].nil?
            @downcase_service = cookies[:"homepage-service"].downcase unless cookies[:"homepage-service"].nil?

            if Suggestion.where("lower(suggestion) = ?", @downcase_service).empty? && Category.where("lower(cat_name) = ?", @downcase_service).empty? && SubCategory.where("lower(sub_name) = ?", @downcase_service).empty? && SubPlatform.where("lower(plat_name) = ?", @downcase_service).empty?
              jump_to(:start)
            end
          end
          skip_step if cookies[:"homepage-service"].nil? && cookies[:"wishlist"].nil?
        end
      when :dienst
        @assignment = Assignment.find_by(:assignment_code => session[:ass_token])

        if session[:ass_token].nil?
          jump_to(:start)
        elsif past_step?(@assignment.current_step.to_sym)
          jump_to(@assignment.current_step.to_sym)
        else
          if AssignmentMainService.exists?(:assignment_id => @assignment.id)
            @savedObject = AssignmentMainService.find_or_initialize_by(:assignment_id => @assignment.id)
            @secondaireServices = AssignmentSecondaireService.where(:assignment_id => @assignment.id)

            @term = @savedObject.keyword
            gon.chosen_cat = @term_cat = @savedObject.category_id.to_s + "," + @savedObject.sub_category_id.to_s + "," + @savedObject.sub_platform_id.to_s

          elsif UnknownAssignment.exists?(:assignment_id => @assignment.id)
            @unknown_assignment = UnknownAssignment.find_by(:assignment_id => @assignment.id)
            @savedObject = @unknown_assignment.unknown_keyword
            @term = @savedObject.u_keyword
            gon.chosen_cat = ""
          else
            @savedObject = AssignmentMainService.find_or_initialize_by(:assignment_id => @assignment.id)
            unless cookies[:"homepage-service"].nil? || Suggestion.search_by_service(cookies[:"homepage-service"]).empty?
              home_page_term = cookies[:"homepage-service"]
              search_result = Suggestion.search_by_service(cookies[:"homepage-service"])

              index_splitted = search_result[:index].split(",")
              @savedObject = AssignmentMainService.find_or_initialize_by(:assignment_id => @assignment.id, keyword: home_page_term, category_id: index_splitted[0], sub_category_id: index_splitted[1], sub_platform_id: index_splitted[2])
              @secondaireServices = AssignmentSecondaireService.where(:assignment_id => @assignment.id)

              @term = @savedObject.keyword
              gon.chosen_cat = @term_cat = @savedObject.category_id.to_s + "," + @savedObject.sub_category_id.to_s + "," + @savedObject.sub_platform_id.to_s

            else
              @term = ''
              gon.chosen_cat = ""
            end
          end

          if gon.chosen_cat != ""
            if !@savedObject.sub_platform_id.nil?
              if SubPlatform.exists?(:id => @savedObject.sub_platform_id, :show_more => true)
                @additionalServicesPlats = SubPlatform.where(:sub_category_id => @savedObject.sub_category_id).where.not(:id => @savedObject.sub_platform_id)
              end
              @title = SubPlatform.select(:title).find_by(:id => @savedObject.sub_platform_id)
              @sub_title = SubPlatform.select(:sub_title).find_by(:id => @savedObject.sub_platform_id)
            elsif !@savedObject.sub_category_id.nil? && @savedObject.sub_platform_id.nil?
              @additionalServicesPlats = []
              if SubCategory.exists?(:id => @savedObject.sub_category_id, :show_more => true)
                @additionalServicesPlats = SubPlatform.where(:sub_category_id => @savedObject.sub_category_id)
              end
              @title = SubCategory.select(:title).find_by(:id => @savedObject.sub_category_id)
              @sub_title = SubCategory.select(:sub_title).find_by(:id => @savedObject.sub_category_id)
            elsif !@savedObject.category_id.nil? && @savedObject.sub_category_id.nil? && @savedObject.sub_platform_id.nil?
              if Category.exists?(:id => @savedObject.category_id, :show_more => true)
                @additionalServicesSubs = SubCategory.where(:category_id => @savedObject.category_id)
              end
              @title = Category.select(:title).find_by(:id => @savedObject.category_id)
              @sub_title = Category.select(:sub_title).find_by(:id => @savedObject.category_id)
            end

          end

          @categories = Category.all.includes(sub_categories: [:sub_platforms]).order(:cat_name => "ASC")
        end
      when :opdracht
        @savedObject = Assignment.find_by(:assignment_code => session[:ass_token])
        @assignment = @savedObject
        if session[:ass_token].nil?
          jump_to(:start)
        elsif past_step?(@savedObject.current_step.to_sym)
          jump_to(@savedObject.current_step.to_sym)
        else
          @attachments = AssignmentAttachment.where(:assignment_id => @savedObject.id)
          @attachment = AssignmentAttachment.new
          gon.attachments = []
          @attachments.each do |attachment|
            att = {}
            att[:content_type] = attachment.document.content_type
            att[:url] = attachment.document.url(:xl)
            att[:size] = attachment.document.size
            att[:name] = attachment.document_file_name
            gon.attachments.push(att)
          end

        end
      when :'start-datum'
        @savedObject = Assignment.find_by(:assignment_code => session[:ass_token])
        @assignment = @savedObject

        if session[:ass_token].nil?
          jump_to(:start)
        elsif past_step?(@savedObject.current_step.to_sym)
          jump_to(@savedObject.current_step.to_sym)
        else
          if !@savedObject.start_date.nil?
            @start_type = @savedObject.start_date.type_start_date
          end
        end
      when :budget
        @assignment = Assignment.find_by(:assignment_code => session[:ass_token])
        if session[:ass_token].nil?
          jump_to(:start)
        elsif past_step?(@assignment.current_step.to_sym)
          jump_to(@assignment.current_step.to_sym)
        else
          @savedObject = AssignmentBudget.find_or_initialize_by(:assignment_id => @assignment.id)
          @savedObject.build_assignment_budget_hourly if @savedObject.assignment_budget_hourly.nil?
        end
      when :'persoonlijke-informatie'
        @savedObject = Assignment.find_by(:assignment_code => session[:ass_token])
        @assignment = @savedObject
        if session[:ass_token].nil?
          jump_to(:start)
        elsif past_step?(@savedObject.current_step.to_sym)
          jump_to(@savedObject.current_step.to_sym)
        else
          @company = Company.find_or_initialize_by(id: @savedObject.company_id, client: true)
          @company_adress = CompanyAdress.find_by(:company_id => @savedObject.company_id)
          @user = !@savedObject.owner.nil? ? User.find(@savedObject.owner.user_id) : User.new
          @user_profile = @user.user_profile
        end
      when :'ingelogd-persoonlijke-informatie'
        @savedObject = Assignment.find_by(:assignment_code => session[:ass_token])
        @assignment = @savedObject
        if session[:ass_token].nil?
          jump_to(:start)
        elsif past_step?(@savedObject.current_step.to_sym)
          jump_to(@savedObject.current_step.to_sym)
        else
          @company = Company.find_or_initialize_by(id: @savedObject.company_id, client: true)
          @company_adress = CompanyAdress.find_by(:company_id => @savedObject.company_id)
          @user = !@savedObject.owner.nil? ? User.find(@savedObject.owner.user_id) : User.new
          @user_profile = @user.user_profile
        end
    end
    render_wizard
  end

  def update
    case params[:id]
      when "welkom-terug"
        if !params[:assignment].nil? || !params[:return].nil?
          if !params[:assignment].nil?
            returnn = params[:assignment][:return]
          else
            returnn = params[:return]
          end

          @savedObject = Assignment.find_by(:assignment_code => session[:ass_token])
          @assignment = @savedObject
          session[:midwayLogin] = nil
          if returnn == "false"
            if current_user && @savedObject.current_step == "persoonlijke-informatie"
              @savedObject.current_step = "ingelogd-persoonlijke-informatie"
              @savedObject.save
              @savedObject.reload
            end
            jump_to(@savedObject.current_step)
          else

            if current_user
              @savedObject.reset_assignment(current_user.id)
              session[:client_name] = current_user.user_profile.first_name
            else
              @savedObject.reset_assignment(nil)
              session[:client_name] = nil
            end

            @savedObject.reload

            session[:return] = nil
            gon.clear

            jump_to(@savedObject.current_step.to_sym)
          end
        else
          jump_to(:'welkom-terug')
        end
      when "ingelogd-intro"
        role = Role.find_by(:user_role => "beheerder")
        @savedObject = Assignment.find_or_initialize_by(:assignment_code => session[:ass_token])
        @assignment = @savedObject
        @savedObject.user_assignments.build(:user_id => current_user.id, :owner => true, :role_id => role.id, :added_through => "client") if !@savedObject.user_assignments.exists?(:role_id => role.id, :owner => true, :added_through => "client")
        @savedObject.last_completed_step = "ingelogd-intro"

        if UserCompany.count_owner(current_user.id) == 0
          @savedObject.current_step = "type-organisatie"
        elsif UserCompany.count_owner(current_user.id) <= 1
          @savedObject.current_step = "ingelogd-opdracht-voor-een"
        else
          @savedObject.current_step = "ingelogd-opdracht-voor-meerdere"
        end
        @savedObject.save
        Assignment.remove_incomplete_assignments(current_user)

        session[:client_name] = current_user.user_profile.first_name

        if !session[:ass_token]
          session[:ass_token] = @savedObject.assignment_code
        end
      when "ingelogd-opdracht-voor-een"
        role = Role.find_by(:user_role => "beheerder")
        @savedObject = Assignment.find_by(:assignment_code => session[:ass_token])
        @assignment = @savedObject
        @savedObject.user_assignments.build(:user_id => current_user.id, :owner => true, :role_id => role.id, :added_through => "client") if !@savedObject.user_assignments.exists?(:role_id => role.id, :owner => true, :added_through => "client")
        @savedObject.validation_step = "logged_assignment_for_single"
        @company = UserCompany.get_user_admin_companies(current_user).first

        @savedObject.company_id = params[:client_company][:company_id] == "true" ? nil : params[:client_company][:company_id]

        if @savedObject.valid?
          @savedObject.last_completed_step = "ingelogd-opdracht-voor-een" if !future_step?(@savedObject.last_completed_step.to_sym)
          @savedObject.current_step = "dienst"

          if session[:assignment_login]
            if @savedObject.current_step == "persoonlijke-informatie"
              @savedObject.current_step = "ingelogd-persoonlijke-informatie"
            end

            @savedObject.save
            jump_to(@savedObject.current_step.to_sym)
            session[:assignment_login] = nil
          end
        end
      when "ingelogd-opdracht-voor-meerdere"
        role = Role.find_by(:user_role => "beheerder")
        @savedObject = Assignment.find_by(:assignment_code => session[:ass_token])
        @assignment = @savedObject
        @savedObject.user_assignments.build(:user_id => current_user.id, :owner => true, :role_id => role.id, :added_through => "client") if !@savedObject.user_assignments.exists?(:role_id => role.id, :owner => true, :added_through => "client")
        @savedObject.validation_step = "logged_assignment_for_multiple"
        @companies = UserCompany.get_user_admin_companies(current_user)
        teamcaptain_role = Role.find_by(:user_role => "team captain")
        beheerder_role = Role.find_by(:user_role => "beheerder")

        if !params[:client_company].nil?
          client_company_param = params[:client_company][:company]
          if client_company_param == "new_company" || UserCompany.exists?(:company_id => client_company_param, :user_id => current_user.id, :role_id => beheerder_role.id) || UserCompany.exists?(:company_id => client_company_param, :user_id => current_user.id, :role_id => teamcaptain_role.id)
            @savedObject.new_company = client_company_param
          else
            @savedObject.new_company = nil
          end
        else
          @savedObject.new_company = nil
        end

        if @savedObject.valid?
          if @savedObject.new_company != "new_company"
            if @savedObject.company_id != nil
              if @savedObject.company.old == false
                excess_company = Company.find_by(:id => @savedObject.company_id, :old => false)
                excess_user_company = UserCompany.find_by(:user_id => current_user.id, :company_id => @savedObject.company_id)
                @savedObject.company_id = nil
                @savedObject.save
                excess_user_company.destroy if !excess_user_company.nil?
                excess_company.destroy
              end
            end

            @savedObject.company_id = client_company_param.to_i

            @savedObject.last_completed_step = "ingelogd-opdracht-voor-meerdere" if !future_step?(@savedObject.last_completed_step.to_sym)
            @savedObject.current_step = "dienst" unless session[:assignment_login]
          else
            if !@savedObject.company.nil? && @savedObject.company.old == true
              @savedObject.company_id = nil
            end
            @savedObject.last_completed_step = "ingelogd-opdracht-voor-meerdere" if !future_step?(@savedObject.last_completed_step.to_sym)
            @savedObject.current_step = "dienst" unless session[:assignment_login]
          end

          if session[:assignment_login]
            if @savedObject.current_step == "persoonlijke-informatie"
              @savedObject.current_step = "ingelogd-persoonlijke-informatie"
              @savedObject.save
            end
            jump_to(@savedObject.current_step.to_sym)
            session[:assignment_login] = nil
          end

        end
      when "start"
        @savedObject = Assignment.find_or_initialize_by(:assignment_code => session[:ass_token])
        @assignment = @savedObject
        @savedObject.validation_step = "start"

        up = UserProfile.new
        up.full_name = params[:user_profile][:full_name]
        up.full_name_cleanup
        if up.full_name == ""
          @savedObject.user_profile_name = nil
        else
          @savedObject.user_profile_name = up.full_name
        end

        @savedObject.client_email = params[:assignment][:client_email]

        if @savedObject.valid?
          @savedObject.current_step = "dienst"
          @savedObject.last_completed_step = "start" if @savedObject.new_record? || !future_step?(@savedObject.last_completed_step.to_sym)
          session[:client_name] = @savedObject.user_profile_name
          session[:ass_token] = @savedObject.assignment_code if !session[:ass_token]
        end
      when "start-dienst"
        @savedObject = Assignment.find_or_initialize_by(:assignment_code => session[:ass_token])
        @assignment = @savedObject
        @savedObject.validation_step = "start"

        up = UserProfile.new
        up.full_name = params[:user_profile][:full_name]
        up.full_name_cleanup
        if up.full_name == ""
          @savedObject.user_profile_name = nil
        else
          @savedObject.user_profile_name = up.full_name
        end

        @savedObject.client_email = params[:assignment][:client_email]

        if @savedObject.valid?
          @savedObject.current_step = "dienst"
          @savedObject.last_completed_step = "start-dienst" if @savedObject.new_record? || !future_step?(@savedObject.last_completed_step.to_sym)
          session[:client_name] = @savedObject.user_profile_name
          session[:ass_token] = @savedObject.assignment_code if !session[:ass_token]
        end
      when "start-wishlist"
        @savedObject = Assignment.find_or_initialize_by(:assignment_code => session[:ass_token])
        @assignment = @savedObject
        @savedObject.validation_step = "start"

        up = UserProfile.new
        up.full_name = params[:user_profile][:full_name]
        up.full_name_cleanup
        if up.full_name == ""
          @savedObject.user_profile_name = nil
        else
          @savedObject.user_profile_name = up.full_name
        end

        @savedObject.client_email = params[:assignment][:client_email]

        if @savedObject.valid?
          @savedObject.current_step = "dienst"
          @savedObject.last_completed_step = "start-wishlist" if @savedObject.new_record? || !future_step?(@savedObject.last_completed_step.to_sym)
          session[:client_name] = @savedObject.user_profile_name
          session[:ass_token] = @savedObject.assignment_code if !session[:ass_token]
        end
      when "start-wishlist-dienst"
        @savedObject = Assignment.find_or_initialize_by(:assignment_code => session[:ass_token])
        @assignment = @savedObject
        @savedObject.validation_step = "start"

        up = UserProfile.new
        up.full_name = params[:user_profile][:full_name]
        up.full_name_cleanup
        if up.full_name == ""
          @savedObject.user_profile_name = nil
        else
          @savedObject.user_profile_name = up.full_name
        end

        @savedObject.client_email = params[:assignment][:client_email]

        if @savedObject.valid?
          @savedObject.current_step = "dienst"
          @savedObject.last_completed_step = "start-wishlist" if @savedObject.new_record? || !future_step?(@savedObject.last_completed_step.to_sym)
          session[:client_name] = @savedObject.user_profile_name
          session[:ass_token] = @savedObject.assignment_code if !session[:ass_token]
        end
      when "dienst"
        @assignment = Assignment.find_by(:assignment_code => session[:ass_token])
        if params[:assignment_main_service][:cats].nil? || params[:assignment_main_service][:cats] == ""
          if !params[:unknown_keyword].nil?
            @savedObject = UnknownKeyword.find_or_initialize_by(:u_keyword => params[:unknown_keyword][:keyword])
          else
            @savedObject = UnknownKeyword.find_or_initialize_by(:u_keyword => params[:assignment_main_service][:keyword])
          end

          if @savedObject.valid?
            @savedObject.save
            unknown_assignment = UnknownAssignment.find_or_initialize_by(:assignment_id => @assignment.id)
            unknown_assignment.unknown_keyword_id = @savedObject.id
            unknown_assignment.save

            AssignmentMainService.find_by(:assignment_id => @assignment.id).destroy if AssignmentMainService.exists?(:assignment_id => @assignment.id)
            AssignmentSecondaireService.where(:assignment_id => @assignment.id).destroy_all if AssignmentSecondaireService.exists?(:assignment_id => @assignment.id)
            gon.clear
            @assignment.current_step = " opdracht"
            @assignment.last_completed_step = "dienst" if !future_step?(@assignment.last_completed_step.to_sym)
            @assignment.save
            @assignment.update_matching_services
          end
        else
          @savedObject = AssignmentMainService.find_or_initialize_by(:assignment_id => @assignment.id)
          if !params[:unknown_keyword].nil?
            @savedObject.keyword = params[:unknown_keyword][:keyword]
          else
            @savedObject.keyword = params[:assignment_main_service][:keyword]
          end

          main_service = params[:assignment_main_service][:cats].split(",")
          @savedObject.category_id = main_service[0]
          @savedObject.sub_category_id = main_service[1]
          @savedObject.sub_platform_id = main_service[2]

          if @savedObject.valid?
            @savedObject.save

            AssignmentSecondaireService.where(:assignment_id => @assignment.id).destroy_all if AssignmentSecondaireService.exists?(:assignment_id => @assignment.id)

            if params[:assignment_main_service][:extra_subs].present?
              params[:assignment_main_service][:extra_subs].each do |extra|
                subc = SubCategory.find_by(:sub_name => extra)
                AssignmentSecondaireService.create(:assignment_id => @assignment.id, :category_id => @savedObject.category_id, :sub_category_id => subc.id)
              end
            elsif params[:assignment_main_service][:extra_plats].present?
              params[:assignment_main_service][:extra_plats].each do |extra|
                plat = SubPlatform.find_by(:plat_name => extra)
                AssignmentSecondaireService.create(:assignment_id => @assignment.id, :category_id => @savedObject.category_id, :sub_category_id => plat.sub_category_id, :sub_platform_id => plat.id)
              end
            end
            UnknownAssignment.find_by(:assignment_id => @assignment.id).destroy if UnknownAssignment.exists?(:assignment_id => @assignment.id)
            gon.clear
            @assignment.current_step = "opdracht"
            @assignment.last_completed_step = "dienst" if !future_step?(@assignment.last_completed_step.to_sym)
            @assignment.save
            @assignment.update_matching_services
          else
            jump_to(step)
          end
        end
      when "opdracht"
        @savedObject = Assignment.find_by(:assignment_code => session[:ass_token])
        @assignment = @savedObject
        @savedObject.validation_step = "assignment_info"
        @savedObject.description = params[:assignment][:description]
        @savedObject.dreams = params[:assignment][:dreams]
        @savedObject.stripped_description = @savedObject.description.gsub(/<\/?[^>]*>/, "")
        @attachments = AssignmentAttachment.where(:assignment_id => @savedObject.id)
        gon.attachments = @attachments

        if @savedObject.valid?
          if !params[:attachment].nil? && !params[:assignment][:attachment].nil?
            attachments = params[:assignment][:attachment]

            attachments.each do |attachment|
              @savedObject.assignment_attachments.build(:document => attachment)
            end

            if @savedObject.valid?
                if !params[:attachment][:deleted_attachments].nil? && params[:attachment][:deleted_attachments] != ""
                  AssignmentAttachment.where(:id => params[:attachment][:deleted_attachments].split(",")).delete_all
                end
                @savedObject.current_step = "start-datum"
                @savedObject.last_completed_step = "opdracht" if !future_step?(@savedObject.last_completed_step.to_sym)
                @savedObject.save
                gon.clear
            else
              jump_to(step)
            end
          else
            if !params[:attachment][:deleted_attachments].nil? && params[:attachment][:deleted_attachments] != ""
              AssignmentAttachment.where(:id => params[:attachment][:deleted_attachments].split(",")).delete_all
            end
            @savedObject.current_step = "start-datum"
            @savedObject.last_completed_step = "opdracht" if !future_step?(@savedObject.last_completed_step.to_sym)
            @savedObject.save
            gon.clear
          end
        else
          jump_to(step)
        end
      when "start-datum"
        @savedObject = Assignment.find_by(:assignment_code => session[:ass_token])
        @assignment = @savedObject
        @savedObject.validation_step = "start_date"

        if StartDate.exists?(:type_start_date => params[:budgetTypeOptions])
          @savedObject.start_date = StartDate.find_by(:type_start_date => params[:budgetTypeOptions])
        else
          @savedObject.start_date = nil
        end

        if @savedObject.valid?
          @savedObject.current_step = "budget"
          @savedObject.last_completed_step = "start-datum" if !future_step?(@savedObject.last_completed_step.to_sym)
          gon.clear
        end
      when "budget"
        @assignment = Assignment.find_by(:assignment_code => session[:ass_token])
        @savedObject = AssignmentBudget.find_or_initialize_by(:assignment_id => @assignment.id)

        @savedObject.assign_attributes(assignment_budget_params)
        @savedObject.other = false if params[:assignment_budget][:other].nil?
        @savedObject.monthly_payment = false if params[:assignment_budget][:monthly_payment].nil?

        if @savedObject.valid?
          @assignment.current_step = "persoonlijke-informatie"
          @assignment.last_completed_step = "budget" if !future_step?(@assignment.last_completed_step.to_sym)
          @assignment.save
        end
      when "persoonlijke-informatie"
        @savedObject = Assignment.find_by(:assignment_code => session[:ass_token])
        @assignment = @savedObject

        generated_password = Devise.friendly_token.first(8)
        role = Role.find_by(:user_role => "beheerder")

        @savedObject.user_assignments.build(:owner => true, :role_id => role.id, :added_through => "client")
        @savedObject.user_assignments.last.build_user(assignment_personalinfo_user_params)
        @savedObject.user_assignments.last.user.password = generated_password
        @savedObject.user_assignments.last.user.user_type_id = UserType.find_by(:user_type => "client").id

        @savedObject.user_assignments.last.user.build_user_profile(assignment_personalinfo_user_profile_params)
        @savedObject.user_assignments.last.user.user_profile.full_name_cleanup
        @savedObject.user_assignments.last.user.user_profile.set_first_last_name
        @savedObject.user_assignments.last.user.user_profile.set_user_tag
        @savedObject.user_assignments.last.user.user_profile.validation_step = "personal_info"

        organisation_type = OrganisationType.find_by(company_type: "Bedrijf")
        @savedObject.company = Company.find_or_initialize_by(id: @savedObject.company_id, client: true, organisation_type_id: organisation_type.id)
        @savedObject.company.assign_attributes(assignment_personalinfo_company_params)
        @savedObject.company.validation_step = "personal_info"

        if CompanyAdress.exists?(:company_id => @savedObject.company_id)
          @savedObject.company.company_adress = CompanyAdress.find_by(:company_id => @savedObject.company_id)
        else
          @savedObject.company.build_company_adress
        end

        @savedObject.company.company_adress.assign_attributes(assignment_personalinfo_company_adress_params)
        @savedObject.company.company_adress.validation_step = "start-opdracht"

        if @savedObject.valid?
          @savedObject.current_step = "succes"
          @savedObject.last_completed_step = "persoonlijke-informatie"

          @savedObject.user_assignments.last.user.skip_confirmation_notification!
          @savedObject.user_assignments.last.user.save
          @savedObject.company.save

          if UserCompany.exists?(:company_id => @savedObject.company_id, :owner => true)
            UserCompany.find_or_create_by(:user_id => @savedObject.user_assignments.last.user.id, :company_id => @savedObject.company.id, :role_id => Role.find_by(:user_role => "beheerder").id)
          else
            UserCompany.find_or_create_by(:user_id => @savedObject.user_assignments.last.user.id, :company_id => @savedObject.company.id, :owner => true, :role_id => Role.find_by(:user_role => "beheerder").id)
          end

          if !cookies[:wishlist].nil?
            wishlist = JSON.parse cookies[:wishlist]
            wishlist.each do |ww|
              @savedObject.assignment_wishlist_partners.build(:company_id => ww["partner"].to_i) if Company.exists?(:id => ww["partner"].to_i, :closed_at => nil)
            end
          end

          @savedObject.save
          @savedObject.company.old = true
          @savedObject.company.save

          ApiMailer.send_mail(Mailer::StartOpdrachtMailer.account_and_assignment_activation_mail(@savedObject.user_assignments.last.user, @savedObject.assignment_code))

          session[:email] = @savedObject.user_assignments.last.user.email
          session[:last_assignment] = session[:ass_token]
          session[:ass_token] = nil
          session[:client_name] = nil
          cookies.delete :wishlist
        else
          @user = @savedObject.user_assignments.last.user
          @user_profile = @savedObject.user_assignments.last.user.user_profile
          @company = @savedObject.company
          @company_adress = @savedObject.company.company_adress
        end
      when "ingelogd-persoonlijke-informatie"
        @savedObject = Assignment.find_by(:assignment_code => session[:ass_token])
        @assignment = @savedObject

        if @savedObject.company.nil? || @savedObject.company.old != true
          organisation_type = OrganisationType.find_by(company_type: "Bedrijf")
          @savedObject.company = Company.find_or_initialize_by(id: @savedObject.company_id, client: true, organisation_type_id: organisation_type.id)
          @savedObject.company.assign_attributes(assignment_personalinfo_company_params)

          @savedObject.company.build_company_adress
          @savedObject.company.company_adress.assign_attributes(assignment_personalinfo_company_adress_params)
          @savedObject.company.company_adress.validation_step = "start-opdracht"
        end

        if @savedObject.valid?
          @savedObject.current_step = "succes_multiple"
          @savedObject.last_completed_step = "ingelogd-persoonlijke-informatie"
          @savedObject.save
          UserCompany.create(:user_id => current_user.id, :company_id => @savedObject.company.id, :owner => true, :role_id => Role.find_by(:user_role => "beheerder").id) if @savedObject.company.old == false
          @savedObject.company.old = true
          @savedObject.company.save

          if !cookies[:wishlist].nil?
            wishlist = JSON.parse cookies[:wishlist]
            wishlist.each do |ww|
              @savedObject.assignment_wishlist_partners.build(:company_id => ww["partner"].to_i) if Company.exists?(:id => ww["partner"].to_i, :closed_at => nil)
            end
          end

          ApiMailer.send_mail(Mailer::StartOpdrachtMailer.assignment_activation_mail(@savedObject.user_assignments.last.user, @savedObject.assignment_code))

          session[:email] = @savedObject.user_assignments.last.user.email
          session[:last_assignment] = session[:ass_token]
          session[:ass_token] = nil
          session[:client_name] = nil
          cookies.delete :wishlist
        else
          @user = @savedObject.user_assignments.last.user
          @user_profile = @savedObject.user_assignments.last.user.user_profile
          @company = @savedObject.company
          @company_adress = @savedObject.company.company_adress
        end
    end
    render_wizard @savedObject
  end

  def open_popular_services_partial
    respond_to do |format|
      format.js   { }
     end
  end

  def open_budget_fixed_partial
    @assignment = Assignment.find_by(:assignment_code => session[:ass_token])
    @savedObject = AssignmentBudget.find_or_initialize_by(:assignment_id => @assignment.id)
    @savedObject.build_assignment_budget_hourly if @savedObject.assignment_budget_hourly.nil?
    respond_to do |format|
      format.js   { }
     end
  end

  def open_budget_hourly_partial
    @assignment = Assignment.find_by(:assignment_code => session[:ass_token])
    @savedObject = AssignmentBudget.find_or_initialize_by(:assignment_id => @assignment.id)
    @savedObject.build_assignment_budget_hourly if @savedObject.assignment_budget_hourly.nil?
    respond_to do |format|
      format.js   { }
     end
  end

  def succes
    if session[:last_assignment].nil?
      redirect_to root_url
    else
      @savedObject = Assignment.find_by(:assignment_code => session[:last_assignment])
      @assignment = @savedObject
      if @savedObject.current_step == "succes_multiple"
        redirect_to succes_meerdere_start_opdracht_index_path
      else
        @company = @savedObject.company
        @user = @savedObject.user_assignments.last.user
        @user_profile = @savedObject.user_assignments.last.user.user_profile
      end
    end
  end

  def succes_meerdere
    if session[:last_assignment].nil?
      redirect_to root_url
    else
      @savedObject = Assignment.find_by(:assignment_code => session[:last_assignment])
      @assignment = @savedObject
      @company = @savedObject.company
      @user = @savedObject.user_assignments.last.user
      @user_profile = @savedObject.user_assignments.last.user.user_profile
    end
  end

  def search
    respond_to do |format|
      format.html do raise ActionController::RoutingError, "Invalid format" end
      format.json do
        unless params[:term].blank?
          render json: Suggestion.search(params[:term])
        end
      end
    end
  end

  def get_sub_categories
    respond_to do |format|
      format.html do raise ActionController::RoutingError, "Invalid format" end
      format.json do
        category = params[:cats].split(",")
        render json: SubCategory.get_subs(category)
      end
    end
  end

  def get_platforms
    respond_to do |format|
      format.html do raise ActionController::RoutingError, "Invalid format" end
      format.json do
        cats = params[:cats].split(",")
        render json: SubPlatform.get_plats(cats)
      end
    end
  end

  def get_category_title
    respond_to do |format|
      format.html do raise ActionController::RoutingError, "Invalid format" end
      format.json do
        category = params[:service].split(",")
        render json: Category.select(:cat_name, :title, :sub_title).find_by(:id => category)
      end
    end
  end

  def get_sub_category_title
    respond_to do |format|
      format.html do raise ActionController::RoutingError, "Invalid format" end
      format.json do
        sub_category = params[:service].split(",")
        render json: SubCategory.select(:sub_name, :title, :sub_title).find_by(:id => sub_category[1])
      end
    end
  end

  def get_sub_platform_title
    respond_to do |format|
      format.html do raise ActionController::RoutingError, "Invalid format" end
      format.json do
        sub_platform = params[:service].split(",")
        render json: SubPlatform.select(:plat_name, :title, :sub_title).find_by(:id => sub_platform[2])
      end
    end
  end

  def search_by_service
    respond_to do |format|
      format.html do raise ActionController::RoutingError, "Invalid format" end
      format.json do
        unless params[:term].blank?
          render json: Suggestion.search_by_service(params[:term])
        end
      end
    end
  end

  def check
    if session[:ass_token]
      assignment = Assignment.find_by(:assignment_code => session[:ass_token])
      if session[:assignment_login]
        session[:client_name] = current_user.user_profile.first_name
        if !assignment.has_owner?
          session[:midwayLogin] = true
          role = Role.find_by(:user_role => "beheerder")
          assignment.user_assignments.build(:owner => true, :user_id => current_user.id, :role_id => role.id, :added_through => "client")
          assignment.last_completed_step = "ingelogd-intro"
          assignment.current_step = "ingelogd-persoonlijke-informatie" if current_user && assignment.current_step == "persoonlijke-informatie"
          assignment.save
          Assignment.remove_incomplete_assignments(current_user)
          assignment.reload
          if UserCompany.count_owner(current_user.id) == 0
            redirect_to start_opdracht_path(assignment.current_step)
          elsif UserCompany.count_owner(current_user.id) == 1
            redirect_to start_opdracht_path(:'ingelogd-opdracht-voor-een')
          else
            redirect_to start_opdracht_path(:'ingelogd-opdracht-voor-meerdere')
          end
        else
          session[:return] = true
          redirect_to start_opdracht_path(:'welkom-terug')
        end
      else
        session[:return] = true
        redirect_to start_opdracht_path(:'welkom-terug')
      end
    else
      redirect_to start_opdracht_path(steps[1])
    end
  end

  def send_confirmation
    respond_to do |format|
      format.json do
        if !session[:last_assignment].nil?
          assignment = Assignment.find_by(:assignment_code => session[:last_assignment])
          if assignment.confirmed_at.nil?
            assignment_owner = assignment.user_assignments.last.user
            if assignment_owner.confirmation_resend < 1

              if assignment_owner.assignments.count <= 1
                generated_password = Devise.friendly_token.first(8)
                assignment_owner.password = generated_password
                assignment_owner.confirmation_resend += 1
                assignment_owner.save
                ApiMailer.send_mail(Mailer::StartOpdrachtMailer.account_and_assignment_activation_mail(assignment_owner, assignment.assignment_code))
                @send = {:errors => ""}
              else
                assignment_owner.confirmation_resend += 1
                assignment_owner.save
                ApiMailer.send_mail(Mailer::StartOpdrachtMailer.assignment_activation_mail(assignment_owner, assignment.assignment_code))
                @send = {:errors => ""}
              end
            else
              @send = {:errors => "U heeft al de email opnieuw verzonden. Nog steeds geen email ontvangen? Neem contact op via support@partnie.com"}
            end
          else
            @send = {:errors => "U heeft al je account bevestigd. U kunt dit venster sluiten of inloggen."}
          end
        else
          @send = {:errors => "U heeft al je account bevestigd. U kunt dit venster sluiten of inloggen."}
        end
        render json: @send
      end
    end
  end

  def change_email
    respond_to do |format|
      format.json do
        if !session[:last_assignment].nil?
          assignment = Assignment.find_by(:assignment_code => session[:last_assignment])
          if assignment.confirmed_at.nil?
            @user = assignment.user_assignments.last.user
            if @user.unconfirmed_email == nil
              @user.email = params[:email]
              if !User.exists?(:email => @user.email)
                if @user.valid?
                  generated_password = Devise.friendly_token.first(8)
                  @user.password = generated_password
                  @user.skip_confirmation_notification!
                  @user.save
                  ApiMailer.send_mail(Mailer::StartOpdrachtMailer.account_and_assignment_activation_mail(@user, assignment.assignment_code))
                  @changed = {:errors => ""}
                else
                  @changed = {:errors => @user.errors.full_messages.first.to_s}
                end
              else
                @changed = {:errors => "E-Email adres al in gebruik."}
              end
            else
              @changed = {:errors => "U heeft uw email al gewijzigd. Nog steeds geen email ontvangen? Neem contact op via support@partnie.com"}
            end
          else
            @changed = {:errors => "U heeft al je account bevestigd. U kunt dit venster sluiten of inloggen."}
          end
        else
          @changed = {:errors => "U heeft al je account bevestigd. U kunt dit venster sluiten of inloggen."}
        end
        render json: @changed
      end
    end
  end

  private
  def set_steps
    if current_user.nil?
      self.steps = [:'welkom-terug', :start, :'start-dienst', :'start-wishlist', :'start-wishlist-dienst', :dienst, :'opdracht', :'start-datum', :'budget', :'persoonlijke-informatie']
    else
      if UserCompany.count_owner(current_user.id) == 0
        self.steps = [:'welkom-terug', :'ingelogd-intro', :dienst, :'opdracht', :'start-datum', :'budget', :'persoonlijke-informatie']
      else
        self.steps = [:'welkom-terug', :'ingelogd-intro', :'ingelogd-opdracht-voor-een', :'ingelogd-opdracht-voor-meerdere', :dienst, :'opdracht', :'start-datum', :'budget', :'ingelogd-persoonlijke-informatie']
      end
    end
  end

  def set_sets_variable
    @steps = self.steps
  end

  def redirect_to_finish_wizard(options = nil)
    @savedObject = Assignment.find_by(:assignment_code => session[:last_assignment])
    ApiMailer.send_mail(Mailer::PartnieMailer.new_assignment_before_confirmation_mail(@savedObject))

    if current_user
      redirect_to succes_meerdere_start_opdracht_index_path
    else
      redirect_to succes_start_opdracht_index_path
    end
  end

  def assignment_start_params
    params.require(:user_profile).permit(:full_name)
  end

  def bedrijfsinformatie_params_client_company
    params.require(:company).permit(:title, :description)
  end

  def assignment_dreams_params
    params.require(:assignment).permit(:dreams)
  end

  def assignment_service_params
    params.require(:assignment_main_service).permit(:keyword, :cats, :extra_subs, :extra_plats)
  end

  def assignment_description_params
    params.require(:assignment).permit(:description)
  end

  def assignment_attachment_params
    params.fetch(:assignment).permit(assignment_attachments_params: [attachment: []])
  end

  def assignment_budget_params
    params.require(:assignment_budget).permit(:budget_type, :sum, :monthly_payment, :other, :other_sum, assignment_budget_hourly_attributes: [:selection, :hour, :period])
  end

  def assignment_deadline_params
    params.require(:assignment_deadline).permit(:deadline, :year, :day)
  end

  def assignment_personalinfo_user_profile_params
    params.require(:user_profile).permit(:full_name, :phone, :phone_country)
  end

  def assignment_personalinfo_company_adress_params
    params.require(:company_adress).permit(:zipcode)
  end

  def assignment_personalinfo_user_params
    params.require(:user).permit(:email)
  end

  def assignment_personalinfo_company_params
    params.require(:company).permit(:company_name, :website)
  end

  def get_workspaces
    @workspaces = current_user.workspaces if current_user
  end

  def client_owner_count
    @client_owner_count = UserAssignment.where(user_id: current_user.id, owner: true, deleted: false).count if current_user
  end
end
