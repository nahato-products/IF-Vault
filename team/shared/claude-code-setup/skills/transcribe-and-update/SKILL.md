---
name: transcribe-and-update
description: "Update existing Notion meeting minutes by transcribing audio recordings via ptrans, detecting differences against existing content, and merging missing information. Use when supplementing existing minutes with recording data, updating minutes after meetings, reflecting additional information from audio recordings, or filling gaps in manually written meeting notes. Do not trigger for creating new minutes from scratch (use transcribe-to-minutes) or generating blank templates (use create-minutes). Invoke with /transcribe-and-update."
user-invocable: true
---

# transcribe-and-update

外部MTG録音を文字起こしし、既存の議事録ページに差分マージする複合スキル。

## ユースケース

事前に `create-minutes` や `fill-external-minutes` で議事録の骨子を作成済み。
MTG後に録音データから追加情報を既存議事録にマージする。

```
既存議事録（骨子） + 録音文字起こし → 補完・更新された議事録
```

## パイプライン

```
録音 → ptrans(文字起こし) → 誤変換修正 → 既存議事録取得 → 差分検出 → マージ → Notion更新
```

## 実行フロー

### Step 1: 文字起こし

```bash
~/.claude/scripts/ptrans.sh /path/to/external-meeting.m4a \
  --language ja \
  --json \
  --out /tmp/claude/ext-transcript.json \
  --prompt "山田太郎様 鈴木花子様 プロジェクトBeta 要件定義"
```

### Step 2: 誤変換修正

`transcribe-to-minutes` と同じ修正ロジックを適用:
- 固有名詞修正（参加者名・プロジェクト名）
- 技術用語統一
- フィラー除去
- 句読点正規化

### Step 3: 既存議事録の取得

```
notion_get_page_content(page_id: "<既存議事録のページID>")
→ 現在の議事録内容をMarkdownで取得
```

### Step 4: 差分検出（キーワードマッチング）

#### 4-1. 議題キーワード抽出

既存議事録の各 `##` 見出しを議題キーワードとして取得する。

```
例: "## 1. 要件定義の確認" → キーワード: "要件定義"
    "## 2. スケジュール調整" → キーワード: "スケジュール"
```

#### 4-2. セグメント分割

文字起こしテキストを議題キーワードでセグメント分割する（キーワード出現位置で区切り）。
キーワードが初めて出現した位置から次のキーワード出現位置までを1セグメントとする。

#### 4-3. パターン検出

各セグメント内で以下のパターンをマッチングして情報を抽出する:

| パターン | マッチ例 | 抽出対象 |
|----------|---------|---------|
| **決定事項** | `〜に決定` `〜でいく` `〜にしましょう` `〜ということで` | 決定内容の文 |
| **TODO** | `〜お願い` `〜対応する` `〜までに` `〜やっておきます` | タスク・担当・期限 |
| **補足情報** | 具体的な数字・日付・固有名詞を含む発言 | 詳細データ |

#### 4-4. 新規情報の抽出

既存議事録の同一議題セクションと比較し、キーフレーズが一致しない新規情報のみ抽出する。
既に記載済みの内容は重複として除外する。

#### 差分タイプ一覧

| 差分タイプ | 内容 | アクション |
|-----------|------|-----------|
| **追加情報** | 議事録にない議論内容 | 該当議題に追記 |
| **決定事項の補完** | 口頭で決まったが未記載 | 決定事項に追加 |
| **TODO追加** | 録音で判明した新タスク | アクション一覧に追加 |
| **修正** | 議事録の記述と録音が矛盾 | `[録音確認]` マーク付きで併記 |
| **詳細化** | 概要のみ → 具体的な数字・日付 | 既存内容を詳細化 |

### Step 5: マージ方針

**原則**: 既存内容を壊さず、追加・補完のみ行う

#### 挿入位置ルール

| 抽出された情報 | 挿入先 | フォーマット |
|--------------|--------|------------|
| 決定事項 | 既存の `### 決定事項` セクションに追記 | `[🎙️]` プレフィックス付き |
| TODO | 既存の `### TODO` セクションに追記 | `[🎙️]` プレフィックス付き |
| 補足・議論内容 | 各議題セクションの末尾に `### 🎙️ 録音から追加` サブセクションを挿入 | 発言者名付き箇条書き |
| マッチする議題なし | `## その他（録音から追加）` セクションにまとめる | 発言者名付き箇条書き |

#### マージ例

```markdown
## 1. 要件定義の確認

### 既存の内容
概要: 要件定義書の内容を確認しました。

### 決定事項
- 要件定義書v2をベースに進める
- [🎙️] パフォーマンス要件をSLAに追加する

### TODO
- [ ] [弊社] 要件定義書v2の送付 [期限: 2/5]
- [ ] [🎙️] [弊社] SLA案の作成 [期限: 2/7]
- [ ] [🎙️] [山田様] 利用デバイス一覧の共有 [期限: 2/3]

### 🎙️ 録音から追加
- 山田様: 検索機能の応答速度は2秒以内を希望
- 鈴木様: モバイル対応は必須。iPadでの利用が多い

## その他（録音から追加）
- 山田様: 次回は開発チームも同席してほしいとのこと
```

### Step 6: Notion更新

マージ結果をNotionページに反映:

```
notion_update_page(page_id: "<ページID>", content: "<マージ済みMarkdown>")
```

## 使い方

```
/transcribe-and-update

必要な情報:
1. 音声ファイルパス
2. 既存議事録のNotionページID or URL
3. 参加者リスト（固有名詞認識用）
4. （任意）特に補完したい項目
```

## マージの表示規則

| マーカー | 意味 |
|---------|------|
| `[🎙️ 録音補完]` | 録音から追加された情報 |
| `[録音確認]` | 既存内容と矛盾がある箇所 |
| `[🎙️ TODO追加]` | 録音で判明した新タスク |

→ ユーザーが最終確認後、マーカーを除去して確定

## 依存スキル

| スキル | 役割 |
|--------|------|
| `ptrans.sh` | 音声→テキスト変換 |

## 注意事項

- 既存議事録のバックアップ: 更新前にNotionのページ履歴で復元可能
- マージ結果は必ずユーザーにプレビュー表示してから更新
- 矛盾箇所は自動解決せず、両方を併記して判断を委ねる
- 外部向け議事録（Notionページタイトルに「外部」を含む or ユーザー指定）の場合は、マージ完了後に `fill-external-minutes` スキルの機密フィルタリングルールを適用する

## Cross-references

- **transcribe-to-minutes**: 新規文字起こしとの使い分け
- **create-minutes**: 更新対象の議事録テンプレート
