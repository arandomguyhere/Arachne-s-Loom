# 🏛️ Olympus Scraper

**Olympus Scraper** is an automated OSINT tool that uses Google Dork-style queries (via DuckDuckGo) to gather data from Pastebin (or other target sites) and deploys the results as a live GitHub Pages site.

This scraper is designed for **ethical cybersecurity research** and **open-source threat intelligence gathering**.

---

## ✨ Features

- 🔍 Uses **DuckDuckGo search** to find links using Google Dork-like queries.
- 🕷️ Scrapes target sites (like Pastebin) to extract relevant content.
- 🛡️ Includes **rotating user agents, referrers, headers, delays, and retries** to mimic human browsing and avoid basic anti-bot detection.
- 📦 Saves results to `data/scroll_of_news.json`.
- 🌐 Deploys the results to GitHub Pages using **peaceiris/actions-gh-pages**.
- 🔒 Fully automated via GitHub Actions — runs every 6 hours or on demand.

---

## 📂 Project Structure

