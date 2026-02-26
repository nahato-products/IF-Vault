---
name: micro-interaction-patterns
description: "Framer Motion micro-interactions: loading/skeleton, toast/sonner, form validation UX, AnimatePresence, button states, streaming"
user-invocable: false
---

# Micro-Interaction & UI State Patterns

Next.js App Router + Tailwind CSS + Framer Motion 環境での実装ガイド。

## When to Apply

- ローディング/スケルトンUI/シマー効果の実装
- トースト通知/スナックバー/バナーの設計
- フォームバリデーションのタイミングとエラー表示
- 空状態（初回/検索0件/エラー）の設計
- エラーバウンダリ/リトライ/グレースフルデグラデーション
- 成功フィードバック/ページ遷移/リストアニメーション
- ボタンのhover/focus/active/disabled/loading状態
- ストリーミングUI/Server Actions pending/AI応答ストリーミング

## When NOT to Apply / Skill Boundaries

| 関心事 | このスキルの役割 | 参照先スキル |
|--------|----------------|-------------|
| 認知心理学の「なぜそうすべきか」 | 実装の「どうやるか」（コード） | ux-psychology（Doherty閾値、Hick's Law等） |
| WCAG準拠/aria/セマンティックHTML | aria-invalid、role="alert"等の実装時の最低限のみ | web-design-guidelines（コントラスト比、フォーカス管理） |
| アニメーションのランタイム最適化 | 状態遷移パターンの設計・実装 | vercel-react-best-practices（content-visibility、dynamic import、SVGアニメ最適化） |
| コンポーネントAPI設計/合成パターン | UI状態(loading/error/empty)のフィードバック表示 | react-component-patterns（useOptimistic のコンポーネント設計、CVAバリアント） |
| デザイントークン定義 | トークンの利用側（duration/easing参照） | design-token-system（duration/easing/keyframeトークン定義） |
| エラーハンドリング戦略/ロギング | UI上のエラー表示・リトライパターン | error-handling-logging（AppError分類、Sentry連携） |

---

## Decision Tree

ユーザーの操作 → フィードバックが必要？ → Yes → 即時応答（< 100ms）が可能？ → Yes → CSS transition（hover/focus/active: Part 8） → No → 400ms 以内に完了？ → Yes → スピナー不要、楽観的UI更新（Part 1.4） → No → Skeleton/Shimmer 表示（Part 1） → エラー発生？ → Yes → error.tsx boundary + リトライ（Part 5） → No → 成功フィードバック（Toast: Part 2 / チェックマーク: Part 6） → 操作結果の通知？ → 一時的 → Toast（Part 2） / 永続 → Inline alert / Banner

---

## Part 1: Loading States [CRITICAL]

### 1. loading.tsx（ルートレベル）

App Router の `loading.tsx` は自動で Suspense バウンダリを生成する。

```tsx
// app/dashboard/loading.tsx — 同階層 page.tsx を自動ラップ
export default function Loading() { return <DashboardSkeleton />; }
```

- ナビゲーション時に instant loading state として即座に表示

### 2. Suspense（コンポーネントレベル）

独立したデータフェッチごとに `Suspense` で囲み、段階的にUIを表示する。

```tsx
<Suspense fallback={<CardSkeleton />}>
  <RevenueChart />   {/* 遅いfetchが他をブロックしない */}
</Suspense>
```

- データフェッチするコンポーネントの**上**に配置（同階層や下では機能しない）
- ネスト可能: ページ全体の `loading.tsx` + セクション個別の `Suspense`

### 3. Skeleton UI

```tsx
// 基本Skeleton。リッチ版(シマー)・各種パターンは → reference.md
function Skeleton({ className }: { className?: string }) {
  return <div className={cn("animate-pulse rounded-md bg-muted", className)} />;
}
```

- 実コンテンツの形状に近い形を再現（テキスト行数、画像位置）
- **400ms未満で完了する処理にはスケルトン不要**（チラつきの原因）

### 4. Optimistic Updates のフィードバック設計

サーバー応答前にUIを即時更新し、失敗時だけロールバック。コンポーネント設計は react-component-patterns 参照。

- 楽観的更新中: `opacity-60` + `pointer-events-none` で視覚的に区別
- 失敗時: 自動ロールバック + **トーストでエラー通知**
- 成功確定後: `opacity-60` 解除、控えめなフェードで確定を伝える

---

## Part 2: Toast / Notification [HIGH]

