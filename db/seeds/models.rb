Model.delete_all

models = {
  anthropic: [
    [ "Claude Opus 4.1", "claude-opus-4-1" ],
    [ "Claude Sonnet 4.5", "claude-sonnet-4-5" ],
    [ "Claude Haiku 4.5", "claude-haiku-4-5" ]
  ]
}

records = models.flat_map do |provider, list|
  list.map do |name, model_id|
    {
      provider: provider,
      model_id: model_id,
      name: name,
      created_at: Time.current,
      updated_at: Time.current
    }
  end
end

Model.upsert_all(
  records,
  unique_by: %i[provider model_id]
)

puts "✅ #{Model.count} models created/updated"
