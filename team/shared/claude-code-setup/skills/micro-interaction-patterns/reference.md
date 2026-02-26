# Micro-Interaction Patterns — Reference

SKILL.md の補足資料。実装チェックリスト、タイミング数値表、アニメーションガイド、アンチパターン集。

---

## アニメーション Duration ガイド

> アニメーション Duration/Easing トークン定義は **design-token-system** 参照

### Framer Motion spring 推奨値

| ユースケース | stiffness | damping | 特徴 |
|-------------|-----------|---------|------|
| スナッピー（ボタン、トグル） | 400 | 25 | 素早い、わずかなバウンス |
| 通常（リスト、カード） | 300 | 25 | バランス良い |
| ゆったり（モーダル、ページ） | 200 | 20 | ゆるやかなバウンス |
| バウンシー（お祝い、注目） | 300 | 10 | 大きなバウンス |

---

## Toast / 通知タイミング数値表

| 通知タイプ | 自動消去 | duration | position (Desktop) | position (Mobile) |
|-----------|---------|----------|--------------------|--------------------|
| Success | あり | 3000ms | bottom-right | top-center |
| Info | あり | 4000ms | bottom-right | top-center |
| Warning | あり | 5000ms | bottom-right | top-center |
| Error | なし(手動) | Infinity | bottom-right | top-center |
| Action付き | なし(手動) | Infinity | bottom-right | bottom-center |

### Sonner 設定チートシート

```tsx
// layout.tsx
<Toaster
  position="bottom-right"
  richColors              // success/error/warning に色を自動付与
  closeButton             // 全トーストに閉じるボタン
  duration={4000}         // デフォルト自動消去時間
  visibleToasts={3}       // 同時表示最大数
  toastOptions={{
    classNames: {
      toast: 'font-sans',
      title: 'text-sm font-medium',
      description: 'text-sm text-muted-foreground',
    },
  }}
/>
```

### toast.promise パターン集

```tsx
// CRUD操作
toast.promise(createItem(data), {
  loading: '作成中...',
  success: (result) => `「${result.name}」を作成しました`,
  error: '作成に失敗しました。もう一度お試しください',
});

// ファイルアップロード
toast.promise(uploadFile(file), {
  loading: `${file.name} をアップロード中...`,
  success: 'アップロードが完了しました',
  error: 'アップロードに失敗しました',
});

// バルク操作
toast.promise(deleteItems(ids), {
  loading: `${ids.length}件を削除中...`,
  success: `${ids.length}件を削除しました`,
  error: '一部の削除に失敗しました',
});
```

---

## フォームバリデーション戦略マトリクス

### フィールドタイプ別推奨タイミング

| フィールド | 初回バリデーション | エラー後 | 理由 |
|-----------|------------------|---------|------|
| メール | onBlur | onChange | 入力中にエラー出すと邪魔 |
| パスワード | onChange (debounced) | onChange | 強度メーターはリアルタイムが有用 |
| ユーザー名 | onBlur + API | onChange (debounced) | API負荷を考慮 |
| 電話番号 | onBlur | onChange | フォーマットチェック |
| 必須テキスト | onBlur | onChange | 空欄チェック |
| 数値（金額等） | onBlur | onChange | フォーマット変換後にチェック |
| 日付 | onBlur / picker選択時 | onChange | ピッカー使用推奨 |
| ファイル | onChange（即時） | onChange | サイズ・形式を即チェック |

### エラーメッセージ構造テンプレート

```
[何が問題か] + [期待される形式/条件]
```

| 悪い例 | 良い例 |
|--------|--------|
| 無効な入力です | メールアドレスの形式が正しくありません（例: user@example.com） |
| エラー | パスワードは8文字以上で、英数字と記号を含めてください |
| 入力が必要です | 名前を入力してください |
| 範囲外です | 金額は100円以上100,000円以下で入力してください |

### アクセシブルフォームフィールド完全パターン

