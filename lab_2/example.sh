#!/bin/bash

# Знайти всі записи з кодом відповіді, який починається з 3
redirect_logs=$(grep "^[^ ]* - - .*\" 3[0-9][0-9] " 05-huge-access.log)

# Підрахувати кількість переадресацій для кожного хосту
redirect_counts=$(echo "$redirect_logs" | awk '{print $1}' | sort | uniq -c | sort -nr)

# Загальна кількість переадресацій для перших 10 хостів
total_redirects=$(echo "$redirect_counts" | head -n 10 | awk '{sum+=$1} END {print sum}')
echo $total_redirects >> test_log.txt
# Вивести топ-10 хостів з кількістю переадресацій та їх відсоткове відношення
top_10_redirects=$(echo "$redirect_counts" | head -n 10)
while read -r count host; do
    percentage=$(bc <<< "scale=2; ($count / $total_redirects) * 100")
    printf "%s - %d - %.0f%%\n" "$host" "$count" "$percentage"
done <<< $top_10_redirects

