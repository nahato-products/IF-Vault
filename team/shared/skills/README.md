# チーム共有 Skills

guchiが作成・厳選したClaude Code Skillsの共有フォルダ。

## 共有スキル一覧

| スキル | 内容 | 行数 |
|---|---|---|
| ux-psychology | アプリ開発特化UX 29原則+ニールセン10H+AI UX+ニューロダイバーシティ。自動適用 | 415行（+ref 246行） |

## セットアップ手順

### 1. シンボリンクを作成

```bash
ln -s "$(pwd)/team/shared/skills/ux-psychology" ~/.claude/skills/ux-psychology
```

Vault のルートディレクトリで実行すること。

### 2. 確認

Claude Codeを起動してUI/UX関連の作業をすると自動で発火する。
`user-invocable: false` なのでコマンド呼び出しは不要。

## 更新について

- このフォルダのSKILL.mdを更新すれば、シンボリンク経由で全メンバーに反映される
- `git pull` するだけでOK。再リンク不要
