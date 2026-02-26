# Security Best Practices — Reference

> スタック横断のセキュリティパターン集。TypeScript/Node.js・Python・Go + Next.js 特化セクション。
> 各セクションは S-N 形式で参照。コード例は「Before（脆弱）→ After（安全）」で対比。

---

## S-1: Input Validation（入力バリデーション）

### S-1.1 Zod スキーマパターン（TypeScript）

```ts
// ── BEFORE: バリデーションなしで直接使用 ──────────────────────
const handler = async (req: Request) => {
  const { email, age } = await req.json(); // 型保証なし・任意の値が来る
  await db.createUser({ email, age });
};

// ── AFTER: Zod でスキーマ定義 ────────────────────────────────
import { z } from "zod";

const CreateUserSchema = z.object({
  email: z.string().email().max(254).toLowerCase(),
  age:   z.number().int().min(0).max(150),
  name:  z.string().min(1).max(100).trim(),
});

type CreateUserInput = z.infer<typeof CreateUserSchema>; // 型をスキーマから導出

const handler = async (req: Request) => {
  const result = CreateUserSchema.safeParse(await req.json());
  if (!result.success) {
    return Response.json({ errors: result.error.flatten() }, { status: 400 });
  }
  await db.createUser(result.data); // 型安全・検証済み
};
```

### S-1.2 ファイルアップロードバリデーション

```ts
const UploadSchema = z.object({
  file: z
    .instanceof(File)
    .refine((f) => f.size <= 10 * 1024 * 1024, "10MB 以下にしてください")
    .refine(
      (f) => ["image/jpeg", "image/png", "image/webp"].includes(f.type),
      "JPEG/PNG/WebP のみ許可"
    ),
});

// Content-Type ヘッダーだけで判定するな → マジックバイトで確認
import { fileTypeFromBuffer } from "file-type";

async function validateFileContent(buffer: Buffer, declaredType: string) {
  const detected = await fileTypeFromBuffer(buffer);
  if (!detected || detected.mime !== declaredType) {
    throw new Error("ファイル形式が宣言と一致しません");
  }
}
```

### S-1.3 Python (Pydantic v2)

```python
from pydantic import BaseModel, EmailStr, field_validator
import re

class CreateUserInput(BaseModel):
    email: EmailStr
    name: str
    age: int

    @field_validator("name")
    @classmethod
    def sanitize_name(cls, v: str) -> str:
        v = v.strip()
        if len(v) < 1 or len(v) > 100:
            raise ValueError("名前は 1〜100 文字")
        # 制御文字を拒否
        if re.search(r"[\x00-\x1f\x7f]", v):
            raise ValueError("制御文字は使用不可")
        return v

    @field_validator("age")
    @classmethod
    def validate_age(cls, v: int) -> int:
        if v < 0 or v > 150:
            raise ValueError("年齢は 0〜150")
        return v
```

### S-1.4 Go (validator)

```go
import "github.com/go-playground/validator/v10"

type CreateUserInput struct {
    Email string `json:"email" validate:"required,email,max=254"`
    Name  string `json:"name"  validate:"required,min=1,max=100"`
    Age   int    `json:"age"   validate:"gte=0,lte=150"`
}

var validate = validator.New()

func parseAndValidate(r *http.Request, dst any) error {
    if err := json.NewDecoder(http.MaxBytesReader(nil, r.Body, 1<<20)).Decode(dst); err != nil {
        return fmt.Errorf("JSONパース失敗: %w", err)
    }
    return validate.Struct(dst)
}
```

---

## S-2: Authentication Hardening（認証強化）

### S-2.1 パスワードハッシュ — bcrypt