```tsx
function FormField({
  label, name, error, description, required, ...inputProps
}: FormFieldProps) {
  const errorId = `${name}-error`;
  const descId = `${name}-desc`;
  const describedBy = [
    description ? descId : null,
    error ? errorId : null,
  ].filter(Boolean).join(' ') || undefined;

  return (
    <div className="space-y-1.5">
      <label htmlFor={name} className="text-sm font-medium">
        {label}
        {required && <span className="text-destructive ml-0.5">*</span>}
      </label>
      {description && (
        <p id={descId} className="text-xs text-muted-foreground">
          {description}
        </p>
      )}
      <input
        id={name}
        name={name}
        aria-invalid={!!error}
        aria-describedby={describedBy}
        aria-required={required}
        className={cn(
          "input-base",
          error && "border-destructive focus-visible:ring-destructive"
        )}
        {...inputProps}
      />
      <AnimatePresence>
        {error && (
          <motion.p
            id={errorId}
            role="alert"
            className="text-sm text-destructive flex items-center gap-1"
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
          >
            <AlertCircle className="h-3.5 w-3.5 shrink-0" />
            {error}
          </motion.p>
        )}
      </AnimatePresence>
    </div>
  );
}
```

---

## 状態遷移マトリクス

### データ表示コンポーネントの4状態

すべてのデータ表示UIはこの4状態を設計する。

```
┌──────────┐   成功    ┌──────────┐
│ Loading  │────────→│ Success  │
└──────────┘          └──────────┘
     │                      │
     │ 失敗           リフレッシュ
     ▼                      │
┌──────────┐          ┌──────────┐
│  Error   │←─────────│ Refresh  │
└──────────┘   失敗    └──────────┘
     │
     │ リトライ
     ▼
┌──────────┐   0件    ┌──────────┐
│ Loading  │────────→│  Empty   │
└──────────┘          └──────────┘
```

### 遷移時のアニメーション指針

| 遷移 | アニメーション | Duration |
|------|-------------|----------|
| Loading → Success | スケルトン → コンテンツのクロスフェード | 150-200ms |
| Loading → Error | スケルトン即削除 → エラー表示(フェードなし) | 0ms |
| Success → Refresh | 現在データ表示のまま + オーバーレイスピナー | - |
| Error → Loading (retry) | エラー → スケルトンにフェード | 150ms |
| Loading → Empty | スケルトン → 空状態のフェードイン | 200ms |

---

## Skeleton 設計パターン集

### テキストコンテンツ

```tsx
function TextSkeleton() {
  return (
    <div className="space-y-2">
      <Skeleton className="h-6 w-3/4" />    {/* 見出し */}
      <Skeleton className="h-4 w-full" />    {/* 本文1行目 */}
      <Skeleton className="h-4 w-5/6" />     {/* 本文2行目 */}
      <Skeleton className="h-4 w-2/3" />     {/* 本文3行目(短い) */}
    </div>
  );
}
```

### カードグリッド

```tsx
function CardGridSkeleton({ count = 6 }: { count?: number }) {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      {Array.from({ length: count }).map((_, i) => (
        <div key={i} className="rounded-xl border p-4 space-y-3">
          <Skeleton className="h-40 w-full rounded-lg" />  {/* 画像 */}
          <Skeleton className="h-5 w-3/4" />               {/* タイトル */}
          <Skeleton className="h-4 w-1/2" />               {/* サブテキスト */}
        </div>
      ))}
    </div>
  );
}
```

### テーブル

```tsx
function TableSkeleton({ rows = 5, cols = 4 }: TableSkeletonProps) {
  return (
    <div className="rounded-lg border">
      <div className="border-b p-4 flex gap-4">
        {Array.from({ length: cols }).map((_, i) => (
          <Skeleton key={i} className="h-4 flex-1" />
        ))}
      </div>
      {Array.from({ length: rows }).map((_, row) => (
        <div key={row} className="border-b last:border-0 p-4 flex gap-4">
          {Array.from({ length: cols }).map((_, col) => (
            <Skeleton key={col} className="h-4 flex-1" />
          ))}
        </div>
      ))}
    </div>
  );
}
```

