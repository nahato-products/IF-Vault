---
name: micro-interaction-patterns
description: "Use when implementing, debugging, reviewing, or refactoring UI micro-interactions in Next.js App Router with Tailwind CSS and Framer Motion. Covers loading states (skeleton, shimmer, Suspense, loading.tsx, useOptimistic), toast notifications (sonner, snackbar, banner), form validation UX (onBlur/onChange timing, inline errors, useFormStatus), empty states (first-use, no-results, error), error.tsx boundaries (reset, retry, graceful degradation), success feedback (checkmark animation), page and list transitions (AnimatePresence, layout prop, View Transitions API), hover/focus-visible/active/disabled/loading button states, streaming UI (Suspense streaming, AI chat useChat), and progress bars. Does NOT cover component API design (react-component-patterns), cognitive UX (ux-psychology), or accessibility standards (web-design-guidelines)."
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

## Part 1: Loading States [CRITICAL]

### 1. loading.tsx（ルートレベル）

App Router の `loading.tsx` は自動で Suspense バウンダリを生成する。

```tsx
// app/dashboard/loading.tsx
export default function Loading() {
  return <DashboardSkeleton />;
}
```

- 同階層の `page.tsx` を自動ラップし、静的ファイルとして先に送信される
- ナビゲーション時に instant loading state として即座に表示

### 2. Suspense（コンポーネントレベル）

独立したデータフェッチごとに `Suspense` で囲み、段階的にUIを表示する。

```tsx
<div className="grid grid-cols-2 gap-4">
  <Suspense fallback={<CardSkeleton />}>
    <RevenueChart />   {/* 遅いfetchが他をブロックしない */}
  </Suspense>
  <Suspense fallback={<CardSkeleton />}>
    <LatestInvoices />
  </Suspense>
</div>
```

- データフェッチするコンポーネントの**上**に配置（同階層や下では機能しない）
- ネスト可能: ページ全体の `loading.tsx` + セクション個別の `Suspense`

### 3. Skeleton UI

```tsx
function Skeleton({ className }: { className?: string }) {
  return <div className={cn("animate-pulse rounded-md bg-muted", className)} />;
}
```

- 実コンテンツの形状に近い形を再現する（テキスト行数、画像位置）
- `animate-pulse` で十分。リッチにする場合はシマーグラデーション → reference.md「シマーグラデーション」セクション
- **400ms未満で完了する処理にはスケルトン不要**（チラつきの原因）

### 4. Optimistic Updates のフィードバック設計

サーバー応答前にUIを即時更新し、失敗時だけロールバック。コンポーネント設計（useOptimistic の配置・state管理）は react-component-patterns 参照。このスキルでは**視覚フィードバック**に特化。

- 楽観的更新中のアイテムは `opacity-60` + `pointer-events-none` で視覚的に区別する
- Server Action 失敗時は自動で元の state に戻る → **失敗時にトーストでエラー通知**する
- いいね/ブックマーク/ステータス変更など即時フィードバックが重要な操作に有効
- 成功確定後は `opacity-60` を解除し、控えめなフェードで確定を伝える

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
// layout.tsx に <Toaster position="bottom-right" richColors closeButton /> を配置

// 基本
toast.success('保存しました');
toast.error('保存に失敗しました');

// アクション付き（破壊的操作に）
toast('ファイルを削除しました', {
  action: { label: '元に戻す', onClick: () => restoreFile(id) },
});

// Promise連携
toast.promise(saveData(), {
  loading: '保存中...', success: '保存しました', error: '保存に失敗しました',
});
```

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

**推奨**: onBlur で初回バリデーション → エラー表示後は onChange で即時クリア

フィールドタイプ別の詳細マトリクスは reference.md 参照。

### 9. エラー表示の配置と構造

- エラーメッセージはフィールド直下に配置
- `aria-invalid="true"` + `aria-describedby` でスクリーンリーダー対応
- 色（赤）+ アイコン + テキストの**3重伝達**（色だけに頼らない）
- サクセス状態も緑チェックで視覚フィードバック
- フォーム上部のエラーサマリーは送信時エラーでのみ表示

### 10. useFormStatus でのペンディング状態

```tsx
function SubmitButton() {
  const { pending } = useFormStatus(); // <form> の子コンポーネント内でのみ使用可
  return (
    <button type="submit" disabled={pending} className="btn-primary disabled:opacity-50">
      {pending ? <><Spinner className="h-4 w-4 animate-spin" /> 送信中...</> : '送信'}
    </button>
  );
}
```

- `useFormStatus` はフォーム自体ではなく**子コンポーネント**内で使う
- pending 中は disabled + spinner + テキスト変更を同時適用

---

## Part 4: Empty States [MEDIUM]

### 11. 3種類の空状態

| 種類 | 状況 | CTA |
|------|------|-----|
| First-use | 初回利用/データ未作成 | 作成ボタン |
| No-results | 検索/フィルタで0件 | フィルター解除/条件変更 |
| Error | データ取得失敗 | リトライボタン |

- アイコンはシンプルに（56x56px程度で十分）
- CTAは**1つだけ**。複数あると選択に迷う
- first-use と error は視覚的に明確に区別する（first-useは穏やかな色、errorは destructive）

コンポーネント実装例は reference.md 参照。

---

## Part 5: Error States [CRITICAL]

### 12. error.tsx パターン

```tsx
'use client'; // 必須: error.tsx はクライアントコンポーネント

