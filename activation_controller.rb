class ActivationController < ApplicationController
    def home
      if current_user
        @user = User.find(current_user.id)
      end
    end

    def catch
      # NOTE: this is the aciton that every user comes if he clicks on the butotn in the invitation mail.
      # NOTE: here the user will be redirected to the right action, if the user is logged in this means he has a account so redirect him to his backend en then a page where he can accept the invitation.
      # NOTE: if the user is niet logged in this means 2 things or the user exists but no login or the user is a new user and needs to create a account, we can check this with the email adress, if the email exists this means that the user already exists...
      # NOTE: so redirect him to the login page or something, and for the new user redirect to a account registration page.

      if User.exists?(:id => params[:format])
        user = User.find(params[:format])
      elsif User.exists?(:email => params[:email])
        user = User.find_by(:email => params[:email])
      else
        # NOTE: user not found.
        redirect_to root_path
      end

      if user.user_type_id == UserType.find_by(:user_type => "partner").id || user.user_type_id == UserType.find_by(:user_type => "client").id
        case params[:type]
        when "assignment"
          if Assignment.exists?(:assignment_code => params[:token]) && Assignment.is_owner_by_assignment_code?(params[:token], user.id)
            assignment = Assignment.find_by(:assignment_code => params[:token])
            company = assignment.company
            if assignment.confirmed_at == nil && assignment.current_step == "succes" || assignment.current_step == "succes_multiple"
              user.confirmation_resend = 0
              user.save

              assignment.confirmed_at = DateTime.now
              assignment.confirmed_by_id = user.id
              assignment.save
              session[:last_assignment] = nil

              ApiMailer.send_mail(Mailer::PartnieMailer.new_assignment_mail(user, company, assignment))

              if UserAssignment.where(:user_id => user.id).count == 1
                if user.user_type_id == UserType.find_by(:user_type => "client").id
                  generated_password = Devise.friendly_token.first(8)
                  user.password = generated_password
                  user.save
                  if assignment.assignment_campaign_id.nil?
                    ApiMailer.send_mail(Mailer::StartOpdrachtMailer.client_welcome_mail(user, assignment.id, generated_password))
                  else
                    ApiMailer.send_mail(Mailer::StartOpdrachtMailer.new_user_campaign_welcome_mail(user, assignment.id, generated_password, assignment.assignment_campaign.campaign_name))
                  end
                end
                sign_in user
                redirect_to check_o_onboarding_index_path
              else
                if !assignment.assignment_campaign_id.nil?
                  ApiMailer.send_mail(Mailer::StartOpdrachtMailer.campaign_welcome_mail(user, assignment.id, assignment.assignment_campaign.campaign_name))
                end
                sign_in user
                redirect_to o_opdrachten_index_path
              end
            else
              puts "assignment already confirmed, or not completed"
              redirect_to root_path
            end
          else
            puts "user is not the owner of the assignment"
            redirect_to root_path
          end
        when "invitation"
          invitation = Invitation.find_by(:invitee_id => user.id, invitation_token: params[:token])
          if invitation.nil?
            puts "invitation not found"
            redirect_to oeps_path
          elsif !invitation.invitation_accepted_at.nil?
            puts "invitation already accepted"
            redirect_to o_opdrachten_index_path
          else
            invitation.invitation_accepted_at = DateTime.now
            invitation.save!

            user.confirmed_at = DateTime.now if !user.confirmed?

            if user.user_onboarding.nil?
              generated_password = Devise.friendly_token.first(8)
              user.password = generated_password

              ApiMailer.send_mail(Mailer::InvitationMailer.new_user_invitation_follow_up(user.email, user.user_profile, user.user_type.user_type, generated_password))
            end
            
            user.save
            bypass_sign_in(user)

            if invitation.invited_by == "partner"
              workspace_id = 0

              if invitation.invitable_type == "Company"
                workspace_id = invitation.invitable_id
                redirect_to p_ontdek_index_path(workspace_id, uitnodiging: "organisatie")
              else
                workspace_id = invitation.invitable_id = invitation.invitation_partner_assignment_invites.last.company_id
                redirect_to p_ontdek_index_path(workspace_id, uitnodiging: "opdracht")
              end
            else
              if invitation.invitable_type == "Company"
                redirect_to o_opdrachten_index_path(uitnodiging: "organisatie")
              else
                redirect_to o_opdrachten_index_path(uitnodiging: "opdracht")
              end
            end
          end
        when "onboarding_invitation"
          invitation = Invitation.find_by(:invitee_id => user.id, invitation_token: params[:token])

          if invitation.nil?
            redirect_to oeps_path
          elsif !invitation.invitation_accepted_at.nil?
            puts "invitation already accepted"
            redirect_to o_opdrachten_index_path
          else
            invitation.invitation_accepted_at = DateTime.now
            invitation.save!

            company = invitation.invitable.company
            company_invitation = Invitation.find_by(:invitee_id => user.id, :invitable_id => company.id, :invitable_type => "Company")
            company_invitation.invitation_accepted_at = DateTime.now
            company_invitation.save!

            generated_password = Devise.friendly_token.first(8)
            user.password = generated_password
            user.confirmed_at = DateTime.now if !user.confirmed?
            user.save
            sign_in user

            if user.user_onboarding.nil?
              ApiMailer.send_mail(Mailer::InvitationMailer.new_user_invitation_follow_up(user.email, user.user_profile, user.user_type.user_type, generated_password))
            end
            redirect_to o_opdrachten_index_path
          end
        when "email_change"
          ApiMailer.send_mail(Mailer::O::InstellingenMailer.success_new_email_change_mail(user.email, params[:token], user.user_profile))
          sign_in user
          redirect_to edit_o_instellingen_path(user.id)
        else
          puts "type activation not found"
          redirect_to root_path
        end
      else
        puts "user type unknown"
        redirect_to root_path
      end
    end

    def agency
      if params[:id]
        if BetaInvitationLink.exists?(:unique_key => params[:id])
          link = BetaInvitationLink.find_by(:unique_key => params[:id])
          redirect_to user_beta_invitation_path(:beta_token => link.beta_token, :utm_source => link.utm_source, :utm_medium => link.utm_medium, :utm_campaign => link.utm_campaign)
        end
      else
        redirect_to root_path
      end
    end

    def user_beta_invitation
      if BetaInvitationLink.exists?(:beta_token => params[:beta_token])
        beta_link = BetaInvitationLink.find_by(:beta_token => params[:beta_token])
        beta_link.clicked += 1
        beta_link.save
        session[:beta_invitation] = params[:beta_token]
      end
      redirect_to root_path
    end
end