### プロフィール / アバター

```tsx
function ProfileSkeleton() {
  return (
    <div className="flex items-center gap-3">
      <Skeleton className="h-10 w-10 rounded-full" />  {/* アバター */}
      <div className="space-y-1.5">
        <Skeleton className="h-4 w-24" />               {/* 名前 */}
        <Skeleton className="h-3 w-32" />               {/* メールアドレス */}
      </div>
    </div>
  );
}
```

### シマーグラデーション（リッチなスケルトン）

`animate-pulse` より高品質な光沢アニメーション。

```tsx
function ShimmerSkeleton({ className }: { className?: string }) {
  return (
    <div
      className={cn(
        "relative overflow-hidden rounded-md bg-muted",
        className
      )}
    >
      <div className="absolute inset-0 -translate-x-full animate-[shimmer_2s_infinite] bg-gradient-to-r from-transparent via-white/20 to-transparent" />
    </div>
  );
}
```

```css
/* globals.css or @theme */
@keyframes shimmer {
  100% { transform: translateX(100%); }
}
```

- `animate-pulse` で十分な場合はシマー不要（トークン効率優先）
- `prefers-reduced-motion` 時は静的グレー背景に（`motion-reduce:` で shimmer を無効化）

---

## プログレスバー / インジケーター

### 確定的プログレスバー

処理の進捗が数値で分かる場合（ファイルアップロード、バルク処理）。

```tsx
function ProgressBar({ value, max = 100 }: { value: number; max?: number }) {
  const percentage = Math.round((value / max) * 100);
  return (
    <div className="w-full bg-muted rounded-full h-2" role="progressbar"
      aria-valuenow={value} aria-valuemin={0} aria-valuemax={max}>
      <div
        className="bg-primary h-2 rounded-full transition-all duration-300 ease-out"
        style={{ width: `${percentage}%` }}
      />
    </div>
  );
}
```

### 不確定プログレスバー

処理の進捗が不明な場合（外部API呼び出し）。

```tsx
function IndeterminateProgress() {
  return (
    <div className="w-full bg-muted rounded-full h-1 overflow-hidden" role="progressbar">
      <div className="h-full bg-primary rounded-full animate-[indeterminate_1.5s_ease-in-out_infinite] w-1/3" />
    </div>
  );
}
```

```css
@keyframes indeterminate {
  0% { transform: translateX(-100%); }
  100% { transform: translateX(400%); }
}
```

- 確定的: ファイルアップロード、バルク操作、ステップウィザード
- 不確定: API呼び出し、バックグラウンド処理
- `role="progressbar"` + `aria-valuenow` でアクセシビリティ対応

---

## ボタン状態マトリクス

### Tailwind クラス体系

| 状態 | Tailwind クラス | 視覚 |
|------|---------------|------|
| Default | `bg-primary text-primary-foreground` | 通常表示 |
| Hover | `hover:bg-primary/90` | 少し暗く |
| Focus | `focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none` | フォーカスリング |
| Active | `active:scale-[0.98]` | わずかに縮小 |
| Disabled | `disabled:pointer-events-none disabled:opacity-50` | 半透明 + クリック無効 |
| Loading | disabled + spinner(absolute) + テキスト不可視 | スピナー回転 |

### バリアント別スタイル

```tsx
const buttonVariants = {
  primary: "bg-primary text-primary-foreground hover:bg-primary/90",
  secondary: "bg-secondary text-secondary-foreground hover:bg-secondary/80",
  destructive: "bg-destructive text-destructive-foreground hover:bg-destructive/90",
  outline: "border border-input bg-background hover:bg-accent hover:text-accent-foreground",
  ghost: "hover:bg-accent hover:text-accent-foreground",
  link: "text-primary underline-offset-4 hover:underline",
};

// 共通のインタラクション状態
const interactionClasses = `
  focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2
  active:scale-[0.98]
  disabled:pointer-events-none disabled:opacity-50
  transition-colors duration-150
