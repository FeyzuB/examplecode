class ChatChannel < ActiveRecord::Base
  belongs_to :user
  belongs_to :company
  has_many :channel_conversations
  has_many :conversations, :through => :channel_conversations

  accepts_nested_attributes_for :channel_conversations, :conversations

  scope :all_user_partner_talks, -> (currentuser, workspace) { where(user: currentuser, company: workspace, deleted_at: nil).joins(:conversations).where("conversations.conversation_type = 'partner_talk'").distinct }


    def self.get_all_user_partner_talks(user, workspace, user_company)
      convs = []

      partner_talk_chat_channel = all_user_partner_talks(user, workspace).first
      return convs if partner_talk_chat_channel.nil?

      partner_talk_chat_channel.conversations.includes(conversation_users:[:messages, :message_recipients, participant: [:user_profile], conversation: [:company,  assignment: [:assignment_matching_information, :unknown_assignment, :assignment_main_service, :company]]]).each do |conversation|
        assignment = conversation.assignment

        unless workspace.nil?
          conversation_user = conversation.conversation_users.select {|cu| cu.participant_id == user_company.user_company_id && cu.participant_type == "UserCompany"}.first
        else
          conversation_user = conversation.conversation_users.select {|cu| cu.participant_id == user.id && cu.participant_type == "User"}.first
        end

        temp = {}
        temp[:conversation_id] = conversation.id
        temp[:conversation_type] = conversation.conversation_type
        temp[:conversation_user_id] = conversation_user.id
        temp[:unread_messages] = conversation_user.message_recipients.select {|mr| mr.read_at == nil}.size

        unless workspace.nil?
          temp[:chat_title] = assignment.company.company_name
          temp[:chat_subtitle] = assignment.assignment_matching_information.title
          temp[:company_logo] = assignment.company.logo.url(:xxl)
          temp[:company_type] = assignment.company.organisation_type.company_type
        else
          temp[:chat_title] = conversation.company.company_name
          temp[:chat_subtitle] = assignment.assignment_main_service.nil? ? assignment.unknown_assignment.unknown_keyword.u_keyword.capitalize : assignment.assignment_main_service.keyword.capitalize
          temp[:company_logo] = conversation.company.logo.url(:xxl)
          temp[:company_type] = conversation.company.organisation_type.company_type
        end

        if !conversation_user.messages.empty?
          last_message = conversation_user.messages.order(:created_at).last # NOTE: can not eager load(includes) messages because i cant limit the number of messages bein retrieved
          temp[:last_message] = last_message.body
          temp[:last_message_sender_name] = last_message.conversation_user.participant.user_profile.first_name
          temp[:last_message_sender_avatar] = last_message.conversation_user.participant.user_profile.avatar.url(:l)
          temp[:last_message_sender_initials] = last_message.conversation_user.participant.user_profile.get_initials
          temp[:last_message_send_at] = (I18n.localize last_message.created_at.to_time, format: :hour_minute)
          temp[:last_message_send_at_raw] = last_message.created_at
        end

        convs.push(temp)
      end
      convs = convs.sort_by { |a| [a[:last_message_send_at_raw] ? 1 : 0, a[:last_message_send_at_raw]] }.reverse # NOTE: i have no idea how this works but it does..
      convs
    end
end
