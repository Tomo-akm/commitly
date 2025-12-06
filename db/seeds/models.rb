Model.delete_all

models = {
  openai: [
    [ "GPT-5", "gpt-5" ],
    [ "GPT-5 Mini", "gpt-5-mini" ],
    [ "GPT-5 Nano", "gpt-5-nano" ],
    [ "GPT-5 Pro", "gpt-5-pro" ]
  ],
  anthropic: [
    [ "Claude Opus 4.1", "claude-opus-4-1" ],
    [ "Claude Sonnet 4.5", "claude-sonnet-4-5" ],
    [ "Claude Haiku 4.5", "claude-haiku-4-5" ]
  ]
}

models.each do |provider, list|
  list.each do |name, model_id|
    Model.find_or_create_by!(provider: provider, model_id: model_id) do |m|
      m.name = name
    end
  end
end

puts "✅ #{Model.count} models created/updated"
