import os
import json
import time
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

# Use Gemini 1.5 Flash (Standard for 2026 fast processing)
model = genai.GenerativeModel('gemini-2.5-flash')

def get_unprocessed_articles():
    """Fetches articles from news_articles that aren't in finbytes yet."""
    print("🔍 Scanning database for unprocessed articles...")
    
    processed_response = supabase.table("finbytes").select("article_id").execute()
    processed_ids = [row['article_id'] for row in processed_response.data]
    
    query = supabase.table("news_articles").select("*")
    if processed_ids:
        query = query.not_.in_("id", processed_ids)
        
    # Order by created_at to process chronologically
    unprocessed = query.order("created_at").execute()
    return unprocessed.data

def generate_finbyte_card(article):
    """Generates the card data using the latest prompt logic."""
    prompt = f"""
    You are an expert quantitative financial analyst and behavioral economist. Perform a deep sentiment analysis on the provided news article and return a structured JSON response.

SUMMARY SPECIFICATIONS:
1. summary_eli5: 
   - Persona: Absolute Beginner (ELI5). 
   - Tone: Jargon-free, punchy, and narrative. 
   - Format: Exactly 3 bullet points.
2. summary_overview: 
   - Persona: Experienced Investor. 
   - Tone: High-signal, technical, and objective. 
   - Format: 3-4 professional bullet points.
3. actionable_takeaway:
   - Persona: General Wealth Advisor.
   - Content: Contrast HEAVY impact vs MINIMAL impact. Mention savings, taxes, or investments.
   - Format: Exactly 4 bullet points.
4. impact_score: Integer (0-100). (100 = massive market-moving event, 0 = boring news).
5. simulated_public_reaction: 1-2 concise sentences.

JSON KEYS REQUIRED:
Return exactly: {{ "summary_eli5", "summary_overview", "actionable_takeaway", "simulated_public_reaction", "impact_score" }}

INPUT DATA:
Headline: {article['headline']}
Category: {article['category']}
Content: {article['raw_content']}

STRICT RULE: RETURN ONLY VALID JSON. No markdown backticks.
    """
    try:
        response = model.generate_content(
            prompt,
            generation_config={{"response_mime_type": "application/json"}}
        )
        return json.loads(response.text)
    except Exception as e:
        print(f"   ❌ AI Generation failed: {e}")
        return None

def process_and_filter():
    all_unprocessed = get_unprocessed_articles()
    if not all_unprocessed:
        print("✅ No new articles to process.")
        return
        
    print(f"🚀 Filtering {len(all_unprocessed)} articles. Targeting high-impact news (>40)...")
    
    processed_count = 0
    deleted_count = 0

    for article in all_unprocessed:
        print(f"\n🧠 Analyzing: {article['headline'][:60]}...")
        
        ai_data = generate_finbyte_card(article)
        if not ai_data:
            continue
            
        score = ai_data.get('impact_score', 0)
        article_id = article['id']

        # --- LOGIC: SCORE FILTERING ---
        if score >= 40:
            print(f"   ✅ HIGH IMPACT ({score}/100). Appending to FinBytes...")
            db_payload = {
                "article_id": article_id,
                "category": article['category'], 
                "summary_eli5": ai_data.get('summary_eli5', ''),
                "summary_overview": ai_data.get('summary_overview', ''),
                "actionable_takeaway": ai_data.get('actionable_takeaway', ''),
                "simulated_public_reaction": ai_data.get('simulated_public_reaction', ''),
                "impact_score": score
            }
            supabase.table("finbytes").insert(db_payload).execute()
            processed_count += 1
            
            # Since we only want to process the FIRST valid article for this test:
            print("🛑 Finished processing the first high-impact article. Stopping test.")
            break 
        else:
            print(f"   🗑️ LOW IMPACT ({score}/100). Deleting from source table...")
            supabase.table("news_articles").delete().eq("id", article_id).execute()
            deleted_count += 1
            # Continue the loop to find the next article that might be > 40

    print(f"\n✨ Final Report: 1 card created, {deleted_count} low-impact articles purged.")

if __name__ == "__main__":
    process_and_filter()