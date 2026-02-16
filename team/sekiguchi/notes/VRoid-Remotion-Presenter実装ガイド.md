---
date: 2026-02-14
tags: [Remotion, VRM, Three.js, VOICEVOX, 動画生成, 実装ガイド]
status: active
---

# VRoid Remotion Presenter 実装ガイド

VRMの3Dキャラクターが喋りながらプレゼンする動画を、コードだけで生成するプロジェクト。動画編集ソフトを一切使わず、`npm run build` 一発でMP4が出力される。

プライベートリポジトリで開発。ここでは実装の設計思想と具体的な手法をまとめる。

---

## 技術スタック

| ライブラリ | バージョン | 役割 |
|-----------|-----------|------|
| Remotion | 4.0.420 | ビデオ・アズ・コード。Reactコンポーネントを映像化する |
| Three.js | 0.182 | 3Dレンダリングエンジン |
| @react-three/fiber | 9.5 | Three.jsのReactバインディング |
| @pixiv/three-vrm | 3.4 | VRM 1.0 モデルの読み込みと制御 |
| VOICEVOX | - | 音声合成エンジン。ローカルAPIで動く |
| Tailwind CSS | 4.0 | UIスタイリング |

---

## プロジェクト構成

```
vroid-remotion-presenter/
├── src/
│   ├── components/
│   │   ├── VRMCharacter.tsx    # キャラクターの全モーション制御
│   │   ├── Slide.tsx           # グラスモーフィズムのスライドUI
│   │   └── Subtitle.tsx        # 字幕テロップ
│   ├── data/
│   │   └── script.ts           # シーン定義データ
│   ├── Composition.tsx         # 画面レイアウト・ライティング・カメラ
│   └── Root.tsx                # Remotionエントリポイント
├── public/
│   ├── audio/                  # VOICEVOX生成の音声WAV
│   ├── models/sample.vrm       # VRMモデル
│   └── tech_bg.png             # サイバーパンク風の背景画像
└── scripts/
    └── generate_voice.mjs      # 音声自動生成スクリプト
```

---

## 核心の設計判断

### 決定論的アニメーション

Remotionで最も重要な原則。`useFrame` 内で `state.clock.elapsedTime` を使うと、プレビューとレンダリングで結果が変わる。全てのアニメーションを `frame` と `fps` だけで計算する。

```tsx
// NG: 実時間に依存。レンダリング結果が毎回変わる
const time = state.clock.elapsedTime;

// OK: フレーム番号から計算。どの環境でも同じ出力
const time = frame / fps;
```

この `time` を `Math.sin` や `Math.cos` に渡して全ての動きを生成する。ランダムに見えるゆらぎも、実際はsin波の組み合わせで決定論的に作る。

### 三分割法

キャラクターを画面中央に置くと素人感が出る。画面右に15%オフセットして三分割法に沿った配置にする。スライドは左側、キャラクターは右側。視線がスライド→キャラクターと自然に流れる。

```tsx
<div style={{ transform: 'translateX(15%)' }}>
  <ThreeCanvas camera={{ position: [0, 1.4, 5], fov: 28 }}>
    {/* 3Dシーン */}
  </ThreeCanvas>
</div>
```

`fov: 28` の狭い画角がポイント。望遠レンズに近い描写になり、キャラクターの歪みが減って自然に見える。

---

## 3点照明

映像制作の基本。キーライト、フィルライト、バックライトの3つでキャラクターの立体感を出す。

```tsx
{/* 1. アンビエント: 全体の底上げ。暗すぎを防ぐ */}
<ambientLight intensity={0.8} color="#f0f9ff" />

{/* 2. キーライト: 右上からの強い光。影を作って立体感を出す */}
<directionalLight
  position={[5, 10, 5]}
  intensity={2.8}
  castShadow
  shadow-mapSize-width={2048}
  shadow-mapSize-height={2048}
/>

{/* 3. バックライト: 背後からの青い光。輪郭を際立たせて背景から分離 */}
<spotLight
  position={[0, 5, -10]}
  intensity={15}
  color="#00f2ff"
  penumbra={1}
/>

{/* 4. 補助ライト: 左から暖色。影を和らげる */}
<pointLight position={[-5, 5, 5]} intensity={1.2} color="#ffdecc" />
```

バックライトの `#00f2ff`（シアン系）がサイバーパンク感の主要因。これをなくすと途端に地味になる。

