# Mermaid テスト

## 簡単なER図
```mermaid
erDiagram
    USER ||--o{ ORDER : places
    ORDER ||--|{ ITEM : contains
```

## フローチャート
```mermaid
flowchart LR
    A[開始] --> B[処理]
    B --> C[終了]
```
