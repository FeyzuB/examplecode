class ConversationUser < ActiveRecord::Base
  attr_accessor :validation_step, :current_workspace_id
  belongs_to :participant, polymorphic: true
  belongs_to :conversation
  belongs_to :role

  has_many :message_recipients, dependent: :destroy
  has_many :messages, :through => :message_recipients
  has_many :senders, :class_name => "Message", :foreign_key => "conversation_user_id" # NOTE: these are messages that the user has sent = sender

  accepts_nested_attributes_for :conversation, :senders, :message_recipients

  validate :is_member, if: :check_is_member

  scope :all_user_conversations, -> (participant_type, participant_id) { where("conversation_users.participant_type = ? AND conversation_users.participant_id = ?", participant_type, participant_id).includes(:conversation) }
  scope :active_as_conversation_user, -> (conversation_id, participant_type, participant_id) { where(conversation_id: conversation_id, participant_type: participant_type, participant_id: participant_id, deleted_at: nil, removed_at: nil)}

  before_save :uniqueness_participant
  after_save :destroy_channel_conversation

  def get_messages(from_date)
    messages_show_cap = 30
    last_size_cap = messages_show_cap + 1

    temp = {}
    temp.store(:messages, {})
    last_send = DateTime.now
    new_day_intro = "Vandaag"

    previous_sender = 0
    hash_key = 0
    self.update_attribute(:reminder_count, 0) unless self.reminder_count == 0
    self.message_recipients.where(read_at: nil).update_all(read_at: DateTime.now) # NOTE: read all messages

    messages = self.messages.before(from_date).includes(:active_message_recipients, conversation_user: [conversation: [assignment: [:company]], participant: [:user_profile]]).order(:created_at).last(last_size_cap)

    has_more_messages = messages.size > messages_show_cap ? true : false
    temp.store(:has_more_messages, has_more_messages)

    messages.last(messages_show_cap).each do |message|
      read_all = message.active_message_recipients.select {|mr| mr.read_at.nil? }.empty? ? true : false

      message_send_at = message.created_at
      is_new_day = !(Time.at(last_send).to_date === Time.at(message_send_at).to_date)

      if is_new_day
        if message_send_at.to_date == Date.today
          new_day_intro = "Vandaag"
        elsif message_send_at.to_date == Date.yesterday
          new_day_intro = "Gisteren"
        else
          new_day_intro = I18n.localize message_send_at.to_date
        end
        temp[:messages].store(new_day_intro, {})
        previous_sender = 0
      else
        temp[:messages].store(new_day_intro, {}) if temp[:messages][new_day_intro].nil?
      end

      if previous_sender != message.conversation_user_id
        previous_sender = message.conversation_user_id
        hash_key = "#{previous_sender}_#{SecureRandom.hex}"
        if message.conversation_user.participant_type == "User"
          send_by_company_logo = message.conversation_user.conversation.assignment.company.logo(:xxl)
          send_by_company_type = message.conversation_user.conversation.assignment.company.organisation_type.company_type
        else
          send_by_company_logo = message.conversation_user.conversation.company.logo(:xxl)
          send_by_company_type = message.conversation_user.conversation.company.organisation_type.company_type
        end

        temp[:messages][new_day_intro].store((hash_key), {
          :send_by => message.conversation_user_id,
          :send_by_name => message.conversation_user.participant.user_profile.get_full_name,
          :send_by_initials => message.conversation_user.participant.user_profile.get_initials,
          :send_by_avatar => message.conversation_user.participant.user_profile.avatar.url(:l),
          :send_by_company_logo => send_by_company_logo,
          :messages => {}
        })
      end

      temp_mes = {
        :body => message.body,
        :time_send => (I18n.localize message.created_at.to_time, format: :hour_minute),
        :time_send_raw => message_send_at,
        :read_all => read_all
      }
      temp[:messages][new_day_intro][hash_key][:messages].store(message.id, temp_mes)

      last_send = message_send_at
      previous_sender = message.conversation_user_id

    end
    temp
  end

  def send_message(message, workspace)
    return self if message.gsub(/[[:space:]]/, '') == ""

    self.current_workspace_id = workspace.id unless workspace.nil?
    self.validation_step = "send_message"

    presence_conversation = Pusher.channel_users("presence-conversation-#{self.conversation_id}")

    self.senders.build(body: message, conversation_id: self.conversation_id)
    self.conversation.conversation_users.each do |cu|
      if cu.left_at.nil? && cu.deleted_at.nil? && cu.removed_at.nil?
        cu.message_recipients.build(message: self.senders.last)
        cu.reminder_count = 0
        user_id = cu.participant.class.name == "User" ? cu.participant.id : cu.participant.user_id
        cu.message_recipients.last.read_at = DateTime.now if cu.id == self.id || !presence_conversation[:users].select {|kk| kk["id"] == user_id.to_s}.empty?
      end
    end

    if self.valid?
      self.save
      Conversation.trigger_new_message_partner_talk(self.senders.last, self, self.conversation)
    end
    return self
  end

  def delete_user(cu_id, workspace)
  end

  private
  def destroy_channel_conversation
    unless self.deleted_at.nil? && self.removed_at.nil?

      user = case self.participant_type
      when "User"
        self.participant.id
      when "UserCompany"
        self.participant.user_id
      end

     eventData = {
       "conversation_user_id" => self.id,
       "conversation_id" => self.conversation_id,
       "user_id" => user
     }
      Pusher.trigger("presence-conversation-#{self.conversation_id}", 'delete_member', eventData)
    end
  end

  def uniqueness_participant
    if ConversationUser.exists?(participant_id: self.participant_id, participant_type: self.participant_type, deleted_at: nil, removed_at: nil)
      return true
      puts "already exists"
    end
  end

  def check_is_member
    validation_step == "send_message"
  end

  def is_member
    user_obj = self.participant_type == "User" ? self.participant : self.participant.user
    unless self.conversation.is_member?(user_obj, self.current_workspace_id)
      errors.add(:participant, I18n.translate('activerecord.errors.models.conversation_users.attributes.participant.not_a_member'))
    end
  end


end
