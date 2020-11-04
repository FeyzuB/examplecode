class PartnerAbility
  include CanCan::Ability

  def initialize(user, company)
    if user.user_type_id == UserType.find_by(:user_type => "partner").id || user.user_type_id == UserType.find_by(:user_type => "client").id
      can :read, Company do |company|
        company.is_member?(user.id)
      end

      can :read_as_p_before_seal, Assignment do |assignment|
        company.is_member?(user.id)
      end

      can :seal, Assignment do |assignment|
        company.is_admin?(user.id) && assignment.is_candidate?(company.id)
      end

      can :reject, Assignment do |assignment|
        company.is_admin?(user.id) && assignment.is_candidate?(company.id) && !assignment.assignment_wishlist_partners.empty?
      end

      can :read_as_p, Assignment do |assignment|
        if !assignment.review.nil?
          assignment.is_member_through_partner?(user.id, company.id) && assignment.has_sealed?(company.id) && !assignment.review.accepted_at.nil?
        else
          assignment.is_member_through_partner?(user.id, company.id) && assignment.has_sealed?(company.id)
        end
      end

      can :update_as_p, Assignment do |assignment|
        assignment.is_admin_through_partner?(user.id, company.id) && assignment.has_sealed?(company.id) && assignment.closed_at == nil
      end

      can :send_proposal_as_p, Assignment do |assignment|
        assignment.is_admin_through_partner?(user.id, company.id) && assignment.has_sealed?(company.id) && assignment.closed_at == nil && !assignment.is_connected? && assignment.created_through != "review-request"
      end

      can :close_assignment_as_p, Assignment do |assignment|
        company.is_superadmin?(user.id) && assignment.is_member_through_partner?(user.id, company.id) && assignment.has_sealed?(company.id)
      end

      can :leave_assignment_as_p, UserAssignment do |user_assignment|
        user_assignment.user_id == user.id
      end

      can :edit_as_p, Proposal do |proposal|
        proposal.assignment.is_admin_through_partner?(user.id, company.id) && proposal.sent_at.nil?
      end

      can :read_as_p, Proposal do |proposal|
        proposal.assignment.is_member_through_partner?(user.id, company.id)
      end

      can :can_request_review, Company do |company|
        company.is_admin?(user.id)
      end

      can :can_revoke_review, Company do |company|
        company.is_admin?(user.id)
      end

      can :can_create_case, Company do |company|
        company.is_admin?(user.id)
      end

      can :can_edit_case, Case do |casee|
        casee.partner_company_id == company.partner_company.id
      end

    # NOTE: chats
      can :send_message, Conversation do |conversation|
        conversation.is_member?(user, company.id)
      end

      can :edit_conversation, Conversation do |conversation|
        conversation.is_admin?(user, company)
      end

    elsif user.user_type_id == UserType.find_by(:user_type => "admin").id
      can :manage, :all # NOTE: overrules all abilities =)
      can :read_as_p_before_seal
    end
  end
end