`;
```

### Loading Button

> LoadingButton の完全実装例は **react-component-patterns** 参照（CVA バリアント設計テンプレート + Button）

**実装ポイント:**

- `disabled={loading || props.disabled}` で二重送信防止
- `relative` + `absolute` スピナーでボタン幅を維持
- `motion-reduce:` でスピナー → テキスト「処理中...」に切替
- `AnimatePresence mode="wait"` でラベル ↔ スピナーのクロスフェード

---

## Error Boundary 階層設計

### ファイルシステム配置

```
app/
├── global-error.tsx     ← ルートlayout.tsxのエラー
├── error.tsx            ← app直下ページのエラー
├── layout.tsx
├── dashboard/
│   ├── error.tsx        ← ダッシュボード全体のエラー
│   ├── loading.tsx      ← ダッシュボードのローディング
│   ├── page.tsx
│   └── settings/
│       ├── error.tsx    ← 設定ページ固有のエラー
│       └── page.tsx
```

> error.tsx / global-error.tsx の実装パターンとエラー種別ハンドリングは **react-component-patterns** 参照

### error.tsx 実装パターン

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

---

## ストリーミング UI パターン集

### Suspense + streaming RSC

```tsx
// app/feed/page.tsx
import { Suspense } from 'react';

export default function FeedPage() {
  return (
    <div>
      {/* 即座に表示 */}
      <h1>フィード</h1>

      {/* 段階的にストリーミング */}
      <Suspense fallback={<FeaturedSkeleton />}>
        <FeaturedPosts />  {/* 優先度高: 先にfetch完了 */}
      </Suspense>

      <Suspense fallback={<TimelineSkeleton />}>
        <Timeline />  {/* データ量が多い: 後からストリーミング */}
      </Suspense>

      <Suspense fallback={<RecommendSkeleton />}>
        <Recommendations />  {/* 外部API依存: 最後に到着 */}
      </Suspense>
    </div>
  );
}
```

### AI チャットストリーミング完全パターン

```tsx
'use client';
import { useChat } from '@ai-sdk/react';
import { useEffect, useRef, useState } from 'react';

function ChatInterface() {
  const { messages, input, handleInputChange, handleSubmit, isLoading, stop } = useChat();
  const scrollRef = useRef<HTMLDivElement>(null);
  const [autoScroll, setAutoScroll] = useState(true);

  // 自動スクロール（ユーザーが上スクロールしたら停止）
  useEffect(() => {
    if (autoScroll && scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [messages, autoScroll]);

  function handleScroll(e: React.UIEvent<HTMLDivElement>) {
    const { scrollTop, scrollHeight, clientHeight } = e.currentTarget;
    setAutoScroll(scrollHeight - scrollTop - clientHeight < 100);
  }

  return (
    <div className="flex flex-col h-full">
      <div ref={scrollRef} onScroll={handleScroll} className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.map((m) => (
          <div key={m.id} className={cn(
            "max-w-[80%] rounded-lg p-3",
            m.role === 'user'
              ? 'ml-auto bg-primary text-primary-foreground'
              : 'bg-muted'
          )}>
            {m.content}
          </div>
        ))}
        {isLoading && (
          <div className="flex items-center gap-2 text-muted-foreground">
            <span className="flex gap-1">
              <span className="h-2 w-2 rounded-full bg-current animate-bounce [animation-delay:-0.3s]" />
              <span className="h-2 w-2 rounded-full bg-current animate-bounce [animation-delay:-0.15s]" />
              <span className="h-2 w-2 rounded-full bg-current animate-bounce" />
            </span>
          </div>
        )}
      </div>

      <form onSubmit={handleSubmit} className="border-t p-4 flex gap-2">
        <input
          value={input}
          onChange={handleInputChange}
          placeholder="メッセージを入力..."
          className="flex-1 input-base"
        />
        {isLoading ? (
          <button type="button" onClick={stop} className="btn-secondary">
            停止
          </button>
        ) : (
          <button type="submit" className="btn-primary">
            送信
          </button>
        )}
      </form>
    </div>
  );
}
```

