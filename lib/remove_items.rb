# frozen_string_literal: true

# Module RemoveItems provides a utility method to remove items from multiple services.
module RemoveItems
  def self.remove_item_from_all_services(user, services_item)
    services_item.each do |key, item_id|
      key.to_s.constantize.new(user).remove_item(item_id) if item_id.present?
    end
  end
end