---

## キャラクター制御の全貌

`VRMCharacter.tsx` がこのプロジェクトの心臓部。239行にキャラクターの生命感を全部詰めている。

### リップシンク

`@remotion/media-utils` の `visualizeAudio` で音声の波形データを取得し、口の開き具合に変換する。

```tsx
const visualization = visualizeAudio({
  fps,
  frame: frame - accumulatedFrames, // シーン内の相対フレーム
  audioData,
  numberOfSamples: 16,
});
const avgVolume = visualization.reduce((a, b) => a + b, 0) / visualization.length;
const mouthValue = Math.min(1.2, avgVolume * 22.0);
```

感度 `22.0` は試行錯誤の結果。低すぎると口がほとんど動かず、高すぎると常に口が全開になる。

口の形はVRMの4つのブレンドシェイプを組み合わせる。

```tsx
vrm.expressionManager.setValue('aa', mouthValue * 0.9);  // あ
vrm.expressionManager.setValue('ih', mouthValue * 0.3);  // い
vrm.expressionManager.setValue('ee', mouthValue * 0.2);  // え
vrm.expressionManager.setValue('ou', mouthValue * 0.15); // お
```

`aa` を主体にして他を控えめにブレンドすると、日本語の発話に自然に見える。

### 眼球のサッカード

人間の目は静止しているときも微細に動いている。これをシミュレーションするだけでキャラクターの生命感が劇的に上がる。

```tsx
const saccadeTime = time * 2;
const saccadeX = Math.sin(saccadeTime * 1.5) * 0.05
               + Math.sin(frame * 0.5) * 0.01;
const saccadeY = Math.cos(saccadeTime * 2.1) * 0.05
               + Math.cos(frame * 0.7) * 0.01;
```

2種類のsin波を足し合わせている。低周波の大きな動き（`saccadeTime * 1.5`）と高周波の細かい振動（`frame * 0.5`）。振幅は `0.05` と `0.01` で、大きくしすぎると不気味になる。

### まばたき

3.5秒間隔でまばたきする。`frame % blinkInterval` でフレームカウンターを周期に変換し、`Math.sin` で閉→開の曲線を作る。

```tsx
const blinkInterval = 3.5 * fps;    // 3.5秒ごと
const blinkDuration = 0.12 * fps;   // 1回0.12秒
const blinkTime = frame % blinkInterval;
if (blinkTime < blinkDuration) {
  blinkValue = Math.sin((blinkTime / blinkDuration) * Math.PI);
}
```

### シーン連動ジェスチャー

シーンIDに応じてボーンを直接操作する。イージングには手書きの ease-in-out を使う。

```tsx
const t = Math.min(sceneTime / 1.5, 1);
// ease-in-out 二次関数
gestureProgress = t < 0.5
  ? 2 * t * t
  : 1 - Math.pow(-2 * t + 2, 2) / 2;
```

| シーン | ジェスチャー | ボーン操作 |
|--------|------------|-----------|
| intro | 手を振る挨拶 | rightUpperArm.rotation.z + rightLowerArm にsin波 |
| feature | 前方を指差す | rightUpperArm を前方に回転 |
| security | 両腕を広げて警戒 | 左右のUpperArm を対称に開く |
| future | 片手を上げて喜ぶ | rightUpperArm + rightLowerArm を上方に回転 |

ジェスチャーが発動していないとき（`gestureProgress < 0.1`）はアイドルモーションに戻る。腕が体の横で軽く揺れる自然な待機ポーズ。

### 体の呼吸とスウェイ

spineボーンにゆっくりした揺れを加えると、棒立ち感がなくなる。

```tsx
spine.rotation.z = Math.sin(time * 0.7) * 0.04  // 左右の揺れ
                 + Math.cos(time * 0.3) * 0.02;  // 不規則さ
spine.rotation.x = Math.sin(time * 1.8) * 0.015; // 呼吸
```

声を出しているとき（`mouthValue > 0.1`）は肩が微妙に上がる。セカンダリモーション。

### シーン別の表情

VRMのExpressionManagerで表情をブレンドする。

| シーン | happy | relaxed | surprised |
|--------|-------|---------|-----------|
| intro | 0.2 | 0 | 0 |
| feature | 0 | 0.2 | 0 |
| security | 0 | 0 | 0.3 |
| future | 0.4 | 0 | 0 |