### 5. 通知タイプの使い分け

| タイプ | 用途 | 消え方 | 例 |
|--------|------|--------|-----|
| Toast | 一時的な操作結果 | 自動消去 | 「保存しました」 |
| Snackbar | 操作結果+取り消し | 自動(アクション付き) | 「削除しました [元に戻す]」 |
| Banner | システム全体の状態 | 手動 | 「メンテナンス予定」 |
| Inline alert | 特定セクションの通知 | 永続 | フォーム上部のエラーサマリー |

### 6. Sonner 実装パターン

```tsx
toast.success('保存しました');
toast.error('保存に失敗しました');
toast('削除しました', { action: { label: '元に戻す', onClick: () => restore(id) } });
```

- `<Toaster position="bottom-right" richColors closeButton />` を layout.tsx に配置
- Promise連携: `toast.promise(fn, { loading, success, error })` → 完全設定: reference.md

### 7. 通知設計ルール

- **自動消去**: 成功=3秒、情報=4秒、エラー=手動閉じ or 10秒
- **同時表示**: 最大3件、超過時は古いものから消す
- **優先度**: error > warning > info > success
- **ホバー時**: タイマー一時停止（Sonnerはデフォルトで対応）
- **アクセシビリティ**: 情報系=`role="status"` / エラー系=`role="alert"`

---

## Part 3: Form Validation UX [CRITICAL]

### 8. バリデーションタイミング戦略

| 戦略 | タイミング | 用途 |
|------|-----------|------|
| onBlur | フォーカスアウト時 | メール、パスワード、フォーマットチェック |
| onChange (debounced) | 入力中300ms後 | ユーザー名重複チェック、リアルタイム検索 |
| onSubmit | 送信時 | 最終的な整合性チェック（フォーム全体） |

**推奨**: onBlur で初回バリデーション → エラー表示後は onChange で即時クリア。フィールドタイプ別マトリクスは reference.md 参照。

### 9. エラー表示の配置と構造

- エラーメッセージはフィールド直下に配置
- `aria-invalid="true"` + `aria-describedby` でスクリーンリーダー対応
- 色（赤）+ アイコン + テキストの**3重伝達**（色だけに頼らない）
- フォーム上部のエラーサマリーは送信時エラーでのみ表示

### 10. useFormStatus でのペンディング状態

```tsx
// <form>の子コンポーネント内で使用。pending中は disabled + spinner + テキスト変更
const { pending } = useFormStatus();
```

- `useFormStatus` はフォーム自体ではなく**子コンポーネント**内で使う → 完全実装: reference.md

---

## Part 4: Empty States [MEDIUM]

### 11. 3種類の空状態

| 種類 | 状況 | CTA |
|------|------|-----|
| First-use | 初回利用/データ未作成 | 作成ボタン |
| No-results | 検索/フィルタで0件 | フィルター解除/条件変更 |
| Error | データ取得失敗 | リトライボタン |

- CTAは**1つだけ**。first-use と error は視覚的に明確に区別する
- コンポーネント実装例は reference.md 参照

---

## Part 5: Error States [CRITICAL]

### 12. error.tsx パターン

```tsx
// 'use client' 必須。error + reset を受け取り、リトライUIを表示
// → 完全実装: reference.md「error.tsx 実装パターン」
```

### 13. エラー設計ルール

- エラーは最寄りの親バウンダリにバブルアップ → 適切な階層に `error.tsx` を配置
- `layout.tsx`/`template.tsx` のエラーは同階層の `error.tsx` ではキャッチ不可 → 親階層に配置
- ルートレイアウトのエラーは `global-error.tsx` でキャッチ
- `reset()` でルートセグメントの再レンダリング（一時的なエラーに有効）
- エラーメッセージ構造: **「何が起きたか + どうすればいいか」**
- 部分的な失敗: Suspense バウンダリ内でのみエラー表示、他セクションは正常維持

エラー階層設計図・getErrorMessage 実装は reference.md 参照。

---

## Part 6: Success Feedback [HIGH]

### 14. チェックマークアニメーション

```tsx
// Framer Motion pathLength で SVG を「描画」表示
<motion.path d="M5 13l4 4L19 7" initial={{ pathLength: 0 }} animate={{ pathLength: 1 }} />
```

### 15. 成功フィードバックの使い分け

