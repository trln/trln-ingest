module DashboardHelper
  def solrstatus_to_bootstrap_item(status)
    suffix = case status.downcase
             when 'ok'
               'success'
             else
               'warning'
             end
    "list-group-item-#{suffix}"
  end
end
