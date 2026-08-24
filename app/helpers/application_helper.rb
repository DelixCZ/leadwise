module ApplicationHelper
  def ai_score_badge(score, size: :md)
    if score.nil?
      return content_tag(:span, "Pending", class: score_badge_classes("bg-slate-100 text-slate-600 ring-slate-200", size))
    end

    color_classes =
      case score
      when 80..100 then "bg-emerald-50 text-emerald-800 ring-emerald-200"
      when 50..79 then "bg-amber-50 text-amber-800 ring-amber-200"
      else "bg-rose-50 text-rose-800 ring-rose-200"
      end

    content_tag(:span, score, class: score_badge_classes(color_classes, size))
  end

  private

  def score_badge_classes(color_classes, size)
    size_classes =
      case size
      when :lg then "px-3 py-1.5 text-base"
      else "px-2.5 py-0.5 text-sm"
      end

    "inline-flex items-center justify-center rounded-full font-semibold tabular-nums ring-1 ring-inset #{size_classes} #{color_classes}"
  end
end
