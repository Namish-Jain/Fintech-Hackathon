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

# Use Gemini 1.5 Flash 
model = genai.GenerativeModel('gemini-2.5-flash')

def get_unprocessed_articles():
    """Fetches all articles from news_articles that aren't in finbytes yet."""
    print("🔍 Scanning database for unprocessed articles...")
    
    processed_response = supabase.table("finbytes").select("article_id").execute()
    processed_ids = [row['article_id'] for row in processed_response.data]
    
    query = supabase.table("news_articles").select("*")
    if processed_ids:
        query = query.not_.in_("id", processed_ids)
        
    unprocessed = query.order("created_at").execute()
    return unprocessed.data

def generate_finbyte_card(article):
    """Generates the card data, acting as a predictive sentiment engine."""
    
    prompt = f"""
   SUMMARY SPECIFICATIONS:
1. summary_eli5: 
   - Persona: Absolute Beginner (ELI5). 
   - Tone: Jargon-free, punchy, and narrative. Don't use kid-like analogies. Replace words like 'inflation' with 'prices going up'. The level should be of a 16 year old with basic finanical knowledge.
   - Format: Exactly 3 bullet points.
   - Constraint: Max 70 words total.
   - Output 3 Bullet Points
2. summary_overview: 
   - Persona: Experienced Investor. 
   - Tone: High-signal, technical, and objective. Use professional terms like 'yields', 'volatility', or 'EPS'.
   - Format: 3-4 professional bullet points.
   - Constraint: Between 80 and 90 words. DO NOT EXCEED 90 WORDS.
3. actionable_takeaway:
   - Persona: General Wealth Advisor answering "Why does this matter?"
   - Context: You do not know the user's specific personal finances.
   - Content: Contrast the extremes. Provide advice for someone who would be HEAVILY impacted by this news (explain why, and what they should do regarding savings, taxes, or investments), and contrast it with someone who will be MINIMALLY impacted.
   - Format: Exactly 4 bullet points.
4. Impact Score: An integer from 0 to 100. Calculate this based on the article's sentiment volatility and your simulated public reaction. (100 = massive market-moving event/high panic or euphoria, 0 = zero impact/boring routine news).

5. Simulated Public Reaction: Based on your sentiment analysis of the article, predict and simulate exactly how the general public (retail investors/consumers) will react to this news. Keep it to 1-2 concise, realistic sentences.

JSON KEYS REQUIRED:
Return exactly these 5 keys in a flat JSON object:
{{
  "summary_eli5": "string",
  "summary_overview": "string",
  "actionable_takeaway": "string",
  "simulated_public_reaction": "string",
  "impact_score": "integer"
}}

INPUT DATA:
Headline: {article['headline']}
Category: {article['category']}
Content: {article['raw_content']}

STRICT RULE: RETURN ONLY VALID JSON. Do not include markdown formatting like ```json. 
Do not include any text before or after the JSON object
    """
    
    try:
        response = model.generate_content(
            prompt,
            generation_config={"response_mime_type": "application/json"}
        )
        return json.loads(response.text)
        
    except Exception as e:
        print(f"   ❌ AI Generation failed: {e}")
        return None

def process_all():
    articles = get_unprocessed_articles()
    
    if not articles:
        print("✅ All articles have already been processed into FinBytes!")
        return
        
    print(f"🚀 Found {len(articles)} articles ready. Processing ALL high-impact cards...")
    
    processed_count = 0
    deleted_count = 0
    
    for index, article in enumerate(articles):
        print(f"\n[{index + 1}/{len(articles)}] 🧠 Analyzing: {article['headline'][:50]}...")
        
        # 1. Generate the AI Data
        ai_data = generate_finbyte_card(article)
        if not ai_data:
            print("   ⏭️ Skipping due to AI error.")
            continue
            
        score = ai_data.get('impact_score', 0)
        article_id = article['id']
        
        print(f"   🔥 Impact Score: {score}/100")
        
        # --- THE FILTERING LOGIC ---
        if score < 40:
            print(f"   🗑️ LOW IMPACT: Deleting article from database to keep feed clean.")
            try:
                supabase.table("news_articles").delete().eq("id", article_id).execute()
                deleted_count += 1
            except Exception as e:
                print(f"   ❌ Failed to delete article: {e}")
                
        else:
            print(f"   💬 Public Reaction: {ai_data.get('simulated_public_reaction', '')[:70]}...")
            
            # 2. Format for Database (High Impact Only)
            db_payload = {
                "article_id": article_id,
                "category": article['category'], 
                "summary_eli5": ai_data.get('summary_eli5', ''),
                "summary_overview": ai_data.get('summary_overview', ''),
                "actionable_takeaway": ai_data.get('actionable_takeaway', ''),
                "simulated_public_reaction": ai_data.get('simulated_public_reaction', ''),
                "impact_score": score
            }
            
            # 3. Save to finbytes table
            try:
                supabase.table("finbytes").insert(db_payload).execute()
                print("   ✅ High-impact card stored perfectly in database.")
                processed_count += 1
                    
            except Exception as e:
                print(f"   ❌ Database insert failed: {e}")
            
        # 4. RATE LIMIT PROTECTION: Sleep for 4 seconds to stay under 15 requests per minute
        if index < len(articles) - 1:
            time.sleep(4)
            
    print(f"\n🎉 DONE! Generated {processed_count} high-impact cards. Purged {deleted_count} low-impact articles.")

if __name__ == "__main__":
    process_all()