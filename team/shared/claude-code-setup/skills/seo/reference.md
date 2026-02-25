# SEO Reference — Code Examples & Templates

## Section 1: Technical SEO

### robots.txt

```text
User-agent: *
Allow: /
Disallow: /admin/
Disallow: /api/
Disallow: /private/
Sitemap: https://example.com/sitemap.xml
```

### Meta Robots

```html
<meta name="robots" content="index, follow">
<meta name="robots" content="noindex, nofollow">
<meta name="robots" content="max-snippet:150, max-image-preview:large">
```

### Canonical URLs

```html
<link rel="canonical" href="https://example.com/current-page">
```

### XML Sitemap

```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://example.com/</loc>
    <lastmod>2024-01-15</lastmod>
    <changefreq>daily</changefreq>
    <priority>1.0</priority>
  </url>
</urlset>
```

### Security Headers

```
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
```

---

## Section 2: On-Page SEO

### Title Tags

```html
<!-- BAD -->
<title>Page</title>

<!-- GOOD: Primary keyword near beginning, brand at end -->
<title>Blue Widgets for Sale | Premium Quality | Example Store</title>
```

### Meta Descriptions

```html
<meta name="description" content="Shop premium blue widgets with free shipping. 30-day returns. Rated 4.9/5 by 10,000+ customers. Order today and save 20%.">
```

### Heading Structure

```html
<h1>Blue Widgets - Premium Quality</h1>
  <h2>Product Features</h2>
    <h3>Durability</h3>
    <h3>Design</h3>
  <h2>Customer Reviews</h2>
  <h2>Pricing</h2>
```

### Image SEO

```html
<img src="blue-widget-product-photo.webp"
     alt="Blue widget with chrome finish, side view showing control panel"
     width="800" height="600" loading="lazy">
```

### Internal Linking

```html
<!-- BAD -->
<a href="/products">Click here</a>

<!-- GOOD: Descriptive anchor text -->
<a href="/products/blue-widgets">Browse our blue widget collection</a>
```

---

## Section 3: Structured Data (JSON-LD)

### Organization

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Organization",
  "name": "Example Company",
  "url": "https://example.com",
  "logo": "https://example.com/logo.png",
  "sameAs": ["https://twitter.com/example", "https://linkedin.com/company/example"],
  "contactPoint": {
    "@type": "ContactPoint",
    "telephone": "+1-555-123-4567",
    "contactType": "customer service"
  }
}
</script>
```

### Article

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "How to Choose the Right Widget",
  "description": "Complete guide to selecting widgets for your needs.",
  "image": "https://example.com/article-image.jpg",
  "author": { "@type": "Person", "name": "Jane Smith", "url": "https://example.com/authors/jane-smith" },
  "publisher": { "@type": "Organization", "name": "Example Blog", "logo": { "@type": "ImageObject", "url": "https://example.com/logo.png" } },
  "datePublished": "2024-01-15",
  "dateModified": "2024-01-20"
}
</script>
```

### Product

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Product",
  "name": "Blue Widget Pro",
  "image": "https://example.com/blue-widget.jpg",
  "description": "Premium blue widget with advanced features.",
  "brand": { "@type": "Brand", "name": "WidgetCo" },
  "offers": {
    "@type": "Offer",
    "price": "49.99",
    "priceCurrency": "USD",
    "availability": "https://schema.org/InStock",
    "url": "https://example.com/products/blue-widget"
  },
  "aggregateRating": { "@type": "AggregateRating", "ratingValue": "4.8", "reviewCount": "1250" }
}
</script>
```

### FAQ

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    { "@type": "Question", "name": "What colors are available?", "acceptedAnswer": { "@type": "Answer", "text": "Our widgets come in blue, red, and green." } },
    { "@type": "Question", "name": "What is the warranty?", "acceptedAnswer": { "@type": "Answer", "text": "All widgets include a 2-year warranty." } }
  ]
}
</script>
```

### BreadcrumbList

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "BreadcrumbList",
  "itemListElement": [
    { "@type": "ListItem", "position": 1, "name": "Home", "item": "https://example.com" },
    { "@type": "ListItem", "position": 2, "name": "Products", "item": "https://example.com/products" },
    { "@type": "ListItem", "position": 3, "name": "Blue Widgets", "item": "https://example.com/products/blue-widgets" }
  ]
}
</script>
```

---

## Section 4: Mobile & International SEO

### Responsive Viewport

```html
<meta name="viewport" content="width=device-width, initial-scale=1">
```

### Tap Targets

```css
.mobile-friendly-link {
  padding: 12px;
  font-size: 16px;
  min-height: 48px;
  min-width: 48px;
}
```

### Hreflang

```html
<link rel="alternate" hreflang="en" href="https://example.com/page">
<link rel="alternate" hreflang="es" href="https://example.com/es/page">
<link rel="alternate" hreflang="x-default" href="https://example.com/page">
```

### Language Declaration

```html
<html lang="en">
<!-- or regional: -->
<html lang="es-MX">
```
