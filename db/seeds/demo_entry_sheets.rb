# frozen_string_literal: true

# デモ用ES・テンプレートの作成
puts "=== デモ用ES・テンプレートを作成中 ==="

demo = User.find_by(account_id: "demo")
yuki = User.find_by(account_id: "yuki_dev")
riku = User.find_by(account_id: "riku_26")
miku = User.find_by(account_id: "miku_anx")
senpai = User.find_by(account_id: "senpai_naitei")

# ===========================================
# テンプレート作成（demo, yuki, senpai）
# ===========================================
puts "  テンプレートを作成中..."

# demo のテンプレート
if demo
  EntrySheetItemTemplate.find_or_create_by!(user: demo, tag: "ガクチカ", title: "チーム開発でのガクチカ") do |t|
    t.content = <<~CONTENT
      大学3年時、4人チームでWebアプリケーションを開発しました。
      私はバックエンド担当として、Ruby on Railsを用いたAPI設計を担当しました。

      開発中、メンバー間で仕様の認識齟齬が発生し、手戻りが多発する課題がありました。
      そこで私は週次でのドキュメント共有会を提案・実施し、仕様書のレビュー文化を導入しました。

      結果、手戻りが約60%削減され、予定通りにリリースできました。
      この経験から、技術力だけでなく、チームでの認識合わせの重要性を学びました。
    CONTENT
  end

  EntrySheetItemTemplate.find_or_create_by!(user: demo, tag: "自己PR", title: "継続力をアピール") do |t|
    t.content = <<~CONTENT
      私の強みは「継続力」です。

      大学入学時からプログラミング学習を始め、3年間毎日最低1時間のコーディングを継続しています。
      AtCoderでは緑レートを達成し、GitHubでは500日以上の草を生やし続けています。

      この継続力は、技術の習得だけでなく、困難な課題に直面しても諦めずに取り組む姿勢として活かせます。
      御社でも、日々の業務改善や新技術のキャッチアップに継続的に取り組み、貢献していきたいです。
    CONTENT
  end
end

# senpai のテンプレート（公開用）
if senpai
  EntrySheetItemTemplate.find_or_create_by!(user: senpai, tag: "志望動機", title: "IT業界志望動機（汎用）") do |t|
    t.content = <<~CONTENT
      私がIT業界を志望する理由は、技術を通じて社会課題を解決したいからです。

      大学で○○を学ぶ中で、IT技術が様々な業界の課題解決に貢献していることを知りました。
      特に御社の○○というサービスは、△△という課題を解決しており、強く共感しています。

      私は□□の経験を通じて培った「課題発見力」と「技術力」を活かし、
      御社で新たな価値を生み出すエンジニアとして成長したいと考えています。
    CONTENT
  end

  EntrySheetItemTemplate.find_or_create_by!(user: senpai, tag: "挫折経験", title: "挫折経験テンプレート") do |t|
    t.content = <<~CONTENT
      【挫折経験】
      ○○に取り組んだ際、△△という壁にぶつかりました。

      【乗り越え方】
      最初は□□を試みましたが、うまくいきませんでした。
      そこで、原因を分析し、◇◇というアプローチに切り替えました。

      【学び】
      この経験から、××の重要性を学びました。
      現在は、この学びを活かして◎◎に取り組んでいます。
    CONTENT
  end
end

# ===========================================
# ES作成（公開ES + 通過版/不通過版の対比）
# ===========================================
puts "  ESを作成中..."

