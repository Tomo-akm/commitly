module EntrySheetAdvicePromptable
  extend ActiveSupport::Concern

  private

  def build_advice_prompt(company_name:, title:, content:, char_limit:)
    <<~PROMPT
      あなたはES（エントリーシート）添削の専門家です。以下のES項目を添削し、改善点と改善例を提示してください。

      【企業】#{company_name}
      【設問】#{title}
      【文字数制限】#{char_limit.present? ? "#{char_limit}文字" : "なし"}
      【現在の回答】
      #{content}

      以下の形式で必ず出力してください。この形式を厳密に守ってください：

      ## 改善ポイント

      - **具体性**: [ここに具体性に関する指摘を1-2行で記載]
      - **論理構成**: [ここに論理構成に関する指摘を1-2行で記載]
      - **企業適合性**: [ここに企業適合性に関する指摘を1-2行で記載]

      ## 改善例

      ```
      [ここに改善された回答文を記載。文字数制限がある場合はそれを守る]
      ```

      注意：
      - 必ず「## 改善ポイント」という見出しから始めてください
      - 改善例の前には必ず「## 改善例」という見出しを入れてください
      - コードブロック（```）の前後には必ず空行を入れてください
      - [ここに〜]というプレースホルダーは実際の内容に置き換えてください
    PROMPT
  end
end