```ts
// ── BEFORE: MD5/SHA256 は絶対にNG ────────────────────────────
import crypto from "crypto";
const hash = crypto.createHash("sha256").update(password).digest("hex"); // 危険！

// ── AFTER: bcrypt (コスト12以上) ────────────────────────────
import bcrypt from "bcryptjs";

const BCRYPT_ROUNDS = 12; // 本番は12以上。14はログインが ~1秒

async function hashPassword(plain: string): Promise<string> {
  // bcrypt は72バイト上限あり。長いパスフレーズはSHA256で前処理
  if (Buffer.byteLength(plain, "utf8") > 72) {
    throw new Error("パスワードは72バイト以内");
  }
  return bcrypt.hash(plain, BCRYPT_ROUNDS);
}

async function verifyPassword(plain: string, hash: string): Promise<boolean> {
  return bcrypt.compare(plain, hash); // タイミング安全な比較
}
```

```python
# Python: passlib + argon2
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["argon2"], deprecated="auto")

def hash_password(plain: str) -> str:
    return pwd_context.hash(plain)

def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)
```

### S-2.2 JWT ベストプラクティス

```ts
import { SignJWT, jwtVerify } from "jose";

const SECRET = new TextEncoder().encode(process.env.JWT_SECRET!); // 最低256bit
const ALG = "HS256";

// ── BEFORE: 弱いJWT ──────────────────────────────────────────
// jwt.sign(payload, "secret")          ← ハードコード禁止
// jwt.sign(payload, secret, {})        ← 有効期限なし危険
// algorithm: "none"                    ← 絶対NG

// ── AFTER: jose で型安全・有効期限付き ────────────────────────
export async function signToken(userId: string): Promise<string> {
  return new SignJWT({ sub: userId })
    .setProtectedHeader({ alg: ALG })
    .setIssuedAt()
    .setExpirationTime("15m")  // アクセストークンは短命に
    .setIssuer("myapp")
    .setAudience("myapp-client")
    .sign(SECRET);
}

export async function verifyToken(token: string) {
  const { payload } = await jwtVerify(token, SECRET, {
    issuer: "myapp",
    audience: "myapp-client",
  });
  return payload;
}
```

### S-2.3 セッション管理

```ts
// セッションIDは crypto.randomBytes で生成
import crypto from "crypto";

function generateSessionId(): string {
  return crypto.randomBytes(32).toString("hex"); // 256bit のランダム
}

// Cookie 設定（production）
const SESSION_COOKIE = {
  name: "session",
  options: {
    httpOnly: true,                                         // JS からアクセス不可
    secure: process.env.NODE_ENV === "production",          // HTTPS のみ（本番）
    sameSite: "lax" as const,                              // CSRF 対策
    maxAge: 60 * 60 * 24 * 7,                             // 7日
    path: "/",
  },
};
```

---

## S-3: SQL Injection Prevention（SQLインジェクション防止）

### S-3.1 Supabase — パラメータ化クエリ

```ts
// ── BEFORE: 文字列結合で SQLi ────────────────────────────────
const { data } = await supabase.rpc(
  `SELECT * FROM users WHERE email = '${email}'` // 絶対NG
);

// ── AFTER: Supabase クライアントのフィルタを使う ──────────────
const { data, error } = await supabase
  .from("users")
  .select("id, email, name")
  .eq("email", email)      // パラメータ化される
  .single();

// 生 SQL が必要な場合は RPC + パラメータ
const { data } = await supabase.rpc("get_user_by_email", { p_email: email });
```

```sql
-- Supabase Edge Function 側の安全な関数定義
CREATE OR REPLACE FUNCTION get_user_by_email(p_email TEXT)
RETURNS SETOF users AS $$
  SELECT * FROM users WHERE email = p_email;  -- パラメータ化
$$ LANGUAGE sql SECURITY DEFINER;
```

### S-3.2 Prisma

```ts
// ── BEFORE: raw クエリに変数を直接埋め込み ───────────────────
await prisma.$queryRaw(`SELECT * FROM "User" WHERE id = ${userId}`); // SQLi

// ── AFTER: Prisma クライアント API を使う ─────────────────────
const user = await prisma.user.findUnique({ where: { id: userId } });

// raw が必要な場合は Prisma.sql タグを使う
import { Prisma } from "@prisma/client";

const users = await prisma.$queryRaw(
  Prisma.sql`SELECT * FROM "User" WHERE email = ${email}` // エスケープ済み
);
```