export default function Error({
  error, reset,
}: {
  error: Error & { digest?: string }; reset: () => void;
}) {
  return (
    <div className="flex flex-col items-center justify-center py-16">
      <AlertCircle className="h-12 w-12 text-destructive" />
      <h2 className="mt-4 text-lg font-semibold">問題が発生しました</h2>
      <p className="mt-1 text-sm text-muted-foreground">{getErrorMessage(error)}</p>
      <button onClick={reset} className="mt-4 btn-primary">もう一度試す</button>
    </div>
  );
}
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

Framer Motion の `pathLength` で SVG を「描画」するように表示する。

```tsx
<motion.path
  d="M5 13l4 4L19 7"
  fill="none" stroke="currentColor" strokeWidth={2}
  initial={{ pathLength: 0 }}
  animate={{ pathLength: 1 }}
  transition={{ duration: 0.3, delay: 0.1 }}
/>
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
<AnimatePresence mode="popLayout">
  {items.map((item) => (
    <motion.div
      key={item.id}
      layout  // 位置変更を自動アニメーション
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, x: -100 }}
      transition={{ type: 'spring', stiffness: 300, damping: 25 }}
    >
      <ItemCard item={item} />
    </motion.div>
  ))}
</AnimatePresence>
```

- `layout` prop で並び替え時の位置変更を自動アニメーション
- `AnimatePresence` で exit アニメーション有効化、各アイテムに一意の `key`（index不可）
- `mode="popLayout"` で exit 時に他アイテムが即座にレイアウト補正

### 17. Collapse / Expand / Modal

`AnimatePresence` + `height: 'auto'` でアコーディオン、`scale + opacity` でモーダルの enter/exit を実装する。完全なコード例は reference.md 参照。

---

## Part 8: Hover / Focus / Active / Disabled States [MEDIUM]

### 18. Tailwind ステートバリアント体系

```tsx
<button className="
  bg-primary text-primary-foreground
  hover:bg-primary/90
  focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring
  active:scale-[0.98]
  disabled:pointer-events-none disabled:opacity-50
  transition-colors
">
```

- **`focus-visible` を使う（`focus` ではなく）**: マウスクリック時にリングが出ない、キーボード時のみ
- `disabled:pointer-events-none` でクリック無効化 + `disabled:opacity-50` で視覚的に非活性化

### 19. Loading Button パターン

```tsx
function LoadingButton({ loading, children, ...props }: LoadingButtonProps) {
  return (
    <button disabled={loading} className="btn-primary disabled:opacity-50 relative" {...props}>
      <span className={loading ? 'opacity-0' : ''}>{children}</span>
      {loading && (
        <span className="absolute inset-0 flex items-center justify-center">
          <Loader2 className="h-4 w-4 animate-spin" />
        </span>
      )}
    </button>
  );
}
```

- ボタン幅が変わらないよう spinner は absolute 配置
- `motion-reduce:hidden` で `prefers-reduced-motion` 時はテキスト「処理中...」に切り替え

バリアント別スタイル・完全実装は reference.md 参照。

---

## Part 9: Streaming UI [HIGH]

### 20. AI応答ストリーミング（Vercel AI SDK）

```tsx
const { messages, input, handleInputChange, handleSubmit, isLoading, stop } = useChat();
```

- ストリーミング中は「停止」ボタン (`stop()`) を表示
- ユーザーが上スクロールしたら自動スクロールを停止
- タイピングインジケーター（3ドットアニメーション）をローディング中に表示
- `streamUI` (RSC API) で React コンポーネント自体をストリーミング可能

完全なチャットUI実装は reference.md 参照。

---

## Reference

[reference.md](reference.md) に以下を収録:

- アニメーション duration / easing ガイド（Framer Motion spring推奨値）
- Toast / 通知タイミング数値表・Sonner設定チートシート
- バリデーションタイミング マトリクス（フィールドタイプ別）
- Skeleton パターン集（テキスト/カード/テーブル/プロフィール/シマーグラデーション）
- プログレスバー（確定的/不確定的）
- ボタン状態マトリクス（variant x state）
- Error boundary 階層設計図・getErrorMessage 実装
- Empty State コンポーネント実装例
- Collapse / Modal アニメーション完全コード
- ページ遷移パターン（View Transitions API / Framer Motion template.tsx）
- AI チャットUI 完全実装（useChat + 自動スクロール）
- prefers-reduced-motion 対応表
- 実装チェックリスト・アンチパターン集
- 参考ライブラリ一覧
