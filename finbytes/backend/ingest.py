import os
import requests
import difflib
import time
from datetime import datetime, timedelta
from bs4 import BeautifulSoup
from dotenv import load_dotenv
from supabase import create_client, Client

# 1. Load Environment Variables
load_dotenv()
SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY")
ALPHA_VANTAGE_API_KEY = os.environ.get("ALPHA_VANTAGE_API_KEY")

# 2. Initialize Supabase
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

def is_too_similar(new_headline, accepted_headlines, threshold=0.55):
    """Prevents saving duplicate stories about the exact same event."""
    for accepted in accepted_headlines:
        if difflib.SequenceMatcher(None, new_headline.lower(), accepted.lower()).ratio() > threshold:
            return True
    return False

def scrape_full_text(url):
    """Bypasses API truncation by scraping the actual webpage."""
    try:
        headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}
        page = requests.get(url, headers=headers, timeout=10)
        soup = BeautifulSoup(page.content, 'html.parser')
        
        paragraphs = soup.find_all('p')
        full_text = ' '.join([p.get_text() for p in paragraphs])
        
        return full_text.strip() if len(full_text.strip()) > 100 else None
    except Exception:
        return None

def fetch_all_categories(target_per_category=10):
    """
    Loops through all 7 FinBytes categories, fetching distinct, 
    recent articles for each directly from Alpha Vantage.
    """
    
    # 1. Map FinBytes categories to ONE exact Alpha Vantage topic
    category_map = {
        "Markets": "financial_markets",
        "Economy": "economy_macro",
        "Policy": "economy_monetary",
        "Company Moves": "earnings", 
        "Money & Credit": "finance",
        "Personal Finance": "real_estate", 
        "Crypto Currency": "blockchain"
    }

    # 2. Set the 7-day time window
    one_week_ago = datetime.now() - timedelta(days=7)
    time_from_str = one_week_ago.strftime("%Y%m%dT%H%M")
    
    total_stored = 0

    # 3. The Grand Loop
    for category_name, av_topic in category_map.items():
        print(f"\n=======================================================")
        print(f"Fetching {target_per_category} articles for: {category_name} (Topic: {av_topic})")
        print(f"=======================================================")
        
        api_url = f"https://www.alphavantage.co/query?function=NEWS_SENTIMENT&topics={av_topic}&time_from={time_from_str}&sort=LATEST&limit=50&apikey={ALPHA_VANTAGE_API_KEY}"
        
        response = requests.get(api_url)
        data = response.json()

        if "feed" in data and len(data["feed"]) > 0:
            stored_count = 0
            accepted_headlines = []
            
            for article in data["feed"]:
                # Stop if we hit our target for this specific category
                if stored_count >= target_per_category:
                    break
                    
                article_url = article.get("url")
                headline = article.get("title")
                
                # Skip invalid entries
                if not article_url or not headline:
                    continue
                    
                # Skip duplicate/highly similar news
                if is_too_similar(headline, accepted_headlines):
                    continue
                    
                # Scrape the full text, with fallback to API summary
                full_content = scrape_full_text(article_url)
                final_content = full_content if full_content else article.get("summary", "No content available.")
                
                # Format timestamp
                raw_time = article.get("time_published", "")
                formatted_time = None
                if len(raw_time) == 15:
                    formatted_time = f"{raw_time[:4]}-{raw_time[4:6]}-{raw_time[6:8]} {raw_time[9:11]}:{raw_time[11:13]}:{raw_time[13:]}"

                # 4. The Payload (Now including the Category!)
                db_payload = {
                    "headline": headline,
                    "source_name": article.get("source", "Alpha Vantage"),
                    "url": article_url,
                    "raw_content": final_content,
                    "published_at": formatted_time,
                    "category": category_name  # The AI no longer has to guess!
                }

                try:
                    supabase.table("news_articles").insert(db_payload).execute()
                    print(f"   ✅ Saved: {headline[:60]}...")
                    accepted_headlines.append(headline)
                    stored_count += 1
                    total_stored += 1
                except Exception:
                    # Fails silently if the URL is already in the database (Unique Constraint)
                    pass
            
            print(f"➡️ Category '{category_name}' Complete: Saved {stored_count} articles.")
            
        else:
            print(f"❌ Failed to fetch {category_name}.")
            if "Information" in data:
                print(f"API Message: {data['Information']}")
                
        # 5. API Protection: Pause for 2 seconds to avoid rate limiting
        time.sleep(2)

    print(f"\n🎉 GRAND TOTAL: Successfully stored {total_stored} articles across all categories!")

if __name__ == "__main__":
    fetch_all_categories(target_per_category=10)