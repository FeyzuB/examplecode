class Message < ActiveRecord::Base
  belongs_to :conversation
  has_many :message_recipients, dependent: :destroy
  belongs_to :conversation_user

  has_many :active_message_recipients, -> { joins(:conversation_user).where("conversation_users.deleted_at IS NULL AND conversation_users.removed_at IS NULL") }, class_name: "MessageRecipient"

  accepts_nested_attributes_for :message_recipients, :conversation_user



  def self.check_read_status(messages)
    message_ids = []
    messages.each do |message|
      message_id = message.split("_")[-1].to_i
      next if message_id == 0
      message_ids << message_id
    end

    message_status = []
    Message.where(id: message_ids).includes(:active_message_recipients).each do |message|
      temp = {}
      temp[:message_id] = message.id
      temp[:read_all] = message.active_message_recipients.select {|mr| mr.read_at.nil? }.empty? ? true : false
      message_status.push(temp)
    end
    message_status
  end
end