値は控えめに。特に `happy` を上げすぎると目が閉じてしまい、ゾンビのような見た目になる。

---

## 手持ちカメラ風のゆらぎ

完全に固定されたカメラは不自然。低周波のsin波で微妙な手ブレを足す。

```tsx
const swayX = Math.sin(time * 0.5) * 0.02
            + Math.cos(time * 0.3) * 0.01;
const swayY = Math.sin(time * 0.4) * 0.015
            + Math.cos(time * 0.6) * 0.01;
```

振幅は `0.02` が上限。これ以上大きいと酔う。`camera.position.lerp(target, 0.04)` でなめらかに追従させる。

---

## スライドUI

グラスモーフィズムで背景を透過させる。

```tsx
style={{
  background: 'rgba(15, 23, 42, 0.4)',
  backdropFilter: 'blur(16px) saturate(180%)',
}}
```

タイトルとポイントにはRemotionの `spring` でアニメーションをつける。ポイントは `index * 8` フレームずつ遅延させて順番に現れる。

```tsx
const pointProgress = spring({
  frame: frame - (10 + index * 8),
  fps,
  config: { damping: 15, mass: 1, stiffness: 100 },
});
```

---

## 音声生成パイプライン

VOICEVOXをローカルで起動し、HTTP APIで音声合成する。

```bash
# VOICEVOXを先に起動しておく
node scripts/generate_voice.mjs
```

スクリプトの構造はシンプルで、`audio_query`（テキスト→パラメータ変換）と `synthesis`（パラメータ→WAV変換）の2ステップ。

```javascript
// 1. テキストから音声パラメータを取得
const queryRes = await fetch(
  `${API_URL}/audio_query?text=${encodeURIComponent(text)}&speaker=${SPEAKER_ID}`,
  { method: 'POST' }
);
const queryJson = await queryRes.json();

// 2. パラメータからWAVを合成
const synthRes = await fetch(
  `${API_URL}/synthesis?speaker=${SPEAKER_ID}`,
  { method: 'POST', body: JSON.stringify(queryJson) }
);
```

Speaker ID 3 はずんだもんのノーマル声。他のキャラクターを使うならIDを変える。

---

## スクリプトのデータ構造

各シーンはこの型で定義する。

```typescript
type SceneData = {
  id: string;                        // シーンの一意ID。音声ファイル名にも使う
  text: string;                      // 字幕テキスト（読み上げ内容）
  title: string;                     // スライドのタイトル
  points: string[];                  // スライドの箇条書き（3つ推奨）
  durationInSeconds: number;         // シーンの長さ（音声の秒数に合わせる）
  cameraPos?: [number, number, number]; // カメラ位置のオーバーライド
};
```

`durationInSeconds` は音声のWAVファイルの長さと一致させる必要がある。ずれるとリップシンクが壊れる。

---

## セットアップ手順

```bash
# 1. 依存インストール
npm install

# 2. VRMモデルを配置
#    VRoid Studio等で作成し public/models/sample.vrm に置く

# 3. VOICEVOXを起動してから音声生成
node scripts/generate_voice.mjs

# 4. 開発プレビュー
npm run dev

# 5. 本番レンダリング
npm run build
npx remotion render MyComp output.mp4
```

---

## 自分のプレゼンを作るには

1. `script.ts` のシーン配列を書き換える
2. `generate_voice.mjs` の `segments` 配列も同じテキストに揃える
3. 音声を再生成する
4. 各シーンの `durationInSeconds` を生成されたWAVの長さに合わせる
5. ジェスチャーを変えたければ `VRMCharacter.tsx` の `switch` 文を編集する
6. 背景画像を差し替えるなら `public/tech_bg.png` を上書きする

---

## 実装で得た教訓

- Remotionでは `state.clock` を絶対に使わない。全て `frame / fps` で計算する
- VRMの表情値は控えめに。`happy: 0.4` でも強すぎるくらい
- リップシンクの感度は `20〜25` の範囲が自然
- 手ブレの振幅は `0.02` 以下に抑える。映像酔いを防ぐ
- sin波を2つ以上重ねると、規則的に見えないゆらぎが作れる
- バックライトの色を変えるだけで映像の雰囲気が激変する
- `fov` は28前後の狭い画角が人物撮影向き

---

_最終更新: 2026-02-14_