### S-3.3 Python (SQLAlchemy / psycopg2)

```python
# ── BEFORE: f-string で SQLi ─────────────────────────────────
cursor.execute(f"SELECT * FROM users WHERE email = '{email}'")  # 危険！

# ── AFTER: バインドパラメータ ────────────────────────────────
# psycopg2
cursor.execute("SELECT * FROM users WHERE email = %s", (email,))

# SQLAlchemy Core
from sqlalchemy import text
result = conn.execute(
    text("SELECT * FROM users WHERE email = :email"),
    {"email": email}
)

# SQLAlchemy ORM（最推奨）
user = session.query(User).filter(User.email == email).first()
```

### S-3.4 Go (database/sql)

```go
// ── BEFORE: fmt.Sprintf で SQLi ──────────────────────────────
query := fmt.Sprintf("SELECT * FROM users WHERE email='%s'", email) // NG

// ── AFTER: プレースホルダ ────────────────────────────────────
row := db.QueryRowContext(ctx,
    "SELECT id, name FROM users WHERE email = $1", email)

var id int
var name string
if err := row.Scan(&id, &name); err != nil {
    return nil, fmt.Errorf("DB クエリ失敗: %w", err)
}
```

---

## S-4: XSS Prevention（クロスサイトスクリプティング防止）

### S-4.1 React の組み込み保護を活かす

```tsx
// ── BEFORE: dangerouslySetInnerHTML の乱用 ───────────────────
<div dangerouslySetInnerHTML={{ __html: userContent }} /> // XSS！

// ── AFTER: DOMPurify でサニタイズしてから使う ─────────────────
import DOMPurify from "dompurify";

const PURIFY_CONFIG = {
  ALLOWED_TAGS: ["b", "i", "em", "strong", "a", "p", "br"],
  ALLOWED_ATTR: ["href", "title"],
  ALLOW_DATA_ATTR: false,
};

function SafeHtml({ html }: { html: string }) {
  const clean = DOMPurify.sanitize(html, PURIFY_CONFIG);
  return <div dangerouslySetInnerHTML={{ __html: clean }} />;
}

// URL は javascript: スキームに注意
function SafeLink({ href, children }: { href: string; children: React.ReactNode }) {
  const safe = href.startsWith("http") || href.startsWith("/") ? href : "#";
  return <a href={safe}>{children}</a>;
}
```

### S-4.2 CSP ヘッダー（Next.js middleware）

```ts
// middleware.ts
import { NextResponse, type NextRequest } from "next/server";

const CSP = [
  "default-src 'self'",
  "script-src 'self' 'nonce-{NONCE}'",   // nonce ベース推奨
  "style-src 'self' 'unsafe-inline'",    // Tailwind のため
  "img-src 'self' data: https:",
  "font-src 'self'",
  "connect-src 'self' https://api.example.com",
  "frame-ancestors 'none'",              // クリックジャッキング対策も兼ねる
  "base-uri 'self'",
  "form-action 'self'",
].join("; ");

export function middleware(req: NextRequest) {
  const res = NextResponse.next();
  res.headers.set("Content-Security-Policy", CSP);
  return res;
}
```

### S-4.3 出力エンコーディング（テンプレートエンジン外）

```ts
// HTML エンティティエスケープ（自前実装は避け、ライブラリを使う）
import he from "he";

const safe = he.encode(userInput); // <script> → &lt;script&gt;

// JSON に埋め込む場合（HTML 内 <script> タグ）
const safeJson = JSON.stringify(data).replace(/</g, "\\u003c");
```

---

## S-5: CSRF Protection（クロスサイトリクエストフォージェリ対策）

### S-5.1 SameSite Cookie + カスタムヘッダー

```ts
// SameSite=Lax が基本防御。さらにカスタムヘッダーチェックを追加
// ── AFTER: Server Action / Route Handler でのチェック ──────────
export async function POST(req: Request) {
  // カスタムヘッダーの存在確認（ブラウザの CSRF リクエストには付かない）
  const xRequested = req.headers.get("X-Requested-With");
  if (xRequested !== "XMLHttpRequest") {
    return Response.json({ error: "Forbidden" }, { status: 403 });
  }
  // ... 処理
}

// クライアント側
fetch("/api/action", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "X-Requested-With": "XMLHttpRequest", // 毎回付ける
  },
  body: JSON.stringify(data),
});
```

