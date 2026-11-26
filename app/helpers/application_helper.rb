module ApplicationHelper
  def cop(value)
    number_to_currency(value.to_i, unit: "$", precision: 0, delimiter: ".", format: "%u %n")
  end

  def compact_cop(value)
    amount = value.to_i
    return cop(amount) if amount < 1_000_000

    millions = number_with_precision(amount / 1_000_000.0, precision: 1, delimiter: ".", separator: ",", strip_insignificant_zeros: true)
    t("helpers.money.millions", amount: millions)
  end

  def percentage(ratio)
    number_to_percentage(ratio.to_f * 100, precision: 1, separator: ",", strip_insignificant_zeros: true)
  end

  def risk_badge(score)
    level = RiskLevel.for(score)
    tag.span(t("risk_levels.badge", score: score, level: t("risk_levels.#{level}")), class: "badge badge-#{level}")
  end

  def flag_chip(flag)
    link_to flag.name, contracts_path(flag: flag.key), class: "chip", title: flag.description
  end

  def contractor_document(contractor)
    return "NIT #{contractor.document_number}" if contractor.nit?

    "CC ****#{contractor.document_number.last(4)}"
  end

  def entity_level_options
    Entity.levels.keys.map { |level| [ t("entities.levels.#{level}"), level ] }
  end

  def modality_options
    Contract.modalities.keys.map { |modality| [ t("contracts.modalities.#{modality}"), modality ] }
  end

  def flag_options
    RedFlag.all.map { |flag| [ flag.name, flag.key ] }
  end

  def nav_link(label, path)
    link_to label, path, class: ("active" if current_page?(path)), aria: { current: ("page" if current_page?(path)) }
  end
end
