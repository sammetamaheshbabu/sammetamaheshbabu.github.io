# ToorIndia — Static Single Page Site

A lightweight static replica of the ToorIndia home page built with HTML + Bootstrap CSS. No JavaScript app or backend — just a single `index.html` you can edit anytime.

## Features

- Responsive layout with Bootstrap 5
- Header, Hero, Packages, How It Works, Reviews, Gallery, CTA, Footer
- "Book on WhatsApp" buttons with your number and pre-filled message
- Clean structure to self-host via GitHub Pages
- SEO ready: canonical, Open Graph/Twitter tags, JSON-LD, robots.txt, sitemap.xml

## Structure

```
index.html
assets/
  css/styles.css
  img/   # Place your images and logos here
CNAME    # Optional: set to 'toorindia.com' for GitHub Pages custom domain
robots.txt
sitemap.xml
```

## Update WhatsApp number/message

Search in `index.html` for `wa.me/919676003945` and update the phone or message as needed. Message text must be URL-encoded.

## Publish to GitHub Pages

1. Create a new GitHub repository (public), e.g. `toorindia-static`.
2. Add these files and push the repo.
3. In GitHub: Settings → Pages → Build and deployment
   - Source: `Deploy from a branch`
   - Branch: `main` (or `master`), folder `/root`
4. Wait for the site to build. Your site will be available at `https://<username>.github.io/<repo>/`.

If you use a custom domain (CNAME), GitHub Pages will host your site at that domain and serve `robots.txt` and `sitemap.xml` from the root automatically.

## Use your domain toorindia.com

Option A — apex domain on GitHub Pages (recommended):

- Create a file named `CNAME` in the repo root containing:
  ```
  toorindia.com
  ```
- In your DNS provider (where toorindia.com is managed), create A records:
  - `@` → 185.199.108.153
  - `@` → 185.199.109.153
  - `@` → 185.199.110.153
  - `@` → 185.199.111.153
- (Optional) Also add `AAAA` records for IPv6 (from GitHub Pages docs).
- In GitHub: Settings → Pages → Custom domain: `toorindia.com`. Enable **Enforce HTTPS** after the certificate issues.

Tip: After domain is active, re-check the canonical/OG URLs and update if needed.

Option B — use `www` as the main domain:

- Create a file `CNAME` with `www.toorindia.com`.
- DNS: Add a CNAME record `www` → `<username>.github.io`.
- Point the apex `toorindia.com` to `www` using an ALIAS/ANAME/URL redirect at your DNS provider.

## Editing

- Open `index.html` and edit sections/content as needed.
- Put your images under `assets/img/` and update paths.
- Customize colors in `assets/css/styles.css`.

## Attributions

Logos and images are owned by ToorIndia. Bootstrap is © Twitter, Inc. and The Bootstrap Authors, licensed under MIT.