### S-5.2 CSRF トークン（フォームベース）

```ts
import crypto from "crypto";

// トークン生成（セッションに紐づける）
export function generateCsrfToken(): string {
  return crypto.randomBytes(32).toString("hex");
}

// サーバーサイド検証
export function validateCsrfToken(
  sessionToken: string,
  submittedToken: string
): boolean {
  // タイミング攻撃対策: timingSafeEqual を使う
  return crypto.timingSafeEqual(
    Buffer.from(sessionToken),
    Buffer.from(submittedToken)
  );
}
```

```tsx
// フォームへの埋め込み
export default async function ContactForm() {
  const csrfToken = await getCsrfToken(); // セッションから取得
  return (
    <form action={submitAction}>
      <input type="hidden" name="csrf_token" value={csrfToken} />
      {/* ... */}
    </form>
  );
}
```

### S-5.3 Python (FastAPI / Django)

```python
# FastAPI: カスタムヘッダーチェック middleware
from fastapi import Request, HTTPException
from starlette.middleware.base import BaseHTTPMiddleware

class CSRFMiddleware(BaseHTTPMiddleware):
    SAFE_METHODS = {"GET", "HEAD", "OPTIONS", "TRACE"}

    async def dispatch(self, request: Request, call_next):
        if request.method not in self.SAFE_METHODS:
            origin = request.headers.get("origin", "")
            if origin and not origin.startswith("https://myapp.example.com"):
                raise HTTPException(status_code=403, detail="CSRF check failed")
        return await call_next(request)
```

---

## S-6: Secret Management（シークレット管理）

### S-6.1 環境変数パターン

```bash
# .env.example（リポジトリにコミット — 値は空）
DATABASE_URL=
JWT_SECRET=
OPENAI_API_KEY=
STRIPE_SECRET_KEY=

# .gitignore に必ず追加
echo ".env*" >> .gitignore
echo "!.env.example" >> .gitignore  # example は除外
```

```ts
// lib/env.ts — 起動時に環境変数を検証（Zod）
import { z } from "zod";

const EnvSchema = z.object({
  DATABASE_URL:    z.string().url(),
  JWT_SECRET:      z.string().min(32), // 最低256bit
  NODE_ENV:        z.enum(["development", "test", "production"]),
  // クライアントに露出するものは NEXT_PUBLIC_ プレフィックス必須
  NEXT_PUBLIC_APP_URL: z.string().url(),
});

export const env = EnvSchema.parse(process.env); // 起動時に失敗させる
```

### S-6.2 git-secrets / secret scanning

```bash
# git-secrets のインストールと設定
brew install git-secrets
git secrets --install          # フック設定
git secrets --register-aws     # AWSパターン登録

# pre-commit で truffleHog を実行
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/trufflesecurity/trufflehog
    rev: v3.x.x
    hooks:
      - id: trufflehog
        args: ["--only-verified"]
```

### S-6.3 シークレットをログに出さない

```ts
// ── BEFORE: 危険なログ ────────────────────────────────────────
console.log("DB接続:", process.env.DATABASE_URL); // 認証情報が丸見え
console.error("Error:", req.headers);             // Authorizationが漏れる

// ── AFTER: センシティブフィールドをマスク ─────────────────────
function sanitizeHeaders(headers: Headers): Record<string, string> {
  const result: Record<string, string> = {};
  headers.forEach((value, key) => {
    result[key] = ["authorization", "cookie", "x-api-key"].includes(
      key.toLowerCase()
    )
      ? "[REDACTED]"
      : value;
  });
  return result;
}
```

---

## S-7: CORS Configuration（CORS設定）

### S-7.1 Next.js Route Handler

