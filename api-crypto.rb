require 'open-uri'
require 'json'
require 'sqlite3'

loop {
    ##################### JSON #####################

    # Load json from api coinbase
    currency = "USD"
    url = "https://api.coinbase.com/v2/exchange-rates?currency="+currency
    jsonText = URI.open(url) {|f| f.read }

    # Display json to console
    json = JSON.parse(jsonText)
    rates = json["data"]["rates"]
    eur = json["data"]["rates"]["EUR"]



    ##################### DATABASE #####################

    # Open database
    db = SQLite3::Database.open 'data.sqlite'

    # Create tables
    sqlCreateCoins = "CREATE TABLE IF NOT EXISTS coins (id_coin VARCHAR(10) PRIMARY KEY NOT NULL,name_coin VARCHAR(10) NOT NULL);"
    db.execute sqlCreateCoins;
    sqlCreateCoinsValue = "CREATE TABLE IF NOT EXISTS coins_value (date_coins_value NUMERIC NOT NULL, id_coin VARCHAR(10) NOT NULL,value_coin_usd NUMERIC,value_coin_eur NUMERIC,FOREIGN KEY(id_coin) REFERENCES coins(id_coin));"
    db.execute sqlCreateCoinsValue;

    # Add information in tables
    date = Time.now

    # 1. Update/populate table of coins
    rates.each do |coin,value|
        sql = "INSERT OR REPLACE INTO coins (id_coin,name_coin) VALUES ('"+coin+"','"+coin+"');"
        db.execute sql;
    end

    # 2. Update/populate table of coins_value with current values
    
    datestr = date.strftime("%Y/%m/%d %H:%M:%S")
    rates.each do |coin,value|
        # Conversion valeur / coins
        coinUsd = 1.0 / value.to_f
        valueCoinUsd = coinUsd.to_s
        # Conversion en eur 
        coinEur = coinUsd * eur.to_f
        valueCoinEur = coinEur.to_s

        # Update
        sql = "INSERT INTO coins_value (date_coins_value,id_coin,value_coin_usd,value_coin_eur) VALUES ('"+datestr+"','"+coin+"','"+valueCoinUsd+"','"+valueCoinEur+"');"
        db.execute sql;
    end

    ##################### DISPLAY #####################

    puts "============================"
    puts datestr
    puts "============================"
    
    puts "Name Coin \t USD \t\t EUR"
    researchXRP = db.prepare("SELECT * FROM coins_value WHERE id_coin LIKE 'XRP' AND date_coins_value LIKE '"+datestr+"';").execute
    researchBTC = db.prepare("SELECT * FROM coins_value WHERE id_coin LIKE 'BTC' AND date_coins_value LIKE '"+datestr+"';").execute
    researchETH = db.prepare("SELECT * FROM coins_value WHERE id_coin LIKE 'ETH' AND date_coins_value LIKE '"+datestr+"';").execute

    xrp = researchXRP.next
    btc = researchBTC.next
    eth = researchETH.next

    puts xrp[1]+"\t\t"+xrp[2].to_s+"\t"+xrp[3].to_s
    puts btc[1]+"\t\t"+btc[2].to_s+"\t"+btc[3].to_s
    puts eth[1]+"\t\t"+eth[2].to_s+"\t"+eth[3].to_s

    researchXRP.close
    researchBTC.close
    researchETH.close



    sleep(57)
}