#!/usr/bin/env node

import dotenv from "dotenv";
import { fileURLToPath } from "url";
import { dirname, join } from "path";
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import fetch from "node-fetch";

// .envファイルから環境変数を読み込む（このファイルと同じディレクトリ）
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
dotenv.config({ path: join(__dirname, ".env") });

// Qiita APIエンドポイント
const QIITA_API_BASE = "https://qiita.com/api/v2";

// 環境変数からQiitaアクセストークンを取得
const QIITA_TOKEN = process.env.QIITA_ACCESS_TOKEN;

if (!QIITA_TOKEN) {
  console.error("Error: QIITA_ACCESS_TOKEN environment variable is required");
  process.exit(1);
}

// MCPサーバーの作成
const server = new Server(
  {
    name: "qiita-mcp-server",
    version: "1.1.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// 利用可能なツール一覧
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "qiita_post_article",
        description: "Qiitaに記事を投稿します（下書きまたは公開）",
        inputSchema: {
          type: "object",
          properties: {
            title: {
              type: "string",
              description: "記事のタイトル",
            },
            body: {
              type: "string",
              description: "記事本文（Markdown形式）",
            },
            tags: {
              type: "array",
              items: {
                type: "object",
                properties: {
                  name: { type: "string" },
                  versions: {
                    type: "array",
                    items: { type: "string" },
                  },
                },
                required: ["name"],
              },
              description: "タグ（最大5個）",
            },
            private: {
              type: "boolean",
              description: "限定共有記事にするか（true: 限定共有, false: 公開）",
              default: false,
            },
            tweet: {
              type: "boolean",
              description: "Twitterに投稿するか",
              default: false,
            },
            organization_url_name: {
              type: "string",
              description: "Organizationに紐付ける場合のURL名（例: 'my-organization'）",
            },
          },
          required: ["title", "body", "tags"],
        },
      },
      {
        name: "qiita_update_article",
        description: "既存のQiita記事を更新します",
        inputSchema: {
          type: "object",
          properties: {
            article_id: {
              type: "string",
              description: "記事のID",
            },
            title: {
              type: "string",
              description: "記事のタイトル",
            },
            body: {
              type: "string",
              description: "記事本文（Markdown形式）",
            },
            tags: {
              type: "array",
              items: {
                type: "object",
                properties: {
                  name: { type: "string" },
                  versions: {
                    type: "array",
                    items: { type: "string" },
                  },
                },
                required: ["name"],
              },
              description: "タグ（最大5個）",
            },
            private: {
              type: "boolean",
              description: "限定共有記事にするか",
            },
          },
          required: ["article_id"],
        },
      },
      {
        name: "qiita_get_my_articles",
        description: "自分の投稿記事一覧を取得します",
        inputSchema: {
          type: "object",
          properties: {
            page: {
              type: "number",
              description: "ページ番号（デフォルト: 1）",
              default: 1,
            },
            per_page: {
              type: "number",
              description: "1ページあたりの記事数（最大100）",
              default: 20,
            },
          },
        },
      },
      {
        name: "qiita_get_article",
        description: "特定の記事の詳細を取得します",
        inputSchema: {
          type: "object",
          properties: {
            article_id: {
              type: "string",
              description: "記事のID",
            },
          },
          required: ["article_id"],
        },
      },
      {
        name: "qiita_delete_article",
        description: "記事を削除します",
        inputSchema: {
          type: "object",
          properties: {
            article_id: {
              type: "string",
              description: "記事のID",
            },
          },
          required: ["article_id"],
        },
      },
      {
        name: "qiita_get_article_stats",
        description: "記事の統計情報（閲覧数、いいね数など）を取得します",
        inputSchema: {
          type: "object",
          properties: {
            article_id: {
              type: "string",
              description: "記事のID",
            },
          },
          required: ["article_id"],
        },
      },
      {
        name: "qiita_get_organizations",
        description: "自分が所属しているOrganization一覧を取得します",
        inputSchema: {
          type: "object",
          properties: {},
        },
      },
    ],
  };
});