```ts
// lib/cors.ts
const ALLOWED_ORIGINS = new Set([
  "https://app.example.com",
  "https://admin.example.com",
  ...(process.env.NODE_ENV === "development" ? ["http://localhost:3000"] : []),
]);

export function withCors(
  handler: (req: Request) => Promise<Response>
) {
  return async (req: Request): Promise<Response> => {
    const origin = req.headers.get("Origin") ?? "";

    // プリフライト
    if (req.method === "OPTIONS") {
      const res = new Response(null, { status: 204 });
      setCorsHeaders(res.headers, origin);
      return res;
    }

    const res = await handler(req);
    setCorsHeaders(res.headers, origin);
    return res;
  };
}

function setCorsHeaders(headers: Headers, origin: string) {
  if (ALLOWED_ORIGINS.has(origin)) {
    headers.set("Access-Control-Allow-Origin", origin); // * は使わない
    headers.set("Vary", "Origin");                       // キャッシュ汚染防止
  }
  headers.set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE");
  headers.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
  headers.set("Access-Control-Max-Age", "86400");
  // credentials が必要な場合のみ（* との組み合わせは不可）
  // headers.set("Access-Control-Allow-Credentials", "true");
}
```

### S-7.2 Python (FastAPI)

```python
from fastapi.middleware.cors import CORSMiddleware

# ── BEFORE: 危険な設定 ────────────────────────────────────────
app.add_middleware(CORSMiddleware, allow_origins=["*"])  # NG（特に credentials と組み合わせ）

# ── AFTER: 明示的なオリジンリスト ────────────────────────────
ALLOWED_ORIGINS = [
    "https://app.example.com",
    "https://admin.example.com",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,       # cookies を使う場合のみ True
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["Content-Type", "Authorization"],
    max_age=86400,
)
```

---

## S-8: Security Headers Checklist（セキュリティヘッダー）

### S-8.1 Next.js `next.config.ts`

```ts
import type { NextConfig } from "next";

const securityHeaders = [
  // XSS: type sniffing 防止
  { key: "X-Content-Type-Options", value: "nosniff" },
  // クリックジャッキング防止（CSP frame-ancestors があれば不要だが念のため）
  { key: "X-Frame-Options", value: "DENY" },
  // リファラ情報を制限
  { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
  // 不要な機能を無効化
  { key: "Permissions-Policy", value: "camera=(), microphone=(), geolocation=()" },
  // CSP は middleware.ts で nonce 付きで設定（静的設定は↓）
  {
    key: "Content-Security-Policy",
    value: [
      "default-src 'self'",
      "script-src 'self'",
      "style-src 'self' 'unsafe-inline'",
      "img-src 'self' data: https:",
      "frame-ancestors 'none'",
    ].join("; "),
  },
];

const nextConfig: NextConfig = {
  headers: async () => [
    { source: "/(.*)", headers: securityHeaders },
  ],
};

export default nextConfig;
```

### S-8.2 チェックリスト

| ヘッダー | 推奨値 | 優先度 |
|---------|--------|--------|
| `Content-Security-Policy` | スクリプトは nonce/hash ベース | Critical |
| `X-Content-Type-Options` | `nosniff` | High |
| `X-Frame-Options` | `DENY` or `SAMEORIGIN` | High |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | Medium |
| `Permissions-Policy` | 使わない機能を明示的に無効化 | Medium |
| `Cache-Control` | センシティブページは `no-store` | High |

> NOTE: HSTS は一度設定すると戻せないリスクがあるため、TLS 構成を完全に確認してから導入する（SKILL.md §General Security Advice 参照）。

---

## S-9: Rate Limiting（レート制限）

### S-9.1 Upstash Redis + Next.js

