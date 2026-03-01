import os
import json
import google.generativeai as genai
from dotenv import load_dotenv
from supabase import create_client, Client

# 1. Load Environment Variables
load_dotenv()

SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY")
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")

# 2. Initialize Clients
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
genai.configure(api_key=GEMINI_API_KEY)

# Use Gemini 1.5 Flash (Perfect for fast, cheap text processing in hackathons)
model = genai.GenerativeModel('gemini-1.5-flash')

def get_unprocessed_article():
    """Fetches one article from news_articles that isn't in finbytes yet."""
    print("🔍 Looking for unprocessed articles...")
    
    # Get all processed article IDs
    processed_response = supabase.table("finbytes").select("article_id").execute()
    processed_ids = [row['article_id'] for row in processed_response.data]
    
    # Query for articles, filtering out the ones we already processed
    query = supabase.table("news_articles").select("*")
    if processed_ids:
        # Supabase syntax to exclude a list of IDs
        query = query.not_.in_("id", processed_ids)
        
    # Get just the oldest unprocessed one
    unprocessed = query.order("created_at").limit(1).execute()
    
    if len(unprocessed.data) == 0:
        print("✅ All articles have been processed into FinBytes!")
        return None
        
    return unprocessed.data[0]

def generate_finbyte_card(article):
    """Sends the raw article to Gemini and asks for strict JSON back."""
    print(f"🧠 Sending to Gemini: '{article['headline']}'...")
    
    prompt = f"""
    You are an expert financial analyst creating bite-sized content for a mobile app.
    Read the following news article and generate a JSON response with exactly these keys:
    
    1. "category": Choose EXACTLY ONE from this list: ["Markets", "Economy", "Policy", "Company Moves", "Money & Credit", "Personal Finance", "Crypto Currency"].
    2. "summary_eli5": A simple, jargon-free summary (max 90 words) for a beginner.
    3. "summary_overview": A more technical overview (max 90 words) for an experienced investor.
    4. "fallback_takeaway": One sentence of generic actionable advice based on this news.
    5. "street_vs_suit_verdict": A 1-sentence synthesis of how retail investors might view this versus institutional investors.
    
    Here is the article text:
    Headline: {article['headline']}
    Content: {article['raw_content']}
    
    RETURN ONLY VALID JSON. Do not include markdown formatting like ```json.
    """
    
    try:
        # We enforce JSON output natively in Gemini
        response = model.generate_content(
            prompt,
            generation_config={"response_mime_type": "application/json"}
        )
        
        # Parse the JSON string into a Python dictionary
        return json.loads(response.text)
        
    except Exception as e:
        print(f"❌ AI Generation failed: {e}")
        return None

def process_and_store():
    # Step 1: Get raw data
    article = get_unprocessed_article()
    if not article:
        return
        
    # Step 2: Generate the AI Card
    ai_data = generate_finbyte_card(article)
    if not ai_data:
        return
        
    print(f"🎯 AI categorized this as: {ai_data['category']}")
    
    # Step 3: Format for Database
    db_payload = {
        "article_id": article['id'],
        "category": ai_data['category'],
        "summary_eli5": ai_data['summary_eli5'],
        "summary_overview": ai_data['summary_overview'],
        "fallback_takeaway": ai_data['fallback_takeaway'],
        "street_vs_suit_verdict": ai_data['street_vs_suit_verdict']
    }
    
    # Step 4: Save to finbytes table
    try:
        supabase.table("finbytes").insert(db_payload).execute()
        print("✅ Success! FinByte Card stored in database and ready for Flutter.")
        
        # Print a preview so you can see the magic!
        print("\n--- APP PREVIEW (ELI5 MODE) ---")
        print(f"Category: {db_payload['category']}")
        print(f"Text: {db_payload['summary_eli5']}")
        print(f"Action: {db_payload['fallback_takeaway']}")
        print("-------------------------------\n")
        
    except Exception as e:
        print(f"❌ Database insert failed: {e}")

if __name__ == "__main__":
    process_and_store()