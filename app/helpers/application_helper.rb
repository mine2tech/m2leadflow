module ApplicationHelper
  def sidebar_link(label, path, icon_svg, controllers: [])
    active = controllers.include?(controller_name)
    link_to path, class: "group flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition-colors duration-150 #{active ? 'bg-slate-800 text-white' : 'text-slate-300 hover:bg-slate-800/50 hover:text-slate-200'}" do
      raw(icon_svg) + content_tag(:span, label)
    end
  end

  def badge_variant_for(status)
    case status.to_s
    when "enriched", "completed", "sent", "active", "replied"
      "badge-success"
    when "pending", "claimed", "processing", "scheduled", "drafted", "new_company"
      "badge-warning"
    when "failed", "exhausted", "revoked", "cancelled"
      "badge-danger"
    when "in_progress", "reviewed"
      "badge-info"
    when "draft", "skipped", "pending_stage", "expired"
      "badge-neutral"
    when "meeting"
      "badge-primary"
    else
      "badge-neutral"
    end
  end

  def pipeline_stage_color(stage)
    case stage.to_sym
    when :pending  then "bg-slate-400"
    when :drafted  then "bg-amber-400"
    when :sent     then "bg-sky-400"
    when :replied  then "bg-emerald-400"
    when :meeting  then "bg-indigo-500"
    else "bg-slate-300"
    end
  end

  def initials_for(name)
    return "?" unless name.present?
    name.split(/[\s.]+/).map(&:first).first(2).join.upcase
  end
end