---

## リストアニメーション（追加/削除/並び替え）

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

---

## useFormStatus SubmitButton パターン

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

## Tailwind ボタンステートバリアント完全例

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

---

## Collapse / Modal アニメーション

### アコーディオン（Collapse / Expand）

```tsx
'use client';
import { AnimatePresence, motion } from 'framer-motion';
import { useState } from 'react';

function Accordion({ title, children }: { title: string; children: React.ReactNode }) {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <div className="border rounded-lg">
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="w-full flex items-center justify-between p-4 text-left font-medium"
        aria-expanded={isOpen}
        aria-controls={`panel-${title}`}
      >
        {title}
        <motion.span animate={{ rotate: isOpen ? 180 : 0 }} transition={{ duration: 0.2 }}>
          <ChevronDown className="h-4 w-4" />
        </motion.span>
      </button>
      <AnimatePresence initial={false}>
        {isOpen && (
          <motion.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: 'auto', opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            transition={{ duration: 0.2, ease: 'easeInOut' }}
            className="overflow-hidden"
          >
            <div id={`panel-${title}`} role="region" className="p-4 pt-0">{children}</div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
```

### モーダル（enter / exit）

```tsx
function Modal({ isOpen, onClose, title, children }: ModalProps) {
  const titleId = 'modal-title';

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          {/* Backdrop */}
          <motion.div
            className="fixed inset-0 bg-black/50 z-40"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
          />
          {/* Content */}
          <motion.div
            role="dialog"
            aria-modal="true"
            aria-labelledby={titleId}
            className="fixed inset-0 z-50 flex items-center justify-center p-4"
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.95 }}
            transition={{ type: 'spring', stiffness: 300, damping: 25 }}
          >
            <div className="bg-background rounded-xl shadow-xl max-w-md w-full p-6">
              {title && <h2 id={titleId} className="text-lg font-semibold mb-4">{title}</h2>}
              {children}
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
}
```

---

## Empty State コンポーネント

```tsx
interface EmptyStateProps {
  type: 'first-use' | 'no-results' | 'error';
  icon: React.ReactNode;
  title: string;
  description: string;
  action: { label: string; onClick: () => void };
}

function EmptyState({ type, icon, title, description, action }: EmptyStateProps) {
  return (
    <div className="flex flex-col items-center justify-center py-16 text-center">
      <div className={cn(
        "flex h-14 w-14 items-center justify-center rounded-full mb-4",
        type === 'error' ? 'bg-destructive/10 text-destructive' : 'bg-muted text-muted-foreground'
      )}>
        {icon}
      </div>
      <h3 className="text-lg font-semibold">{title}</h3>
      <p className="mt-1 text-sm text-muted-foreground max-w-sm">{description}</p>
      <button
        onClick={action.onClick}
        className={cn(
          "mt-4",
          type === 'error' ? 'btn-destructive' : 'btn-primary'
        )}
      >
        {action.label}
      </button>
    </div>
  );
}

// 使用例
<EmptyState
  type="first-use"
  icon={<Plus className="h-6 w-6" />}
  title="プロジェクトがありません"
  description="最初のプロジェクトを作成して始めましょう"
  action={{ label: '新規作成', onClick: () => router.push('/projects/new') }}
/>
```

---

## getErrorMessage ヘルパー

