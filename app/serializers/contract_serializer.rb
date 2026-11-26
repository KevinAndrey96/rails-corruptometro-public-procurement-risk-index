class ContractSerializer
  def initialize(contract)
    @contract = contract
  end

  def as_json(*)
    {
      id: @contract.id,
      reference: @contract.reference,
      object: @contract.object,
      modality: @contract.modality,
      signed_on: @contract.signed_on,
      start_on: @contract.start_on,
      end_on: @contract.end_on,
      initial_value: @contract.initial_value,
      additions_value: @contract.additions_value,
      bidders_count: @contract.bidders_count,
      risk_score: @contract.risk_score,
      risk_level: @contract.risk_level,
      red_flags: @contract.red_flags,
      entity: { id: @contract.entity_id, name: @contract.entity.name, nit: @contract.entity.nit },
      contractor: { id: @contract.contractor_id, name: @contract.contractor.name, document_type: @contract.contractor.document_type }
    }
  end
end
