module ApplicationHelper
  # Preserve search and filter parameters when switching views
  def preserve_params_for_view_switch
    params.permit(:search, :status, :agent, :sort, :direction).to_h.symbolize_keys
  end
end
