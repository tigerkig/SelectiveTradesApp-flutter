class Watchlist{

  String id;
  String symbol;
  double buy_price;
  String buy_date;
  double live_price;
  double price_change_24hr;
  double pct_change_24hr;
  double net_change;
  double net_pct_change;

  Watchlist({
      this.id,
      this.symbol,
      this.buy_price,
      this.buy_date,
      this.live_price,
      this.price_change_24hr,
      this.pct_change_24hr,
      this.net_change,
      this.net_pct_change
  });
}