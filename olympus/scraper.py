import requests
from bs4 import BeautifulSoup
import json
import time
import random
import os
from faker import Faker
import logging

# Constants
DATA_DIR = "data"
OUTPUT_FILE = os.path.join(DATA_DIR, "scroll_of_news.json")
fake = Faker()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler("olympus_scraper.log"),
        logging.StreamHandler()
    ]
)

# Function to generate dynamic, realistic headers
def generate_headers():
    user_agent = fake.user_agent()
    accept_language = f"{fake.language_code()},{fake.language_code()};q=0.9"
    referers = [
        "https://www.reddit.com/",
        "https://twitter.com/",
        "https://news.ycombinator.com/",
        "https://www.duckduckgo.com/",
        fake.url()
    ]
    referer = random.choice(referers)
    headers = {
        "User-Agent": user_agent,
        "Accept-Language": accept_language,
        "Accept-Encoding": "gzip, deflate, br",
        "Referer": referer,
        "X-Requested-With": "XMLHttpRequest",
        "Upgrade-Insecure-Requests": "1",
        "Cache-Control": "no-cache",
        "DNT": "1",
        "Connection": "keep-alive"
    }
    return headers

# Function to perform HTTP GET with retries and exponential backoff
def fetch_with_retries(session, url, max_retries=3):
    for attempt in range(1, max_retries + 1):
        try:
            headers = generate_headers()
            response = session.get(url, headers=headers, timeout=10)
            if response.status_code == 200:
                logging.info(f"Fetched successfully: {url}")
                return response
            else:
                logging.warning(f"Unexpected status code {response.status_code} for {url}")
        except requests.RequestException as e:
            logging.error(f"Request failed (attempt {attempt}): {e}")
        time.sleep(2 ** attempt + random.uniform(0, 2))  # Exponential backoff
    logging.error(f"Failed to fetch after {max_retries} attempts: {url}")
    return None

def search_duckduckgo(query, max_results=10):
    session = requests.Session()
    search_results = []
    url = f"https://html.duckduckgo.com/html/?q={query}"
    response = fetch_with_retries(session, url)
    if not response:
        return search_results

    soup = BeautifulSoup(response.text, "html.parser")
    for a in soup.find_all("a", class_="result__url", href=True):
        search_results.append(a["href"])
        if len(search_results) >= max_results:
            break

    time.sleep(random.uniform(2, 5))  # Simulate human delay
    return search_results

def scrape_pastebin(url):
    session = requests.Session()
    response = fetch_with_retries(session, url)
    if not response:
        return ""

    soup = BeautifulSoup(response.text, "html.parser")
    paste_content = ""
    paste_div = soup.find("textarea", {"id": "paste_code"})
    if paste_div:
        paste_content = paste_div.text.strip()
    else:
        pre_tag = soup.find("pre")
        if pre_tag:
            paste_content = pre_tag.text.strip()
    return paste_content

def main():
    os.makedirs(DATA_DIR, exist_ok=True)
    query = 'site:pastebin.com "stealer logs"'
    links = search_duckduckgo(query, max_results=10)

    results = []
    for idx, link in enumerate(links, start=1):
        logging.info(f"Hermes is gathering scroll {idx}: {link}")
        paste_content = scrape_pastebin(link)
        results.append({
            "url": link,
            "content": paste_content
        })
        time.sleep(random.uniform(2, 5))  # Delay between pages

    with open(OUTPUT_FILE, "w") as f:
        json.dump(results, f, indent=2)

    logging.info(f"Hermes has delivered {len(results)} scrolls from Olympus! 🏛️")

if __name__ == "__main__":
    main()