```tsx
function getErrorMessage(error: Error & { digest?: string }): string {
  // digest がある場合はサーバー側エラー（本番ではユーザーに詳細を見せない）
  if (error.digest) {
    return 'サーバーで問題が発生しました。しばらくしてからもう一度お試しください。';
  }

  // 既知のエラーメッセージをユーザーフレンドリーに変換
  const errorMap: Record<string, string> = {
    'Failed to fetch': 'ネットワーク接続を確認してください。',
    'Not Found': 'お探しのページが見つかりませんでした。',
    'Unauthorized': 'ログインが必要です。再度ログインしてください。',
    'Forbidden': 'このページにアクセスする権限がありません。',
  };

  return errorMap[error.message] ?? error.message ?? '予期しないエラーが発生しました。';
}
```

---

## ページ遷移パターン

### View Transitions API（ネイティブ）

```tsx
// next.config.ts
const nextConfig = {
  experimental: {
    viewTransition: true,  // Next.js の View Transitions サポート
  },
};
```

### Framer Motion テンプレートパターン

```tsx
// app/template.tsx
// template.tsx は navigation ごとに新インスタンスを作成（layout.tsx と異なる）
'use client';
import { motion } from 'framer-motion';

export default function Template({ children }: { children: React.ReactNode }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3, ease: 'easeOut' }}
    >
      {children}
    </motion.div>
  );
}
```

---

## 実装チェックリスト

### Loading States

- [ ] 全データフェッチページに `loading.tsx` または `Suspense` fallback があるか
- [ ] スケルトンは実コンテンツの形状を再現しているか
- [ ] 短時間の処理にはスケルトンを出さず、長時間処理には必ず出しているか
  ```tsx
  // useTransition で低優先度更新として扱い、UIの応答性を維持
  const [isPending, startTransition] = useTransition();
  // startTransition(() => fetchData()); → isPending は即座に true になる
  // React が更新を低優先度としてスケジュールするため、UIスレッドをブロックしない
  // チラつき防止には別途 setTimeout や useDeferredValue を組み合わせる
  ```
- [ ] 楽観的更新が適用できる操作（いいね、ステータス変更）に `useOptimistic` を使っているか（→ **react-component-patterns** 参照）

### Toast / Notification

- [ ] `<Toaster />` がルートレイアウトに1つだけ配置されているか
- [ ] 成功トーストが3秒、エラートーストが手動閉じになっているか
- [ ] 破壊的操作に「元に戻す」アクション付きトーストを使っているか
- [ ] 同時表示が3件以内に制限されているか

### Form Validation

- [ ] 初回バリデーションが onBlur、エラー後が onChange になっているか
- [ ] エラーメッセージがフィールド直下に配置されているか
- [ ] `aria-invalid` + `aria-describedby` がエラーフィールドに設定されているか
- [ ] 送信ボタンに `useFormStatus` の pending 状態が反映されているか（→ **react-component-patterns** 参照）
- [ ] エラーは色+アイコン+テキストの3重伝達か

### Empty States

- [ ] first-use / no-results / error の3パターンが区別されているか
- [ ] 各パターンにCTAが1つあるか
- [ ] first-use と error が視覚的に区別されているか

### Error States

- [ ] エラーバウンダリ(`error.tsx`)が適切な階層に配置されているか
- [ ] `reset()` による再試行ボタンがあるか
- [ ] エラーメッセージが「何が起きたか + どうすればいいか」の構造か
- [ ] `global-error.tsx` がルートに配置されているか
- [ ] Suspense + error boundary で部分的な失敗が他のセクションに影響しないか

### Transitions

- [ ] リストの追加/削除に `AnimatePresence` + `layout` prop を使っているか
- [ ] 各アニメーションアイテムに一意の `key` があるか（indexは不可）
- [ ] `prefers-reduced-motion` を尊重しているか（`motion-reduce:` variant）
- [ ] モーダルの enter/exit にアニメーションがあるか

### Button States

- [ ] `focus-visible` を使っているか（`focus` ではなく）
- [ ] disabled 状態に `pointer-events-none` + `opacity-50` を適用しているか
- [ ] loading 中のボタン幅が変わらないか（absolute spinner）
- [ ] `prefers-reduced-motion` 時にスピナーがテキストに切り替わるか

### Streaming UI

