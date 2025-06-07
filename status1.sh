#!/bin/bash
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"

# Установка временной зоны
TZ="Europe/Madrid"

# Определение следующей полуночи
midnight_epoch=$(gdate -d "tomorrow 00:00:00" +%s)

# Дата начала бронирования — через 6 дней от полуночи
booking_date=$(gdate -d "@$((midnight_epoch + 5 * 86400))" +"%Y-%m-%d")      # начало: 22:00
booking_date_end=$(gdate -d "@$((midnight_epoch + 6 * 86400))" +"%Y-%m-%d")  # конец: 17:00

# Параметры брони (часовой пояс — Europe/Madrid, летом +02:00)
start_date_utc="${booking_date}T22:00:00+02:00"
end_date_utc="${booking_date_end}T17:00:00+02:00"

# Места
seat1=362106
seat2=845096

# Текущий timestamp с миллисекундами
timestamp() {
  gdate +"%Y-%m-%d %H:%M:%S.%3N %Z"
}

# Функция бронирования
try_reserve() {
  local seat_id=$1
  local ts=$(timestamp)

  response=$(curl -s -w "\n%{http_code}" 'https://federation-gateway.robinpowered.com/graphql' \
    -H 'accept: */*' \
    -H 'accept-language: ru,en-US;q=0.9,en;q=0.8' \
    -H 'apollographql-client-name: dashboard-ui' \
    -H 'authorization: Access-Token Z5SI2Uw0yR1o7SaiZMoNXgOrbbCWFXAcN7RbePxtNH7QlTspPnQ8oW8XPWRPVx2pnXcLIC4SYkJnbFWyw7X2Sis5PbGNrSthwqkZ92jBY1MuTgiX5XXjISCg470ukOJy' \
    -H 'content-type: application/json' \
    -H 'origin: https://dashboard.robinpowered.com' \
    -H 'priority: u=1, i' \
    -H 'referer: https://dashboard.robinpowered.com/' \
    -H 'sec-ch-ua: "Chromium";v="136", "Google Chrome";v="136", "Not.A/Brand";v="99"' \
    -H 'sec-ch-ua-mobile: ?0' \
    -H 'sec-ch-ua-platform: "macOS"' \
    -H 'sec-fetch-dest: empty' \
    -H 'sec-fetch-mode: cors' \
    -H 'sec-fetch-site: same-site' \
    -H 'tenant-id: 935265' \
    -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36' \
    -H 'x-requested-with: robin/dashboard/angular' \
    --data-raw "{\"operationName\":\"ReserveDeskForMe\",\"variables\":{\"seatId\":${seat_id},\"type\":\"hoteled\",\"start\":{\"dateTime\":\"${start_date_utc}\",\"timeZone\":\"Europe/Madrid\"},\"end\":{\"dateTime\":\"${end_date_utc}\",\"timeZone\":\"Europe/Madrid\"},\"visibility\":\"EVERYONE\",\"notify\":true},\"extensions\":{\"persistedQuery\":{\"version\":1,\"sha256Hash\":\"11366e841bf22b7d1ce465c449e8e96c6d6ba4addbdb11f0d21d48f221e94d70\"}}}")

  http_body=$(echo "$response" | sed '$d')
  http_code=$(echo "$response" | tail -n1)

  if echo "$http_body" | grep -q '"errors"'; then
    echo "${ts} | ❌ Ошибка бронирования для места ${seat_id}"
    echo "${ts} | HTTP статус: $http_code"
    echo "${ts} | Ответ сервера: $http_body"
    return 1
  else
    echo "${ts} | ✅ Успешная бронь для места ${seat_id}"
    echo "${ts} | HTTP статус: $http_code"
    echo "${ts} | Ответ сервера: $http_body"
    return 0
  fi
}

# Ожидание до начала следующей минуты
#current_epoch=$(gdate +%s)
#next_minute_epoch=$(( (current_epoch / 60 + 1) * 60 ))
#next_minute_human=$(gdate -d "@$next_minute_epoch" +"%Y-%m-%d %H:%M:%S %Z")
#sleep_s=$(( next_minute_epoch - current_epoch ))

#echo "$(timestamp) | 📅 Дата начала бронирования: ${booking_date} в 22:00"
#echo "$(timestamp) | 📅 Дата окончания бронирования: ${booking_date_end} в 17:00"
#echo "$(timestamp) | 🕛 Время запуска скрипта бронирования: $next_minute_human"
#echo "$(timestamp) | ⏳ Ожидание до запуска $sleep_s секунд"

#sleep $sleep_s

#echo "$(timestamp) | 🚀 Запуск скрипта бронирования..."


# Рассчитываем задержку до 00:00:00.100
target_epoch_ms=$(( midnight_epoch * 1000 + 100 ))
current_epoch_ms=$(gdate +%s%3N)
sleep_ms=$(( target_epoch_ms - current_epoch_ms ))

sleep_s=$(( sleep_ms / 1000 ))
sleep_rem_ms=$(( sleep_ms % 1000 ))
target_time=$(gdate -d "@$midnight_epoch" +"%Y-%m-%d 00:00:00.100 %Z")

echo "$(timestamp) | 📅 Дата начала бронирования: $(gdate -d "${booking_date} +1 day" +"%Y-%m-%d") в 22:00"
echo "$(timestamp) | 📅 Дата окончания бронирования: $(gdate -d "${booking_date_end} +1 day" +"%Y-%m-%d") в 17:00"

#echo "$(timestamp) | 📅 Дата начала бронирования: ${booking_date} в 22:00"
#echo "$(timestamp) | 📅 Дата окончания бронирования: ${booking_date_end} в 17:00"
echo "$(timestamp) | 🕛 Время запуска скрипта: ${target_time}"
echo "$(timestamp) | ⏳ Ожидание до запуска: ${sleep_s} сек и ${sleep_rem_ms} мс"

sleep "${sleep_s}"
sleep "$(printf ".%03d" "${sleep_rem_ms}")"

echo "$(timestamp) | 🚀 Запуск скрипта бронирования..."



# Цикл 10 секунд: 5 сек для seat1, 5 сек для seat2
end_time=$(( $(gdate +%s) + 10 ))

while [ $(gdate +%s) -lt $end_time ]; do
  loop_end=$(( $(gdate +%s) + 5 ))
  while [ $(gdate +%s) -lt $loop_end ]; do
    try_reserve $seat1 && break
    sleep 0.1
  done

  loop_end=$(( $(gdate +%s) + 5 ))
  while [ $(gdate +%s) -lt $loop_end ]; do
    try_reserve $seat2 && break
    sleep 0.1
  done
done

echo "$(timestamp) | ✅ Скрипт завершён."

