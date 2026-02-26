# Claude Code Instructions

## Identity

- **日本語で応対**

## Rules

- Git: 必ず確認してからコミット。機密情報・10MB超ファイルは絶対にコミットしない
- 危険コマンド（rm -rf, git push --force等）は事前確認必須
- 既存ファイル編集優先。ドキュメント・新規ファイルは必要時のみ
- 外部APIキーは必ず環境変数経由。ハードコード禁止
- Compact復帰時: `~/.claude/session-env/compact-state.md` を読んで復元

## Context

- スタック: Next.js 15 App Router, TypeScript, Supabase, Tailwind CSS v4
- スキル管理: `/skill-forge` / トークン最適化: `/context-economy`