```ts
// lib/rate-limit.ts
import { Ratelimit } from "@upstash/ratelimit";
import { Redis } from "@upstash/redis";

const redis = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL!,
  token: process.env.UPSTASH_REDIS_REST_TOKEN!,
});

// 認証エンドポイント用（厳しめ）
export const authRateLimit = new Ratelimit({
  redis,
  limiter: Ratelimit.slidingWindow(10, "15 m"), // 15分に10回
  analytics: true,
  prefix: "rl:auth",
});

// 一般 API 用
export const apiRateLimit = new Ratelimit({
  redis,
  limiter: Ratelimit.slidingWindow(100, "1 m"), // 1分に100回
  prefix: "rl:api",
});

// 使い方
export async function withRateLimit(
  req: Request,
  limiter: Ratelimit
): Promise<Response | null> {
  const ip =
    req.headers.get("x-forwarded-for")?.split(",")[0].trim() ?? "unknown";
  const { success, limit, remaining, reset } = await limiter.limit(ip);

  if (!success) {
    return Response.json(
      { error: "Too Many Requests" },
      {
        status: 429,
        headers: {
          "X-RateLimit-Limit": String(limit),
          "X-RateLimit-Remaining": String(remaining),
          "X-RateLimit-Reset": String(reset),
          "Retry-After": String(Math.ceil((reset - Date.now()) / 1000)),
        },
      }
    );
  }
  return null; // 通過
}
```

### S-9.2 Python (slowapi + FastAPI)

```python
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from fastapi import FastAPI, Request

limiter = Limiter(key_func=get_remote_address)
app = FastAPI()
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

@app.post("/auth/login")
@limiter.limit("10/15minute")   # 15分に10回
async def login(request: Request, body: LoginInput):
    ...

@app.get("/api/data")
@limiter.limit("100/minute")
async def get_data(request: Request):
    ...
```

### S-9.3 Go (golang.org/x/time/rate)

```go
import "golang.org/x/time/rate"

// IPごとのリミッター管理
type IPRateLimiter struct {
    limiters sync.Map
    r        rate.Limit
    b        int
}

func NewIPRateLimiter(r rate.Limit, b int) *IPRateLimiter {
    return &IPRateLimiter{r: r, b: b}
}

func (i *IPRateLimiter) Get(ip string) *rate.Limiter {
    val, ok := i.limiters.Load(ip)
    if !ok {
        lim := rate.NewLimiter(i.r, i.b)
        i.limiters.Store(ip, lim)
        return lim
    }
    return val.(*rate.Limiter)
}

// Middleware
func RateLimitMiddleware(limiter *IPRateLimiter) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            ip, _, _ := net.SplitHostPort(r.RemoteAddr)
            if !limiter.Get(ip).Allow() {
                http.Error(w, "Too Many Requests", http.StatusTooManyRequests)
                return
            }
            next.ServeHTTP(w, r)
        })
    }
}

// 認証エンドポイント: 1分に5リクエスト
authLimiter := NewIPRateLimiter(rate.Every(time.Minute/5), 5)
```

---

## S-10: Anti-Patterns（アンチパターン集）

### S-10.1 シークレットのハードコード

```ts
// ── BEFORE ───────────────────────────────────────────────────
const client = new OpenAI({ apiKey: "sk-proj-abc123..." }); // コミットしたら終わり

// ── AFTER ────────────────────────────────────────────────────
const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY! });
```

### S-10.2 eval / new Function

```ts
// ── BEFORE ───────────────────────────────────────────────────
const result = eval(userInput);               // RCE
const fn = new Function("return " + expr)();  // RCE

// ── AFTER: 安全な代替手段 ─────────────────────────────────────
// 数式評価: mathjs を使う
import { evaluate } from "mathjs";
const result = evaluate(userInput); // サンドボックス済み
```

### S-10.3 プロトタイプ汚染

```ts
// ── BEFORE ───────────────────────────────────────────────────
function merge(target: any, source: any) {
  for (const key in source) {
    target[key] = source[key]; // __proto__ が汚染される可能性
  }
}

// ── AFTER ────────────────────────────────────────────────────
// lodash.merge はプロトタイプ汚染対策済み
import { merge } from "lodash";

// または Object.assign + Object.create(null) で prototype なしオブジェクト
const safeObj = Object.assign(Object.create(null), userInput);

// キーの検証
function safeMerge(target: Record<string, unknown>, source: unknown) {
  if (typeof source !== "object" || source === null) return target;
  for (const [key, value] of Object.entries(source)) {
    if (key === "__proto__" || key === "constructor" || key === "prototype") {
      continue; // スキップ
    }
    target[key] = value;
  }
  return target;
}
```

