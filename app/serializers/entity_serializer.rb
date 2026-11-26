class EntitySerializer
  def initialize(entity)
    @entity = entity
  end

  def as_json(*)
    {
      id: @entity.id,
      name: @entity.name,
      nit: @entity.nit,
      level: @entity.level,
      department: @entity.department,
      risk_index: @entity.risk_index,
      risk_level: @entity.risk_level,
      contracts_count: @entity.contracts_count,
      contracted_value: @entity.contracted_value
    }
  end
end