| アクション | フィードバック | リダイレクト |
|-----------|-------------|-------------|
| 軽量フォーム送信 | インライン成功メッセージ | なし |
| 重要フォーム送信 | 成功ページ + 次のアクション案内 | 1-2秒後 |
| CRUD操作 | Toast通知 | なし |
| 購入完了/タスク完了 | 成功ページ + お祝い演出 | なし |
| 削除/破壊的操作 | 「元に戻す」付きToast | なし |

- リダイレクトする場合は最低1秒の成功表示を挟む
- 連続操作（いいね等）は楽観的UI更新 + 控えめなアニメーション

---

## Part 7: Transition Patterns [MEDIUM]

### 16. リストアニメーション（追加/削除/並び替え）

```tsx
// AnimatePresence + layout prop + 一意key。mode="popLayout" で即座にレイアウト補正
// → 完全実装: reference.md「リストアニメーション」
```

- `layout` prop で並び替え時の位置変更を自動アニメーション
- 各アイテムに一意の `key`（index不可）

### 17. Collapse / Expand / Modal

`AnimatePresence` + `height: 'auto'` でアコーディオン、`scale + opacity` でモーダル → reference.md 参照。

---

## Part 8: Hover / Focus / Active / Disabled States [MEDIUM]

### 18. Tailwind ステートバリアント体系

```tsx
// hover:bg-primary/90 + focus-visible:ring-2 + active:scale-[0.98] + disabled:opacity-50
// → 完全クラス例: reference.md「Tailwind ボタンステートバリアント完全例」
```

- **`focus-visible` を使う（`focus` ではなく）**: キーボード操作時のみリング表示
- `disabled:pointer-events-none` + `disabled:opacity-50` で非活性化

### 19. Loading Button パターン

```tsx
// relative配置のabsolute spinnerでボタン幅を維持。loading中はテキストをopacity-0
// → 完全実装: reference.md「Loading Button」
```

- `motion-reduce:hidden` で `prefers-reduced-motion` 時はテキスト「処理中...」に切り替え

---

## Part 9: Streaming UI [HIGH]

### 20. AI応答ストリーミング（Vercel AI SDK）

```tsx
const { messages, input, handleInputChange, handleSubmit, isLoading, stop } = useChat();
```

- ストリーミング中は「停止」ボタン (`stop()`) を表示
- ユーザーが上スクロールしたら自動スクロールを停止
- タイピングインジケーター（3ドットアニメーション）をローディング中に表示

完全なチャットUI実装は reference.md 参照。

---

## Reference

[reference.md](reference.md) に以下を収録:

- アニメーション duration / easing ガイド（Framer Motion spring推奨値）
- Toast / 通知タイミング数値表・Sonner設定チートシート
- バリデーションタイミング マトリクス（フィールドタイプ別）
- Skeleton パターン集（テキスト/カード/テーブル/プロフィール/シマーグラデーション）
- プログレスバー（確定的/不確定的）
- ボタン状態マトリクス（variant x state）・Loading Button完全実装
- Error boundary 階層設計図・error.tsx実装・getErrorMessage
- Empty State コンポーネント実装例
- リストアニメーション・Collapse / Modal アニメーション完全コード
- useFormStatus SubmitButton 完全実装
- Tailwind ボタンステートバリアント完全例
- ページ遷移パターン（View Transitions API / Framer Motion template.tsx）
- AI チャットUI 完全実装（useChat + 自動スクロール）
- prefers-reduced-motion 対応表
- 実装チェックリスト・アンチパターン集
- 参考ライブラリ一覧

---

## Checklist

- [ ] 全非同期操作にローディング状態（skeleton / spinner）があるか
- [ ] Toast通知にauto-dismiss + 手動closeがあるか
- [ ] フォームバリデーションのタイミングが適切か（onBlur / onChange / onSubmit）
- [ ] Empty stateに次のアクション導線があるか
- [ ] error.tsx が各ルートセグメントに配置されているか
- [ ] `prefers-reduced-motion` でアニメーション無効化対応しているか
- [ ] ボタンのdisabled状態とloading状態が区別されているか

## Cross-references [MEDIUM]

- `ux-psychology` — Doherty 閾値（400ms）、Hick's Law、認知負荷理論など「なぜそのフィードバックが必要か」の心理学的根拠
- `react-component-patterns` — useOptimistic のコンポーネント設計、CVA バリアント、Compound Components、Error Boundary 設計
- `mobile-first-responsive` — LIFF/PWA でのタッチインタラクション、Bottom Sheet、キーボード検出、safe-area 対応