### S-10.4 オープンリダイレクト

```ts
// ── BEFORE ───────────────────────────────────────────────────
const next = req.nextUrl.searchParams.get("next");
redirect(next!); // 外部サイトに飛ばせる

// ── AFTER: 同一オリジンのみ許可 ──────────────────────────────
function getSafeRedirectUrl(next: string | null, fallback = "/"): string {
  if (!next) return fallback;
  try {
    const url = new URL(next, "https://dummy.invalid");
    // 相対パスのみ許可（ホストが dummy の場合）
    if (url.hostname !== "dummy.invalid") return fallback;
    return next;
  } catch {
    return fallback;
  }
}
```

### S-10.5 Mass Assignment（一括代入）

```ts
// ── BEFORE ───────────────────────────────────────────────────
await prisma.user.update({
  where: { id },
  data: req.body, // role: "admin" が混入できる！
});

// ── AFTER: 許可フィールドを明示 ──────────────────────────────
const UpdateProfileSchema = z.object({
  name:  z.string().max(100).optional(),
  bio:   z.string().max(500).optional(),
  // role, isAdmin などは含めない
});

const data = UpdateProfileSchema.parse(req.body);
await prisma.user.update({ where: { id }, data });
```

---

## S-11: TypeScript / Node.js 固有

### S-11.1 Path Traversal 防止

```ts
import path from "path";

const UPLOADS_DIR = path.resolve(process.cwd(), "uploads");

function safeFilePath(filename: string): string {
  // path.basename でディレクトリトラバーサル文字を除去
  const basename = path.basename(filename);
  const resolved = path.resolve(UPLOADS_DIR, basename);

  // UPLOADS_DIR の外に出ていないか確認
  if (!resolved.startsWith(UPLOADS_DIR + path.sep)) {
    throw new Error("不正なファイルパス");
  }
  return resolved;
}
```

### S-11.2 依存パッケージの監査

```bash
# npm audit（定期実行 or CI に組み込む）
pnpm audit --audit-level=high

# Snyk（より詳細）
npx snyk test

# CI（GitHub Actions）例
- name: Security audit
  run: pnpm audit --audit-level=moderate
```

---

## S-12: Python 固有

### S-12.1 シリアライゼーション安全性

```python
# ── BEFORE: pickle は RCE ─────────────────────────────────────
import pickle
data = pickle.loads(user_data)  # 絶対NG

# ── AFTER: JSON or orjson を使う ─────────────────────────────
import json
data = json.loads(user_data)  # 安全

# 型安全が必要なら Pydantic
from pydantic import BaseModel
class SafeInput(BaseModel):
    name: str
    value: int

data = SafeInput.model_validate_json(user_data)
```

### S-12.2 コマンドインジェクション防止

```python
import subprocess

# ── BEFORE: shell=True + ユーザー入力 ────────────────────────
subprocess.run(f"convert {filename} output.png", shell=True)  # コマンドインジェクション

# ── AFTER: リスト形式 + shell=False ──────────────────────────
import shlex

def safe_convert(filename: str, output: str) -> None:
    # ファイル名を検証
    if not re.match(r'^[a-zA-Z0-9_\-\.]+$', filename):
        raise ValueError("不正なファイル名")

    subprocess.run(
        ["convert", filename, output],
        shell=False,      # シェル経由しない
        check=True,
        timeout=30,
        capture_output=True,
    )
```

---

## S-13: Go 固有

### S-13.1 constant-time comparison

```go
import "crypto/subtle"

// ── BEFORE: 通常の == はタイミング攻撃に弱い ─────────────────
if token == expectedToken { // NG（タイミングサイドチャネル）

// ── AFTER: subtle.ConstantTimeCompare ─────────────────────────
func SecureCompare(a, b string) bool {
    return subtle.ConstantTimeCompare([]byte(a), []byte(b)) == 1
}
```

### S-13.2 セキュアなランダム生成

