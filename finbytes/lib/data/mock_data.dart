import '../models/byte_model.dart';

/// High-quality mock cards — all summaries strictly under 90 words,
/// zero jargon, covering three of the seven FinBytes categories.
final List<Byte> mockBytes = [
  Byte(
    id: 'mock_001',
    category: 'Markets',
    title: 'S&P 500 Hits Record High as Jobs Data Beats Expectations',
    source: 'Reuters',
    summaryBullets: [
      'The US stock market hit an all-time high after a government report showed employers added 250,000 new jobs last month — way more than experts predicted.',
      'When lots of people are employed, they spend more money, which helps companies earn more, so investors get excited and buy more stock.',
      'The tech sector led the rally, with major chipmakers up 3–5% on hopes that strong consumer spending will boost device sales.',
    ],
    eli5Content:
        'Imagine the stock market is like a school scoreboard. Today the score went up to its highest ever because a lot more people got new jobs than anyone expected. More jobs means people have more money to spend, which makes businesses happier, which makes the scoreboard go up!',
  ),

  Byte(
    id: 'mock_002',
    category: 'Crypto',
    title: 'Bitcoin Tops \$95K as Institutional ETF Inflows Surge',
    source: 'CoinDesk',
    summaryBullets: [
      'Bitcoin crossed \$95,000 for the first time this year after large investment funds poured over \$2 billion into Bitcoin ETFs in a single week.',
      'An ETF is like a basket you can buy on a normal stock exchange — it lets big funds invest in Bitcoin without holding the coins directly.',
      'Analysts say the price rise is driven by real demand from pension funds and asset managers, not just individual traders betting on price swings.',
    ],
    eli5Content:
        'Bitcoin is like a very limited-edition trading card. Big grown-up money managers — like the people who look after your pension — have started buying lots of them through a special shop called an ETF. When lots of important buyers want the same card, the price shoots up!',
  ),

  Byte(
    id: 'mock_003',
    category: 'Personal Finance',
    title: 'High-Yield Savings Accounts Still Beating Inflation — For Now',
    source: 'NerdWallet',
    summaryBullets: [
      'Online savings accounts are currently paying 4.5–5.1% interest per year, which is still higher than the current 3.2% inflation rate.',
      'This means your money is actually growing in real terms — meaning you can buy slightly more stuff next year than you could today.',
      'Experts warn that the Federal Reserve is likely to cut rates twice in 2025, which will gradually push these savings rates lower.',
    ],
    eli5Content:
        'If prices go up by 3% this year but your savings account pays you 5%, you actually come out ahead — your money grows faster than things get expensive. It is like getting a raise that outpaces your bills. Enjoy it while it lasts, because interest rates are expected to fall later this year.',
  ),
];
