---
name: seo
description: "Optimize search engine visibility through technical SEO, structured data (JSON-LD, Schema.org), meta tags, Open Graph, XML sitemaps, canonical URLs, and heading hierarchy. Use when auditing SEO, implementing structured data, optimizing title tags, configuring sitemaps, improving crawlability, or validating rich results."
user-invocable: false
---

# SEO optimization

Search engine optimization based on Lighthouse SEO audits and Google Search guidelines. Focus on technical SEO, on-page optimization, and structured data.

## SEO Fundamentals

Search ranking factors (approximate influence):

| Factor | Influence | This Skill |
|--------|-----------|------------|
| Content quality & relevance | ~40% | Partial (structure) |
| Backlinks & authority | ~25% | ✗ |
| Technical SEO | ~15% | ✓ |
| Page experience (Core Web Vitals) | ~10% | See vercel-react-best-practices skill |
| On-page SEO | ~10% | ✓ |

---

## Technical SEO

| Rule | Key Points |
|------|-----------|
| robots.txt | Allow /, block /admin/ /api/ /private/. Include Sitemap URL. Don't block rendering resources |
| Meta robots | `index,follow`(default), `noindex,nofollow`(private), `max-snippet:150,max-image-preview:large` |
| Canonical URLs | Self-referencing canonical on every page. Prevent duplicate content |
| XML Sitemap | Max 50K URLs or 50MB. Only canonical indexable URLs. Update lastmod. Submit to GSC |
| URL Structure | Hyphens not underscores, lowercase, < 75 chars, keywords naturally, HTTPS |
| HTTPS | All resources HTTPS. HSTS + X-Content-Type-Options + X-Frame-Options headers |

→ Code examples: [reference.md](reference.md) Section 1

---

## On-page SEO

| Rule | Key Points |
|------|-----------|
| Title Tags | 50-60 chars. Primary keyword near start. Unique per page. Brand at end |
| Meta Descriptions | 150-160 chars. Include keyword. CTA. Unique per page |
| Heading Hierarchy | Single `<h1>` per page. Sequential levels. Keywords naturally |
| Image SEO | Descriptive filenames. Alt text describes content. WebP/AVIF. Lazy load below-fold |
| Internal Linking | Descriptive anchor text with keywords. Breadcrumbs for hierarchy. Fix broken links |

→ Code examples: [reference.md](reference.md) Section 2

---

## Structured data (JSON-LD)

Types: **Organization**, **Article**, **Product**, **FAQ**, **BreadcrumbList** — all use `<script type="application/ld+json">` with `@context: "https://schema.org"`.

Validate: [Rich Results Test](https://search.google.com/test/rich-results) / [Schema.org Validator](https://validator.schema.org/)

→ Full JSON-LD templates: [reference.md](reference.md) Section 3

---

## Mobile & International SEO [MEDIUM]

| Rule | Key Points |
|------|-----------|
| Responsive viewport | `width=device-width, initial-scale=1` |
| Tap targets | min-height/width 48px, padding 12px, font-size 16px |
| Hreflang | `<link rel="alternate" hreflang="xx" href="...">` for each language + `x-default` |
| Language | `<html lang="en">` or `<html lang="es-MX">` |

→ Code examples: [reference.md](reference.md) Section 4

---

## SEO audit checklist

### Critical
- [ ] HTTPS enabled
- [ ] robots.txt allows crawling
- [ ] No `noindex` on important pages
- [ ] Title tags present and unique
- [ ] Single `<h1>` per page

### High priority
- [ ] Meta descriptions present
- [ ] Sitemap submitted
- [ ] Canonical URLs set
- [ ] Mobile-responsive
- [ ] Core Web Vitals passing

### Medium priority
- [ ] Structured data implemented
- [ ] Internal linking strategy
- [ ] Image alt text
- [ ] Descriptive URLs
- [ ] Breadcrumb navigation

### Ongoing
- [ ] Fix crawl errors in Search Console
- [ ] Update sitemap when content changes
- [ ] Monitor ranking changes
- [ ] Check for broken links
- [ ] Review Search Console insights

---

## Tools

| Tool | Use |
|------|-----|
| Google Search Console | Monitor indexing, fix issues |
| Google PageSpeed Insights | Performance + Core Web Vitals |
| Rich Results Test | Validate structured data |
| Lighthouse | Full SEO audit |
| Screaming Frog | Crawl analysis |

## Cross-references

- **_vercel-react-best-practices**: Core Web Vitals 最適化の実装パターン参照
- **_web-design-guidelines**: WCAG 2.2 アクセシビリティ・セマンティック HTML 連携
