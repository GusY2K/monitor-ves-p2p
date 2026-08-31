# Monitor del libro P2P USDT/VES

Mide el libro de Binance P2P cada 30 minutos vía API pública y guarda la serie en
`datos/spread-ves.csv`.

Nace de una necesidad concreta: el spread del tope pasó de 0,204% a 0,107% en 45 minutos, así que
una sola foto no sirve para decidir nada. Esto construye la serie temporal.

## Columnas

| Columna | Qué es |
|---|---|
| `ts_utc` / `ts_local` | Momento de la medición. Local = UTC−5 (Ecuador) |
| `ask` | Mejor precio para **comprar** USDT, en **bolívares por USDT** |
| `bid` | Mejor precio para **vender** USDT, en bolívares por USDT |
| `spread_pct` | `(ask − bid) / bid × 100` |
| `rango_pct` | Amplitud de los 20 niveles de cada lado |
| `prof_*_usdt` | USDT disponibles sumando los 20 niveles |
| `ask2/ask3/bid2/bid3` | 2.º y 3.º nivel, para detectar si el tope era un anuncio atípico |

**Notación:** los precios son bolívares por USDT. `934.909` son novecientos treinta y cuatro
bolívares, no 934 mil.

## Nota sobre el spread

En P2P **no hay matching automático**: el libro puede quedar con spread cero o cruzado porque los
anuncios tienen distintos métodos de pago, límites y filtros. Un spread de 0 o negativo es un dato
válido, no un error de medición.

## Aviso

GitHub deshabilita los workflows programados en repos sin actividad durante 60 días.
Como este commitea en cada corrida, se mantiene activo solo.