// ツール実行ハンドラ
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case "qiita_post_article": {
        const postData = {
          title: args.title,
          body: args.body,
          tags: args.tags,
          private: args.private || false,
          tweet: args.tweet || false,
        };

        if (args.organization_url_name) {
          postData.organization_url_name = args.organization_url_name;
        }

        const response = await fetch(`${QIITA_API_BASE}/items`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${QIITA_TOKEN}`,
          },
          body: JSON.stringify(postData),
        });

        if (!response.ok) {
          const error = await response.json();
          throw new Error(`Qiita API Error: ${JSON.stringify(error)}`);
        }

        const data = await response.json();
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                success: true,
                message: "記事を投稿しました！",
                article_id: data.id,
                url: data.url,
                title: data.title,
                private: data.private,
              }, null, 2),
            },
          ],
        };
      }

      case "qiita_update_article": {
        const updateData = {};
        if (args.title) updateData.title = args.title;
        if (args.body) updateData.body = args.body;
        if (args.tags) updateData.tags = args.tags;
        if (args.private !== undefined) updateData.private = args.private;

        const response = await fetch(
          `${QIITA_API_BASE}/items/${args.article_id}`,
          {
            method: "PATCH",
            headers: {
              "Content-Type": "application/json",
              Authorization: `Bearer ${QIITA_TOKEN}`,
            },
            body: JSON.stringify(updateData),
          }
        );

        if (!response.ok) {
          const error = await response.json();
          throw new Error(`Qiita API Error: ${JSON.stringify(error)}`);
        }

        const data = await response.json();
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                success: true,
                message: "記事を更新しました！",
                article_id: data.id,
                url: data.url,
              }, null, 2),
            },
          ],
        };
      }

      case "qiita_get_my_articles": {
        const page = args.page || 1;
        const per_page = args.per_page || 20;

        const response = await fetch(
          `${QIITA_API_BASE}/authenticated_user/items?page=${page}&per_page=${per_page}`,
          {
            headers: {
              Authorization: `Bearer ${QIITA_TOKEN}`,
            },
          }
        );

        if (!response.ok) {
          const error = await response.json();
          throw new Error(`Qiita API Error: ${JSON.stringify(error)}`);
        }

        const data = await response.json();
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                success: true,
                articles: data.map((article) => ({
                  id: article.id,
                  title: article.title,
                  url: article.url,
                  likes_count: article.likes_count,
                  created_at: article.created_at,
                  updated_at: article.updated_at,
                  private: article.private,
                  tags: article.tags.map((tag) => tag.name),
                })),
              }, null, 2),
            },
          ],
        };
      }

      case "qiita_get_article": {
        const response = await fetch(
          `${QIITA_API_BASE}/items/${args.article_id}`,
          {
            headers: {
              Authorization: `Bearer ${QIITA_TOKEN}`,
            },
          }
        );

        if (!response.ok) {
          const error = await response.json();
          throw new Error(`Qiita API Error: ${JSON.stringify(error)}`);
        }

        const data = await response.json();
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                success: true,
                article: {
                  id: data.id,
                  title: data.title,
                  body: data.body,
                  url: data.url,
                  likes_count: data.likes_count,
                  page_views_count: data.page_views_count,
                  created_at: data.created_at,
                  updated_at: data.updated_at,
                  private: data.private,
                  tags: data.tags,
                },
              }, null, 2),
            },
          ],
        };
      }

      case "qiita_delete_article": {
        const response = await fetch(
          `${QIITA_API_BASE}/items/${args.article_id}`,
          {
            method: "DELETE",
            headers: {
              Authorization: `Bearer ${QIITA_TOKEN}`,
            },
          }
        );

        if (!response.ok && response.status !== 204) {
          const error = await response.json();
          throw new Error(`Qiita API Error: ${JSON.stringify(error)}`);
        }

        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                success: true,
                message: "記事を削除しました",
                article_id: args.article_id,
              }, null, 2),
            },
          ],
        };
      }

      case "qiita_get_article_stats": {
        const response = await fetch(
          `${QIITA_API_BASE}/items/${args.article_id}`,
          {
            headers: {
              Authorization: `Bearer ${QIITA_TOKEN}`,
            },
          }
        );

        if (!response.ok) {
          const error = await response.json();
          throw new Error(`Qiita API Error: ${JSON.stringify(error)}`);
        }

        const data = await response.json();
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                success: true,
                stats: {
                  article_id: data.id,
                  title: data.title,
                  url: data.url,
                  likes_count: data.likes_count,
                  page_views_count: data.page_views_count,
                  stocks_count: data.stocks_count,
                  comments_count: data.comments_count,
                  created_at: data.created_at,
                  updated_at: data.updated_at,
                },
              }, null, 2),
            },
          ],
        };
      }

      case "qiita_get_organizations": {
        const response = await fetch(
          `${QIITA_API_BASE}/authenticated_user/organizations`,
          {
            headers: {
              Authorization: `Bearer ${QIITA_TOKEN}`,
            },
          }
        );

        if (!response.ok) {
          const error = await response.json();
          throw new Error(`Qiita API Error: ${JSON.stringify(error)}`);
        }

        const data = await response.json();
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                success: true,
                organizations: data.map((org) => ({
                  name: org.name,
                  url_name: org.url_name,
                  profile_image_url: org.profile_image_url,
                  description: org.description,
                })),
              }, null, 2),
            },
          ],
        };
      }

      default:
        throw new Error(`Unknown tool: ${name}`);
    }
  } catch (error) {
    return {
      content: [
        {
          type: "text",
          text: JSON.stringify({
            success: false,
            error: error.message,
          }, null, 2),
        },
      ],
      isError: true,
    };
  }
});

// サーバー起動
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("Qiita MCP server running on stdio");
}

main().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