- [ ] 独立したデータフェッチが個別の `Suspense` でラップされているか
- [ ] AI チャットにタイピングインジケーター + 停止ボタンがあるか
- [ ] ストリーミング中の自動スクロールがユーザースクロールで停止するか

### Progress Indicators

- [ ] 確定的進捗（ファイルアップロード等）にプログレスバーを使っているか
- [ ] 不確定進捗（API呼び出し等）に不確定プログレスバーまたはスピナーを使っているか
- [ ] `role="progressbar"` + `aria-valuenow` でアクセシビリティ対応しているか

---

## アンチパターン集

| パターン | 問題 | 対策 |
|----------|------|------|
| スケルトンのチラつき | 100ms以下で完了するfetchにスケルトン表示 | 400ms閾値でスケルトン表示を遅延 |
| 二重スピナー | ページと個別コンポーネント両方にスピナー | Suspenseの階層を整理 |
| トースト乱発 | 軽微な操作ごとにトースト表示 | 連続操作はまとめ通知、楽観的UI更新を活用 |
| disabled送信ボタン理由不明 | なぜ押せないか不明 | バリデーションエラーをインラインで即表示 |
| フォーム送信後の空白画面 | リダイレクト中に何も表示されない | 成功フィードバック → 遅延リダイレクト |
| exit アニメなし | 要素が突然消える | `AnimatePresence` + `exit` prop |
| focus ring がうるさい | マウスクリックでもリングが出る | `focus-visible` に変更 |
| スケルトンとコンテンツのミスマッチ | スケルトンの形が実コンテンツと全く違う | 実UIの形状に合わせたスケルトン設計 |
| 空状態の放置 | データ0件で何も表示されない | 3種類の空状態を必ず設計 |
| エラー時の情報不足 | 「エラーが発生しました」だけ | 原因 + 対処法を明示 |
| リスト key に index | アニメーションが壊れる、再レンダリング問題 | 一意のIDを key に使用 |
| `useFormStatus` の配置ミス | form自体のコンポーネントで使おうとする | 子コンポーネントに分離（→ **react-component-patterns** 参照） |
| 楽観的更新の失敗時対応なし | ロールバックされるがユーザーに通知されない | 失敗時にトーストでエラー通知 |

---

## prefers-reduced-motion 対応表

| 要素 | 通常 | reduced-motion |
|------|------|----------------|
| スケルトン | animate-pulse / shimmer | 静的なグレー背景 |
| ページ遷移 | フェード/スライド | 即時切り替え |
| リスト追加/削除 | フェード + スライド | 即時表示/非表示 |
| トースト | スライドイン | 即時表示 |
| ボタン press | scale(0.98) | なし |
| スピナー | animate-spin | テキスト「処理中...」に置換 |
| 成功チェックマーク | SVG pathLength アニメ | 静的チェックマーク表示 |
| モーダル | scale + fade | 即時表示 |

### Framer Motion での対応

```tsx
import { useReducedMotion } from 'framer-motion';

function AnimatedComponent() {
  const shouldReduceMotion = useReducedMotion();

  return (
    <motion.div
      initial={shouldReduceMotion ? false : { opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={shouldReduceMotion ? { duration: 0 } : { duration: 0.3 }}
    >
      Content
    </motion.div>
  );
}
```

---

## 参考ライブラリ

| カテゴリ | ライブラリ | 用途 |
|---------|-----------|------|
| Toast | sonner | 通知（Observer パターン、スタッキング対応） |
| Form | react-hook-form + zod | バリデーション（onBlur/onChange制御） |
| Form | @tanstack/react-form | バリデーション（フレームワーク非依存） |
| Animation | framer-motion (motion) | リスト/ページ遷移/レイアウトアニメーション |
| AI Streaming | @ai-sdk/react | useChat / useCompletion |
| Skeleton | react-loading-skeleton | プリセットスケルトン（自作も簡単） |
| Icons | lucide-react | アイコン（Loader2, AlertCircle, Check等） |
