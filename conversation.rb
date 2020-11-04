class Conversation < ActiveRecord::Base
  attr_accessor :validation_step, :editor_type, :editor_id, :current_workspace_id
  belongs_to :company
  belongs_to :assignment
  has_many :messages, dependent: :destroy
  has_many :conversation_users, dependent: :destroy
  has_many :message_recipients, :through => :conversation_users
  has_many :channel_conversations, dependent: :destroy
  has_many :channels, :through => :channel_conversations

  validate :admin_count, if: :check_admin_count

  accepts_nested_attributes_for :conversation_users, :messages, :message_recipients, :channel_conversations

  # validate :number_of_participants # NOTE: there must be atleast two participants/

  after_validation :log_errors, :if => Proc.new {|m| m.errors}

  scope :get_partner_talk, -> (assignment, partner) {
    where(conversation_type: "partner_talk", assignment_id: assignment, company_id: partner)
  }

  def is_member?(user, workspace)
    if workspace.nil?
      return true if self.conversation_users.exists?(participant_id: user.id, participant_type: "User", deleted_at: nil, left_at: nil, removed_at: nil)
    else
      user_company = UserCompany.find_by(company_id: workspace, user_id: user.id, :deleted => false)
      return true if self.conversation_users.exists?(participant_id: user_company.id, participant_type: "UserCompany", deleted_at: nil, left_at: nil, removed_at: nil)
    end
  end

  def is_admin?(user, workspace)
    admin_role = Role.find_by(user_role: "beheerder")
    if workspace.nil?
      return true if self.conversation_users.exists?(participant_id: user.id, participant_type: "User", deleted_at: nil, left_at: nil, role_id: admin_role.id)
    else
      user_company = UserCompany.find_by(company_id: workspace.id, user_id: user.id, :deleted => false)
      return true if self.conversation_users.exists?(participant_id: user_company.id, participant_type: "UserCompany", deleted_at: nil, left_at: nil, role_id: admin_role.id)
    end
  end

  def self.create_partner_talk_conversation(assignment, partner_company_ids) # NOTE: expects partner_company_ids to be an Integer or Array.
    admin_roles = Role.where(user_role: ["beheerder", "team captain"]).ids

    partner_company_ids = Array(partner_company_ids) unless partner_company_ids.class == Array
    partner_company_ids = partner_company_ids.push(nil) # NOTE: put nil into this array because we also want the client user_assignmnts

    partners = Company.where(id: partner_company_ids).includes(:user_companies)
    user_assignments = assignment.user_assignments.where(role_id: admin_roles, added_through_id: partner_company_ids, deleted: false)
    client_user_assignments = user_assignments.select {|user_assignment| user_assignment.added_through_id == nil}

    user_ids = user_assignments.map(&:user_id)
    user_channels = ChatChannel.where(user_id: user_ids, deleted_at: nil)

    partners.each do |partner|
      participants = []

      conversation = get_partner_talk(assignment, partner.id)
      next conversation unless conversation.empty?

      partner_user_assignments = user_assignments.select {|user_assignment| user_assignment.added_through_id == partner.id} # NOTE: add these and client_user_assignments to the conversation

      conversation = Conversation.new(conversation_type: "partner_talk", assignment_id: assignment.id, company_id: partner.id) # NOTE: build the new conversation

      # NOTE: add all client side assignment users to the conversation
      client_user_assignments.each do |user_assignment|
        participant = {}
        participant[:participant_type] = "User"
        participant[:participant_id] = user_assignment.user_id
        participant[:role] = admin_roles[0]
        participant[:user_id] = user_assignment.user_id
        participant[:company_id] = nil
        participants.push(participant)
      end

      # NOTE: add all partner side assignment users to the conversation
      partner_user_assignments.each do |user_assignment|
        participant_id = partner.user_companies.select {|user_company| user_company.user_id == user_assignment.user_id && user_company.deleted == false}.first.id

        participant = {}
        participant[:participant_type] = "UserCompany"
        participant[:participant_id] = participant_id
        participant[:role] = admin_roles[0]
        participant[:user_id] = user_assignment.user_id
        participant[:company_id] = user_assignment.added_through_id
        participants.push(participant)
      end

      conversation.build_conversation_users(participants)

      conversation.validation_step = "create_conversation"
      if conversation.valid?
        conversation.save
      else
        return conversation
      end
    end
    return true
  end

  def self.create_conversation(conversation_type, new_conversation_users, partner_talk_params, workspace) # NOTE: send assignment OR company nil if not necessary
    conversation = get_partner_talk(partner_talk_params[:assignment], partner_talk_params[:partner])
    return conversation unless conversation.empty?

    user_ids = new_conversation_users.map { |user| user[:user_id] }
    user_channels = ChatChannel.where(user_id: user_ids, deleted_at: nil)

    conversation = Conversation.new(conversation_type: conversation_type, assignment_id: partner_talk_params[:assignment], company_id: partner_talk_params[:partner]) # NOTE: build the new conversation

    new_conversation_users.each do |cp| # NOTE: build the conversation participants ONLY ONE OWNER ALLOWED
      # NOTE: user_type = User or UserCompany. User if the user is from the client side or the user side, UserCompany if the user added belongs to a partner company. This way we can get the right profile information.
      # NOTE: so if UserCompany get the usercompanyprofile information.
      participant_id = cp[:user_type] == "User" ? cp[:user_id] : cp[:user_company_id]

      conversation.conversation_users.build(participant_type: cp[:user_type], participant_id: participant_id, owner: cp[:owner], role_id: cp[:role])

      user_channel = user_channels.select {|uc| uc.user_id == cp[:user_id] && uc.company_id == cp[:workspace_id]}.first
      conversation.channel_conversations.build(chat_channel_id: user_channel.id)
    end

    conversation.validation_step = "create_conversation"
    if conversation.valid?
      conversation.save
    end

    conversation
  end

  def self.load_partner_talk(conversation_id, conversation_user_id)
    convers = Conversation.find(conversation_id)
    # NOTE: authorization: https://stackoverflow.com/questions/3293400/access-cancans-can-method-from-a-model
    conversation_user = ConversationUser.find(conversation_user_id)

    conversation = {}

    conversation[:conversation_id] = conversation_user.conversation.id
    conversation[:conversation_user_id] = conversation_user.id
    conversation[:conversation_user_deleted] = conversation_user.deleted_at
    conversation[:conversation_user_removed] = conversation_user.removed_at
    conversation[:conversation_partner_left] = convers.assignment.poule_companies.where(company_id: convers.company_id).where.not(sealed_at: nil, closed_at: nil).empty? ? false : true
    conversation[:conversation_assignment_closed] = convers.assignment.closed_at.nil? ? false : true
    conversation[:conversation_participant_type] = conversation_user.participant.class.name
    conversation[:conversation_participant_first_name] = conversation_user.participant.user_profile.first_name
    conversation[:conversation_type] = convers.conversation_type

    if !convers.company_id.nil?
      conversation[:conversation_partner_company_name] = convers.company.company_name
      conversation[:conversation_partner_company_logo] = convers.company.logo(:xxl)
      conversation[:conversation_partner_company_type] = convers.company.organisation_type.company_type
      conversation[:conversation_partner_company_slogan] = convers.company.partner_company.slogan
    end

    if !convers.assignment_id.nil?
      conversation[:conversation_client_company_name] = convers.assignment.company.company_name
      conversation[:conversation_client_company_logo] = convers.assignment.company.logo(:xxl)
      conversation[:conversation_client_company_type] = convers.assignment.company.organisation_type.company_type
      conversation[:conversation_client_company_assignment] = convers.assignment.assignment_number
    end

    conversation[:chat_messages] = conversation_user.get_messages(DateTime.now)
    Conversation.trigger_message_read(convers)
    conversation
  end

  def self.load_partner_talk_profile(conversation_id, conversation_user_id)
    convers = Conversation.find(conversation_id)
    # NOTE: authorization: https://stackoverflow.com/questions/3293400/access-cancans-can-method-from-a-model
    conversation_user = ConversationUser.find(conversation_user_id)

    assignment = convers.assignment
    client = assignment.company
    partner = convers.company

    conversation = {}
    conversation[:conversation_counterparty_users] = []
    conversation[:conversation_users] = []

    conversation[:conversation_id] = conversation_user.conversation.id
    conversation[:conversation_user_id] = conversation_user.id
    conversation[:conversation_user_role] = conversation_user.role.user_role
    conversation[:conversation_participant_type] = conversation_user.participant.class.name
    conversation[:conversation_type] = convers.conversation_type

    conversation[:conversation_partner_company_id] = partner.id
    conversation[:conversation_partner_company_name] = partner.company_name
    conversation[:conversation_partner_company_logo] = partner.logo(:xxl)
    conversation[:conversation_partner_company_type] = partner.organisation_type.company_type
    conversation[:conversation_partner_company_slogan] = partner.partner_company.slogan
    conversation[:conversation_partner_company_review_score] = (partner.partner_company.get_review_score(partner.published_reviews))

    conversation[:conversation_assignment_owner_name] = assignment.owner.user.user_profile.get_full_name
    conversation[:conversation_assignment_owner_initials] = assignment.owner.user.user_profile.get_initials
    conversation[:conversation_assignment_owner_avatar] = assignment.owner.user.user_profile.avatar.url(:l)
    if conversation_user.participant.class.name == "User"
      conversation[:conversation_assignment_service] = assignment.assignment_main_service.nil? ? assignment.unknown_assignment.unknown_keyword.u_keyword.capitalize : assignment.assignment_main_service.keyword.capitalize
    else
      conversation[:conversation_assignment_service] = assignment.assignment_matching_information.title
    end

    conversation[:conversation_client_company_name] = client.company_name
    conversation[:conversation_client_company_logo] = client.logo(:xxl)
    conversation[:conversation_client_company_type] = client.organisation_type.company_type
    conversation[:conversation_client_company_assignment] = assignment.assignment_number

    conversation_users = convers.conversation_users.where(participant_type: conversation_user.participant.class.name, deleted_at: nil, removed_at: nil).includes(:role, participant: [:user_profile])
    conversation_users.each do |conversation_user|
      temp = {}
      temp[:initials] = conversation_user.participant.user_profile.get_initials
      temp[:avatar] = conversation_user.participant.user_profile.avatar.url(:l)
      temp[:role] = conversation_user.role.user_role
      conversation[:conversation_users].push(temp)
    end

    case conversation_user.participant.class.name
    when "User"
      # NOTE: get partner profile users.
      partner.partner_company_profile.partner_company_profile_users.includes(:user_company_profile).each do |profile_user|
        temp = {}
        temp[:avatar] = profile_user.avatar.exists? ? profile_user.avatar.url(:xxl) : "logo/partnie-standalone.svg"
        temp[:initials] = profile_user.user_company_profile.get_initials
        conversation[:conversation_counterparty_users].push(temp)
      end
    when "UserCompany"
      # NOTE: get assignment client users.
      assignment.user_assignments.where(added_through_id: nil).each do |user_assignment|
        temp = {}
        temp[:avatar] = user_assignment.user.user_profile.avatar.url(:l)
        temp[:initials] = user_assignment.user.user_profile.get_initials
        conversation[:conversation_counterparty_users].push(temp)
      end
    end
    conversation
  end

  def self.load_conversation_users(convers, conversation_user_id)
    conversation_user = ConversationUser.find(conversation_user_id)

    assignment = convers.assignment
    client = assignment.company
    partner = convers.company
    user_companies = partner.user_companies

    conversation = {}
    conversation[:non_conversation_users] = []
    conversation[:conversation_users] = []
    conversation[:conversation_id] = conversation_user.conversation.id
    conversation[:conversation_user_id] = conversation_user.id
    conversation[:avatar] = conversation_user.participant.user_profile.avatar.url(:l)
    conversation[:user_tag] = conversation_user.participant.user_profile.user_tag
    conversation[:full_name] = conversation_user.participant.user_profile.get_full_name
    conversation[:initials] = conversation_user.participant.user_profile.get_initials
    conversation[:role] = conversation_user.role.user_role
    conversation[:conversation_participant_type] = conversation_user.participant.class.name
    conversation[:conversation_type] = convers.conversation_type


    conversation_users = convers.conversation_users.where(participant_type: conversation_user.participant.class.name, deleted_at: nil, removed_at: nil).where.not(id: conversation_user_id).includes(:role, participant: [:user_profile])
    conversation_users.each do |conversation_user|
      temp = {}
      temp[:conversation_user_id] = conversation_user.id
      temp[:initials] = conversation_user.participant.user_profile.get_initials
      temp[:full_name] = conversation_user.participant.user_profile.get_full_name
      temp[:user_tag] = conversation_user.participant.user_profile.user_tag
      temp[:avatar] = conversation_user.participant.user_profile.avatar.url(:l)
      temp[:role] = conversation_user.role.user_role
      conversation[:conversation_users].push(temp)
    end

    case conversation_user.participant.class.name
    when "User"
      user_assignments = assignment.user_assignments.where(added_through_id: nil, deleted: false)
    when "UserCompany"
      user_assignments = assignment.user_assignments.where(added_through_id: partner.id, deleted: false)
    end

    user_assignments.includes(:role, user: [:user_profile]).each do |user_assignment|
      temp = {}
      case conversation_user.participant.class.name
      when "User"
        participant = user_assignment.user
        participant_role = user_assignment.role.user_role
        in_chat = convers.conversation_users.select {|conv| conv.participant_id == participant.id && conv.participant_type == "User" && conv.deleted_at.nil? && conv.removed_at.nil?}.empty? ? false : true
      when "UserCompany"
        participant = user_companies.select {|user_company| user_company.user_id == user_assignment.user_id && user_company.deleted == false}.first
        participant_role = participant.role.user_role
        in_chat = convers.conversation_users.select {|conv| conv.participant_id == participant.id && conv.participant_type == "UserCompany" && conv.deleted_at.nil? && conv.removed_at.nil?}.empty? ? false : true
      end

      if in_chat == false
        temp[:id] = participant.id
        temp[:user_type] = participant.class.name
        temp[:user] = user_assignment.user_id
        temp[:avatar] = participant.user_profile.avatar.url(:l)
        temp[:full_name] = participant.user_profile.get_full_name
        temp[:initials] = participant.user_profile.get_initials
        temp[:user_tag] = participant.user_profile.user_tag
        temp[:role] = participant_role

        conversation[:non_conversation_users].push(temp)
      end
    end

    conversation
  end

  def build_conversation_users(participants)

    user_ids = []
    participants.each { |participant| user_ids.push(participant[:user_id]) }

    user_channels = ChatChannel.where(user_id: user_ids, deleted_at: nil)
    user_assignments = self.assignment.user_assignments if self.conversation_type == "partner_talk"

    participants.each do |participant|

      add_conversation_user = true
      if self.conversation_type == "partner_talk"
        added_through = participant[:participant_type] == "User" ? "client" : "partner"
        added_through_id = participant[:company_id]

        user_assignment = user_assignments.select {|ua| ua.added_through == added_through && ua.added_through_id == added_through_id && ua.user_id == participant[:user_id].to_i && ua.deleted == false}.first
        add_conversation_user = false if user_assignment.nil?
      end

      if add_conversation_user
        if self.conversation_users.select {|conv| conv.participant_type == participant[:participant_type] && conv.participant_id == participant[:participant_id].to_i}.empty?
          self.conversation_users.build(participant_type: participant[:participant_type], participant_id: participant[:participant_id].to_i, role_id: participant[:role])
        else
          conversation_user = self.conversation_users.select {|conv| conv.participant_type == participant[:participant_type] && conv.participant_id == participant[:participant_id].to_i}.first
          conversation_user.role_id = participant[:role]
          conversation_user.deleted_at = nil
          conversation_user.removed_at = nil
        end

        user_channel = user_channels.select {|uc| uc.user_id == participant[:user_id].to_i && uc.company_id == participant[:company_id] && uc.deleted_at == nil}.first
        self.channel_conversations.build(chat_channel_id: user_channel.id) if self.channel_conversations.select {|cc| cc.chat_channel_id == user_channel.id}.empty?
      end
    end

    return self
  end

  private
    def log_errors
      Rails.logger.debug self.errors.full_messages.join("\n")
    end

    def self.trigger_new_message_partner_talk(message, sender, conversation)
      case sender.participant.class.name
      when "User"
        sender_user_id = sender.participant.id
        company_logo = sender.conversation.assignment.company.logo(:xxl)
        company_type = sender.conversation.assignment.company.organisation_type.company_type
      when "UserCompany"
        sender_user_id = sender.participant.user_id
        company_logo = sender.conversation.company.logo(:xxl)
        company_type = sender.conversation.company.organisation_type.company_type
      end

      read_all = message.active_message_recipients.select {|mr| mr.read_at.nil? }.empty? ? true : false

      eventData = {
        "message" => message.body,
        "message_id" => message.id,
        "message_read_all" => read_all,
        "sender_full_name" => sender.participant.user_profile.get_full_name,
        "sender_avatar" => sender.participant.user_profile.avatar.url(:l),
        "sender_initials" => sender.participant.user_profile.get_initials,
        "sender_id" => sender.id,
        "sender_user_id" => sender_user_id,
        "sender_company_logo" => company_logo,
        "sender_company_type" => company_type
      }
      Pusher.trigger("presence-conversation-#{conversation.id}", 'new_message', eventData)
    end

    def self.trigger_typing(conversation, typer, current_workspace)
      case typer.participant.class.name
      when "User"
        user_obj = typer.participant
      when "UserCompany"
        user_obj = typer.participant.user
      end

      if conversation.is_member?(user_obj, (current_workspace.id unless current_workspace.nil?))
        eventData = {
          "typer_name" => typer.participant.user_profile.first_name,
          "typer_user_id" => user_obj.id
        }
        Pusher.trigger("presence-conversation-#{conversation.id}", 'typing', eventData)
      end
    end

    def self.trigger_message_read(conversation)
      Pusher.trigger("presence-conversation-#{conversation.id}", 'message_read', conversation.id)
    end

    def check_admin_count
      validation_step == "change_role"
    end

    def admin_count
     admin_role = Role.find_by(user_role: "beheerder")
     admins = self.conversation_users.select {|conv_usr| conv_usr.id != self.editor_id && conv_usr.participant_type == self.editor_type && conv_usr.role_id == admin_role.id && conv_usr.deleted_at == nil && conv_usr.removed_at == nil}

     if admins.empty?
       errors.add(:role_id, I18n.translate('activerecord.errors.models.conversations.attributes.role_id.no_admin'))
     end

    end

end
