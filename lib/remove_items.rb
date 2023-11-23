# frozen_string_literal: true

# Module RemoveItems provides a utility method to remove items from multiple services.
module RemoveItems
  def self.remove_item_from_all_services(current_user, services_item)
    services_item.each do |key, item_id|
      key.constantize.new(current_user).remove_item(item_id)
    end
  end
end