# yuki の公開ES（通過版）
if yuki
  es = EntrySheet.find_or_create_by!(
    user: yuki,
    company_name: "GlobalLogic"
  ) do |e|
    e.status = :passed
    e.visibility = :shared
    e.shared_at = 3.days.ago
  end

  unless es.entry_sheet_items.exists?
    es.entry_sheet_items.create!(
      title: "志望動機（400字以内）",
      content: <<~CONTENT.strip,
        私がGlobalLogicを志望する理由は、グローバルな環境で技術力を磨きながら、世界中のユーザーに価値を届けたいからです。

        インターンシップで3ヶ月間、実際のプロダクト開発に参加しました。多国籍なチームでの開発は最初は大変でしたが、技術という共通言語でコミュニケーションが取れることに感動しました。

        特に印象的だったのは、コードレビュー文化です。国籍に関係なく、良いコードには賞賛が、改善点には具体的なアドバイスがもらえる環境で、技術者として大きく成長できました。

        この経験を通じて、グローバルな環境で働くことへの確信を持ちました。御社で世界水準の技術力を身につけ、グローバルに活躍するエンジニアになりたいです。
      CONTENT
      char_limit: 400,
      position: 0
    )

    es.entry_sheet_items.create!(
      title: "学生時代に力を入れたこと（600字以内）",
      content: <<~CONTENT.strip,
        学生時代に最も力を入れたのは、5社でのインターンシップ経験です。

        大学2年時、「実務経験なしでは就活で不利になる」という危機感から、積極的にインターンに応募し始めました。最初は書類で落ち続けましたが、ポートフォリオを充実させることで徐々に通過率が上がりました。

        特に成長を感じたのは、GlobalLogicでの3ヶ月間の長期インターンです。実際のプロダクトのコードベースは想像以上に複雑で、最初は何も貢献できませんでした。しかし、毎日先輩エンジニアに質問し、コードリーディングを重ね、2ヶ月目からは機能追加のPRを出せるようになりました。

        5社での経験を通じて、技術力だけでなく「わからないことを素直に聞く力」「チームで成果を出す力」を身につけました。特に、異なる企業文化やコーディング規約に適応する経験は、どんな環境でも活躍できる自信につながっています。

        この経験を活かし、御社でも早期にキャッチアップし、チームに貢献できるエンジニアになりたいです。
      CONTENT
      char_limit: 600,
      position: 1
    )
  end
end

# demo の公開ES（レビュー依頼用）
if demo
  es = EntrySheet.find_or_create_by!(
    user: demo,
    company_name: "TechNova"
  ) do |e|
    e.status = :in_progress
    e.visibility = :shared
    e.shared_at = 1.day.ago
  end

  unless es.entry_sheet_items.exists?
    es.entry_sheet_items.create!(
      title: "志望動機（400字以内）",
      content: <<~CONTENT.strip,
        私がTechNovaを志望する理由は、インターンシップで感じた「エンジニアを大切にする文化」に惹かれたからです。

        2週間のインターンで、毎日のコードレビューと1on1を通じて、技術的にも人間的にも成長できました。特に「失敗を恐れずチャレンジする」という文化は、私の価値観と一致しています。

        私は大学でRuby on Railsを学び、個人開発で就活管理アプリを作成しました。この経験を活かし、御社のプロダクト開発に貢献したいです。

        また、御社が掲げる「技術で社会を良くする」というミッションに共感しています。将来的には、技術力を磨きながら、ユーザーの課題を解決するプロダクト作りに携わりたいです。
      CONTENT
      char_limit: 400,
      position: 0
    )

    es.entry_sheet_items.create!(
      title: "学生時代に力を入れたこと（400字以内）",
      content: <<~CONTENT.strip,
        学生時代に力を入れたのは、プログラミング学習と個人開発です。

        大学2年からRuby on Railsを学び始め、3年目には就活管理アプリ「Commitly」を個人開発しました。このアプリは、就活生が選考状況を記録・共有できるSNS型のサービスです。

        開発で最も苦労したのは、リアルタイム通信の実装です。WebSocketの概念を理解するのに時間がかかりましたが、公式ドキュメントを読み込み、実際に動くものを作ることで理解を深めました。

        この経験から、「わからないことは手を動かして学ぶ」という姿勢が身につきました。御社でも、新しい技術に積極的にチャレンジし、成長し続けたいです。
      CONTENT
      char_limit: 400,
      position: 1
    )
  end

  # demo の非公開ES（不通過版）
  es_failed = EntrySheet.find_or_create_by!(
    user: demo,
    company_name: "BlueSystems"
  ) do |e|
    e.status = :failed
    e.visibility = :personal
  end

  unless es_failed.entry_sheet_items.exists?
    es_failed.entry_sheet_items.create!(
      title: "志望動機（400字以内）",
      content: <<~CONTENT.strip,
        私がBlueSystems を志望する理由は、SIerとして幅広い業界の課題解決に携わりたいからです。

        御社は金融、製造、公共など様々な業界のシステム開発を手がけており、多様な経験を積めると考えています。

        私は大学でプログラミングを学び、Webアプリケーションの開発経験があります。この経験を活かして、御社で活躍したいと考えています。
      CONTENT
      char_limit: 400,
      position: 0
    )
  end
