#!/usr/bin/env bash
# Mide el libro P2P USDT/VES via API publica de Binance y agrega una fila al CSV.
set -uo pipefail
OUT="datos/spread-ves.csv"
API='https://p2p.binance.com/bapi/c2c/v2/friendly/c2c/adv/search'
ROWS=20

consulta() {
  curl -s -X POST "$API" -H 'content-type: application/json' \
    -d "{\"asset\":\"USDT\",\"fiat\":\"VES\",\"tradeType\":\"$1\",\"page\":1,\"rows\":$ROWS}" --max-time 25
}
precios() { grep -o '"price":"[0-9.]*"' | sed 's/.*:"//;s/"//'; }
montos()  { grep -o '"surplusAmount":"[0-9.]*"' | sed 's/.*:"//;s/"//'; }

TS_UTC=$(date -u +"%Y-%m-%d %H:%M:%S")
DOW=$(date -u +%u); HOUR_UTC=$(date -u +%H)
# hora local del usuario: UTC-5 (Ecuador). Verificado contra el offset del sistema (-0500)
TS_LOC=$(date -u -d '-5 hours' +"%Y-%m-%d %H:%M:%S")
HOUR_LOC=$(date -u -d '-5 hours' +%H)

RB=$(consulta BUY); RS=$(consulta SELL)
echo "$RB" | grep -q '"code":"000000"' || { echo "fallo API BUY"; exit 1; }
echo "$RS" | grep -q '"code":"000000"' || { echo "fallo API SELL"; exit 1; }

ASK=$(echo "$RB" | precios | sort -g | head -1)
BID=$(echo "$RS" | precios | sort -g | tail -1)
[ -n "$ASK" ] && [ -n "$BID" ] || { echo "sin precios"; exit 1; }

OK=$(awk -v a="$ASK" -v b="$BID" 'BEGIN{print (a>100 && a<100000 && b>100 && b<100000)?1:0}')
[ "$OK" = "1" ] || { echo "precios implausibles ask=$ASK bid=$BID"; exit 1; }

SA=$(awk -v a="$ASK" -v b="$BID" 'BEGIN{printf "%.3f", a-b}')
SP=$(awk -v a="$ASK" -v b="$BID" 'BEGIN{printf "%.4f", (a-b)/b*100}')
DA=$(echo "$RB" | montos | awk '{s+=$1} END{printf "%.2f", s}')
DB=$(echo "$RS" | montos | awk '{s+=$1} END{printf "%.2f", s}')
AMAX=$(echo "$RB" | precios | sort -g | tail -1)
BMIN=$(echo "$RS" | precios | sort -g | head -1)
RG=$(awk -v x="$AMAX" -v n="$BMIN" 'BEGIN{printf "%.4f", (x-n)/n*100}')
A2=$(echo "$RB" | precios | sort -g | sed -n '2p'); A3=$(echo "$RB" | precios | sort -g | sed -n '3p')
B2=$(echo "$RS" | precios | sort -g | tail -2 | head -1); B3=$(echo "$RS" | precios | sort -g | tail -3 | head -1)

mkdir -p datos
[ -f "$OUT" ] || echo "ts_utc,ts_local,dia_semana,hora,ask,bid,spread_abs,spread_pct,rango_pct,prof_ask_usdt,prof_bid_usdt,ask2,ask3,bid2,bid3" > "$OUT"
echo "$TS_UTC,$TS_LOC,$DOW,$HOUR_LOC,$ASK,$BID,$SA,$SP,$RG,$DA,$DB,$A2,$A3,$B2,$B3" >> "$OUT"
echo "ok $TS_LOC ask=$ASK bid=$BID spread=$SP%"