```go
import (
    "crypto/rand"
    "encoding/hex"
    "math/big"
)

// ── BEFORE: math/rand はNG ────────────────────────────────────
import "math/rand"
token := fmt.Sprintf("%d", rand.Int63()) // 予測可能

// ── AFTER: crypto/rand ───────────────────────────────────────
func GenerateToken(n int) (string, error) {
    b := make([]byte, n)
    if _, err := rand.Read(b); err != nil {
        return "", fmt.Errorf("乱数生成失敗: %w", err)
    }
    return hex.EncodeToString(b), nil
}

// 32バイト（256bit）のトークン
token, err := GenerateToken(32)
```

---

## S-14: Next.js 固有（App Router）

### S-14.1 Server Actions のセキュリティ

```ts
// app/actions/user.ts
"use server";

import { auth } from "@/lib/auth";        // 認証チェック
import { z } from "zod";
import { revalidatePath } from "next/cache";

const UpdateProfileSchema = z.object({
  name: z.string().min(1).max(100).trim(),
  bio:  z.string().max(500).trim().optional(),
});

export async function updateProfile(formData: FormData) {
  // 1. 認証確認（必須！）
  const session = await auth();
  if (!session?.user?.id) {
    throw new Error("Unauthorized");
  }

  // 2. 入力バリデーション
  const result = UpdateProfileSchema.safeParse({
    name: formData.get("name"),
    bio:  formData.get("bio"),
  });
  if (!result.success) {
    return { error: result.error.flatten() };
  }

  // 3. 操作はセッションユーザーのIDに紐づける（IDOR対策）
  await db.user.update({
    where: { id: session.user.id },  // ユーザーが指定したIDではなく自分のID
    data: result.data,
  });

  revalidatePath("/profile");
  return { success: true };
}
```

### S-14.2 Route Handler の認証ガード

```ts
// app/api/admin/users/route.ts
import { auth } from "@/lib/auth";
import { NextResponse } from "next/server";

export async function GET() {
  const session = await auth();

  // 認証チェック
  if (!session) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  // 認可チェック（ロールベース）
  if (session.user.role !== "admin") {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const users = await db.user.findMany({
    select: { id: true, email: true, name: true }, // 最小限のフィールドのみ
  });
  return NextResponse.json(users);
}
```

### S-14.3 Middleware でのルート保護

```ts
// middleware.ts
import { auth } from "@/lib/auth";
import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

const PUBLIC_PATHS = ["/", "/login", "/signup", "/api/auth"];

export async function middleware(req: NextRequest) {
  const { pathname } = req.nextUrl;

  // パブリックルートはスルー
  if (PUBLIC_PATHS.some((p) => pathname.startsWith(p))) {
    return NextResponse.next();
  }

  const session = await auth();
  if (!session) {
    const loginUrl = new URL("/login", req.url);
    loginUrl.searchParams.set("next", pathname); // リダイレクト先を保持
    return NextResponse.redirect(loginUrl);
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico).*)"],
};
```

### S-14.4 環境変数の分類（Next.js）

```bash
# サーバーサイドのみ（ブラウザに露出しない）
DATABASE_URL=postgresql://...
JWT_SECRET=...
STRIPE_SECRET_KEY=sk_live_...

# クライアントに露出してOK（NEXT_PUBLIC_ プレフィックス必須）
NEXT_PUBLIC_APP_URL=https://app.example.com
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_live_...

# NEXT_PUBLIC_ に機密情報を入れてはいけない
# NEXT_PUBLIC_DATABASE_URL=...  ← これは絶対NG
```

---

## Cross-references

- 脆弱性検出 → `_security-review`
- 脅威モデリング → `_security-threat-model`
- 攻撃テスト → `security-arsenal`
- Supabase Auth + RLS → `_supabase-auth-patterns`
- Next.js App Router パターン → `nextjs-app-router-patterns`
- エラーハンドリング → `error-handling-logging`

---

_ref: OWASP Top 10 (2021), OWASP Cheat Sheet Series, Next.js 15 Security Docs_
_最終更新: 2026-02-24_