end

# riku の公開ES（レビュー依頼用）
if riku
  es = EntrySheet.find_or_create_by!(
    user: riku,
    company_name: "DataBridge"
  ) do |e|
    e.status = :in_progress
    e.visibility = :shared
    e.shared_at = 2.days.ago
  end

  unless es.entry_sheet_items.exists?
    es.entry_sheet_items.create!(
      title: "志望動機（400字以内）",
      content: <<~CONTENT.strip,
        私がDataBridgeを志望する理由は、社会インフラを支えるシステム開発に携わりたいからです。

        御社が手がける金融系システムは、多くの人々の生活を支える重要な基盤です。安定性と信頼性が求められる開発に挑戦し、社会に貢献したいと考えています。

        大学ではPythonでデータ分析を学び、卒業研究ではデータベースの最適化に取り組みました。この経験を活かし、御社の大規模システム開発に貢献したいです。

        また、御社の研修制度が充実していると伺いました。未経験の技術も積極的に学び、幅広いスキルを持つエンジニアに成長したいです。
      CONTENT
      char_limit: 400,
      position: 0
    )
  end
end

# miku の公開ES（レビュー依頼用 - 改善前）
if miku
  es = EntrySheet.find_or_create_by!(
    user: miku,
    company_name: "CodeWave"
  ) do |e|
    e.status = :draft
    e.visibility = :shared
    e.shared_at = 1.day.ago
  end

  unless es.entry_sheet_items.exists?
    es.entry_sheet_items.create!(
      title: "志望動機（400字以内）",
      content: <<~CONTENT.strip,
        私がCodeWaveを志望する理由は、Web開発に興味があるからです。

        大学でJavaScriptを学び、簡単なWebサイトを作ったことがあります。御社のサービスを使ってみて、使いやすいと思いました。

        プログラミングを始めて1年ですが、毎日勉強しています。まだわからないことも多いですが、頑張って成長したいです。

        御社で働きながら、もっと技術を身につけたいと思っています。よろしくお願いします。
      CONTENT
      char_limit: 400,
      position: 0
    )
  end
end

# senpai の公開ES（通過版 - お手本）
if senpai
  es = EntrySheet.find_or_create_by!(
    user: senpai,
    company_name: "GlobalLogic"
  ) do |e|
    e.status = :passed
    e.visibility = :shared
    e.shared_at = 300.days.ago
  end

  unless es.entry_sheet_items.exists?
    es.entry_sheet_items.create!(
      title: "志望動機（400字以内）",
      content: <<~CONTENT.strip,
        私がGlobalLogicを志望する理由は2つあります。

        1つ目は、グローバルな環境で技術力を磨きたいからです。インターンで3ヶ月間、多国籍チームでの開発を経験し、技術という共通言語で世界中のエンジニアと協働できることに感動しました。御社でなら、この経験を活かしながらさらに成長できると確信しています。

        2つ目は、御社のエンジニアリング文化に共感したからです。コードレビューを通じた知識共有、失敗を学びに変える文化は、私が理想とするエンジニア像と一致しています。

        入社後は、まず技術力を磨き、3年後にはチームをリードできるエンジニアになることを目指します。御社の成長に貢献しながら、自分自身も成長していきたいです。
      CONTENT
      char_limit: 400,
      position: 0
    )

    es.entry_sheet_items.create!(
      title: "挫折経験とそこから学んだこと（400字以内）",
      content: <<~CONTENT.strip,
        最も大きな挫折は、初めてのチーム開発でプロジェクトを失敗させたことです。

        大学2年時、4人チームでWebアプリを開発しましたが、締め切りに間に合わず、発表会で動かないアプリを見せることになりました。原因は、私がリーダーとして進捗管理を怠り、各自が何をしているか把握できていなかったことです。

        この失敗から、「コミュニケーションの重要性」と「小さく作って確認する」ことの大切さを学びました。以降のプロジェクトでは、毎日15分の進捗共有会を設け、週次でデモを行う運用に変更しました。

        結果、次のプロジェクトでは予定通りにリリースでき、チームメンバーからも「進め方が改善された」と評価されました。この経験は、現在の「早めに共有し、早めにフィードバックを得る」という開発スタイルの原点になっています。
      CONTENT
      char_limit: 400,
      position: 1
    )
  end
end

puts "=== デモ用ES・テンプレート作成完了 ==="