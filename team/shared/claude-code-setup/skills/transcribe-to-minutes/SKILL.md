---
name: transcribe-to-minutes
description: "Transcribe audio recordings to internal meeting minutes using ptrans CLI. Covers speech-to-text conversion, misrecognition correction, topic restructuring, and automatic Notion page generation from audio files. Use when creating minutes from audio recordings, transcribing meeting recordings, converting voice files to structured meeting notes, or generating Notion minutes from recorded audio. Do not trigger for updating existing minutes with new recordings (use transcribe-and-update) or creating blank meeting templates (use create-minutes). Invoke with /transcribe-to-minutes."
user-invocable: true
---

# transcribe-to-minutes

MTG録音から内部議事録を自動生成する複合スキル。

## パイプライン

```
音声ファイル → ptrans(文字起こし) → 誤変換修正 → トピック再構成 → create-minutes(Notion作成)
```

## 前提

- `ptrans.sh` がインストール済み（`~/.claude/scripts/ptrans.sh`）
- `OPENAI_API_KEY` 環境変数が設定済み
- Notion MCP が接続済み

## 実行フロー

### Step 0: 前提条件チェック

パイプライン開始前に、以下の前提条件をすべて検証する。いずれか1つでも満たさない場合はエラーメッセージを表示して処理を停止する。

1. **ptrans.sh の存在確認**: `~/.claude/scripts/ptrans.sh` が存在するか `ls` で確認する。存在しない場合 → `エラー: ptrans.sh が見つかりません。~/.claude/scripts/ptrans.sh にインストールしてください。`
2. **OPENAI_API_KEY の確認**: 環境変数 `OPENAI_API_KEY` が設定されているか確認する。未設定の場合 → `エラー: OPENAI_API_KEY が設定されていません。OPENAI_API_KEY を .env や .zshrc に設定してください。`
3. **Notion MCP 接続確認**: `notion-search` ツールを呼び出してNotion MCPが応答するかテストする。接続できない場合 → `エラー: Notion MCP に接続できません。MCPサーバーの設定を確認してください。`

すべてパスしたら Step 1 に進む。

### Step 1: 文字起こし

```bash
~/.claude/scripts/ptrans.sh /path/to/meeting.m4a \
  --language ja \
  --json \
  --out /tmp/claude/transcript.json \
  --prompt "田中太郎 佐藤花子 プロジェクトAlpha スプリント"
```

**ポイント**:
- `--prompt` に参加者名・プロジェクト名を渡すと認識精度が上がる
- 25MB超の場合はユーザーに分割を依頼

### Step 2: 誤変換修正

Whisperの文字起こし結果に対して、以下の修正を順番に適用する:

1. **固有名詞の修正**: ユーザーから提供された参加者リストと照合し、ひらがな・カタカナ表記を漢字表記に統一する。プロジェクト名・チーム名等も同様に正式表記へ変換する。
   - 例: 「たなかたろう」「タナカタロウ」→「田中太郎」
   - 例: 「プロジェクトアルファ」→「プロジェクトAlpha」

2. **技術用語の統一**: `reference.md` の技術用語辞書に基づき、表記を統一する。辞書にない用語は一般的なカタカナ表記に揃える。
   - 例: 「デプロイ」「デプロい」「でぷろい」→「デプロイ」
   - 例: 「えーぴーあい」「エーピーアイ」→「API」

3. **フィラー除去**: 文頭の「えーと」「あの」「まあ」「なんか」を除去する。相槌の「そうですね」は、直前の発言に対する応答でなく単なる間つなぎの場合のみ除去する。意味のある応答（同意・肯定）としての「そうですね」は残す。

4. **句読点の正規化**: 文末の句点、読点の適切な配置

### Step 3: トピック再構成

文字起こしのタイムライン順テキストを、議題ベースに再構成する:

1. **議題の識別**: 以下の議題開始パターンを手がかりに、話題の切り替わりポイントを検出する。
   - 「〜について」「次の議題は」「それでは〜」「次に〜」
   - 事前に議題リストが提供されている場合は、それを優先してマッチングする。

2. **発言のグルーピング**: 同一議題に属する発言をまとめる

3. **決定事項の抽出**: 以下のパターンに該当する発言を決定事項として抽出する。
   - 「〜に決まり」「〜でいきましょう」「結論として〜」「〜ということで」

4. **TODOの抽出**: 以下のパターンに該当する発言をTODOとして抽出し、担当者・期限を紐づける。
   - 「〜お願いします」「〜対応します」「〜までに〜」「〜やっておきます」

5. **構造化**: 議題 > 議論内容 > 決定事項 > TODO の階層に整理

### Step 4: Notion議事録作成

`create-minutes` スキルを使って内部MTG議事録テンプレートを作成し、Step 3の内容を流し込む。

```
create-minutes で作成 → 内容を追記
```

最終的なNotionページの構造:

```markdown
[日付] [MTG名] 議事録

基本情報:
- 日時: (録音日時 or ユーザー指定)
- 参加者: (ユーザー指定)
- 記録者: AI文字起こし

## 1. [議題1]
### 議論内容
- 田中: 〜〜〜
- 佐藤: 〜〜〜

### 決定事項
- 〜〜〜

### TODO
- [ ] [田中] 〜〜〜 [期限: 1/25]

## 2. [議題2]
...

## 決定事項まとめ
- 〜〜〜

## 次回アクション
- [ ] [担当] [内容] [期限]
```

## 使い方

```
/transcribe-to-minutes

必要な情報:
1. 音声ファイルパス（m4a, mp3, wav等）
2. MTG名
3. 参加者リスト
4. Notion配置先（親ページID）
5. （任意）議題リスト（事前にわかっている場合）
```

## 品質向上のコツ

| テクニック | 効果 |
|-----------|------|
| `--prompt` に固有名詞を列挙 | 人名・プロジェクト名の認識精度UP |
| 議題リストを事前提供 | トピック分類の精度UP |
| 録音品質を上げる（マイク近く） | 全体の精度UP |
| 1時間以内の録音 | 処理速度・精度のバランス良い |

## 依存スキル

| スキル | 役割 |
|--------|------|
| `ptrans.sh` | 音声→テキスト変換 |
| `create-minutes` | Notion議事録テンプレート作成 |

## エラーハンドリング

| エラー | 対処 |
|--------|------|
| 音声ファイルが25MB超 | 分割を案内（ffmpegで分割可） |
| OPENAI_API_KEY未設定 | 環境変数設定を案内 |
| Whisper認識精度が低い | `--prompt` 追加、言語指定確認 |
| Notion MCP 未接続 | 再接続を案内 |

## Cross-references

- **create-minutes**: 議事録テンプレートの作成・Notion ページ生成
- **transcribe-and-update**: 既存議事録への録音データ差分マージ
